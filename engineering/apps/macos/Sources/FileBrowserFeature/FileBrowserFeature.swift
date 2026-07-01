import ComposableArchitecture
import SharedModels
import Foundation

/// Implements: FR-crp-multi-file-nav, FR-crp-panel-resize, FR-crp-file-reviewed-toggle,
/// FR-crp-file-reviewed-visual, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-progress,
/// FR-crp-file-tooltip, FR-crp-active-file-path
@Reducer
public struct FileBrowserFeature {
    @ObservableState
    public struct State: Equatable {
        /// Loaded files — shared with AppFeature (read here to render the tree/tooltips).
        @Shared public var files: IdentifiedArrayOf<FileNode>
        /// All comments — shared with AppFeature (read here for per-file comment counts).
        @Shared public var allComments: IdentifiedArrayOf<Comment>
        /// Set of collapsed directory paths.
        public var collapsedDirs: Set<String> = []
        /// The computed file tree (rebuilt when files or review status changes).
        public var fileTree: [FileTreeNode] = []

        public init(
            files: Shared<IdentifiedArrayOf<FileNode>> = Shared(value: []),
            allComments: Shared<IdentifiedArrayOf<Comment>> = Shared(value: []),
            collapsedDirs: Set<String> = [],
            fileTree: [FileTreeNode] = []
        ) {
            self._files = files
            self._allComments = allComments
            self.collapsedDirs = collapsedDirs
            self.fileTree = fileTree
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case fileSelected(FileNode.ID)
        case directoryExpandedChanged(path: String, isExpanded: Bool)
        case toggleFileReviewed(FileNode.ID)
        case removeFileRequested(FileNode.ID)
        case fileTreeRebuilt([FileTreeNode])
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fileSelected:
                // Handled by parent (AppFeature) to update activeFileID
                return .none
            // Write the exact requested value — never toggle. A value-ignoring toggle makes
            // the directory DisclosureGroup binding getter disagree with SwiftUI's write,
            // driving an infinite re-layout loop (row ghosting/flicker).
            case let .directoryExpandedChanged(dirPath, isExpanded):
                if isExpanded {
                    state.collapsedDirs.remove(dirPath)
                } else {
                    state.collapsedDirs.insert(dirPath)
                }
                return .none
            case .toggleFileReviewed:
                // Handled by parent to update file's isReviewed
                return .none
            case .removeFileRequested:
                // Handled by parent (confirmation flow)
                return .none
            case let .fileTreeRebuilt(tree):
                state.fileTree = tree
                return .none
            }
        }
    }
}
