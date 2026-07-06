import Foundation

/// Supported syntax highlighting languages.
/// Implements: FR-crp-syntax-highlight
public enum SyntaxLanguage: String, CaseIterable, Equatable, Codable, Sendable {
    case javascript
    case typescript
    case python
    case go
    case rust
    case java
    case c
    case cpp
    case html
    case css
    case json
    case yaml
    case markdown
    case plaintext

    /// Maps file extensions to languages.
    public static func detect(from fileName: String) -> SyntaxLanguage {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "js", "jsx", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "py": return .python
        case "go": return .go
        case "rs": return .rust
        case "java": return .java
        case "c", "h": return .c
        case "cpp", "cc", "cxx", "hpp": return .cpp
        case "html", "htm": return .html
        case "css": return .css
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "md", "markdown": return .markdown
        case "swift": return .plaintext
        default: return .plaintext
        }
    }

    /// Display name for use in prompts (matches rawValue for most languages).
    public var displayName: String {
        rawValue
    }
}
