import Foundation
import IdentifiedCollections

/// Implements: FR-crp-prompt-format, FR-crp-multi-file-prompt-format,
/// NFR-crp-prompt-gen-time
///
/// Format matches the web app's promptBuilder.ts — uses `## Review Feedback` headers
/// and `- **Referenced code:** ... **Comment:**` entries.
public enum PromptBuilder {
    /// Build the structured prompt. Returns nil if no files have comments.
    public static func build(
        files: IdentifiedArrayOf<FileNode>,
        comments: IdentifiedArrayOf<Comment>,
        overallComment: String
    ) -> String? {
        // Group comments by file
        let commentsByFile = Dictionary(grouping: comments.elements, by: \.fileID)

        // Filter to files that have comments, in file order
        let filesWithComments = files.filter { commentsByFile[$0.id]?.isEmpty == false }

        guard !filesWithComments.isEmpty else { return nil }

        // Single file with comments — use single-file format
        if filesWithComments.count == 1, let file = filesWithComments.first {
            let fileComments = commentsByFile[file.id] ?? []
            return buildSingleFilePrompt(
                file: file,
                comments: fileComments,
                preamble: overallComment
            )
        }

        // Multi-file format
        return buildMultiFilePrompt(
            files: Array(filesWithComments),
            commentsByFile: commentsByFile,
            preamble: overallComment
        )
    }

    // MARK: - Single-File Format

    private static func buildSingleFilePrompt(
        file: FileNode,
        comments: [Comment],
        preamble: String
    ) -> String {
        var sections: [String] = []

        // Instructions section (only if preamble is non-empty after trimming)
        let trimmedPreamble = preamble.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPreamble.isEmpty {
            sections.append("## Instructions\n\n\(trimmedPreamble)")
        }

        // File reference
        sections.append("## File: \(file.name) (\(file.language.rawValue))")

        // Feedback section
        sections.append("## Review Feedback\n\nThe following are comments from a code review. Each item references the relevant code along with the reviewer's comment, which may be a suggested change, a question, or general feedback.")

        let sorted = comments.sorted { lhs, rhs in
            if lhs.startLine != rhs.startLine { return lhs.startLine < rhs.startLine }
            return lhs.createdAt < rhs.createdAt
        }

        let changeEntries = sorted.map { comment -> String in
            let startIdx = comment.startLine - 1
            let endIdx = min(comment.endLine, file.lines.count)
            let codeLines = Array(file.lines[startIdx..<endIdx])
            let codeSnippet = codeLines.joined(separator: "\n")
            let indentedSnippet = codeSnippet.split(separator: "\n", omittingEmptySubsequences: false)
                .joined(separator: "\n  ")
            return "- **Referenced code:**\n  ```\n  \(indentedSnippet)\n  ```\n  **Comment:** \(comment.text)"
        }

        sections.append(changeEntries.joined(separator: "\n\n"))

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Multi-File Format

    private static func buildMultiFilePrompt(
        files: [FileNode],
        commentsByFile: [UUID: [Comment]],
        preamble: String
    ) -> String {
        var sections: [String] = []

        let trimmedPreamble = preamble.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPreamble.isEmpty {
            sections.append("## Instructions\n\n\(trimmedPreamble)")
        }

        sections.append("## Review Feedback\n\nThe following are comments from a code review across multiple files. Each file section includes the relevant code snippets along with the reviewer's comments.")

        for file in files {
            let fileComments = commentsByFile[file.id] ?? []
            guard !fileComments.isEmpty else { continue }

            sections.append("### File: \(file.name) (\(file.language.rawValue))")

            let sorted = fileComments.sorted { lhs, rhs in
                if lhs.startLine != rhs.startLine { return lhs.startLine < rhs.startLine }
                return lhs.createdAt < rhs.createdAt
            }

            let changeEntries = sorted.map { comment -> String in
                let startIdx = comment.startLine - 1
                let endIdx = min(comment.endLine, file.lines.count)
                let codeLines = Array(file.lines[startIdx..<endIdx])
                let codeSnippet = codeLines.joined(separator: "\n")
                let indentedSnippet = codeSnippet.split(separator: "\n", omittingEmptySubsequences: false)
                    .joined(separator: "\n  ")
                return "- **Referenced code:**\n  ```\n  \(indentedSnippet)\n  ```\n  **Comment:** \(comment.text)"
            }

            sections.append(changeEntries.joined(separator: "\n\n"))
        }

        return sections.joined(separator: "\n\n")
    }
}
