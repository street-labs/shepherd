import Testing
import SharedModels
@testable import ShepherdDependencies

/// Verifies the live TreeSitter highlighter parses and classifies tokens.
/// Implements: FR-crp-syntax-highlight
@Suite("SyntaxHighlighter")
struct SyntaxHighlightTests {
    @Test("JSON produces string, number, key and boolean tokens")
    func highlightJSON() async {
        let json = """
        {
          "name": "value",
          "count": 42,
          "ok": true
        }
        """
        let tokens = await SyntaxHighlightClient.liveValue.highlight(json, .json)
        #expect(!tokens.isEmpty)

        func texts(_ type: SyntaxToken.TokenType) -> [String] {
            tokens.filter { $0.type == type }.map { String(json[$0.range]) }
        }
        #expect(texts(.number).contains("42"))
        #expect(texts(.string).contains("\"value\""))
        #expect(texts(.property).contains("\"name\""))   // object key
        #expect(texts(.number).contains("true") || texts(.keyword).contains("true"))
    }

    @Test("Plaintext yields no tokens")
    func highlightPlaintext() async {
        let tokens = await SyntaxHighlightClient.liveValue.highlight("just some text\n", .plaintext)
        #expect(tokens.isEmpty)
    }

    @Test("Empty content yields no tokens")
    func highlightEmpty() async {
        let tokens = await SyntaxHighlightClient.liveValue.highlight("", .json)
        #expect(tokens.isEmpty)
    }
}
