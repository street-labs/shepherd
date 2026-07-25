# Shepherd Review — iOS Platform

> iOS-specific requirements for Shepherd Review. See `../shepherd-review.md` for shared requirements.
> See also `./code-review-prompt.md` for the CRPG review surface that the opened patch loads into.

The iOS variant has no CLI, no slash command, and no local git repository. Its sole review entry point is the in-app opened NIP-34 patch, ported from the macOS in-app patch open (`../macos/shepherd-review.md`, In-app patch open). Once a patch is loaded, the patch-thread review loop is bidirectional exactly as on macOS: the reviewer reads other participants' replies and publishes their own comments back to the thread under their Nostr identity.

## Shared Requirements — Applicability on iOS

### Implemented via iOS-specific requirements

The following shared requirements describe platform-neutral behavior that the iOS variant realizes through the iOS-specific requirements in the "Patch-thread reply publishing" and "In-app patch open" sections below:

- `FR-sr-patch-reply-publish` — realized by `FR-sri-comment-publish-on-submit` + `FR-sri-event-sign` + `FR-sri-event-publish`
- `FR-sr-reviewer-identity` — realized by `FR-sri-identity-load` + `FR-sri-identity-indicator`
- `FR-sr-bunker-signing` — realized by `FR-sri-bunker-connect` + the bunker half of `FR-sri-event-sign`
- `FR-sr-patch-reply-respond` — realized by `FR-sri-reply-to-reply`
- `FR-sr-patch-source` — realized by `FR-sri-patch-open-entry` through `FR-sri-patch-open-load`

### Apply as-is

- `FR-sr-relay-client` — In-process Nostr relay client. The iOS app subscribes and publishes over the same in-process relay transport, resolving relay URLs from in-app configuration (see `FR-sri-identity-load` note and Open Questions) with a default public fallback.
- `FR-sr-patch-replies-display` — Display other participants' patch-thread replies (inspector section + inline at anchors, bot/human markers). Applies unchanged.
- `FR-sr-patch-replies-live` — Live subscription for new replies during the review. Applies unchanged.
- `FR-sr-patch-metadata-display` — Display patch metadata (author, message, parent, status, repo coordinate, event id). Applies, with the v1 status caveat below.

### Modified on iOS

- **`FR-sr-patch-fetch`** — Does not apply in its shared (shell `nak`) form. The iOS app fetches the patch event in-process by event id over the relay client. See `FR-sri-patch-open-fetch`.
- **`FR-sr-patch-validation`** — Modified to the NIP-34-correct kind set: the iOS path reviews kind `1617` (patch) only. Kind `1621` is an issue, not a patch, and is rejected. See `FR-sri-patch-open-fetch`. (This matches the macOS in-app path's correction; see `../macos/shepherd-review.md` Open Question 5.)
- **`FR-sr-patch-application`** — Does not apply. No local git repository and no temporary review branch; the patch is loaded from the event contents alone. See `FR-sri-patch-open-load`.
- **`FR-sr-patch-metadata-display`** (status) — Patch status is shown as `open` unconditionally in v1. NIP-34 conveys status via separate kind `1630`–`1633` status events, not a tag on the patch event; fetching them is a shared roadmap fast-follow (`../../roadmap/patch-watcher.md`).

### Do not apply on iOS

None of the CLI/agent-orchestration requirements apply — there is no slash command, no local git, no agent conversation, and no terminal handoff:

- `FR-sr-changeset-detection`, `FR-sr-scope-argument`, `FR-sr-file-filtering`, `FR-sr-priority-ordering`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-context-handoff`, `FR-sr-multi-file-launch`, `FR-sr-feedback-collection`, `FR-sr-completion-summary`, `FR-sr-iteration-loop`, `FR-sr-file-list-display`, `FR-sr-git-required`, `FR-sr-command-file`, `FR-sr-install`
- `FR-sc-session-id`, `FR-sc-session-scoped-output`, `FR-sc-file-api`
- `NFR-sr-agent-native`, `NFR-sr-cross-platform`, `NFR-sr-no-dependencies`, `NFR-sr-startup-speed`

## iOS-Specific Functional Requirements

### In-app patch open

These requirements are the iOS port of the macOS in-app patch open (`../macos/shepherd-review.md`, In-app patch open). The reviewer is in the app's empty state and initiates the patch review themselves; the app fetches the NIP-34 patch event in-process and loads it using only what the event contains. No local git repository is required and no shell process is invoked.

#### `FR-sri-patch-open-entry` — Empty state exposes an "Open Patch" affordance
The app's empty state exposes an "Open Patch" affordance as the primary entry point. Activating it opens a lightweight entry sheet in which the reviewer enters or pastes a NIP-34 patch reference. This affordance is present only in the empty state; it is not shown once a patch is loaded. It does not invoke any slash command or shell process.

#### `FR-sri-patch-open-input` — Accept a patch event reference and validate its format
The Open Patch entry accepts a patch reference in either of two forms:
1. A 64-character hex Nostr event id.
2. A NIP-19 `nevent1…` bech32 entity that encodes a patch event (decoded to its referenced event id and relays).

A `naddr1…` reference is not accepted (NIP-34 patches are kind `1617`, non-parameterized, with no `naddr` form). Leading/trailing whitespace is trimmed. An input matching neither form is rejected inline with a clear message and the entry stays open; no fetch is attempted.

#### `FR-sri-patch-open-fetch` — Fetch and validate the NIP-34 patch event in-process
When the reviewer submits a valid reference, the app fetches the patch event in-process using the relay client (`FR-sr-relay-client`): a NIP-01 subscription whose filter is the event id only (`{"ids": ["<id>"]}`), with no `kinds` filter, across the configured relays. Fetching by `ids` alone lets the app receive the event whatever its kind, then reject non-patch kinds explicitly with a precise error. When the decoded `nevent1` carries relay hints, those relays are preferred. The first matching event is taken and the subscription is cancelled immediately. The app then validates:

- **Event kind**: must be `1617` (NIP-34 patch). Any other kind is rejected with "Event <short-id> is not a NIP-34 patch (kind <k>)."
- **Diff format**: the content must be a valid unified diff beginning with `diff --git` and containing `+++`/`---` headers and `@@` hunks. A malformed diff is rejected with "Patch event <short-id> does not contain a valid unified diff."

A fetch that returns no event within the relay wait window is rejected with "Patch event <short-id> not found on the configured relays." If no relay is reachable, the entry reports "No Nostr relays reachable — check your relay configuration." and no review is started.

#### `FR-sri-patch-open-load` — Load the patch for review from the event alone
On a successfully fetched and validated patch event, the app loads a patch review session using only the event's contents — no local git repository and no temporary review branch:

1. **Parse the unified diff per file.** The diff is split on each `diff --git a/<path> b/<path>` boundary into one block per changed file. Each block becomes a tab in the file browser, named by the file path, with the block's diff text as the tab's content. (v1 review surface: the reviewer annotates the diff. Full-file reconstruction is a roadmap fast-follow, shared with macOS.)
2. **Attach patch metadata.** The app builds a patch metadata record from the event — full and short event id, author (event pubkey, resolved to a display name via the roster when available), commit message (the first line of the event content), parent commit short hash (from a `parent-commit` tag, if present), repo coordinate (the `a` tag, when present), and status `open` (v1) — and sets it on the session. This activates the patch metadata section, the live patch-thread reply subscription (`FR-sr-patch-replies-live`), and the reply-publishing path (`FR-sri-comment-publish-on-submit`).
3. **Enter the review.** The empty state is replaced by the standard multi-file review layout (one tab per changed file), adapted to the form factor per `FR-crp-ios-adaptive-layout`. The reviewer adds inline comments on the diff and publishes them to the patch thread under their identity exactly as in a CLI-launched patch review.

There is no agent-generated neutral/review context for an in-app-opened patch (no LLM runs in this path); per-file review context is absent and the review-context panel hides for tabs that have none.

### Patch-thread reply publishing (bidirectional)

These are the iOS implementation of the shared `FR-sr-patch-reply-publish`, `FR-sr-reviewer-identity`, and `FR-sr-patch-reply-respond`, ported from the macOS variants (`../macos/shepherd-review.md`). They apply only to patch reviews; there is no non-patch review on iOS.

#### `FR-sri-identity-load` — Load the reviewer's Nostr identity
The app loads a reviewer-owned Nostr identity so the reviewer can publish signed replies to patch threads. The identity takes one of two forms, both configured by the reviewer in-app (the app neither generates nor manages keys):

- **Local key** — a Nostr secret key (`nsec1…` or hex).
- **Bunker connection** — a NIP-46 bunker URI (`bunker://<remote-signer-pubkey>?relay=<wss-url>[&secret=<token>]`) pointing at a remote signer that holds the reviewer's secret key.

On iOS, identity configuration is entered in the app's settings (there are no environment variables or dotfiles available to the user). The secret key, when used, is held in memory for the app's lifetime and never written to unprotected storage; any persistence across launches is an engineering decision subject to platform secure-storage conventions. For a bunker connection the app holds no secret key at all — only the connection parameters and an ephemeral NIP-46 session keypair. A malformed `bunker://` URI is treated as no identity with a clear parse-error indication (`FR-sri-identity-indicator`). When no identity is configured, the app works for read-only patch review and local commenting, and reply publishing is unavailable with a clear indication.

#### `FR-sri-bunker-connect` — Establish the NIP-46 bunker control channel
When the loaded identity is a bunker connection, the app opens a NIP-46 session with the remote signer over the Nostr relay named in the bunker URI (reusing the relay client, `FR-sr-relay-client`). The app generates an ephemeral session keypair, sends a NIP-46 `connect` request NIP-44-encrypted to the bunker's pubkey, and includes the `secret` token when present. Once connected, the app obtains the reviewer's public key via `get_public_key` and uses it to attribute and display the active identity and to mark the reviewer's own replies. The control channel stays open for the life of the review window and is cancelled when the window closes. If the bunker does not respond, refuses, or `get_public_key` fails, the identity is treated as unavailable for publishing and the indicator reflects the failure, while read-only review and local commenting remain available.

#### `FR-sri-event-sign` — Sign Nostr events under the loaded identity
The app signs the Nostr events it publishes under the loaded reviewer identity, without shelling out. Signing produces a valid NIP-01 event for a kind:1 reply. The signing path has two modes:

- **Local key** — signing is in-process (secp256k1 Schnorr).
- **Bunker connection** — signing is delegated to the remote bunker: the app sends a NIP-46 `sign_event` request over the control channel and awaits the signed event.

Signing is async; the publish path awaits it before publishing. If bunker signing fails, sign returns no event and the publish path degrades per `FR-sri-bunker-sign-failure`.

#### `FR-sri-bunker-sign-failure` — Degrade gracefully when the bunker cannot sign
When a `sign_event` request fails (bunker unreachable, dropped channel, refusal, or timeout), the app does not publish and does not drop the comment. The comment is retained locally, the editor reopens with an inline error naming the bunker as the cause, and the identity indicator reflects the connection problem. The reviewer may retry. Read-only review and local commenting are unaffected.

#### `FR-sri-event-publish` — Publish signed events to relays
The app publishes signed Nostr events to the configured relays over the relay transport. Publishing sends an `EVENT` frame to each reachable relay and tolerates individual relay failures best-effort (a publish succeeds when at least one relay accepts the event). Publishing is only invoked for patch reviews when an identity is loaded.

#### `FR-sri-comment-publish-on-submit` — Submitting an inline comment publishes it as a patch-thread reply
When the reviewer submits an inline comment during a patch review and an identity is loaded, the app publishes that comment as a kind:1 patch-thread reply (`FR-sr-patch-reply-publish`) in addition to recording it locally. The published reply carries the patch event as root, the repository `a` tag, and — when the comment is anchored to a line range — a line-range anchor matching the file's path and the comment's line span. The locally-recorded comment and the published reply stay associated so the reviewer's own published reply is not duplicated when it arrives back over the live subscription. When no identity is loaded, submitting a comment records it locally only and the reviewer is informed it was not published.

#### `FR-sri-reply-to-reply` — Respond to an existing patch-thread reply from inline
The reviewer can initiate a response to an existing patch-thread reply directly from that reply's rendered surface (inspector section and inline anchored bubble). On submit, the app publishes a kind:1 note with the root `e` tag on the patch event, a reply `e` tag on the responded-to reply's event id, and a `p` tag naming that reply's author (`FR-sr-patch-reply-respond`), signed under the reviewer's identity. The response may carry a line-range anchor when pinned to a location.

#### `FR-sri-identity-indicator` — Surface the active reviewer identity
The app surfaces the active reviewer identity so the reviewer knows, before publishing, which identity their replies will be attributed to. When an identity is loaded, the indicator shows the reviewer's resolved display name (or truncated npub) at or near the patch-thread surface, and for a bunker connection a small status reflecting whether the control channel is connected, connecting, or failed. When no identity is configured, or a bunker URI is malformed or its channel could not be established, the indicator makes clear that replies will not be published and names what is needed. The indicator is present only for patch reviews.

## iOS-Specific Non-Functional Requirements

#### `NFR-sri-no-server` — No local server is started
The app does not start or rely on any local server. It is self-contained.

#### `NFR-sri-no-git` — No local git repository required
In-app patch review requires no local git repository and no git tooling. The patch is loaded from the event contents alone.

#### `NFR-sri-platform-restriction` — iOS only
The app targets iOS and runs on iPhone and iPad. It is not available on other operating systems.

## Acceptance Criteria

### In-app patch open

- [ ] **Open Patch from empty state** `AC-sri-patch-open-happy`: Given the app is in its empty state, when the reviewer opens the "Open Patch" affordance, pastes a 64-character hex event id for a valid NIP-34 patch (kind `1617`) whose content is a unified diff, and submits, then the app fetches the event in-process, splits the diff into one tab per changed file named by file path, attaches patch metadata (author, message, parent, status `open`, repo coordinate), and enters the review layout with the patch metadata section, live patch-thread replies, and reply-publishing path active — without invoking any shell process and without a local git repository.
- [ ] **nevent reference accepted** `AC-sri-patch-open-nevent`: Given the reviewer pastes a `nevent1…` reference encoding a patch event id, when the app decodes it, then it fetches from the relays encoded in the reference (preferred) and proceeds as in `AC-sri-patch-open-happy`.
- [ ] **Invalid reference rejected inline** `AC-sri-patch-open-invalid-id`: Given text that is neither a 64-char hex id nor a `nevent1`, when submitted, then the entry shows a clear message, no fetch is attempted, and the entry stays open.
- [ ] **Patch event not found** `AC-sri-patch-open-not-found`: Given no event with the id exists on the configured relays, when the wait window elapses with no match, then the entry reports "Patch event <short-id> not found on the configured relays." and no review starts.
- [ ] **Non-patch event rejected** `AC-sri-patch-open-wrong-kind`: Given the id of a kind:1 note (or kind:1621 issue, or any non-`1617` event) that exists, when fetched and validated, then the entry reports "Event <short-id> is not a NIP-34 patch (kind <k>)." and no review starts.
- [ ] **Malformed diff rejected** `AC-sri-patch-open-bad-diff`: Given the fetched content does not begin with `diff --git` or lacks valid `@@` hunks, then the entry reports "Patch event <short-id> does not contain a valid unified diff." and no review starts.
- [ ] **No relays reachable** `AC-sri-patch-open-no-relays`: Given no configured relay is reachable, when the reviewer submits, then the entry reports "No Nostr relays reachable — check your relay configuration." and no fetch is attempted.

### Patch-thread reply publishing

- [ ] **Identity configured in-app** `AC-sri-identity-load`: Given the reviewer has configured a Nostr identity in-app (local key or bunker URI), when a patch review is open, then the app loads the identity, resolves the reviewer's public key, and surfaces it per `FR-sri-identity-indicator`. Given no identity configured, then read-only review and local commenting work, the indicator shows replies will not publish, and no publish action is offered.
- [ ] **Bunker connect handshake** `AC-sri-bunker-connect`: Given a `bunker://` URI pointing at a reachable bunker, when a patch review is open, then the app opens the control channel, completes `connect` (supplying `secret` when present), obtains the pubkey via `get_public_key`, and surfaces the identity as connected. Given the bunker is unreachable or refuses, then the identity is unavailable for publishing, the indicator reflects the failure, and read-only review and local commenting remain available.
- [ ] **Reply signed by bunker** `AC-sri-bunker-sign`: Given a connected bunker identity (no local key), when the reviewer submits an inline comment, then the app sends a `sign_event` request, receives the signed event, publishes it under the reviewer's pubkey, and the reply appears immediately in the reviewer's own patch-thread section and at its anchor — without the secret key ever being on the device.
- [ ] **Bunker sign failure degrades gracefully** `AC-sri-bunker-sign-failure`: Given a bunker identity that cannot sign, when the reviewer submits a comment, then the app retains the comment locally, reopens the editor with an inline error naming the bunker, does not publish, and the reviewer can retry; on a successful retry the reply publishes.
- [ ] **Comment publishes on submit** `AC-sri-comment-publish`: Given a patch review is open and an identity is loaded, when the reviewer submits an inline comment anchored to a file and line range, then the app signs and publishes a kind:1 reply tagged with the patch event as root, the repo `a` tag, and a matching line-range anchor, and the reply appears immediately in the reviewer's own patch-thread section and at its anchor without waiting for a relay round-trip. Given no identity, when a comment is submitted, then it is recorded locally only and the reviewer is informed it was not published.
- [ ] **Respond to a reply** `AC-sri-reply-to-reply`: Given the patch thread contains a reply from another participant, when the reviewer initiates a response from that reply and submits, then the app publishes a kind:1 note with a root `e` tag on the patch event, a reply `e` tag on the responded-to reply, and a `p` tag naming that reply's author, and the response appears alongside the replied-to reply.
- [ ] **Published reply not duplicated** `AC-sri-publish-no-dup`: Given the reviewer has published a reply, when the same reply arrives back over the live subscription, then the app does not render it twice (deduplicated by event id).
- [ ] **Publish tolerates relay failure** `AC-sri-publish-relay-failure`: Given some relays are unreachable, when the app publishes, then as long as one relay accepts the event the publish succeeds without a hard error; if none accept, the reviewer is informed and the local copy is retained.
- [ ] **In-app patch open activates the thread** `AC-sri-patch-open-activates-thread`: Given an in-app-opened patch review, when new replies arrive over the live subscription, then they appear in the patch-thread section and inline at their anchors, and submitting a comment with an identity publishes to the thread — identical to a CLI-launched patch review.

## Open Questions

1. **Relay configuration UI**: macOS resolves relays from env vars / `~/.config/nostr/relays.txt`. iOS has neither. Where does the reviewer configure relays? Default decision: in-app settings with a default public relay fallback, mirroring the identity configuration path. Exact UI is a design decision.

2. **Identity persistence**: Should the iOS app persist the reviewer's identity (bunker URI, or a local key in secure storage) across launches so it need not be re-entered each session? v1 holds identity in memory for the session only; persistence is an engineering/security decision deferred to implementation.

3. **Roster / display-name resolution on iOS**: The macOS app resolves author display names via a roster file. iOS has no dotfiles. Does the iOS app ship a bundled roster, fetch NIP-05, or show truncated npubs only for v1? Deferred — truncated npub is the safe fallback; richer resolution is a follow-up.

4. **Same NIP-34 spec corrections as macOS**: The shared `product/shepherd-review.md` kind set and status-tag claims are pre-existing errors (see `../macos/shepherd-review.md` Open Question 5). The iOS path is written NIP-34-correctly and does not inherit them. Correcting the shared spec is a separate follow-up, shared with the macOS path.

## Dependencies

- Shared `shepherd-review` requirements (`../shepherd-review.md`) — patch metadata display, live replies, reply publishing contracts.
- macOS in-app patch open (`../macos/shepherd-review.md`, In-app patch open) — the pattern this ports; same NIP-34-correct kind/diff handling.
- iOS CRPG requirements (`./code-review-prompt.md`) — the review surface (file tabs, commenting, prompt preview) that the opened patch loads into.
