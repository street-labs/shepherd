import Foundation

/// A syntax token produced by syntax highlighting.
public struct SyntaxToken: Equatable, Sendable {
    public let range: Range<String.Index>
    public let type: TokenType

    public init(range: Range<String.Index>, type: TokenType) {
        self.range = range
        self.type = type
    }

    public enum TokenType: String, Equatable, Sendable {
        case keyword
        case string
        case comment
        case number
        case type
        case function
        case property
        case variable
        case `operator`
        case punctuation
        case plain
    }
}
