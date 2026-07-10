import Foundation

// Implements: FR-mdr-render-toggle

/// The rendering mode for markdown files.
public enum MarkdownRenderMode: String, Equatable, Sendable, CaseIterable {
    /// Show raw markdown source with syntax highlighting
    case raw

    /// Show rendered markdown with formatted elements
    case rendered

    public var displayName: String {
        switch self {
        case .raw: return "Raw"
        case .rendered: return "Rendered"
        }
    }
}
