import SwiftUI
import ComposableArchitecture
import SharedModels
import IdentifiedCollections
import PromptFeature
import ReviewContextFeature

/// Right sidebar: review context + overall comment + tabs (preview / all comments)
public struct InspectorView: View {
    @Bindable var store: StoreOf<InspectorFeature>
    @Binding var overallComment: String
    let generatedPrompt: String?
    let allComments: IdentifiedArrayOf<Comment>
    let files: IdentifiedArrayOf<FileNode>
    let reviewContext: ReviewContext?
    let reviewContextStore: StoreOf<ReviewContextFeature>
    /// Reviewer's loaded Nostr identity for the identity indicator. Implements:
    /// FR-srm-identity-indicator. nil for non-patch reviews.
    let reviewerIdentity: ReviewerIdentity?
    /// Transient publish confirmation shown near the identity indicator.
    let showPublishConfirmation: Bool
    /// Invoked when the reviewer taps Reply on a patch-thread inspector row.
    /// Implements: FR-srm-reply-to-reply.
    let onReplyToPatchReply: (ReviewContext.PatchReply) -> Void

    public init(
        store: StoreOf<InspectorFeature>,
        overallComment: Binding<String>,
        generatedPrompt: String?,
        allComments: IdentifiedArrayOf<Comment>,
        files: IdentifiedArrayOf<FileNode>,
        reviewContext: ReviewContext?,
        reviewContextStore: StoreOf<ReviewContextFeature>,
        reviewerIdentity: ReviewerIdentity? = nil,
        showPublishConfirmation: Bool = false,
        onReplyToPatchReply: @escaping (ReviewContext.PatchReply) -> Void = { _ in }
    ) {
        self.store = store
        self._overallComment = overallComment
        self.generatedPrompt = generatedPrompt
        self.allComments = allComments
        self.files = files
        self.reviewContext = reviewContext
        self.reviewContextStore = reviewContextStore
        self.reviewerIdentity = reviewerIdentity
        self.showPublishConfirmation = showPublishConfirmation
        self.onReplyToPatchReply = onReplyToPatchReply
    }

    public var body: some View {
        VStack(spacing: 0) {
            // NIP-34 patch metadata (when reviewing a Nostr patch)
            if let patchMetadata = reviewContext?.patchMetadata {
                PatchMetadataSectionView(metadata: patchMetadata)
            }

            // Reviewer identity indicator (patch reviews only). Implements:
            // FR-srm-identity-indicator. Shown above the Patch Thread section.
            if reviewContext?.patchMetadata != nil {
                IdentityIndicatorView(
                    identity: reviewerIdentity,
                    showPublishConfirmation: showPublishConfirmation
                )
            }

            // NIP-34 patch thread replies (other agents / humans). Implements
            // FR-sr-patch-replies-display. Shown only for patch reviews with replies.
            if let replies = reviewContext?.patchMetadata?.replies, !replies.isEmpty {
                PatchRepliesSectionView(
                    replies: replies,
                    reviewerPubkey: reviewerIdentity?.pubkeyHex,
                    onReply: onReplyToPatchReply
                )
            }

            // Overall review context (collapsible)
            if let reviewContext {
                ReviewContextSectionView(
                    context: reviewContext.overall,
                    isCollapsed: store.isReviewContextCollapsed,
                    onExpandedChange: { store.send(.reviewContextExpandedChanged($0)) }
                )
                Divider()
            }

            // Overall comment / preamble
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Comment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                TextEditor(text: $overallComment)
                    .font(.callout)
                    .frame(minHeight: 44, maxHeight: 88)
            }
            .padding(8)

            Divider()

            // Tab picker
            Picker("View", selection: $store.activeTab.sending(\.tabChanged)) {
                Text("Preview").tag(InspectorTab.preview)
                Text("All Comments").tag(InspectorTab.allComments)
            }
            .pickerStyle(.segmented)
            .padding(8)

            // Tab content
            switch store.activeTab {
            case .preview:
                PromptPreviewView(prompt: generatedPrompt)
            case .allComments:
                CommentSummaryView(
                    comments: allComments,
                    files: files,
                    onCommentTapped: { id in
                        store.send(.commentSummaryCommentTapped(id))
                    }
                )
            }
        }
    }
}
