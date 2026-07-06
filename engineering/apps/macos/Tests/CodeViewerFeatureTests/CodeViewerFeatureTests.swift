import Testing
import ComposableArchitecture
import Foundation
@testable import CodeViewerFeature
@testable import SharedModels
@testable import ShepherdDependencies

@Suite("CodeViewerFeature")
@MainActor
struct CodeViewerFeatureTests {
    @Test("Line click clears selection and opens comment editor")
    func lineClick() async {
        let store = TestStore(initialState: CodeViewerFeature.State(
            selectedRange: 1...3
        )) {
            CodeViewerFeature()
        }

        await store.send(.lineClicked(5)) {
            $0.selectedRange = nil
        }

        await store.receive(\.openCommentEditor) // Forwarded to parent
    }

    @Test("Line range selected updates state")
    func lineRangeSelected() async {
        let store = TestStore(initialState: CodeViewerFeature.State()) {
            CodeViewerFeature()
        }

        await store.send(.lineRangeSelected(2...5)) {
            $0.selectedRange = 2...5
        }
    }

    @Test("Syntax highlighting completed updates tokens")
    func syntaxHighlightingCompleted() async {
        let store = TestStore(initialState: CodeViewerFeature.State(
            showLargeFileWarning: true
        )) {
            CodeViewerFeature()
        }

        let tokens: [SyntaxToken] = []
        await store.send(.syntaxHighlightingCompleted(tokens)) {
            $0.syntaxTokens = tokens
            $0.showLargeFileWarning = false
        }
    }

    @Test("Focused line changed updates state")
    func focusedLineChanged() async {
        let store = TestStore(initialState: CodeViewerFeature.State()) {
            CodeViewerFeature()
        }

        await store.send(.focusedLineChanged(10)) {
            $0.focusedLine = 10
        }
    }

    @Test("Large banner dismissed clears warning")
    func largeBannerDismissed() async {
        let store = TestStore(initialState: CodeViewerFeature.State(
            showLargeFileWarning: true
        )) {
            CodeViewerFeature()
        }

        await store.send(.largeBannerDismissed) {
            $0.showLargeFileWarning = false
        }
    }
}
