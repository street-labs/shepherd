import SwiftUI
import ComposableArchitecture
import AppFeature

// Implements: FR-crp-ios-system-appearance, FR-crp-ios-background-handoff
@main
struct ShepherdiOSApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            // Follows the device light/dark setting (no in-app toggle).
            // Implements: FR-crp-ios-system-appearance
            iOSAppView(store: store)
        }
    }
}
