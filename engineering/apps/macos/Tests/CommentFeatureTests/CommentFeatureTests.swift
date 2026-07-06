import Testing
import ComposableArchitecture
import Foundation
@testable import CommentFeature
@testable import SharedModels

@Suite("CommentFeature")
@MainActor
struct CommentFeatureTests {
    @Test("Open editor sets state to creating")
    func openEditor() async {
        let store = TestStore(initialState: CommentFeature.State()) {
            CommentFeature()
        }

        await store.send(.openEditor(.creating(anchorLine: 5, endLine: 5))) {
            $0.editorState = .creating(anchorLine: 5, endLine: 5)
            $0.editorText = ""
        }
    }

    @Test("Submit comment clears editor state")
    func submitComment() async {
        let store = TestStore(initialState: CommentFeature.State(
            editorState: .creating(anchorLine: 3, endLine: 3),
            editorText: "Fix this bug"
        )) {
            CommentFeature()
        }

        await store.send(.submitComment) {
            $0.editorState = nil
            $0.editorText = ""
        }
    }

    @Test("Submit with empty text does nothing")
    func submitEmptyText() async {
        let store = TestStore(initialState: CommentFeature.State(
            editorState: .creating(anchorLine: 1, endLine: 1),
            editorText: "   "
        )) {
            CommentFeature()
        }

        await store.send(.submitComment)
        // State unchanged — editor stays open
    }

    @Test("Cancel editor clears state")
    func cancelEditor() async {
        let store = TestStore(initialState: CommentFeature.State(
            editorState: .creating(anchorLine: 1, endLine: 1),
            editorText: "partial text"
        )) {
            CommentFeature()
        }

        await store.send(.cancelEditor) {
            $0.editorState = nil
            $0.editorText = ""
        }
    }

    @Test("Set focused comment updates state")
    func setFocusedComment() async {
        let commentID = UUID()
        let store = TestStore(initialState: CommentFeature.State()) {
            CommentFeature()
        }

        await store.send(.setFocusedComment(commentID)) {
            $0.focusedCommentID = commentID
        }
    }

    @Test("Binding updates editor text")
    func bindingEditorText() async {
        let store = TestStore(initialState: CommentFeature.State(
            editorState: .creating(anchorLine: 1, endLine: 1)
        )) {
            CommentFeature()
        }

        await store.send(.binding(.set(\.editorText, "New text"))) {
            $0.editorText = "New text"
        }
    }
}
