import SwiftUI
import ComposableArchitecture

/// TextEditor with submit (Cmd+Enter) and cancel (Esc)
public struct InlineCommentEditorView: View {
    @Bindable var store: StoreOf<CommentFeature>
    /// True when reviewing a NIP-34 patch (`patchMetadata != nil`). Drives the
    /// submit button label between Publish / Save locally / Add Comment.
    /// Implements: FR-srm-comment-publish-on-submit.
    let isPatchReview: Bool
    /// True when a reviewer Nostr identity is loaded. When false on a patch review,
    /// the submit button reads "Save locally" and no publish is attempted.
    let identityLoaded: Bool
    @FocusState private var isFocused: Bool

    public init(store: StoreOf<CommentFeature>, isPatchReview: Bool = false, identityLoaded: Bool = false) {
        self.store = store
        self.isPatchReview = isPatchReview
        self.identityLoaded = identityLoaded
    }

    private var submitLabel: String {
        guard isPatchReview else { return "Add Comment" }
        guard identityLoaded else { return "Save locally" }
        switch store.publishState {
        case .publishing: return "Publishing…"
        case .failed: return "Retry"
        case .published: return "Published"
        default: return "Publish"
        }
    }

    private var isPublishing: Bool { store.publishState == .publishing }

    private var failedMessage: String? {
        if case let .failed(msg) = store.publishState { return msg }
        return nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextEditor(text: $store.editorText)
                .font(.callout)
                .frame(minHeight: 60, maxHeight: 120)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }

            HStack {
                Text("⌘↩ to submit, Esc to cancel")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Cancel") {
                    store.send(.cancelEditor)
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.bordered)

                Button(submitLabel) {
                    store.send(.submitComment)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(isPublishing || store.editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let failedMessage {
                Text(failedMessage)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.quaternary)
        )
    }
}
