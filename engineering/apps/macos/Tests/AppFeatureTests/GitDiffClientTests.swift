import Testing
import Foundation
import ComposableArchitecture
@testable import ShepherdDependencies

/// End-to-end test of `GitDiffClient.liveValue` against a real local bare git
/// repository. Validates `FR-srm-pr-open-diff`: fetch-by-SHA from a clone URL
/// and `git diff <merge-base>..<tip>` produce the net unified diff.
/// macOS-only — the live value shells out to `git` (`Process`).
#if os(macOS)
@Suite("GitDiffClient live (FR-srm-pr-open-diff)")
struct GitDiffClientTests {
    /// Build a two-commit repo, bare-clone it, and return (barePath, tipSHA, baseSHA).
    private func makeBareRepo() throws -> (bare: URL, tip: String, base: String) {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitdiff-src-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        try runGit(tmp, ["init", "--quiet"])
        try runGit(tmp, ["config", "user.email", "t@t"])
        try runGit(tmp, ["config", "user.name", "t"])
        try Data("v1\n".utf8).write(to: tmp.appendingPathComponent("f.txt"))
        try runGit(tmp, ["add", "f.txt"])
        try runGit(tmp, ["commit", "--quiet", "-m", "v1"])
        let base = try runGitOut(tmp, ["rev-parse", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)
        try Data("v1\nv2\n".utf8).write(to: tmp.appendingPathComponent("f.txt"))
        try runGit(tmp, ["add", "f.txt"])
        try runGit(tmp, ["commit", "--quiet", "-m", "v2"])
        let tip = try runGitOut(tmp, ["rev-parse", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)

        let bare = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitdiff-bare-\(UUID().uuidString)", isDirectory: true)
        try runGit(tmp, ["clone", "--quiet", "--bare", tmp.path, bare.path])
        return (bare, tip, base)
    }

    @Test("acquirePRDiff returns the net diff between merge-base and tip")
    func acquireDiff() async throws {
        let (bare, tip, base) = try makeBareRepo()
        defer { try? FileManager.default.removeItem(at: bare) }
        let spec = GitDiffClient.Spec(cloneURLs: [bare.path], tipCommit: tip, mergeBase: base)
        let result = await GitDiffClient.liveValue.acquirePRDiff(spec)
        guard case let .diff(diff) = result else {
            Issue.record("expected .diff, got \(result)"); return
        }
        #expect(diff.contains("diff --git"))
        #expect(diff.contains("+v2"))
    }

    @Test("acquirePRDiff returns .empty when tip == merge-base")
    func acquireEmpty() async throws {
        let (bare, tip, _) = try makeBareRepo()
        defer { try? FileManager.default.removeItem(at: bare) }
        let spec = GitDiffClient.Spec(cloneURLs: [bare.path], tipCommit: tip, mergeBase: tip)
        let result = await GitDiffClient.liveValue.acquirePRDiff(spec)
        if case .empty = result {} else { Issue.record("expected .empty, got \(result)") }
    }

    @Test("acquirePRDiff returns .fetchFailed for an unreachable clone URL")
    func acquireFetchFailed() async throws {
        let spec = GitDiffClient.Spec(
            cloneURLs: ["/nonexistent/path/repo"],
            tipCommit: String(repeating: "a", count: 40),
            mergeBase: String(repeating: "b", count: 40)
        )
        let result = await GitDiffClient.liveValue.acquirePRDiff(spec)
        if case .fetchFailed = result {} else { Issue.record("expected .fetchFailed, got \(result)") }
    }

    // MARK: - git helpers

    private func runGit(_ dir: URL, _ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["git"] + args
        p.currentDirectoryURL = dir
        let err = Pipe()
        p.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
        p.standardError = err
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            Issue.record("git \(args.first ?? "") failed in \(dir.lastPathComponent): \(e)")
        }
    }

    private func runGitOut(_ dir: URL, _ args: [String]) throws -> String {
        let pipe = Pipe()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["git"] + args
        p.currentDirectoryURL = dir
        p.standardOutput = pipe
        p.standardError = FileHandle(forWritingAtPath: "/dev/null")
        try p.run()
        p.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
#endif
