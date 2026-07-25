---
product-hash: 3be8b01ef980231ee907e94c5591e47414c5e047c1e0495541e48426acbca4ae
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-bunker-signing, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-patch-reply-publish, AC-sr-patch-reply-respond, AC-sr-quit-early, AC-sr-reviewer-identity, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-bunker-signing, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-reply-publish, FR-sr-patch-reply-respond, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-reviewer-identity, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---
# Shepherd Review — iOS Technical Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/ios/shepherd-review.md` for iOS-specific requirements.
> Based on design in `../../design/ios/shepherd-review.md`

## What We're Building

The iOS in-app patch open and the bidirectional patch-thread review loop — the port of the macOS in-app patch open (`../../engineering/macos/shepherd-review.md`). The app fetches a NIP-34 patch event in-process by event id, parses its unified diff into per-file tabs, attaches patch metadata, subscribes live to the patch-thread replies, and publishes the reviewer's inline comments as kind:1 replies under a configured Nostr identity (local key or NIP-46 bunker). There is no CLI, no git, and no agent orchestration.

## Technical Approach

The patch-open and publishing paths are iOS ports of the macOS `RelayClient`/`NostrSigner`/`PatchReplyMapper` machinery. For v1 the iOS app target carries its own copies of these dependencies under `engineering/apps/ios/Sources/Dependencies/` (see `./code-review-prompt.md` Open Question 1); a later refactor can lift them into a shared multiplatform target. The in-process relay client uses `URLSessionWebSocketTask`; signing is a single async `NostrSigner.sign(event:)` that dispatches to in-process secp256k1 Schnorr (local key) or a NIP-46 `sign_event` round-trip (bunker).

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
| Identity config | In-app Settings form; held in memory for the session | iOS has no env vars/dotfiles (`FR-sri-identity-load`). |

## Data Model

- `NostrEvent` — NIP-01 event (id, pubkey, created_at, kind, tags, content, sig). Reused model.
- `PatchMetadata` — full/short id, author pubkey + resolved display name (npub fallback in v1), commit message, parent short hash, repo coordinate, status.
- `PatchReply` — author (display name + pubkey), bot/human flag, content, timestamp, optional `LineAnchor(filePath, startLine, endLine)`. Reused from the macOS mapper.
- `ReviewerIdentity` — enum: `local(secretKey)`, `bunker(uri)`, `none`; plus the resolved public key and (for bunker) connection state.

## API / Interface Design

- `RelayClient` (iOS copy):
  - `func subscribe(_ filter: NostrFilter) -> AsyncStream<NostrEvent>`
  - `func publish(_ event: NostrEvent) async -> PublishResult` (`.accepted` / `.rejected` / `.noRelays`)
  - relay URL resolution: in-app configured list → default public fallback.
- `NostrSigner` (iOS copy):
  - `func sign(event: UnsignedNostrEvent) async -> NostrEvent?`
  - `func publicKey(for identity: ReviewerIdentity) async -> PublicKey?`
  - `testValue` returns deterministic fixtures.
- `PatchParser`:
  - `func parse(_ event: NostrEvent) -> PatchParseResult` (`.success([FileBlock], PatchMetadata)` / `.wrongKind` / `.badDiff`).
- `PatchReplyMapper`:
  - `func map(_ events: [NostrEvent], patchEventId: String) -> [PatchReply]` (kind:1 root filter, bot/human, line anchor parse).
- `PatchOpenFeature` reducer actions: `openButtonTapped`, `referenceChanged(String)`, `submitTapped`, `.success(PatchReviewSession)`, `.failure(PatchOpenError)`.

## Component Architecture

- `PatchOpenFeature` — the Open Patch sheet reducer. Validates the reference (`Bech32`/hex), runs the fetch effect (`RelayClient.subscribe` ids-only, cancel-on-first), parses (`PatchParser`), and emits `sessionLoaded`. Owns the sheet's idle/fetching/error states.
- `PatchThreadFeature` (composed into the inspector) — subscribes live to the patch's replies, maps them, and renders the inspector Thread section + inline anchored bubbles. Owns the live `AsyncStream` lifecycle (tear down on dismiss).
- `PublishingFeature` (or extension of `CommentFeature`) — on comment submit in a patch review: build the unsigned kind:1 (root `e`, repo `a`, line-range anchor), `sign`, `publish`, record locally, dedupe the echo. Handles bunker-sign-failure reopen.
- `IdentityFeature` — loads/holds `ReviewerIdentity` from in-app Settings, drives the identity indicator, opens/closes the bunker control channel.

## State Management

TCA. `PatchOpenFeature.State` holds the sheet UI state and a `PatchOpenError?`. `AppFeature.State` holds the optional `PatchReviewSession` and `ReviewerIdentity`. The live thread subscription is a cancellable TCA effect keyed to the session; dismissing the session sends `.cancel`. Published replies are inserted into the thread state immediately (optimistic) and deduped by event id when the echo arrives (`AC-sri-publish-no-dup`).

## Error Handling

- `PatchOpenError`: `.invalidInput`, `.notFound`, `.wrongKind(Int)`, `.badDiff`, `.noRelays` — each maps to the exact user-facing string in `../../design/ios/shepherd-review.md`.
- `PublishError`: `.bunkerSignFailed`, `.noRelayAccepted` — bunker failure reopens the editor with the local comment retained (`FR-sri-bunker-sign-failure`); no-relay-accepted informs the reviewer and retains the local copy (`AC-sri-publish-relay-failure`).
- Malformed `bunker://` URI → identity treated as `none` with a parse-error indicator (`FR-sri-identity-indicator`).

## Performance Considerations

- The fetch subscription is cancelled on the first event (one event, not a stream). The live thread subscription runs for the review's lifetime only.
- NIP-46 bunker round-trips are network calls; the publish button reflects `Publishing…` and the indicator's status dot during them (`../../design/ios/shepherd-review.md`).
- NFR-sri-no-git / NFR-sri-no-server hold: no git, no local server.

## Security Considerations

- Local secret keys are in-memory only; no unprotected storage. Bunker mode holds no secret key on device.
- Published replies are signed under the reviewer's identity; the unsigned event is built in-process and handed to the signer.
- Relay and identity configuration is validated before use.

## Implementation Plan

1. **`Bech32` + `NostrEvent` + `RelayClient` (iOS copies)** — enables fetch/subscribe/publish. (Cross-ref `./code-review-prompt.md`.)
2. **`PatchParser` + `PatchOpenFeature` + Open Patch sheet** — enables opening a patch and loading the session.
3. **`PatchReplyMapper` + `PatchThreadFeature` (live subscription)** — enables reading the thread.
4. **`NostrSigner` (local key) + `PublishingFeature`** — enables publishing replies under a local key.
5. **Bunker path: `IdentityFeature` NIP-46 connect/get_public_key/sign_event + indicator** — enables bunker signing and the identity indicator.
6. **Settings (identity + relays) + error/edge states** — enables in-app configuration and all `AC-sri-*` coverage.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-sr-relay-client | engineering/apps/ios/Sources/Dependencies/RelayClient.swift | planned |
| FR-sr-patch-metadata-display | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-sr-patch-replies-display | engineering/apps/ios/Sources/Dependencies/PatchReplyMapper.swift | planned |
| FR-sr-patch-replies-live | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sr-patch-reply-publish | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sr-patch-reply-respond | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sr-reviewer-identity | engineering/apps/ios/Sources/Dependencies/NostrSigner.swift | planned |
| FR-sr-bunker-signing | engineering/apps/ios/Sources/Dependencies/NostrSigner.swift | planned |
| FR-sri-patch-open-entry | engineering/apps/ios/Sources/PatchOpenFeature/PatchOpenView.swift | planned |
| FR-sri-patch-open-input | engineering/apps/ios/Sources/PatchOpenFeature/PatchOpenFeature.swift | planned |
| FR-sri-patch-open-fetch | engineering/apps/ios/Sources/PatchOpenFeature/PatchOpenFeature.swift | planned |
| FR-sri-patch-open-load | engineering/apps/ios/Sources/Dependencies/PatchParser.swift | planned |
| FR-sri-identity-load | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sri-bunker-connect | engineering/apps/ios/Sources/Dependencies/NostrSigner.swift | planned |
| FR-sri-event-sign | engineering/apps/ios/Sources/Dependencies/NostrSigner.swift | planned |
| FR-sri-bunker-sign-failure | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sri-event-publish | engineering/apps/ios/Sources/Dependencies/RelayClient.swift | planned |
| FR-sri-comment-publish-on-submit | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sri-reply-to-reply | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-sri-identity-indicator | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |

Notes:
- Shared `FR-sr-*` requirements that do not apply on iOS (changeset detection, file filtering, context generation, CLI launch, install, git, feedback collection, etc.) are omitted from the Code Map; see `../../product/ios/shepherd-review.md` "Do not apply on iOS".
- `FR-sr-patch-fetch` and `FR-sr-patch-application` are superseded on iOS by the in-app fetch/load (`FR-sri-patch-open-fetch`/`FR-sri-patch-open-load`); they are omitted.
- `FR-sr-patch-validation` is realized by `PatchParser`/`PatchOpenFeature` validation (kind 1617 + diff), NIP-34-correct; covered by `FR-sri-patch-open-fetch`.

## Open Questions

1. **Shared Nostr dependencies** — as in `./code-review-prompt.md` Open Question 1: duplicate for v1, lift to a shared multiplatform target as a follow-up.
2. **Roster / display-name resolution** — v1 uses truncated npub. Bundling a roster or fetching NIP-05 is a follow-up (product Open Question 3). `PatchReplyMapper` resolves display name via a pluggable resolver that returns npub in v1.
3. **Relay default set** — the in-app "use defaults" toggle needs a default public relay list; reuse the macOS default set. Exact list is an engineering decision.
4. **NIP-46 library** — implement NIP-46 (`connect`/`get_public_key`/`sign_event`, NIP-44 encryption) in Swift in the iOS `NostrSigner`, mirroring the macOS implementation. If a Swift NIP-46 library is already used by macOS, reuse it; otherwise port the minimal pieces. Verify at implementation time.
