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

    @Test("Review context collapse toggled")
    func reviewContextCollapse() async {
        let store = TestStore(initialState: InspectorFeature.State(
            isReviewContextCollapsed: false
        )) {
            InspectorFeature()
        }

        await store.send(.reviewContextCollapseToggled) {
            $0.isReviewContextCollapsed = true
        }

        await store.send(.reviewContextCollapseToggled) {
            $0.isReviewContextCollapsed = false
        }
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
