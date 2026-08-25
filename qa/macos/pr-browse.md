# PR Browse — macOS Test Plan

> Covers requirements in `../../product/pr-browse.md` (design: `../../design/macos/pr-browse.md`, engineering: `../../engineering/macos/pr-browse.md`)

## What We're Testing

The Browse PRs surface (the app's default empty state): watchlist management and persistence, repo PR listing, npub-tagged PR listing, and routing a selected PR into the existing in-app review flow.

## Coverage Matrix

| Requirement | Test Cases |
|---|---|
| `FR-pb-default-state` | `TC-pb-default-state` |
| `FR-pb-watchlist-manage` | `TC-pb-watchlist-add`, `TC-pb-watchlist-invalid`, `TC-pb-watchlist-remove`, `TC-pb-watchlist-duplicate`, `TC-pb-watchlist-persist` |
| `FR-pb-repo-list` | `TC-pb-repo-list`, `TC-pb-repo-list-timeout` |
| `FR-pb-npub-list` | `TC-pb-npub-list`, `TC-pb-npub-invalid` |
| `FR-pb-open-pr` | `TC-pb-open-pr` |
| `NFR-pb-fetch-window` | `TC-pb-repo-list-timeout` |

## Test Cases

### Default state

#### `TC-pb-default-state` — Browse is the default empty state
Given the app launches with no files loaded, then the main window shows the browse surface inline (watchlist + PR list) with the Open Files / Paste / Open Patch or PR buttons above it; loading any file replaces it with the review layout. (Unit test asserts initial state; manual confirmation of the layout.)

### Watchlist

#### `TC-pb-watchlist-add` — Valid coordinate is added and persisted
Given the Browse PRs sheet open, when the user enters `30617:<64-hex-pubkey>:shepherd` and clicks Add, then the coordinate appears in the list (displayed by its `d` tail) and is present after relaunch.

#### `TC-pb-watchlist-invalid` — Malformed coordinate rejected
When the user enters `not-a-coordinate` (or a coordinate with a non-hex pubkey, or kind other than 30617), then an inline error is shown and the watchlist is unchanged.

#### `TC-pb-watchlist-remove` — Remove drops the entry
Given a watched repo, when its ✕ is clicked, then the entry disappears and stays gone after relaunch.

#### `TC-pb-watchlist-duplicate` — Duplicate rejected
Given a coordinate already watched, when it is entered again, then an error is shown and no duplicate is created.

#### `TC-pb-watchlist-persist` — Persistence round-trip
Given an overridden `WatchlistClient`, when the feature loads, then the persisted array is presented; when mutated, then save is called with the new array. (Unit test.)

### Repo PR list

#### `TC-pb-repo-list` — Repo lookup lists PRs newest first
Given the relay client yields three kind `1618` events with the repo's `a` tag (out of order `created_at`, one duplicate id), when the repo is selected, then the list shows two unique PRs newest first with subject, author, and age. (Unit test with a stubbed `RelayClient` stream.)

#### `TC-pb-repo-list-timeout` — Empty after wait window
Given a relay client whose stream yields nothing, when a lookup runs, then after the 8s window the state is "No pull requests found." and no spinner remains.

### Npub list

#### `TC-pb-npub-list` — Npub lookup lists tagged PRs
Given a valid `npub1…` (and separately a 64-char hex), when Find is clicked, then kind `1618` events with that `p` tag are listed newest first.

#### `TC-pb-npub-invalid` — Invalid npub rejected
When the user enters `npub1xyz` (fails bech32) or a 40-char string, then an inline error is shown and no lookup starts.

### Opening

#### `TC-pb-open-pr` — Selecting a PR routes into the review flow
Given a listed PR, when it is opened, then the Open Patch flow begins with the PR's event id (`.delegate(.openPR(id))` observed; `presentOpenPatch` invoked) and the review surface loads. (Unit test at the `PRBrowseFeature`/`AppFeature` boundary plus manual confirmation that the review surface loads.)
