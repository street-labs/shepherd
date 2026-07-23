import Testing
import Foundation
@testable import ShepherdDependencies

/// Implements: TC-srm-nip44-unit — NIP-44 encrypt/decrypt round-trips and
/// rejects tampered ciphertext. Validates against the NIP-44 reference test
/// vectors (sec1=1, sec2=2, conversation_key, nonce, payload).
@Suite("NIP44Crypto / FR-srm-bunker-connect", .serialized)
struct NIP44CryptoTests {
    // Reference vectors from NIP-44 spec (nostr-protocol/nips 44.md)
    private let sec1 = Data(repeating: 0, count: 31) + [1]
    private let sec2 = Data(repeating: 0, count: 31) + [2]
    private let expectedConversationKey = Data(hexString: "c41c775356fd92eadc63ff5a0dc1da211b268cbea22316767095b2871ea1412d")!
    private let nonce = Data(repeating: 0, count: 31) + [1]
    private let expectedPayload = "AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABee0G5VSK0/9YypIObAtDKfYEAjD35uVkHyB0F4DwrcNaCXlCWZKaArsGrY6M9wnuTMxWfp1RTN9Xga8no+kF5Vsb"

    @Test("ECDH conversation key matches reference vector")
    func conversationKeyMatchesVector() throws {
        // Derive pub2 from sec2, then conv(sec1, pub2)
        let pub2 = try #require(NIP44Crypto.conversationKey(privateKey: sec2, peerPubkey: pubkey(from: sec1)))
        // conv(a, B) == conv(b, A) — verify symmetry
        let pub1 = try #require(NIP44Crypto.conversationKey(privateKey: sec1, peerPubkey: pubkey(from: sec2)))
        #expect(pub2 == pub1, "conversation key must be symmetric")
    }

    @Test("Conversation key equals expected hex")
    func conversationKeyHex() throws {
        // The spec says conv(sec1, pub2) == c41c...1412d. We compute it via the
        // internal API to get the raw conversation key (not wrapped in encrypt).
        let pub2 = pubkey(from: sec2)
        let convKey = try #require(NIP44Crypto.conversationKey(privateKey: sec1, peerPubkey: pub2))
        #expect(convKey == expectedConversationKey)
    }

    @Test("Encrypt with fixed nonce matches reference payload")
    func encryptMatchesVector() throws {
        let convKey = expectedConversationKey
        let payload = try #require(NIP44Crypto.encrypt("a", conversationKey: convKey, nonce: nonce))
        #expect(payload == expectedPayload)
    }

    @Test("Decrypt reference payload yields expected plaintext")
    func decryptMatchesVector() throws {
        let convKey = expectedConversationKey
        let plaintext = try #require(NIP44Crypto.decrypt(expectedPayload, conversationKey: convKey))
        #expect(plaintext == "a")
    }

    @Test("Round-trip encrypt then decrypt with random nonce")
    func roundTrip() throws {
        let pub2 = pubkey(from: sec2)
        let payload = try #require(NIP44Crypto.encrypt("hello world", privateKey: sec1, peerPubkey: pub2))
        let decrypted = try #require(NIP44Crypto.decrypt(payload, privateKey: sec2, peerPubkey: pubkey(from: sec1)))
        #expect(decrypted == "hello world")
    }

    @Test("Tampered ciphertext fails decryption (MAC mismatch)")
    func tamperFails() throws {
        let convKey = expectedConversationKey
        let payload = try #require(NIP44Crypto.encrypt("secret", conversationKey: convKey, nonce: nonce))
        // Flip a byte in the base64 payload's middle (ciphertext region)
        var bytes = Data(base64Encoded: payload)!
        bytes[40] ^= 0x01
        let tampered = bytes.base64EncodedString()
        #expect(NIP44Crypto.decrypt(tampered, conversationKey: convKey) == nil)
    }

    @Test("Padding: calcPaddedLen matches reference values")
    func paddingSizes() {
        #expect(NIP44Crypto.calcPaddedLen(1) == 32)
        #expect(NIP44Crypto.calcPaddedLen(32) == 32)
        #expect(NIP44Crypto.calcPaddedLen(33) == 64)
        #expect(NIP44Crypto.calcPaddedLen(64) == 64)
        #expect(NIP44Crypto.calcPaddedLen(65) == 96)
        #expect(NIP44Crypto.calcPaddedLen(255) == 256)
        #expect(NIP44Crypto.calcPaddedLen(256) == 256)
        #expect(NIP44Crypto.calcPaddedLen(257) == 320)
    }

    @Test("Long message round-trip")
    func longRoundTrip() throws {
        let pub2 = pubkey(from: sec2)
        let long = String(repeating: "x", count: 1000)
        let payload = try #require(NIP44Crypto.encrypt(long, privateKey: sec1, peerPubkey: pub2))
        let decrypted = try #require(NIP44Crypto.decrypt(payload, privateKey: sec2, peerPubkey: pubkey(from: sec1)))
        #expect(decrypted == long)
    }

    /// Derive the 32-byte x-only public key from a 32-byte private key.
    private func pubkey(from sec: Data) -> Data {
        // Use the same derivation as NostrSigner (Schnorr x-only pubkey)
        NostrSigner.derivePublicKey(sec).flatMap { Data(hexString: $0) } ?? Data()
    }
}
