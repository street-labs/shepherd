# Diff View — macOS Engineering

> Based on requirements in `../../product/diff-view.md`
> Based on design in `../../design/macos/diff-view.md`

## Architecture

There is no diff engine in Shepherd and no new feature module. The diff is produced by `git` in the launcher and travels to the app as ordinary file content; the app's only job is to notice that the content is a diff and tint it.

**Launcher (`scripts/shepherd-launch.sh`).** A `--diff <git-diff-args>` option turns on diff staging. Its argument is whatever belongs between `git diff` and `-- <path>` for the review's scope — a rev, a rev pair, a flag, or the empty string — and it is expanded unquoted so all of those forms work through one code path. `review_content` then decides per file:

1. The path is tracked → `git diff --no-color $DIFF_BASE -- <repo-relative-path>`.
2. The path is untracked → `git diff --no-color --no-index -- /dev/null <repo-relative-path>`, which renders the file as all additions. (`--no-index` exits non-zero when the inputs differ, which is the normal case, so its status is ignored.)
3. The result is empty (unchanged in scope) → fall back to the file's full content and note it on stderr.

Paths are made repo-relative before being handed to `git` so the diff headers read `a/Sources/Foo.swift` rather than an absolute path. `session.json` is otherwise unchanged: `path` remains the real file path, and only `content` differs.

**App.** `FileNode.isDiff` is true when the content begins with `diff --git `. That covers every diff-bearing review — a `--diff` launch, a NIP-34 patch, and a PR — without any of them having to declare itself, so patch and PR reviews get the tinting for free. `DiffLineKind(line:)` classifies one line as added, removed, header, or context; header prefixes are matched before `+`/`-` so `+++` and `---` are not mistaken for content. `CodeViewerView` passes a kind per line when `file.isDiff`, and `LineView` applies it below the focus, selection, and has-comment states.

**Command (`.claude/commands/shepherd-review.md`).** Each scope already had a `git diff` base for reading diffs into the agent's context; the same base is now also passed to the launcher as `--diff`, so the reviewer sees exactly the changeset the agent summarized.

## Why the diff is not computed in the app

Shepherd would need the file's baseline blob, a diff algorithm, and hunk assembly to reproduce what `git diff` already does correctly — including rename detection, mode changes, and binary handling. The launcher is already a git-aware shell script running in the repository, so computing there costs one subprocess per file and no new Swift code.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-diff-baseline-ref | scripts/shepherd-launch.sh | implemented |
| FR-diff-compute | scripts/shepherd-launch.sh | implemented |
| FR-diff-empty-state | scripts/shepherd-launch.sh | implemented |
| FR-diff-display | engineering/apps/macos/Sources/SharedModels/FileNode.swift; engineering/apps/macos/Sources/CodeViewerFeature/LineView.swift | implemented |
| FR-diff-comment-create | engineering/apps/macos/Sources/CodeViewerFeature/CodeViewerFeature.swift | implemented |
| FR-diff-prompt-format | engineering/apps/macos/Sources/SharedModels/PromptBuilder.swift | implemented |

## Testing

`DiffLineKind` is a pure classifier and is unit tested directly, including the `+++`/`---` header cases that a naive prefix check gets wrong. `FileNode.isDiff` is tested against a real `git diff` header, a `--no-index` header, and ordinary source content. The launcher's three staging branches (tracked, untracked, unchanged) have no automated coverage — the repository has no shell-test harness — and are verified by running `review_content` against a scratch file in the repository.
