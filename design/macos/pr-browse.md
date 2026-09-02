---
product-hash: ec7848c9428c28f1a2281961f54d73ff305683387b2f74d32573ac4c6ef8309b
product-slugs: [AC-pb-default-state, AC-pb-npub-list, AC-pb-open-pr, AC-pb-private-relays, AC-pb-repo-list, AC-pb-status-badge, AC-pb-watchlist-invalid, AC-pb-watchlist-persists, FR-pb-default-state, FR-pb-npub-list, FR-pb-open-pr, FR-pb-repo-list, FR-pb-status, FR-pb-watchlist-manage, FR-srm-patch-open-entry, NFR-pb-fetch-window]
---

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

Once any file is loaded the surface is replaced by the review layout; there is no browse entry point while reviewing (v1). A one-line hint under the button row — "or drop files anywhere" — keeps the drag-and-drop affordance discoverable (it works on the whole window).

## Layout (inline in the main window)

```
┌ Browse Pull Requests ──────────────────────────────┐
│ [Watchlist sidebar]      │ [PR list]               │
│ ┌────────────────────┐  │  Search by npub: [    ] │
│ │ repo coordinate ✕  │  │  [Find]                 │
│ │ 30617:abc…:shepherd│  │ ─────────────────────  │
│ └────────────────────┘  │  Subject            age │
│ [+ add field   Add]      │  Author (short npub)     │
│                          │  …                       │
│                          │  [Refresh]               │
└────────────────────────────────────────────────────┘
```

- **Left column — watchlist.** List of added coordinates, each row showing the repo's human tail (the `d` identifier) with the full coordinate as its help tooltip; a trailing ✕ removes it. Below the list, a text field + "Add" button. Invalid input shows an inline red message under the field; nothing is added.
- **Right column — PR list.** The npub field and "Find" button run an npub-tagged lookup (`FR-pb-npub-list`); its results replace the list and the header shows "PRs tagged <npub>" with a clear button. Selecting a watchlist row runs the repo lookup (`FR-pb-repo-list`); the header shows the coordinate's tail.

## PR rows

Each row: subject (bold, single line, truncated), second line author as `npub1…` short form (first 10 chars) or `—` when unknown, trailing relative age ("2d"), and a status badge between subject and age (`open` default, or `merged` / `closed` / `draft` from the newest NIP-34 status event — `FR-pb-status`). Badge is small caps, tinted: open gray, merged green, closed red, draft orange. Newest first. Row height 44. Double-click (or Enter on keyboard selection) opens the PR.

The list shows open PRs by default; a `Show all` toggle under the list header includes merged/closed/draft rows (`FR-pb-status`).

## States

- **idle** — no lookup run yet: PR list area shows "Select a repo or enter an npub."
- **loading** — spinner in the list area while a fetch is in flight (repo or npub).
- **populated** — rows per above; "Refresh" re-runs the active lookup.
- **empty** — "No pull requests found." after the wait window.
- **no relays** — if no relay is reachable, the same style of message the Open Patch dialog uses: "No relays reachable."
- **invalid npub** — inline red message under the npub field.
- **authenticating** — while a repo relay requires NIP-42 AUTH before answering, the loading spinner's caption reads "Authenticating to <relay host>…" (`AC-pb-private-relays`); a relay that rejects after auth is skipped silently and the fetch continues with the rest.

## Opening a PR

Selecting a PR routes the PR's event id through the existing Open Patch dialog flow, auto-fetching — identical surface and errors to pasting the id by hand (`FR-pb-open-pr`). The browse state itself persists beneath the load (loading replaces the empty state as before). The unsaved-feedback confirmation (replace current review) behavior is identical to the deeplink path.
