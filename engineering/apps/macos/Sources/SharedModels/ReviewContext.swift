import Foundation

/// Structured review context data passed from the shepherd-review command.
/// Implements: FR-crp-review-context-receive, FR-sr-patch-metadata-display
public struct ReviewContext: Equatable, Codable, Sendable {
    /// Overall changeset context (neutral description + agent's review feedback).
    public var overall: ContextPair
    /// Per-file context, keyed by file path.
    public var files: [String: ContextPair]
    /// NIP-34 patch metadata (present only when reviewing a Nostr patch).
    /// Carries the patch's own metadata plus the live review-thread replies from
    /// other agents/humans (FR-sr-patch-replies-display).
    public var patchMetadata: PatchMetadata?

    public init(
        overall: ContextPair = ContextPair(),
        files: [String: ContextPair] = [:],
        patchMetadata: PatchMetadata? = nil
    ) {
        self.overall = overall
        self.files = files
        self.patchMetadata = patchMetadata
    }

    public struct ContextPair: Equatable, Codable, Sendable {
        /// Factual description of what changed.
        public var neutral: String
        /// The AI agent's assessment and opinions.
        public var review: String

        public init(neutral: String = "", review: String = "") {
            self.neutral = neutral
            self.review = review
        }
    }

    /// NIP-34 patch metadata for Nostr patch reviews.
    public struct PatchMetadata: Equatable, Codable, Sendable {
        /// Full 64-character Nostr event ID.
        public var eventID: String
        /// Short 8-character event ID for display.
        public var shortEventID: String
        /// Patch author (resolved name or truncated npub).
        public var author: String
        /// First line of commit message (truncated to 60 chars if longer).
        public var commitMessage: String
        /// Parent commit short hash (8 chars), or null if initial commit.
        public var parentCommit: String?
        /// Patch status: open, merged, closed, or draft.
        public var status: String
        /// Replies on the patch review thread from other agents/humans (NIP-34 live
        /// review loop). Implements: FR-sr-patch-replies-display. Read-only
        /// conversation context, not user-editable comments. Empty when no replies.
        public var replies: [PatchReply]

        public init(
            eventID: String,
            shortEventID: String,
            author: String,
            commitMessage: String,
            parentCommit: String?,
            status: String,
            replies: [PatchReply] = []
        ) {
            self.eventID = eventID
            self.shortEventID = shortEventID
            self.author = author
            self.commitMessage = commitMessage
            self.parentCommit = parentCommit
            self.status = status
            self.replies = replies
        }

        // Back-compat: older payloads (pre FR-sr-patch-replies-display) omit
        // `replies`. decodeIfPresent lets them decode to an empty array rather than
        // throwing a keyNotFound.
        private enum CodingKeys: String, CodingKey {
            case eventID, shortEventID, author, commitMessage
            case parentCommit, status, replies
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.eventID = try c.decode(String.self, forKey: .eventID)
            self.shortEventID = try c.decode(String.self, forKey: .shortEventID)
            self.author = try c.decode(String.self, forKey: .author)
            self.commitMessage = try c.decode(String.self, forKey: .commitMessage)
            self.parentCommit = try c.decodeIfPresent(String.self, forKey: .parentCommit)
            self.status = try c.decode(String.self, forKey: .status)
            self.replies = try c.decodeIfPresent([PatchReply].self, forKey: .replies) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(eventID, forKey: .eventID)
            try c.encode(shortEventID, forKey: .shortEventID)
            try c.encode(author, forKey: .author)
            try c.encode(commitMessage, forKey: .commitMessage)
            try c.encodeIfPresent(parentCommit, forKey: .parentCommit)
            try c.encode(status, forKey: .status)
            try c.encode(replies, forKey: .replies)
        }
    }

    /// A reply on the patch review thread from another agent or human.
    /// Implements: FR-sr-patch-replies-display. Read-only conversation context;
    /// not user-editable. Distinguished from local Comment by `isBot` and a fixed
    /// author identity rather than a UUID-owned user comment.
    public struct PatchReply: Equatable, Codable, Sendable, Identifiable {
        /// Stable identity for SwiftUI ForEach. Derived from the Nostr event id when
        /// available, else a synthetic hash of author+content+timestamp.
        public var id: String
        /// Resolved display name (NIP-05 / profile name) or truncated npub.
        public var author: String
        /// Raw author pubkey (bech32 npub or hex) for identity tagging.
        public var authorPubkey: String
        /// True when the author is a bot/agent, false for human comments. Drives the
        /// visual marker in the UI.
        public var isBot: Bool
        /// The reply text (kind:1 note content).
        public var content: String
        /// Creation timestamp of the reply event (seconds since epoch).
        public var timestamp: Int64
        /// Optional line-range anchor. When present, the reply is also rendered inline
        /// on the diff at this file + line range.
        public var lineAnchor: LineAnchor?

        public init(
            id: String,
            author: String,
            authorPubkey: String,
            isBot: Bool,
            content: String,
            timestamp: Int64,
            lineAnchor: LineAnchor? = nil
        ) {
            self.id = id
            self.author = author
            self.authorPubkey = authorPubkey
            self.isBot = isBot
            self.content = content
            self.timestamp = timestamp
            self.lineAnchor = lineAnchor
        }

        /// A line-range anchor pinning a reply to a specific file + line span.
        /// Path keys match the absolute path strings in `session.json.files[].path`.
        public struct LineAnchor: Equatable, Codable, Sendable {
            public var filePath: String
            public var startLine: Int
            public var endLine: Int

            public init(filePath: String, startLine: Int, endLine: Int) {
                self.filePath = filePath
                self.startLine = startLine
                self.endLine = endLine
            }
        }
    }
}
