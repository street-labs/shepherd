---
product-hash: ec7848c9428c28f1a2281961f54d73ff305683387b2f74d32573ac4c6ef8309b
product-slugs: [AC-pb-default-state, AC-pb-npub-list, AC-pb-open-pr, AC-pb-private-relays, AC-pb-repo-list, AC-pb-status-badge, AC-pb-watchlist-invalid, AC-pb-watchlist-persists, FR-pb-default-state, FR-pb-npub-list, FR-pb-open-pr, FR-pb-repo-list, FR-pb-status, FR-pb-watchlist-manage, FR-srm-patch-open-entry, NFR-pb-fetch-window]
---

# PR Browse — iOS Design

> Based on requirements in `../../product/pr-browse.md` and `../../product/ios/pr-browse.md`

## Overview

Browse becomes the iOS app's root screen (`FR-pbi-browse-root`), reusing the shared browse behavior; layout adapts to iPhone and iPad (`FR-pbi-adaptive`).

## Root structure

`iOSAppView` gains a `NavigationStack` rooted at Browse:

- **Browse screen** — watchlist section (list of repo rows with swipe-to-delete, plus an "Add repo" field row with inline validation message) and the PR list below it, mirroring the macOS two-pane content as stacked sections. The npub lookup is a search field pinned under the navigation title; its results replace the PR list with a "PRs tagged <npub>" header and clear button. The existing "Open Patch or PR…" by-id entry stays as a toolbar action.
- **PR rows** — subject, author short npub, relative age, status badge (same tinting as macOS). Tap pushes the existing review flow (`OpenPatchView` path); back returns to Browse with list state intact.
- **States** — idle / loading (spinner, with "Authenticating to <host>…" caption during NIP-42 auth) / populated / empty / invalid-npub inline message, matching the shared spec.

iPhone renders the sections in one scrolling column; iPad may present watchlist and PR list side by side when width allows.
