---
product-hash: 63dd74d1198483ed4727495a3fa24821f6daf12ccd9ef3aff043e02d33b25d18
product-slugs: [AC-pb-npub-list, AC-pb-open-pr, AC-pb-repo-list, AC-pb-watchlist-invalid, AC-pb-watchlist-persists, FR-pb-npub-list, FR-pb-open-pr, FR-pb-repo-list, FR-pb-watchlist-manage, NFR-pb-fetch-window]
---
# PR Browse — iOS Test Plan

> Based on requirements in `../../product/pr-browse.md`
> Based on design in `../../design/ios/pr-browse.md`
> Based on technical spec in `../../engineering/ios/pr-browse.md`

## What We're Testing

The iOS presentation of the Browse PRs sheet: entry from the empty state, adaptive layout across size classes, and routing a selected PR into the existing iOS review flow. Feature logic (watchlist persistence, lookups, dedupe, wait window) is shared with macOS and covered by `qa/macos/pr-browse.md` plus the shared `PRBrowseFeatureTests`; this plan covers the iOS surface.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-pb-watchlist-persists` | `TC-pbi-watchlist-persist` | Not started |
| `AC-pb-watchlist-invalid` | `TC-pbi-watchlist-invalid` | Not started |
| `AC-pb-repo-list` | `TC-pbi-repo-list`, `TC-pbi-layout-compact` | Not started |
| `AC-pb-npub-list` | `TC-pbi-npub-list` | Not started |
| `AC-pb-open-pr` | `TC-pbi-open-pr` | Not started |
| `NFR-pb-fetch-window` | `TC-pbi-repo-list` (bounded wait observed) | Not started |

## Test Cases

### Watchlist

#### Watchlist persists across relaunch `TC-pbi-watchlist-persist`
- **Type**: Manual
- **Covers**: `AC-pb-watchlist-persists`, `FR-pb-watchlist-manage`
- **Preconditions**: App on the empty state.
- **Steps**:
  1. Tap "Browse PRs", add `30617:<64-hex-pubkey>:shepherd`.
  2. Dismiss the sheet, kill the app, relaunch.
  3. Tap "Browse PRs" again.
- **Expected Result**: The coordinate is still in the watchlist, shown by its `d` tail.

#### Malformed coordinate rejected `TC-pbi-watchlist-invalid`
- **Type**: Manual
- **Covers**: `AC-pb-watchlist-invalid`, `FR-pb-watchlist-manage`
- **Steps**:
  1. In the Browse PRs sheet, enter `not-a-coordinate` (and separately a coordinate with a non-hex pubkey) and tap Add.
- **Expected Result**: An inline error is shown; the watchlist is unchanged. Entering a duplicate shows an error and no duplicate row.

### Lists and layout

#### Repo lookup lists PRs newest first, compact layout `TC-pbi-repo-list`
- **Type**: Manual
- **Covers**: `AC-pb-repo-list`, `FR-pb-repo-list`, `NFR-pb-fetch-window`
- **Preconditions**: A watched repo with kind `1618` PRs on the configured relays; iPhone or compact width.
- **Steps**:
  1. Tap the watched repo.
  2. Observe the fetch (spinner) and the resulting list.
- **Expected Result**: PRs listed newest first with subject, author short form, and age; the fetch resolves within the ~8s window even if empty; a back affordance returns to the watchlist.

#### Compact vs expanded layout `TC-pbi-layout-compact`
- **Type**: Manual
- **Covers**: `FR-pb-watchlist-manage`, `FR-pb-repo-list` (presentation)
- **Steps**:
  1. Open the Browse PRs sheet on iPhone (compact) — single column, swipe-to-delete a watchlist row.
  2. Open it on iPad or iPhone landscape with expanded width — two columns, trailing ✕ on watchlist rows.
- **Expected Result**: Compact shows the single-column stack with swipe-to-delete; expanded shows the two-column layout. Watchlist removal works in both.

#### Npub lookup lists tagged PRs `TC-pbi-npub-list`
- **Type**: Manual
- **Covers**: `AC-pb-npub-list`, `FR-pb-npub-list`
- **Steps**:
  1. Enter a valid `npub1…` (and separately a 64-char hex) and tap Find.
  2. Enter `npub1xyz` and tap Find.
- **Expected Result**: Valid input lists tagged PRs newest first; invalid input shows an inline error and starts no lookup.

### Opening

#### Selecting a PR routes into the review flow `TC-pbi-open-pr`
- **Type**: Manual
- **Covers**: `AC-pb-open-pr`, `FR-pb-open-pr`
- **Steps**:
  1. From either list, tap a PR row (single tap on compact).
- **Expected Result**: The existing Open Patch/PR review flow loads the PR — same surface, metadata, and diff presentation as opening the id by hand. On a successful load the review layout replaces the empty state and the sheet with it; on a failed load the sheet remains with its lookup reset on dismissal, so reopening Browse PRs starts fresh.

## Edge Cases & Error Scenarios

### No relays reachable
- **Trigger**: Airplane mode / no relay reachable during a lookup.
- **Expected behavior**: "No relays reachable." message in the list area, consistent with Open Patch.
- **Test case**: manual check during `TC-pbi-repo-list`.

### Empty result after wait window
- **Trigger**: Watched repo with no kind `1618` events on the user's relays.
- **Expected behavior**: "No pull requests found." after the window; no lingering spinner; Refresh re-runs the lookup.
- **Test case**: manual check during `TC-pbi-repo-list`.

## Regression Considerations

- The shared `PRBrowseView` changes (adaptive layout) affect macOS: the macOS sheet must keep its two-column layout and fixed sizing — run the macOS manual pass from `qa/macos/pr-browse.md` after the change.
- The empty state gains a second button: "Open Patch" must remain primary and the layout must not break at larger Dynamic Type sizes.
- Opening a PR must not disturb the existing Open Patch sheet and deeplink (`shepherd://pr/<ref>`) paths, since all three route through `presentOpenPatch`.
