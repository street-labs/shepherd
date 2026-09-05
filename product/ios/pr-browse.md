# PR Browse — iOS Platform

> iOS-specific requirements for PR Browse. See `../pr-browse.md` for shared requirements.

iOS gains the PR Browse surface in this scope: today the iOS app opens patches/PRs only by pasted event id or link (`EmptyStateView`); there is no browse list, watchlist, or status display on iOS. The shared spec applies; this supplement covers where iOS diverges.

## Shared Requirements — Applicability on iOS

All shared `FR-pb-*` requirements apply unchanged on iOS, with these realizations and exceptions:

- `FR-pb-watchlist-manage`, `FR-pb-repo-list`, `FR-pb-npub-list`, `FR-pb-status` — apply as-is; persistence and relay/auth behavior are shared (`WatchlistClient`, `RelayClient` are platform-neutral SPM sources used by both apps).
- `FR-pb-default-state` — does not apply as written. iOS has no inline main-window empty state; the browse surface is the app's root view (`iOSAppView`), with "Open Patch or PR…" by id available as a toolbar action, matching the existing iOS open flow.
- `FR-pb-open-pr` — applies as-is via the existing iOS in-app open load path (`FR-sri-patch-open-*` / PR open in `./shepherd-review.md`).
- `NFR-pb-fetch-window` — applies as-is.

## iOS-Specific Requirements

- **Browse as root view** `FR-pbi-browse-root`: The PR Browse surface (watchlist, repo/npub PR lists, status badges) is the iOS app's root screen. Selecting a PR pushes the existing review flow onto the navigation stack; popping back returns to browse with the list state preserved.
- **Adaptive layout** `FR-pbi-adaptive`: The browse surface renders as a single column on iPhone and may use the available width for list detail on iPad; no macOS-only window chrome is assumed.
