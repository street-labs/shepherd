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
            // Force an initial layout/draw pass shortly after launch. A freshly created
            // SwiftUI window — most reliably when the root view swaps to a NavigationSplitView
            // as session data loads asynchronously — can stay blank (empty sidebar and
            // content) until the user first resizes it. Nudging the window width by 1pt and
            // back triggers the same layout pass the manual resize does. The delay lets the
            // async session load switch the root view in first.
            try? await Task.sleep(for: .milliseconds(200))
            await MainActor.run {
                guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first
                else { return }
                let frame = window.frame
                var nudged = frame
                nudged.size.width += 1
                window.setFrame(nudged, display: true)
                window.setFrame(frame, display: true)
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
