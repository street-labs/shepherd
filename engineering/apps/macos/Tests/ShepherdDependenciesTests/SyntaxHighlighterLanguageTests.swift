import Testing
import SharedModels
@testable import ShepherdDependencies

/// Guards that each language's grammar links and its vendored `highlights.scm`
/// compiles — a missing query file or a bad capture name yields zero tokens.
@Suite("SyntaxHighlighter grammars")
struct SyntaxHighlighterLanguageTests {
    @Test(
        "Every supported language produces tokens",
        arguments: [
            (SyntaxLanguage.swift, "// hi\nfunc greet() -> String { \"hello\" }"),
            (.kotlin, "// hi\nfun greet(): String = \"hello\""),
            (.shell, "# hi\ngreet() { echo \"hello\"; }"),
        ]
    )
    func tokens(language: SyntaxLanguage, source: String) {
        let tokens = SyntaxHighlighter.highlight(source, language: language)
        #expect(!tokens.isEmpty)
        #expect(tokens.contains { $0.type == .comment })
        #expect(tokens.contains { $0.type == .string })
    }
}
