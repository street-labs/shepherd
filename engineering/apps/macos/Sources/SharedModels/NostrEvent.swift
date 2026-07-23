import Foundation

/// A Nostr event as received from a relay.
/// Implements: FR-sr-relay-client
/// Minimal subset of NIP-01 needed for patch-thread reply mapping: identity,
/// kind, content, tags, and creation timestamp. Used by `RelayClient` and
/// `PatchReplyMapper` to drive live patch-thread replies in-app.
public struct NostrEvent: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var pubkey: String
    public var kind: Int
    public var content: String
    public var tags: [[String]]
    public var createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, pubkey, kind, content, tags
        case createdAt = "created_at"
    }

    public init(id: String, pubkey: String, kind: Int, content: String, tags: [[String]], createdAt: Int64) {
        self.id = id
        self.pubkey = pubkey
        self.kind = kind
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
    }
}
