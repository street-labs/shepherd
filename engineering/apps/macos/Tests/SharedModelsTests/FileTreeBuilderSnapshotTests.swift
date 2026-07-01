import Testing
import Foundation
import IdentifiedCollections
import InlineSnapshotTesting
@testable import SharedModels

/// Value (dump) snapshots of the file-tree builder — the pure logic that drives the sidebar.
/// Reliable and headless (no view rendering). Fixed UUIDs keep the dump deterministic.
@Suite("FileTreeBuilder snapshots")
struct FileTreeBuilderSnapshotTests {
    private func uuid(_ n: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", n))")!
    }

    @Test("Nested tree: common prefix stripped, dirs before files, full unique paths")
    func nestedTree() {
        let files: IdentifiedArrayOf<FileNode> = [
            FileNode(id: uuid(1), name: "PromptBuilder.swift", filePath: "/p/Sources/SharedModels/PromptBuilder.swift", content: ""),
            FileNode(id: uuid(2), name: "InspectorFeature.swift", filePath: "/p/Sources/InspectorFeature/InspectorFeature.swift", content: ""),
            FileNode(id: uuid(3), name: "ReviewContextFeature.swift", filePath: "/p/Sources/ReviewContextFeature/ReviewContextFeature.swift", content: ""),
        ]
        let tree = FileTreeBuilder.buildFileTree(files: files)
        assertInlineSnapshot(of: tree, as: .dump) {
            """
            ▿ 3 elements
              ▿ FileTreeNode
                ▿ directory: DirectoryNode
                  ▿ children: 1 element
                    ▿ FileTreeNode
                      ▿ file: FileLeaf
                        - fileID: 00000000-0000-0000-0000-000000000002
                        - isReviewed: false
                        - name: "InspectorFeature.swift"
                  - isFullyReviewed: false
                  - name: "InspectorFeature"
                  - path: "InspectorFeature"
              ▿ FileTreeNode
                ▿ directory: DirectoryNode
                  ▿ children: 1 element
                    ▿ FileTreeNode
                      ▿ file: FileLeaf
                        - fileID: 00000000-0000-0000-0000-000000000003
                        - isReviewed: false
                        - name: "ReviewContextFeature.swift"
                  - isFullyReviewed: false
                  - name: "ReviewContextFeature"
                  - path: "ReviewContextFeature"
              ▿ FileTreeNode
                ▿ directory: DirectoryNode
                  ▿ children: 1 element
                    ▿ FileTreeNode
                      ▿ file: FileLeaf
                        - fileID: 00000000-0000-0000-0000-000000000001
                        - isReviewed: false
                        - name: "PromptBuilder.swift"
                  - isFullyReviewed: false
                  - name: "SharedModels"
                  - path: "SharedModels"

            """
        }
    }

    @Test("Flatten with a collapsed directory omits its descendants")
    func flattenWithCollapse() {
        let files: IdentifiedArrayOf<FileNode> = [
            FileNode(id: uuid(1), name: "PromptBuilder.swift", filePath: "/p/Sources/SharedModels/PromptBuilder.swift", content: ""),
            FileNode(id: uuid(2), name: "InspectorFeature.swift", filePath: "/p/Sources/InspectorFeature/InspectorFeature.swift", content: ""),
            FileNode(id: uuid(3), name: "ReviewContextFeature.swift", filePath: "/p/Sources/ReviewContextFeature/ReviewContextFeature.swift", content: ""),
        ]
        let tree = FileTreeBuilder.buildFileTree(files: files)
        // Collapse InspectorFeature: its child file must not appear in the visible rows.
        let rows = FileTreeFlattener.visibleRows(tree: tree, collapsedDirs: ["InspectorFeature"])
        let described = rows.map { row -> String in
            let label: String
            switch row.node {
            case let .directory(dir): label = "[dir] \(dir.name)"
            case let .file(leaf): label = leaf.name
            }
            return String(repeating: "  ", count: row.depth) + label
        }
        assertInlineSnapshot(of: described, as: .dump) {
            """
            ▿ 5 elements
              - "[dir] InspectorFeature"
              - "[dir] ReviewContextFeature"
              - "  ReviewContextFeature.swift"
              - "[dir] SharedModels"
              - "  PromptBuilder.swift"

            """
        }
    }
}
