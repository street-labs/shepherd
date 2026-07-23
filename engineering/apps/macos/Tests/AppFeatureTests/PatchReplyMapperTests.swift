import Testing
import Foundation
@testable import ShepherdDependencies
@testable import SharedModels

@Suite("PatchReplyMapper / FR-sr-relay-client")
struct PatchReplyMapperTests {
    let patchID = String(repeating: "a", count: 64)

    func ev(id: String, kind: Int = 1, pubkey: String = "pk1",
            content: String = "hi", ts: Int64 = 100,
            tags: [[String]] = [["e", String(repeating: "a", count: 64), "", "root"]]) -> NostrEvent {
        NostrEvent(id: id, pubkey: pubkey, kind: kind, content: content, tags: tags, createdAt: ts)
    }

    @Test("Maps kind:1 root replies, excludes status transitions and the patch event")
    func mapsAndExcludes() {
        let events = [
            ev(id: "r1", content: "second", ts: 20),
            ev(id: "r2", content: "first", ts: 10),
            ev(id: "status1", kind: 1630, content: "merged"),
            ev(id: "patchev", kind: 1617, content: "diff"),
            ev(id: "r3", content: "other root", ts: 30, tags: [["e", "otherevent", "", "root"]]),
        ]
        let replies = PatchReplyMapper.map(events, patchEventID: patchID)
        #expect(replies.map { $0.id } == ["r2", "r1"])
        #expect(replies.allSatisfy { $0.isBot == false })
    }

    @Test("Parses a range line anchor and tolerates missing root marker")
    func anchorAndMarkerlessRoot() {
        // No 4th "root" element, but e tag value still matches -> accepted.
        let events = [
            ev(id: "r1", content: "nits", ts: 10, tags: [["e", patchID], ["range", "src/a.swift", "12", "14"]])
        ]
        let replies = PatchReplyMapper.map(events, patchEventID: patchID)
        #expect(replies.count == 1)
        #expect(replies[0].lineAnchor?.filePath == "src/a.swift")
        #expect(replies[0].lineAnchor?.startLine == 12)
        #expect(replies[0].lineAnchor?.endLine == 14)
    }

    @Test("Author defaults to truncated hex pubkey when no roster entry")
    func defaultAuthor() {
        let pk = String(repeating: "b", count: 40)
        let events = [ev(id: "r1", pubkey: pk, content: "hi", ts: 10, tags: [["e", patchID]])]
        let replies = PatchReplyMapper.map(events, patchEventID: patchID)
        #expect(replies[0].author == String(pk.prefix(16)) + "…")
        #expect(replies[0].authorPubkey == pk)
    }

    @Test("mapOne returns nil for non-reply events")
    func mapOneNilCases() {
        #expect(PatchReplyMapper.mapOne(ev(id: "x", kind: 1630), patchEventID: patchID) == nil)
        #expect(PatchReplyMapper.mapOne(ev(id: patchID), patchEventID: patchID) == nil)
        #expect(PatchReplyMapper.mapOne(ev(id: "x", content: "o", tags: [["e", "other"]]), patchEventID: patchID) == nil)
        #expect(PatchReplyMapper.mapOne(ev(id: "x", content: "ok", ts: 10, tags: [["e", patchID]]), patchEventID: patchID) != nil)
    }
}
