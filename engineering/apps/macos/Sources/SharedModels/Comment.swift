import Foundation

/// A single inline comment attached to one or more lines of a specific file.
/// Implements: FR-crp-line-comment-create, FR-crp-line-range-comment
public struct Comment: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// The file this comment belongs to.
    public let fileID: FileNode.ID
    /// First line of the commented range (1-indexed).
    public let startLine: Int
    /// Last line of the commented range (1-indexed). Same as startLine for single-line comments.
    public let endLine: Int
    /// The user's comment text.
    public var text: String
    /// Timestamp of creation. Used for stable ordering when line numbers are equal.
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        fileID: FileNode.ID,
        startLine: Int,
        endLine: Int,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileID = fileID
        self.startLine = startLine
        self.endLine = endLine
        self.text = text
        self.createdAt = createdAt
    }
}
