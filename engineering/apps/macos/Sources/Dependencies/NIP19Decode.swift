import Foundation

/// Minimal NIP-19 bech32 decoder for `nevent1` references.
/// Implements: FR-srm-patch-open-input (the `nevent1` decoding half).
///
/// Decodes a `nevent1…` entity to its referenced event id (32-byte id, hex) and
/// any recommended relay URLs encoded in the TLV. Reuses the bech32 alphabet and
/// checksum logic already in `Bech32.swift`. `naddr1` is not supported — NIP-34
/// patch events are kind `1617` (non-parameterized) with no `naddr` form; see
/// `FR-srm-patch-open-input`.
public enum NIP19Decode {
    /// A decoded `nevent1` reference.
    public struct NEvent: Equatable, Sendable {
        /// The referenced event id as a 64-character lowercase hex string.
        public let eventID: String
        /// Recommended relay URLs carried in the entity's TLVs (may be empty).
        public let relays: [String]
        public init(eventID: String, relays: [String]) {
            self.eventID = eventID
            self.relays = relays
        }
    }

    /// Decode a `nevent1…` string. Returns nil if the string is not a valid
    /// `nevent` entity (wrong prefix, bad checksum, malformed TLVs, or missing
    /// the 32-byte event id).
    public static func decodeNEvent(_ s: String) -> NEvent? {
        guard let (prefix, data) = Bech32.decode(s), prefix == "nevent" else {
            return nil
        }
        let bytes = [UInt8](data)
        var index = 0
        var eventID: String? = nil
        var relays: [String] = []
        // NIP-19 TLV stream: [type:u8, length:u8, value:length bytes]…
        // (NIP-19: "T and L being 1 byte each (uint8), V a sequence of bytes of
        // the size indicated by L".) A 2-byte length would make every real
        // nevent1 fail to decode.
        while index + 2 <= bytes.count {
            let type = bytes[index]
            let len = Int(bytes[index + 1])
            index += 2
            guard index + len <= bytes.count else { return nil }
            let value = Array(bytes[index..<index + len])
            index += len
            switch type {
            case 0: // 32-byte event id
                guard value.count == 32 else { return nil }
                eventID = value.map { String(format: "%02x", $0) }.joined()
            case 1: // recommended relay URL (UTF-8)
                if let url = String(bytes: value, encoding: .utf8), !url.isEmpty {
                    relays.append(url)
                }
            default:
                break // ignore unknown TLV types (author, kind, …)
            }
        }
        guard let eventID else { return nil }
        return NEvent(eventID: eventID, relays: relays)
    }

    /// Decode an `npub1…` string to its 32-byte pubkey (64-char lowercase hex).
    /// Implements the input half of `FR-pb-npub-list`.
    public static func decodeNPub(_ s: String) -> String? {
        guard let (prefix, data) = Bech32.decode(s), prefix == "npub", data.count == 32 else {
            return nil
        }
        return [UInt8](data).map { String(format: "%02x", $0) }.joined()
    }
}
