import Foundation
import ComposableArchitecture
import SharedModels

/// Resolves the reviewer's Nostr identity at launch so signed patch-thread
/// replies can be published under it.
// Implements: FR-srm-identity-load
///
/// Configuration precedence (same shape as `RelayClient.resolveRelays`):
///   1. `SHEPHERD_NSEC` env var — bech32 `nsec1...` or hex secret key.
///   2. `~/.config/nostr/identity` file — first non-blank, non-`#` line,
///      `nsec1...` or hex.
///   3. No identity (publish unavailable; read-only review + local comments work).
///
/// When a key is loaded the public key is derived (secp256k1 scalar mult via
/// `NostrSigner`) and the display name resolved from
/// `~/.config/nostr/roster.json` (else truncated npub). The secret key is held in
/// memory for the app's lifetime (needed to sign on each submit) and is never
/// written to disk by the app. The app does not generate or manage keys.
@DependencyClient
public struct IdentityClient: Sendable {
    /// Load the reviewer's display identity (pubkey, npub, display name), or nil
    /// when no identity is configured. Drives the identity indicator and the
    /// `YOU` self-marker.
    public var loadIdentity: @Sendable () -> ReviewerIdentity?
    /// The cached 32-byte secret key for signing published events, or nil when no
    /// identity is loaded. Held outside observed app state.
    public var currentSecret: @Sendable () -> Data?
}

extension IdentityClient: DependencyKey {
    public static let liveValue: IdentityClient = {
        // Load once and cache: the secret key stays in memory for the app lifetime.
        let loaded = LoadedIdentity.load()
        return IdentityClient(
            loadIdentity: { loaded?.identity },
            currentSecret: { loaded?.secret }
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

/// The loaded identity bundle (display info + secret), cached once per process.
private struct LoadedIdentity {
    let identity: ReviewerIdentity
    let secret: Data

    static func load() -> LoadedIdentity? {
        guard let raw = resolveRawSecret() else { return nil }
        // Accept bech32 nsec1... or hex.
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
            identity: ReviewerIdentity(pubkeyHex: pubkeyHex, npub: npub, displayName: displayName),
            secret: secret
        )
    }

    /// Resolve the raw secret string from env / config file, or nil.
    static func resolveRawSecret() -> String? {
        let env = ProcessInfo.processInfo.environment
        if let v = env["SHEPHERD_NSEC"]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
            return v
        }
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/identity")
        guard let contents = try? String(contentsOf: file) else { return nil }
        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            return trimmed
        }
        return nil
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
        // Truncated npub: npub1... + last 4 chars, matching the command-prompt style.
        guard npub.count > 16 else { return pubkeyHex.isEmpty ? "unknown" : String(pubkeyHex.prefix(16)) + "…" }
        return String(npub.prefix(10)) + "…" + String(npub.suffix(4))
    }
}
