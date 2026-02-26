import ComposableArchitecture
import SharedModels
import ShepherdDependencies
import Foundation

/// Implements: FR-crp-macos-slash-command-launch, FR-crp-macos-standalone-mode,
/// FR-crp-session-identity, FR-crp-done-action, FR-crp-prompt-handoff,
/// FR-crp-macos-auto-close
@Reducer
public struct SessionFeature {
    @ObservableState
    public struct State: Equatable {
        /// The session ID (nil in standalone mode).
        public var sessionID: String?
        /// Whether the app was launched via slash command with a session.
        public var isSlashCommandMode: Bool = false
        /// The project name or working directory for the window title.
        public var projectName: String?
        /// Done button state.
        public var doneState: DoneState = .idle

        public enum DoneState: Equatable, Sendable {
            case idle, sending, sent
        }

        /// The window title derived from session context.
        /// Implements: FR-crp-session-identity
        public var windowTitle: String {
            if let name = projectName {
                return "Shepherd — \(name)"
            }
            return "Shepherd"
        }

        public init(
            sessionID: String? = nil,
            isSlashCommandMode: Bool = false,
            projectName: String? = nil,
            doneState: DoneState = .idle
        ) {
            self.sessionID = sessionID
            self.isSlashCommandMode = isSlashCommandMode
            self.projectName = projectName
            self.doneState = doneState
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case launched(sessionID: String?)
        case sessionDataLoaded(SessionData)
        case sessionDataLoadFailed(String)
    }

    @Dependency(\.sessionClient) var sessionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .launched(sessionID):
                state.sessionID = sessionID
                state.isSlashCommandMode = sessionID != nil
                guard let sessionID else { return .none }
                return .run { send in
                    let data = try await sessionClient.loadSession(sessionID)
                    await send(.sessionDataLoaded(data))
                } catch: { error, send in
                    await send(.sessionDataLoadFailed(error.localizedDescription))
                }

            case let .sessionDataLoaded(data):
                state.projectName = data.projectName ?? data.workingDirectory
                // Parent handles loading files and review context from data
                return .none

            case .sessionDataLoadFailed:
                // Parent may show an alert
                return .none
            }
        }
    }
}
