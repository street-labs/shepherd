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
            $0.files = [
                FileNode(
                    id: testUUID,
                    name: "test.ts",
                    language: .typescript,
                    content: "const x = 1;"
                )
            ]
            $0.activeFileID = testUUID
        }
    }

    @Test("Clear session requires confirmation when comments exist")
    func clearSessionConfirmation() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            allComments: [SharedModels.Comment(fileID: fileID, startLine: 1, endLine: 1, text: "hi")],
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

    // Implements: AC-crp-clear-no-confirm-empty
    @Test("Clear session with no comments clears immediately without confirmation")
    func clearSessionNoConfirmWhenEmpty() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.clearSessionRequested) {
            $0.files = []
            $0.activeFileID = nil
            $0.alert = nil
        }
    }

    // Implements: FR-sr-patch-replies-live (merge reducer)
    @Test("Patch replies refresh replaces, dedupes by id, orders oldest-first")
    func patchRepliesRefreshedMerges() async {
        let meta = ReviewContext.PatchMetadata(
            eventID: String(repeating: "a", count: 64),
            shortEventID: "aaaaaaaa",
            author: "alice",
            commitMessage: "msg",
            parentCommit: nil,
            status: "open",
            replies: [
                ReviewContext.PatchReply(
                    id: "r1", author: "borg", authorPubkey: "pk1",
                    isBot: true, content: "first", timestamp: 1700000010
                )
            ]
        )
        let store = TestStore(initialState: AppFeature.State(
            reviewContextData: ReviewContext(overall: .init(), files: [:], patchMetadata: meta)
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        // New list: r1 (existing) + r2 (new), delivered out of order; r1 duped.
        let refreshed: [ReviewContext.PatchReply] = [
            ReviewContext.PatchReply(
                id: "r2", author: "luke", authorPubkey: "pk2",
                isBot: false, content: "second", timestamp: 1700000020
            ),
            ReviewContext.PatchReply(
                id: "r1", author: "borg", authorPubkey: "pk1",
                isBot: true, content: "first", timestamp: 1700000010
            ),
            ReviewContext.PatchReply(
                id: "r1", author: "borg", authorPubkey: "pk1",
                isBot: true, content: "first dup", timestamp: 1700000010
            )
        ]
        await store.send(.patchRepliesRefreshed(refreshed)) {
            $0.reviewContextData?.patchMetadata?.replies = [
                ReviewContext.PatchReply(
                    id: "r1", author: "borg", authorPubkey: "pk1",
                    isBot: true, content: "first", timestamp: 1700000010
                ),
                ReviewContext.PatchReply(
                    id: "r2", author: "luke", authorPubkey: "pk2",
                    isBot: false, content: "second", timestamp: 1700000020
                )
            ]
        }
    }

    // Implements: FR-sr-patch-replies-live (no-op when not a patch review)
    @Test("Patch replies refresh is a no-op without patch metadata")
    func patchRepliesRefreshedNoopWithoutPatch() async {
        let store = TestStore(initialState: AppFeature.State(
            reviewContextData: ReviewContext(overall: .init(), files: [:], patchMetadata: nil)
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        let reply = ReviewContext.PatchReply(
            id: "r1", author: "x", authorPubkey: "pk", isBot: false,
            content: "hi", timestamp: 1
        )
        await store.send(.patchRepliesRefreshed([reply]))
        #expect(store.state.reviewContextData?.patchMetadata == nil)
    }

    @Test("Clear session confirmed removes all state")
    func clearSessionConfirmed() async {
        let fileID = UUID()
        var initialState = AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            allComments: [SharedModels.Comment(fileID: fileID, startLine: 1, endLine: 1, text: "hi")],
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
            $0.files = []
            $0.allComments = []
            $0.activeFileID = nil
            $0.overallComment = ""
        }
    }

    // Implements: AC-crp-copy-clipboard
    @Test("Prompt copied shows confirmation then auto-dismisses after 2s")
    func promptCopiedConfirmation() async {
        let clock = TestClock()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        store.exhaustivity = .off

        await store.send(.promptCopied) {
            $0.showCopyConfirmation = true
        }
        await clock.advance(by: .seconds(2))
        await store.receive(\.dismissCopyConfirmation) {
            $0.showCopyConfirmation = false
        }
    }

    // Implements: FR-crp-comment-navigation
    @Test("Navigating comments sets focused comment and viewer focused line")
    func commentNavigationFocusesLine() async {
        let fileID = UUID()
        let c1 = SharedModels.Comment(fileID: fileID, startLine: 5, endLine: 5, text: "a")
        let c2 = SharedModels.Comment(fileID: fileID, startLine: 20, endLine: 20, text: "b")
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "f.ts", content: String(repeating: "x\n", count: 30))],
            allComments: [c1, c2],
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        // First "next" with no current focus -> first comment (line 5), viewer scrolls there.
        await store.send(.comment(.navigateComment(.next))) {
            $0.comment.focusedCommentID = c1.id
            $0.codeViewer.focusedLine = 5
        }
        // Next -> second comment (line 20).
        await store.send(.comment(.navigateComment(.next))) {
            $0.comment.focusedCommentID = c2.id
            $0.codeViewer.focusedLine = 20
        }
    }

    // Implements: AC-crp-binary-file-rejected
    @Test("Binary / non-text file surfaces a Cannot Open File alert")
    func fileErrorBinaryAlert() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        store.exhaustivity = .off
        await store.send(.filesReadCompleted([.failed(name: "image.png", reason: .notText)])) {
            $0.alert = AlertState {
                TextState("Cannot Open File")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("This file does not appear to contain text. Only plain-text files are supported.")
            }
        }
    }

    // Implements: AC-crp-macos-file-permission-error
    @Test("Permission-denied file surfaces a Cannot Read File alert")
    func fileErrorPermissionAlert() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        store.exhaustivity = .off
        await store.send(.filesReadCompleted([.failed(name: "secret.txt", reason: .permissionDenied)])) {
            $0.alert = AlertState {
                TextState("Cannot Read File")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("The file could not be read. Check that the application has permission to access this file.")
            }
        }
    }

    @Test("Remove file without comments removes immediately")
    func removeFileNoComments() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            activeFileID: fileID
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.removeFileRequested(fileID)) {
            $0.files = []
            $0.activeFileID = nil
        }
    }

    @Test("Remove file with comments requires confirmation")
    func removeFileWithComments() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            allComments: [SharedModels.Comment(fileID: fileID, startLine: 1, endLine: 1, text: "comment")],
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
            files: [FileNode(id: fileID, name: "test.ts", content: "x\ny\nz")],
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
            $0.allComments = [
                SharedModels.Comment(
                    id: commentID,
                    fileID: fileID,
                    startLine: 2,
                    endLine: 2,
                    text: "Rename this",
                    createdAt: $0.allComments.first?.createdAt ?? Date()
                )
            ]
            $0.comment.editorState = nil
            $0.comment.editorText = ""
        }
    }

    @Test("Submit editing comment updates existing text")
    func submitEditingComment() async {
        let fileID = UUID()
        let commentID = UUID()
        var initialState = AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
            allComments: [SharedModels.Comment(
                id: commentID,
                fileID: fileID,
                startLine: 1,
                endLine: 1,
                text: "old"
            )],
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
            $0.allComments[id: commentID]?.text = "new text"
            $0.comment.editorState = nil
            $0.comment.editorText = ""
        }
    }

    @Test("Submit with whitespace-only text does not create comment")
    func submitWhitespaceComment() async {
        let fileID = UUID()
        var initialState = AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x")],
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

    @Test("Toggle file reviewed")
    func toggleFileReviewed() async {
        let fileID = UUID()
        let store = TestStore(initialState: AppFeature.State(
            files: [FileNode(id: fileID, name: "test.ts", content: "x", isReviewed: false)]
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        await store.send(.fileBrowser(.toggleFileReviewed(fileID))) {
            $0.files[id: fileID]?.isReviewed = true
        }
    }
}
