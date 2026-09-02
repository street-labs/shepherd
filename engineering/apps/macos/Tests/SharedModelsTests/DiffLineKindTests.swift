import Testing
@testable import SharedModels

/// Classification of unified-diff lines, and the check that decides whether a loaded
/// file is a diff at all. Covers `FR-diff-display`.
@Suite("Diff line classification")
struct DiffLineKindTests {
    @Test("File-header prefixes win over the +/- content check")
    func headersBeatContentPrefixes() {
        // `+++`/`---` are file headers, not an added/removed line. A naive
        // hasPrefix("+") check tints them as content, which is the bug this guards.
        #expect(DiffLineKind(line: "+++ b/Sources/Foo.swift") == .header)
        #expect(DiffLineKind(line: "--- a/Sources/Foo.swift") == .header)
        #expect(DiffLineKind(line: "diff --git a/Foo.swift b/Foo.swift") == .header)
        #expect(DiffLineKind(line: "index 3919d9b..e183529 100644") == .header)
        #expect(DiffLineKind(line: "@@ -1,4 +1,6 @@ func body() {") == .header)
        #expect(DiffLineKind(line: "new file mode 100644") == .header)
        #expect(DiffLineKind(line: "\\ No newline at end of file") == .header)
    }

    @Test("Added, removed, and context lines")
    func contentLines() {
        #expect(DiffLineKind(line: "+    let x = 1") == .added)
        #expect(DiffLineKind(line: "-    let x = 0") == .removed)
        #expect(DiffLineKind(line: "     let y = 2") == .context)
        #expect(DiffLineKind(line: "") == .context)
        // A lone "+" or "-" is a real diff line for an empty source line.
        #expect(DiffLineKind(line: "+") == .added)
        #expect(DiffLineKind(line: "-") == .removed)
    }

    @Test("isDiff recognises git output and nothing else")
    func isDiffDetection() {
        let tracked = FileNode(name: "Foo.swift", content: """
        diff --git a/Foo.swift b/Foo.swift
        index 111..222 100644
        --- a/Foo.swift
        +++ b/Foo.swift
        @@ -1 +1 @@
        -old
        +new
        """)
        #expect(tracked.isDiff)

        // `git diff --no-index /dev/null <path>` — how an untracked file is staged.
        let untracked = FileNode(name: "New.swift", content: """
        diff --git a/New.swift b/New.swift
        new file mode 100644
        --- /dev/null
        +++ b/New.swift
        @@ -0,0 +1 @@
        +hello
        """)
        #expect(untracked.isDiff)

        // Ordinary source, including source that merely mentions a diff.
        #expect(!FileNode(name: "Foo.swift", content: "let x = 1\n").isDiff)
        #expect(!FileNode(name: "README.md", content: "Run `diff --git` to see.\n").isDiff)
    }
}
