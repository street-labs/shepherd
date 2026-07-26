import Testing
import Foundation
import CryptoKit
import ComposableArchitecture
@testable import ShepherdDependencies
@testable import SharedModels
import P256K

/// NIP-42 relay AUTH: a relay sends `["AUTH", challenge]` on connect and rejects
/// REQ/EVENT until the client replies with `["AUTH", {kind-22242 event}]`. These
/// tests cover the signing core (the new logic) — the EVENT-delivery path is the
/// unchanged existing branch of `RelaySubscriptionTask.handleFrame`.
@Suite("RelayAuth / NIP-42 relay auth")
struct RelayAuthTests {
    // sec = 0x000...001 — BIP-340 generator key (same vector as NostrSignerTests).
    private let secData = Data(repeating: 0, count: 31) + Data([1])
    private let expectedPubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

    @Test("AUTH challenge -> signed kind:22242 frame with correct tags + valid sig")
    func authFrameSigns() throws {
        let frame = try #require(RelayAuth.authFrame(
            challenge: "deadbeef",
            relayURL: "ws://lukes-mac-studio:3000",
            secret: secData,
            signer: NostrSigner.liveValue
        ))
        let array = try #require(try JSONSerialization.jsonObject(
            with: Data(frame.utf8)) as? [Any])
        #expect(array[0] as? String == "AUTH")
        let evt = try #require(array[1] as? [String: Any])
        #expect(evt["kind"] as? Int == 22242)
        #expect(evt["content"] as? String == "")
        #expect(evt["pubkey"] as? String == expectedPubkey)
        let tags = try #require(evt["tags"] as? [[String]])
        #expect(tags == [
            ["challenge", "deadbeef"],
            ["relay", "ws://lukes-mac-studio:3000"],
        ])

        let id = try #require(evt["id"] as? String)
        let sig = try #require(evt["sig"] as? String)
        #expect(sig.count == 128) // 64-byte Schnorr signature, hex

        // id is the SHA-256 of the canonical serialization; re-derive and verify.
        let createdAt = (evt["created_at"] as? Int64) ?? 0
        let reconstructed = NostrEvent(
            id: id, pubkey: expectedPubkey, kind: 22242, content: "",
            tags: tags, createdAt: createdAt, sig: sig
        )
        #expect(reconstructed.id == reconstructed.computedID)

        let pub = try P256K.Schnorr.PrivateKey(dataRepresentation: [UInt8](secData)).publicKey.xonly
        let sigObj = try P256K.Schnorr.SchnorrSignature(
            dataRepresentation: [UInt8](Data(hexString: sig) ?? Data()))
        let digest = SHA256.hash(data: Data(reconstructed.canonicalSerialization().utf8))
        #expect(pub.isValidSignature(sigObj, for: digest))
    }

    @Test("No secret key -> nil AUTH frame (fallback to unauthenticated)")
    func noKeyFallback() {
        #expect(RelayAuth.authFrame(
            challenge: "x", relayURL: "ws://r", secret: nil, signer: NostrSigner.liveValue
        ) == nil)
    }
}
