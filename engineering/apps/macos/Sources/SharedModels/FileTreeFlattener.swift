import Foundation

/// Flattens a file tree into the ordered list of rows the sidebar renders, honoring collapsed
/// directories (their descendants are omitted). Pure logic extracted from `FileBrowserView` so
/// the row order/depth — the sequence that replaced the buggy nested `DisclosureGroup`s — is
/// testable headlessly.
/// Implements: FR-crp-multi-file-nav
public enum FileTreeFlattener {
    /// A visible row: a tree node plus its indentation depth (0 at the tree root).
    public struct VisibleRow: Equatable, Sendable {
        public let node: FileTreeNode
        public let depth: Int

        public init(node: FileTreeNode, depth: Int) {
            self.node = node
            self.depth = depth
        }
    }

    /// The visible rows for `tree`, skipping the descendants of any directory whose `path` is in
    /// `collapsedDirs`.
    public static func visibleRows(tree: [FileTreeNode], collapsedDirs: Set<String>) -> [VisibleRow] {
        var rows: [VisibleRow] = []
        func walk(_ nodes: [FileTreeNode], _ depth: Int) {
            for node in nodes {
                rows.append(VisibleRow(node: node, depth: depth))
                if case let .directory(dir) = node, !collapsedDirs.contains(dir.path) {
                    walk(dir.children, depth + 1)
                }
            }
        }
        walk(tree, 0)
        return rows
    }
}
