import Testing
import Markdown
@testable import MarkdownRenderFeature

@Suite("GFMVisitor Tests")
struct GFMVisitorTests {

    @Test("Extract GFM tables")
    func extractTables() {
        let source = """
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |

        Another paragraph.

        | Name | Value |
        |------|-------|
        | A    | 1     |
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        // Should find 2 tables
        #expect(features.tables.count == 2)
        #expect(features.hasGFMContent)
    }

    @Test("Extract task list items")
    func extractTaskListItems() {
        let source = """
        - [ ] Unchecked task 1
        - [x] Checked task 1
        - [ ] Unchecked task 2
        - [X] Checked task 2 (uppercase)
        - Regular list item
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        // Should find 4 task list items (not the regular one)
        #expect(features.taskListItems.count == 4)

        // Should have 2 checked and 2 unchecked
        let checkedCount = features.taskListItems.filter { $0.isChecked }.count
        let uncheckedCount = features.taskListItems.filter { !$0.isChecked }.count
        #expect(checkedCount == 2)
        #expect(uncheckedCount == 2)
    }

    @Test("Extract strikethrough elements")
    func extractStrikethrough() {
        let source = """
        This is ~~strikethrough~~ text.

        Another ~~deleted~~ word.
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        // Should find 2 strikethrough elements
        #expect(features.strikethroughElements.count == 2)
    }

    @Test("Mixed GFM content")
    func extractMixedGFM() {
        let source = """
        # Title

        - [ ] Task 1
        - [x] Task 2

        | Header 1 | Header 2 |
        |----------|----------|
        | Data     | ~~Old~~  |

        Some ~~strikethrough~~ text.
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        #expect(features.taskListItems.count == 2)
        #expect(features.tables.count == 1)
        #expect(features.strikethroughElements.count >= 1) // At least the standalone one
        #expect(features.hasGFMContent)
    }

    @Test("No GFM content")
    func noGFMContent() {
        let source = """
        # Regular markdown

        This is a paragraph.

        - Regular list item
        - Another item
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        #expect(features.taskListItems.isEmpty)
        #expect(features.tables.isEmpty)
        #expect(features.strikethroughElements.isEmpty)
        #expect(!features.hasGFMContent)
    }

    @Test("Task list with mixed formats")
    func taskListMixedFormats() {
        let source = """
        - [ ] Unchecked (lowercase)
        - [x] Checked (lowercase)
        - [X] Checked (uppercase)
        - [  ] Invalid (too many spaces)
        - [] Invalid (no space)
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        // Should only find the valid task list items (first 3)
        #expect(features.taskListItems.count == 3)
    }

    @Test("Table with alignment")
    func tableWithAlignment() {
        let source = """
        | Left | Center | Right |
        |:-----|:------:|------:|
        | L1   | C1     | R1    |
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        #expect(features.tables.count == 1)

        // Verify table structure
        let table = features.tables[0]
        #expect(table.childCount > 0)
    }

    @Test("Nested task lists")
    func nestedTaskLists() {
        let source = """
        - [x] Parent task
          - [ ] Child task 1
          - [x] Child task 2
        """

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        // Should find all task items including nested ones
        #expect(features.taskListItems.count == 3)
    }

    @Test("Empty document")
    func emptyDocument() {
        let source = ""

        let document = Document(parsing: source)
        let features = GFMExtractor.extract(from: document)

        #expect(features.taskListItems.isEmpty)
        #expect(features.tables.isEmpty)
        #expect(features.strikethroughElements.isEmpty)
        #expect(!features.hasGFMContent)
    }
}
