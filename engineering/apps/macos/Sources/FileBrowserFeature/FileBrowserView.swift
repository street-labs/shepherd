import SwiftUI
import ComposableArchitecture
import SharedModels
import IdentifiedCollections

/// Source list sidebar with directory tree, review indicators, context menus.
///
/// The tree is rendered as a **flat** list of visible rows (directories that are
/// collapsed hide their descendants) rather than recursive `DisclosureGroup`s nested
/// inside the `List`. Nested disclosures in a macOS `List` miscalculate row frames
/// (rows overlap / labels ghost), and the recursion previously forced `AnyView`, which
/// erases the view identity `List` relies on for correct row reuse. Flattening removes
/// both problems: directory rows own a manual chevron and collapse is self-managed via
/// `collapsedDirs`.
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

    /// A single visible row: a tree node plus its indentation depth. Descendants of a
    /// collapsed directory are omitted.
    private struct Row: Identifiable {
        let node: FileTreeNode
        let depth: Int
        var id: String { node.id }
    }

    private var visibleRows: [Row] {
        var rows: [Row] = []
        func walk(_ nodes: [FileTreeNode], _ depth: Int) {
            for node in nodes {
                rows.append(Row(node: node, depth: depth))
                if case let .directory(dir) = node, !store.collapsedDirs.contains(dir.path) {
                    walk(dir.children, depth + 1)
                }
            }
        }
        walk(store.fileTree, 0)
        return rows
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
            ForEach(visibleRows) { row in
                switch row.node {
                case let .directory(dir):
                    directoryRow(dir, depth: row.depth)
                case let .file(leaf):
                    fileRow(leaf, depth: row.depth)
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                reviewProgressView
            }
        }
    }

    @ViewBuilder
    private func directoryRow(_ dir: FileTreeNode.DirectoryNode, depth: Int) -> some View {
        let isExpanded = !store.collapsedDirs.contains(dir.path)
        Button {
            // Write the exact requested value — never toggle (see FileBrowserFeature).
            store.send(.directoryExpandedChanged(path: dir.path, isExpanded: !isExpanded))
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                Image(systemName: dir.isFullyReviewed ? "folder.badge.checkmark" : "folder")
                    .foregroundStyle(dir.isFullyReviewed ? .green : .secondary)
                Text(dir.name)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, CGFloat(depth) * 14)
    }

    @ViewBuilder
    private func fileRow(_ leaf: FileTreeNode.FileLeaf, depth: Int) -> some View {
        let commentCount = allComments.filter { $0.fileID == leaf.fileID }.count
        HStack(spacing: 4) {
            Image(systemName: leaf.isReviewed ? "checkmark.circle.fill" : "doc.text")
                .foregroundStyle(leaf.isReviewed ? .green : .secondary)
                .font(.caption)
            Text(leaf.name)
                .lineLimit(1)
            Spacer(minLength: 0)
            if commentCount > 0 {
                Text("\(commentCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
        // Indent past the directory chevron so files align under their folder's name.
        .padding(.leading, CGFloat(depth) * 14 + 16)
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
