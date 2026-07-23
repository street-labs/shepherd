import SwiftUI
import ComposableArchitecture
import SharedModels
import CommentFeature

/// ScrollView + LazyVStack for virtualized line rendering
public struct CodeViewerView: View {
    let store: StoreOf<CodeViewerFeature>
    let file: FileNode
    let comments: [Comment]
    let lineWrapEnabled: Bool
    let commentStore: StoreOf<CommentFeature>
    /// Anchored patch-thread replies to render inline on this file's diff.
    /// Implements: FR-sr-patch-replies-display. Read-only; visually marked bot vs
    /// user, distinct from the user's own editable Comment bubbles.
    let patchReplies: [ReviewContext.PatchReply]
    /// Reviewer's loaded pubkey (hex) for the `YOU` self-marker on inline replies.
    let reviewerPubkey: String?
    /// True when this is a NIP-34 patch review (drives the editor submit label).
    let isPatchReview: Bool
    /// True when a reviewer identity is loaded (editor offers Publish vs Save locally).
    let identityLoaded: Bool
    /// Invoked when the reviewer taps Reply on an inline patch-thread bubble.
    /// Implements: FR-srm-reply-to-reply.
    let onReply: (ReviewContext.PatchReply) -> Void

    /// Prebuilt syntax-highlighted lines for `file`, rebuilt when the file or its
    /// tokens change. Empty until highlighting completes (renders plain until then).
    @State private var lineAttributedStrings: [AttributedString] = []

    public init(
        store: StoreOf<CodeViewerFeature>,
        file: FileNode,
        comments: [Comment],
        lineWrapEnabled: Bool,
        commentStore: StoreOf<CommentFeature>,
        patchReplies: [ReviewContext.PatchReply] = [],
        reviewerPubkey: String? = nil,
        isPatchReview: Bool = false,
        identityLoaded: Bool = false,
        onReply: @escaping (ReviewContext.PatchReply) -> Void = { _ in }
    ) {
        self.store = store
        self.file = file
        self.comments = comments
        self.lineWrapEnabled = lineWrapEnabled
        self.commentStore = commentStore
        self.patchReplies = patchReplies
        self.reviewerPubkey = reviewerPubkey
        self.isPatchReview = isPatchReview
        self.identityLoaded = identityLoaded
        self.onReply = onReply
    }

    /// Map line numbers to comments covering that line
    private var commentsByLine: [Int: [Comment]] {
        var result: [Int: [Comment]] = [:]
        for comment in comments {
            for line in comment.startLine...comment.endLine {
                result[line, default: []].append(comment)
            }
        }
        return result
    }

    /// Map line numbers to anchored patch replies whose anchor starts on that line.
    private var repliesByStartLine: [Int: [ReviewContext.PatchReply]] {
        var result: [Int: [ReviewContext.PatchReply]] = [:]
        for reply in patchReplies {
            guard let anchor = reply.lineAnchor else { continue }
            result[anchor.startLine, default: []].append(reply)
        }
        return result
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(file.lines.enumerated()), id: \.offset) { index, line in
                        let lineNumber = index + 1
                        let hasComment = commentsByLine[lineNumber] != nil
                        let isInSelection = store.selectedRange?.contains(lineNumber) == true

                        VStack(spacing: 0) {
                            LineView(
                                lineNumber: lineNumber,
                                content: line,
                                attributed: lineAttributedStrings.indices.contains(index)
                                    ? lineAttributedStrings[index] : nil,
                                hasComment: hasComment,
                                isSelected: isInSelection,
                                isFocused: store.focusedLine == lineNumber,
                                lineWrapEnabled: lineWrapEnabled
                            )
                            .id(lineNumber)
                            .onTapGesture {
                                store.send(.lineClicked(lineNumber))
                            }

                            // Show comments attached to this line
                            let lineComments = commentsByLine[lineNumber] ?? []
                            ForEach(lineComments) { comment in
                                if comment.startLine == lineNumber {
                                    CommentBubbleView(
                                        comment: comment,
                                        onEdit: { commentStore.send(.editComment(comment.id)) },
                                        onDelete: { commentStore.send(.deleteComment(comment.id)) }
                                    )
                                    .padding(.leading, 60)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 2)
                                }
                            }

                            // Anchored patch-thread replies (read-only, bot/human marked)
                            let lineReplies = repliesByStartLine[lineNumber] ?? []
                            ForEach(lineReplies) { reply in
                                PatchReplyInlineView(reply: reply, reviewerPubkey: reviewerPubkey, onReply: onReply)
                                    .padding(.leading, 60)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 2)
                            }

                            // Inline editor (if creating at this line)
                            if case let .creating(anchor, end) = commentStore.editorState,
                               min(anchor, end) == lineNumber {
                                InlineCommentEditorView(store: commentStore, isPatchReview: isPatchReview, identityLoaded: identityLoaded)
                                    .padding(.leading, 60)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 4)
                            }

                            // Inline editor (if editing a comment at this line)
                            if case let .editing(commentID) = commentStore.editorState,
                               lineComments.contains(where: { $0.id == commentID && $0.startLine == lineNumber }) {
                                InlineCommentEditorView(store: commentStore, isPatchReview: isPatchReview, identityLoaded: identityLoaded)
                                    .padding(.leading, 60)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
            .onChange(of: file.id) { _, _ in
                // Restore scroll position when switching files
                if file.scrollOffset > 0 {
                    proxy.scrollTo(file.scrollOffset, anchor: .top)
                }
            }
            // Scroll to the focused line when comment navigation (or a comment-summary
            // tap) moves focus. Implements: FR-crp-comment-navigation
            .onChange(of: store.focusedLine) { _, newValue in
                if let line = newValue {
                    withAnimation {
                        proxy.scrollTo(line, anchor: .center)
                    }
                }
            }
            // Build highlighted lines on appear and whenever the file switches or its
            // syntax tokens arrive (highlighting completes asynchronously).
            .task(id: file.id) { rebuildHighlighting() }
            .onChange(of: store.syntaxTokens) { _, _ in rebuildHighlighting() }
        }
    }

    private func rebuildHighlighting() {
        lineAttributedStrings = buildLineAttributedStrings(
            content: file.content,
            tokens: store.syntaxTokens
        )
    }
}
