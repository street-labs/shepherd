import SwiftUI
import SharedModels
import IdentifiedCollections

/// All Comments tab: grouped by file
public struct CommentSummaryView: View {
    let comments: IdentifiedArrayOf<Comment>
    let files: IdentifiedArrayOf<FileNode>
    let onCommentTapped: (Comment.ID) -> Void

    public init(
        comments: IdentifiedArrayOf<Comment>,
        files: IdentifiedArrayOf<FileNode>,
        onCommentTapped: @escaping (Comment.ID) -> Void
    ) {
        self.comments = comments
        self.files = files
        self.onCommentTapped = onCommentTapped
    }

    private var commentsByFile: [(file: FileNode, comments: [Comment])] {
        let grouped = Dictionary(grouping: comments.elements, by: \.fileID)
        return files.compactMap { file in
            guard let fileComments = grouped[file.id], !fileComments.isEmpty else { return nil }
            let sorted = fileComments.sorted { $0.startLine < $1.startLine }
            return (file, sorted)
        }
    }

    public var body: some View {
        ScrollView {
            if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2)
                        .foregroundStyle(.quaternary)
                    Text("No comments yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(commentsByFile, id: \.file.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.file.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(item.comments) { comment in
                                Button {
                                    onCommentTapped(comment.id)
                                } label: {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("L\(comment.startLine)")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 36, alignment: .trailing)
                                        Text(comment.text)
                                            .font(.caption)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.quaternary.opacity(0.5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}
