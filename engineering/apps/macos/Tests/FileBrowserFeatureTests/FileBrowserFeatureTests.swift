import Testing
import ComposableArchitecture
import Foundation
@testable import FileBrowserFeature
@testable import SharedModels

@Suite("FileBrowserFeature")
@MainActor
struct FileBrowserFeatureTests {
    @Test("Collapsing a directory writes the exact value (never toggles)")
    func directoryCollapsed() async {
        let store = TestStore(initialState: FileBrowserFeature.State()) {
            FileBrowserFeature()
        }

        // Collapse.
        await store.send(.directoryExpandedChanged(path: "src", isExpanded: false)) {
            $0.collapsedDirs = ["src"]
        }
        // Regression: repeating the same value is a no-op (SET semantics, not toggle).
        // A value-ignoring toggle here caused the directory DisclosureGroup binding loop.
        await store.send(.directoryExpandedChanged(path: "src", isExpanded: false))
    }

    @Test("Expanding a collapsed directory removes it from the set")
    func directoryExpanded() async {
        let store = TestStore(initialState: FileBrowserFeature.State(
            collapsedDirs: ["src"]
        )) {
            FileBrowserFeature()
        }

        await store.send(.directoryExpandedChanged(path: "src", isExpanded: true)) {
            $0.collapsedDirs = []
        }
        await store.send(.directoryExpandedChanged(path: "src", isExpanded: true))
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
