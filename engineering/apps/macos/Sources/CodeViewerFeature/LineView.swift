import SwiftUI
import SharedModels

/// Single line: line number + gutter + code content
public struct LineView: View {
    let lineNumber: Int
    let content: String
    /// Prebuilt syntax-highlighted text for this line. Falls back to plain `content`
    /// when nil/empty (plaintext files, or before highlighting completes).
    let attributed: AttributedString?
    let hasComment: Bool
    let isSelected: Bool
    let isFocused: Bool
    let lineWrapEnabled: Bool
    /// Set when the file under review is a unified diff, so the line can be tinted
    /// by kind. Nil for whole-file review. Implements: FR-diff-display
    let diffKind: DiffLineKind?

    public init(
        lineNumber: Int,
        content: String,
        attributed: AttributedString? = nil,
        hasComment: Bool = false,
        isSelected: Bool = false,
        isFocused: Bool = false,
        lineWrapEnabled: Bool = true,
        diffKind: DiffLineKind? = nil
    ) {
        self.lineNumber = lineNumber
        self.content = content
        self.attributed = attributed
        self.hasComment = hasComment
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.lineWrapEnabled = lineWrapEnabled
        self.diffKind = diffKind
    }

    private var codeText: Text {
        if let attributed, !attributed.characters.isEmpty {
            return Text(attributed)
        }
        return Text(content)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number
            Text("\(lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, 4)

            // Gutter indicator
            Rectangle()
                .fill(hasComment ? Color.accentColor : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 1)

            // Code content. When wrapping is off, the content scrolls horizontally
            // within its own column so long lines are fully reachable instead of
            // truncated; the line-number and gutter columns stay fixed.
            // Implements: FR-crp-line-wrap
            Group {
                if lineWrapEnabled {
                    codeText
                        .textSelection(.enabled)
                        .padding(.leading, 8)
                    Spacer(minLength: 0)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        codeText
                            .textSelection(.enabled)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.leading, 8)
                    }
                }
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(codeForegroundStyle)
        }
        .padding(.vertical, 1)
        .background(backgroundColor)
        .contentShape(Rectangle())
    }

    private var backgroundColor: Color {
        if isFocused {
            return Color.accentColor.opacity(0.15)
        }
        if isSelected {
            return Color.accentColor.opacity(0.08)
        }
        if hasComment {
            return Color.yellow.opacity(0.05)
        }
        // Diff tinting sits below every interaction state above, so selection and
        // comment highlighting stay legible on a tinted line.
        // Implements: FR-diff-display
        switch diffKind {
        case .added: return Color.green.opacity(0.14)
        case .removed: return Color.red.opacity(0.14)
        case .header, .context, .none: return Color.clear
        }
    }

    /// Header lines (`diff --git`, `@@`, mode lines) are structural noise — dimmed
    /// so the changed lines carry the eye. Implements: FR-diff-display
    private var codeForegroundStyle: HierarchicalShapeStyle {
        diffKind == .header ? .secondary : .primary
    }
}
