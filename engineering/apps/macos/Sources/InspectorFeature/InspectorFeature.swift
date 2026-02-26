import ComposableArchitecture
import SharedModels
import Foundation

/// Implements: FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-comment-summary,
/// FR-crp-review-context-overall, FR-crp-review-context-collapsible
@Reducer
public struct InspectorFeature {
    @ObservableState
    public struct State: Equatable {
        /// Active tab: preview or all comments.
        public var activeTab: InspectorTab = .preview
        /// Whether the overall review context section is collapsed.
        public var isReviewContextCollapsed: Bool = false

        public init(
            activeTab: InspectorTab = .preview,
            isReviewContextCollapsed: Bool = false
        ) {
            self.activeTab = activeTab
            self.isReviewContextCollapsed = isReviewContextCollapsed
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case tabChanged(InspectorTab)
        case reviewContextCollapseToggled
        case commentSummaryCommentTapped(Comment.ID)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabChanged(tab):
                state.activeTab = tab
                return .none

            case .reviewContextCollapseToggled:
                state.isReviewContextCollapsed.toggle()
                return .none

            case .commentSummaryCommentTapped:
                // Handled by parent (navigate to file + comment)
                return .none
            }
        }
    }
}
