import SwiftUI
import ComposableArchitecture

/// TextEditor with submit (Cmd+Enter) and cancel (Esc)
public struct InlineCommentEditorView: View {
    @Bindable var store: StoreOf<CommentFeature>
    @FocusState private var isFocused: Bool

    public init(store: StoreOf<CommentFeature>) {
        self.store = store
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

                Button("Add Comment") {
                    store.send(.submitComment)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(store.editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
