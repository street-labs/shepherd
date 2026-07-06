import SwiftUI
import AppKit
import ComposableArchitecture
import AppFeature

@main
struct ShepherdApp: App {
    let store: StoreOf<AppFeature>

    init() {
        // Bare SwiftPM exe (no .app bundle): force regular policy + activate
        // so window becomes key and TextEditor accepts input (no beep).
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        let sessionID = Self.parseSessionID()
        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
        }
        if let sessionID {
            store.send(.session(.launched(sessionID: sessionID)))
        }
    }

    static func parseSessionID() -> String? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--session"),
              idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    var body: some Scene {
        // Implements: FR-crp-macos-window-management
        WindowGroup {
            AppView(store: store)
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
            ShepherdCommands(store: store)
        }
        .handlesExternalEvents(matching: ["shepherd"])
    }
}
