import Foundation
import Markdown

// Implements: FR-mdr-render-commonmark, FR-mdr-element-id

/// Parses markdown source into an AST with stable element IDs and source range mappings.
public struct MarkdownParser {

    /// Parse markdown source into a structured AST with element identifiers.
    public static func parse(_ source: String) -> MarkdownAST {
        let document = Document(parsing: source)

        // Walk the AST and assign stable IDs to block-level elements
        var walker = ElementIDWalker()
        walker.visit(document)

        return MarkdownAST(document: document, elementMap: walker.elementMap)
    }
}

/// Represents a parsed markdown document with element ID mapping.
public struct MarkdownAST: Equatable {
    public let document: Document
    public let elementMap: [String: MarkdownElement]

    public init(document: Document, elementMap: [String: MarkdownElement]) {
        self.document = document
        self.elementMap = elementMap
    }

    public static func == (lhs: MarkdownAST, rhs: MarkdownAST) -> Bool {
        // Compare by element map keys (document comparison is non-trivial)
        Set(lhs.elementMap.keys) == Set(rhs.elementMap.keys)
    }
}

/// Represents a single markdown element with its stable identifier and source range.
public struct MarkdownElement: Equatable, Hashable {
    public let id: String
    public let node: any Markup
    public let sourceRange: SourceRange?

    public init(id: String, node: any Markup, sourceRange: SourceRange?) {
        self.id = id
        self.node = node
        self.sourceRange = sourceRange
    }

    public static func == (lhs: MarkdownElement, rhs: MarkdownElement) -> Bool {
        lhs.id == rhs.id && lhs.sourceRange == rhs.sourceRange
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(sourceRange)
    }
}

/// Source range in the original markdown document.
public struct SourceRange: Equatable, Hashable {
    public let startLine: Int
    public let endLine: Int

    public init(startLine: Int, endLine: Int) {
        self.startLine = startLine
        self.endLine = endLine
    }
}

/// AST walker that assigns stable IDs to block-level elements.
private struct ElementIDWalker: MarkupWalker {
    var elementMap: [String: MarkdownElement] = [:]
    var elementCounter: [String: Int] = [:]

    mutating func visitHeading(_ heading: Heading) -> () {
        assignID(to: heading, prefix: "heading")
        descendInto(heading)
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> () {
        assignID(to: paragraph, prefix: "paragraph")
        descendInto(paragraph)
    }

    mutating func visitListItem(_ listItem: ListItem) -> () {
        assignID(to: listItem, prefix: "list-item")
        descendInto(listItem)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> () {
        assignID(to: codeBlock, prefix: "code-block")
        // Don't descend into code blocks (leaf node)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        assignID(to: blockQuote, prefix: "blockquote")
        descendInto(blockQuote)
    }

    mutating func visitTable(_ table: Table) -> () {
        assignID(to: table, prefix: "table")
        descendInto(table)
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> () {
        assignID(to: thematicBreak, prefix: "thematic-break")
    }

    mutating func visitImage(_ image: Image) -> () {
        assignID(to: image, prefix: "image")
        descendInto(image)
    }

    private mutating func assignID(to node: any Markup, prefix: String) {
        let count = elementCounter[prefix, default: 0]
        let id = "\(prefix)-\(count)"
        elementCounter[prefix] = count + 1

        let sourceRange = node.range.map { range in
            SourceRange(
                startLine: range.lowerBound.line,
                endLine: range.upperBound.line
            )
        }

        let element = MarkdownElement(id: id, node: node, sourceRange: sourceRange)
        elementMap[id] = element
    }
}
