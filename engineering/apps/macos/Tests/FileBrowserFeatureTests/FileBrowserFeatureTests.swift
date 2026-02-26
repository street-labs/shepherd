import Testing
import ComposableArchitecture
import Foundation
@testable import FileBrowserFeature
@testable import SharedModels

@Suite("FileBrowserFeature")
@MainActor
struct FileBrowserFeatureTests {
    @Test("Toggle directory collapsed adds to set")
    func toggleCollapse() async {
        let store = TestStore(initialState: FileBrowserFeature.State()) {
            FileBrowserFeature()
        }

        await store.send(.toggleDirectoryCollapsed("src")) {
            $0.collapsedDirs = ["src"]
        }
    }

    @Test("Toggle collapsed directory again removes from set")
    func toggleUnCollapse() async {
        let store = TestStore(initialState: FileBrowserFeature.State(
            collapsedDirs: ["src"]
        )) {
            FileBrowserFeature()
        }

        await store.send(.toggleDirectoryCollapsed("src")) {
            $0.collapsedDirs = []
        }
    }

    @Test("File tree rebuilt updates state")
    func fileTreeRebuilt() async {
        let tree: [FileTreeNode] = [
            .file(FileTreeNode.FileLeaf(fileID: UUID(), name: "test.ts"))
        ]
        let store = TestStore(initialState: FileBrowserFeature.State()) {
            FileBrowserFeature()
        }

        await store.send(.fileTreeRebuilt(tree)) {
            $0.fileTree = tree
        }
    }

    @Test("File selected is forwarded (no state change in child)")
    func fileSelected() async {
        let store = TestStore(initialState: FileBrowserFeature.State()) {
            FileBrowserFeature()
        }

        await store.send(.fileSelected(UUID()))
        // No state change — parent handles this
    }
}
