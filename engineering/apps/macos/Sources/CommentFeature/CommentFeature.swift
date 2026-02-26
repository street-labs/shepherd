import ComposableArchitecture
import SharedModels
import Foundation

/// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit,
/// FR-crp-line-comment-delete, FR-crp-comment-navigation
@Reducer
public struct CommentFeature {
    @ObservableState
    public struct State: Equatable {
        /// Current editor state (creating or editing a comment).
        public var editorState: EditorState?
        /// The text currently in the editor.
        public var editorText: String = ""
        /// The ID of the focused comment (via next/prev navigation).
        public var focusedCommentID: Comment.ID?

        public init(
            editorState: EditorState? = nil,
            editorText: String = "",
            focusedCommentID: Comment.ID? = nil
        ) {
            self.editorState = editorState
            self.editorText = editorText
            self.focusedCommentID = focusedCommentID
        }
    }

    @CasePathable
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case openEditor(EditorState)
        case submitComment
        case cancelEditor
        case editComment(Comment.ID)
        case deleteComment(Comment.ID)
        case navigateComment(Direction)
        case setFocusedComment(Comment.ID?)

        public enum Direction: Equatable, Sendable {
            case next, previous
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .openEditor(editorState):
                state.editorState = editorState
                state.editorText = ""
                return .none

            case .submitComment:
                guard !state.editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                // Parent handles creating/updating the comment in allComments
                state.editorState = nil
                state.editorText = ""
                return .none

            case .cancelEditor:
                state.editorState = nil
                state.editorText = ""
                return .none

            case .editComment:
                // Handled by parent
                return .none

            case .deleteComment:
                // Handled by parent
                return .none

            case .navigateComment:
                // Handled by parent (needs access to allComments)
                return .none

            case let .setFocusedComment(id):
                state.focusedCommentID = id
                return .none
            }
        }
    }
}
