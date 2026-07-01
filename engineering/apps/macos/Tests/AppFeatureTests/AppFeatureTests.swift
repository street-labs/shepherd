import Testing
import ComposableArchitecture
import Foundation
import IdentifiedCollections
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import FileBrowserFeature
@testable import CodeViewerFeature
@testable import CommentFeature
@testable import InspectorFeature
@testable import PromptFeature
@testable import SessionFeature
@testable import ReviewContextFeature

@Suite("AppFeature")
@MainActor
struct AppFeatureTests {
    @Test("Files loaded creates file nodes and selects first file")
    func filesLoaded() async {
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(testUUID)
            $0.syntaxHighlightClient.highlight = { @Sendable _, _ in [] }
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.filesLoaded([LoadedFile(content: "const x = 1;", name: "test.ts", url: nil)])) {
            $0.$files.withLock { $0 = [
                FileNode(
                    id: testUUID,
                    name: "test.ts",
                    language: .typescript,
                    content: "const x = 1;"
                )
            ] }
            $0.activeFileID = testUUID
        }
    }

    @Test("Clear session requires confirmation")
    func clearSessionConfirmation() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.clearSessionRequested) {
            $0.alert = AlertState {
                TextState("Clear Session")
            } actions: {
                ButtonState(role: .destructive, action: .clearConfirmed) {
                    TextState("Clear")
                }
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
            } message: {
                TextState("Remove all files and comments? This cannot be undone.")
            }
        }
    }

    @Test("Clear session confirmed removes all state")
    func clearSessionConfirmed() async {
        let fileID = UUID()
        var initialState = AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            allComments: Shared(value: [SharedModels.Comment(fileID: fileID, startLine: 1, endLine: 1, text: "hi")]),
            activeFileID: fileID,
            overallComment: "preamble"
        )
        initialState.alert = AlertState {
            TextState("Clear Session")
        } actions: {
            ButtonState(role: .destructive, action: .clearConfirmed) {
                TextState("Clear")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("Remove all files and comments? This cannot be undone.")
        }
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.alert(.presented(.clearConfirmed))) {
            $0.alert = nil
            $0.$files.withLock { $0 = [] }
            $0.$allComments.withLock { $0 = [] }
            $0.activeFileID = nil
            $0.overallComment = ""
        }
    }

    @Test("Remove file without comments removes immediately")
    func removeFileNoComments() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.removeFileRequested(fileID)) {
            $0.$files.withLock { $0 = [] }
            $0.activeFileID = nil
        }
    }

    @Test("Remove file with comments requires confirmation")
    func removeFileWithComments() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            allComments: Shared(value: [SharedModels.Comment(fileID: fileID, startLine: 1, endLine: 1, text: "comment")]),
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.removeFileRequested(fileID)) {
            $0.alert = AlertState {
                TextState("Remove File")
            } actions: {
                ButtonState(role: .destructive, action: .removeFileConfirmed(fileID)) {
                    TextState("Remove")
                }
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
            } message: {
                TextState("This file has comments. Remove it and its comments?")
            }
        }
    }

    @Test("Toggle line wrap")
    func toggleLineWrap() async {
        let store = TestStore(initialState: AppFeature.State(lineWrapEnabled: true)) {
            AppFeature()
        }
        store.exhaustivity = .off

        await store.send(.toggleLineWrap) {
            $0.lineWrapEnabled = false
        }
    }

    @Test("Submit creating comment appends to allComments and clears editor")
    func submitCreatingComment() async {
        let fileID = UUID()
        let commentID = UUID(uuidString: "00000000-0000-0000-0000-0000000000aa")!
        var initialState = AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x\ny\nz")]),
            activeFileID: fileID
        )
        initialState.comment.editorState = .creating(anchorLine: 2, endLine: 2)
        initialState.comment.editorText = "Rename this"

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(commentID)
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment)) {
            $0.$allComments.withLock { comments in
                comments = [
                    SharedModels.Comment(
                        id: commentID,
                        fileID: fileID,
                        startLine: 2,
                        endLine: 2,
                        text: "Rename this",
                        createdAt: comments.first?.createdAt ?? Date()
                    )
                ]
            }
            $0.comment.editorState = nil
            $0.comment.editorText = ""
        }
    }

    @Test("Submit editing comment updates existing text")
    func submitEditingComment() async {
        let fileID = UUID()
        let commentID = UUID()
        var initialState = AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            allComments: Shared(value: [SharedModels.Comment(
                id: commentID,
                fileID: fileID,
                startLine: 1,
                endLine: 1,
                text: "old"
            )]),
            activeFileID: fileID
        )
        initialState.comment.editorState = .editing(commentID: commentID)
        initialState.comment.editorText = "new text"

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment)) {
            $0.$allComments.withLock { $0[id: commentID]?.text = "new text" }
            $0.comment.editorState = nil
            $0.comment.editorText = ""
        }
    }

    @Test("Submit with whitespace-only text does not create comment")
    func submitWhitespaceComment() async {
        let fileID = UUID()
        var initialState = AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x")]),
            activeFileID: fileID
        )
        initialState.comment.editorState = .creating(anchorLine: 1, endLine: 1)
        initialState.comment.editorText = "   "

        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment))
        #expect(store.state.allComments.isEmpty)
        #expect(store.state.comment.editorState != nil)
    }

    @Test("Shared files/comments are connected across parent and children")
    func sharedStateConnected() {
        let state = AppFeature.State()
        state.$files.withLock { $0 = [FileNode(id: UUID(), name: "a.ts", content: "x")] }
        state.$allComments.withLock {
            $0 = [SharedModels.Comment(fileID: UUID(), startLine: 1, endLine: 1, text: "c")]
        }
        // The child features read files/allComments from the SAME @Shared storage, so no
        // view-param threading is needed. If the wiring broke, these would be empty.
        #expect(state.fileBrowser.files.count == 1)
        #expect(state.fileBrowser.allComments.count == 1)
        #expect(state.inspector.files.count == 1)
        #expect(state.inspector.allComments.count == 1)
    }

    @Test("Toggle file reviewed")
    func toggleFileReviewed() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: Shared(value: [FileNode(id: fileID, name: "test.ts", content: "x", isReviewed: false)])
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.fileBrowser(.toggleFileReviewed(fileID))) {
            $0.$files.withLock { $0[id: fileID]?.isReviewed = true }
        }
    }
}
