import Foundation
import CryptoKit

/// A Nostr event as received from a relay.
/// Implements: FR-sr-relay-client
/// Minimal subset of NIP-01 needed for patch-thread reply mapping: identity,
/// kind, content, tags, and creation timestamp. Used by `RelayClient` and
/// `PatchReplyMapper` to drive live patch-thread replies in-app. The signing
/// extension (`sign(secretKey:)`) lives alongside `NostrSigner` in
/// ShepherdDependencies so the secp256k1 dependency stays out of the pure-model
/// target; the pure id computation (`computedID`) lives here.
public struct NostrEvent: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var pubkey: String
    public var kind: Int
    public var content: String
    public var tags: [[String]]
    public var createdAt: Int64
    public var sig: String

    enum CodingKeys: String, CodingKey {
        case id, pubkey, kind, content, tags
        case createdAt = "created_at"
        case sig
    }

    public init(id: String, pubkey: String, kind: Int, content: String, tags: [[String]], createdAt: Int64, sig: String = "") {
        self.id = id
        self.pubkey = pubkey
        self.kind = kind
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.sig = sig
    }

    /// Canonical NIP-01 serialization of the event array used to compute the id:
    /// `[0, pubkey, created_at, kind, tags, content]` with compact JSON (no
    /// whitespace, no slash escaping). Matches `JSON.stringify` / go-nostr.
    /// Implements: FR-srm-event-sign (id computation, pure half).
    public func canonicalSerialization() -> String {
        var s = "[0,\"\(NostrEvent.escape(pubkey))\",\(createdAt),\(kind),"
        s += "[" + tags.map { tag in
            "[" + tag.map { "\"\(NostrEvent.escape($0))\"" }.joined(separator: ",") + "]"
        }.joined(separator: ",") + "]"
        s += ",\"\(NostrEvent.escape(content))\"]"
        return s
    }

    /// SHA-256 of the canonical serialization, hex-encoded. This is the NIP-01 event id.
    public var computedID: String {
        let bytes = SHA256.hash(data: Data(canonicalSerialization().utf8))
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// JSON string escaping matching JS `JSON.stringify` for the values Nostr uses:
    /// escapes `"`, `\`, the named control chars, and other control chars as
    /// `\u00XX`. Does NOT escape `/`, `<`, `>`, `&`, or non-ASCII.
    static func escape(_ s: String) -> String {
        var out = ""
        for scalar in s.unicodeScalars {
            switch scalar.value {
            case 0x22: out += "\\\""
            case 0x5C: out += "\\\\"
            case 0x0A: out += "\\n"
            case 0x0D: out += "\\r"
            case 0x09: out += "\\t"
            case 0x08: out += "\\b"
            case 0x0C: out += "\\f"
            case 0..<0x20: out += String(format: "\\u%04x", scalar.value)
            default: out += String(scalar)
            }
        }
        return out
    }
}
