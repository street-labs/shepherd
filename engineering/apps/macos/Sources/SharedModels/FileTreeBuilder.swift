import Foundation
import IdentifiedCollections

/// Builds a nested directory tree from a flat list of FileNodes.
/// Implements: FR-crp-multi-file-nav, FR-crp-file-reviewed-grouping
public enum FileTreeBuilder {
    /// Build a file tree from the given files.
    /// Strips common path prefix so the tree starts at the deepest shared directory.
    /// Files without a filePath appear at root level.
    /// Unreviewed files sort before reviewed files within each directory.
    public static func buildFileTree(files: IdentifiedArrayOf<FileNode>) -> [FileTreeNode] {
        guard !files.isEmpty else { return [] }

        // Separate files with paths from pasted files (no path)
        var pathFiles: [(file: FileNode, components: [String])] = []
        var rootFiles: [FileTreeNode] = []

        for file in files {
            if let filePath = file.filePath {
                let components = filePath.split(separator: "/").map(String.init)
                pathFiles.append((file, components))
            } else {
                rootFiles.append(.file(FileTreeNode.FileLeaf(
                    fileID: file.id,
                    name: file.name,
                    isReviewed: file.isReviewed
                )))
            }
        }

        guard !pathFiles.isEmpty else {
            return sortNodes(rootFiles)
        }

        // Find common prefix
        let commonPrefix = findCommonPrefix(pathFiles.map(\.components))

        // Strip common prefix from all paths
        let stripped = pathFiles.map { item -> (file: FileNode, components: [String]) in
            let remaining = Array(item.components.dropFirst(commonPrefix.count))
            return (item.file, remaining)
        }

        // Build nested tree
        let tree = buildTree(from: stripped, parentPath: "")

        return sortNodes(rootFiles + tree)
    }

    // MARK: - Private

    private static func findCommonPrefix(_ paths: [[String]]) -> [String] {
        guard let first = paths.first else { return [] }
        var prefix: [String] = []
        for (i, component) in first.enumerated() {
            // Only consider directory components (not file names)
            if i == first.count - 1 { break }
            if paths.allSatisfy({ $0.count > i && $0[i] == component }) {
                prefix.append(component)
            } else {
                break
            }
        }
        return prefix
    }

    private static func buildTree(from entries: [(file: FileNode, components: [String])], parentPath: String) -> [FileTreeNode] {
        // Group by first component
        var directories: [String: [(file: FileNode, components: [String])]] = [:]
        var leafFiles: [FileTreeNode] = []

        for entry in entries {
            if entry.components.count <= 1 {
                // This is a file at the current level
                leafFiles.append(.file(FileTreeNode.FileLeaf(
                    fileID: entry.file.id,
                    name: entry.file.name,
                    isReviewed: entry.file.isReviewed
                )))
            } else {
                let dirName = entry.components[0]
                let remaining = Array(entry.components.dropFirst())
                directories[dirName, default: []].append((entry.file, remaining))
            }
        }

        // Build directory nodes
        var dirNodes: [FileTreeNode] = []
        for (dirName, children) in directories.sorted(by: { $0.key < $1.key }) {
            // Full path from the tree root so each directory node has a unique id/collapse
            // key. Same-named directories at different depths must not collide.
            let dirPath = parentPath.isEmpty ? dirName : "\(parentPath)/\(dirName)"
            let childTree = buildTree(from: children, parentPath: dirPath)
            let allReviewed = allFilesReviewed(in: childTree)
            dirNodes.append(.directory(FileTreeNode.DirectoryNode(
                name: dirName,
                path: dirPath,
                children: sortNodes(childTree),
                isFullyReviewed: allReviewed
            )))
        }

        return dirNodes + leafFiles
    }

    private static func allFilesReviewed(in nodes: [FileTreeNode]) -> Bool {
        for node in nodes {
            switch node {
            case .directory(let dir):
                if !dir.isFullyReviewed { return false }
            case .file(let leaf):
                if !leaf.isReviewed { return false }
            }
        }
        return !nodes.isEmpty
    }

    /// Sort nodes: directories first (alphabetically), then files.
    /// Within files, unreviewed sort before reviewed.
    private static func sortNodes(_ nodes: [FileTreeNode]) -> [FileTreeNode] {
        nodes.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (.directory(let a), .directory(let b)):
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case (.directory, .file):
                return true
            case (.file, .directory):
                return false
            case (.file(let a), .file(let b)):
                // Unreviewed files sort first
                if a.isReviewed != b.isReviewed {
                    return !a.isReviewed
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        }
    }
}
