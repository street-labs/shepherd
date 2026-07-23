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
        /// When the editor is open to respond to an existing patch-thread reply, the
        /// reply being responded to. On submit, the published note carries a reply
        /// `e` tag on this reply's event id and a `p` tag naming its author.
        /// Implements: FR-srm-reply-to-reply. nil for top-level comments.
        public var replyTarget: ReviewContext.PatchReply?
        /// Publish state for patch-review comment submit. Implements: FR-srm-comment-publish-on-submit.
        /// `.idle` for non-patch reviews and before submit.
        public var publishState: PublishState = .idle

        public init(
            editorState: EditorState? = nil,
            editorText: String = "",
            focusedCommentID: Comment.ID? = nil,
            replyTarget: ReviewContext.PatchReply? = nil,
            publishState: PublishState = .idle
        ) {
            self.editorState = editorState
            self.editorText = editorText
            self.focusedCommentID = focusedCommentID
            self.replyTarget = replyTarget
            self.publishState = publishState
        }
    }

    /// Publish state for the comment submit button on patch reviews.
    /// Implements: FR-srm-comment-publish-on-submit, AC-srm-publish-relay-failure.
    public enum PublishState: Equatable, Sendable {
        case idle
        case publishing
        case published
        case failed(String)
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
        /// Open the editor pre-targeted at an existing patch-thread reply.
        // Implements: FR-srm-reply-to-reply
        case replyToPatchReply(ReviewContext.PatchReply)
        /// Publish state transitions driven by the parent during the publish flow.
        case publishStateChanged(PublishState)

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

            case let .replyToPatchReply(reply):
                // Open the editor at the reply's anchor (or line 1 of the active
                // file when the reply is unanchored), pre-targeted at this reply.
                let start = reply.lineAnchor?.startLine ?? 1
                let end = reply.lineAnchor?.endLine ?? start
                state.editorState = .creating(anchorLine: start, endLine: end)
                state.editorText = ""
                state.replyTarget = reply
                state.publishState = .idle
                return .none

            case let .publishStateChanged(newState):
                state.publishState = newState
                return .none
            }
        }
    }
}
