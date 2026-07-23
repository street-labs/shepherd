import Foundation
import SharedModels

/// Maps Nostr events to `PatchReply` objects for the patch-thread review loop.
/// Implements: FR-sr-relay-client. This is the Swift port of the mapper in
/// `scripts/shepherd-patch-poll.sh` (single set of rules, shared by the
/// in-app live subscription and the command-prompt initial snapshot).
///
/// Rules:
/// - kind == 1 only (excludes 1630-1633 status transitions and the patch event).
/// - root `e` tag must point at the patch event id (marker tolerated).
/// - author resolved from `~/.config/nostr/roster.json` else truncated hex pubkey.
/// - isBot from the roster's `bot` flag for that pubkey.
/// - optional lineAnchor parsed from a `["range", file, start, end]` tag.
public enum PatchReplyMapper {
    /// Map a batch of events for the given patch event id. Dedupes by event id
    /// and returns oldest-first. Events whose id equals the patch id are skipped.
    public static func map(_ events: [NostrEvent], patchEventID: String) -> [ReviewContext.PatchReply] {
        let roster = loadRoster()
        var seen = Set<String>()
        var out: [ReviewContext.PatchReply] = []
        for ev in events {
            guard ev.kind == 1 else { continue }
            guard ev.id != patchEventID else { continue }
            guard rootMatch(ev.tags, patchID: patchEventID) else { continue }
            guard seen.insert(ev.id).inserted else { continue }
            out.append(makeReply(ev, roster: roster))
        }
        return out.sorted { $0.timestamp < $1.timestamp }
    }

    /// Map a single event (no dedup). Returns nil if it is not a kind:1 root
    /// reply for the given patch id.
    public static func mapOne(_ ev: NostrEvent, patchEventID: String) -> ReviewContext.PatchReply? {
        guard ev.kind == 1, ev.id != patchEventID, rootMatch(ev.tags, patchID: patchEventID) else {
            return nil
        }
        return makeReply(ev, roster: loadRoster())
    }

    private static func makeReply(_ ev: NostrEvent, roster: [String: Any]) -> ReviewContext.PatchReply {
        let pk = ev.pubkey
        let entry = roster[pk] as? [String: Any]
        let name = (entry?["name"] as? String) ?? defaultName(pk)
        let isBot = (entry?["bot"] as? Bool) ?? false
        // ponytail: no live NIP-05 fetch in the mapper; bot detection is roster-only.
        return ReviewContext.PatchReply(
            id: ev.id.isEmpty ? pk + String(ev.createdAt) : ev.id,
            author: name,
            authorPubkey: pk,
            isBot: isBot,
            content: ev.content,
            timestamp: ev.createdAt,
            lineAnchor: parseAnchor(ev.tags)
        )
    }

    private static func defaultName(_ pk: String) -> String {
        guard !pk.isEmpty else { return "unknown" }
        return pk.count > 16 ? String(pk.prefix(16)) + "…" : pk
    }

    private static func rootMatch(_ tags: [[String]], patchID: String) -> Bool {
        for t in tags {
            if t.count >= 2, t[0] == "e", t[1] == patchID { return true }
        }
        return false
    }

    private static func parseAnchor(_ tags: [[String]]) -> ReviewContext.PatchReply.LineAnchor? {
        // ponytail: only the ["range", file, start, end] convention is parsed.
        // Other anchoring schemes (q/r tags) fall back to inspector-only rendering.
        for t in tags {
            if t.count >= 4, t[0] == "range",
               let start = Int(t[2]), let end = Int(t[3]) {
                return ReviewContext.PatchReply.LineAnchor(
                    filePath: t[1], startLine: start, endLine: end
                )
            }
        }
        return nil
    }

    private static func loadRoster() -> [String: Any] {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nostr/roster.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return obj
    }
}
