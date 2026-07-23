import Foundation
import ComposableArchitecture
import SharedModels

/// Session directory operations.
/// Implements: FR-crp-prompt-handoff, FR-crp-macos-slash-command-launch
@DependencyClient
public struct SessionClient: Sendable {
    /// Load session data from ~/.shepherd/sessions/<session-id>/
    public var loadSession: @Sendable (String) async throws -> SessionData
    /// Write prompt output to the session directory.
    public var writePromptOutput: @Sendable (String, String) async throws -> Void
    /// Load refreshed patch-thread replies from the session sidecar
    /// `~/.shepherd/sessions/<session-id>/patch-replies.json`, written by the
    /// background poller. Implements: FR-sr-patch-replies-live. Returns an empty
    /// array when the sidecar is absent (no poller running / no replies yet).
    public var loadPatchReplies: @Sendable (String) async throws -> [ReviewContext.PatchReply]
}

extension SessionClient: DependencyKey {
    public static let liveValue = SessionClient(
        loadSession: { sessionID in
            let sessionDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)")
            let sessionFile = sessionDir.appendingPathComponent("session.json")
            let data = try Data(contentsOf: sessionFile)
            return try JSONDecoder().decode(SessionData.self, from: data)
        },
        writePromptOutput: { sessionID, promptText in
            let outputPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)/prompt-output.md")
            try promptText.write(to: outputPath, atomically: true, encoding: .utf8)
        },
        loadPatchReplies: { sessionID in
            let sidecar = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)/patch-replies.json")
            guard FileManager.default.fileExists(atPath: sidecar.path) else {
                return []
            }
            let data = try Data(contentsOf: sidecar)
            return try JSONDecoder().decode([ReviewContext.PatchReply].self, from: data)
        }
    )

    public static let testValue = Self()
}

extension DependencyValues {
    public var sessionClient: SessionClient {
        get { self[SessionClient.self] }
        set { self[SessionClient.self] = newValue }
    }
}
