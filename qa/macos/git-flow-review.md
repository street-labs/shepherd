---
product-hash: 03fccb4b7bd677b4b7a8742717e7d39cadee5c7107fec9157948f6e33138c556
product-slugs: [AC-gfr-ai-findings-anchored, AC-gfr-blind-no-leak, AC-gfr-confirm-before-post, AC-gfr-eligible-list, AC-gfr-explicit-status, AC-gfr-post-back-lines, AC-gfr-post-failure-reported, AC-gfr-workshop-resolutions, FR-gfr-ai-review, FR-gfr-blind-launch, FR-gfr-changeset, FR-gfr-combined-output, FR-gfr-eligibility, FR-gfr-neutral-context, FR-gfr-post-back, FR-gfr-post-confirm, FR-gfr-post-failure, FR-gfr-reveal, FR-gfr-source-selection, FR-gfr-workshop, NFR-gfr-mac-scope, NFR-gfr-no-new-deps, NFR-gfr-single-reviewer, AC-gfrm-blind-indicator, AC-gfrm-output-structure, AC-gfrm-reveal-on-done, AC-gfrm-undecided-excluded, AC-gfrm-workshop-edit, FR-gfrm-blind-mode, FR-gfrm-reveal, FR-gfrm-review-output, FR-gfrm-workshop-view, NFR-gfr-single-voice]
---

# Git Flow Review — macOS Test Plan

> Based on requirements in `../../product/git-flow-review.md`
> Based on design in `../../design/macos/git-flow-review.md`
> Based on technical spec in `../../engineering/macos/git-flow-review.md`
> See also `../../product/macos/git-flow-review.md` for macOS-specific requirements.

## What We're Testing

The git flow review loop end to end: command-side source selection and eligibility, the anchored AI review handoff, blind-mode suppression in the review window, the reveal-into-workshop transition, workshop resolutions, the combined output file, and the confirmation-gated post back to GitHub. App-side tests run against the macOS package (`swift test` in `engineering/apps/macos/`); command- and posting-side tests are manual against a scratch GitHub repository. Risk areas: blind-mode leakage (any surface rendering feedback text early), anchor mismatches between local files and PR diff lines, and partial posting failures.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-gfr-eligible-list` | `TC-gfr-eligible-list` | Not started |
| `AC-gfr-explicit-status` | `TC-gfr-explicit-draft-warning` | Not started |
| `AC-gfr-ai-findings-anchored` | `TC-gfr-findings-anchored`, `TC-gfr-unresolvable-finding-dropped` | Not started |
| `AC-gfr-blind-no-leak` | `TC-gfrm-blind-suppression`, `TC-gfrm-blind-leak-search` | Not started |
| `AC-gfrm-blind-indicator` | `TC-gfrm-blind-badge` | Not started |
| `AC-gfrm-reveal-on-done` | `TC-gfrm-reveal-transition` | Not started |
| `AC-gfr-workshop-resolutions` | `TC-gfrm-workshop-resolutions`, `TC-gfrm-undecided-excluded` | Not started |
| `AC-gfrm-workshop-edit` | `TC-gfrm-workshop-edit` | Not started |
| `AC-gfrm-output-structure` | `TC-gfrm-output-shape` | Not started |
| `AC-gfr-confirm-before-post` | `TC-gfr-confirm-gate`, `TC-gfr-cancel-no-post` | Not started |
| `AC-gfr-post-back-lines` | `TC-gfr-post-back-lines` | Not started |
| `AC-gfr-post-failure-reported` | `TC-gfr-post-partial-failure` | Not started |

## Test Cases

### Command-Side (manual, scratch repo)

These cases run against a scratch GitHub repository with controllable PRs.

#### Eligible list shows only open non-draft PRs `TC-gfr-eligible-list`
- **Type**: Manual
- **Covers**: `AC-gfr-eligible-list`, `FR-gfr-eligibility`, `FR-gfr-source-selection`
- **Steps**: Create one open, one draft, and one merged PR in the scratch repo. Invoke `/git-flow-review` with no argument.
- **Expected**: The offered list contains exactly the open non-draft PR, with number, title, and author; draft and merged are absent.

#### Draft PR referenced explicitly is warned `TC-gfr-explicit-draft-warning`
- **Type**: Manual
- **Covers**: `AC-gfr-explicit-status`, `FR-gfr-eligibility`
- **Steps**: Invoke `/git-flow-review <draft-PR-number>`.
- **Expected**: The command states the PR is a draft before opening the review; declining stops the command with no review window.

#### AI findings anchored to real lines `TC-gfr-findings-anchored`
- **Type**: Manual
- **Covers**: `AC-gfr-ai-findings-anchored`, `FR-gfr-ai-review`
- **Steps**: Run the flow on a PR with multi-file changes. Inspect the generated session `reviewContext` payload.
- **Expected**: Every finding has a file (absolute path matching a loaded tab) and a valid 1-based line in that file; exactly one summary string is present.

#### Unresolvable finding dropped `TC-gfr-unresolvable-finding-dropped`
- **Type**: Manual
- **Covers**: `FR-gfr-ai-review`
- **Steps**: Hand-edit the emitted context to include a finding with a bogus line/file, and run the launcher directly with it.
- **Expected**: The command's validation (or app load) drops the finding; a note appears in the conversation; the rest of the session loads.

### App-Side (macOS package tests + manual)

#### Blind session suppresses feedback `TC-gfrm-blind-suppression`
- **Type**: Unit (AppFeature reducer)
- **Covers**: `AC-gfr-blind-no-leak`, `FR-gfrm-blind-mode`
- **Steps**: Load a session fixture with `gitFlow.reviewMode == "blind"` and findings present; assert state.
- **Expected**: Phase is `.blind`; findings are held in state but no rendered section exposes finding text; neutral context renders.

#### No finding text anywhere in blind UI `TC-gfrm-blind-leak-search`
- **Type**: Manual
- **Covers**: `AC-gfr-blind-no-leak`, `FR-gfrm-blind-mode`
- **Steps**: Run the full flow on a real PR; during the blind pass, inspect every tab, the inspector, tooltips, and window title.
- **Expected**: No AI finding text, nor paraphrases of it, is visible; the blind badge is visible in all tabs.

#### Blind badge present `TC-gfrm-blind-badge`
- **Type**: Manual
- **Covers**: `AC-gfrm-blind-indicator`, `FR-gfrm-blind-mode`
- **Steps**: Same session as above.
- **Expected**: The badge reads that AI feedback is hidden; a normal (non-git-flow) session shows no badge.

#### Done reveals instead of closing `TC-gfrm-reveal-transition`
- **Type**: Unit (AppFeature reducer) + Manual
- **Covers**: `AC-gfrm-reveal-on-done`, `FR-gfrm-reveal`
- **Steps**: In a `.blind` session, send the Done action.
- **Expected**: Phase becomes `.workshop` with items built from reviewer comments (accepted, provenance yours) and findings (undecided, provenance ai); the window does not close; findings become visible.

#### Resolutions honored `TC-gfrm-workshop-resolutions`
- **Type**: Unit (WorkshopFeature/AppFeature reducer)
- **Covers**: `AC-gfr-workshop-resolutions`, `FR-gfrm-workshop-view`
- **Steps**: Build a workshop state with 2 AI findings and 1 reviewer comment. Reject one finding, edit the other, leave the comment accepted; finish.
- **Expected**: Output contains the edited finding (edited text) and the comment; the rejected finding is absent.

#### Undecided finding excluded `TC-gfrm-undecided-excluded`
- **Type**: Unit
- **Covers**: `AC-gfrm-undecided-excluded`, `FR-gfrm-workshop-view`
- **Steps**: Finish a workshop with one AI finding still undecided.
- **Expected**: That finding is absent from the output file.

#### Output file shape `TC-gfrm-output-shape`
- **Type**: Unit (SessionClient)
- **Covers**: `AC-gfrm-output-structure`, `FR-gfrm-review-output`
- **Steps**: Write a combined review via `SessionClient` and decode the file.
- **Expected**: `review-output.json` decodes to `{ summary, comments: [{file, line, text, provenance}] }` with accepted items only; `prompt-output.md` is also written (existing behavior preserved).

### Posting-Side (manual, scratch repo)

#### Confirmation gate `TC-gfr-confirm-gate`
- **Type**: Manual
- **Covers**: `AC-gfr-confirm-before-post`, `FR-gfr-post-confirm`
- **Steps**: Complete a workshop; when the command shows the final review, confirm.
- **Expected**: The shown review lists each inline comment with file+line and the summary; nothing is posted before confirmation.

#### Cancel posts nothing `TC-gfr-cancel-no-post`
- **Type**: Manual
- **Covers**: `AC-gfr-confirm-before-post`
- **Steps**: Same as above, but decline at confirmation.
- **Expected**: No comments or review appear on the PR.

#### Posted review lands on the right lines `TC-gfr-post-back-lines`
- **Type**: Manual
- **Covers**: `AC-gfr-post-back-lines`, `FR-gfr-post-back`
- **Steps**: Confirm posting on a PR with 3 accepted items across 2 files.
- **Expected**: The PR shows 3 inline comments, each on the correct file and line of the PR diff, and exactly one review comment carrying the summary; no provenance labels appear.

#### Partial posting failure reported `TC-gfr-post-partial-failure`
- **Type**: Manual
- **Covers**: `AC-gfr-post-failure-reported`, `FR-gfr-post-failure`
- **Steps**: Before confirming, force one item's anchor stale (rebase the PR so one reviewed line moved) or revoke `gh` auth mid-flow.
- **Expected**: The command reports which items posted and which did not, does not claim success, and leaves the unposted set retryable.
