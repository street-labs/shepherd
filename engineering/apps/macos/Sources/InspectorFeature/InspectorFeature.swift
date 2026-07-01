import ComposableArchitecture
import SharedModels
import Foundation

/// Implements: FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-comment-summary,
/// FR-crp-review-context-overall, FR-crp-review-context-collapsible
@Reducer
public struct InspectorFeature {
    @ObservableState
    public struct State: Equatable {
        /// Loaded files — shared with AppFeature (read here for the All Comments tab).
        @Shared public var files: IdentifiedArrayOf<FileNode>
        /// All comments — shared with AppFeature (read here for the All Comments tab).
        @Shared public var allComments: IdentifiedArrayOf<Comment>
        /// Active tab: preview or all comments.
        public var activeTab: InspectorTab = .preview
        /// Whether the overall review context section is collapsed.
        public var isReviewContextCollapsed: Bool = false

        public init(
            files: Shared<IdentifiedArrayOf<FileNode>> = Shared(value: []),
            allComments: Shared<IdentifiedArrayOf<Comment>> = Shared(value: []),
            activeTab: InspectorTab = .preview,
            isReviewContextCollapsed: Bool = false
        ) {
            self._files = files
            self._allComments = allComments
            self.activeTab = activeTab
            self.isReviewContextCollapsed = isReviewContextCollapsed
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case tabChanged(InspectorTab)
        case reviewContextExpandedChanged(Bool)
        case commentSummaryCommentTapped(Comment.ID)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabChanged(tab):
                state.activeTab = tab
                return .none

            // Write the exact requested value — never toggle. A value-ignoring toggle
            // makes the DisclosureGroup binding getter disagree with the value SwiftUI
            // just wrote, driving an infinite re-layout loop (flicker + scroll starvation).
            case let .reviewContextExpandedChanged(isExpanded):
                state.isReviewContextCollapsed = !isExpanded
                return .none

            case .commentSummaryCommentTapped:
                // Handled by parent (navigate to file + comment)
                return .none
            }
        }
    }
}
