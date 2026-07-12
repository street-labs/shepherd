import Foundation

/// Structured review context data passed from the shepherd-review command.
/// Implements: FR-crp-review-context-receive, FR-sr-patch-metadata-display
public struct ReviewContext: Equatable, Codable, Sendable {
    /// Overall changeset context (neutral description + agent's review feedback).
    public var overall: ContextPair
    /// Per-file context, keyed by file path.
    public var files: [String: ContextPair]
    /// NIP-34 patch metadata (present only when reviewing a Nostr patch).
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

        public init(
            eventID: String,
            shortEventID: String,
            author: String,
            commitMessage: String,
            parentCommit: String?,
            status: String
        ) {
            self.eventID = eventID
            self.shortEventID = shortEventID
            self.author = author
            self.commitMessage = commitMessage
            self.parentCommit = parentCommit
            self.status = status
        }
    }
}
