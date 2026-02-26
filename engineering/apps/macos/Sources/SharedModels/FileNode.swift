import Foundation
import IdentifiedCollections

/// A loaded file in the review session.
/// Implements: FR-crp-file-load, FR-crp-file-display, FR-crp-multi-file-load
public struct FileNode: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// File name, or "Untitled" if pasted without a name.
    public var name: String
    /// Full file path from the file system. Nil for pasted content.
    public var filePath: String?
    /// Detected programming language.
    public var language: SyntaxLanguage
    /// The raw file content as a single string.
    public let content: String
    /// The content split into individual lines. Derived from `content`.
    public let lines: [String]
    /// Whether the user has marked this file as reviewed.
    /// Implements: FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-persistence
    public var isReviewed: Bool
    /// Cached scroll position (line index) for restoring on file switch.
    public var scrollOffset: Int

    public init(
        id: UUID = UUID(),
        name: String,
        filePath: String? = nil,
        language: SyntaxLanguage = .plaintext,
        content: String,
        lines: [String]? = nil,
        isReviewed: Bool = false,
        scrollOffset: Int = 0
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.language = language
        self.content = content
        self.lines = lines ?? content.components(separatedBy: "\n")
        self.isReviewed = isReviewed
        self.scrollOffset = scrollOffset
    }
}
