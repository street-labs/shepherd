---
product-hash: 06c62257c709f69b05f1b8b75c2e47b4d769ce86d7236f06383895fef6bbadd8
product-slugs: [AC-gfr-ai-findings-anchored, AC-gfr-blind-no-leak, AC-gfr-confirm-before-post, AC-gfr-eligible-list, AC-gfr-explicit-status, AC-gfr-post-back-lines, AC-gfr-post-failure-reported, AC-gfr-workshop-resolutions, FR-gfr-ai-review, FR-gfr-blind-launch, FR-gfr-changeset, FR-gfr-combined-output, FR-gfr-eligibility, FR-gfr-neutral-context, FR-gfr-post-back, FR-gfr-post-confirm, FR-gfr-post-failure, FR-gfr-reveal, FR-gfr-source-selection, FR-gfr-workshop, NFR-gfr-mac-scope, NFR-gfr-no-new-deps, NFR-gfr-single-reviewer, AC-gfrm-blind-indicator, AC-gfrm-output-structure, AC-gfrm-reveal-on-done, AC-gfrm-undecided-excluded, AC-gfrm-workshop-edit, FR-gfrm-blind-mode, FR-gfrm-reveal, FR-gfrm-review-output, FR-gfrm-workshop-view]
---

# Git Flow Review — macOS Design Spec

> Based on requirements in `../../product/git-flow-review.md`
> See also `../../product/macos/git-flow-review.md` for macOS-specific requirements.

## What We're Designing

The macOS review-tool surfaces of the git flow review loop: a blind first pass in the existing multi-file review window, a one-way reveal of the AI findings, and a workshop mode where the reviewer reconciles the combined feedback set before it is exported for posting to GitHub. The design reuses the existing review window, tabs, gutter comments, and inspector context sections; the new surfaces are a blind-mode indicator, the reveal transition, and the workshop list. Command-side UX (PR selection, confirmation, posting) lives in the agent conversation and is out of scope here.

## Screen Inventory

1. **Review Window — Blind Mode** (existing window, new mode)
2. **Workshop Mode** (a mode of the same window, entered on Done)

## Screen Definitions

### Review Window — Blind Mode

The reviewer reviews the diff and records their own comments, with AI feedback hidden but known to exist.

- **Entry points**: Launched by `/git-flow-review` via the existing launcher; session payload marked as a blind git-flow review.
- **Layout**: Identical to the existing multi-file review window (file browser, code viewer with gutter, inspector) with two additions:
  - A **blind-mode indicator** — a compact badge in the toolbar ("AI feedback hidden — your pass first") with a small eye-slash icon. It is visible whenever blind mode is active, in every tab, and cannot be dismissed.
  - The inspector shows neutral context sections only; review-feedback sections from the session payload are simply not rendered (no collapsed placeholders, no "hidden" teasers that hint at content).
- **Components**:
  - Blind-mode badge: static informational badge; no actions. Tooltip: "AI review feedback is held back until you finish your pass. Neutral context is shown."
- **States**: Identical to the standard review window (loading, populated, error). The only new state is the badge itself.
- **Actions**: All existing actions (comment on line, edit comment, navigate tabs, cancel). Cancel exits without revealing. **Done** does not close the window — it triggers the reveal (next screen).
- **Requirements satisfied**: `FR-gfr-blind-launch`, `FR-gfr-neutral-context`, `FR-gfrm-blind-mode`, `AC-gfrm-blind-indicator`, `AC-gfr-blind-no-leak`

### Workshop Mode

The reviewer reconciles every feedback item — their own comments and the now-revealed AI findings — into the final review.

- **Entry points**: Pressing **Done** in a blind git-flow session. The reveal happens as part of this transition: AI findings appear in the workshop list (and as distinct inline gutter markers on their lines), and the window enters workshop mode.
- **Layout**: The file tabs and code viewer remain usable on the left; the workshop list replaces the inspector's context area on the right (the inspector pane is where the reviewer already reads context, so it is the natural home for the reconciliation list).
- **Components**:
  - **Workshop list**: One row per feedback item, ordered by file (tab order) then line number. Each row shows: provenance badge ("Yours" / "AI"), file name + line number, and the item text (multi-line, scrollable, read-only until edited).
    - Row states: **Accepted** (checkmark, included), **Undecided** (AI items only — dot icon, excluded until decided), **Rejected** (strikethrough + dimmed, excluded), **Editing** (text field with Save/Cancel).
    - Row actions: Accept / Reject toggle buttons; Edit (opens inline text editing); clicking anywhere else on the row navigates the code viewer to that file tab and line.
  - **Summary field**: At the top of the list, the overall summary text (from the AI review), editable like any item; it is always included and cannot be rejected, only edited.
  - **Finish button**: "Finish & Export" in the toolbar where Done was. Writes the combined output and closes the window.
- **States**:
  - Populated (normal): list of items as above.
  - Empty reviewer pass: list contains only AI findings (all undecided) plus the summary; works identically.
  - Empty everything: not reachable — the session is only launched when the AI produced a review; if the AI produced zero findings, the command launches a normal (non-blind) review instead.
- **Actions**: Accept/reject/edit per item; navigate-to-line; finish & export; cancel (exits without writing output).
- **Requirements satisfied**: `FR-gfr-reveal`, `FR-gfr-workshop`, `FR-gfrm-reveal`, `FR-gfrm-workshop-view`, `FR-gfrm-review-output`, `AC-gfrm-reveal-on-done`, `AC-gfrm-workshop-edit`, `AC-gfrm-undecided-excluded`, `AC-gfrm-output-structure`, `AC-gfr-workshop-resolutions`

## Interaction Flows

### Full loop (reviewer's journey)

A reviewer asked to review an open PR in their repository.

1. Reviewer invokes `/git-flow-review`, picks a PR from the offered list → agent computes the change set, runs its own review, launches the review window in blind mode.
2. Reviewer sees the blind badge, reads neutral context, reviews each tab, adds inline comments → presses **Done**.
3. Window stays open; AI findings are revealed in the workshop list; reviewer's own comments appear with "Yours" badges.
4. Reviewer clicks rows to jump to lines, judges each AI finding, accepts/edits/rejects each; edits their own comments where the AI's take changed their mind; edits the summary.
5. Reviewer presses **Finish & Export** → combined output is written to the session directory, window closes.
6. In the conversation, the agent shows the final review for confirmation and, on confirm, posts it to the PR (command-side; not part of this design).

### Early exit

A reviewer who wants out mid-loop.

1. Reviewer presses Cancel during the blind pass or workshop → window closes, nothing is revealed or written, the agent reports the aborted review.

## Component Specs

### Blind-Mode Badge

A toolbar badge communicating that AI feedback exists but is withheld.

- **Variants**: Active (blind pass in progress); absent otherwise.
- **Props/Inputs**: Session blind-mode flag.
- **States**: Static; not interactive.
- **Behavior**: Shown from launch until the reveal.

### Workshop Row

One feedback item under reconciliation.

- **Variants**: Yours / AI provenance; accepted / undecided / rejected / editing state.
- **Props/Inputs**: Item text, file, line, provenance, current resolution.
- **States**: As listed above; AI rows start undecided, reviewer rows start accepted.
- **Behavior**: Row click navigates code viewer; accept/reject toggle updates the output set immediately; edit opens inline editing with Save/Cancel.

## Responsive Behavior

The workshop list lives in the existing inspector pane, which already adapts to window width. No new responsive behavior; the minimum window size is unchanged.

## Accessibility

- The blind badge is announced to VoiceOver as static text on window focus ("AI feedback hidden").
- Workshop rows are keyboard-navigable (arrow keys move selection, Enter activates navigation, A/R/E for accept/reject/edit), with visible focus.
- State changes (accepted/rejected) are conveyed by more than color alone: icon and strikethrough.
- The provenance badge has accessible text ("Your comment" / "AI finding"), not just color.
