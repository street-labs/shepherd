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
    let reviewContext: ReviewContext?
    let reviewContextStore: StoreOf<ReviewContextFeature>

    public init(
        store: StoreOf<InspectorFeature>,
        overallComment: Binding<String>,
        generatedPrompt: String?,
        reviewContext: ReviewContext?,
        reviewContextStore: StoreOf<ReviewContextFeature>
    ) {
        self.store = store
        self._overallComment = overallComment
        self.generatedPrompt = generatedPrompt
        self.reviewContext = reviewContext
        self.reviewContextStore = reviewContextStore
    }

    public var body: some View {
        VStack(spacing: 0) {
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
                    comments: store.allComments,
                    files: store.files,
                    onCommentTapped: { id in
                        store.send(.commentSummaryCommentTapped(id))
                    }
                )
            }
        }
    }
}
