# Diff View — macOS Test Plan

> Covers requirements in `../../product/diff-view.md` (design: `../../design/macos/diff-view.md`, engineering: `../../engineering/macos/diff-view.md`)

## What We're Testing

That a review launched from local changes opens as git diffs rather than whole files, that the three staging branches (tracked, untracked, unchanged) each produce the right content, that diff lines are tinted by kind, and that comments and the generated prompt carry the diff through to the agent.

## Coverage Matrix

| Requirement | Test Cases |
|---|---|
| `FR-diff-baseline-ref` | `TC-diff-working-scope`, `TC-diff-commit-scope` |
| `FR-diff-compute` | `TC-diff-tracked-file`, `TC-diff-untracked-file` |
| `FR-diff-display` | `TC-diff-line-kinds`, `TC-diff-is-diff-detection`, `TC-diff-tint` |
| `FR-diff-comment-create` | `TC-diff-comment-added-line` |
| `FR-diff-prompt-format` | `TC-diff-prompt-notation` |
| `FR-diff-empty-state` | `TC-diff-unchanged-file` |
| `NFR-diff-accessibility` | `TC-diff-prefix-present` |

## Test Cases

### Staging (launcher)

#### `TC-diff-tracked-file` — A tracked, modified file stages as its diff
Given a repository with an uncommitted edit to a tracked file, when `shepherd-launch.sh --diff HEAD <path>` runs, then that file's `content` in `session.json` begins with `diff --git a/<repo-relative-path>` and contains the edit as `+`/`-` lines. (Manual, against a scratch file.)

#### `TC-diff-untracked-file` — An untracked file stages as all additions
Given a newly created file that is untracked, when the launcher runs with `--diff HEAD`, then its content is a `new file mode` diff whose every content line is an addition, and the header path is repo-relative rather than absolute. (Manual.)

#### `TC-diff-unchanged-file` — An unchanged file falls back to full content
Given a tracked file with no change against the scope's base, when the launcher runs with `--diff HEAD`, then that file's content is its whole text (not empty), and a note naming the file is written to stderr. (Manual.)

#### `TC-diff-working-scope` — The default scope diffs against the last commit
Given `/shepherd-review` with no scope argument, when files open, then each shows its change against `HEAD`, including both staged and unstaged edits. (Manual.)

#### `TC-diff-commit-scope` — A commit review diffs against the commit's parent
Given `/shepherd-review --commit <sha>`, when files open, then each shows the change that commit introduced, not the state of the file at that commit. (Manual.)

### Classification and rendering

#### `TC-diff-line-kinds` — Line kinds are classified correctly
Given a unified diff, then `+++`, `---`, `@@`, `diff --git`, `index`, and mode lines classify as headers; `+foo` classifies as added; `-foo` as removed; a leading-space line as context. Header prefixes take precedence over the `+`/`-` check. (Unit test — `DiffLineKindTests`.)

#### `TC-diff-is-diff-detection` — Diff content is recognised, source is not
Given content beginning with `diff --git `, then `FileNode.isDiff` is true for both tracked and `--no-index` diff headers; given ordinary source, or prose that merely mentions `diff --git`, then it is false. (Unit test — `DiffLineKindTests`.)

#### `TC-diff-tint` — Added and removed lines are tinted, headers dimmed
Given a diff open in the code viewer, then added lines carry a green wash, removed lines a red wash, header lines no wash and secondary text, and context lines neither. Selecting a tinted line shows the selection tint instead. (Manual.)

#### `TC-diff-prefix-present` — Line kind is legible without colour
Given a diff open in the code viewer, then every added line still begins with `+` and every removed line with `-`, so kind is readable with tint disregarded. (Manual.)

### Comments and prompt

#### `TC-diff-comment-added-line` — Comment attaches to an added line
Given a diff is open, when the reviewer clicks the gutter of a `+` line and submits a comment, then the comment attaches to that line and the gutter shows an indicator. (Manual.)

#### `TC-diff-prompt-notation` — Generated prompt preserves diff notation
Given comments on added and removed lines, when the prompt is generated, then the quoted code blocks retain the `+` and `-` prefixes verbatim. (Manual.)
