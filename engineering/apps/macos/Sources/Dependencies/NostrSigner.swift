import Foundation
import ComposableArchitecture
import CryptoKit
import P256K
import SharedModels

/// In-process NIP-01 event signing under the reviewer's Nostr identity.
// Implements: FR-srm-event-sign
///
/// Wraps secp256k1 Schnorr signing + x-only pubkey derivation behind a
/// `@Dependency` protocol so reducers and tests depend on a protocol, not the
/// raw `P256K` package. The live value signs in-process (no `nak` subprocess,
/// no crossing of the secret key across a process boundary). `testValue`
/// returns nil (deterministic fixtures are injected per-test as needed).
@DependencyClient
public struct NostrSigner: Sendable {
    /// Sign `event` under `secretKey` (32 bytes), returning a copy with the
    /// NIP-01 `id`, `pubkey`, and `sig` populated. Returns nil on a bad key.
    public var sign: @Sendable (NostrEvent, Data) -> NostrEvent?
    /// Derive the x-only public key (hex, 64 chars) for `secretKey` (32 bytes).
    /// Returns nil on a bad key.
    public var publicKey: @Sendable (Data) -> String?
}

extension NostrSigner: DependencyKey {
    public static let liveValue = NostrSigner(
        sign: { event, secretKey in
            event.sign(secretKey: secretKey)
        },
        publicKey: { secretKey in
            NostrSigner.derivePublicKey(secretKey)
        }
    )

    public static let testValue = Self()

    /// Derive the 32-byte x-only public key for a 32-byte secret key, hex-encoded.
    static func derivePublicKey(_ secretKey: Data) -> String? {
        guard let priv = try? P256K.Schnorr.PrivateKey(dataRepresentation: [UInt8](secretKey)) else {
            return nil
        }
        return priv.publicKey.xonly.bytes.map { String(format: "%02x", $0) }.joined()
    }
}

extension DependencyValues {
    public var nostrSigner: NostrSigner {
        get { self[NostrSigner.self] }
        set { self[NostrSigner.self] = newValue }
    }
}

// MARK: - NostrEvent signing extension
//
// The `sign(secretKey:)` method is defined here (ShepherdDependencies) rather
// than on the model in SharedModels so the secp256k1 dependency stays out of the
// pure-model target. It is callable as `event.sign(secretKey:)` from any module
// importing ShepherdDependencies. Implements: FR-srm-event-sign (Schnorr half).
public extension NostrEvent {
    /// Return a signed copy of this event under `secretKey` (32 bytes): populates
    /// `id` (SHA-256 of the canonical serialization), `pubkey` (x-only), and `sig`
    /// (BIP-340 Schnorr signature over the id). The receiver supplies `kind`,
    /// `content`, `tags`, and `createdAt`; `pubkey`/`id`/`sig` are overwritten.
    /// Returns nil if the secret key is invalid.
    func sign(secretKey: Data) -> NostrEvent? {
        guard let priv = try? P256K.Schnorr.PrivateKey(dataRepresentation: [UInt8](secretKey)) else {
            return nil
        }
        let pubHex = priv.publicKey.xonly.bytes.map { String(format: "%02x", $0) }.joined()
        var signed = self
        signed.pubkey = pubHex
        signed.id = signed.computedID
        // BIP-340 signs the 32-byte message digest (the event id) directly.
        guard let idBytes = Data(hexString: signed.id) else { return nil }
        var msg = [UInt8](idBytes)
        var aux = [UInt8](repeating: 0, count: 32)
        guard let sig = try? priv.signature(message: &msg, auxiliaryRand: &aux) else {
            return nil
        }
        signed.sig = sig.bytes.map { String(format: "%02x", $0) }.joined()
        return signed
    }
}

extension Data {
    /// Decode a hex string into bytes. Returns nil on a non-hex / odd-length string.
    init?(hexString: String) {
        let s = hexString.lowercased()
        guard s.count % 2 == 0, s.allSatisfy({ $0.isHexDigit }) else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(s.count / 2)
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            guard let b = UInt8(s[idx..<next], radix: 16) else { return nil }
            bytes.append(b)
            idx = next
        }
        self = Data(bytes)
    }
}
