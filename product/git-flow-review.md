# Git Flow Review

## Overview

Git Flow Review is a two-party review loop over a git change set. An AI agent kicks off a review of an eligible GitHub pull request (or an explicit branch-versus-base change set), produces its own line-anchored findings and an overall summary, then hands the diff to the human reviewer in a **blind pass** — the AI feedback is present in the session but hidden. After the reviewer records their own feedback, the AI feedback is revealed and the two parties **workshop** the combined set: the reviewer accepts, edits, or rejects each AI finding and each of their own comments. The surviving set is posted back to the GitHub pull request as inline line-anchored comments plus one overall review comment. The goal is higher-quality feedback in a timely manner: the AI's coverage and the human's judgment, each kept honest by the other.

The flow splits across two surfaces. The **agent recipe** (a slash command) owns source selection, the AI review, session setup, and posting back to GitHub. The **review tool** owns the blind pass, the reveal, and the workshop. Per the reviewer's direction this is scoped to macOS review-tool surfaces; the command-level workflow is platform-neutral.

This feature composes with Shepherd Review (`shepherd-review.md`): it reuses that feature's changeset detection, file filtering, and priority ordering, and launches the same review-tool session. It does not modify the existing Shepherd Review behavior — a `/shepherd-review` invocation without the git-flow launch mode is unchanged.

## User Stories

### US-GFR-1: Kick off a review of an eligible PR without hunting for it
**As a** reviewer, **I want to** invoke the git flow review command with no arguments and see the eligible open pull requests for the repository I'm in, **so that** I can pick a PR and start the review loop in one step.

### US-GFR-2: Point the review at any change set
**As a** reviewer, **I want to** give the command a pull request reference (URL or number) or an explicit branch (with an optional base, defaulting to the main branch), **so that** I can run the same AI-plus-human loop on any change set, whether or not it has a PR yet.

### US-GFR-3: Get an AI review with line numbers and overall feedback
**As a** reviewer, **I want to** the AI to review the change set and produce per-file findings anchored to specific line numbers plus an overall feedback summary, **so that** its feedback is precise enough to act on, not vague prose.

### US-GFR-4: Form my own opinion first
**As a** reviewer, **I want to** review the diff with the AI's feedback hidden, **so that** my first pass is my own judgment, not anchored to what the AI already said.

### US-GFR-5: Compare notes and workshop the feedback
**As a** reviewer, **I want to** see the AI's findings revealed after my pass and reconcile the combined set — accepting, editing, or rejecting each AI finding and each of my own comments, **so that** the final review carries only feedback I stand behind.

### US-GFR-6: Post the final review back to the pull request
**As a** reviewer, **I want to** confirm and post the final combined review to the GitHub pull request — inline comments on the right lines plus one overall review comment, **so that** the author receives actionable, line-anchored feedback without me copying anything by hand.

## Requirements

### Source Selection

How the reviewer points the review at a change set.

- **Source selection** `FR-gfr-source-selection`: The command accepts, as its review source, a GitHub pull request reference (a full pull request URL or a bare PR number, resolved against the repository of the current working directory), or an explicit branch name with an optional base branch (defaulting to the main branch). With no argument, it lists the repository's open, non-draft pull requests and the reviewer selects one. The PR's change set is its head-versus-base diff.
- **Eligibility** `FR-gfr-eligibility`: The no-argument selection list shows only open, non-draft pull requests, each with number, title, and author. Draft, closed, and merged pull requests are excluded from the list. A draft or closed pull request referenced explicitly is allowed but the command states its status before proceeding; if the reviewer declines, the command stops without opening a review.
- **Change set reuse** `FR-gfr-changeset`: For the selected source, the command reuses the Shepherd Review change set pipeline — file filtering (lockfiles, generated files, binaries excluded) and review-priority ordering — unchanged.

### AI Review Pass

The AI's independent review, produced before the reviewer sees anything.

- **AI review findings** `FR-gfr-ai-review`: After the change set is determined, the agent reviews it and produces a set of findings, each anchored to a file and a specific line number in that file, plus one overall feedback summary. Findings whose anchor cannot be resolved to a real line in a reviewed file are dropped before handoff with a note in the conversation.
- **Neutral context preserved** `FR-gfr-neutral-context`: The structured context handed to the review tool keeps the existing separation between neutral (factual) descriptions and review feedback; the AI findings live entirely on the review-feedback side.
- **Blind launch** `FR-gfr-blind-launch`: The review tool session is launched with the AI findings present in the session payload but marked hidden. During the reviewer's first pass, no AI finding text is visible in the tool; neutral context and normal commenting are unaffected.

### Workshop and Reconciliation

The human pass, the reveal, and the merge of the two feedback sets.

- **Reveal after first pass** `FR-gfr-reveal`: When the reviewer completes their first pass, the AI findings are revealed in the review tool, positioned for comparison against the reviewer's own comments.
- **Workshop resolutions** `FR-gfr-workshop`: For every feedback item — each AI finding and each reviewer comment — the reviewer can accept it as-is, edit its text, or reject it. Every item starts accepted except AI findings, which the reviewer must explicitly accept or reject (AI feedback is never posted by default). Rejected items are excluded from the final review.
- **Combined output** `FR-gfr-combined-output`: When the reviewer finishes the workshop, the final review is exported as a structured document: the accepted per-file line-anchored comments (with the final, possibly edited, text) and the overall summary. The output records which comments originated from the reviewer and which from the AI only for the conversation summary; the posted review carries no provenance labels.

### Posting Back

Getting the final review onto the pull request.

- **Confirmation before posting** `FR-gfr-post-confirm`: Before anything is posted, the command shows the reviewer the final review — each inline comment with its file and line, and the overall summary — and asks for explicit confirmation. The reviewer can cancel, and nothing is posted.
- **Post back** `FR-gfr-post-back`: On confirmation, the command posts the final review to the GitHub pull request: each accepted line-anchored comment as an inline comment on the corresponding line of the PR diff, and the overall summary as a single review comment on the PR.
- **Posting failure reporting** `FR-gfr-post-failure`: If posting fails — for any item or for the whole submission (for example, missing authentication, no network, or the PR's diff no longer matching the reviewed lines) — the command reports exactly which items were posted and which were not, and does not report success. The unposted remainder stays available so the reviewer can retry.

### Scope and Non-Goals

- **macOS scope** `NFR-gfr-mac-scope`: The review-tool surfaces of this feature (blind mode, reveal, workshop) are macOS-only. The command-level workflow (source selection, AI review, posting) is platform-neutral and does not depend on macOS.
- **No new app dependencies** `NFR-gfr-no-new-deps`: The feature adds no new dependencies to the review tool; it reuses the existing session, context, and commenting machinery.
- **Single reviewer** `NFR-gfr-single-reviewer`: The loop assumes one human reviewer per invocation; multi-reviewer reconciliation is out of scope.

## Acceptance Criteria

- [ ] **Eligible list only** `AC-gfr-eligible-list`: Given the repository has open, draft, and merged PRs, when the command is invoked with no argument, then only the open non-draft PRs are offered for selection, each showing number, title, and author.
- [ ] **Explicit status warning** `AC-gfr-explicit-status`: Given a draft PR is referenced explicitly, when the command resolves it, then the PR's draft status is stated to the reviewer before the review opens.
- [ ] **Findings anchored** `AC-gfr-ai-findings-anchored`: After the AI review, every finding handed to the review tool names a reviewed file and a valid line number in that file, and an overall summary exists.
- [ ] **Blind pass leaks nothing** `AC-gfr-blind-no-leak`: During the reviewer's first pass, no AI finding text is visible anywhere in the review tool.
- [ ] **Workshop resolutions honored** `AC-gfr-workshop-resolutions`: Given the workshop contains AI findings and reviewer comments, when the reviewer rejects one AI finding, edits another, and accepts a reviewer comment, then the combined output contains only the accepted items, with the edited item carrying its edited text, and no unaccepted AI finding appears in the output.
- [ ] **Confirmation gates posting** `AC-gfr-confirm-before-post`: Posting occurs only after the reviewer explicitly confirms the shown final review; on cancel, nothing is posted.
- [ ] **Posted review shape** `AC-gfr-post-back-lines`: After posting, the pull request carries one inline comment per accepted line-anchored item on the correct file and line, and exactly one overall review comment containing the summary.
- [ ] **Failures reported** `AC-gfr-post-failure-reported`: Given posting fails partway, then the command reports the posted and unposted items separately and does not claim success.

## Open Questions

1. **Duplicate anchors.** When the reviewer's comment and an AI finding land on the same line, should the workshop offer a one-action merge into a single comment? Currently they remain separate items the reviewer can edit to converge. (Deferred; the edit path covers it.)
2. **Posting as a PR review vs. standalone comments.** GitHub supports both a single review (with a verdict) and standalone inline comments. The spec requires the summary as one review comment and inline items as line comments; whether to also set a review verdict (approve/request changes) is left to the reviewer at confirmation time in v1 and is not required.
3. **Non-PR branch results.** When the source is a bare branch with no PR, the loop runs through the workshop and the combined output is delivered in the conversation (as today's Shepherd Review feedback handoff) — there is nothing to post to. This is acceptable behavior, not an error.

## Dependencies

- Shepherd Review (`shepherd-review.md`) — changeset detection, file filtering, priority ordering, session launch, and context handoff.
- The review tool's multi-file session, inline commenting, and neutral-vs-review context separation.
- GitHub CLI availability and authentication on the invoking machine for listing, diffing, and posting (an engineering concern; surfaced to the reviewer as a clear error when absent).
