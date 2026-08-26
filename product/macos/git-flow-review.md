# Git Flow Review — macOS Platform

> macOS-specific requirements for `git-flow-review`. See `../git-flow-review.md` for shared requirements.

## Overview

The macOS variant adds the review-tool surfaces of the git flow review loop: a blind review mode for the reviewer's first pass, the reveal of the AI findings after that pass, the workshop for reconciling the two feedback sets, and the structured combined output the command posts back to GitHub. The command-level workflow (source selection, AI review, posting) is unchanged from the shared spec and is realized by a new command file alongside `/shepherd-review`, reusing the existing launcher and session machinery.

## Shared Requirements — Applicability on macOS

- `FR-gfr-source-selection`, `FR-gfr-eligibility`, `FR-gfr-changeset`, `FR-gfr-ai-review`, `FR-gfr-neutral-context` — realized by the command file and existing `/shepherd-review` changeset machinery; no app changes.
- `FR-gfr-blind-launch` — realized by `FR-gfrm-blind-mode` plus a launcher extension (see the macOS engineering spec).
- `FR-gfr-reveal` — realized by `FR-gfrm-reveal`.
- `FR-gfr-workshop` — realized by `FR-gfrm-workshop-view`.
- `FR-gfr-combined-output` — realized by `FR-gfrm-review-output`.
- `FR-gfr-post-confirm`, `FR-gfr-post-back`, `FR-gfr-post-failure` — command-side; no app changes.
- `NFR-gfr-no-new-deps`, `NFR-gfr-single-reviewer` — apply unchanged.
- `NFR-gfr-mac-scope` — satisfied by this variant being the only platform variant.

## macOS-Specific Functional Requirements

#### `FR-gfrm-blind-mode` — Blind review mode in the review window
When a session payload is marked as a blind git-flow review, the review window loads and behaves as a normal multi-file review with one exception: every review-feedback entry from the session context is loaded but held hidden. Neutral context sections display normally, and the reviewer can add inline comments on any file and line as usual. The window displays a persistent, visible indicator that AI feedback is hidden for the blind pass, so the reviewer always knows which mode they are in and that more feedback exists than they can see.

#### `FR-gfrm-reveal` — Reveal after the first pass
When the reviewer completes their first pass (the existing Done action) in a blind git-flow session, the review window does not close. The AI findings are revealed — visible alongside the reviewer's own comments — and the reviewer moves into the workshop. The reveal is a one-way transition within the same session; there is no way to re-hide the AI findings once revealed.

#### `FR-gfrm-workshop-view` — Workshop the combined feedback
The workshop presents every feedback item in one list: each AI finding and each reviewer comment, each with its file and line anchor. Each item can be accepted as-is, edited (its text changed in place), or rejected (excluded from the final review). AI findings start in an undecided state and must be explicitly accepted or rejected; reviewer comments start accepted. Selecting an item navigates to its file tab and anchors the view on its line, so the reviewer can judge each item against the code. Rejecting an item updates the list immediately; the item remains visible in the list while the workshop is open, marked rejected, and is excluded from the output.

#### `FR-gfrm-review-output` — Structured combined output
When the reviewer finishes the workshop, the review window writes the combined review to the session directory as a structured document (machine-readable, alongside — not replacing — the existing prompt output): one entry per accepted item with its file, line, and final text, plus the overall summary. The window then closes normally, and the command-side flow resumes from that document.

## Acceptance Criteria (macOS-specific)

- [ ] **Blind indicator shown** `AC-gfrm-blind-indicator`: Given a blind git-flow session is open, then the review window shows a persistent indicator that AI feedback is hidden, neutral context is visible, and commenting works normally.
- [ ] **Reveal on Done** `AC-gfrm-reveal-on-done`: Given the reviewer presses Done in a blind git-flow session, then the AI findings become visible in the same session and the workshop is entered, rather than the window closing.
- [ ] **Workshop edit applies** `AC-gfrm-workshop-edit`: Given the reviewer edits an item's text in the workshop, then the item shows the edited text immediately and the combined output carries the edited text.
- [ ] **Undecided AI finding excluded** `AC-gfrm-undecided-excluded`: Given an AI finding is neither accepted nor rejected when the workshop finishes, then it is excluded from the combined output.
- [ ] **Output shape** `AC-gfrm-output-structure`: The combined output file contains one entry per accepted item with file, line, and final text, plus the overall summary.

## Open Questions

1. **Workshop placement.** The workshop is specified as a mode of the review window (same session, list presented over/alongside the file tabs) rather than a separate window, so line navigation stays one click away. Whether it renders as a sheet over the code area or a third pane is a design decision in `design/macos/git-flow-review.md`.

## Dependencies

- Shared git flow review spec (`../git-flow-review.md`).
- The existing multi-file session, context handoff (`FR-srm-context-handoff`), and inline commenting machinery from Shepherd Review.
