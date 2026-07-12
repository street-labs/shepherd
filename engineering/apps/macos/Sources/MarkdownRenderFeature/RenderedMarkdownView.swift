import SwiftUI
import Markdown

// Implements: FR-mdr-render-commonmark, FR-mdr-render-styling

/// SwiftUI view that renders a markdown AST as formatted content.
public struct RenderedMarkdownView: View {
    let ast: MarkdownAST

    public init(ast: MarkdownAST) {
        self.ast = ast
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<ast.document.childCount, id: \.self) { index in
                    if let child = ast.document.child(at: index) {
                        MarkupElementView(markup: child, elementMap: ast.elementMap)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Renders a single markup element.
private struct MarkupElementView: View {
    let markup: any Markup
    let elementMap: [String: MarkdownElement]

    var body: some View {
        Group {
            if let heading = markup as? Heading {
                HeadingView(heading: heading)
            } else if let paragraph = markup as? Paragraph {
                ParagraphView(paragraph: paragraph, elementMap: elementMap)
            } else if let codeBlock = markup as? CodeBlock {
                CodeBlockView(codeBlock: codeBlock)
            } else if let blockQuote = markup as? BlockQuote {
                BlockQuoteView(blockQuote: blockQuote, elementMap: elementMap)
            } else if let list = markup as? UnorderedList {
                UnorderedListView(list: list, elementMap: elementMap)
            } else if let list = markup as? OrderedList {
                OrderedListView(list: list, elementMap: elementMap)
            } else if let table = markup as? Markdown.Table {
                TableView(table: table, elementMap: elementMap)
            } else if markup is ThematicBreak {
                ThematicBreakView()
            } else {
                // Unsupported markup type - render nothing
                EmptyView()
            }
        }
    }
}

// MARK: - Heading

private struct HeadingView: View {
    let heading: Heading

    var body: some View {
        Text(heading.plainText)
            .font(fontForLevel(heading.level))
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        case 5: return .headline
        default: return .subheadline
        }
    }
}

// MARK: - Paragraph

private struct ParagraphView: View {
    let paragraph: Paragraph
    let elementMap: [String: MarkdownElement]

    var body: some View {
        InlineContentView(inlines: Array(paragraph.inlineChildren), elementMap: elementMap)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inline Content

private struct InlineContentView: View {
    let inlines: [any InlineMarkup]
    let elementMap: [String: MarkdownElement]

    var body: some View {
        inlines.map { inline in
            formatInline(inline)
        }
        .reduce(SwiftUI.Text(""), +)
    }

    private func formatInline(_ inline: any InlineMarkup) -> SwiftUI.Text {
        if let text = inline as? Markdown.Text {
            return SwiftUI.Text(text.string)
        } else if let strong = inline as? Strong {
            return strong.inlineChildren
                .map { formatInline($0) }
                .reduce(SwiftUI.Text(""), +)
                .bold()
        } else if let emphasis = inline as? Emphasis {
            return emphasis.inlineChildren
                .map { formatInline($0) }
                .reduce(SwiftUI.Text(""), +)
                .italic()
        } else if let code = inline as? InlineCode {
            return SwiftUI.Text(code.code)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        } else if let strikethrough = inline as? Strikethrough {
            return strikethrough.inlineChildren
                .map { formatInline($0) }
                .reduce(SwiftUI.Text(""), +)
                .strikethrough()
        } else if let link = inline as? Markdown.Link {
            return link.inlineChildren
                .map { formatInline($0) }
                .reduce(SwiftUI.Text(""), +)
                .foregroundColor(Color.blue)
                .underline()
        } else if inline is SoftBreak {
            return SwiftUI.Text(" ")
        } else if inline is LineBreak {
            return SwiftUI.Text("\n")
        } else {
            // Fallback for other inline types
            return SwiftUI.Text("")
        }
    }
}

// MARK: - Code Block

private struct CodeBlockView: View {
    let codeBlock: CodeBlock

    var body: some View {
        Text(codeBlock.code)
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
            .cornerRadius(6)
    }
}

// MARK: - Block Quote

private struct BlockQuoteView: View {
    let blockQuote: BlockQuote
    let elementMap: [String: MarkdownElement]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<blockQuote.childCount, id: \.self) { index in
                    if let child = blockQuote.child(at: index) {
                        MarkupElementView(markup: child, elementMap: elementMap)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Lists

private struct UnorderedListView: View {
    let list: UnorderedList
    let elementMap: [String: MarkdownElement]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                ListItemView(item: item, ordered: false, index: 0, elementMap: elementMap)
            }
        }
    }
}

private struct OrderedListView: View {
    let list: OrderedList
    let elementMap: [String: MarkdownElement]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                ListItemView(item: item, ordered: true, index: index + 1, elementMap: elementMap)
            }
        }
    }
}

private struct ListItemView: View {
    let item: ListItem
    let ordered: Bool
    let index: Int
    let elementMap: [String: MarkdownElement]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(bulletText)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<item.childCount, id: \.self) { index in
                    if let child = item.child(at: index) {
                        MarkupElementView(markup: child, elementMap: elementMap)
                    }
                }
            }
        }
    }

    private var bulletText: String {
        if isTaskListItem {
            return isTaskChecked ? "☑" : "☐"
        } else if ordered {
            return "\(index)."
        } else {
            return "•"
        }
    }

    private var isTaskListItem: Bool {
        let text = item.format()
        return text.contains("[ ]") || text.contains("[x]") || text.contains("[X]")
    }

    private var isTaskChecked: Bool {
        let text = item.format()
        return text.contains("[x]") || text.contains("[X]")
    }
}

// MARK: - Table

private struct TableView: View {
    let table: Markdown.Table
    let elementMap: [String: MarkdownElement]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TableHeadView(head: table.head, elementMap: elementMap)

            TableBodyView(tableBody: table.body, elementMap: elementMap)
        }
        .overlay(
            Rectangle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct TableHeadView: View {
    let head: Markdown.Table.Head
    let elementMap: [String: MarkdownElement]

    var body: some View {
        if let row = head.child(at: 0) as? Markdown.Table.Row {
            HStack(spacing: 0) {
                ForEach(0..<row.childCount, id: \.self) { index in
                    if let cell = row.child(at: index) as? Markdown.Table.Cell {
                        TableCellView(cell: cell, elementMap: elementMap, isHeader: true)
                    }
                }
            }
            .background(Color.secondary.opacity(0.1))
        }
    }
}

private struct TableBodyView: View {
    let tableBody: Markdown.Table.Body
    let elementMap: [String: MarkdownElement]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<tableBody.childCount, id: \.self) { index in
                if let row = tableBody.child(at: index) as? Markdown.Table.Row {
                    HStack(spacing: 0) {
                        ForEach(0..<row.childCount, id: \.self) { cellIndex in
                            if let cell = row.child(at: cellIndex) as? Markdown.Table.Cell {
                                TableCellView(cell: cell, elementMap: elementMap, isHeader: false)
                            }
                        }
                    }
                    .overlay(
                        Rectangle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5),
                        alignment: .top
                    )
                }
            }
        }
    }
}

private struct TableCellView: View {
    let cell: Markdown.Table.Cell
    let elementMap: [String: MarkdownElement]
    let isHeader: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<cell.childCount, id: \.self) { index in
                if let child = cell.child(at: index) {
                    MarkupElementView(markup: child, elementMap: elementMap)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fontWeight(isHeader ? .semibold : .regular)
        .overlay(
            Rectangle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5),
            alignment: .trailing
        )
    }
}

// MARK: - Thematic Break

private struct ThematicBreakView: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}
