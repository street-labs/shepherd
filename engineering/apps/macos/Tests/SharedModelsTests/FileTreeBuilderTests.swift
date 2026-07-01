import Testing
import Foundation
import IdentifiedCollections
@testable import SharedModels

@Suite("FileTreeBuilder")
struct FileTreeBuilderTests {
    @Test("Empty files produces empty tree")
    func emptyFiles() {
        let tree = FileTreeBuilder.buildFileTree(files: [])
        #expect(tree.isEmpty)
    }

    @Test("Single file without path appears at root")
    func singlePastedFile() {
        let file = FileNode(name: "Untitled", content: "hello")
        let tree = FileTreeBuilder.buildFileTree(files: [file])
        #expect(tree.count == 1)
        if case let .file(leaf) = tree.first {
            #expect(leaf.name == "Untitled")
            #expect(leaf.fileID == file.id)
        } else {
            Issue.record("Expected file node")
        }
    }

    @Test("Files with common prefix have prefix stripped")
    func commonPrefixStripped() {
        let f1 = FileNode(name: "a.ts", filePath: "/Users/dev/project/src/a.ts", content: "a")
        let f2 = FileNode(name: "b.ts", filePath: "/Users/dev/project/src/b.ts", content: "b")
        let tree = FileTreeBuilder.buildFileTree(files: [f1, f2])

        // Both files are in src/, so they should appear at root level (prefix stripped)
        // Since they share the full directory path, files should be at root
        #expect(tree.count == 2)
        let names = tree.compactMap { node -> String? in
            if case let .file(leaf) = node { return leaf.name }
            return nil
        }
        #expect(names.contains("a.ts"))
        #expect(names.contains("b.ts"))
    }

    @Test("Nested directories create tree structure")
    func nestedDirs() {
        let f1 = FileNode(name: "index.ts", filePath: "/project/src/index.ts", content: "a")
        let f2 = FileNode(name: "util.ts", filePath: "/project/src/lib/util.ts", content: "b")
        let tree = FileTreeBuilder.buildFileTree(files: [f1, f2])

        // After stripping common prefix (/project), we have:
        // src/index.ts and src/lib/util.ts -> root should have src/ dir
        // Actually, common prefix is /project/src for the directory part
        // f1 components: ["project", "src", "index.ts"]
        // f2 components: ["project", "src", "lib", "util.ts"]
        // Common prefix (dirs only): ["project", "src"]
        // After strip: f1 -> ["index.ts"], f2 -> ["lib", "util.ts"]
        // So root has: index.ts file + lib/ dir containing util.ts
        #expect(tree.count == 2) // lib/ dir + index.ts

        let dirNames = tree.compactMap { node -> String? in
            if case let .directory(dir) = node { return dir.name }
            return nil
        }
        #expect(dirNames.contains("lib"))
    }

    @Test("Unreviewed files sort before reviewed files")
    func reviewedSorting() {
        let f1 = FileNode(name: "a.ts", filePath: "/p/a.ts", content: "a", isReviewed: true)
        let f2 = FileNode(name: "b.ts", filePath: "/p/b.ts", content: "b", isReviewed: false)
        let tree = FileTreeBuilder.buildFileTree(files: [f1, f2])

        #expect(tree.count == 2)
        // b.ts (unreviewed) should come before a.ts (reviewed)
        if case let .file(first) = tree[0] {
            #expect(first.name == "b.ts")
            #expect(!first.isReviewed)
        }
    }

    @Test("Directories sort before files")
    func directoriesFirst() {
        let f1 = FileNode(name: "z.ts", filePath: "/p/z.ts", content: "z")
        let f2 = FileNode(name: "a.ts", filePath: "/p/dir/a.ts", content: "a")
        let tree = FileTreeBuilder.buildFileTree(files: [f1, f2])

        #expect(tree.count == 2)
        // dir/ should come before z.ts
        if case .directory = tree[0] {
            // Good
        } else {
            Issue.record("Expected directory first")
        }
    }

    @Test("isFullyReviewed is true when all descendants are reviewed")
    func fullyReviewedDir() {
        let f1 = FileNode(name: "a.ts", filePath: "/p/src/a.ts", content: "a", isReviewed: true)
        let f2 = FileNode(name: "b.ts", filePath: "/p/src/b.ts", content: "b", isReviewed: true)
        // Use a structure with a shared prefix (/p) so directory nodes remain after the
        // common prefix (/p) is stripped — f1/f2/f3 land under src/ and lib/.
        let f3 = FileNode(name: "c.ts", filePath: "/p/lib/c.ts", content: "c", isReviewed: true)
        let tree2 = FileTreeBuilder.buildFileTree(files: [f1, f2, f3])

        // Common prefix: /p, remaining: src/a.ts, src/b.ts, lib/c.ts
        let dirNodes = tree2.compactMap { node -> FileTreeNode.DirectoryNode? in
            if case let .directory(dir) = node { return dir }
            return nil
        }
        for dir in dirNodes {
            #expect(dir.isFullyReviewed)
        }
    }
}
