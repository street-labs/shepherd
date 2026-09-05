import XCTest
import SharedModels
@testable import ShepherdDependencies

/// Tag/JSON truth tables for PR action event builders and the merge gate.
/// Implements: FR-pa-review, FR-pa-merge, FR-pa-comment (per the engineering
/// spec's test plan in `engineering/macos/pr-actions.md`).
final class EventBuilderTests: XCTestCase {
    let tip = String(repeating: "c", count: 40)

    func testVerdictApprovalTags() {
        let event = EventBuilder.verdict(
            prEventID: "prid", prAuthorPubkey: "authorpk",
            repoCoordinate: "30617:owner:repo", verdict: "approval",
            tipCommit: tip, summary: "Looks good"
        )
        XCTAssertEqual(event.kind, 1620)
        XCTAssertEqual(event.content, "Looks good")
        XCTAssertEqual(event.tags, [
            ["e", "prid", "", "root"],
            ["p", "authorpk"],
            ["a", "30617:owner:repo"],
            ["t", "approval"],
            ["c", tip],
        ])
    }

    func testVerdictRejectionWithoutSummaryOmitsContentAndOptionals() {
        let event = EventBuilder.verdict(
            prEventID: "prid", prAuthorPubkey: nil, repoCoordinate: nil,
            verdict: "rejection", tipCommit: tip, summary: nil
        )
        XCTAssertEqual(event.kind, 1620)
        XCTAssertEqual(event.content, "")
        XCTAssertEqual(event.tags, [
            ["e", "prid", "", "root"],
            ["t", "rejection"],
            ["c", tip],
        ])
    }

    func testMergeStatusTags() {
        let event = EventBuilder.mergeStatus(
            prEventID: "prid", repoCoordinate: "30617:owner:repo",
            mergeCommit: tip
        )
        XCTAssertEqual(event.kind, 1631)
        XCTAssertEqual(event.tags, [
            ["e", "prid", "", "root"],
            ["a", "30617:owner:repo"],
            ["merge-commit", tip],
        ])
    }

    func testThreadedReplyRootReplyAndRangeTags() {
        let reply = ReviewContext.PatchReply(
            id: "targetid", author: "t", authorPubkey: "targetpk", isBot: false,
            content: "hi", timestamp: 0, lineAnchor: nil
        )
        let event = EventBuilder.threadedReply(
            rootID: "rootid", replyTarget: reply, content: "a reply",
            range: ("src/a.swift", 3, 5)
        )
        XCTAssertEqual(event.kind, 1)
        XCTAssertEqual(event.content, "a reply")
        XCTAssertEqual(event.tags, [
            ["e", "rootid", "", "root"],
            ["e", "targetid", "", "reply"],
            ["p", "targetpk"],
            ["range", "src/a.swift", "3", "5"],
        ])
    }

    // MARK: - Merge gate

    private func verdict(_ pubkey: String, t: String, c: String, at: Int64) -> NostrEvent {
        NostrEvent(id: pubkey + t + String(at), pubkey: pubkey, kind: 1620,
                   content: "", tags: [["t", t], ["c", c]], createdAt: at, sig: "")
    }

    func testGatePassesWithOneCurrentApproval() {
        let outcome = MergeGate.evaluate(events: [verdict("a", t: "approval", c: tip, at: 1)], tipCommit: tip)
        XCTAssertTrue(outcome.passes)
        XCTAssertTrue(outcome.rejections.isEmpty)
        XCTAssertTrue(outcome.stale.isEmpty)
    }

    func testGateBlockedByZeroApprovals() {
        let outcome = MergeGate.evaluate(events: [], tipCommit: tip)
        XCTAssertFalse(outcome.passes)
        XCTAssertEqual(outcome.failureReason, "Needs 1 approval")
    }

    func testNewestVerdictPerReviewerWins() {
        // A later rejection withdraws the reviewer's earlier approval.
        let events = [
            verdict("a", t: "approval", c: tip, at: 1),
            verdict("a", t: "rejection", c: tip, at: 2),
        ]
        let outcome = MergeGate.evaluate(events: events, tipCommit: tip)
        XCTAssertFalse(outcome.passes)
        XCTAssertEqual(outcome.rejections.count, 1)
    }

    func testStaleApprovalDoesNotCount() {
        // Approval bound to an older tip never satisfies the gate (AC-pa-stale).
        let oldTip = String(repeating: "d", count: 40)
        let outcome = MergeGate.evaluate(events: [verdict("a", t: "approval", c: oldTip, at: 1)], tipCommit: tip)
        XCTAssertFalse(outcome.passes)
        XCTAssertEqual(outcome.stale.count, 1)
    }

    func testMixedApprovalAndRejectionBlocks() {
        let events = [
            verdict("a", t: "approval", c: tip, at: 1),
            verdict("b", t: "rejection", c: tip, at: 2),
        ]
        let outcome = MergeGate.evaluate(events: events, tipCommit: tip)
        XCTAssertFalse(outcome.passes)
    }

    func testMaintainersFromPTags() {
        let repo = NostrEvent(id: "r", pubkey: "o", kind: 30617, content: "",
                              tags: [["d", "repo"], ["p", "m1"], ["p", "m2"]], createdAt: 0, sig: "")
        XCTAssertEqual(MergeGate.maintainers(from: repo), ["m1", "m2"])
    }
}
