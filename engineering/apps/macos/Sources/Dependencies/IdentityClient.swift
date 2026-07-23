import Foundation
import ComposableArchitecture
import SharedModels

/// Resolves the reviewer's Nostr identity at launch so signed patch-thread
/// replies can be published under it.
// Implements: FR-srm-identity-load
///
/// Configuration precedence (bunker preferred so a raw secret key need not live
/// on the host):
///   1. `SHEPHERD_BUNKER` env var — a `bunker://` URI (NIP-46 remote signer).
///   2. `~/.config/nostr/bunker` file — first non-blank, non-`#` line, `bunker://` URI.
///   3. `SHEPHERD_NSEC` env var — bech32 `nsec1...` or hex secret key.
///   4. `~/.config/nostr/identity` file — first non-blank, non-`#` line, `nsec1...` or hex.
///   5. No identity (publish unavailable; read-only review + local comments work).
///
/// For a local key, the public key is derived (secp256k1) and the secret key is
/// held in memory for the app's lifetime. For a bunker, no secret key is held —
/// the reviewer's pubkey is obtained from the bunker via `get_public_key`, and
/// signing is delegated to the bunker via `sign_event`. The app does not
/// generate or manage the reviewer's keys (for a bunker it generates only an
/// ephemeral session keypair for the NIP-46 control channel, never persisted).
@DependencyClient
public struct IdentityClient: Sendable {
    /// Load the reviewer's display identity (pubkey, npub, display name, source
    /// kind, bunker connection state), or nil when no identity is configured.
    public var loadIdentity: @Sendable () -> ReviewerIdentity?
    /// The cached 32-byte secret key for signing published events, or nil when
    /// no local-key identity is loaded (nil for a bunker identity). Held outside
    /// observed app state.
    public var currentSecret: @Sendable () -> Data?
    /// Sign a Nostr event under the loaded identity. For a local key, signs
    /// in-process via secp256k1 Schnorr. For a bunker, delegates to the remote
    /// signer via NIP-46 `sign_event`. Returns nil on bunker failure.
    /// Implements: FR-srm-event-sign, FR-sr-bunker-signing
    public var sign: @Sendable (NostrEvent) async -> NostrEvent?
    /// Start the bunker connect handshake (for a bunker identity). No-op for a
    /// local-key identity. Returns the reviewer's pubkey hex on success, nil on
    /// failure. Implements: FR-srm-bunker-connect
    public var connectBunker: @Sendable () async -> String?
}

extension IdentityClient: DependencyKey {
    public static let liveValue: IdentityClient = {
        // Load once and cache: the identity stays in memory for the app lifetime.
        let loaded = LoadedIdentity.load()
        return IdentityClient(
            loadIdentity: { loaded?.identity },
            currentSecret: { loaded?.secret },
            sign: { event in
                await loaded?.sign(event)
            },
            connectBunker: {
                await loaded?.connectBunker()
            }
        )
    }()

    public static let testValue = Self()
}

extension DependencyValues {
    public var identityClient: IdentityClient {
        get { self[IdentityClient.self] }
        set { self[IdentityClient.self] = newValue }
    }
}

// MARK: - Loading

/// The loaded identity bundle, cached once per process.
private final class LoadedIdentity: @unchecked Sendable {
    var identity: ReviewerIdentity
    let secret: Data?
    let bunkerConfig: BunkerConfig?

    init(identity: ReviewerIdentity, secret: Data?, bunkerConfig: BunkerConfig?) {
        self.identity = identity
        self.secret = secret
        self.bunkerConfig = bunkerConfig
    }

    static func load() -> LoadedIdentity? {
        let env = ProcessInfo.processInfo.environment

        // 1. SHEPHERD_BUNKER env (bunker:// URI)
        if let uri = env["SHEPHERD_BUNKER"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !uri.isEmpty, let config = BunkerConfig.parse(uri) {
            return LoadedIdentity.bunker(config: config)
        }

        // 2. ~/.config/nostr/bunker file
        let bunkerFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/bunker")
        if let contents = try? String(contentsOf: bunkerFile) {
            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                if let config = BunkerConfig.parse(trimmed) {
                    return LoadedIdentity.bunker(config: config)
                }
                // Malformed bunker URI → parse-error identity state
                if trimmed.hasPrefix("bunker://") {
                    return LoadedIdentity.parseError()
                }
            }
        }

        // 3. SHEPHERD_NSEC env (nsec1... or hex)
        if let raw = env["SHEPHERD_NSEC"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            if let local = loadLocalKey(raw) { return local }
        }

        // 4. ~/.config/nostr/identity file
        let identityFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/identity")
        if let contents = try? String(contentsOf: identityFile) {
            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                if let local = loadLocalKey(trimmed) { return local }
            }
        }

        return nil // No identity
    }

    /// Load a local secret key (bech32 nsec1... or hex). Returns nil on a bad key.
    private static func loadLocalKey(_ raw: String) -> LoadedIdentity? {
        var secret: Data?
        if raw.hasPrefix("nsec1") {
            if let decoded = Bech32.decode(raw), decoded.prefix == "nsec" {
                secret = decoded.data
            }
        } else {
            secret = Data(hexString: raw)
        }
        guard let secret, secret.count == 32 else { return nil }
        guard let pubkeyHex = NostrSigner.derivePublicKey(secret) else { return nil }
        let pubkeyBytes = Data(hexString: pubkeyHex) ?? Data()
        let npub = Bech32.encode(pubkeyBytes, prefix: "npub")
        let displayName = resolveDisplayName(pubkeyHex: pubkeyHex, npub: npub)
        return LoadedIdentity(
            identity: ReviewerIdentity(
                pubkeyHex: pubkeyHex, npub: npub, displayName: displayName, source: .localKey
            ),
            secret: secret,
            bunkerConfig: nil
        )
    }

    /// Create a bunker identity with the initial `.connecting` state. The pubkey
    /// is empty until the bunker handshake completes; `loadIdentity` returns the
    /// identity with `.connecting` state so the indicator can show the handshake
    /// in progress. After `connectBunker()` succeeds, the identity is updated.
    private static func bunker(config: BunkerConfig) -> LoadedIdentity {
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Connecting…",
            source: .bunker,
            bunkerState: .connecting,
            bunkerRelayURL: config.relayURL
        )
        return LoadedIdentity(identity: identity, secret: nil, bunkerConfig: config)
    }

    /// Create a parse-error identity (malformed bunker:// URI).
    private static func parseError() -> LoadedIdentity {
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Invalid bunker URI",
            source: .bunker,
            bunkerState: .failed("Malformed bunker:// URI"),
            bunkerRelayURL: nil
        )
        return LoadedIdentity(identity: identity, secret: nil, bunkerConfig: nil)
    }

    // MARK: - Signing

    /// Sign a Nostr event under the loaded identity. Local key → in-process Schnorr;
    /// bunker → NIP-46 sign_event delegation.
    // Implements: FR-srm-event-sign, FR-sr-bunker-signing
    func sign(_ event: NostrEvent) async -> NostrEvent? {
        if let secret {
            return event.sign(secretKey: secret)
        }
        if bunkerConfig != nil {
            return await BunkerClient.liveValue.signEvent(event)
        }
        return nil
    }

    /// Run the bunker connect handshake and update the identity with the
    /// reviewer's pubkey. Returns the pubkey hex on success, nil on failure.
    // Implements: FR-srm-bunker-connect
    func connectBunker() async -> String? {
        guard let config = bunkerConfig else { return nil }
        let pubkey = await BunkerClient.liveValue.connect(config)
        if let pubkey {
            // Update the identity with the resolved pubkey
            let npub = Bech32.encode(Data(hexString: pubkey) ?? Data(), prefix: "npub")
            identity.pubkeyHex = pubkey
            identity.npub = npub
            identity.displayName = LoadedIdentity.resolveDisplayName(pubkeyHex: pubkey, npub: npub)
            identity.bunkerState = .connected
        } else {
            identity.bunkerState = .failed("Bunker unreachable")
        }
        return pubkey
    }

    /// Display name from roster.json for this pubkey, else truncated npub.
    static func resolveDisplayName(pubkeyHex: String, npub: String) -> String {
        let rosterURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/roster.json")
        if let data = try? Data(contentsOf: rosterURL),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let entry = obj[pubkeyHex] as? [String: Any],
           let name = entry["name"] as? String, !name.isEmpty {
            return name
        }
        guard npub.count > 16 else { return pubkeyHex.isEmpty ? "unknown" : String(pubkeyHex.prefix(16)) + "…" }
        return String(npub.prefix(10)) + "…" + String(npub.suffix(4))
    }
}
