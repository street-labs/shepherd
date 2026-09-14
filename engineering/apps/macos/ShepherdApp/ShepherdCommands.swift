import SwiftUI
import ComposableArchitecture
import AppFeature
import AppKit

/// Implements: FR-crp-macos-menu-bar, FR-crp-macos-keyboard-shortcuts,
/// AC-crp-macos-menu-shortcuts
struct ShepherdCommands: Commands {
    // The focused window's store; nil when no review window is key.
    @FocusedValue(\.reviewStore) private var store

    var body: some Commands {
        // File menu
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                openFilePicker()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Paste as File") {
                store?.send(.pasteFileFromClipboard)
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }

        // Review menu
        CommandMenu("Review") {
            // Persistent global comment count. Implements: FR-crp-comment-count
            Text("\(commentCount) Comment\(commentCount == 1 ? "" : "s")")

            Divider()

            Button("Copy Prompt") {
                store?.send(.copyPrompt)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(!hasComments)

            if store?.session.isSlashCommandMode == true {
                Button("Done") {
                    store?.send(.doneRequested)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!hasComments || store?.session.doneState != .idle)
            }

            Divider()

            Button("Next Comment") {
                store?.send(.comment(.navigateComment(.next)))
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!hasComments)

            Button("Previous Comment") {
                store?.send(.comment(.navigateComment(.previous)))
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!hasComments)

            Divider()

            Button("Mark Current File as Reviewed") {
                if let id = store?.activeFileID {
                    store?.send(.fileBrowser(.toggleFileReviewed(id)))
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(store?.activeFileID == nil)

            Divider()

            Button("Identity…") {
                store?.send(.openIdentityScreen)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            // Implements: FR-srm-relay-settings — same in-app Settings surface as iOS.
            Button("Settings…") {
                store?.send(.settingsRequested)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Clear Session") {
                store?.send(.clearSessionRequested)
            }
            .disabled(store?.files.isEmpty ?? true)
        }

        // View menu
        CommandGroup(replacing: .toolbar) {
            Button("Toggle Line Wrapping") {
                store?.send(.toggleLineWrap)
            }
            .disabled(store?.files.isEmpty ?? true)
        }
    }

    private var commentCount: Int { store?.commentCount ?? 0 }
    private var hasComments: Bool { store?.hasComments ?? false }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            if response == .OK {
                store?.send(.filesDropped(panel.urls))
            }
        }
    }
}
