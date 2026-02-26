import AppKit
import ComposableArchitecture

/// Window management operations.
/// Implements: FR-crp-macos-window-management, FR-crp-macos-auto-close
public struct WindowClient: Sendable {
    /// Close the frontmost window.
    public var closeWindow: @Sendable () async -> Void
    /// Bring a window with a given session ID to the front.
    /// Returns true if an existing window was found and activated.
    public var bringWindowToFront: @Sendable (String) async -> Bool
    /// Configure window geometry persistence for a session.
    public var configureAutosave: @Sendable (String?) async -> Void

    public init(
        closeWindow: @escaping @Sendable () async -> Void,
        bringWindowToFront: @escaping @Sendable (String) async -> Bool,
        configureAutosave: @escaping @Sendable (String?) async -> Void
    ) {
        self.closeWindow = closeWindow
        self.bringWindowToFront = bringWindowToFront
        self.configureAutosave = configureAutosave
    }
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

    public static let testValue = WindowClient(
        closeWindow: unimplemented("WindowClient.closeWindow"),
        bringWindowToFront: unimplemented("WindowClient.bringWindowToFront"),
        configureAutosave: unimplemented("WindowClient.configureAutosave")
    )
}

extension DependencyValues {
    public var windowClient: WindowClient {
        get { self[WindowClient.self] }
        set { self[WindowClient.self] = newValue }
    }
}
