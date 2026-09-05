import Foundation
import SharedModels

// Implements: FR-pa-comment, FR-pa-review, FR-pa-merge
//
// Pure Nostr event constructors for PR actions. Event shapes follow
// `docs/approval-events.md`: verdicts are kind `1620` bound to the PR tip
// commit via the `c` tag; merges are NIP-34 kind `1631` status events;
// comments are kind `1` threaded replies. Builders produce unsigned events;
// `IdentityClient.sign` signs, `RelayClient.publish` sends.
public enum EventBuilder {

    /// Unsigned kind `1` threaded reply on a PR (or patch) root event.
    /// `replyTarget` adds the reply `e` tag and target-author `p` tag;
    /// `range` attaches an optional file/line reference.
    public static func threadedReply(
        rootID: String, replyTarget: ReviewContext.PatchReply?, content: String,
        range: (path: String, start: Int, end: Int)? = nil
    ) -> NostrEvent {
        var tags: [[String]] = [["e", rootID, "", "root"]]
        if let replyTarget {
            tags.append(["e", replyTarget.id, "", "reply"])
            tags.append(["p", replyTarget.authorPubkey])
        }
        if let range {
            tags.append(["range", range.path, String(range.start), String(range.end)])
        }
        return NostrEvent(
            id: "", pubkey: "", kind: 1, content: content,
            tags: tags, createdAt: Int64(Date().timeIntervalSince1970)
        )
    }

    /// Unsigned kind `1620` review verdict per `docs/approval-events.md`:
    /// `e` root tag on the PR event, `p` on the PR author, `a` repo coordinate,
    /// `t` approval/rejection, `c` tip commit the verdict binds to.
    public static func verdict(
        prEventID: String, prAuthorPubkey: String?, repoCoordinate: String?,
        verdict: String, tipCommit: String, summary: String? = nil
    ) -> NostrEvent {
        precondition(verdict == "approval" || verdict == "rejection")
        var tags: [[String]] = [["e", prEventID, "", "root"]]
        if let prAuthorPubkey { tags.append(["p", prAuthorPubkey]) }
        if let repoCoordinate { tags.append(["a", repoCoordinate]) }
        tags.append(["t", verdict])
        tags.append(["c", tipCommit])
        return NostrEvent(
            id: "", pubkey: "", kind: 1620, content: summary ?? "",
            tags: tags, createdAt: Int64(Date().timeIntervalSince1970)
        )
    }

    /// Unsigned NIP-34 kind `1631` Applied/Merged status event. Shepherd
    /// publishes the status only; landing commits is the merge service's job
    /// (`FR-pa-merge`).
    public static func mergeStatus(
        prEventID: String, repoCoordinate: String?, mergeCommit: String
    ) -> NostrEvent {
        var tags: [[String]] = [["e", prEventID, "", "root"]]
        if let repoCoordinate { tags.append(["a", repoCoordinate]) }
        tags.append(["merge-commit", mergeCommit])
        return NostrEvent(
            id: "", pubkey: "", kind: 1631, content: "",
            tags: tags, createdAt: Int64(Date().timeIntervalSince1970)
        )
    }
}

// Implements: FR-pa-merge, FR-pa-capabilities
//
/// Merge gate over the PR's fetched kind `1620` verdict events. Verdict
/// resolution per `docs/approval-events.md`: each reviewer's verdict is their
/// newest `1620` per (pubkey, PR); a stale `c` tag (PR tip moved since the
/// verdict) never counts. Gate passes on >=1 current approval and 0 current
/// rejections.
public enum MergeGate {

    public struct Outcome: Equatable, Sendable {
        /// Current (fresh) approvals and rejections after resolution.
        public var approvals: [NostrEvent]
        public var rejections: [NostrEvent]
        /// Verdicts whose `c` tag no longer matches the tip — shown stale,
        /// never counted (AC-pa-stale).
        public var stale: [NostrEvent]

        public var passes: Bool { !approvals.isEmpty && rejections.isEmpty }
        /// Human-readable gate reason for a disabled Merge control.
        public var failureReason: String {
            if let rejection = rejections.first {
                return "Rejected by \(rejection.pubkey.prefix(16))…"
            }
            if approvals.isEmpty { return "Needs 1 approval" }
            return "Approval is stale — PR was updated"
        }
    }

    /// `tipCommit` is the PR's current full tip commit (newest `1618`/`1619`
    /// `c` tag); `events` are the fetched kind `1620` events for the PR.
    public static func evaluate(
        events: [NostrEvent], tipCommit: String
    ) -> Outcome {
        // Newest verdict per reviewer pubkey (created_at order, ties broken by
        // array order = relay delivery order).
        var newest: [String: NostrEvent] = [:]
        for event in events where event.kind == 1620 {
            guard let existing = newest[event.pubkey] else {
                newest[event.pubkey] = event
                continue
            }
            if event.createdAt >= existing.createdAt { newest[event.pubkey] = event }
        }
        var approvals: [NostrEvent] = []
        var rejections: [NostrEvent] = []
        var stale: [NostrEvent] = []
        for event in newest.values.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard let c = event.tags.first(where: { $0.count >= 2 && $0[0] == "c" })?[1] else {
                continue
            }
            guard c == tipCommit else {
                stale.append(event)
                continue
            }
            switch event.tags.first(where: { $0.count >= 2 && $0[0] == "t" })?[1] {
            case "approval": approvals.append(event)
            case "rejection": rejections.append(event)
            default: break
            }
        }
        return Outcome(approvals: approvals, rejections: rejections, stale: stale)
    }

    /// Maintainer pubkeys from a repo `30617` announcement event (`p` tags).
    public static func maintainers(from event: NostrEvent) -> [String] {
        event.tags.filter { $0.count >= 2 && $0[0] == "p" }.map { $0[1] }
    }
}
