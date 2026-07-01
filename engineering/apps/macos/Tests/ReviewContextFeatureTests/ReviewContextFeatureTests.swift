import Testing
import ComposableArchitecture
@testable import ReviewContextFeature
@testable import SharedModels

@Suite("ReviewContextFeature")
@MainActor
struct ReviewContextFeatureTests {
    @Test("Expanded change writes the exact value (never toggles)")
    func expandedChangeSetsExactValue() async {
        let store = TestStore(initialState: ReviewContextFeature.State(isCollapsed: false)) {
            ReviewContextFeature()
        }

        // Collapse.
        await store.send(.expandedChanged(false)) {
            $0.isCollapsed = true
        }
        // Regression: sending the same value again is a no-op. This proves SET semantics
        // rather than toggle — the value-ignoring toggle is exactly what caused the
        // DisclosureGroup binding to feed back on itself and thrash layout.
        await store.send(.expandedChanged(false))
        // Expand.
        await store.send(.expandedChanged(true)) {
            $0.isCollapsed = false
        }
        await store.send(.expandedChanged(true))
    }

    @Test("Active file context update replaces the stored context")
    func activeFileContextUpdated() async {
        let pair = ReviewContext.ContextPair(neutral: "added a function", review: "looks good")
        let store = TestStore(initialState: ReviewContextFeature.State()) {
            ReviewContextFeature()
        }

        await store.send(.activeFileContextUpdated(pair)) {
            $0.activeFileContext = pair
        }
        await store.send(.activeFileContextUpdated(nil)) {
            $0.activeFileContext = nil
        }
    }
}
