import Foundation
import ComposableArchitecture
import SharedModels
import SwiftTreeSitter
import TreeSitterJSON

/// TreeSitter-backed syntax highlighter. Maps a `SyntaxLanguage` to its grammar +
/// vendored `highlights.scm` query, parses the source, and returns `SyntaxToken`s
/// (String.Index ranges + a coarse `TokenType`) for the code viewer to color.
/// Implements: FR-crp-syntax-highlight
enum SyntaxHighlighter {
    /// A grammar's parser entry point plus the basename of its vendored query file
    /// (`Resources/queries/<query>.scm`).
    private struct Grammar {
        let language: OpaquePointer
        let query: String
    }

    /// SyntaxLanguage -> grammar. Languages absent here (e.g. `.plaintext`) are not highlighted.
    private static func grammar(for language: SyntaxLanguage) -> Grammar? {
        switch language {
        case .json: return Grammar(language: tree_sitter_json(), query: "json")
        default: return nil
        }
    }

    /// Compiled `Language` + `Query`, cached per `SyntaxLanguage` (compiling a query is
    /// expensive). A cached `nil` means the language is unsupported or failed to compile.
    private static let cache = LockIsolated<[SyntaxLanguage: Compiled?]>([:])
    private struct Compiled { let language: Language; let query: Query }

    private static func compiled(for language: SyntaxLanguage) -> Compiled? {
        cache.withValue { store in
            if let cached = store[language] { return cached }
            let result = build(for: language)
            store[language] = result
            return result
        }
    }

    private static func build(for language: SyntaxLanguage) -> Compiled? {
        guard let grammar = grammar(for: language),
              let url = Bundle.module.url(forResource: grammar.query, withExtension: "scm", subdirectory: "queries"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        let tsLanguage = Language(language: grammar.language)
        guard let query = try? Query(language: tsLanguage, data: data) else { return nil }
        return Compiled(language: tsLanguage, query: query)
    }

    static func highlight(_ content: String, language: SyntaxLanguage) -> [SyntaxToken] {
        guard !content.isEmpty, let compiled = compiled(for: language) else { return [] }

        let parser = Parser()
        guard (try? parser.setLanguage(compiled.language)) != nil,
              let tree = parser.parse(content),
              let root = tree.rootNode
        else { return [] }

        let cursor = compiled.query.execute(node: root, in: tree)
        let matches = cursor.resolve(with: Predicate.Context(string: content))

        var tokens: [SyntaxToken] = []
        for match in matches {
            for capture in match.captures {
                guard let name = capture.name else { continue }
                let type = tokenType(for: name)
                guard type != .plain, let range = Range(capture.range, in: content) else { continue }
                tokens.append(SyntaxToken(range: range, type: type))
            }
        }
        // Apply broad captures first so narrower/more-specific ones win on overlap
        // (the renderer applies tokens in order, later overriding earlier).
        tokens.sort { lhs, rhs in
            let l = content.distance(from: lhs.range.lowerBound, to: lhs.range.upperBound)
            let r = content.distance(from: rhs.range.lowerBound, to: rhs.range.upperBound)
            return l > r
        }
        return tokens
    }

    /// Map a tree-sitter highlight capture name (e.g. `string.special.key`) to a coarse
    /// `TokenType`. Uses the first dotted component with a few full-name special cases.
    private static func tokenType(for captureName: String) -> SyntaxToken.TokenType {
        // Full-name special cases first.
        switch captureName {
        case "string.special.key": return .property        // JSON/object keys
        case "escape": return .string
        default: break
        }
        let head = captureName.split(separator: ".").first.map(String.init) ?? captureName
        switch head {
        case "keyword", "constant": return .keyword
        case "string", "character": return .string
        case "comment": return .comment
        case "number", "float", "boolean": return .number
        case "type", "constructor": return .type
        case "function", "method": return .function
        case "property", "field", "attribute": return .property
        case "variable", "parameter": return .variable
        case "operator": return .operator
        case "punctuation", "delimiter", "bracket": return .punctuation
        default: return .plain
        }
    }
}
