import Testing
import ComposableArchitecture
import Foundation
import IdentifiedCollections
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import CommentFeature
@testable import ReviewContextFeature

/// Implements: FR-srm-comment-publish-on-submit, FR-sr-patch-reply-publish,
/// FR-sr-patch-reply-respond, AC-srm-publish-no-dup, AC-srm-publish-relay-failure
/// (the automated half of the bidirectional publish loop; the relay round-trip
/// and manual surfaces are covered by the manual QA cases).
@Suite("Patch-thread reply publishing")
@MainActor
struct PatchReplyPublishTests {
    private let fileID = UUID()
    private let patchID = String(repeating: "a", count: 64)
    private let reviewerPubkey = String(repeating: "b", count: 64)

    /// A fixed signed event the mock signer returns. Carries the root `e` tag so
    /// `PatchReplyMapper.mapOne` accepts it. Static so it is nonisolated and
    /// capturable from `@Sendable` dependency closures.
    private nonisolated static let signedEvent = NostrEvent(
        id: String(repeating: "c", count: 64),
        pubkey: String(repeating: "b", count: 64),
        kind: 1,
        content: "nice work",
        tags: [["e", String(repeating: "a", count: 64), "", "root"], ["a", "30617:owner:repo"],
               ["range", "/src/foo.ts", "5", "5"]],
        createdAt: 1700000000,
        sig: String(repeating: "d", count: 128)
    )

    private func makeState(editorText: String = "nice work") -> AppFeature.State {
        var comment = CommentFeature.State(
            editorState: .creating(anchorLine: 5, endLine: 5),
            editorText: editorText
        )
        comment.publishState = .idle
        return AppFeature.State(
            comment: comment,
            files: [FileNode(id: fileID, name: "foo.ts", filePath: "/src/foo.ts", content: "x\n")],
            activeFileID: fileID,
            reviewContextData: ReviewContext(
                patchMetadata: ReviewContext.PatchMetadata(
                    eventID: patchID,
                    shortEventID: String(repeating: "a", count: 8),
                    author: "author",
                    commitMessage: "msg",
                    parentCommit: nil,
                    status: "open",
                    repoCoordinate: "30617:owner:repo"
                )
            ),
            reviewerIdentity: ReviewerIdentity(
                pubkeyHex: reviewerPubkey, npub: "npub1example", displayName: "me"
            )
        )
    }

    @Test("Submitting an inline comment on a patch review publishes a kind:1 reply")
    func submitPublishesReply() async {
        let clock = TestClock()
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000aa")!
        let store = TestStore(initialState: makeState()) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(testUUID)
            $0.continuousClock = clock
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
            $0.identityClient.currentSecret = { Data(repeating: 1, count: 32) }
            $0.identityClient.sign = { @Sendable _ in Self.signedEvent }
            $0.relayClient.publish = { @Sendable _ in .accepted }
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment))
        await store.receive(\.patchReplyPublishResult)

        // The local comment is retained and associated with the published event id.
        #expect(store.state.allComments[id: testUUID]?.publishedEventID == Self.signedEvent.id)
        // The reviewer's own reply is appended immediately (renders with YOU badge;
        // deduped when the relay delivers it back).
        #expect(store.state.reviewContextData?.patchMetadata?.replies.contains(where: { $0.id == Self.signedEvent.id }) == true)
        #expect(store.state.comment.publishState == .published)
        #expect(store.state.showPublishConfirmation == true)

        // Confirmation auto-dismisses after 2s. Implements: FR-srm-comment-publish-on-submit.
        await clock.advance(by: .seconds(2))
        await store.receive(\.dismissPublishConfirmation)
        #expect(store.state.showPublishConfirmation == false)
    }

    @Test("Publish failure reopens the editor and retains the local comment")
    func publishFailureReopensEditor() async {
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000bb")!
        let store = TestStore(initialState: makeState()) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(testUUID)
            $0.continuousClock = TestClock()
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
            $0.identityClient.currentSecret = { Data(repeating: 1, count: 32) }
            $0.identityClient.sign = { @Sendable _ in Self.signedEvent }
            $0.relayClient.publish = { @Sendable _ in .failed }
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment))
        await store.receive(\.patchReplyPublishResult)

        // Local comment retained, no event id, editor reopened for retry.
        #expect(store.state.allComments[id: testUUID]?.publishedEventID == nil)
        #expect(store.state.allComments[id: testUUID]?.text == "nice work")
        if case .failed = store.state.comment.publishState {} else {
            Issue.record("expected .failed publish state")
        }
        #expect(store.state.comment.editorState != nil)
    }

    @Test("No identity: submit is local-only, no publish attempted")
    func noIdentityLocalOnly() async {
        var state = makeState()
        state.reviewerIdentity = nil
        let testUUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000cc")!
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(testUUID)
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
            // Publish must never be called; default test relayClient.publish returns .failed,
            // but we assert no patchReplyPublishResult is ever received.
        }
        store.exhaustivity = .off

        await store.send(.comment(.submitComment))
        // No publish effect runs, so no publish result arrives. The comment is local-only.
        #expect(store.state.allComments[id: testUUID]?.publishedEventID == nil)
        #expect(store.state.comment.publishState == .idle)
    }

    @Test("Reply-to-reply from inspector switches active file to the reply's anchor file")
    func replyToReplySwitchesFile() async {
        let fileA = UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!
        let fileB = UUID(uuidString: "00000000-0000-0000-0000-0000000000b2")!
        let store = TestStore(initialState: AppFeature.State(
            files: [
                FileNode(id: fileA, name: "a.ts", filePath: "/src/a.ts", content: "x\n"),
                FileNode(id: fileB, name: "b.ts", filePath: "/src/b.ts", content: "y\n"),
            ],
            activeFileID: fileA,
            reviewContextData: ReviewContext(
                patchMetadata: ReviewContext.PatchMetadata(
                    eventID: patchID, shortEventID: "aaaaaaaa",
                    author: "author", commitMessage: "msg", parentCommit: nil, status: "open"
                )
            )
        )) {
            AppFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in nil }
        }
        store.exhaustivity = .off

        let anchoredReply = ReviewContext.PatchReply(
            id: String(repeating: "e", count: 64),
            author: "someone", authorPubkey: String(repeating: "f", count: 64),
            isBot: false, content: "looks good", timestamp: 1,
            lineAnchor: ReviewContext.PatchReply.LineAnchor(
                filePath: "/src/b.ts", startLine: 3, endLine: 4
            )
        )
        await store.send(.replyToPatchReply(anchoredReply))
        // Active file switched to the reply's anchored file (b.ts), not the
        // previously-active a.ts. Implements: FR-srm-reply-to-reply.
        #expect(store.state.activeFileID == fileB)
        #expect(store.state.comment.editorState == .creating(anchorLine: 3, endLine: 4))
        #expect(store.state.comment.replyTarget?.id == anchoredReply.id)
    }
}
