import SwiftUI

/// Single line: line number + gutter + code content
public struct LineView: View {
    let lineNumber: Int
    let content: String
    let hasComment: Bool
    let isSelected: Bool
    let isFocused: Bool
    let lineWrapEnabled: Bool

    public init(
        lineNumber: Int,
        content: String,
        hasComment: Bool = false,
        isSelected: Bool = false,
        isFocused: Bool = false,
        lineWrapEnabled: Bool = true
    ) {
        self.lineNumber = lineNumber
        self.content = content
        self.hasComment = hasComment
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.lineWrapEnabled = lineWrapEnabled
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

            // Code content
            Group {
                if lineWrapEnabled {
                    Text(content)
                        .textSelection(.enabled)
                } else {
                    Text(content)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .font(.system(.body, design: .monospaced))
            .padding(.leading, 8)

            Spacer(minLength: 0)
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
        return Color.clear
    }
}
