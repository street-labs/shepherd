---
product-hash: 03fccb4b7bd677b4b7a8742717e7d39cadee5c7107fec9157948f6e33138c556
product-slugs: [AC-gfr-ai-findings-anchored, AC-gfr-blind-no-leak, AC-gfr-confirm-before-post, AC-gfr-eligible-list, AC-gfr-explicit-status, AC-gfr-post-back-lines, AC-gfr-post-failure-reported, AC-gfr-workshop-resolutions, FR-gfr-ai-review, FR-gfr-blind-launch, FR-gfr-changeset, FR-gfr-combined-output, FR-gfr-eligibility, FR-gfr-neutral-context, FR-gfr-post-back, FR-gfr-post-confirm, FR-gfr-post-failure, FR-gfr-reveal, FR-gfr-source-selection, FR-gfr-workshop, NFR-gfr-mac-scope, NFR-gfr-no-new-deps, NFR-gfr-single-reviewer, AC-gfrm-blind-indicator, AC-gfrm-output-structure, AC-gfrm-reveal-on-done, AC-gfrm-undecided-excluded, AC-gfrm-workshop-edit, FR-gfrm-blind-mode, FR-gfrm-reveal, FR-gfrm-review-output, FR-gfrm-workshop-view, NFR-gfr-single-voice]
---

# Git Flow Review — macOS Technical Spec

> Based on requirements in `../../product/git-flow-review.md`
> Based on design in `../../design/macos/git-flow-review.md`
> See also `../../product/macos/git-flow-review.md` for macOS-specific requirements.

## What We're Building

A new agent command, `/git-flow-review`, plus three review-tool additions: blind session mode, the reveal-into-workshop transition, and a structured combined-review output. The command side is a prompt file that shells out to `git` and `gh` (GitHub CLI), reusing the existing `scripts/shepherd-launch.sh` machinery with one new flag; the app side is a session-mode extension of the existing `session.json` → `ReviewContext` → `AppFeature` path and one new SwiftUI/TCA feature module for the workshop. No new package dependencies; `gh` is an external tool dependency of the command, not the app (the app never talks to GitHub).

The key architectural decision: **AI findings ride the existing `ReviewContext` handoff, not a new channel.** The command already embeds a `reviewContext` JSON in `session.json`; we extend that payload with a `gitFlow` block carrying the anchored findings and the blind flag. This keeps the single-session-file contract (`engineering/macos/shepherd-review.md` §"Why session.json instead of a separate context file") intact and requires zero launcher changes — blind mode rides the context payload.

## Technical Approach

1. **Command** (`.claude/commands/git-flow-review.md` + opencode skill peer): resolves the source (PR list via `gh pr list --json number,title,author,isDraft,state`, or explicit ref), computes the change set (`git diff` for branch sources; for a PR, `gh pr view <n> --json headRefName,baseRefName` resolves the branch pair and `gh pr view --json headRefOid` the head commit — the diff itself is computed locally after `git fetch` of the PR head so line numbers match local files), filters/prioritizes exactly as `/shepherd-review` does, performs the AI review, emits a `gitFlow` context block with `reviewMode: "blind"`, and invokes `scripts/shepherd-launch.sh --context <path> <files…>` unchanged.
2. **Launcher**: unchanged. The blind mode is carried entirely by the context payload — `reviewMode` lives in one place, the `gitFlow` block inside `ReviewContext` — so `scripts/shepherd-launch.sh` needs no new flag and `session.json` gains no new top-level field.
3. **App**: `ReviewContext` gains an optional `gitFlow: GitFlowReview?` block; when present with `reviewMode == "blind"`, the review-feedback `ContextPair.review` content for the session is delivered via the git-flow findings (anchored, provenance-tagged) instead of free text, hidden until the Done action; a new `WorkshopFeature` renders the reconciliation list; Done in workshop writes `review-output.json` next to `prompt-output.md`.
4. **Posting**: after the app exits, the command reads `review-output.json`, shows the final review in the conversation for confirmation, and posts via `gh` (one `gh api` call per inline comment on `repos/{owner}/{repo}/pulls/{n}/comments`, plus one `gh pr review --comment --body <summary>`), reporting per-item results.

## Data Model

`ReviewContext` (existing, `SharedModels/ReviewContext.swift`) gains:

```swift
public struct GitFlowReview: Equatable, Codable, Sendable {
    public var reviewMode: String        // "blind" — the sole blind-mode flag; the launcher and session.json are unchanged
    public var summary: String           // overall AI summary (editable in workshop)
    public var findings: [AIFinding]     // line-anchored AI findings

    public struct AIFinding: Equatable, Codable, Sendable {
        public var file: String   // absolute path, same key contract as files map
        public var line: Int      // 1-based line in that file
        public var text: String
    }
}
```

Keying follows the existing absolute-path contract (`engineering/macos/shepherd-review.md`: `reviewContext.files` keys MUST equal `realpath` output for the positional file args). `AIFinding.file` obeys the same rule; the app matches findings to tabs by exact string equality.

Workshop state (in `AppFeature`, not persisted): a list of items, each a value type `{ file, line, text, provenance: yours|ai, resolution: accepted|undecided|rejected }`. Reviewer comments are mapped from the existing `Comment` model at reveal time.

**Combined output** — `~/.shepherd/sessions/<id>/review-output.json`:

```json
{
  "summary": "…final overall summary…",
  "comments": [
    { "file": "/abs/path.swift", "line": 42, "text": "…", "provenance": "ai" }
  ]
}
```

`provenance` is included for the command's conversation summary only; the spec requires posted comments to carry no provenance labels, and the command omits it when posting.

## API / Interface Design

- `scripts/shepherd-launch.sh`: no change (blind mode rides the context payload).
- `SessionClient`: new `writeReviewOutput(_:)` writing `review-output.json` to the session directory; existing `loadSession`/`prompt-output.md` path unchanged (both files are written on workshop finish — the prompt output keeps its current shape so the standard feedback-handoff flow still works).
- `gh` calls made by the command (not the app): `gh pr list`, `gh pr view` (`--json number,title,author,isDraft,state`, `--json headRefName,baseRefName,headRefOid`), `gh api repos/{owner}/{repo}/pulls/{n}/comments` (POST per inline comment), `gh pr review --comment --body <summary>`.

GitHub inline comments anchor to the PR diff, not a bare file+line. The command resolves each `file`/`line` against the local `git diff base...head` to compute the POST body for `pulls/{n}/comments`: `body`, `commit_id` (the PR head OID from `gh pr view --json headRefOid`), repository-relative `path`, and `line` (the line in the file's right side of the diff; `subject_type` is omitted, defaulting to a line comment — a `subject_type: FILE` comment would land on the whole file and mis-anchor, and omitting `commit_id` or using a line not present in the diff returns 422). An item whose line is no longer in the PR diff is reported as unposted per `FR-gfr-post-failure` rather than silently dropped or mis-anchored.

## Component Architecture

| Component | Responsibility |
|---|---|
| `.claude/commands/git-flow-review.md` (+ `.config/opencode/skills/git-flow-review/SKILL.md`) | Command prompt: source selection, eligibility, AI review, context emission, launch, confirmation, posting, failure reporting |
| `SharedModels/ReviewContext.swift` | `GitFlowReview` + `AIFinding` models |
| `AppFeature/AppFeature.swift` | Session-mode state machine: blind → revealed/workshop → finished; maps reviewer `Comment`s + findings into workshop items; writes output via `SessionClient` |
| `WorkshopFeature/` (new module) | Workshop list UI: rows, resolutions, inline edit, navigate-to-line, summary field, Finish & Export |
| `ReviewContextFeature/` | Blind badge; suppress review-feedback sections while blind |
| `Dependencies/SessionClient.swift` | `review-output.json` write |

## State Management

`AppFeature` gains a `gitFlowPhase` enum: `nil` (normal session, unchanged behavior), `.blind`, `.workshop(items)`, `.finished`. Done action routes by phase: `.blind` → build items (reviewer comments as accepted `yours`, findings as `undecided` `ai`) → `.workshop`; `.workshop` → write `review-output.json` (+ `prompt-output.md` as today) and close. Cancel in either phase closes without revealing/writing. No new persistence; all workshop state is in-memory for the session lifetime.

## Error Handling

- `gh` missing or unauthenticated at any command-side step: clear error naming the fix (`gh auth login`), nothing launched/posted.
- Finding whose `file`/`line` doesn't resolve to a loaded tab: dropped by the command before launch with a conversation note (`FR-gfr-ai-review`).
- Posting failures: the command posts items individually, collects per-item results, and reports posted vs. unposted (`FR-gfr-post-failure`); the unposted set is re-runnable by re-invoking the confirm step.
- Malformed `review-output.json`: the command reports it and offers to reopen the session rather than posting garbage.

## Performance Considerations

None significant. The workshop list is bounded by review size (tens of items); per-item `gh api` posts are sequential and typically <20 calls.

## Security Considerations

The app never gains GitHub access; all network posting happens in the agent command under the reviewer's existing `gh` authentication, and only after explicit confirmation (`FR-gfr-post-confirm`). No secrets enter `session.json`.

## Implementation Plan

1. **Models** — `GitFlowReview`/`AIFinding` in `ReviewContext.swift` (backward-compatible, optional field; carries the blind flag). Foundation for everything else; ships inert.
2. **Blind mode in app** — `gitFlowPhase` in `AppFeature`, blind badge in `ReviewContextFeature`, suppression of review-feedback sections. Verifiable standalone.
3. **Workshop** — reveal on Done, `WorkshopFeature` list with accept/edit/reject/navigate, summary editing, `review-output.json` write.
4. **Command** — `/git-flow-review` prompt file + opencode skill: selection, eligibility, AI review with anchor validation, blind launch, then confirmation + posting with per-item failure reporting.
5. **Install** — extend `scripts/install-command.sh` to symlink the new command file (same pattern as `FR-srm-install`).

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| `FR-gfr-source-selection` | .claude/commands/git-flow-review.md; .config/opencode/skills/git-flow-review/SKILL.md | planned |
| `FR-gfr-eligibility` | .claude/commands/git-flow-review.md; .config/opencode/skills/git-flow-review/SKILL.md | planned |
| `FR-gfr-changeset` | .claude/commands/git-flow-review.md (reuses /shepherd-review pipeline) | planned |
| `FR-gfr-ai-review` | .claude/commands/git-flow-review.md | planned |
| `FR-gfr-neutral-context` | .claude/commands/git-flow-review.md (existing context generation) | planned |
| `FR-gfr-blind-launch` | .claude/commands/git-flow-review.md (emits `gitFlow.reviewMode: "blind"` in the context; launcher unchanged) | planned |
| `FR-gfr-reveal` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | planned |
| `FR-gfr-workshop` | engineering/apps/macos/Sources/WorkshopFeature/; engineering/apps/macos/Sources/AppFeature/AppFeature.swift | planned |
| `FR-gfr-combined-output` | engineering/apps/macos/Sources/Dependencies/SessionClient.swift; engineering/apps/macos/Sources/AppFeature/AppFeature.swift | planned |
| `FR-gfr-post-confirm` | .claude/commands/git-flow-review.md | planned |
| `FR-gfr-post-back` | .claude/commands/git-flow-review.md | planned |
| `FR-gfr-post-failure` | .claude/commands/git-flow-review.md | planned |
| `NFR-gfr-mac-scope` | (structural: only macOS variants exist) | planned |
| `NFR-gfr-no-new-deps` | engineering/apps/macos/Package.swift (no change) | planned |
| `NFR-gfr-single-reviewer` | (structural) | planned |
| `FR-gfrm-blind-mode` | engineering/apps/macos/Sources/SharedModels/ReviewContext.swift; engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/ReviewContextFeature/ | planned || `FR-gfrm-reveal` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | planned |
| `FR-gfrm-workshop-view` | engineering/apps/macos/Sources/WorkshopFeature/ | planned |
| `FR-gfrm-review-output` | engineering/apps/macos/Sources/Dependencies/SessionClient.swift | planned |
