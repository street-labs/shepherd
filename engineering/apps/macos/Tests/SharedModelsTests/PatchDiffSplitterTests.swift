import Testing
import Foundation
@testable import SharedModels

@Suite("PatchDiffSplitter")
struct PatchDiffSplitterTests {
    private let patchID = String(repeating: "a", count: 64)
    private let author = String(repeating: "b", count: 64)

    private func patchEvent(content: String, tags: [[String]] = []) -> NostrEvent {
        NostrEvent(id: patchID, pubkey: author, kind: 1617, content: content, tags: tags, createdAt: 1)
    }

    @Test("Valid patch splits into per-file tabs and extracts metadata")
    func validPatch() {
        let content = """
        Fix the thing

        diff --git a/foo.swift b/foo.swift
        @@ -1,3 +1,4 @@
         line
        +added
        diff --git a/bar.md b/bar.md
        @@ -1 +1 @@
        -old
        +new
        """
        let result = PatchDiffSplitter.validate(patchEvent(
            content: content,
            tags: [["a", "30617:acme:widget"], ["parent-commit", "abcdef1234567890"]]
        ))
        guard case let .ok(files, metadata) = result else {
            Issue.record("expected .ok, got \(result)"); return
        }
        #expect(files.count == 2)
        #expect(files[0].filePath == "foo.swift")
        #expect(files[0].diffBlock.hasPrefix("diff --git a/foo.swift b/foo.swift"))
        #expect(files[1].filePath == "bar.md")
        #expect(metadata.eventID == patchID)
        #expect(metadata.shortEventID == "aaaaaaaa")
        #expect(metadata.commitMessage == "Fix the thing")
        #expect(metadata.parentCommit == "abcdef12")
        #expect(metadata.repoCoordinate == "30617:acme:widget")
        #expect(metadata.status == "open")
        #expect(metadata.replies == [])
    }

    @Test("Non-1617 kind is rejected as wrongKind")
    func wrongKind() {
        let event = NostrEvent(id: patchID, pubkey: author, kind: 1, content: "diff --git a/x b/x\n@@ -1 +1 @@\n+a", tags: [], createdAt: 1)
        let result = PatchDiffSplitter.validate(event)
        guard case let .wrongKind(kind) = result else {
            Issue.record("expected .wrongKind, got \(result)"); return
        }
        #expect(kind == 1)
    }

    @Test("Content with no diff --git header is badDiff")
    func noDiffHeader() {
        let result = PatchDiffSplitter.validate(patchEvent(content: "just a commit message, no diff"))
        if case .badDiff = result {} else { Issue.record("expected .badDiff, got \(result)") }
    }

    @Test("Diff header without @@ hunk is badDiff")
    func noHunk() {
        let result = PatchDiffSplitter.validate(patchEvent(content: "diff --git a/x b/x\n(no hunk)"))
        if case .badDiff = result {} else { Issue.record("expected .badDiff, got \(result)") }
    }

    @Test("Deletion-only file (b/dev/null) uses the a/ path so it stays visible")
    func deletionUsesAPath() {
        let content = """
        diff --git a/gone.swift b/dev/null
        @@ -1,2 +0,0 @@
        -line1
        -line2
        """
        let result = PatchDiffSplitter.validate(patchEvent(content: content))
        guard case let .ok(files, _) = result else {
            Issue.record("expected .ok, got \(result)"); return
        }
        #expect(files.count == 1)
        #expect(files[0].filePath == "gone.swift")
    }

    @Test("Commit message truncated to 60 chars")
    func longMessageTruncated() {
        let longSubject = String(repeating: "x", count: 80)
        let content = "\(longSubject)\n\ndiff --git a/x b/x\n@@ -1 +1 @@\n+a"
        let result = PatchDiffSplitter.validate(patchEvent(content: content))
        guard case let .ok(_, metadata) = result else {
            Issue.record("expected .ok, got \(result)"); return
        }
        #expect(metadata.commitMessage.count == 60)
    }
}
