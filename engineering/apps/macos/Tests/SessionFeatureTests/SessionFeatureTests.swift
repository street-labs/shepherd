import Testing
import ComposableArchitecture
import Foundation
@testable import SessionFeature
@testable import SharedModels
@testable import ShepherdDependencies

@Suite("SessionFeature")
@MainActor
struct SessionFeatureTests {
    @Test("Launch without session ID sets standalone mode")
    func launchStandalone() async {
        let store = TestStore(initialState: SessionFeature.State()) {
            SessionFeature()
        }

        await store.send(.launched(sessionID: nil))
        // State unchanged — sessionID and isSlashCommandMode are already default values
    }

    @Test("Launch with session ID sets slash command mode and loads data")
    func launchWithSession() async {
        let mockSession = SessionData(
            sessionID: "abc123",
            workingDirectory: "/Users/dev/project",
            projectName: "myproject",
            files: [.init(path: "src/main.swift", content: "let x = 1")],
            reviewContext: nil
        )

        let store = TestStore(initialState: SessionFeature.State()) {
            SessionFeature()
        } withDependencies: {
            $0.sessionClient.loadSession = { @Sendable _ in mockSession }
        }

        await store.send(.launched(sessionID: "abc123")) {
            $0.sessionID = "abc123"
            $0.isSlashCommandMode = true
        }

        await store.receive(\.sessionDataLoaded) {
            $0.projectName = "myproject"
        }
    }

    @Test("Session load failure is handled")
    func sessionLoadFailure() async {
        let store = TestStore(initialState: SessionFeature.State()) {
            SessionFeature()
        } withDependencies: {
            $0.sessionClient.loadSession = { @Sendable _ in
                throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
        }

        await store.send(.launched(sessionID: "bad-id")) {
            $0.sessionID = "bad-id"
            $0.isSlashCommandMode = true
        }

        await store.receive(\.sessionDataLoadFailed)
    }

    @Test("Window title uses project name when available")
    func windowTitleWithProject() {
        let state = SessionFeature.State(projectName: "my-app")
        #expect(state.windowTitle == "Shepherd — my-app")
    }

    @Test("Window title is Shepherd when no project")
    func windowTitleDefault() {
        let state = SessionFeature.State()
        #expect(state.windowTitle == "Shepherd")
    }
}
