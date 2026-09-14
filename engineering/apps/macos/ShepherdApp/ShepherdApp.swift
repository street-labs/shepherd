import SwiftUI
import AppKit
import ComposableArchitecture
import AppFeature

@main
struct ShepherdApp: App {
    init() {
        // Never restore windows from a previous run: a review window belongs to a CLI
        // session that is gone by then, and restored blank windows pile up on every
        // relaunch after the app is killed.
        UserDefaults.standard.register(defaults: ["ApplePersistenceIgnoreState": true])
        // Bare SwiftPM exe (no .app bundle): force regular policy + activate
        // so window becomes key and TextEditor accepts input (no beep).
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        // One process, one window per review session. The window's value is its
        // session ID (nil for a standalone window), so `openWindow(value:)` with an
        // already-open session brings that window to the front instead of opening a
        // duplicate.
        // Implements: FR-crp-macos-window-management, FR-crp-macos-slash-command-launch
        WindowGroup(for: String.self) { $sessionID in
            ReviewWindow(sessionID: $sessionID)
        }
        // Set the initial window size explicitly. Without this, SwiftUI sizes a new
        // window to its content's ideal height — and the code viewer's ScrollView reports
        // the full file height as its ideal, so a fresh session opens a window thousands
        // of points tall (its bottom far below the screen, with nothing to scroll).
        // `.defaultSize` fixes the initial size without wrapping `AppView` (which is a
        // `NavigationSplitView` in multi-file mode) in a `.frame` — wrapping the split
        // view in a frame collapses its sidebar column. The window stays freely resizable.
        .defaultSize(width: 1280, height: 800)
        .commands {
            ShepherdCommands()
        }
        .handlesExternalEvents(matching: ["shepherd"])
    }
}

/// One review window with its own store, so windows never share session state.
struct ReviewWindow: View {
    /// The window's scene value. Setting it re-keys the window, so a blank window can
    /// adopt a session.
    @Binding var sessionID: String?
    @State private var store = Store(initialState: AppFeature.State()) { AppFeature() }
    @State private var window: NSWindow?
    @Environment(\.openWindow) private var openWindow
    @Dependency(\.windowClient) private var windowClient

    var body: some View {
        AppView(store: store)
            .focusedSceneValue(\.reviewStore, store)
            .background(WindowReader(window: $window))
            // Implements: FR-crp-macos-window-management
            .task(id: TaskKey(sessionID: sessionID, window: window)) {
                guard let sessionID, let window else { return }
                if store.session.sessionID == nil {
                    store.send(.session(.launched(sessionID: sessionID)))
                }
                // Keys this window for dedup (`bringWindowToFront`) and per-session geometry.
                window.setFrameAutosaveName("session-\(sessionID)")
                // A freshly created SwiftUI window — most reliably when the root view swaps
                // to a NavigationSplitView as session data loads — can stay blank until the
                // user first resizes it. Nudging the width by 1pt and back triggers the same
                // layout pass. The delay lets the async session load swap the root view in.
                try? await Task.sleep(for: .milliseconds(200))
                let frame = window.frame
                var nudged = frame
                nudged.size.width += 1
                window.setFrame(nudged, display: true)
                window.setFrame(frame, display: true)
            }
            // Any open window may receive an inbound shepherd:// link; without this
            // SwiftUI spawns a blank window per link.
            .handlesExternalEvents(preferring: ["shepherd"], allowing: ["shepherd"])
            // Implements: FR-srm-deeplink-scheme, FR-srm-deeplink-cold-launch, FR-srm-deeplink-malformed, FR-sc-mac-launch, FR-crp-macos-slash-command-launch
            .onOpenURL { url in
                guard let session = AppFeature.parseSessionDeeplink(url) else {
                    store.send(.deeplinkReceived(url))
                    return
                }
                Task {
                    // An open session's window comes forward instead of opening a duplicate.
                    if await windowClient.bringWindowToFront(session) { return }
                    // A blank window (the default window a cold launch delivers the link
                    // to) adopts the session; otherwise the session gets its own window.
                    if sessionID == nil, store.files.isEmpty {
                        sessionID = session
                    } else {
                        openWindow(value: session)
                    }
                }
            }
    }

    private struct TaskKey: Equatable {
        let sessionID: String?
        let window: NSWindow?
    }
}

/// Reports the NSWindow hosting this view, so per-window AppKit setup targets the right
/// window rather than whichever one happens to be key.
private struct WindowReader: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onWindow = { window in DispatchQueue.main.async { self.window = window } }
        return view
    }

    func updateNSView(_ nsView: ReaderView, context: Context) {}

    final class ReaderView: NSView {
        var onWindow: (NSWindow?) -> Void = { _ in }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindow(window)
        }
    }
}

struct ReviewStoreKey: FocusedValueKey {
    typealias Value = StoreOf<AppFeature>
}

extension FocusedValues {
    var reviewStore: StoreOf<AppFeature>? {
        get { self[ReviewStoreKey.self] }
        set { self[ReviewStoreKey.self] = newValue }
    }
}
