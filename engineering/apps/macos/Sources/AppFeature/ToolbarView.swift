import SwiftUI
import ComposableArchitecture
import AppKit

/// Toolbar items: Open, Line Wrap toggle, Copy Prompt, Done (conditional)
struct ToolbarView: ToolbarContent {
    @Bindable var store: StoreOf<AppFeature>

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                openFilePicker()
            } label: {
                Label("Open", systemImage: "doc.badge.plus")
            }
            .help("Open files (⌘O)")
        }

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $store.lineWrapEnabled) {
                Label("Line Wrap", systemImage: "text.word.spacing")
            }
            .help("Toggle line wrapping")
            .disabled(store.files.isEmpty)
        }

        // Copy Prompt: the icon briefly swaps to a checkmark for ~2s after a
        // successful copy as the confirmation (no toast, per design).
        // Implements: FR-crp-prompt-copy
        ToolbarItem(placement: .primaryAction) {
            Button {
                store.send(.copyPrompt)
            } label: {
                Label(
                    "Copy Prompt",
                    systemImage: store.showCopyConfirmation ? "checkmark" : "doc.on.doc"
                )
            }
            .help(store.showCopyConfirmation ? "Copied to clipboard" : "Copy generated prompt to clipboard (⇧⌘C)")
            .disabled(!store.hasComments)
        }

        if store.session.isSlashCommandMode {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.doneRequested)
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                }
                .help("Send prompt to agent and close (⌘↩)")
                .disabled(!store.hasComments || store.session.doneState != .idle)
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            if response == .OK {
                store.send(.filesDropped(panel.urls))
            }
        }
    }
}
