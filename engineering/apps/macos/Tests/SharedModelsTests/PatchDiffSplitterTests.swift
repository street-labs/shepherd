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

    // MARK: - PR (kind 1618) helpers — Implements: FR-sr-pr-metadata-display,
    // FR-srm-pr-open-load, FR-sri-pr-open-load

    private func prEvent(tags: [[String]], content: String = "PR body\nsecond line") -> NostrEvent {
        NostrEvent(id: patchID, pubkey: author, kind: 1618, content: content, tags: tags, createdAt: 1)
    }

    @Test("PR tag extractors read clone/c/merge-base/branch-name/e tags")
    func prTagExtractors() {
        let tags: [[String]] = [
            ["clone", "https://git.example/acme/widget"],
            ["clone", "git@git.example:acme/widget"],
            ["c", "c0ffee1111111111111111111111111111111111"],
            ["merge-base", "deadbeef2222222222222222222222222222222222"],
            ["branch-name", "feature/x"],
            ["subject", "Add widget frobber"],
            ["a", "30617:acme:widget"],
            ["e", String(repeating: "f", count: 64)],
            ["e", String(repeating: "e", count: 64)],
        ]
        #expect(PatchDiffSplitter.cloneURLs(from: tags).count == 2)
        #expect(PatchDiffSplitter.tipCommit(from: tags) == "c0ffee1111111111111111111111111111111111")
        #expect(PatchDiffSplitter.mergeBase(from: tags) == "deadbeef2222222222222222222222222222222222")
        #expect(PatchDiffSplitter.branchName(from: tags) == "feature/x")
        #expect(PatchDiffSplitter.referencedPatchIDs(from: tags).count == 2)
    }

    @Test("prMetadata builds PR fields from a 1618 event")
    func prMetadataBuilds() {
        let tags: [[String]] = [
            ["c", "c0ffee1111111111111111111111111111111111111"],
            ["merge-base", "deadbeef2222222222222222222222222222222222"],
            ["branch-name", "feature/x"],
            ["subject", "Add widget frobber"],
            ["a", "30617:acme:widget"],
        ]
        let meta = PatchDiffSplitter.prMetadata(from: prEvent(tags: tags))
        #expect(meta.eventID == patchID)
        #expect(meta.shortEventID == "aaaaaaaa")
        #expect(meta.commitMessage == "Add widget frobber")
        #expect(meta.parentCommit == "deadbeef")  // merge-base shortened
        #expect(meta.tipCommit == "c0ffee11")     // c shortened
        #expect(meta.branchName == "feature/x")
        #expect(meta.repoCoordinate == "30617:acme:widget")
        #expect(meta.status == "open")
        #expect(meta.replies == [])
    }

    @Test("prMetadata subject falls back to first content line, truncated")
    func prMetadataSubjectFallback() {
        let long = String(repeating: "y", count: 80)
        let meta = PatchDiffSplitter.prMetadata(from: prEvent(tags: [], content: "\(long)\nrest"))
        #expect(meta.commitMessage.count == 60)
        #expect(meta.tipCommit == nil)
        #expect(meta.branchName == nil)
        #expect(meta.parentCommit == nil)
    }

    @Test("splitUnifiedDiff parses a git-diff string into per-file blocks")
    func splitUnifiedDiffParses() {
        let diff = """
        diff --git a/a.swift b/a.swift
        index 111..222 100644
        --- a/a.swift
        +++ b/a.swift
        @@ -1 +1,2 @@
         line
        +added
        diff --git a/b.md b/b.md
        @@ -1 +1 @@
        -old
        +new
        """
        guard let files = PatchDiffSplitter.splitUnifiedDiff(diff) else {
            Issue.record("expected non-nil split"); return
        }
        #expect(files.count == 2)
        #expect(files[0].filePath == "a.swift")
        #expect(files[1].filePath == "b.md")
    }

    @Test("splitUnifiedDiff returns nil for empty or header-less input")
    func splitUnifiedDiffInvalid() {
        #expect(PatchDiffSplitter.splitUnifiedDiff("") == nil)
        #expect(PatchDiffSplitter.splitUnifiedDiff("no diff here") == nil)
        #expect(PatchDiffSplitter.splitUnifiedDiff("diff --git a/x b/x\n(no hunk)") == nil)
    }
}

// NIP-34 patch series: cover-letter roots (ngit send --force-patch). The root
// kind-1617 carries only a commit message; diffs live in kind-1617 replies
// tagged with `t: cover-letter` referencing it via `e`.
@Suite("PatchDiffSplitter cover letter")
struct PatchCoverLetterTests {
    private func event(content: String, tags: [[String]]) -> NostrEvent {
        NostrEvent(id: String(repeating: "a", count: 64), pubkey: String(repeating: "b", count: 64), kind: 1617, content: content, tags: tags, createdAt: 1)
    }

    @Test("Cover-letter tag is detected; plain patch and non-1617 are not")
    func detectCoverLetter() {
        let letter = event(content: "Subject line\n\nbody", tags: [["t", "cover-letter"], ["t", "root"]])
        #expect(PatchDiffSplitter.isCoverLetter(letter))
        #expect(!PatchDiffSplitter.isCoverLetter(event(content: "x", tags: [["t", "root"]])))
        #expect(!PatchDiffSplitter.isCoverLetter(event(content: "x", tags: [["t", "cover-letter"]]).withKind(1618)))
    }

    @Test("Cover letter validates as badDiff (dispatches to series fetch)")
    func coverLetterHasNoDiff() {
        let letter = event(content: "Persist shepherd deep link format", tags: [["t", "cover-letter"]])
        guard case .badDiff = PatchDiffSplitter.validate(letter) else {
            Issue.record("expected .badDiff"); return
        }
    }
}

extension NostrEvent {
    func withKind(_ kind: Int) -> NostrEvent {
        NostrEvent(id: id, pubkey: pubkey, kind: kind, content: content, tags: tags, createdAt: createdAt)
    }
}
