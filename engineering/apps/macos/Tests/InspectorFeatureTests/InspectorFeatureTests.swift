import Testing
import ComposableArchitecture
import Foundation
@testable import InspectorFeature
@testable import SharedModels

@Suite("InspectorFeature")
@MainActor
struct InspectorFeatureTests {
    @Test("Tab changed updates active tab")
    func tabChanged() async {
        let store = TestStore(initialState: InspectorFeature.State()) {
            InspectorFeature()
        }

        await store.send(.tabChanged(.allComments)) {
            $0.activeTab = .allComments
        }

        await store.send(.tabChanged(.preview)) {
            $0.activeTab = .preview
        }
    }

    @Test("Review context expanded change writes the exact value (never toggles)")
    func reviewContextCollapse() async {
        let store = TestStore(initialState: InspectorFeature.State(
            isReviewContextCollapsed: false
        )) {
            InspectorFeature()
        }

        // Collapse
        await store.send(.reviewContextExpandedChanged(false)) {
            $0.isReviewContextCollapsed = true
        }
        // Regression: repeating the same value is a no-op (SET semantics, not toggle).
        // A value-ignoring toggle here is what caused the DisclosureGroup binding loop.
        await store.send(.reviewContextExpandedChanged(false))
        // Expand
        await store.send(.reviewContextExpandedChanged(true)) {
            $0.isReviewContextCollapsed = false
        }
        await store.send(.reviewContextExpandedChanged(true))
    }

    @Test("Comment summary tap is forwarded")
    func commentSummaryTap() async {
        let store = TestStore(initialState: InspectorFeature.State()) {
            InspectorFeature()
        }

        await store.send(.commentSummaryCommentTapped(UUID()))
        // No state change — handled by parent
    }
}
