import ComposableArchitecture
import SharedModels

/// Syntax highlighting client.
/// Implements: FR-crp-syntax-highlight
///
/// Note: Returns empty tokens for now (no TreeSitter). Plain text display only.
/// TreeSitter integration will be added in a future iteration.
public struct SyntaxHighlightClient: Sendable {
    /// Highlight a file's content, returning an array of syntax tokens.
    public var highlight: @Sendable (String, SyntaxLanguage) async -> [SyntaxToken]

    public init(
        highlight: @escaping @Sendable (String, SyntaxLanguage) async -> [SyntaxToken]
    ) {
        self.highlight = highlight
    }
}

extension SyntaxHighlightClient: DependencyKey {
    public static let liveValue = SyntaxHighlightClient(
        highlight: { content, language in
            SyntaxHighlighter.highlight(content, language: language)
        }
    )

    public static let testValue = SyntaxHighlightClient(
        highlight: { _, _ in [] }
    )
}

extension DependencyValues {
    public var syntaxHighlightClient: SyntaxHighlightClient {
        get { self[SyntaxHighlightClient.self] }
        set { self[SyntaxHighlightClient.self] = newValue }
    }
}
