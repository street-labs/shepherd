import Foundation
import ComposableArchitecture

/// Acquires a NIP-34 PR (kind `1618`) diff by shelling out to `git` in a
/// temporary repository. macOS-only at the live layer; the iOS in-app PR path
/// does not use this client (it iterates referenced patch events instead — see
/// `FR-sri-pr-open-patches`). Implements `FR-srm-pr-open-diff`,
/// `NFR-srm-pr-git-required`.
public struct GitDiffClient: Sendable {
    /// The PR references needed to fetch + diff: clone URLs (tried in order),
    /// the tip commit (`c` tag), the merge-base, and an optional branch name
    /// fallback when the server rejects fetching by arbitrary SHA.
    public struct Spec: Equatable, Sendable {
        public var cloneURLs: [String]
        public var tipCommit: String
        public var mergeBase: String
        public var branchName: String?

        public init(cloneURLs: [String], tipCommit: String, mergeBase: String, branchName: String? = nil) {
            self.cloneURLs = cloneURLs
            self.tipCommit = tipCommit
            self.mergeBase = mergeBase
            self.branchName = branchName
        }
    }

    /// Outcome of acquiring a PR diff.
    public enum Result: Equatable, Sendable {
        /// The net unified diff between merge-base and tip (non-empty).
        case diff(String)
        /// The merge-base..tip range produced no changes.
        case empty
        /// `git` is not on the PATH. (`NFR-srm-pr-git-required`.)
        case noGit
        /// No clone URL was reachable, or the commits could not be fetched.
        /// Carries the offending clone URL + the git error message.
        case fetchFailed(String)
    }

    public var acquirePRDiff: @Sendable (Spec) async -> Result

    public init(acquirePRDiff: @Sendable @escaping (Spec) async -> Result) {
        self.acquirePRDiff = acquirePRDiff
    }
}

extension GitDiffClient: DependencyKey {
    public static let liveValue: GitDiffClient = {
        #if os(macOS)
        // Implements: FR-srm-pr-open-diff, NFR-srm-pr-git-required
        return GitDiffClient { spec in await acquireLive(spec) }
        #else
        // iOS has no subprocess; the iOS PR path never uses this client (it
        // iterates referenced patch events instead). Stub satisfies the key.
        return GitDiffClient { _ in .noGit }
        #endif
    }()

    public static let testValue = GitDiffClient { _ in .empty }
}

extension DependencyValues {
    public var gitDiffClient: GitDiffClient {
        get { self[GitDiffClient.self] }
        set { self[GitDiffClient.self] = newValue }
    }
}

#if os(macOS)
// Implements: FR-srm-pr-open-diff
private func acquireLive(_ spec: GitDiffClient.Spec) async -> GitDiffClient.Result {
    // NFR-srm-pr-git-required: no git on PATH -> precise noGit state.
    guard shellExit("/usr/bin/env", ["git", "--version"]) == 0 else { return .noGit }

    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("shepherd-pr-\(UUID().uuidString)", isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    } catch {
        return .fetchFailed("(could not create temp repo: \(error.localizedDescription))")
    }
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // `git init` (bare-ish: we only fetch objects + compute a diff, no checkout).
    guard runGit(tempDir, ["init", "--quiet"]) == 0 else {
        return .fetchFailed("(could not init temp repo)")
    }

    // Fetch the tip + merge-base from the first reachable clone URL. Try
    // fetch-by-SHA first; if the server rejects it and a branch-name is present,
    // fall back to fetching the branch (delivers the tip + ancestors including
    // the merge-base). ponytail: never full-clone; only the needed commits.
    var lastError = ""
    var fetched = false
    for url in spec.cloneURLs {
        if runGit(tempDir, ["fetch", "--quiet", url, spec.tipCommit, spec.mergeBase]) == 0 {
            fetched = true
            break
        }
        // Capture stderr for the failure message.
        lastError = runGitErr(tempDir, ["fetch", "--quiet", url, spec.tipCommit, spec.mergeBase])
        if let branch = spec.branchName,
           runGit(tempDir, ["fetch", "--quiet", url, branch]) == 0 {
            fetched = true
            break
        }
        lastError = lastError.isEmpty
            ? runGitErr(tempDir, ["fetch", "--quiet", url, spec.tipCommit])
            : lastError
    }
    guard fetched else {
        let firstURL = spec.cloneURLs.first ?? "(no clone URL)"
        let detail = lastError.trimmingCharacters(in: .whitespacesAndNewlines)
        return .fetchFailed("\(firstURL): \(detail.isEmpty ? "unreachable" : detail)")
    }

    // Compute the net diff. `--no-color` + unified format. An empty diff -> .empty.
    let diff = runGitOut(tempDir, ["diff", "--no-color", "\(spec.mergeBase)..\(spec.tipCommit)"])
    let trimmed = diff.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .empty }
    return .diff(diff)
}

/// Run `git` in `dir` and return the exit status. stdout/stderr are discarded.
private func runGit(_ dir: URL, _ args: [String]) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["git"] + args
    p.currentDirectoryURL = dir
    p.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
    p.standardError = FileHandle(forWritingAtPath: "/dev/null")
    do { try p.run(); p.waitUntilExit() } catch { return -1 }
    return p.terminationStatus
}

/// Run `git` in `dir` and return stdout as a string (stderr discarded).
private func runGitOut(_ dir: URL, _ args: [String]) -> String {
    let pipe = Pipe()
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["git"] + args
    p.currentDirectoryURL = dir
    p.standardOutput = pipe
    p.standardError = FileHandle(forWritingAtPath: "/dev/null")
    do { try p.run() } catch { return "" }
    p.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

/// Run `git` in `dir` and return stderr as a string (stdout discarded).
private func runGitErr(_ dir: URL, _ args: [String]) -> String {
    let pipe = Pipe()
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["git"] + args
    p.currentDirectoryURL = dir
    p.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
    p.standardError = pipe
    do { try p.run() } catch { return "" }
    p.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

/// Run a command and return its exit status (stdout/stderr discarded). Used for
/// the `git --version` PATH probe.
private func shellExit(_ exe: String, _ args: [String]) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: exe)
    p.arguments = args
    p.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
    p.standardError = FileHandle(forWritingAtPath: "/dev/null")
    do { try p.run(); p.waitUntilExit() } catch { return -1 }
    return p.terminationStatus
}
#endif
