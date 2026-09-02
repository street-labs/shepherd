import Foundation

/// Splits a NIP-34 patch event's unified-diff content into one block per changed
/// file and extracts patch metadata from the event. Also validates the event kind
/// and diff format. Implements the parse half of `FR-srm-patch-open-load` and the
/// validation half of `FR-srm-patch-open-fetch`.
///
/// NIP-34 patch events are kind `1617` and their content is the output of
/// `git format-patch`: a commit-message subject followed by a unified diff. This
/// validator requires the content to contain a `diff --git` header and at least
/// one `@@` hunk (the diff body), and treats any text before the first
/// `diff --git` line as the commit-message subject. Status is rendered `open`
/// unconditionally in v1 — NIP-34 status lives on separate kind `1630`–`1633`
/// events, not a tag on the patch event, and v1 does not fetch them.
public enum PatchDiffSplitter {
    /// NIP-34 patch event kind.
    public static let patchKind = 1617

    /// NIP-34 pull request event kind.
    public static let prKind = 1618

    /// A single changed file's diff block.
    public struct DiffFile: Equatable, Sendable {
        public var filePath: String
        public var diffBlock: String
        public init(filePath: String, diffBlock: String) {
            self.filePath = filePath
            self.diffBlock = diffBlock
        }
    }

    /// Outcome of validating a fetched event.
    public enum ValidationResult: Equatable, Sendable {
        /// The event kind is not `1617`. Carries the offending kind.
        case wrongKind(kind: Int)
        /// The content has no `diff --git` header or no `@@` hunk.
        case badDiff
        /// The event is a valid patch: per-file diff blocks + metadata.
        case ok(files: [DiffFile], metadata: ReviewContext.PatchMetadata)
    }

    /// Validate the event kind, then parse the unified-diff content into per-file
    /// blocks and build the patch metadata record. Pure function — no I/O.
    // Implements: FR-srm-patch-open-load, FR-srm-patch-open-fetch
    public static func validate(_ event: NostrEvent) -> ValidationResult {
        guard event.kind == patchKind else {
            return .wrongKind(kind: event.kind)
        }
        let content = event.content
        // Locate the first `diff --git` header. Everything before it (trimmed,
        // first non-empty line) is the commit-message subject; the rest is the diff.
        guard let diffRange = content.range(of: "diff --git") else {
            return .badDiff
        }
        let preamble = content[..<diffRange.lowerBound]
        let diffBody = content[diffRange.lowerBound...]
        // A valid unified diff has at least one hunk marker.
        guard diffBody.contains("@@") else { return .badDiff }

        let files = splitDiffBlocks(String(diffBody))
        // A `diff --git` header with no parsed file path is malformed.
        if files.isEmpty { return .badDiff }

        let commitMessage = preamble
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? ""
        let truncatedMessage = commitMessage.count > 60
            ? String(commitMessage.prefix(60))
            : commitMessage

        let metadata = ReviewContext.PatchMetadata(
            eventID: event.id,
            shortEventID: shortID(event.id),
            author: truncatedPubkey(event.pubkey),
            commitMessage: truncatedMessage,
            parentCommit: parentCommit(from: event.tags),
            status: "open",
            repoCoordinate: repoCoordinate(from: event.tags),
            replies: []
        )
        return .ok(files: files, metadata: metadata)
    }

    /// Split a unified-diff body (beginning at the first `diff --git` line) into
    /// one `DiffFile` per changed file, named by the path in the `b/` side of the
    /// `diff --git a/<path> b/<path>` header.
    static func splitDiffBlocks(_ diffBody: String) -> [DiffFile] {
        let lines = diffBody.components(separatedBy: "\n")
        var files: [DiffFile] = []
        var currentPath: String? = nil
        var currentLines: [String] = []
        for line in lines {
            if line.hasPrefix("diff --git ") {
                if let path = currentPath {
                    files.append(DiffFile(filePath: path, diffBlock: currentLines.joined(separator: "\n")))
                }
                currentPath = pathFromDiffHeader(line)
                currentLines = [line]
            } else {
                currentLines.append(line)
            }
        }
        if let path = currentPath {
            files.append(DiffFile(filePath: path, diffBlock: currentLines.joined(separator: "\n")))
        }
        return files
    }

    /// Parse `diff --git a/<path> b/<path>` → the `<path>` (the `b/` side, which is
    /// the post-patch name; renamed files use their new path, matching the shared
    /// `AC-sr-excludes-deleted` convention). Returns nil if the header is
    /// malformed. A `/dev/null` `b` side (deletion-only) still yields the `a/`
    /// path so the reviewer can see and comment on the removal.
    static func pathFromDiffHeader(_ line: String) -> String? {
        // `diff --git a/foo.swift b/foo.swift`
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 4 else { return nil }
        let a = String(parts[2])
        let b = String(parts[3])
        let aPath = a.hasPrefix("a/") ? String(a.dropFirst(2)) : a
        let bPath = b.hasPrefix("b/") ? String(b.dropFirst(2)) : b
        // Deletion: the `b` side is `/dev/null` (raw `/dev/null` or `b/dev/null`)
        // → use the `a` path so the removed file is still visible and commentable.
        if b == "/dev/null" || bPath == "dev/null" { return aPath }
        return bPath
    }

    /// 8-character short id from a 64-char hex event id (first 8 chars).
    static func shortID(_ id: String) -> String {
        String(id.prefix(8))
    }

    /// ponytail: v1 has no roster/name resolution, so the author falls back to a
    /// truncated hex pubkey. A truncated npub would be friendlier but npub
    /// encoding lives in `Dependencies/Bech32.swift` and SharedModels stays
    /// dependency-free; upgrade to npub when a roster resolver lands.
    public static func truncatedPubkey(_ pubkey: String) -> String {
        guard pubkey.count > 16 else { return pubkey }
        return String(pubkey.prefix(12)) + "…"
    }

    /// Whether the event is a NIP-34 patch-series cover letter: a kind `1617`
    /// whose `t` tags include `cover-letter`. A cover letter describes the
    /// series (commit message only, no diff); the diffs live in the series'
    /// reply patches that reference the cover letter via `e` tags (marker
    /// `root`/`reply`). This is the structure `ngit`/`borg --force-patch`
    /// publishes for multi-patch PRs.
    public static func isCoverLetter(_ event: NostrEvent) -> Bool {
        event.kind == patchKind && event.tags.contains { $0.count >= 2 && $0[0] == "t" && $0[1] == "cover-letter" }
    }

    /// First `parent-commit` tag value (full hash), shortened to 8 chars.
    public static func parentCommit(from tags: [[String]]) -> String? {
        for tag in tags where tag.count >= 2 && tag[0] == "parent-commit" {
            return shortID(tag[1])
        }
        return nil
    }

    /// First `a` tag value (NIP-34 repo coordinate `30617:<owner>:<repo>`).
    public static func repoCoordinate(from tags: [[String]]) -> String? {
        for tag in tags where tag.count >= 2 && tag[0] == "a" {
            return tag[1]
        }
        return nil
    }

    // MARK: - PR (kind 1618) helpers

    /// All `clone` tag values (git clone URLs), in tag order. Implements the
    /// clone-URL acquisition of `FR-srm-pr-open-fetch` / `FR-sr-pr-diff-acquisition`.
    public static func cloneURLs(from tags: [[String]]) -> [String] {
        tags.filter { $0.count >= 2 && $0[0] == "clone" }.map { $0[1] }
    }

    /// First `c` tag value (tip commit id of the PR branch). nil if absent.
    public static func tipCommit(from tags: [[String]]) -> String? {
        for tag in tags where tag.count >= 2 && tag[0] == "c" { return tag[1] }
        return nil
    }

    /// First `merge-base` tag value (full hash). nil if absent.
    public static func mergeBase(from tags: [[String]]) -> String? {
        for tag in tags where tag.count >= 2 && tag[0] == "merge-base" { return tag[1] }
        return nil
    }

    /// First `branch-name` tag value. nil if absent.
    public static func branchName(from tags: [[String]]) -> String? {
        for tag in tags where tag.count >= 2 && tag[0] == "branch-name" { return tag[1] }
        return nil
    }

    /// First `subject` tag value, else the first non-empty line of `content`.
    /// Truncated to 60 chars for display. Implements `FR-sr-pr-metadata-display`.
    public static func subject(from event: NostrEvent) -> String {
        let subject = event.tags.first(where: { $0.count >= 2 && $0[0] == "subject" }).map { $0[1] }
        let resolved = subject ?? event.content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? ""
        return resolved.count > 60 ? String(resolved.prefix(60)) : resolved
    }

    /// Every `e` tag value (referenced event ids) on the PR event, as a superset.
    /// iOS iterates these as referenced kind `1617` patches (`FR-sri-pr-open-patches`).
    /// Reading every `e` tag is a harmless superset that tolerates a PR
    /// referencing multiple patches.
    // Implements: FR-sri-pr-open-patches
    public static func referencedPatchIDs(from tags: [[String]]) -> [String] {
        tags.filter { $0.count >= 2 && $0[0] == "e" }.map { $0[1] }
    }

    /// Build a `PatchMetadata` record from a kind `1618` PR event. The PR's
    /// `merge-base` tag becomes `parentCommit` (short); `c` becomes `tipCommit`;
    /// `branch-name` becomes `branchName`. Status is `open` in v1 (NIP-34 status
    /// lives on separate kind `1630`–`1633` events, not a tag on the PR event).
    // Implements: FR-sr-pr-metadata-display, FR-srm-pr-open-load, FR-sri-pr-open-load
    public static func prMetadata(from event: NostrEvent) -> ReviewContext.PatchMetadata {
        ReviewContext.PatchMetadata(
            eventID: event.id,
            shortEventID: shortID(event.id),
            author: truncatedPubkey(event.pubkey),
            commitMessage: subject(from: event),
            parentCommit: mergeBase(from: event.tags).map { shortID($0) },
            status: "open",
            repoCoordinate: repoCoordinate(from: event.tags),
            tipCommit: tipCommit(from: event.tags).map { shortID($0) },
            branchName: branchName(from: event.tags),
            replies: []
        )
    }

    /// Split an arbitrary unified-diff string (e.g. the output of
    /// `git diff <merge-base>..<tip>`, or the unioned content of referenced patch
    /// events) into per-file `DiffFile` blocks. Returns nil if the string has no
    /// `diff --git` header or no `@@` hunk (an empty/invalid diff). Implements the
    /// split half of `FR-srm-pr-open-load` and `FR-sri-pr-open-load`.
    // Implements: FR-srm-pr-open-load, FR-sri-pr-open-load
    public static func splitUnifiedDiff(_ diff: String) -> [DiffFile]? {
        guard let range = diff.range(of: "diff --git"), diff[range.lowerBound...].contains("@@") else {
            return nil
        }
        let files = splitDiffBlocks(String(diff[range.lowerBound...]))
        return files.isEmpty ? nil : files
    }
}
