---
product-hash: 63dd74d1198483ed4727495a3fa24821f6daf12ccd9ef3aff043e02d33b25d18
product-slugs: [AC-pb-npub-list, AC-pb-open-pr, AC-pb-repo-list, AC-pb-watchlist-invalid, AC-pb-watchlist-persists, FR-pb-npub-list, FR-pb-open-pr, FR-pb-repo-list, FR-pb-watchlist-manage, NFR-pb-fetch-window]
---
# PR Browse — iOS Engineering

> Based on requirements in `../../product/pr-browse.md`
> Based on design in `../../design/ios/pr-browse.md`

## What We're Building

The iOS port of PR Browse. The heavy lifting already ships in the shared SwiftPM package the iOS target imports (`engineering/apps/macos/`): `PRBrowseFeature` (TCA state/reducers, watchlist persistence, relay lookups), the `AppFeature` wiring (`browsePRsRequested`, `prBrowse` presentation, the `openPR` delegate routed through `presentOpenPatch`), and `PRBrowseView`. The iOS app already links `AppFeature` transitively (it depends on `PRBrowseFeature`), so the remaining work is presentational: expose the entry point, present the sheet, and make `PRBrowseView` adaptive instead of macOS-frame-sized.

## Technical Approach

Three small changes, no new modules:

1. **`EmptyStateView`** — add a "Browse PRs" button sending `.browsePRsRequested`.
2. **`iOSAppView`** — add the `.sheet(item: $store.scope(state: \.prBrowse, action: \.prBrowse)) { PRBrowseView(store:) }` presentation alongside the Open Patch sheet.
3. **`PRBrowseView`** — replace the fixed `frame(minWidth: 620, minHeight: 420)` and the two-pane `HStack` with a size-class-driven body: compact gets a single-column `NavigationStack` (watchlist screen pushing the PR list, swipe-to-delete on watchlist rows), expanded keeps the current two-column layout. Single tap opens a PR on compact (double-tap/Enter stays for pointer/keyboard).

## Data Model

No new data. `PRBrowseFeature.State` (watchlist, inputs, errors, mode, loading, `PRSummary` list) and the UserDefaults-backed `WatchlistClient` are shared with macOS and used as-is.

## API / Interface Design

No new contracts. The existing delegate `PRBrowseFeature.Action.delegate(.openPR(id))` → `AppFeature.presentOpenPatch` path is reused unchanged; iOS has no unsaved-feedback guard to satisfy (no local files loaded when the sheet is reachable — the entry point only exists on the empty state).

## Component Architecture

| Module | Change |
|---|---|
| `engineering/apps/ios/ShepherdiOSApp/EmptyStateView.swift` | Add Browse PRs button (entry point). |
| `engineering/apps/ios/ShepherdiOSApp/iOSAppView.swift` | Present the `prBrowse` sheet. |
| `engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseView.swift` | Adaptive layout: size-class split, compact navigation, single-tap open, remove fixed min frames. |

`PRBrowseFeature.swift`, `WatchlistClient`, the `NostrFilter` `#a`/`#p` extension, and all `AppFeature` wiring are untouched — they are platform-clean and already compiled into the iOS target via the shared package.

## State Management

Unchanged: TCA store scoping from `AppFeature.$prBrowse` into the sheet, exactly as the macOS `AppView` does.

## Error Handling

Unchanged — the feature's existing inline input errors, no-relays state, and the Open Patch flow's load errors surface as on macOS.

## Performance Considerations

None beyond the shared 8s wait-window behavior (`NFR-pb-fetch-window`).

## Security Considerations

None new. Watchlist persists a list of public repo coordinates in UserDefaults; no secrets involved.

## Implementation Plan

1. **Adapt `PRBrowseView` for compact** — size-class-driven layout and single-tap open. First because the sheet is useless on iPhone without it, and it is the only change inside the shared package.
2. **Entry point + sheet** — `EmptyStateView` button and `iOSAppView` presentation; wires the existing actions end to end.
3. **Build + tests** — `swift test` in the package (regression on macOS variants) and an iOS build of the app target.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-pb-watchlist-manage | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseView.swift; engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |
| FR-pb-repo-list | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |
| FR-pb-npub-list | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |
| FR-pb-open-pr | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/ios/ShepherdiOSApp/EmptyStateView.swift | implemented |
| NFR-pb-fetch-window | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |

(All five slugs are `implemented`: the shared surface plus the iOS entry point (`EmptyStateView`) and the adaptive `PRBrowseView` layout.)

## Tests

No new unit tests: every logic path (watchlist CRUD + persistence, lookups, delegate emission) is already covered by `PRBrowseFeatureTests` in the shared package, and this port adds no logic — only views. iOS-specific verification is manual (see `qa/ios/pr-browse.md`): sheet layout on iPhone and iPad size classes, single-tap open, swipe-to-delete.
