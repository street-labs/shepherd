import Testing
@testable import MarkdownRenderFeature

@Suite("RenderedMarkdownView Tests")
struct RenderedMarkdownViewTests {

    @Test("Parse markdown for rendering - basic")
    func parseBasicMarkdown() {
        let source = """
        # Heading

        This is a paragraph with **bold** and *italic* text.

        ## Subheading

        - Item 1
        - Item 2
        - Item 3
        """

        let ast = MarkdownParser.parse(source)

        // Verify AST contains expected elements for rendering
        #expect(ast.elementMap.count > 0)
        #expect(ast.elementMap["heading-0"] != nil)
        #expect(ast.elementMap["heading-1"] != nil)
        #expect(ast.elementMap["paragraph-0"] != nil)
        #expect(ast.elementMap["list-item-0"] != nil)
    }

    @Test("Parse markdown for rendering - code blocks")
    func parseCodeBlocks() {
        let source = """
        ```swift
        let x = 42
        print(x)
        ```
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["code-block-0"] != nil)
    }

    @Test("Parse markdown for rendering - blockquotes")
    func parseBlockquotes() {
        let source = """
        > This is a quote.
        > It has multiple lines.
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["blockquote-0"] != nil)
    }

    @Test("Parse markdown for rendering - task lists")
    func parseTaskLists() {
        let source = """
        - [ ] Unchecked task
        - [x] Checked task
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap.count > 0)
        #expect(ast.elementMap["list-item-0"] != nil)
    }

    @Test("Parse markdown for rendering - tables")
    func parseTables() {
        let source = """
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["table-0"] != nil)
    }

    @Test("Parse markdown for rendering - mixed content")
    func parseMixedContent() {
        let source = """
        # Title

        Introduction with **bold** text.

        - Point 1
        - Point 2

        ```python
        print("hello")
        ```

        > A quote

        ---

        Conclusion.
        """

        let ast = MarkdownParser.parse(source)

        // Should have various elements for rendering
        #expect(ast.elementMap["heading-0"] != nil)
        #expect(ast.elementMap["paragraph-0"] != nil)
        #expect(ast.elementMap["list-item-0"] != nil)
        #expect(ast.elementMap["code-block-0"] != nil)
        #expect(ast.elementMap["blockquote-0"] != nil)
        #expect(ast.elementMap["thematic-break-0"] != nil)
    }

    @Test("Parse markdown for rendering - empty document")
    func parseEmptyDocument() {
        let source = ""

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap.isEmpty)
    }

    @Test("Parse markdown for rendering - nested lists")
    func parseNestedLists() {
        let source = """
        - Item 1
          - Nested 1
          - Nested 2
        - Item 2
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap.count >= 2)
    }

    @Test("Parse markdown for rendering - ordered lists")
    func parseOrderedLists() {
        let source = """
        1. First
        2. Second
        3. Third
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["list-item-0"] != nil)
        #expect(ast.elementMap["list-item-1"] != nil)
        #expect(ast.elementMap["list-item-2"] != nil)
    }

    @Test("Parse markdown for rendering - inline code")
    func parseInlineCode() {
        let source = """
        Use `code` inline.
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["paragraph-0"] != nil)
    }

    @Test("Parse markdown for rendering - strikethrough")
    func parseStrikethrough() {
        let source = """
        This is ~~strikethrough~~ text.
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["paragraph-0"] != nil)
    }

    @Test("Parse markdown for rendering - links")
    func parseLinks() {
        let source = """
        [Link text](https://example.com)
        """

        let ast = MarkdownParser.parse(source)
        #expect(ast.elementMap["paragraph-0"] != nil)
    }
}
