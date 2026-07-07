import SwiftUI
import ComposableArchitecture
import AppFeature
import AppKit

/// Implements: FR-crp-macos-menu-bar, FR-crp-macos-keyboard-shortcuts,
/// AC-crp-macos-menu-shortcuts
struct ShepherdCommands: Commands {
    let store: StoreOf<AppFeature>

    var body: some Commands {
        // File menu
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                openFilePicker()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Paste as File") {
                store.send(.pasteFileFromClipboard)
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }

        // Review menu
        CommandMenu("Review") {
            // Persistent global comment count. Implements: FR-crp-comment-count
            Text("\(store.commentCount) Comment\(store.commentCount == 1 ? "" : "s")")

            Divider()

            Button("Copy Prompt") {
                store.send(.copyPrompt)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(!store.hasComments)

            if store.session.isSlashCommandMode {
                Button("Done") {
                    store.send(.doneRequested)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!store.hasComments || store.session.doneState != .idle)
            }

            Divider()

            Button("Next Comment") {
                store.send(.comment(.navigateComment(.next)))
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!store.hasComments)

            Button("Previous Comment") {
                store.send(.comment(.navigateComment(.previous)))
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!store.hasComments)

            Divider()

            Button("Mark Current File as Reviewed") {
                if let id = store.activeFileID {
                    store.send(.fileBrowser(.toggleFileReviewed(id)))
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(store.activeFileID == nil)

            Divider()

            Button("Clear Session") {
                store.send(.clearSessionRequested)
            }
            .disabled(store.files.isEmpty)
        }

        // View menu
        CommandGroup(replacing: .toolbar) {
            Button("Toggle Line Wrapping") {
                store.send(.toggleLineWrap)
            }
            .disabled(store.files.isEmpty)
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
