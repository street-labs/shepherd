import ComposableArchitecture
import SharedModels

/// Implements: FR-crp-review-context-display, FR-crp-review-context-per-file,
/// FR-crp-review-context-collapsible
@Reducer
public struct ReviewContextFeature {
    @ObservableState
    public struct State: Equatable {
        /// Whether the per-file context panel is collapsed.
        public var isCollapsed: Bool = false
        /// The active file's per-file context (nil if no context for this file).
        public var activeFileContext: ReviewContext.ContextPair?

        public init(
            isCollapsed: Bool = false,
            activeFileContext: ReviewContext.ContextPair? = nil
        ) {
            self.isCollapsed = isCollapsed
            self.activeFileContext = activeFileContext
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case expandedChanged(Bool)
        case activeFileContextUpdated(ReviewContext.ContextPair?)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // Write the exact requested value — never toggle. A value-ignoring toggle
            // makes the DisclosureGroup binding getter disagree with the value SwiftUI
            // just wrote, driving an infinite re-layout loop (flicker + scroll starvation).
            case let .expandedChanged(isExpanded):
                state.isCollapsed = !isExpanded
                return .none
            case let .activeFileContextUpdated(context):
                state.activeFileContext = context
                return .none
            }
        }
    }
}
