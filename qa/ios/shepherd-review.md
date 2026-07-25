---
product-hash: 3be8b01ef980231ee907e94c5591e47414c5e047c1e0495541e48426acbca4ae
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-bunker-signing, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-patch-reply-publish, AC-sr-patch-reply-respond, AC-sr-quit-early, AC-sr-reviewer-identity, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-bunker-signing, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-reply-publish, FR-sr-patch-reply-respond, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-reviewer-identity, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---
# Shepherd Review — iOS Test Plan

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/ios/shepherd-review.md` for iOS-specific requirements.
> Based on design in `../../design/ios/shepherd-review.md`
> Based on engineering in `../../engineering/ios/shepherd-review.md`

## What We're Testing

The iOS in-app patch open and the bidirectional patch-thread review loop: opening a NIP-34 patch by event id / `nevent1`, fetch + validation (kind `1617`, unified diff), per-file tab loading, patch metadata display, the live patch-thread reply subscription, and publishing the reviewer's inline comments as kind:1 replies under a configured identity (local key or NIP-46 bunker), including reply-to-reply and bunker-sign-failure degradation. No CLI, no git, no agent orchestration.

## Test Approach

- **Automated (Swift Testing + TCA `TestStore`)**: `PatchOpenFeature` reducer — reference validation, fetch effect with a stubbed `RelayClient`, success→`sessionLoaded`, each `PatchOpenError` mapping. `PatchParser` — per-file splitting, kind/diff validation. `PatchReplyMapper` — kind:1 root filter, bot/human flag, line-anchor parse, dedup. `NostrSigner` — local-key signing determinism; bunker path with a stubbed NIP-46 client; sign-failure → degrade. Publish dedup by event id.
- **Automated (unit)**: `Bech32` decode of `nevent1` (event id + relay hints); `naddr` rejection; hex-id validation.
- **Manual (iPhone + iPad, iOS 17+, real or sandbox relays + a test bunker)**: end-to-end open + live thread + publish; identity indicator states; Settings configuration; relay-failure tolerance.

## Coverage Matrix

### In-app patch open

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sri-patch-open-happy` | `TC-sri-patch-open-happy`, `TC-sri-patch-parser-unit` | Not started |
| `AC-sri-patch-open-nevent` | `TC-sri-patch-open-nevent` | Not started |
| `AC-sri-patch-open-invalid-id` | `TC-sri-patch-open-invalid-id` | Not started |
| `AC-sri-patch-open-not-found` | `TC-sri-patch-open-not-found` | Not started |
| `AC-sri-patch-open-wrong-kind` | `TC-sri-patch-open-wrong-kind` | Not started |
| `AC-sri-patch-open-bad-diff` | `TC-sri-patch-open-bad-diff` | Not started |
| `AC-sri-patch-open-no-relays` | `TC-sri-patch-open-no-relays` | Not started |

### Patch-thread reply publishing

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sri-identity-load` | `TC-sri-identity-load-local`, `TC-sri-identity-load-bunker`, `TC-sri-identity-none` | Not started |
| `AC-sri-bunker-connect` | `TC-sri-bunker-connect-happy`, `TC-sri-bunker-connect-fails` | Not started |
| `AC-sri-bunker-sign` | `TC-sri-bunker-sign` | Not started |
| `AC-sri-bunker-sign-failure` | `TC-sri-bunker-sign-failure` | Not started |
| `AC-sri-comment-publish` | `TC-sri-comment-publish`, `TC-sri-comment-publish-no-identity` | Not started |
| `AC-sri-reply-to-reply` | `TC-sri-reply-to-reply` | Not started |
| `AC-sri-publish-no-dup` | `TC-sri-publish-no-dup` | Not started |
| `AC-sri-publish-relay-failure` | `TC-sri-publish-relay-failure` | Not started |
| `AC-sri-patch-open-activates-thread` | `TC-sri-thread-live`, `TC-sri-thread-inline-anchor` | Not started |

## Test Cases

### In-app patch open

#### `TC-sri-patch-open-happy` — Open a valid patch (Automated reducer + Manual)
1. Empty state → tap **Open Patch** → paste a 64-char hex id for a kind `1617` event whose content is a unified diff → submit.
- **Expected**: The app fetches in-process, splits the diff into one tab per changed file (named by path), attaches metadata (author, message, parent if present, status `open`, repo coordinate if present), and enters the review layout — no shell process, no git. (`AC-sri-patch-open-happy`)

#### `TC-sri-patch-parser-unit` — Diff splits per file (Automated, `PatchParser`)
1. Feed a sample kind `1617` event with a 3-file unified diff.
- **Expected**: 3 file blocks, each named by its path, content = that file's diff block. A non-`1617` kind → `.wrongKind`; a non-`diff --git` content → `.badDiff`. (`AC-sri-patch-open-happy`, supports `AC-sri-patch-open-wrong-kind`/`bad-diff`)

#### `TC-sri-patch-open-nevent` — nevent1 reference (Automated + Manual)
1. Paste a `nevent1…` encoding a patch event id with relay hints.
- **Expected**: The app decodes it, prefers the encoded relays, fetches, and proceeds as happy. (`AC-sri-patch-open-nevent`)

#### `TC-sri-patch-open-invalid-id` — Invalid reference rejected inline (Automated + Manual)
1. Submit text that is neither 64-char hex nor `nevent1` (e.g. an `naddr1…`, or garbage).
- **Expected**: Inline message "Enter a 64-character hex event id or a nevent1 reference"; no fetch; sheet stays open. (`AC-sri-patch-open-invalid-id`)

#### `TC-sri-patch-open-not-found` — Event not on relays (Automated + Manual)
1. Submit a valid 64-char id no relay has.
- **Expected**: After the wait window, "Patch event <short-id> not found on the configured relays."; no review starts. (`AC-sri-patch-open-not-found`)

#### `TC-sri-patch-open-wrong-kind` — Non-patch event rejected (Automated + Manual)
1. Submit the id of a kind:1 note (and separately a kind:1621 issue) that exists on the relays.
- **Expected**: "Event <short-id> is not a NIP-34 patch (kind <k>)."; no review starts. (ids-only filter returns the event so it can be rejected here.) (`AC-sri-patch-open-wrong-kind`)

#### `TC-sri-patch-open-bad-diff` — Malformed diff rejected (Automated + Manual)
1. Submit a kind `1617` event whose content lacks `diff --git` / `@@` hunks.
- **Expected**: "Patch event <short-id> does not contain a valid unified diff."; no review starts. (`AC-sri-patch-open-bad-diff`)

#### `TC-sri-patch-open-no-relays` — No relays reachable (Manual)
1. With all configured relays unreachable, submit a valid reference.
- **Expected**: "No Nostr relays reachable — check your relay configuration."; no fetch attempted. (`AC-sri-patch-open-no-relays`)

### Patch-thread reply publishing

#### `TC-sri-identity-load-local` — Local-key identity loaded (Automated + Manual)
1. In Settings, enter a valid `nsec`; save.
- **Expected**: The indicator shows a key glyph + the reviewer's display name (or truncated npub); the pubkey is derived. (`AC-sri-identity-load`)

#### `TC-sri-identity-load-bunker` — Bunker identity loaded (Manual)
1. In Settings, enter a valid `bunker://` URI; save.
- **Expected**: The indicator shows a shield glyph + name + `BUNKER` capsule + a status dot that goes green once `connect`/`get_public_key` completes. (`AC-sri-identity-load`, `AC-sri-bunker-connect`)

#### `TC-sri-identity-none` — No identity (Manual)
1. Leave identity unset.
- **Expected**: The indicator shows "No identity — replies won't publish" with a hint; no publish action; comments save locally. (`AC-sri-identity-load`)

#### `TC-sri-bunker-connect-happy` — Bunker handshake (Manual)
1. Configure a reachable bunker; open a patch review.
- **Expected**: The control channel opens, `connect` (with `secret` when present) and `get_public_key` succeed, the identity shows connected. (`AC-sri-bunker-connect`)

#### `TC-sri-bunker-connect-fails` — Bunker unreachable/refuses (Manual)
1. Configure a bunker URI pointing at an unreachable/refusing signer.
- **Expected**: The identity is unavailable for publishing, the indicator reflects failure, read-only review and local commenting remain available. (`AC-sri-bunker-connect`)

#### `TC-sri-bunker-sign` — Reply signed by bunker (Manual)
1. With a connected bunker (no local key), submit an inline comment.
- **Expected**: A `sign_event` request is sent, the signed event returns, is published under the reviewer's pubkey, and the reply appears immediately inline and in the Thread section — without the secret key on device. (`AC-sri-bunker-sign`, `AC-sri-comment-publish`)

#### `TC-sri-bunker-sign-failure` — Bunker sign failure degrades (Automated + Manual)
1. With a bunker identity that cannot sign (drop the channel or refuse), submit a comment.
- **Expected**: The editor reopens with "Couldn't publish reply — the bunker didn't respond. Your comment is saved locally.", the indicator turns red, the local comment is retained; retry succeeds. (`AC-sri-bunker-sign-failure`)

#### `TC-sri-comment-publish` — Comment publishes on submit (Automated + Manual)
1. With a local-key identity loaded, submit an inline comment anchored to a file + line range.
- **Expected**: A kind:1 reply is signed and published with the patch as root, the repo `a` tag, and a matching line-range anchor; it appears immediately inline and in the Thread section. (`AC-sri-comment-publish`)

#### `TC-sri-comment-publish-no-identity` — No identity → local only (Automated + Manual)
1. With no identity, submit a comment.
- **Expected**: The comment is recorded locally only; the reviewer is informed it was not published; the button reads "Save locally". (`AC-sri-comment-publish`)

#### `TC-sri-reply-to-reply` — Respond to a reply (Manual)
1. From a thread reply by another participant, tap its **Reply** affordance; submit.
- **Expected**: A kind:1 note is published with root `e` on the patch, reply `e` on the target, and a `p` tag naming its author; the response appears alongside the target. (`AC-sri-reply-to-reply`)

#### `TC-sri-publish-no-dup` — Published reply not duplicated (Automated + Manual)
1. Publish a reply; let the same event arrive back over the live subscription.
- **Expected**: It is not rendered twice (deduped by event id). (`AC-sri-publish-no-dup`)

#### `TC-sri-publish-relay-failure` — Relay failure tolerated (Manual)
1. Submit a reply with some relays unreachable.
- **Expected**: If ≥1 relay accepts, the publish succeeds with no hard error; if none accept, the reviewer is informed and the local copy is retained. (`AC-sri-publish-relay-failure`)

#### `TC-sri-thread-live` — Live thread updates (Manual)
1. Open a patch; have another participant publish a reply to the same patch.
- **Expected**: The reply appears in the Thread section (and inline if anchored) without re-opening. (`AC-sri-patch-open-activates-thread`)

#### `TC-sri-thread-inline-anchor` — Anchored reply renders inline (Manual)
1. A patch-thread reply carrying a line-range anchor arrives.
- **Expected**: It renders inline at its anchor in the CodeViewer, visually distinct from the reviewer's own editable comments, with the bot/human marker. (`AC-sri-patch-open-activates-thread`, `FR-sr-patch-replies-display`)

## Out of Scope

- All CLI/agent-orchestration criteria (`AC-sr-*` for changeset detection, filtering, ordering, context generation, launcher, install, interactive prompt, completion summary, feedback handoff): no CLI on iOS.
- `AC-sr-patch-application-*`: no git apply on iOS (in-app load from the event only).
- macOS in-app patch open (`AC-srm-patch-open-*`): covered by `qa/macos/shepherd-review.md`; the iOS cases here are the iOS ports.
