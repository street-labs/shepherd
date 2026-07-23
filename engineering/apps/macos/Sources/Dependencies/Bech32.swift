import Foundation

/// Minimal BIP-173 bech32 encoder/decoder for NIP-19 (`npub`/`nsec`).
/// NIP-19 uses bech32 (constant 1) with 32-byte payloads. Implements the
/// 8-bit → 5-bit regrouping and the standard checksum. Used by `IdentityClient`
/// to decode `nsec1...` secret keys and encode `npub1...` for display.
public enum Bech32 {
    private static let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    private static let charsetMap: [Character: UInt8] = {
        Dictionary(uniqueKeysWithValues: Array(charset).enumerated().map { ($1, UInt8($0)) })
    }()

    /// Encode `data` (bytes) with the given human-readable prefix (e.g. "npub").
    /// Returns the bech32 string (`<prefix>1<5bit-groups><checksum>`).
    public static func encode(_ data: Data, prefix: String) -> String {
        // 8-bit -> 5-bit with padding never fails for byte input (0..<256 < 1<<8).
        let fiveBit = convertBits(data: [UInt8](data), fromBits: 8, toBits: 5, pad: true) ?? []
        let checksum = createChecksum(prefix: prefix, fiveBit: fiveBit)
        let combined = fiveBit + checksum
        var result = prefix + "1"
        for v in combined { result.append(charset[charset.index(charset.startIndex, offsetBy: Int(v))]) }
        return result
    }

    /// Decode a bech32 string into `(prefix, data-bytes)`. Returns nil on invalid
    /// checksum / format / mixed case.
    public static func decode(_ s: String) -> (prefix: String, data: Data)? {
        // Mixed case is invalid.
        let isLower = s == s.lowercased()
        let isUpper = s == s.uppercased()
        guard isLower || isUpper else { return nil }
        let str = s.lowercased()
        guard let sep = str.lastIndex(of: "1"), sep != str.startIndex else { return nil }
        let prefix = String(str[..<sep])
        let dataPart = String(str[str.index(after: sep)...])
        guard !dataPart.isEmpty, !prefix.isEmpty else { return nil }
        var fiveBit: [UInt8] = []
        for ch in dataPart {
            guard let v = charsetMap[ch] else { return nil }
            fiveBit.append(v)
        }
        guard verifyChecksum(prefix: prefix, fiveBit: fiveBit) else { return nil }
        // Drop the 6-char checksum.
        let payload = Array(fiveBit.dropLast(6))
        guard let bytes = convertBits(data: payload, fromBits: 5, toBits: 8, pad: false) else {
            return nil
        }
        return (prefix, Data(bytes))
    }

    // MARK: - bit conversion

    private static func convertBits(data: [UInt8], fromBits: UInt8, toBits: UInt8, pad: Bool) -> [UInt8]? {
        var acc: UInt32 = 0
        var bits: UInt8 = 0
        var out: [UInt8] = []
        let maxv: UInt32 = (1 << toBits) - 1
        for value in data {
            guard UInt32(value) < (1 << fromBits) else { return nil }
            acc = (acc << fromBits) | UInt32(value)
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                out.append(UInt8((acc >> bits) & maxv))
            }
        }
        if pad {
            if bits > 0 {
                out.append(UInt8((acc << (toBits - bits)) & maxv))
            }
        } else if bits >= fromBits || (acc << (toBits - bits)) & maxv != 0 {
            return nil
        }
        return out
    }

    // MARK: - checksum

    private static func polymod(_ values: [UInt8]) -> UInt32 {
        let gen: [UInt32] = [0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3]
        var chk: UInt32 = 1
        for v in values {
            let top = chk >> 25
            chk = ((chk & 0x1FFFFFF) << 5) ^ UInt32(v)
            for i in 0..<5 {
                if (top >> i) & 1 != 0 { chk ^= gen[i] }
            }
        }
        return chk
    }

    private static func expandHRP(_ hrp: String) -> [UInt8] {
        let lo = hrp.unicodeScalars.map { UInt8($0.value & 0x1F) }
        let hi = hrp.unicodeScalars.map { UInt8($0.value >> 5) }
        return hi + [0] + lo
    }

    private static func createChecksum(prefix: String, fiveBit: [UInt8]) -> [UInt8] {
        let values = expandHRP(prefix) + fiveBit + [0, 0, 0, 0, 0, 0]
        let mod = polymod(values) ^ 1
        var ret: [UInt8] = []
        for i in 0..<6 {
            ret.append(UInt8((mod >> (5 * (5 - i))) & 0x1F))
        }
        return ret
    }

    private static func verifyChecksum(prefix: String, fiveBit: [UInt8]) -> Bool {
        polymod(expandHRP(prefix) + fiveBit) == 1
    }
}
