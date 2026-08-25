---
product-hash: 63dd74d1198483ed4727495a3fa24821f6daf12ccd9ef3aff043e02d33b25d18
product-slugs: [AC-pb-npub-list, AC-pb-open-pr, AC-pb-repo-list, AC-pb-watchlist-invalid, AC-pb-watchlist-persists, FR-pb-npub-list, FR-pb-open-pr, FR-pb-repo-list, FR-pb-watchlist-manage, NFR-pb-fetch-window]
---
# PR Browse — iOS Design

> Based on requirements in `../../product/pr-browse.md`
> The macOS presentation is specified in `../../design/macos/pr-browse.md`; this spec covers the iOS port. No iOS product supplement exists — the shared requirements apply unchanged on iOS (a selected PR opens through the existing iOS PR review path, `FR-sri-pr-open-patches`).

## What We're Designing

The iOS presentation of the Browse PRs sheet: watchlist management, repo PR lists, npub-tagged PR lists, and routing a selected PR into the existing in-app review flow. The behavior is already specified in the shared product spec; only the presentation is new here. Key constraint: the sheet must reflow between iPhone (compact, single column, tap-driven) and iPad (expanded, two columns like macOS), mirroring the app's existing `NavigationSplitView` adaptivity.

## Screen Inventory

| Surface | Compact (iPhone) | Expanded (iPad) |
|---|---|---|
| **Empty State** | "Review a patch" screen gains a "Browse PRs" button under "Open Patch". | Same. |
| **Browse PRs Sheet** | Full-height modal sheet, single scrolling column: npub lookup, watchlist, PR list. | Modal form sheet, two columns: watchlist left, PR list right (macOS layout). |

## Screen Definitions

### Empty State — Browse PRs button

The existing empty state ("Review a patch") gains a secondary "Browse PRs" button directly below "Open Patch", labeled with the same prominence class the platform gives secondary actions (bordered, not bordered-prominent). Tapping it presents the Browse PRs sheet.

- **Entry points**: App launch with no files loaded (the only iOS entry state).
- **Requirements satisfied**: `FR-pb-watchlist-manage`, `FR-pb-repo-list`, `FR-pb-npub-list` (surface entry).

### Browse PRs Sheet

One surface, both modes, presented as a sheet. Content and ordering per mode are identical to macOS (`../../design/macos/pr-browse.md`); only the arrangement differs.

- **Entry points**: "Browse PRs" button on the empty state.
- **Layout — compact (iPhone)**: a single vertical stack, top to bottom: npub lookup field + Find button; watched-repos list (each row shows the coordinate's `d` tail, swipe-to-delete removes it, tap selects it); add field + Add button. When a lookup is active, the PR list replaces the watched-repos list in the same region, and a back affordance in the sheet's navigation bar returns to the watchlist.
- **Layout — expanded (iPad)**: the macOS two-column layout — watchlist left, npub field + PR list right — inside a form sheet.
- **Components**:
  - **PR row**: subject (medium weight, single line, truncated), second line author `npub1…` short form (first 10 chars) or `—`, trailing relative age ("2d"). Identical to macOS. A single tap opens the PR (there is no keyboard selection on iPhone).
  - **Watchlist row**: `d` tail as the label, tap to select, swipe-to-delete to remove (compact) or trailing ✕ (expanded).
  - **Add field**: placeholder `30617:<pubkey>:<d>`, monospaced caption font, Add button. Inline red error below on invalid or duplicate input.
  - **Npub field**: placeholder `npub1… or hex pubkey`, Find button. Inline red error below on invalid input.
  - **Refresh**: toolbar or trailing button, disabled when no lookup is active or a fetch is in flight.
- **States**: identical to macOS — idle ("Select a watched repo or enter an npub."), loading spinner, populated, empty ("No pull requests found."), no-relays ("No relays reachable."), inline input errors.
- **Actions**: add/remove watchlist entries (`FR-pb-watchlist-manage`); select a repo (`FR-pb-repo-list`); npub lookup (`FR-pb-npub-list`); refresh; open a PR (`FR-pb-open-pr`).
- **Requirements satisfied**: `FR-pb-watchlist-manage`, `FR-pb-repo-list`, `FR-pb-npub-list`, `FR-pb-open-pr`, `NFR-pb-fetch-window`.

## Interaction Flows

### Open a PR from browse (iPhone)

A reviewer wants to triage incoming PRs without copying event ids.

1. User taps "Browse PRs" on the empty state → the Browse PRs sheet presents.
2. User taps a watched repo → the sheet shows the repo's PR list, fetching for the 8s window (`NFR-pb-fetch-window`).
3. User taps a PR row → the Open Patch flow begins with the PR's event id — identical surface, loading, and errors to pasting the id by hand (`FR-pb-open-pr`). On a successful load the review layout replaces the empty state and the sheet with it; if the load fails the sheet remains open and its lookup resets on dismissal (via `onDismiss`), so the next Browse PRs tap starts fresh.

## Responsive Behavior

The sheet selects its layout from the horizontal size class: compact uses the single-column stack with a watchlist→list navigation push; expanded uses the two-column form sheet. Both use the same underlying feature state; only the arrangement differs.

## Accessibility

- PR rows, watchlist rows, and action buttons carry accessibility labels (subject plus age on PR rows; full coordinate on watchlist rows).
- The sheet's navigation title is "Browse Pull Requests"; the active-lookup header uses the same text as macOS ("Pull requests — <tail>" / "Pull requests tagged <short>").
- Delete (swipe or ✕) exposes an accessibility action "Stop watching <coordinate>".
- Dynamic Type: rows use default text styles so they scale; the coordinate and npub fields stay monospaced caption but wrap rather than truncate horizontally.
