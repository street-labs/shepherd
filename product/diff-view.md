# Diff View

## Overview

When a review is launched from a set of local changes — uncommitted edits, a branch, a commit, or a commit range — Shepherd shows each file as a **unified git diff** rather than as its whole content. The reviewer sees what changed, with the surrounding context git provides, and comments directly on the added, removed, and context lines.

This matches the primary use case: a developer works alongside an AI coding agent that modifies files, and afterwards wants to review *the change*. Opening the entire file buries a three-line edit in a thousand lines of unchanged code. The diff surfaces exactly the information the reviewer needs, and the generated prompt carries the diff notation through to the agent, so the agent sees which lines the feedback refers to.

Diff rendering is not a mode the reviewer toggles inside the app. It is a property of how the review was launched: a changeset review renders diffs, and a review of a specific document renders the document. Shepherd does not implement its own diff algorithm — `git` computes the diff at launch time and Shepherd renders and annotates the result. This is the same rendering path already used for NIP-34 patch and PR reviews, where the content under review is also a unified diff.

## User Stories

### US-DIFF-1: See what changed in a file
**As a** developer reviewing AI-generated code changes, **I want to** see a diff of each changed file rather than the whole file, **so that** I can focus my review on what actually changed.

### US-DIFF-4: Comment on diff lines
**As a** developer reviewing a diff, **I want to** add inline comments on any line in the diff — added, removed, or context — **so that** I can annotate specific changes with feedback for the AI agent.

### US-DIFF-5: Generate a prompt from diff comments
**As a** developer who has annotated a diff, **I want** the generated prompt to carry the diff notation, **so that** the agent understands exactly which change each comment is responding to.

### US-DIFF-7: Review a branch or a commit as a diff
**As a** developer reviewing a branch, a commit, or a commit range, **I want** each file rendered as a diff against that scope's baseline, **so that** the review shows the change the scope describes rather than the state it produced.

## Requirements

### Functional Requirements

#### `FR-diff-baseline-ref` -- Diff against the review scope's baseline
A review launched from a set of local changes renders each file as a unified diff against the baseline implied by the review's scope: the working tree against its last commit for uncommitted work, the branch point for a branch review, the parent commit for a single-commit review, and the start of the range for a range review. The baseline is supplied by whatever initiated the review; the reviewer does not choose it inside the application.

#### `FR-diff-compute` -- Diffs are computed by git, not by Shepherd
The unified diff is produced by the version control system at launch time. Shepherd does not implement a diff algorithm. A file with no version control history (newly created, untracked) is rendered as an all-added diff, so new files are reviewable in the same form as edited ones.

#### `FR-diff-display` -- Added and removed lines are visually distinguished
Lines in a diff are visually distinguished by kind: added lines carry an additive tint, removed lines carry a subtractive tint, hunk boundaries and file headers are de-emphasised, and context lines are untinted. The distinction reads correctly in both light and dark appearance. Line numbering in the diff is the diff's own line numbering — the reviewer's comments anchor to the diff as presented.

#### `FR-diff-comment-create` -- Comments attach to diff lines
The reviewer can add an inline comment on any line of a diff — added, removed, context, or hunk header — and on a contiguous range of them, using the same interaction as commenting on a whole file (`FR-crp-line-comment-create`, `FR-crp-line-range-comment`).

#### `FR-diff-prompt-format` -- The generated prompt carries diff notation
A prompt generated from a diff review pairs each comment with the diff lines it covers, preserving the `+` / `-` / context prefixes, so the receiving agent can tell an addition from a removal from unchanged context.

#### `FR-diff-empty-state` -- A file with no changes falls back to its full content
When a file named for review has no changes against the baseline, it is presented as its full content rather than as an empty diff, so the file remains readable and commentable, and the launch says so rather than silently showing something other than a diff.

### Non-Functional Requirements

#### `NFR-diff-compute-perf` -- Diff computation does not delay launch
Computing the diffs for a review must not add a perceptible delay to launch: under one second for a changeset of up to 50 files.

#### `NFR-diff-render-perf` -- Diff rendering performance
A diff is rendered through the same virtualized line rendering as a whole file (`NFR-crp-large-file-perf`); scrolling a large diff is smooth.

#### `NFR-diff-accessibility` -- Diff line distinction is not colour-alone
The distinction between added, removed, and context lines is conveyed by the diff's own `+` / `-` line prefixes as well as by tint, so the diff is readable without relying on colour perception.

## Acceptance Criteria

#### `AC-diff-launch-shows-diff` -- A changeset review opens as diffs
**Given** a repository with uncommitted edits to two files, **when** a changeset review is launched, **then** each file's tab shows a unified diff of that file rather than its whole content.

#### `AC-diff-added-removed-tint` -- Added and removed lines are tinted
**Given** a diff is open, **when** the reviewer looks at it, **then** lines beginning with `+` carry an additive tint, lines beginning with `-` carry a subtractive tint, and file-header and hunk-header lines are de-emphasised.

#### `AC-diff-untracked-all-added` -- An untracked file renders as all additions
**Given** a review includes a newly created, untracked file, **when** the review opens, **then** that file is shown as a diff in which every line is an addition.

#### `AC-diff-commit-scope-baseline` -- A commit review diffs against the commit's parent
**Given** a review scoped to a single commit, **when** the review opens, **then** each file is diffed against that commit's parent, so the reviewer sees the change the commit introduced.

#### `AC-diff-comment-on-added-line` -- Comment can be placed on an added line
**Given** a diff is open showing an added line, **when** the reviewer clicks that line's gutter and submits a comment, **then** the comment is attached to that line and the gutter shows an indicator.

#### `AC-diff-prompt-includes-diff` -- Generated prompt includes diff notation
**Given** a diff review with comments on added and removed lines, **when** the reviewer generates a prompt, **then** the code blocks in the prompt retain the `+` and `-` prefixes.

#### `AC-diff-unchanged-file-full-content` -- An unchanged file falls back to full content
**Given** a file named for a diff review is identical to the baseline, **when** the review opens, **then** that file's tab shows its full content rather than an empty diff, and the launch output names the file as unchanged.

## Open Questions

1. **Word-level diff highlighting**: intra-line highlighting of the changed words within a changed line is deferred; line-level is sufficient.
2. **Side-by-side view**: deferred; unified only.
3. **Expanding beyond git's context**: the diff shows the context git emits. Expanding a collapsed region to see more surrounding code is deferred — the reviewer can open the whole file instead.
4. **Reviewing a document**: launching a review of a specific document (rather than a changeset) shows the document, not a diff. Whether that should become diff-aware when the document has local edits is open.

## Dependencies

- **`FR-crp-file-display`**: a diff is rendered through the same code viewer as a file.
- **`FR-crp-line-comment-create`**, **`FR-crp-line-range-comment`**: commenting on a diff reuses the existing interactions.
- **`FR-crp-prompt-format`**: the diff-aware prompt is the existing prompt format applied to diff content.
- **`FR-srm-multi-file-launch`**, **`FR-srm-scope-modes`**: the changeset review supplies the files and the baseline.
- **Git**: diffs are computed by `git`; a review of local changes requires a git repository (`FR-sr-git-required`).
