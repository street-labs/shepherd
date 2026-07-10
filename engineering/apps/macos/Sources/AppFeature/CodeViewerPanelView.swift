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
                        commentStore: store.scope(state: \.comment, action: \.comment)
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
