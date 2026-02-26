import SwiftUI
import SharedModels

/// Comment display with edit/delete on hover
public struct CommentBubbleView: View {
    let comment: Comment
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    public init(comment: Comment, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.comment = comment
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bubble.left.fill")
                .font(.caption)
                .foregroundStyle(Color.accentColor)

            Text(comment.text)
                .font(.callout)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Edit comment")

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete comment")
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.08))
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
