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

### `NostrFilter` extension (`ShepherdDependencies/RelayClient.swift`)

Add optional `aTag: String?` and `pTag: String?`, serialized as `#a` / `#p` single-element arrays in `jsonObject` — the same shape as the existing `#e`. No new client code; `RelaySubscriptionTask` already serializes whatever the filter emits.

### `WatchlistClient` (new file in `ShepherdDependencies`)

`load() -> [String]` / `save([String])` over a single UserDefaults string-array key (`prbrowse.watchlist`). Validation lives in the feature, not the client: `RepoCoordinate.parse("30617:<pubkey>:<d>")` checks kind literal `30617`, 64-char hex pubkey, non-empty identifier. Struct with `raw` string and computed `d` tail for display. Testable via dependency override.

### `PRBrowseFeature`

- **Repo lookup** (`FR-pb-repo-list`): subscribe `NostrFilter(kinds: [1618], aTag: coordinate)`, collect events for 8s, map to `PRSummary` (id, subject = `subject` tag or first content line, pubkey, createdAt), sort newest first, dedupe by id. Unlike `OpenPatchFeature.firstEventOrTimeout` (whose collecting task returns after the *first* event), the all-events collector accumulates into a shared buffer: the subscription stream never terminates on its own, so the timeout always wins the task-group race and the collecting task's return value would be discarded — the buffer is read after the race instead.
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
- **Status filtering deferred**: kind `1630`–`1633` events are not fetched in v1 (see shared spec Out of Scope).

## Tests

Unit tests in `PRBrowseFeatureTests` (new test target additions under the existing ShepherdTests suite): watchlist add/remove/duplicate/invalid + persistence via overridden `WatchlistClient`; repo lookup collects/dedupes/sorts within window and times out to empty; npub lookup rejects bad input; `openPR` delegate emission. `RepoCoordinate.parse` truth table. `NostrFilter` JSON serialization of `#a`/`#p`.
