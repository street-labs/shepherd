#if os(macOS)
import SwiftUI
import ComposableArchitecture
import PRBrowseFeature
import AppKit

/// Empty state: the default PR Browse surface (FR-pb-default-state) plus the
/// entry-point button row and file drag-and-drop. Implements the layout in
/// `design/macos/pr-browse.md` (Entry point) and `design/macos/shepherd-review.md`
/// (FR-srm-patch-open-entry button row).
struct FileDropZoneView: View {
    let store: StoreOf<AppFeature>
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button("Open Files...") {
                    openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Paste from Clipboard") {
                    store.send(.pasteFileFromClipboard)
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Open Patch or PR…") {
                    store.send(.openPatchRequested)
                }
                // Implements: FR-srm-patch-open-entry
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help("Open a NIP-34 patch or PR by event id (⌘⇧P)")
                .accessibilityLabel("Open a NIP-34 patch or PR by event id")
            }

            Text("or drop files anywhere")
                .font(.body)
                .foregroundStyle(.secondary)

            // Implements: FR-pb-default-state
            // (browse is the default empty state)
            PRBrowseView(
                store: store.scope(state: \.prBrowse, action: \.prBrowse)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundColor(isTargeted ? .blue : .gray.opacity(0.3))
                .padding(24)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
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

    private func handleDrop(providers: [NSItemProvider]) {
        // loadItem completions run concurrently, so accumulate through a lock-isolated
        // box rather than mutating a captured `var` (a data race under strict concurrency).
        let urls = LockIsolated<[URL]>([])
        let group = DispatchGroup()
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                    if let data = data as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.withValue { $0.append(url) }
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            let collected = urls.value
            if !collected.isEmpty {
                store.send(.filesDropped(collected))
            }
        }
    }
}

#endif
