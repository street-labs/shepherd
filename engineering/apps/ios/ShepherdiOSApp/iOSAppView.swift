import SwiftUI
import ComposableArchitecture
import SharedModels
import AppFeature
import FileBrowserFeature
import CodeViewerFeature
import CommentFeature
import InspectorFeature
import ReviewContextFeature
import IdentityFeature
import OpenPatchFeature

/// Adaptive iOS root view. Reflows between a compact single-pane stack (iPhone)
/// and an expanded three-column split (iPad) via `NavigationSplitView`, which
/// SwiftUI selects automatically from the horizontal size class.
// Implements: FR-crp-ios-adaptive-layout, FR-crp-file-display, FR-crp-filename-display, FR-crp-active-file-path, FR-crp-file-reviewed-progress, FR-sri-identity-indicator, FR-id-active-indicator
public struct iOSAppView: View {
    @Bindable public var store: StoreOf<AppFeature>
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.files.isEmpty {
                // Patch-only entry: no local file loading on iOS.
                // Implements: FR-crp-ios-patch-only-entry, FR-sri-patch-open-entry
                // NavigationStack hosts the toolbar (gear → Settings) in the
                // empty state; without it toolbar items are silently dropped.
                NavigationStack {
                    EmptyStateView(store: store)
                        .settingsToolbar(store: store)
                }
            } else {
                NavigationSplitView(
                    columnVisibility: $columnVisibility,
                    sidebar: {
                        FileBrowserView(
                            store: store.scope(state: \.fileBrowser, action: \.fileBrowser),
                            files: store.files,
                            allComments: store.allComments,
                            activeFileID: store.activeFileID
                        )
                        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 500)
                        .navigationTitle(store.activeFile?.filePath ?? "Shepherd")
                        .navigationBarTitleDisplayMode(.inline)
                        .settingsToolbar(store: store)
                    },
                    content: {
                        CodeViewerPanelView(store: store)
                            // End the review and return to the entry screen (Open
                            // Patch / Browse PRs). Reuses the clear-session flow
                            // (confirms when unsaved comments exist). iOS-only:
                            // macOS has menu commands; the iPhone UI had no path
                            // back once a review loaded.
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button {
                                        store.send(.clearSessionRequested)
                                    } label: {
                                        Label("Close Review", systemImage: "xmark")
                                    }
                                    .accessibilityLabel("Close Review")
                                }
                            }
                    },
                    detail: {
                        inspectorPanel
                    }
                )
            }
        }
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
        }
        .onAppear {
            // Triggers loadIdentityAtLaunch (presents the Identity sheet when no
            // identity is stored). Implements: FR-id-screen-when-no-identity,
            // FR-sri-identity-load, FR-id-ios-screen-is-only-path
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
            onReplyToPatchReply: { reply in store.send(.replyToPatchReply(reply)) },
            approvalState: store.approvalState.map { state in
                switch state {
                case .publishing: return .publishing
                case .approved: return .approved
                case .failed(let msg): return .failed(msg)
                }
            },
            onApprove: { store.send(.approvePRTapped) }
        )
    }
}

/// Gear toolbar item (Settings entry point). Implements: FR-sri-relay-settings.
/// Must be applied inside a navigation container (NavigationStack/
/// NavigationSplitView column); attached outside one, iOS drops it silently.
private extension View {
    func settingsToolbar(store: StoreOf<AppFeature>) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.settingsRequested)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
    }
}
