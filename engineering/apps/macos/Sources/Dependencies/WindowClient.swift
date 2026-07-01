import AppKit
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
    /// Configure window geometry persistence for a session.
    public var configureAutosave: @Sendable (String?) async -> Void
}

extension WindowClient: DependencyKey {
    public static let liveValue = WindowClient(
        closeWindow: {
            await MainActor.run {
                NSApplication.shared.keyWindow?.close()
            }
        },
        bringWindowToFront: { sessionID in
            await MainActor.run {
                for window in NSApplication.shared.windows {
                    if window.frameAutosaveName == "session-\(sessionID)" {
                        window.makeKeyAndOrderFront(nil)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        return true
                    }
                }
                return false
            }
        },
        configureAutosave: { sessionID in
            await MainActor.run {
                guard let window = NSApplication.shared.keyWindow else { return }
                let name = sessionID.map { "session-\($0)" } ?? "standalone"
                window.setFrameAutosaveName(name)
            }
        }
    )

    public static let testValue = Self()
}

extension DependencyValues {
    public var windowClient: WindowClient {
        get { self[WindowClient.self] }
        set { self[WindowClient.self] = newValue }
    }
}
