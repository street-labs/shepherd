#if os(macOS)
import AppKit
#endif
import ComposableArchitecture

/// Window management operations.
/// Implements: FR-crp-macos-window-management, FR-crp-macos-auto-close
@DependencyClient
public struct WindowClient: Sendable {
    /// Close the frontmost window.
    public var closeWindow: @Sendable () async -> Void
    /// Bring a window with a given session ID to the front.
    /// Returns true if an existing window was found and activated.
    /// (Non-throwing, non-Void endpoint: @DependencyClient requires an explicit default.)
    public var bringWindowToFront: @Sendable (String) async -> Bool = { _ in false }
}

extension WindowClient: DependencyKey {
    public static let liveValue: WindowClient = {
        #if os(macOS)
        return WindowClient(
            closeWindow: {
                await MainActor.run {
                    NSApplication.shared.keyWindow?.close()
                }
            },
            bringWindowToFront: { sessionID in
                await MainActor.run {
                    // A closed window can linger in `windows`; only a shown (or minimized) one counts.
                    for window in NSApplication.shared.windows where window.isVisible || window.isMiniaturized {
                        if window.frameAutosaveName == "session-\(sessionID)" {
                            window.makeKeyAndOrderFront(nil)
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            return true
                        }
                    }
                    return false
                }
            }
        )
        #else
        // iOS: no multi-window, no frame autosave. No-ops so the shared AppFeature
        // reducer's window lifecycle actions are harmless on iOS.
        return WindowClient(
            closeWindow: {},
            bringWindowToFront: { _ in false }
        )
        #endif
    }()

    public static let testValue = Self()
}

extension DependencyValues {
    public var windowClient: WindowClient {
        get { self[WindowClient.self] }
        set { self[WindowClient.self] = newValue }
    }
}
