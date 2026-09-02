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

    /// Implements: FR-mdr-detect-markdown
    /// Returns true if this file is a markdown file based on its extension.
    public var isMarkdownFile: Bool {
        let markdownExtensions = ["md", "markdown", "mdown", "mkdn", "mkd"]
        guard let ext = name.components(separatedBy: ".").last?.lowercased() else {
            return false
        }
        return markdownExtensions.contains(ext)
    }
}

extension FileNode {
    /// True when this node's content is a unified diff rather than a whole file —
    /// a changeset review launched with `--diff`, a NIP-34 patch, or a PR.
    /// Implements: FR-diff-display
    public var isDiff: Bool { content.hasPrefix("diff --git ") }
}

/// The kind of a single line within a unified diff, used to tint the line.
/// Implements: FR-diff-display, NFR-diff-accessibility
public enum DiffLineKind: Equatable, Sendable {
    case added
    case removed
    /// File header, `index`/mode line, or `@@` hunk boundary.
    case header
    case context

    public init(line: String) {
        // Header prefixes are checked first: `+++`/`---` would otherwise read as
        // an added/removed line.
        let headerPrefixes = [
            "+++", "---", "@@", "diff --git ", "index ", "new file mode",
            "deleted file mode", "similarity index", "rename ", "old mode", "new mode",
            "Binary files ", "\\ No newline",
        ]
        if headerPrefixes.contains(where: line.hasPrefix) {
            self = .header
        } else if line.hasPrefix("+") {
            self = .added
        } else if line.hasPrefix("-") {
            self = .removed
        } else {
            self = .context
        }
    }
}
