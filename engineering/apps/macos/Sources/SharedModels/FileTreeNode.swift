import Foundation

/// A node in the file browser directory tree.
/// Implements: FR-crp-multi-file-nav, FR-crp-file-reviewed-grouping
public enum FileTreeNode: Identifiable, Equatable, Sendable {
    case directory(DirectoryNode)
    case file(FileLeaf)

    public var id: String {
        switch self {
        case .directory(let node): return "dir:\(node.path)"
        case .file(let leaf): return "file:\(leaf.fileID)"
        }
    }

    public struct DirectoryNode: Equatable, Sendable {
        public let name: String
        public let path: String
        public var children: [FileTreeNode]
        /// True when all descendant files are reviewed.
        public var isFullyReviewed: Bool

        public init(name: String, path: String, children: [FileTreeNode], isFullyReviewed: Bool = false) {
            self.name = name
            self.path = path
            self.children = children
            self.isFullyReviewed = isFullyReviewed
        }
    }

    public struct FileLeaf: Equatable, Sendable {
        public let fileID: UUID
        public let name: String
        public let isReviewed: Bool

        public init(fileID: UUID, name: String, isReviewed: Bool = false) {
            self.fileID = fileID
            self.name = name
            self.isReviewed = isReviewed
        }
    }
}
