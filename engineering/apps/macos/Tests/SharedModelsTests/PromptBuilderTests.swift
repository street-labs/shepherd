import Testing
import Foundation
import IdentifiedCollections
@testable import SharedModels

@Suite("PromptBuilder")
struct PromptBuilderTests {
    let fileID = UUID()

    func makeFile(
        id: UUID? = nil,
        name: String = "utils.ts",
        language: SyntaxLanguage = .typescript,
        content: String = "const x = 1;\nconst y = 2;\nconst z = 3;"
    ) -> FileNode {
        FileNode(
            id: id ?? fileID,
            name: name,
            language: language,
            content: content
        )
    }

    func makeComment(
        fileID: UUID? = nil,
        startLine: Int = 1,
        endLine: Int = 1,
        text: String = "Fix this",
        createdAt: Date = Date(timeIntervalSince1970: 1000)
    ) -> SharedModels.Comment {
        SharedModels.Comment(
            fileID: fileID ?? self.fileID,
            startLine: startLine,
            endLine: endLine,
            text: text,
            createdAt: createdAt
        )
    }

    @Test("Returns nil when no files have comments")
    func noComments() {
        let file = makeFile()
        let result = PromptBuilder.build(
            files: [file],
            comments: [],
            overallComment: ""
        )
        #expect(result == nil)
    }

    @Test("Single-file format with one comment")
    func singleFileOneComment() {
        let file = makeFile()
        let comment = makeComment(text: "Rename this variable")

        let result = PromptBuilder.build(
            files: [file],
            comments: [comment],
            overallComment: ""
        )

        #expect(result != nil)
        let prompt = result!

        // Check structure
        #expect(prompt.contains("## File: utils.ts (typescript)"))
        #expect(prompt.contains("## Review Feedback"))
        #expect(prompt.contains("- **Referenced code:**"))
        #expect(prompt.contains("**Comment:** Rename this variable"))
        #expect(prompt.contains("const x = 1;"))
        // Should NOT contain Instructions section (empty preamble)
        #expect(!prompt.contains("## Instructions"))
    }

    @Test("Includes Instructions section when preamble is provided")
    func preambleIncluded() {
        let file = makeFile()
        let comment = makeComment()

        let result = PromptBuilder.build(
            files: [file],
            comments: [comment],
            overallComment: "Refactor for readability"
        )

        #expect(result != nil)
        let prompt = result!
        #expect(prompt.contains("## Instructions\n\nRefactor for readability"))
    }

    @Test("Skips empty preamble (whitespace only)")
    func emptyPreambleSkipped() {
        let file = makeFile()
        let comment = makeComment()

        let result = PromptBuilder.build(
            files: [file],
            comments: [comment],
            overallComment: "   \n  "
        )

        #expect(result != nil)
        #expect(!result!.contains("## Instructions"))
    }

    @Test("Multi-line code snippet with 2-space indentation")
    func multiLineSnippet() {
        let file = makeFile()
        let comment = makeComment(startLine: 1, endLine: 2, text: "Combine these")

        let result = PromptBuilder.build(
            files: [file],
            comments: [comment],
            overallComment: ""
        )

        #expect(result != nil)
        let prompt = result!
        // The snippet should contain both lines with 2-space indent
        #expect(prompt.contains("  const x = 1;\n  const y = 2;"))
    }

    @Test("Comments sorted by line number then creation date")
    func sortOrder() {
        let file = makeFile()
        let c1 = makeComment(startLine: 3, text: "Third line", createdAt: Date(timeIntervalSince1970: 1000))
        let c2 = makeComment(startLine: 1, text: "First line", createdAt: Date(timeIntervalSince1970: 2000))
        let c3 = makeComment(startLine: 1, text: "Also first", createdAt: Date(timeIntervalSince1970: 1000))

        let result = PromptBuilder.build(
            files: [file],
            comments: [c1, c2, c3],
            overallComment: ""
        )

        #expect(result != nil)
        let prompt = result!
        // "Also first" (line 1, earlier) before "First line" (line 1, later) before "Third line" (line 3)
        let alsoIdx = prompt.range(of: "Also first")!.lowerBound
        let firstIdx = prompt.range(of: "First line")!.lowerBound
        let thirdIdx = prompt.range(of: "Third line")!.lowerBound
        #expect(alsoIdx < firstIdx)
        #expect(firstIdx < thirdIdx)
    }

    @Test("Multi-file format when multiple files have comments")
    func multiFileFormat() {
        let file1ID = UUID()
        let file2ID = UUID()
        let file1 = makeFile(id: file1ID, name: "a.ts")
        let file2 = makeFile(id: file2ID, name: "b.py", language: .python, content: "x = 1\ny = 2")

        let c1 = makeComment(fileID: file1ID, text: "Fix A")
        let c2 = makeComment(fileID: file2ID, text: "Fix B")

        let result = PromptBuilder.build(
            files: [file1, file2],
            comments: [c1, c2],
            overallComment: ""
        )

        #expect(result != nil)
        let prompt = result!
        // Multi-file uses ### File headers
        #expect(prompt.contains("### File: a.ts (typescript)"))
        #expect(prompt.contains("### File: b.py (python)"))
        #expect(prompt.contains("across multiple files"))
    }

    @Test("Skips files with no comments in multi-file mode")
    func multiFileSkipsEmpty() {
        let file1ID = UUID()
        let file2ID = UUID()
        let file1 = makeFile(id: file1ID, name: "a.ts")
        let file2 = makeFile(id: file2ID, name: "b.py", language: .python, content: "x = 1")

        let c1 = makeComment(fileID: file1ID, text: "Only A has comments")

        let result = PromptBuilder.build(
            files: [file1, file2],
            comments: [c1],
            overallComment: ""
        )

        #expect(result != nil)
        let prompt = result!
        // Single file with comments uses single-file format (## File, not ### File)
        #expect(prompt.contains("## File: a.ts (typescript)"))
        #expect(!prompt.contains("### File:"))
        #expect(!prompt.contains("b.py"))
    }
}
