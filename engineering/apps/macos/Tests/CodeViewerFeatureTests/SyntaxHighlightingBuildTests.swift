import Testing
import SwiftUI
import SharedModels
@testable import CodeViewerFeature

/// Verifies per-line AttributedString construction from absolute-range tokens.
/// Implements: FR-crp-syntax-highlight
@Suite("buildLineAttributedStrings")
struct SyntaxHighlightingBuildTests {
    @Test("Produces one entry per line and preserves characters")
    func lineCountAndCharacters() {
        let content = "let x = 42\nfoo()\n"   // 3 lines: "let x = 42", "foo()", ""
        let lines = buildLineAttributedStrings(content: content, tokens: [])
        #expect(lines.count == 3)
        #expect(String(lines[0].characters) == "let x = 42")
        #expect(String(lines[1].characters) == "foo()")
        #expect(String(lines[2].characters) == "")
    }

    @Test("Colors the run covering a token and leaves others uncolored")
    func colorsTokenRun() {
        let content = "let x = 42\nfoo()\n"
        let numberRange = content.range(of: "42")!
        let tokens = [SyntaxToken(range: numberRange, type: .number)]
        let lines = buildLineAttributedStrings(content: content, tokens: tokens)

        // Line 0 has exactly one colored run, over "42".
        let colored = lines[0].runs.filter { $0.foregroundColor != nil }
        #expect(colored.count == 1)
        if let run = colored.first {
            #expect(String(lines[0][run.range].characters) == "42")
        }
        // Line 1 (no tokens) has no colored runs.
        #expect(lines[1].runs.allSatisfy { $0.foregroundColor == nil })
    }

    @Test("Clips a multi-line token to each line")
    func multiLineToken() {
        let content = "ab\ncd\nef"
        // A token spanning from line 0 'b' through line 2 'e'.
        let start = content.index(content.startIndex, offsetBy: 1) // 'b'
        let end = content.index(content.startIndex, offsetBy: 7)   // just past 'e'
        let tokens = [SyntaxToken(range: start..<end, type: .comment)]
        let lines = buildLineAttributedStrings(content: content, tokens: tokens)
        #expect(lines.count == 3)
        // Each line has a colored run; the clipped substrings are "b", "cd", "e".
        #expect(String(lines[0][lines[0].runs.first(where: { $0.foregroundColor != nil })!.range].characters) == "b")
        #expect(String(lines[2][lines[2].runs.first(where: { $0.foregroundColor != nil })!.range].characters) == "e")
    }
}
