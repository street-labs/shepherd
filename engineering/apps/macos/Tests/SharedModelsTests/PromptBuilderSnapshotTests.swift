import Testing
import Foundation
import IdentifiedCollections
import InlineSnapshotTesting
@testable import SharedModels

/// Value (line) snapshots of the generated prompt text — locks in the exact output format that
/// downstream AI review consumes. Output contains no UUIDs, so it is deterministic as-is.
@Suite("PromptBuilder snapshots")
struct PromptBuilderSnapshotTests {
    private func uuid(_ n: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", n))")!
    }

    @Test("Single-file prompt with a multi-line comment and preamble")
    func singleFile() {
        let fid = uuid(1)
        let file = FileNode(
            id: fid,
            name: "utils.ts",
            filePath: "/p/utils.ts",
            language: .typescript,
            content: "const x = 1;\nconst y = 2;\nconst z = 3;"
        )
        let comment = SharedModels.Comment(id: uuid(2), fileID: fid, startLine: 1, endLine: 2, text: "Rename these")
        let prompt = PromptBuilder.build(files: [file], comments: [comment], overallComment: "Please review")
        assertInlineSnapshot(of: prompt ?? "<nil>", as: .lines) {
            """
            ## Instructions

            Please review

            ## File: utils.ts (typescript)

            ## Review Feedback

            The following are comments from a code review. Each item references the relevant code along with the reviewer's comment, which may be a suggested change, a question, or general feedback.

            - **Referenced code:**
              ```
              const x = 1;
              const y = 2;
              ```
              **Comment:** Rename these
            """
        }
    }

    @Test("Multi-file prompt groups comments per file")
    func multiFile() {
        let a = uuid(1)
        let b = uuid(2)
        let fileA = FileNode(id: a, name: "a.ts", filePath: "/p/a.ts", language: .typescript, content: "let a = 1;")
        let fileB = FileNode(id: b, name: "b.ts", filePath: "/p/b.ts", language: .typescript, content: "let b = 2;")
        let comments: IdentifiedArrayOf<SharedModels.Comment> = [
            SharedModels.Comment(id: uuid(3), fileID: a, startLine: 1, endLine: 1, text: "Comment on A"),
            SharedModels.Comment(id: uuid(4), fileID: b, startLine: 1, endLine: 1, text: "Comment on B"),
        ]
        let prompt = PromptBuilder.build(files: [fileA, fileB], comments: comments, overallComment: "")
        assertInlineSnapshot(of: prompt ?? "<nil>", as: .lines) {
            """
            ## Review Feedback

            The following are comments from a code review across multiple files. Each file section includes the relevant code snippets along with the reviewer's comments.

            ### File: a.ts (typescript)

            - **Referenced code:**
              ```
              let a = 1;
              ```
              **Comment:** Comment on A

            ### File: b.ts (typescript)

            - **Referenced code:**
              ```
              let b = 2;
              ```
              **Comment:** Comment on B
            """
        }
    }
}
