import Foundation
import ComposableArchitecture

/// State of the inline comment editor.
/// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit
@CasePathable
public enum EditorState: Equatable, Sendable {
    case creating(anchorLine: Int, endLine: Int)
    case editing(commentID: UUID)
}
