# PR Browse — macOS Design

> Based on requirements in `../../product/pr-browse.md`

## Overview

A single Browse surface hosting the watchlist, both browse lists, and PR opening. Implements `FR-pb-default-state`: when no files are loaded, this surface is the app's default state — shown inline in the main window, not as a sheet. The empty state's existing entry points ("Open Files…", "Paste from Clipboard", "Open Patch or PR…", ⌘⇧P) live in a button row above the browse panes; dragging files onto the window still loads them.

## Entry point

The browse surface is the empty state itself (`FR-pb-default-state`). Launching with no files loaded lands here directly. A header row of buttons sits above the panes:

```
[ Open Files… ]   [ Paste from Clipboard ]   [ Open Patch or PR… ]
┌────────────────────────────────────────────────────┐
│ [Watchlist sidebar]      │ [PR list]               │
```

Once any file is loaded the surface is replaced by the review layout; there is no browse entry point while reviewing (v1).

## Layout (inline in the main window)

```
┌ Browse Pull Requests ──────────────────────────────┐
│ [Watchlist sidebar]      │ [PR list]               │

- **Left column — watchlist.** List of added coordinates, each row showing the repo's human tail (the `d` identifier) with the full coordinate as its help tooltip; a trailing ✕ removes it. Below the list, a text field + "Add" button. Invalid input shows an inline red message under the field; nothing is added.
- **Right column — PR list.** The npub field and "Find" button run an npub-tagged lookup (`FR-pb-npub-list`); its results replace the list and the header shows "PRs tagged <npub>" with a clear button. Selecting a watchlist row runs the repo lookup (`FR-pb-repo-list`); the header shows the coordinate's tail.

## PR rows

Each row: subject (bold, single line, truncated), second line author as `npub1…` short form (first 10 chars) or `—` when unknown, trailing relative age ("2d"). Newest first. Row height 44. Double-click (or Enter on keyboard selection) opens the PR.

## States

- **idle** — no lookup run yet: PR list area shows "Select a repo or enter an npub."
- **loading** — spinner in the list area while a fetch is in flight (repo or npub).
- **populated** — rows per above; "Refresh" re-runs the active lookup.
- **empty** — "No pull requests found." after the wait window.
- **no relays** — if no relay is reachable, the same style of message the Open Patch dialog uses: "No relays reachable."
- **invalid npub** — inline red message under the npub field.

## Opening a PR

Selecting a PR routes the PR's event id through the existing Open Patch dialog flow, auto-fetching — identical surface and errors to pasting the id by hand (`FR-pb-open-pr`). The browse state itself persists beneath the load (loading replaces the empty state as before). The unsaved-feedback confirmation (replace current review) behavior is identical to the deeplink path.
