import Testing
import Foundation
@testable import SharedModels

@Suite("PatchReply / FR-sr-patch-replies-display")
struct PatchReplyTests {
    @Test("PatchReply Codable round-trips with and without a line anchor")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let anchored = ReviewContext.PatchReply(
            id: String(repeating: "a", count: 64),
            author: "borg",
            authorPubkey: "npub1borg",
            isBot: true,
            content: "nits on line 12",
            timestamp: 1_700_000_000,
            lineAnchor: .init(filePath: "/repo/a.swift", startLine: 12, endLine: 14)
        )
        let data = try encoder.encode(anchored)
        let back = try decoder.decode(ReviewContext.PatchReply.self, from: data)
        #expect(back == anchored)
        #expect(back.lineAnchor?.filePath == "/repo/a.swift")
        #expect(back.lineAnchor?.startLine == 12)

        let bare = ReviewContext.PatchReply(
            id: String(repeating: "b", count: 64),
            author: "alice",
            authorPubkey: "npub1alice",
            isBot: false,
            content: "ship it",
            timestamp: 1_700_000_001
        )
        let bareData = try encoder.encode(bare)
        let bareBack = try decoder.decode(ReviewContext.PatchReply.self, from: bareData)
        #expect(bareBack == bare)
        #expect(bareBack.lineAnchor == nil)
    }

    @Test("PatchMetadata carries replies and decodes a patch-context payload")
    func metadataRepliesDecode() throws {
        let json = """
        {
          "overall": {"neutral": "n", "review": "r"},
          "files": {},
          "patchMetadata": {
            "eventID": "\(String(repeating: "a", count: 64))",
            "shortEventID": "aaaaaaaa",
            "author": "alice",
            "commitMessage": "Add thing",
            "parentCommit": "deadbeef",
            "status": "open",
            "replies": [
              {
                "id": "\(String(repeating: "b", count: 64))",
                "author": "borg",
                "authorPubkey": "npub1borg",
                "isBot": true,
                "content": "looks good",
                "timestamp": 1700000000,
                "lineAnchor": null
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let ctx = try JSONDecoder().decode(ReviewContext.self, from: json)
        #expect(ctx.patchMetadata?.replies.count == 1)
        #expect(ctx.patchMetadata?.replies.first?.isBot == true)
        #expect(ctx.patchMetadata?.replies.first?.lineAnchor == nil)
    }

    @Test("Replies default to empty when the field is absent (back-compat)")
    func repliesDefaultEmpty() throws {
        let json = """
        {
          "eventID": "\(String(repeating: "a", count: 64))",
          "shortEventID": "aaaaaaaa",
          "author": "alice",
          "commitMessage": "Add thing",
          "parentCommit": null,
          "status": "open"
        }
        """.data(using: .utf8)!

        let meta = try JSONDecoder().decode(ReviewContext.PatchMetadata.self, from: json)
        #expect(meta.replies == [])
    }
}
