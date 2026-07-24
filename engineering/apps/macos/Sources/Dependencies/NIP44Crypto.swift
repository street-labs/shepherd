import Foundation
import CryptoKit
import P256K
import Security

/// NIP-44 v2 authenticated encryption for the NIP-46 bunker control channel.
// Implements: FR-srm-bunker-connect (the encryption layer)
///
/// NIP-46 kind `24133` `content` is NIP-44-encrypted (not NIP-04). NIP-44 v2 is:
/// secp256k1 ECDH → HKDF-SHA256 → ChaCha20 + HMAC-SHA256 → base64. ECDH and
/// HKDF/HMAC use `P256K` and `CryptoKit` respectively (both already dependencies).
/// ChaCha20 is implemented here because CryptoKit exposes only ChaChaPoly (AEAD),
/// not the raw ChaCha20 stream cipher NIP-44 requires (it uses HMAC-SHA256 for
/// authentication, not Poly1305). No new package dependency.
///
/// Test vectors: validated against the NIP-44 reference vectors (sec1=1, sec2=2).
public enum NIP44Crypto {
    // MARK: - Public API

    /// Encrypt `plaintext` under the ECDH-derived conversation key, returning the
    /// base64 NIP-44 v2 payload. `privateKey` is 32 bytes; `peerPubkey` is the
    /// 32-byte x-only public key of the recipient.
    public static func encrypt(
        _ plaintext: String,
        privateKey: Data,
        peerPubkey: Data
    ) -> String? {
        guard let convKey = conversationKey(privateKey: privateKey, peerPubkey: peerPubkey) else {
            return nil
        }
        let nonce = randomBytes(32)
        return encrypt(plaintext, conversationKey: convKey, nonce: nonce)
    }

    /// Decrypt a base64 NIP-44 v2 payload, returning the plaintext. `privateKey`
    /// is 32 bytes; `peerPubkey` is the 32-byte x-only public key of the sender.
    public static func decrypt(
        _ payload: String,
        privateKey: Data,
        peerPubkey: Data
    ) -> String? {
        guard let convKey = conversationKey(privateKey: privateKey, peerPubkey: peerPubkey) else {
            return nil
        }
        return decrypt(payload, conversationKey: convKey)
    }

    // MARK: - ECDH + HKDF

    /// NIP-44 step 1: ECDH shared_x (32-byte x coordinate) → HKDF-extract with
    /// salt "nip44-v2" → 32-byte conversation key. Symmetric: conv(a, B) == conv(b, A).
    /// `peerPubkey` is a 32-byte x-only (BIP-340) pubkey; it is converted to the
    /// 33-byte compressed form (0x02 prefix, even-Y) that P256K's ECDH requires.
    static func conversationKey(privateKey: Data, peerPubkey: Data) -> Data? {
        guard privateKey.count == 32, peerPubkey.count == 32 else { return nil }
        // BIP-340 x-only pubkeys use the even-Y representative, so the compressed
        // encoding is always 0x02 || x.
        var compressed = Data([0x02])
        compressed.append(peerPubkey)
        guard let priv = try? P256K.KeyAgreement.PrivateKey(dataRepresentation: privateKey),
              let pub = try? P256K.KeyAgreement.PublicKey(dataRepresentation: compressed) else {
            return nil
        }
        // sharedSecretFromKeyAgreement returns 33 bytes compressed (version + x).
        // NIP-44 needs the unhashed 32-byte x coordinate — drop the version byte.
        let shared = priv.sharedSecretFromKeyAgreement(with: pub, format: .compressed)
        let sharedBytes = shared.withUnsafeBytes { Data($0) }
        guard sharedBytes.count == 33 else { return nil }
        let sharedX = sharedBytes.dropFirst() // 32-byte x coordinate

        let salt = Data("nip44-v2".utf8)
        let prk = CryptoKit.HKDF<CryptoKit.SHA256>.extract(inputKeyMaterial: SymmetricKey(data: sharedX), salt: salt)
        return prk.withUnsafeBytes { Data($0) }
    }

    // MARK: - Message keys

    /// NIP-44 step 3: HKDF-expand(conversation_key, info=nonce, L=76) →
    /// (chacha_key[0..32], chacha_nonce[32..44], hmac_key[44..76]).
    static func messageKeys(conversationKey: Data, nonce: Data) -> (chachaKey: Data, chachaNonce: Data, hmacKey: Data)? {
        guard conversationKey.count == 32, nonce.count == 32 else { return nil }
        let okm = CryptoKit.HKDF<CryptoKit.SHA256>.expand(
            pseudoRandomKey: SymmetricKey(data: conversationKey),
            info: nonce,
            outputByteCount: 76
        )
        let bytes = okm.withUnsafeBytes { Data($0) }
        // Copy slices into fresh Data to avoid non-zero startIndex issues.
        return (Data(bytes[0..<32]), Data(bytes[32..<44]), Data(bytes[44..<76]))
    }

    // MARK: - Encrypt / Decrypt (conversation-key level)

    /// Encrypt with an explicit conversation key + nonce (for test-vector validation).
    static func encrypt(_ plaintext: String, conversationKey: Data, nonce: Data) -> String? {
        guard let (chachaKey, chachaNonce, hmacKey) = messageKeys(
            conversationKey: conversationKey, nonce: nonce
        ) else { return nil }
        let padded = pad(plaintext)
        guard !padded.isEmpty else { return nil }
        let ciphertext = ChaCha20.cipher(key: chachaKey, nonce: chachaNonce, data: padded)
        let mac = hmacAad(key: hmacKey, message: ciphertext, aad: nonce)
        var payload = Data()
        payload.append(0x02) // version
        payload.append(nonce)
        payload.append(ciphertext)
        payload.append(mac)
        return payload.base64EncodedString()
    }

    /// Decrypt with an explicit conversation key.
    static func decrypt(_ payload: String, conversationKey: Data) -> String? {
        guard payload.first != "#" else { return nil }
        guard let data = Data(base64Encoded: payload) else { return nil }
        guard data.count >= 99 else { return nil }
        let version = data[0]
        guard version == 2 else { return nil }
        // Copy slices into fresh Data to avoid non-zero startIndex issues.
        let nonce = Data(data[1..<33])
        let ciphertext = Data(data[33..<(data.count - 32)])
        let mac = Data(data[(data.count - 32)..<data.count])
        guard let (chachaKey, chachaNonce, hmacKey) = messageKeys(
            conversationKey: conversationKey, nonce: nonce
        ) else { return nil }
        let calculatedMac = hmacAad(key: hmacKey, message: ciphertext, aad: nonce)
        guard constantTimeEqual(calculatedMac, mac) else { return nil }
        let padded = ChaCha20.cipher(key: chachaKey, nonce: chachaNonce, data: ciphertext)
        return unpad(padded)
    }

    // MARK: - HMAC

    /// HMAC-SHA256 over (nonce || ciphertext) — AAD is the 32-byte nonce.
    static func hmacAad(key: Data, message: Data, aad: Data) -> Data {
        var combined = Data()
        combined.append(aad)
        combined.append(message)
        let mac = CryptoKit.HMAC<CryptoKit.SHA256>.authenticationCode(for: combined, using: SymmetricKey(data: key))
        return mac.withUnsafeBytes { Data($0) }
    }

    // MARK: - Padding

    /// NIP-44 padding: 2-byte u16 length prefix, then plaintext, then zero-pad
    /// to the next padded chunk size. NIP-44 v2 caps plaintext at 65535 bytes,
    /// so a 6-byte extended prefix is never needed.
    static func pad(_ plaintext: String) -> Data {
        let unpadded = Data(plaintext.utf8)
        let len = unpadded.count
        guard len >= 1, len <= 65535 else { return Data() }
        var out = Data()
        out.append(UInt8((len >> 8) & 0xFF))
        out.append(UInt8(len & 0xFF))
        out.append(unpadded)
        let paddedLen = calcPaddedLen(len)
        out.append(Data(repeating: 0, count: paddedLen - len))
        return out
    }

    /// Remove NIP-44 padding, returning the plaintext string.
    static func unpad(_ padded: Data) -> String? {
        guard padded.count >= 2 else { return nil }
        let unpaddedLen = (Int(padded[0]) << 8) | Int(padded[1])
        let prefixLen = 2
        guard unpaddedLen >= 1, unpaddedLen <= 65535,
              padded.count == prefixLen + calcPaddedLen(unpaddedLen) else { return nil }
        let unpadded = padded[prefixLen..<(prefixLen + unpaddedLen)]
        return String(data: unpadded, encoding: .utf8)
    }

    /// NIP-44 padded length calculation: powers-of-two chunking, min 32 bytes.
    static func calcPaddedLen(_ unpadded: Int) -> Int {
        if unpadded <= 32 { return 32 }
        let nextPower = 1 << (Int(floor(log2(Double(unpadded - 1)))) + 1)
        let chunk = nextPower <= 256 ? 32 : nextPower / 8
        return chunk * (Int(floor(Double(unpadded - 1) / Double(chunk))) + 1)
    }

    // MARK: - Helpers

    /// Cryptographically secure random bytes.
    static func randomBytes(_ count: Int) -> Data {
        var data = Data(count: count)
        _ = data.withUnsafeMutableBytes { buf -> Int32 in
            guard let base = buf.baseAddress else { return -1 }
            return SecRandomCopyBytes(kSecRandomDefault, count, base)
        }
        return data
    }

    // MARK: - Constant-time comparison

    static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<a.count { diff |= a[i] ^ b[i] }
        return diff == 0
    }
}

// MARK: - ChaCha20 (RFC 8439)
//
// Raw ChaCha20 stream cipher — NOT ChaChaPoly AEAD. NIP-44 uses ChaCha20 for
// encryption and HMAC-SHA256 separately for authentication. CryptoKit exposes
// only ChaChaPoly (AEAD), so the raw cipher is implemented here. ~80 lines,
// well-audited algorithm, no external dependency.

enum ChaCha20 {
    /// Encrypt/decrypt `data` (XOR is symmetric) with a 32-byte key and 12-byte
    /// nonce, counter starting at 0. Produces keystream blocks and XORs with data.
    static func cipher(key: Data, nonce: Data, data: Data) -> Data {
        var keyWords = [UInt32](repeating: 0, count: 8)
        key.withUnsafeBytes { ptr in
            for i in 0..<8 {
                keyWords[i] = ptr.loadUnaligned(fromByteOffset: i * 4, as: UInt32.self).littleEndian
            }
        }
        var nonceWords = [UInt32](repeating: 0, count: 3)
        nonce.withUnsafeBytes { ptr in
            for i in 0..<3 {
                nonceWords[i] = ptr.loadUnaligned(fromByteOffset: i * 4, as: UInt32.self).littleEndian
            }
        }

        var out = Data(count: data.count)
        var counter: UInt32 = 0
        var offset = 0
        let blockSize = 64

        while offset < data.count {
            let block = keystreamBlock(
                key: keyWords, nonce: nonceWords, counter: counter
            )
            let remaining = data.count - offset
            let toXOR = min(blockSize, remaining)
            for i in 0..<toXOR {
                out[offset + i] = data[offset + i] ^ block[i]
            }
            offset += toXOR
            counter &+= 1
        }
        return out
    }

    /// Generate one 64-byte ChaCha20 keystream block.
    private static func keystreamBlock(
        key: [UInt32], nonce: [UInt32], counter: UInt32
    ) -> [UInt8] {
        // State: constants(4) + key(8) + counter(1) + nonce(3) = 16 words
        var s = [
            UInt32(0x61707865), UInt32(0x3320646e), UInt32(0x79622d32), UInt32(0x6b206574),
            key[0], key[1], key[2], key[3],
            key[4], key[5], key[6], key[7],
            counter, nonce[0], nonce[1], nonce[2],
        ]
        let initial = s

        // 20 rounds = 10 double rounds (column + diagonal)
        for _ in 0..<10 {
            quarterRound(&s, 0, 4, 8, 12)
            quarterRound(&s, 1, 5, 9, 13)
            quarterRound(&s, 2, 6, 10, 14)
            quarterRound(&s, 3, 7, 11, 15)
            quarterRound(&s, 0, 5, 10, 15)
            quarterRound(&s, 1, 6, 11, 12)
            quarterRound(&s, 2, 7, 8, 13)
            quarterRound(&s, 3, 4, 9, 14)
        }

        // Add initial state, serialize as little-endian bytes
        var bytes = [UInt8](repeating: 0, count: 64)
        for i in 0..<16 {
            let word = (s[i] &+ initial[i]).littleEndian
            bytes[i * 4]     = UInt8(truncatingIfNeeded: word)
            bytes[i * 4 + 1] = UInt8(truncatingIfNeeded: word >> 8)
            bytes[i * 4 + 2] = UInt8(truncatingIfNeeded: word >> 16)
            bytes[i * 4 + 3] = UInt8(truncatingIfNeeded: word >> 24)
        }
        return bytes
    }

    @inline(__always)
    private static func quarterRound(_ s: inout [UInt32], _ a: Int, _ b: Int, _ c: Int, _ d: Int) {
        s[a] &+= s[b]; s[d] = rotateLeft(s[d] ^ s[a], 16)
        s[c] &+= s[d]; s[b] = rotateLeft(s[b] ^ s[c], 12)
        s[a] &+= s[b]; s[d] = rotateLeft(s[d] ^ s[a], 8)
        s[c] &+= s[d]; s[b] = rotateLeft(s[b] ^ s[c], 7)
    }

    @inline(__always)
    private static func rotateLeft(_ value: UInt32, _ bits: UInt32) -> UInt32 {
        (value << bits) | (value >> (32 - bits))
    }
}
