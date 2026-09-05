#if os(macOS)
import SwiftUI
import ComposableArchitecture
import SharedModels
import FileBrowserFeature
import CodeViewerFeature
import CommentFeature
import InspectorFeature
import PromptFeature
import ReviewContextFeature
import IdentityFeature
import OpenPatchFeature
import PRBrowseFeature

/// Root view. Implements the layout described in the design spec.
/// Conditional layout: empty -> FileDropZone, 1 file -> HSplitView, 2+ -> NavigationSplitView
public struct AppView: View {
    @Bindable public var store: StoreOf<AppFeature>
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isDropTargeted = false

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.files.isEmpty {
                FileDropZoneView(store: store)
            } else if store.isMultiFile {
                // Force the sidebar column visible. With the default `.automatic`
                // visibility, the file-browser column intermittently launches collapsed
                // (the sidebar appears empty even though the file tree is populated).
                // Pinning `columnVisibility` to `.all` keeps it reliably on screen.
                NavigationSplitView(
                    columnVisibility: $columnVisibility,
                    sidebar: {
                        FileBrowserView(
                            store: store.scope(state: \.fileBrowser, action: \.fileBrowser),
                            files: store.files,
                            allComments: store.allComments,
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
        // Verdict sheet (approve / request changes). Implements: FR-pa-review.
        .sheet(item: Binding(
            get: { store.verdictSheet },
            set: { if $0 == nil { store.send(.dismissVerdictSheet) } }
        )) { _ in
            VerdictSheetView(store: store)
        }
        // Highlight the window as a valid drop target while files are dragged over
        // it (loaded state; the empty state has its own zone). Implements: FR-crp-macos-drag-drop-finder
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay {
            if isDropTargeted && !store.files.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .padding(2)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isDropTargeted)
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.identity, action: \.identity)) { identityStore in
            IdentityView(store: identityStore)
        }
        .sheet(item: $store.scope(state: \.openPatch, action: \.openPatch)) { openPatchStore in
            OpenPatchView(store: openPatchStore)
        }
        .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            SettingsView(store: settingsStore) {
                store.send(.openIdentityScreen)
            }
            .frame(minWidth: 440, minHeight: 320)
        }
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
            allComments: store.allComments,
            files: store.files,
            reviewContext: store.reviewContextData,
            reviewContextStore: store.scope(state: \.reviewContext, action: \.reviewContext),
            reviewerIdentity: store.reviewerIdentity,
            showPublishConfirmation: store.showPublishConfirmation,
            // Merge control for maintainers on an open PR. Implements:
            // FR-pa-merge, FR-pa-capabilities.
            mergeSection: mergeSection,
            onReplyToPatchReply: { reply in store.send(.replyToPatchReply(reply)) }
        )
    }

    /// Merge control info for the metadata section, only for maintainers
    /// reviewing an open PR. Implements: FR-pa-capabilities, AC-pa-capabilities.
    private var mergeSection: MergeSection? {
        guard store.isPRReview, store.canMerge else { return nil }
        let gate = store.mergeGate
        return MergeSection(
            gatePasses: gate?.passes ?? false,
            gateReason: gate?.passes == false ? gate?.failureReason : nil,
            inFlight: store.mergeInFlight
        ) {
            store.send(.mergePR)
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
