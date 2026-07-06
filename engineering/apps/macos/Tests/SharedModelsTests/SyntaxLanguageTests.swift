import Testing
@testable import SharedModels

@Suite("SyntaxLanguage")
struct SyntaxLanguageTests {
    @Test("JavaScript extensions", arguments: ["file.js", "component.jsx", "module.mjs", "common.cjs"])
    func javascript(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .javascript)
    }

    @Test("TypeScript extensions", arguments: ["file.ts", "component.tsx"])
    func typescript(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .typescript)
    }

    @Test("Python extension")
    func python() {
        #expect(SyntaxLanguage.detect(from: "script.py") == .python)
    }

    @Test("Go extension")
    func go() {
        #expect(SyntaxLanguage.detect(from: "main.go") == .go)
    }

    @Test("Rust extension")
    func rust() {
        #expect(SyntaxLanguage.detect(from: "lib.rs") == .rust)
    }

    @Test("Java extension")
    func java() {
        #expect(SyntaxLanguage.detect(from: "Main.java") == .java)
    }

    @Test("C extensions", arguments: ["main.c", "header.h"])
    func cLanguage(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .c)
    }

    @Test("C++ extensions", arguments: ["main.cpp", "file.cc", "file.cxx", "header.hpp"])
    func cpp(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .cpp)
    }

    @Test("HTML extensions", arguments: ["page.html", "page.htm"])
    func html(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .html)
    }

    @Test("CSS extension")
    func css() {
        #expect(SyntaxLanguage.detect(from: "styles.css") == .css)
    }

    @Test("JSON extension")
    func json() {
        #expect(SyntaxLanguage.detect(from: "config.json") == .json)
    }

    @Test("YAML extensions", arguments: ["config.yaml", "config.yml"])
    func yaml(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .yaml)
    }

    @Test("Markdown extensions", arguments: ["readme.md", "docs.markdown"])
    func markdown(fileName: String) {
        #expect(SyntaxLanguage.detect(from: fileName) == .markdown)
    }

    @Test("Unknown extension returns plaintext")
    func unknownExtension() {
        #expect(SyntaxLanguage.detect(from: "file.xyz") == .plaintext)
    }

    @Test("No extension returns plaintext")
    func noExtension() {
        #expect(SyntaxLanguage.detect(from: "Makefile") == .plaintext)
    }
}
