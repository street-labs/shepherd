# PR Browse — macOS Design

> Based on requirements in `../../product/pr-browse.md`

## Overview

A single "Browse PRs…" sheet, opened from the empty state next to the existing "Open Patch or PR…" button, hosts the watchlist, both browse lists, and PR opening. One surface, two modes: the watched-repo list is always visible; an npub lookup field sits alongside it.

## Entry point

The empty-state drop zone (`FileDropZoneView`) gains a "Browse PRs…" button after "Open Patch or PR…", shortcut ⌘⇧B, help text "Browse NIP-34 pull requests for a watched repo or a tagged npub". It presents the Browse PRs sheet. No toolbar entry while files are loaded — like Open Patch, the affordance lives in the empty state.

## Sheet layout (single window, ~600×520, not resizable smaller)

```
┌ Browse Pull Requests ──────────────────────────────┐
│ [Watchlist sidebar]      │ [PR list]               │
│ ┌─────────────────────┐  │  Search by npub: [    ] │
│ │ repo coordinate  ✕  │  │  [Find]                 │
│ │ 30617:abc…:shepherd │  │ ──────────────────────  │
│ └─────────────────────┘  │  Subject            age  │
│ [+ add field   Add]      │  Author (short npub)     │
│                          │  …                       │
│                          │  [Refresh]               │
└────────────────────────────────────────────────────┘
```

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

Selecting a PR dismisses the sheet and presents the existing Open Patch dialog flow with the PR's event id, auto-fetching — identical surface and errors to pasting the id by hand (`FR-pb-open-pr`). The unsaved-feedback confirmation (replace current review) behavior is identical to the deeplink path.
