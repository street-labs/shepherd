import SwiftUI
import ComposableArchitecture
import SharedModels
import IdentifiedCollections

/// Source list sidebar with directory tree, review indicators, context menus
public struct FileBrowserView: View {
    let store: StoreOf<FileBrowserFeature>
    let files: IdentifiedArrayOf<FileNode>
    let allComments: IdentifiedArrayOf<Comment>
    let activeFileID: FileNode.ID?

    public init(
        store: StoreOf<FileBrowserFeature>,
        files: IdentifiedArrayOf<FileNode>,
        allComments: IdentifiedArrayOf<Comment>,
        activeFileID: FileNode.ID?
    ) {
        self.store = store
        self.files = files
        self.allComments = allComments
        self.activeFileID = activeFileID
    }

    public var body: some View {
        List(selection: Binding(
            get: { activeFileID.map { "file:\($0)" } },
            set: { id in
                if let id, id.hasPrefix("file:") {
                    let uuidStr = String(id.dropFirst(5))
                    if let uuid = UUID(uuidString: uuidStr) {
                        store.send(.fileSelected(uuid))
                    }
                }
            }
        )) {
            ForEach(store.fileTree) { node in
                fileTreeRow(node: node)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                reviewProgressView
            }
        }
    }

    private func fileTreeRow(node: FileTreeNode) -> AnyView {
        switch node {
        case let .directory(dir):
            return AnyView(
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { !store.collapsedDirs.contains(dir.path) },
                        set: { _ in store.send(.toggleDirectoryCollapsed(dir.path)) }
                    )
                ) {
                    ForEach(dir.children) { child in
                        fileTreeRow(node: child)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: dir.isFullyReviewed ? "folder.badge.checkmark" : "folder")
                            .foregroundStyle(dir.isFullyReviewed ? .green : .secondary)
                        Text(dir.name)
                            .lineLimit(1)
                    }
                }
            )

        case let .file(leaf):
            let commentCount = allComments.filter { $0.fileID == leaf.fileID }.count
            return AnyView(
                HStack(spacing: 4) {
                    Image(systemName: leaf.isReviewed ? "checkmark.circle.fill" : "doc.text")
                        .foregroundStyle(leaf.isReviewed ? .green : .secondary)
                        .font(.caption)
                    Text(leaf.name)
                        .lineLimit(1)
                    Spacer()
                    if commentCount > 0 {
                        Text("\(commentCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .tag("file:\(leaf.fileID)")
                .help(files[id: leaf.fileID]?.filePath ?? leaf.name)
                .contextMenu {
                    Button("Toggle Reviewed") {
                        store.send(.toggleFileReviewed(leaf.fileID))
                    }
                    Divider()
                    Button("Remove File", role: .destructive) {
                        store.send(.removeFileRequested(leaf.fileID))
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var reviewProgressView: some View {
        let reviewed = files.filter(\.isReviewed).count
        let total = files.count
        if total > 0 {
            Text("\(reviewed)/\(total) reviewed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
