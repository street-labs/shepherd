import Foundation

/// Structured review context data passed from the shepherd-review command.
/// Implements: FR-crp-review-context-receive
public struct ReviewContext: Equatable, Codable, Sendable {
    /// Overall changeset context (neutral description + agent's review feedback).
    public var overall: ContextPair
    /// Per-file context, keyed by file path.
    public var files: [String: ContextPair]

    public init(overall: ContextPair = ContextPair(), files: [String: ContextPair] = [:]) {
        self.overall = overall
        self.files = files
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
}
