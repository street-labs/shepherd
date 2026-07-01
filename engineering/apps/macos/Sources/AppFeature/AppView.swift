import SwiftUI
import ComposableArchitecture
import SharedModels
import FileBrowserFeature
import CodeViewerFeature
import CommentFeature
import InspectorFeature
import PromptFeature
import ReviewContextFeature

/// Root view. Implements the layout described in the design spec.
/// Conditional layout: empty -> FileDropZone, 1 file -> HSplitView, 2+ -> NavigationSplitView
public struct AppView: View {
    @Bindable public var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.files.isEmpty {
                FileDropZoneView(store: store)
            } else if store.isMultiFile {
                NavigationSplitView(
                    sidebar: {
                        FileBrowserView(
                            store: store.scope(state: \.fileBrowser, action: \.fileBrowser),
                            activeFileID: store.activeFileID
                        )
                        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 500)
                    },
                    content: {
                        CodeViewerPanelView(store: store)
                    },
                    detail: {
                        inspectorPanel
                    }
                )
            } else {
                HSplitView {
                    CodeViewerPanelView(store: store)
                    inspectorPanel
                        .frame(minWidth: 240, idealWidth: 340)
                }
            }
        }
        .toolbar {
            ToolbarView(store: store)
        }
        .navigationTitle(store.session.windowTitle)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.windowAppeared)
        }
    }

    @ViewBuilder
    private var inspectorPanel: some View {
        InspectorView(
            store: store.scope(state: \.inspector, action: \.inspector),
            overallComment: $store.overallComment,
            generatedPrompt: store.prompt.generatedPrompt,
            reviewContext: store.reviewContextData,
            reviewContextStore: store.scope(state: \.reviewContext, action: \.reviewContext)
        )
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
