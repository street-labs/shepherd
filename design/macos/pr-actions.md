---
product-hash: 155691b3451808cebd8df33b45ff1932bf1520bf74c4026c77b8e5a519566195
product-slugs: [AC-pa-approval-tip, AC-pa-capabilities, AC-pa-comment-publishes, AC-pa-line-comment, AC-pa-live-replies, AC-pa-merge-gate, AC-pa-merge-publishes, AC-pa-stale, FR-pa-capabilities, FR-pa-comment, FR-pa-merge, FR-pa-review, FR-pa-threads, NFR-pa-nostr-only, NFR-pa-publish-window]
---

# PR Actions — macOS Design

> Based on requirements in `../../product/pr-actions.md`
> Lives inside the existing PR review layout (`design/macos/shepherd-review.md`); no new window.

## Overview

Commenting, review verdicts, live replies, and merge all hang off the PR review surface the app already shows when a `1618` is open. Implements `FR-pa-comment`, `FR-pa-review`, `FR-pa-threads`, `FR-pa-merge`, `FR-pa-capabilities`.

## Screen changes (review layout)

- **Toolbar verdict controls.** The existing toolbar gains an Approve and a Request-changes control, enabled per `FR-pa-capabilities` (no identity → disabled with tooltip "Unlock identity to review"; not a maintainer → no merge control at all). Approve opens a small sheet: markdown summary (optional), the tip commit the verdict will bind to (read-only, from the PR's newest `1618`/`1619` `c` tag), and a Submit button. Request-changes uses the same sheet with the rejection verdict preset.
- **PR-level comment.** The existing reply composer at the bottom of the thread publishes to Nostr on submit (`FR-pa-comment`); it already exists for patch threads — PR threads get the identical composer.
- **Line-attached comment.** Inline comment bubbles (existing `CommentFeature` surface) gain a "Post to PR" action alongside local-only annotate. Publishing attaches the file/line reference to the event per `FR-pa-comment`; the bubble shows a posted indicator (checkmark + relay count) or a retry affordance on failure.
- **Merge control.** Maintainers see a Merge button in the metadata section (next to status). Enabled only when the gate passes (`FR-pa-merge`: ≥1 current approval, 0 rejections, tip not stale). Hovering a disabled Merge shows the gate reason ("Needs 1 approval", "Rejected by <npub>", "Approval is stale — PR was updated"). Confirming opens a confirm dialog then publishes kind `1631`; the PR's status badge flips to merged on publish success.
- **Stale labels.** An approval whose `c` tag no longer matches the current tip shows a "stale" tag in the thread and does not count in the merge gate (`AC-pa-stale`).

## Live replies

`FR-pa-threads` reuses the existing live patch-thread subscription machinery: incoming replies appear in the thread in place, threaded under their parent, no manual refresh. New-reply arrival does not scroll-jack; a "N new replies" pill appears when scrolled up.

## States

- **publishing** — composer controls show an in-flight spinner; the comment renders locally immediately, marked "posting…", flipping to posted/failed (`NFR-pa-publish-window`).
- **failed publish** — the bubble shows a red retry control; content is retained locally for retry (`FR-pa-comment`).
- **no identity** — verdict and post controls disabled with explanatory tooltips; local annotation remains fully available.

## Accessibility

All new controls are keyboard reachable; verdict sheet is a standard focused sheet; badges are not color-only (text labels included).
