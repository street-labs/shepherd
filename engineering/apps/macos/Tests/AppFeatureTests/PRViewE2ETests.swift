#if os(macOS)
import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import OpenPatchFeature

/// End-to-end tests of the PR view path against a real local git smart-HTTP
/// server built on `git http-backend` — the same protocol surface a grasp
/// (ngit) server exposes. A sample repository with a PR branch is created in a
/// temp dir, served over HTTP, and a kind `1618` event pointing at it is pushed
/// through the full `OpenPatchFeature` flow with the *live* `GitDiffClient`.
/// The only stubbed layer is the nostr relay (network), for test stability.
/// Implements e2e coverage for `FR-srm-pr-open-fetch`, `FR-srm-pr-open-clone`,
/// `FR-srm-pr-open-load`.
@Suite("PR view e2e (sample ngit-style server)")
@MainActor
struct PRViewE2ETests {
    let prID = String(repeating: "ab", count: 32)
    let author = String(repeating: "cd", count: 32)

    // MARK: - Sample server fixture

    /// A local git smart-HTTP server wrapping `git http-backend`, plus the
    /// temp dir holding the served bare repo.
    final class SampleServer {
        let url: String
        let process: Process
        let root: URL
        init(url: String, process: Process, root: URL) {
            self.url = url
            self.process = process
            self.root = root
        }
        func shutdown() {
            process.terminate()
            process.waitUntilExit()
            try? FileManager.default.removeItem(at: root)
        }
    }

    /// Minimal CGI bridge: each HTTP request is piped to `git http-backend`
    /// with standard CGI env vars. ~40 lines instead of a grasp binary + keys
    /// + network — same wire protocol, fully offline and deterministic.
    /// ponytail: no keep-alive (HTTP/1.0 close) — git is fine with it; add
    /// if a test ever needs connection reuse.
    private static let serverScript = #"""
        import os, subprocess, sys
        from http.server import BaseHTTPRequestHandler, HTTPServer
        root = sys.argv[1]
        class H(BaseHTTPRequestHandler):
            def _handle(self):
                env = dict(os.environ)
                path, _, qs = self.path.partition("?")
                env.update({
                    "GIT_PROJECT_ROOT": root, "GIT_HTTP_EXPORT_ALL": "1",
                    "PATH_INFO": path, "QUERY_STRING": qs,
                    "REQUEST_METHOD": self.command, "REMOTE_ADDR": "127.0.0.1",
                    "CONTENT_TYPE": self.headers.get("Content-Type", ""),
                })
                for h in ("Content-Encoding", "Accept", "Git-Protocol"):
                    v = self.headers.get(h)
                    if v: env["HTTP_" + h.upper().replace("-", "_")] = v
                n = int(self.headers.get("Content-Length") or 0)
                body = self.rfile.read(n) if n else b""
                p = subprocess.run(["git", "http-backend"], input=body, env=env, capture_output=True)
                out, _, payload = p.stdout.partition(b"\r\n\r\n")
                headers = []
                status = 200
                for line in out.decode("latin-1").splitlines():
                    if ":" not in line: continue
                    k, v = line.split(":", 1)
                    if k.lower() == "status": status = int(v.split()[0])
                    else: headers.append((k, v.strip()))
                self.send_response(status)
                for k, v in headers: self.send_header(k, v)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
            do_GET = do_POST = _handle
            def log_message(self, *a): pass
        from http.server import BaseHTTPRequestHandler, HTTPServer
        srv = HTTPServer(("127.0.0.1", 0), H)
        print(srv.server_address[1], flush=True)
        srv.serve_forever()
        """#

    private func run(_ path: String, _ args: [String], cwd: URL? = nil) -> (Int32, String) {
        let pipe = Pipe()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.currentDirectoryURL = cwd
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return (-1, "") }
        p.waitUntilExit()
        return (p.terminationStatus, String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
    }

    @discardableResult
    private func git(_ args: [String], cwd: URL) -> (Int32, String) {
        run("/usr/bin/git", args, cwd: cwd)
    }

    /// Build the sample repo: `master` (base) + `pr/feature` (one commit).
    /// Returns (dir, baseSHA, tipSHA). `allowSHAInWant: false` reproduces a
    /// server (like a default grasp config) that rejects fetch-by-SHA.
    private func makeSampleRepo(allowSHAInWant: Bool) throws -> (dir: URL, base: String, tip: String) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("shepherd-e2e-\(UUID().uuidString)", isDirectory: true)
        let work = dir.appendingPathComponent("src", isDirectory: true)
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        git(["init", "--quiet", "-b", "master"], cwd: work)
        git(["config", "user.email", "t@t"], cwd: work)
        git(["config", "user.name", "t"], cwd: work)
        try Data("v1\n".utf8).write(to: work.appendingPathComponent("f.txt"))
        git(["add", "f.txt"], cwd: work)
        git(["commit", "--quiet", "-m", "base"], cwd: work)
        let base = git(["rev-parse", "HEAD"], cwd: work).1.trimmingCharacters(in: .whitespacesAndNewlines)
        git(["checkout", "--quiet", "-b", "pr/feature"], cwd: work)
        try Data("v1\nv2\n".utf8).write(to: work.appendingPathComponent("f.txt"))
        try Data("new file\n".utf8).write(to: work.appendingPathComponent("g.txt"))
        git(["add", "."], cwd: work)
        git(["commit", "--quiet", "-m", "Add feature"], cwd: work)
        let tip = git(["rev-parse", "HEAD"], cwd: work).1.trimmingCharacters(in: .whitespacesAndNewlines)
        let bare = dir.appendingPathComponent("repo.git", isDirectory: true)
        _ = run("/usr/bin/git", ["clone", "--quiet", "--bare", work.path, bare.path])
        if allowSHAInWant {
            git(["config", "uploadpack.allowTipSHA1InWant", "true"], cwd: bare)
            git(["config", "uploadpack.allowReachableSHA1InWant", "true"], cwd: bare)
        }
        return (dir, base, tip)
    }

    /// Serve `dir/repo.git` over local smart-HTTP. The server binds port 0
    /// (OS-assigned, no collision under parallel runs) and prints the chosen
    /// port; polls `git ls-remote` until it answers (max ~5s).
    private func startServer(root: URL) async throws -> SampleServer {
        let script = root.appendingPathComponent("server.py")
        try Self.serverScript.write(to: script, atomically: true, encoding: .utf8)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        p.arguments = [script.path, root.path]
        let outPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = FileHandle.nullDevice
        try p.run()
        let line = String(data: outPipe.fileHandleForReading.availableData, encoding: .utf8) ?? ""
        guard let port = Int(line.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            p.terminate()
            Issue.record("server did not report a port")
            throw CocoaError(.userActivityConnectionUnavailable)
        }
        let url = "http://127.0.0.1:\(port)/repo.git"
        for _ in 0..<50 {
            if git(["ls-remote", url], cwd: root).0 == 0 { return SampleServer(url: url, process: p, root: root) }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        p.terminate()
        throw CocoaError(.userActivityConnectionUnavailable)
    }

    private func prEvent(clone: String, tip: String, base: String?, branch: String?) -> NostrEvent {
        var tags: [[String]] = [
            ["clone", clone],
            ["c", tip],
            ["subject", "Add feature"],
            ["a", "30617:\(author):shepherd"],
        ]
        if let base { tags.append(["merge-base", base]) }
        if let branch { tags.append(["branch-name", branch]) }
        return NostrEvent(id: prID, pubkey: author, kind: 1618, content: "PR body", tags: tags, createdAt: 100)
    }

    /// Wraps `OpenPatchFeature` so the `patchLoaded` delegate payload is
    /// captured for assertions (TestStore can't inspect delegate arguments).
    private struct Capturing: Reducer {
        let files: ActorBox<[PatchDiffSplitter.DiffFile]>
        let metadata: ActorBox<ReviewContext.PatchMetadata?>
        var body: some ReducerOf<OpenPatchFeature> {
            Reduce { _, action in
                if case let .delegate(.patchLoaded(fs, md)) = action {
                    files.value = fs
                    metadata.value = md
                }
                return .none
            }
            OpenPatchFeature()
        }
    }

    private func makeStore(event: NostrEvent) throws -> (TestStore<OpenPatchFeature.State, OpenPatchFeature.Action>, files: ActorBox<[PatchDiffSplitter.DiffFile]>, metadata: ActorBox<ReviewContext.PatchMetadata?>) {
        let files = ActorBox<[PatchDiffSplitter.DiffFile]>([])
        let metadata = ActorBox<ReviewContext.PatchMetadata?>(nil)
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            Capturing(files: files, metadata: metadata)
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in ["wss://relay.example"] }
            $0.relayClient.subscribe = { _ in
                AsyncStream { $0.yield(event) }
            }
            $0.gitDiffClient = .liveValue
        }
        store.exhaustivity = .off
        return (store, files, metadata)
    }

    // MARK: - Tests

    @Test("full PR view: event -> smart-HTTP fetch -> diff split -> patchLoaded")
    func prLoadsEndToEnd() async throws {
        let (dir, base, tip) = try makeSampleRepo(allowSHAInWant: true)
        let server = try await startServer(root: dir)
        defer { server.shutdown() }

        let (store, files, metadata) = try makeStore(event: prEvent(clone: server.url, tip: tip, base: base, branch: "pr/feature"))
        await store.send(.set(\.input, prID))
        await store.send(.fetchButtonTapped)
        await store.receive(\.eventFetched)
        await store.receive(\.prDiffResult)
        await store.receive(\.delegate.patchLoaded)

        let paths = files.value.map(\.filePath)
        #expect(paths.contains("f.txt"))
        #expect(paths.contains("g.txt"))
        let fBlock = files.value.first { $0.filePath == "f.txt" }?.diffBlock ?? ""
        #expect(fBlock.contains("+v2"))
        #expect(metadata.value?.commitMessage == "Add feature")
        #expect(metadata.value?.tipCommit == String(tip.prefix(8)))
        #expect(metadata.value?.parentCommit == String(base.prefix(8)))
        #expect(metadata.value?.repoCoordinate == "30617:\(author):shepherd")
    }

    @Test("server without SHA-in-want falls back to branch fetch; PR diff is the tagged tip, not the moved branch")
    func branchFallbackWhenSHARejected() async throws {
        // Default server config rejects fetch-by-SHA. Move the branch past the
        // PR tip so the tip is no longer advertised — only the branch-name
        // fallback can acquire it, and the diff must stop at the tagged tip.
        let (dir, base, tip) = try makeSampleRepo(allowSHAInWant: false)
        let work = dir.appendingPathComponent("src", isDirectory: true)
        try Data("v3\n".utf8).write(to: work.appendingPathComponent("f.txt"))
        git(["add", "f.txt"], cwd: work)
        git(["commit", "--quiet", "-m", "later push"], cwd: work)
        git(["push", "--quiet", "-f", "origin", "pr/feature"], cwd: work)

        let server = try await startServer(root: dir)
        defer { server.shutdown() }

        let (store, files, _) = try makeStore(event: prEvent(clone: server.url, tip: tip, base: base, branch: "pr/feature"))
        await store.send(.set(\.input, prID))
        await store.send(.fetchButtonTapped)
        await store.receive(\.eventFetched)
        await store.receive(\.prDiffResult)
        await store.receive(\.delegate.patchLoaded)

        // The later "v3" push must NOT appear: the PR is its tagged tip.
        let fBlock = files.value.first { $0.filePath == "f.txt" }?.diffBlock ?? ""
        #expect(fBlock.contains("+v2"))
        #expect(!fBlock.contains("+v3"))
        #expect(files.value.map(\.filePath).contains("g.txt"))
    }

    @Test("PR without merge-base diffs the tip against its parent (depth-2 fetch)")
    func tipVsParentWhenNoMergeBase() async throws {
        let (dir, _, tip) = try makeSampleRepo(allowSHAInWant: true)
        let server = try await startServer(root: dir)
        defer { server.shutdown() }

        let (store, files, metadata) = try makeStore(event: prEvent(clone: server.url, tip: tip, base: nil, branch: nil))
        await store.send(.set(\.input, prID))
        await store.send(.fetchButtonTapped)
        await store.receive(\.eventFetched)
        await store.receive(\.prDiffResult)
        await store.receive(\.delegate.patchLoaded)

        let fBlock = files.value.first { $0.filePath == "f.txt" }?.diffBlock ?? ""
        #expect(fBlock.contains("+v2"))
        #expect(files.value.map(\.filePath).contains("g.txt"))
        #expect(metadata.value?.parentCommit == nil)
    }

    @Test("unreachable clone URL surfaces the prError fetch-failed state")
    func unreachableServerFailsCleanly() async throws {
        let (store, _, _) = try makeStore(event: prEvent(
            clone: "http://127.0.0.1:1/repo.git",
            tip: String(repeating: "1", count: 40),
            base: String(repeating: "2", count: 40),
            branch: nil
        ))
        await store.send(.set(\.input, prID))
        await store.send(.fetchButtonTapped)
        await store.receive(\.eventFetched)
        await store.receive(\.prDiffResult) {
            if case let .prError(msg) = $0.status {
                #expect(msg.contains("127.0.0.1:1"))
            } else {
                Issue.record("expected prError, got \($0.status)")
            }
        }
    }
}
#endif
