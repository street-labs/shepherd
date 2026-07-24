import Foundation
import ComposableArchitecture
import SharedModels

/// Login/create/logout error for the in-app identity screen. Distinguishes a bad
/// key/URI from a persistence failure so the reducer can show the right message.
public enum IdentityLoginError: Error, Equatable, Sendable {
    case invalidKey      // malformed nsec/hex or not a valid 32-byte secret
    case storageFailed   // Keychain write failed (locked, disk full)
    case invalidURI      // malformed bunker:// URI (missing relay, bad pubkey)
    case connectFailed   // bunker unreachable, refused, or timed out
}

/// The result of creating a new local identity: the identity plus the bech32
/// `nsec` for backup display. A struct (not a tuple) so it is `Equatable`.
public struct CreateIdentityResult: Equatable, Sendable {
    public let identity: ReviewerIdentity
    public let nsec: String

    public init(identity: ReviewerIdentity, nsec: String) {
        self.identity = identity
        self.nsec = nsec
    }
}

/// Resolves the reviewer's Nostr identity at launch so signed patch-thread
/// replies can be published under it.
// Implements: FR-srm-identity-load, FR-id-out-of-band-honored, FR-id-no-silent-override
///
/// Configuration precedence (in-app Keychain first so the reviewer's most
/// recent explicit login is honored; out-of-band sources still work when no
/// in-app identity is stored):
///   1. Keychain (`shepherd-nostr-identity`) — in-app-stored key or bunker URI.
///   2. `SHEPHERD_BUNKER` env var — a `bunker://` URI (NIP-46 remote signer).
///   3. `~/.config/nostr/bunker` file — first non-blank, non-`#` line, `bunker://` URI.
///   4. `SHEPHERD_NSEC` env var — bech32 `nsec1...` or hex secret key.
///   5. `~/.config/nostr/identity` file — first non-blank, non-`#` line, `nsec1...` or hex.
///   6. No identity (publish unavailable; read-only review + local comments work).
///
/// For a local key, the public key is derived (secp256k1) and the secret key is
/// held in memory for the app's lifetime. For a bunker, no secret key is held —
/// the reviewer's pubkey is obtained from the bunker via `get_public_key`, and
/// signing is delegated to the bunker via `sign_event`. The in-app login path
/// (`loginWithKey`/`createNewIdentity`/`loginWithBunker`) generates and persists
/// keys/URIs; the out-of-band path does not generate keys.
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
    /// Close the bunker control channel (cancel WebSocket + receive loop).
    /// Called on window close. No-op for a local-key identity.
    public var closeBunker: @Sendable () -> Void
    /// Validate an nsec (bech32 `nsec1...`) or hex secret key, adopt it as the
    /// active identity, persist it to Keychain. Returns the identity or an
    /// error distinguishing an invalid key from a storage failure.
    /// Implements: FR-id-nsec-login
    public var loginWithKey: @Sendable (String) -> Result<ReviewerIdentity, IdentityLoginError> = { _ in .failure(.invalidKey) }
    /// Generate a fresh 32-byte secret key, adopt it, persist it, and return the
    /// identity plus the bech32 nsec for backup display.
    /// Implements: FR-id-create-new, FR-id-show-new-nsec
    public var createNewIdentity: @Sendable () -> Result<CreateIdentityResult, IdentityLoginError> = { .failure(.storageFailed) }
    /// Parse a `bunker://` URI, persist it to Keychain, run the NIP-46 connect
    /// handshake, obtain the reviewer's pubkey, and adopt the bunker identity.
    /// On a connect failure the persisted URI is removed (no orphaned identity).
    /// Implements: FR-id-bunker-login, FR-id-bunker-connect-failure
    public var loginWithBunker: @Sendable (String) async -> Result<ReviewerIdentity, IdentityLoginError> = { _ in .failure(.connectFailed) }
    /// Forget the app-stored identity (Keychain delete) and clear the cached
    /// loaded identity. Implements: FR-id-logout (both forms).
    public var logout: @Sendable () -> Void
}

extension IdentityClient: DependencyKey {
    public static let liveValue: IdentityClient = {
        // Load once and cache: the identity stays in memory for the app lifetime.
        // Capture the injected bunkerClient/keychainClient so the bunker and
        // persistence paths route through DI (testable via withDependencies)
        // rather than hardcoding .liveValue. A holder lets login/create populate
        // an identity when none was loaded at launch.
        let bunkerClient = DependencyValues._current.bunkerClient
        let keychainClient = DependencyValues._current.keychainClient
        let holder = IdentityHolder(
            loaded: LoadedIdentity.load(bunkerClient: bunkerClient, keychainClient: keychainClient),
            bunkerClient: bunkerClient,
            keychainClient: keychainClient
        )
        return IdentityClient(
            loadIdentity: { holder.loaded?.identity },
            currentSecret: { holder.loaded?.secret },
            sign: { event in await holder.loaded?.sign(event) },
            connectBunker: { await holder.loaded?.connectBunker() },
            closeBunker: { holder.loaded?.closeBunker() },
            loginWithKey: { input in holder.loginWithKey(input) },
            createNewIdentity: { holder.createNewIdentity() },
            loginWithBunker: { uri in await holder.loginWithBunker(uri) },
            logout: { holder.logout() }
        )
    }()

    public static let testValue = Self()
}

/// Mutable holder so an in-app login can populate an identity when none was
/// loaded at launch, and logout can clear it. `@unchecked Sendable` — guarded
/// by the fact that the liveValue is created once and the methods are invoked
/// from the reducer's single-threaded effect context.
final class IdentityHolder: @unchecked Sendable {
    var loaded: LoadedIdentity?
    let bunkerClient: BunkerClient
    let keychainClient: KeychainClient

    init(loaded: LoadedIdentity?, bunkerClient: BunkerClient, keychainClient: KeychainClient) {
        self.loaded = loaded
        self.bunkerClient = bunkerClient
        self.keychainClient = keychainClient
    }

    // Implements: FR-id-nsec-login, FR-id-persistence
    func loginWithKey(_ raw: String) -> Result<ReviewerIdentity, IdentityLoginError> {
        guard let new = LoadedIdentity.loadLocalKey(
            raw, bunkerClient: bunkerClient, keychainClient: keychainClient
        ), let secret = new.secret else { return .failure(.invalidKey) }
        guard keychainClient.writeIdentity(secret) else { return .failure(.storageFailed) }
        loaded = new
        return .success(new.identity)
    }

    // Implements: FR-id-create-new, FR-id-show-new-nsec, FR-id-persistence
    func createNewIdentity() -> Result<CreateIdentityResult, IdentityLoginError> {
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes { buf -> Int32 in
            guard let base = buf.baseAddress else { return -1 }
            return SecRandomCopyBytes(kSecRandomDefault, 32, base)
        }
        guard result == errSecSuccess,
              let pubkeyHex = NostrSigner.derivePublicKey(key) else {
            return .failure(.invalidKey)
        }
        let pubkeyBytes = Data(hexString: pubkeyHex) ?? Data()
        let npub = Bech32.encode(pubkeyBytes, prefix: "npub")
        let nsec = Bech32.encode(key, prefix: "nsec")
        let displayName = LoadedIdentity.resolveDisplayName(pubkeyHex: pubkeyHex, npub: npub)
        let identity = ReviewerIdentity(
            pubkeyHex: pubkeyHex, npub: npub, displayName: displayName, source: .localKey
        )
        // Persist before adopting: refuse to hand back an nsec the app can't
        // restore on relaunch. The reviewer backs up an nsec that is actually durable.
        guard keychainClient.writeIdentity(key) else { return .failure(.storageFailed) }
        loaded = LoadedIdentity(
            identity: identity, secret: key, bunkerConfig: nil,
            bunkerClient: bunkerClient, keychainClient: keychainClient
        )
        return .success(CreateIdentityResult(identity: identity, nsec: nsec))
    }

    // Implements: FR-id-bunker-login, FR-id-bunker-connect-failure, FR-id-bunker-persist
    func loginWithBunker(_ uri: String) async -> Result<ReviewerIdentity, IdentityLoginError> {
        guard uri.hasPrefix("bunker://"),
              let config = BunkerConfig.parse(uri) else {
            return .failure(.invalidURI)
        }
        // Snapshot the existing identity so a failed login attempt cannot wipe it.
        // Persist only after a successful connect: a failed handshake leaves the
        // previous Keychain entry and in-memory identity untouched.
        let previousLoaded = loaded
        let previousKeychain = keychainClient.readIdentity()
        // Close any existing bunker session before reconnecting.
        loaded?.closeBunker()
        let new = LoadedIdentity.bunker(
            config: config, bunkerClient: bunkerClient, keychainClient: keychainClient
        )
        guard await new.connectBunker() != nil else {
            // Connect failed: restore the previous identity in memory + Keychain.
            // Do not adopt the new identity; do not delete the previous one.
            loaded = previousLoaded
            if let prev = previousKeychain {
                _ = keychainClient.writeIdentity(prev)
            } else {
                keychainClient.deleteIdentity()
            }
            return .failure(.connectFailed)
        }
        // Success: persist the new URI, overwriting the previous entry.
        guard keychainClient.writeIdentity(Data(uri.utf8)) else {
            // Persist failed even though the connect succeeded. The identity works
            // for this session but won't survive relaunch; surface it as a failure
            // so the reviewer is not surprised next launch. Restore the previous.
            new.closeBunker()
            loaded = previousLoaded
            if let prev = previousKeychain {
                _ = keychainClient.writeIdentity(prev)
            } else {
                keychainClient.deleteIdentity()
            }
            return .failure(.storageFailed)
        }
        loaded = new
        return .success(new.identity)
    }

    // Implements: FR-id-logout (both forms)
    func logout() {
        loaded?.closeBunker()
        keychainClient.deleteIdentity()
        loaded = nil
    }
}

extension DependencyValues {
    public var identityClient: IdentityClient {
        get { self[IdentityClient.self] }
        set { self[IdentityClient.self] = newValue }
    }
}

// MARK: - Loading

/// The loaded identity bundle, cached once per process.
final class LoadedIdentity: @unchecked Sendable {
    var identity: ReviewerIdentity
    let secret: Data?
    var bunkerConfig: BunkerConfig?
    let bunkerClient: BunkerClient
    let keychainClient: KeychainClient

    init(identity: ReviewerIdentity, secret: Data?, bunkerConfig: BunkerConfig?, bunkerClient: BunkerClient, keychainClient: KeychainClient) {
        self.identity = identity
        self.secret = secret
        self.bunkerConfig = bunkerConfig
        self.bunkerClient = bunkerClient
        self.keychainClient = keychainClient
    }

    static func load(bunkerClient: BunkerClient, keychainClient: KeychainClient) -> LoadedIdentity? {
        // 0. Keychain (in-app-stored identity) — highest precedence.
        // Format rule: 32 bytes -> secret key; else parse as UTF-8 bunker:// URI.
        if let data = keychainClient.readIdentity() {
            if data.count == 32 {
                if let local = loadLocalKey(data, bunkerClient: bunkerClient, keychainClient: keychainClient) {
                    return local
                }
            } else if let str = String(data: data, encoding: .utf8),
                      str.hasPrefix("bunker://"),
                      let config = BunkerConfig.parse(str) {
                return LoadedIdentity.bunker(config: config, bunkerClient: bunkerClient, keychainClient: keychainClient)
            }
            // Corrupt entry: fall through to out-of-band sources.
        }

        let env = ProcessInfo.processInfo.environment

        // 1. SHEPHERD_BUNKER env (bunker:// URI)
        if let uri = env["SHEPHERD_BUNKER"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !uri.isEmpty {
            if let config = BunkerConfig.parse(uri) {
                return LoadedIdentity.bunker(config: config, bunkerClient: bunkerClient, keychainClient: keychainClient)
            }
            // Malformed bunker:// URI → parse-error identity state (not silent
            // fallthrough to nsec). Spec: highest precedence, distinct error state.
            if uri.hasPrefix("bunker://") {
                return LoadedIdentity.parseError(bunkerClient: bunkerClient, keychainClient: keychainClient)
            }
        }

        // 2. ~/.config/nostr/bunker file
        let bunkerFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/bunker")
        if let contents = try? String(contentsOf: bunkerFile) {
            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                if let config = BunkerConfig.parse(trimmed) {
                    return LoadedIdentity.bunker(config: config, bunkerClient: bunkerClient, keychainClient: keychainClient)
                }
                // Malformed bunker URI → parse-error identity state
                if trimmed.hasPrefix("bunker://") {
                    return LoadedIdentity.parseError(bunkerClient: bunkerClient, keychainClient: keychainClient)
                }
            }
        }

        // 3. SHEPHERD_NSEC env (nsec1... or hex)
        if let raw = env["SHEPHERD_NSEC"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            if let local = loadLocalKey(raw, bunkerClient: bunkerClient, keychainClient: keychainClient) { return local }
        }

        // 4. ~/.config/nostr/identity file
        let identityFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/identity")
        if let contents = try? String(contentsOf: identityFile) {
            for line in contents.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                if let local = loadLocalKey(trimmed, bunkerClient: bunkerClient, keychainClient: keychainClient) { return local }
            }
        }

        return nil // No identity
    }

    /// Load a local secret key from a bech32 `nsec1...` or hex string. Returns nil
    /// on a bad key. Implements: FR-id-nsec-login (validation half).
    static func loadLocalKey(_ raw: String, bunkerClient: BunkerClient, keychainClient: KeychainClient) -> LoadedIdentity? {
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
            bunkerConfig: nil,
            bunkerClient: bunkerClient,
            keychainClient: keychainClient
        )
    }

    /// Load a local secret key from 32 bytes of `Data` (the Keychain path).
    static func loadLocalKey(_ data: Data, bunkerClient: BunkerClient, keychainClient: KeychainClient) -> LoadedIdentity? {
        guard data.count == 32,
              let pubkeyHex = NostrSigner.derivePublicKey(data) else { return nil }
        let pubkeyBytes = Data(hexString: pubkeyHex) ?? Data()
        let npub = Bech32.encode(pubkeyBytes, prefix: "npub")
        let displayName = resolveDisplayName(pubkeyHex: pubkeyHex, npub: npub)
        return LoadedIdentity(
            identity: ReviewerIdentity(
                pubkeyHex: pubkeyHex, npub: npub, displayName: displayName, source: .localKey
            ),
            secret: data,
            bunkerConfig: nil,
            bunkerClient: bunkerClient,
            keychainClient: keychainClient
        )
    }

    /// Create a bunker identity with the initial `.connecting` state.
    static func bunker(config: BunkerConfig, bunkerClient: BunkerClient, keychainClient: KeychainClient) -> LoadedIdentity {
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Connecting…",
            source: .bunker,
            bunkerState: .connecting,
            bunkerRelayURL: config.relayURL
        )
        return LoadedIdentity(identity: identity, secret: nil, bunkerConfig: config, bunkerClient: bunkerClient, keychainClient: keychainClient)
    }

    /// Create a parse-error identity (malformed bunker:// URI).
    static func parseError(bunkerClient: BunkerClient, keychainClient: KeychainClient) -> LoadedIdentity {
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Invalid bunker URI",
            source: .bunker,
            bunkerState: .failed("Malformed bunker:// URI"),
            bunkerRelayURL: nil
        )
        return LoadedIdentity(identity: identity, secret: nil, bunkerConfig: nil, bunkerClient: bunkerClient, keychainClient: keychainClient)
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
            // Route through the injected bunkerClient (DI), not .liveValue.
            return await bunkerClient.signEvent(event)
        }
        return nil
    }

    /// Run the bunker connect handshake and update the identity with the
    /// reviewer's pubkey. Returns the pubkey hex on success, nil on failure.
    // Implements: FR-srm-bunker-connect
    func connectBunker() async -> String? {
        guard let config = bunkerConfig else { return nil }
        let pubkey = await bunkerClient.connect(config)
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

    /// Close the bunker control channel. No-op for a local-key identity.
    func closeBunker() {
        bunkerClient.close()
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
