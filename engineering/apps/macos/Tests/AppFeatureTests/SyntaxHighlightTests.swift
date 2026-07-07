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

    @Test("Every supported language compiles its query and produces tokens", arguments: [
        (SyntaxLanguage.javascript, "const x = 42;\n"),
        (SyntaxLanguage.typescript, "let x: number = 42;\n"),
        (SyntaxLanguage.python, "def f():\n    return 42\n"),
        (SyntaxLanguage.go, "package main\nfunc main() { _ = 42 }\n"),
        (SyntaxLanguage.rust, "fn main() { let x = 42; }\n"),
        (SyntaxLanguage.java, "class A { int x = 42; }\n"),
        (SyntaxLanguage.c, "int main() { return 42; }\n"),
        (SyntaxLanguage.cpp, "int main() { return 42; }\n"),
        (SyntaxLanguage.html, "<div class=\"a\">hi</div>\n"),
        (SyntaxLanguage.css, ".a { color: red; }\n"),
        (SyntaxLanguage.json, "{\"a\": 42}\n"),
        (SyntaxLanguage.yaml, "a: 42\n"),
        (SyntaxLanguage.markdown, "# Title\n\nsome text\n"),
    ])
    func eachLanguageProducesTokens(_ pair: (SyntaxLanguage, String)) async {
        let tokens = await SyntaxHighlightClient.liveValue.highlight(pair.1, pair.0)
        #expect(!tokens.isEmpty, "\(pair.0.rawValue) produced no tokens (query may have failed to compile)")
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
