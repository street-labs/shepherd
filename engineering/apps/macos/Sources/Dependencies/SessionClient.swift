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
