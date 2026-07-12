import Testing
@testable import MarkdownRenderFeature

@Suite("MarkdownParser Tests")
struct MarkdownParserTests {

    @Test("Parse basic markdown with headings and paragraphs")
    func parseBasicMarkdown() {
        let source = """
        # Heading 1

        This is a paragraph.

        ## Heading 2

        Another paragraph with **bold** text.
        """

        let ast = MarkdownParser.parse(source)

        // Should have heading-0, paragraph-0, heading-1, paragraph-1
        #expect(ast.elementMap["heading-0"] != nil)
        #expect(ast.elementMap["paragraph-0"] != nil)
        #expect(ast.elementMap["heading-1"] != nil)
        #expect(ast.elementMap["paragraph-1"] != nil)
        #expect(ast.elementMap.count == 4)
    }

    @Test("Assign stable element IDs")
    func assignStableIDs() {
        let source = """
        # Heading

        Paragraph 1

        Paragraph 2
        """

        let ast1 = MarkdownParser.parse(source)
        let ast2 = MarkdownParser.parse(source)

        // Same source should produce same IDs
        #expect(ast1.elementMap.keys.sorted() == ast2.elementMap.keys.sorted())
    }

    @Test("Parse list items")
    func parseListItems() {
        let source = """
        - Item 1
        - Item 2
        - Item 3
        """

        let ast = MarkdownParser.parse(source)

        // Should have list-item-0, list-item-1, list-item-2
        #expect(ast.elementMap["list-item-0"] != nil)
        #expect(ast.elementMap["list-item-1"] != nil)
        #expect(ast.elementMap["list-item-2"] != nil)
    }

    @Test("Parse code blocks")
    func parseCodeBlocks() {
        let source = """
        ```swift
        let x = 42
        ```

        ```typescript
        const y = 'hello';
        ```
        """

        let ast = MarkdownParser.parse(source)

        // Should have code-block-0, code-block-1
        #expect(ast.elementMap["code-block-0"] != nil)
        #expect(ast.elementMap["code-block-1"] != nil)
    }

    @Test("Parse blockquotes")
    func parseBlockquotes() {
        let source = """
        > This is a quote.
        > It spans multiple lines.

        > Another quote.
        """

        let ast = MarkdownParser.parse(source)

        // Should have blockquote-0, blockquote-1
        #expect(ast.elementMap["blockquote-0"] != nil)
        #expect(ast.elementMap["blockquote-1"] != nil)
    }

    @Test("Parse thematic breaks")
    func parseThematicBreaks() {
        let source = """
        Content above

        ---

        Content below

        ***

        More content
        """

        let ast = MarkdownParser.parse(source)

        // Should have thematic-break-0, thematic-break-1
        #expect(ast.elementMap["thematic-break-0"] != nil)
        #expect(ast.elementMap["thematic-break-1"] != nil)
    }

    @Test("Extract source ranges")
    func extractSourceRanges() {
        let source = """
        # Heading

        Paragraph on line 3
        """

        let ast = MarkdownParser.parse(source)

        // Heading should be on line 1
        let heading = ast.elementMap["heading-0"]
        #expect(heading?.sourceRange?.startLine == 1)

        // Paragraph should be on line 3
        let paragraph = ast.elementMap["paragraph-0"]
        #expect(paragraph?.sourceRange?.startLine == 3)
    }

    @Test("Parse empty document")
    func parseEmptyDocument() {
        let source = ""

        let ast = MarkdownParser.parse(source)

        // Empty document should have no elements
        #expect(ast.elementMap.isEmpty)
    }

    @Test("Parse nested lists")
    func parseNestedLists() {
        let source = """
        - Item 1
          - Nested 1
          - Nested 2
        - Item 2
        """

        let ast = MarkdownParser.parse(source)

        // Should have multiple list items
        #expect(ast.elementMap["list-item-0"] != nil)
        #expect(ast.elementMap["list-item-1"] != nil)
        #expect(ast.elementMap["list-item-2"] != nil)
        #expect(ast.elementMap["list-item-3"] != nil)
    }

    @Test("Parse mixed content")
    func parseMixedContent() {
        let source = """
        # Title

        Introduction paragraph.

        ## Section 1

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

        // Should have various element types
        #expect(ast.elementMap["heading-0"] != nil)       // Title
        #expect(ast.elementMap["paragraph-0"] != nil)     // Introduction
        #expect(ast.elementMap["heading-1"] != nil)       // Section 1
        #expect(ast.elementMap["list-item-0"] != nil)     // Point 1
        #expect(ast.elementMap["list-item-1"] != nil)     // Point 2
        #expect(ast.elementMap["code-block-0"] != nil)    // Python code
        #expect(ast.elementMap["blockquote-0"] != nil)    // Quote
        #expect(ast.elementMap["thematic-break-0"] != nil) // Horizontal rule
        #expect(ast.elementMap["paragraph-1"] != nil)     // Conclusion

        // Total should be at least 9 key elements (may include additional list structure)
        #expect(ast.elementMap.count >= 9)
    }
}
