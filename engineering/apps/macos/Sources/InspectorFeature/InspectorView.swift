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

    public init(
        store: StoreOf<InspectorFeature>,
        overallComment: Binding<String>,
        generatedPrompt: String?,
        allComments: IdentifiedArrayOf<Comment>,
        files: IdentifiedArrayOf<FileNode>,
        reviewContext: ReviewContext?,
        reviewContextStore: StoreOf<ReviewContextFeature>
    ) {
        self.store = store
        self._overallComment = overallComment
        self.generatedPrompt = generatedPrompt
        self.allComments = allComments
        self.files = files
        self.reviewContext = reviewContext
        self.reviewContextStore = reviewContextStore
    }

    public var body: some View {
        VStack(spacing: 0) {
            // NIP-34 patch metadata (when reviewing a Nostr patch)
            if let patchMetadata = reviewContext?.patchMetadata {
                PatchMetadataSectionView(metadata: patchMetadata)
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
