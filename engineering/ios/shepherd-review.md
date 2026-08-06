---
product-hash: 3690acf162292d9c87169800429f77532c40192326fcf3225ba44915e0f24463
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-bunker-signing, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-patch-reply-publish, AC-sr-patch-reply-respond, AC-sr-pr-conflicting-args, AC-sr-pr-event-not-found, AC-sr-pr-fetch-fails, AC-sr-pr-happy-path, AC-sr-pr-metadata-displayed, AC-sr-pr-missing-tags, AC-sr-pr-wrong-kind, AC-sr-quit-early, AC-sr-reviewer-identity, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-bunker-signing, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-reply-publish, FR-sr-patch-reply-respond, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-pr-diff-acquisition, FR-sr-pr-fetch, FR-sr-pr-metadata-display, FR-sr-pr-source, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-reviewer-identity, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---
# Shepherd Review — iOS Technical Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/ios/shepherd-review.md` for iOS-specific requirements.
> Based on design in `../../design/ios/shepherd-review.md`

## What We're Building

The iOS in-app patch open and the bidirectional patch-thread review loop — the port of the macOS in-app patch open (`../../engineering/macos/shepherd-review.md`). The app fetches a NIP-34 patch event in-process by event id, parses its unified diff into per-file tabs, attaches patch metadata, subscribes live to the patch-thread replies, and publishes the reviewer's inline comments as kind:1 replies under a configured Nostr identity (local key or NIP-46 bunker). There is no CLI, no git, and no agent orchestration.

## Technical Approach

The patch-open and publishing paths reuse the macOS `RelayClient`/`NostrSigner`/`PatchReplyMapper`/`PatchDiffSplitter`/`OpenPatchFeature`/`ReviewContextFeature` machinery verbatim, compiled for iOS via the multiplatform package (see `./code-review-prompt.md`). No iOS copies are maintained. The in-process relay client uses `URLSessionWebSocketTask`; signing is a single async `NostrSigner.sign(event:)` that dispatches to in-process secp256k1 Schnorr (local key) or a NIP-46 `sign_event` round-trip (bunker). The shared `AppFeature` reducer already orchestrates the open-patch sheet, live-thread subscription, reply publishing, and identity load — the iOS app reuses it unchanged and only supplies the root view that surfaces these.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Patch fetch | `RelayClient.subscribe` with an `ids`-only filter, cancel on first event | Matches the macOS in-app path; lets non-1617 events be rejected with a precise wrong-kind error (`FR-sri-patch-open-fetch`). |
| Reference decode | `Bech32` decode of `nevent1` (event id + relay hints) | Reuse the macOS bech32 code; `naddr` rejected. |
| Diff parsing | `PatchParser` splits on `diff --git a/<p> b/<p>` boundaries | One tab per changed file; the diff block is the tab content (`FR-sri-patch-open-load`). |
| Metadata | Built from the event (pubkey, first content line, `parent-commit`/`a` tags) | No git, no extra fetches. Status `open` in v1. |
| Live thread | `RelayClient.subscribe` with `#e`/`kinds:[1]` filter for the patch event | Reuses `FR-sr-patch-replies-live`; mapped via `PatchReplyMapper`. |
| Publishing | `RelayClient.publish` sends `EVENT` frames; best-effort, ≥1 relay accepts | `FR-sri-event-publish`, `AC-sri-publish-relay-failure`. |
| Signing | `NostrSigner` async, mode-agnostic (local Schnorr \| NIP-46) | One publish path unaware of the identity form (`FR-sri-event-sign`). |
| Bunker | NIP-46 over the same relay client; ephemeral session keypair; `connect`/`get_public_key`/`sign_event` | `FR-sri-bunker-connect`; no secret key on device in this mode. |
| Identity config | In-app Identity sheet; persists in iOS Keychain (`./identity.md`) | iOS has no env vars/dotfiles (`FR-sri-identity-load`); login/create/persist/logout are specified in `./identity.md` (`FR-id-ios-keychain-storage`). |

## Data Model

- `NostrEvent` — NIP-01 event (id, pubkey, created_at, kind, tags, content, sig). Reused model.
- `PatchMetadata` — full/short id, author pubkey + resolved display name (npub fallback in v1), commit message, parent short hash, repo coordinate, status.
- `PatchReply` — author (display name + pubkey), bot/human flag, content, timestamp, optional `LineAnchor(filePath, startLine, endLine)`. Reused from the macOS mapper.
- `ReviewerIdentity` — enum: `local(secretKey)`, `bunker(uri)`, `none`; plus the resolved public key and (for bunker) connection state.

## API / Interface Design

- `RelayClient` (shared, reused):
  - `func subscribe(_ filter: NostrFilter) -> AsyncStream<NostrEvent>`
  - `func publish(_ event: NostrEvent) async -> PublishResult` (`.accepted` / `.rejected` / `.noRelays`)
  - relay URL resolution: in-app configured list → default public fallback.
- `NostrSigner` (shared, reused):
  - `func sign(event: UnsignedNostrEvent) async -> NostrEvent?`
  - `func publicKey(for identity: ReviewerIdentity) async -> PublicKey?`
  - `testValue` returns deterministic fixtures.
- `PatchParser` — the shared `PatchDiffSplitter` splits on `diff --git a/<p> b/<p>` boundaries (`FR-sri-patch-open-load`); `OpenPatchFeature` wraps the parse + kind-1617 validation into `PatchParseResult`.
- `PatchReplyMapper` (shared, reused):
  - `func map(_ events: [NostrEvent], patchEventId: String) -> [PatchReply]` (kind:1 root filter, bot/human, line anchor parse).
- `PatchOpenFeature` reducer actions (shared, reused): `openButtonTapped`, `referenceChanged(String)`, `submitTapped`, `.delegate(.patchLoaded(...))`, `.delegate(.cancelled)`.

## Component Architecture

- `PatchOpenFeature` (shared, reused) — the existing Open Patch sheet reducer. Validates the reference (`Bech32`/hex), runs the fetch effect (`RelayClient.subscribe` ids-only, cancel-on-first), parses (`PatchDiffSplitter`), and emits `delegate.patchLoaded`. Owns the sheet's idle/fetching/error states.
- `PatchThreadFeature` (realized by the shared `AppFeature` + `ReviewContextFeature`) — the existing `startPatchReplySubscription` effect subscribes live to the patch's replies, maps them via `PatchReplyMapper`, and the `ReviewContextFeature` renders the inspector Thread section + inline anchored bubbles. The live `AsyncStream` lifecycle is a cancellable TCA effect torn down on session clear/window close.
- `PublishingFeature` (realized by the shared `AppFeature.patchReviewPublishEffect`) — on comment submit in a patch review: builds the unsigned kind:1 (root `e`, repo `a`, line-range anchor), `sign`, `publish`, records locally, dedupes the echo. Handles bunker-sign-failure reopen.
- `IdentityFeature` (shared, reused) — loads/holds `ReviewerIdentity` from the Keychain, drives the identity indicator (`IdentityIndicatorView`), opens/closes the bunker control channel.

## State Management

TCA. `PatchOpenFeature.State` holds the sheet UI state and a `PatchOpenError?`. `AppFeature.State` holds the optional `PatchReviewSession` and `ReviewerIdentity`. The live thread subscription is a cancellable TCA effect keyed to the session; dismissing the session sends `.cancel`. Published replies are inserted into the thread state immediately (optimistic) and deduped by event id when the echo arrives (`AC-sri-publish-no-dup`).

## Error Handling

- `PatchOpenError`: `.invalidInput`, `.notFound`, `.wrongKind(Int)`, `.badDiff`, `.noRelays` — each maps to the exact user-facing string in `../../design/ios/shepherd-review.md`.
- `PublishError`: `.bunkerSignFailed`, `.noRelayAccepted` — bunker failure reopens the editor with the local comment retained (`FR-sri-bunker-sign-failure`); no-relay-accepted informs the reviewer and retains the local copy (`AC-sri-publish-relay-failure`).
- Malformed `bunker://` URI → identity treated as `none` with a parse-error indicator (`FR-sri-identity-indicator`).

## Performance Considerations

- The fetch subscription is cancelled on the first event (one event, not a stream). The live thread subscription runs for the review's lifetime only.
- NIP-46 bunker round-trips are network calls; the publish button reflects `Publishing…` and the indicator's status dot during them (`../../design/ios/shepherd-review.md`).
- NFR-sri-no-git / NFR-sri-no-server hold: no git, no local server. iOS PR review acquires the diff from referenced kind `1617` patch events over the relay client, not a git fetch.
- iOS PR open fetches N+1 events in-process (the PR event plus each referenced patch) and unions their diffs; this is a handful of small relay round-trips, well within the iOS review budget. No git objects are fetched.

## Security Considerations

- Local secret keys are in-memory only; no unprotected storage. Bunker mode holds no secret key on device.
- Published replies are signed under the reviewer's identity; the unsigned event is built in-process and handed to the signer.
- Relay and identity configuration is validated before use.

## Implementation Plan

The patch-open and publishing machinery already exists in the shared macOS package and is reused on iOS, so the iOS-side work is build verification + root-view wiring:

1. **Verify multiplatform build** — confirm `RelayClient`, `NostrSigner`, `PatchReplyMapper`, `PatchDiffSplitter`, `OpenPatchFeature`, and `ReviewContextFeature` compile for the iOS app target.
2. **Root-view wiring** — the iOS `iOSAppView` surfaces the shared `AppFeature.openPatchRequested` (Open Patch sheet) from the empty state, and the inspector's `ReviewContextFeature` (metadata, thread, identity indicator) in the detail column / pushed screens.
3. **Settings (relays)** — relay configuration UI is an iOS-only settings surface (the shared `RelayClient` reads its relay list from a source that the iOS app supplies); exact shape deferred (Open Question 3).
4. **Tests** — the shared `OpenPatchFeature`/relay/mapper tests run on iOS; verify at build.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| `FR-sr-relay-client` | engineering/apps/macos/Sources/Dependencies/RelayClient.swift | implemented |
| `FR-sr-patch-metadata-display` | engineering/apps/macos/Sources/ReviewContextFeature/PatchMetadataSectionView.swift | implemented |
| `FR-sr-patch-replies-display` | engineering/apps/macos/Sources/ReviewContextFeature/PatchRepliesSectionView.swift | implemented |
| `FR-sr-patch-replies-live` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sr-patch-reply-publish` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sr-patch-reply-respond` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sr-reviewer-identity` | engineering/apps/macos/Sources/ReviewContextFeature/IdentityIndicatorView.swift | implemented |
| `FR-sr-bunker-signing` | engineering/apps/macos/Sources/Dependencies/NostrSigner.swift | implemented |
| `FR-sri-patch-open-entry` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchView.swift | implemented |
| `FR-sri-patch-open-input` | engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift | implemented |
| `FR-sri-patch-open-fetch` | engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift | implemented |
| `FR-sri-patch-open-load` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift | implemented |
| `FR-sri-pr-open-patches` | engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift; engineering/apps/macos/Sources/SharedModels/PatchDiffSplitter.swift | implemented |
| `FR-sri-pr-open-load` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/SharedModels/PatchDiffSplitter.swift | implemented |
| `FR-sr-pr-metadata-display` | engineering/apps/macos/Sources/SharedModels/ReviewContext.swift; engineering/apps/macos/Sources/ReviewContextFeature/PatchMetadataSectionView.swift | implemented |
| `FR-sri-identity-load` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sri-bunker-connect` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/Dependencies/BunkerClient.swift | implemented |
| `FR-sri-event-sign` | engineering/apps/macos/Sources/Dependencies/NostrSigner.swift | implemented |
| `FR-sri-bunker-sign-failure` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sri-event-publish` | engineering/apps/macos/Sources/Dependencies/RelayClient.swift | implemented |
| `FR-sri-comment-publish-on-submit` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sri-reply-to-reply` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-sri-identity-indicator` | engineering/apps/macos/Sources/ReviewContextFeature/IdentityIndicatorView.swift | implemented |

Notes:
- Shared `FR-sr-*` requirements that do not apply on iOS (changeset detection, file filtering, context generation, CLI launch, install, git, feedback collection, etc.) are omitted from the Code Map; see `../../product/ios/shepherd-review.md` "Do not apply on iOS".
- `FR-sr-patch-fetch` and `FR-sr-patch-application` are superseded on iOS by the in-app fetch/load (`FR-sri-patch-open-fetch`/`FR-sri-patch-open-load`); they are omitted.
- `FR-sr-patch-validation` is realized by `PatchParser`/`PatchOpenFeature` validation (kind 1617 + diff), NIP-34-correct; covered by `FR-sri-patch-open-fetch`. A kind `1618` event skips diff validation and routes to `FR-sri-pr-open-patches`.
- `FR-sr-pr-source`, `FR-sr-pr-fetch`, `FR-sr-pr-diff-acquisition` are realized on iOS by the in-app iterate-patches path (`FR-sri-pr-open-patches` / `FR-sri-pr-open-load`) rather than the shared git-fetch acquisition; they are listed under the iOS PR rows above where iOS-specific, and the shared git-fetch acquisition (`FR-sr-pr-diff-acquisition`) does not apply on iOS (`NFR-sri-no-git`).

## Open Questions

1. **Shared Nostr dependencies** — resolved: reused from the shared multiplatform package; no iOS copy maintained (see `./code-review-prompt.md`).
2. **Roster / display-name resolution** — v1 uses truncated npub. Bundling a roster or fetching NIP-05 is a follow-up (product Open Question 3). `PatchReplyMapper` resolves display name via a pluggable resolver that returns npub in v1.
3. **Relay default set** — the in-app "use defaults" toggle needs a default public relay list; reuse the macOS default set. Exact list is an engineering decision; the iOS settings UI shape is deferred.
4. **NIP-46 library** — resolved: the macOS `BunkerClient`/`NostrSigner` already implement NIP-46 (`connect`/`get_public_key`/`sign_event`, NIP-44 encryption) in Swift and are reused on iOS via the multiplatform package.
