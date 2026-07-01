import SwiftUI
import ComposableArchitecture
import AppKit

/// Empty state drop zone with SF Symbols, .onDrop handler
struct FileDropZoneView: View {
    let store: StoreOf<AppFeature>
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Drop Files Here")
                .font(.title2)
                .fontWeight(.medium)

            Text("or open files to start reviewing")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Open Files...") {
                    openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Paste from Clipboard") {
                    store.send(.pasteFileFromClipboard)
                }
                .keyboardShortcut("v", modifiers: .command)
            }
            .padding(.top, 8)
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
