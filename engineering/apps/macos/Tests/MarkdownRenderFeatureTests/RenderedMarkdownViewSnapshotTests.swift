import SwiftUI
import AppKit
import SnapshotTesting
import Testing
@testable import MarkdownRenderFeature

@Suite("RenderedMarkdownView Snapshot Tests")
@MainActor
struct RenderedMarkdownViewSnapshotTests {

    @Test("Snapshot: comprehensive markdown rendering")
    func snapshotComprehensiveMarkdown() async {
        let markdown = """
        # Main Heading

        This is a **bold** paragraph with *italic* text and `inline code`.

        ## Subheading

        Here's a list:
        - Item 1
        - Item 2
        - Item 3

        ### Ordered List

        1. First
        2. Second
        3. Third

        ### Task List

        - [ ] Unchecked task
        - [x] Completed task

        ### Code Block

        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```

        ### Blockquote

        > This is a quote.
        > It spans multiple lines.

        ### Table

        | Column 1 | Column 2 |
        |----------|----------|
        | Cell A   | Cell B   |
        | Cell C   | Cell D   |

        ### Horizontal Rule

        ---

        ### Strikethrough

        This is ~~deleted~~ text.

        ### Link

        [Example Link](https://example.com)
        """

        let ast = MarkdownParser.parse(markdown)
        let view = RenderedMarkdownView(ast: ast)
            .frame(width: 600, height: 800)

        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 600, height: 800)

        assertSnapshot(of: hostingController, as: .image)
    }

    @Test("Snapshot: basic markdown")
    func snapshotBasicMarkdown() async {
        let markdown = """
        # Title

        A simple paragraph with **bold** text.

        - List item
        """

        let ast = MarkdownParser.parse(markdown)
        let view = RenderedMarkdownView(ast: ast)
            .frame(width: 400, height: 300)

        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)

        assertSnapshot(of: hostingController, as: .image)
    }

    @Test("Snapshot: table rendering")
    func snapshotTable() async {
        let markdown = """
        | Header 1 | Header 2 | Header 3 |
        |----------|----------|----------|
        | Row 1 A  | Row 1 B  | Row 1 C  |
        | Row 2 A  | Row 2 B  | Row 2 C  |
        """

        let ast = MarkdownParser.parse(markdown)
        let view = RenderedMarkdownView(ast: ast)
            .frame(width: 500, height: 200)

        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 500, height: 200)

        assertSnapshot(of: hostingController, as: .image)
    }
}
