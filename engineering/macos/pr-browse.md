# PR Browse — macOS Engineering

> Based on requirements in `../../product/pr-browse.md`
> Based on design in `../../design/macos/pr-browse.md`

## Architecture

One new TCA feature module, `PRBrowseFeature`, plus a small persistence client and a filter extension. The feature deliberately contains no review logic: selecting a PR emits a delegate action with the event id, and `AppFeature` routes it through the existing `presentOpenPatch` path (the same one deeplinks use).

```
PRBrowseFeature (new target, macOS/iOS-clean source)
  State: watchlist [RepoCoordinate], addField, addError,
         npubField, npubError, mode (idle/repo/npub), loading,
         prs [PRSummary]
  Delegate: openPR(eventID)   -> AppFeature.presentOpenPatch
PRBrowseView (SwiftUI — inline in the app's default empty state)
WatchlistClient (new dependency, UserDefaults-backed)
NostrFilter: + aTag/pTag -> "#a"/"#p" REQ keys
```

## Components

### `NostrFilter` extension (`ShepherdDependencies/RelayClient.swift)

Add optional `aTag: String?` and `pTag: String?`, serialized as `#a` / `#p` single-element arrays in `jsonObject` — the same shape as the existing `#e`. No new client code; `RelaySubscriptionTask` already serializes whatever the filter emits.

### `WatchlistClient` (new file in `ShepherdDependencies`)

`load() -> [String]` / `save([String])` over a single UserDefaults string-array key (`prbrowse.watchlist`). Validation lives in the feature, not the client: `RepoCoordinate.parse("30617:<pubkey>:<d>")` checks kind literal `30617`, 64-char hex pubkey, non-empty identifier. Struct with `raw` string and computed `d` tail for display. Testable via dependency override.

### `PRBrowseFeature`

- **Repo lookup** (`FR-pb-repo-list`): fetch the repo's `30617` event (`NostrFilter(kinds: [30617], authors: [owner], #d: [d])`) from configured relays; its `relays` tag becomes the fetch target set for the repo's PRs, falling back to configured relays when the repo event or tag is missing (`AC-pb-private-relays`). The relay set is handed to the subscription so private grasp relays are queried directly; NIP-42 AUTH is handled by the existing `RelayAuth` path, which already answers kind-22242 challenges with the user's identity. A relay that rejects after auth is dropped from that lookup's set, not fatal. Subscribe `NostrFilter(kinds: [1618], aTag: coordinate)`, collect events for 8s, map to `PRSummary` (id, subject = `subject` tag or first content line, pubkey, createdAt, status), sort newest first, dedupe by id. Unlike `OpenPatchFeature.firstEventOrTimeout` (whose collecting task returns after the *first* event), the all-events collector accumulates into a shared buffer: the subscription stream never terminates on its own, so the timeout always wins the task-group race and the collecting task's return value would be discarded — the buffer is read after the race instead.
- **Status events** (`FR-pb-status`): the same lookup subscription also collects kinds `1630`–`1633` filtered on the repo's `a` coordinate; after the window closes, each PR's status is resolved to the newest status event (by `created_at`) whose `e` tag matches the PR id, defaulting to open. The list renders open only unless `showAll` is set; `PRSummary` gains `status` and the view gains the `Show all` toggle.
- **Npub lookup** (`FR-pb-npub-list`): accept `npub1…` (Bech32 decode — reuse `NIP19Decode`'s bech32 helpers; if no npub decoder exists, add `decodeNPub` returning the hex pubkey) or 64-char hex; subscribe `NostrFilter(kinds: [1618], pTag: pubkey)`, same collection.
- **Relay guard**: probe `reachableRelays` first, exactly like Open Patch; empty → `.noRelays` message state.
- **Watchlist**: `addTapped` validates via `RepoCoordinate.parse`, rejects duplicates and malformed input with inline error; `remove(coordinate)` deletes. Persist through `WatchlistClient` on every mutation, load on `onAppear`/init effect.
- **`openPR(id)`**: `.delegate(.openPR(id))`, no local loading.

### `AppFeature` wiring

- `var prBrowse = PRBrowseFeature.State()` — non-presented child state (`Scope(state:action:)`), shown inline in the empty state. Implements `FR-pb-default-state`.
- `prBrowse(.delegate(.openPR(id)))` → `presentOpenPatch(id, state:)` via the shared `openRefSafely(_:)` helper (same unsaved-feedback confirmation as a deeplink). The browse state itself is kept, not dismissed.

### `AppView` / `FileDropZoneView`

The empty state (`FileDropZoneView`) hosts the button row (Open Files…, Paste from Clipboard, Open Patch or PR… ⌘⇧P) above the inline `PRBrowseView`, scoped from `AppFeature`'s `prBrowse` state. No browse sheet. Drag-and-drop onto the window is unchanged.

## Trade-offs

- **All-events window, not first-event**: one subscription per lookup; we keep collecting until the 8s window closes, so a repo with many PRs gets them all without paging.
- **No background subscriptions**: lists exist only while the empty state is visible. Live updates are a roadmap item.
- **Status events included**: kinds `1630`–`1633` ride the same subscription window; badge and open-only filter ship with the list (roadmap item graduated).
- **Repo-relay targeting**: PR fetches follow the repo announcement's `relays` tag; misconfigured announcements fall back to configured relays.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| `FR-pb-watchlist-manage` | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift; engineering/apps/macos/Sources/Dependencies/WatchlistClient.swift | implemented |
| `FR-pb-repo-list` | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift; engineering/apps/macos/Sources/Dependencies/RelayClient.swift | implemented |
| `FR-pb-npub-list` | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |
| `FR-pb-default-state` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/AppFeature/FileDropZoneView.swift | implemented |
| `FR-pb-open-pr` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-pb-status` | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift; engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseView.swift | implemented |
| `NFR-pb-fetch-window` | engineering/apps/macos/Sources/PRBrowseFeature/PRBrowseFeature.swift | implemented |

## Tests

Unit tests in `PRBrowseFeatureTests` (new test target additions under the existing ShepherdTests suite): watchlist add/remove/duplicate/invalid + persistence via overridden `WatchlistClient`; repo lookup collects/dedupes/sorts within window and times out to empty; npub lookup rejects bad input; `openPR` delegate emission. `RepoCoordinate.parse` truth table. `NostrFilter` JSON serialization of `#a`/`#p`. Status resolution (newest 1630–1633 per PR, open default). Repo-relay targeting: 30617 with relays tag → PR fetch targets those relays; missing 30617 → fallback.
