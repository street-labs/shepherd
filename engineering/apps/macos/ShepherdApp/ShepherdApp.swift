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
        WindowGroup {
            AppView(store: store)
        }
        .commands {
            ShepherdCommands(store: store)
        }
        .handlesExternalEvents(matching: ["shepherd"])
    }
}
