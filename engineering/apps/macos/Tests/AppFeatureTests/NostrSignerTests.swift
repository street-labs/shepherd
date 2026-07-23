import Testing
import Foundation
import CryptoKit
import ComposableArchitecture
@testable import ShepherdDependencies
@testable import SharedModels
import P256K

/// Implements: TC-srm-signer-unit — the in-process NIP-01 signer produces a valid
/// event whose id, pubkey, and Schnorr signature verify. Uses the canonical
/// `nak`-cross-checked reference vectors (sec = 1).
@Suite("NostrSigner / FR-srm-event-sign, FR-srm-identity-load")
struct NostrSignerTests {
    /// sec = 0x000...001 — the BIP-340 generator key. Pubkey is the generator x-coordinate.
    private let secHex = String(repeating: "0", count: 63) + "1"
    private let secData: Data = {
        var d = Data(repeating: 0, count: 31)
        d.append(1)
        return d
    }()
    private let expectedPubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

    @Test("Signs a kind:1 event: id == sha256(canonical), pubkey == derived, sig verifies")
    func signValidEvent() throws {
        let tags: [[String]] = [
            ["e", "abc123def456", "", "root"],
            ["a", "30617:owner:repo"],
            ["range", "/src/foo.ts", "10", "12"],
        ]
        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: tags, createdAt: 1700000000
        )

        let signed = try #require(unsigned.sign(secretKey: secData))
        #expect(signed.pubkey == expectedPubkey)
        // id is the SHA-256 of the canonical serialization WITH the pubkey set;
        // matches the nak-cross-checked vector.
        #expect(signed.id == "ad74dc2b0d5894e5f50055fd34aa1e094040e788d9818d7e0019a784e05df049")
        #expect(signed.id == signed.computedID)
        #expect(signed.sig.count == 128) // 64-byte Schnorr signature, hex

        // Verify the Schnorr signature against the derived x-only pubkey, over the
        // canonical serialization digest (the event id).
        let pub = try P256K.Schnorr.PrivateKey(dataRepresentation: [UInt8](secData)).publicKey.xonly
        let sigObj = try P256K.Schnorr.SchnorrSignature(dataRepresentation: [UInt8](Data(hexString: signed.sig) ?? Data()))
        let digest = SHA256.hash(data: Data(signed.canonicalSerialization().utf8))
        #expect(pub.isValidSignature(sigObj, for: digest))
    }

    @Test("NostrSigner dependency signs and derives pubkey consistently")
    func signerDependency() throws {
        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = try #require(NostrSigner.liveValue.sign(unsigned, secData))
        #expect(signed.pubkey == expectedPubkey)
        #expect(signed.id == signed.computedID)
        // tags=[], content="hello" -> the nak-cross-checked vector A id.
        #expect(signed.id == "bde202ea7642ff9910600c7edc948a1f4220f0cbf5e4fb2b7efafa681bbb5285")
        #expect(NostrSigner.liveValue.publicKey(secData) == expectedPubkey)
    }

    @Test("Bad secret key returns nil")
    func badKey() {
        let bad = Data(repeating: 0xFF, count: 40) // wrong length
        let unsigned = NostrEvent(id: "", pubkey: "", kind: 1, content: "x", tags: [], createdAt: 1)
        #expect(unsigned.sign(secretKey: bad) == nil)
    }

    @Test("Bech32 encodes npub and decodes nsec against nak reference vectors")
    func bech32Vectors() throws {
        let pubBytes = try #require(Data(hexString: expectedPubkey))
        let npub = Bech32.encode(pubBytes, prefix: "npub")
        #expect(npub == "npub10xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqpkge6d")

        let nsec = "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl"
        let decoded = try #require(Bech32.decode(nsec))
        #expect(decoded.prefix == "nsec")
        #expect(decoded.data == secData)
    }
}
