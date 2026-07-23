import SwiftUI
import ComposableArchitecture
import SharedModels
import CodeViewerFeature
import CommentFeature
import ReviewContextFeature
import MarkdownRenderFeature

/// Wraps file header + review context + code viewer
/// Implements: FR-mdr-render-toggle (conditional rendering)
struct CodeViewerPanelView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        VStack(spacing: 0) {
            // Active file header
            if let activeFile = store.activeFile {
                activeFileHeader(file: activeFile)
            }

            // Per-file review context (if available)
            if store.reviewContext.activeFileContext != nil {
                ReviewContextPanelView(
                    store: store.scope(state: \.reviewContext, action: \.reviewContext)
                )
            }

            // Code viewer (raw or rendered based on mode)
            if let activeFile = store.activeFile {
                if activeFile.isMarkdownFile && store.renderMode == .rendered {
                    // Rendered markdown view
                    let ast = MarkdownParser.parse(activeFile.content)
                    RenderedMarkdownView(ast: ast)
                } else {
                    // Raw code view with syntax highlighting
                    CodeViewerView(
                        store: store.scope(state: \.codeViewer, action: \.codeViewer),
                        file: activeFile,
                        comments: store.allComments.filter { $0.fileID == activeFile.id },
                        lineWrapEnabled: store.lineWrapEnabled,
                        commentStore: store.scope(state: \.comment, action: \.comment),
                        patchReplies: anchoredReplies(for: activeFile),
                        reviewerPubkey: store.reviewerIdentity?.pubkeyHex,
                        isPatchReview: store.reviewContextData?.patchMetadata != nil,
                        identityLoaded: store.reviewerIdentity != nil,
                        onReply: { reply in store.send(.replyToPatchReply(reply)) }
                    )
                }
            } else {
                Text("No file selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Anchored patch-thread replies for the active file (FR-sr-patch-replies-display).
    /// Matches reply.lineAnchor.filePath against the file's absolute path.
    private func anchoredReplies(for file: FileNode) -> [ReviewContext.PatchReply] {
        guard let path = file.filePath else { return [] }
        return (store.reviewContextData?.patchMetadata?.replies ?? []).filter {
            $0.lineAnchor?.filePath == path
        }
    }

    @ViewBuilder
    private func activeFileHeader(file: FileNode) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
            Text(file.filePath ?? file.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(file.filePath ?? file.name)
            Spacer()
            Text(file.language.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        Divider()
    }
}
