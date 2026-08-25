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
- `FR-sr-pr-source` — realized by `FR-sri-patch-open-entry` / `FR-sri-patch-open-input` / `FR-sri-patch-open-fetch` (shared fetch path dispatches on kind) plus `FR-sri-pr-open-patches` / `FR-sri-pr-open-load`. The iOS PR path does not use the shared git-fetch acquisition (`FR-sr-pr-diff-acquisition`); see "In-app PR open (iterate patches)" below.

### Apply as-is

- `FR-sr-relay-client` — In-process Nostr relay client. The iOS app subscribes and publishes over the same in-process relay transport, resolving relay URLs from in-app configuration (see `FR-sri-identity-load` note and Open Questions) with a default public fallback.
- `FR-sr-patch-replies-display` — Display other participants' patch-thread replies (inspector section + inline at anchors, bot/human markers). Applies unchanged.
- `FR-sr-patch-replies-live` — Live subscription for new replies during the review. Applies unchanged.
- `FR-sr-patch-metadata-display` — Display patch metadata (author, message, parent, status, repo coordinate, event id). Applies, with the v1 status caveat below.

### Modified on iOS

- **`FR-sr-patch-fetch`** — Does not apply in its shared (shell `nak`) form. The iOS app fetches the patch event in-process by event id over the relay client. See `FR-sri-patch-open-fetch`.
- **`FR-sr-patch-validation`** — Modified to the NIP-34-correct kind set: the iOS path reviews kind `1617` (patch) and kind `1618` (pull request). Kind `1621` is an issue, not a patch, and is rejected. A kind `1618` event is routed to the PR load path (`FR-sri-pr-open-patches`) rather than diff-validated as a patch. See `FR-sri-patch-open-fetch`. (This matches the macOS in-app path's correction; see `../macos/shepherd-review.md` Open Question 5.)
- **`FR-sr-patch-application`** — Does not apply. No local git repository and no temporary review branch; the patch is loaded from the event contents alone. See `FR-sri-patch-open-load`.
- **`FR-sr-pr-diff-acquisition`** — Does not apply in its shared (git-fetch) form. iOS has no git binary and invokes no shell process (`NFR-sri-no-git`), so it cannot fetch the PR's `clone` URL and run `git diff`. Instead the iOS PR path acquires the diff by fetching the kind `1617` patch events the PR references via `e` tags and unioning their inline diffs. See `FR-sri-pr-open-patches`.
- **`FR-sr-pr-fetch`** — Does not apply in its shared (CLI) form. The iOS app fetches the PR event in-process by event id over the relay client, reusing the same fetch path as patches (`FR-sri-patch-open-fetch`), then dispatches on kind. See `FR-sri-patch-open-fetch`.
- **`FR-sr-patch-metadata-display`** (status) — Patch status is shown as `open` unconditionally in v1. NIP-34 conveys status via separate kind `1630`–`1633` status events, not a tag on the patch event; fetching them is a shared roadmap fast-follow (`../../roadmap/patch-watcher.md`).

### Do not apply on iOS

None of the CLI/agent-orchestration requirements apply — there is no slash command, no local git, no agent conversation, and no terminal handoff:

- `FR-sr-changeset-detection`, `FR-sr-scope-argument`, `FR-sr-file-filtering`, `FR-sr-priority-ordering`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-context-handoff`, `FR-sr-multi-file-launch`, `FR-sr-feedback-collection`, `FR-sr-completion-summary`, `FR-sr-iteration-loop`, `FR-sr-file-list-display`, `FR-sr-git-required`, `FR-sr-command-file`, `FR-sr-install`
- `FR-sc-session-id`, `FR-sc-session-scoped-output`, `FR-sc-file-api`
- `NFR-sr-agent-native`, `NFR-sr-cross-platform`, `NFR-sr-no-dependencies`, `NFR-sr-startup-speed`

## iOS-Specific Functional Requirements

### In-app patch open

These requirements are the iOS port of the macOS in-app patch open (`../macos/shepherd-review.md`, In-app patch open). The reviewer is in the app's empty state and initiates the patch review themselves; the app fetches the NIP-34 patch event in-process and loads it using only what the event contains. No local git repository is required and no shell process is invoked.

#### `FR-sri-patch-open-entry` — Empty state exposes an "Open Patch or PR" affordance
The app's empty state exposes an "Open Patch or PR" affordance as the primary entry point. Activating it opens a lightweight entry sheet in which the reviewer enters or pastes a NIP-34 patch or PR reference. The same entry serves both kinds: the app fetches the event by id and dispatches on its kind — kind `1617` loads as a patch (`FR-sri-patch-open-load`), kind `1618` loads as a PR (`FR-sri-pr-open-patches`). This affordance is present only in the empty state; it is not shown once a review is loaded. It does not invoke any slash command or shell process.

#### `FR-sri-patch-open-input` — Accept a patch or PR event reference and validate its format
The Open Patch or PR entry accepts a reference in either of two forms:
1. A 64-character hex Nostr event id.
2. A NIP-19 `nevent1…` bech32 entity that encodes a patch or PR event (decoded to its referenced event id and relays).

A `naddr1…` reference is not accepted (NIP-34 patches and PRs are kind `1617`/`1618`, non-parameterized, with no `naddr` form). Leading/trailing whitespace is trimmed. An input matching neither form is rejected inline with a clear message and the entry stays open; no fetch is attempted.

#### `FR-sri-patch-open-fetch` — Fetch and validate the NIP-34 patch event in-process
When the reviewer submits a valid reference, the app fetches the patch event in-process using the relay client (`FR-sr-relay-client`): a NIP-01 subscription whose filter is the event id only (`{"ids": ["<id>"]}`), with no `kinds` filter, across the configured relays. Fetching by `ids` alone lets the app receive the event whatever its kind, then reject non-patch kinds explicitly with a precise error. When the decoded `nevent1` carries relay hints, those relays are preferred. The first matching event is taken and the subscription is cancelled immediately. The app then validates:

- **Event kind**: must be `1617` (NIP-34 patch) or `1618` (NIP-34 pull request). Any other kind is rejected with "Event <short-id> is not a NIP-34 patch or PR (kind <k>)." In particular a kind:1 note or a kind:1621 issue produces this error. A kind `1617` event is validated and routed to the patch load path (`FR-sri-patch-open-load`); a kind `1618` event is routed to the PR load path (`FR-sri-pr-open-patches`) and is not diff-validated here (its content is markdown, not a diff). This dispatch is the iOS counterpart of the macOS in-app kind dispatch; iOS realizes the shared `FR-sr-pr-source` this way rather than via the git-fetch acquisition (`FR-sr-pr-diff-acquisition`), because iOS has no git and invokes no subprocess (`NFR-sri-no-git`).
- **Diff format** (patch path only): the content of a kind `1617` event must be a valid unified diff beginning with `diff --git` and containing `+++`/`---` headers and `@@` hunks. A malformed diff is rejected with "Patch event <short-id> does not contain a valid unified diff."

A fetch that returns no event within the relay wait window is rejected with "Patch event <short-id> not found on the configured relays." If no relay is reachable, the entry reports "No Nostr relays reachable — check your relay configuration." and no review is started.

#### `FR-sri-patch-open-load` — Load the patch for review from the event alone
On a successfully fetched and validated patch event, the app loads a patch review session using only the event's contents — no local git repository and no temporary review branch:

1. **Parse the unified diff per file.** The diff is split on each `diff --git a/<path> b/<path>` boundary into one block per changed file. Each block becomes a tab in the file browser, named by the file path, with the block's diff text as the tab's content. (v1 review surface: the reviewer annotates the diff. Full-file reconstruction is a roadmap fast-follow, shared with macOS.)
2. **Attach patch metadata.** The app builds a patch metadata record from the event — full and short event id, author (event pubkey, resolved to a display name via the roster when available), commit message (the first line of the event content), parent commit short hash (from a `parent-commit` tag, if present), repo coordinate (the `a` tag, when present), and status `open` (v1) — and sets it on the session. This activates the patch metadata section, the live patch-thread reply subscription (`FR-sr-patch-replies-live`), and the reply-publishing path (`FR-sri-comment-publish-on-submit`).
3. **Enter the review.** The empty state is replaced by the standard multi-file review layout (one tab per changed file), adapted to the form factor per `FR-crp-ios-adaptive-layout`. The reviewer adds inline comments on the diff and publishes them to the patch thread under their identity exactly as in a CLI-launched patch review.

There is no agent-generated neutral/review context for an in-app-opened patch (no LLM runs in this path); per-file review context is absent and the review-context panel hides for tabs that have none.

### In-app PR open (iterate patches)

These requirements add an in-app way to start a PR review on iOS. Unlike macOS, which acquires a PR's diff by shelling out to `git` to fetch the PR's `clone` URL and compute `git diff <merge-base>..<c>` (`FR-sr-pr-diff-acquisition`), iOS has no git binary and invokes no shell process (`NFR-sri-no-git`). Instead the iOS PR path acquires the diff from the kind `1617` patch events the PR references via `e` tags: NIP-34 documents an `e` tag referencing a patch this PR revises, and the app reads all `e` tags as a superset (in practice most PRs carry 0 or 1 such tag; reading every `e` tag is a harmless superset that also tolerates a PR referencing multiple patches). Each referenced patch event's content is an inline unified diff — exactly what iOS already reviews with zero git. The app fetches the PR event, fetches each referenced patch event over the same relay client, splits and unions their diffs into one changeset, and attaches PR metadata with the PR event as the thread root.

The reviewer enters the PR reference in the same Open Patch or PR dialog (`FR-sri-patch-open-entry` / `FR-sri-patch-open-input`); the shared fetch path (`FR-sri-patch-open-fetch`) fetches by id and dispatches on kind. This adds no new entry surface and no new identity path; once loaded, the review surface and bidirectional thread loop are the ones already specified for patches.

#### `FR-sri-pr-open-patches` — Acquire the PR diff by iterating its referenced patch events
When the fetched event is kind `1618`, the app reads the PR event's `e` tags that point at kind `1617` patch events and fetches each referenced patch event in-process over the relay client (`FR-sr-relay-client`), reusing the same fetch-by-id path as a standalone patch open. For each referenced patch event:

1. **Fetch.** The app opens a NIP-01 subscription whose filter is the referenced event id only (`{"ids": ["<id>"]}`), with no `kinds` filter, across the configured relays (and the `nevent` relay hints when the reference came in that form). The first matching event is taken and the subscription is cancelled immediately.
2. **Validate.** The fetched event must be kind `1617` and its content a valid unified diff (the same validation as `FR-sri-patch-open-fetch` patch path). A referenced event that is not kind `1617`, or whose diff is malformed, is skipped with a warning recorded against the PR review (the PR still loads from any remaining valid referenced patches); a referenced event that cannot be fetched within the relay wait window is skipped with a not-found warning.
3. **Split.** The valid patch's diff is split on each `diff --git a/<path> b/<path>` boundary into one block per changed file (the existing splitter).

The per-file diff blocks from every successfully fetched referenced patch are unioned into one changeset. When the same file path appears in more than one referenced patch, the blocks are concatenated in the order their patch events were fetched (tab content is the concatenated diff text); the reviewer sees one tab per distinct file path. This concatenation is safe for the v1 display-only diff-as-tabs surface, but a multi-patch tab stitches hunks computed against different base versions, so inline comment line anchors on such a tab may misalign against any single base, and full-file reconstruction on a concatenated tab will fail (the general full-file-reconstruction caveat in `FR-sri-patch-open-load` covers this; the multi-patch case is the specific instance QA should expect). If **no** `e` tags referencing kind `1617` patches are present on the PR event, or none of the referenced patches could be fetched or validated, the app does not start a review and reports "PR <short-id> has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS." This is the graceful-degradation case for git-only PRs (see Open Questions).

> ponytail: no git, no subprocess, no new dependency. The PR's diff is reconstructed from events that already contain it inline. A PR whose changes exist only on the clone server and were never published as patch events cannot be reviewed on iOS in v1; that is the documented ceiling, not a bug.

#### `FR-sri-pr-open-load` — Load the PR for review from the unioned patch diffs
On a successfully unioned changeset (at least one referenced patch produced diff blocks), the app loads a PR review session:

1. **Tabs per changed file.** Each distinct file path from the unioned changeset becomes a tab in the file browser, named by the file path, with the unioned diff text for that file as the tab's content. (Same v1 diff-as-tabs surface and full-file-reconstruction caveat as in-app patches.)
2. **Attach PR metadata.** The app builds a patch metadata record from the PR event — full and short event id, author (event pubkey, resolved to a display name via the roster when available), commit message (the PR `subject` tag, or the first non-empty line of the content), parent commit short hash (from the PR event's `merge-base` tag if present, else left nil), repo coordinate (the `a` tag, when present), and status `open` (v1, same status-event caveat as patches) — and sets it on the session. This activates the metadata section, the live patch-thread reply subscription (`FR-sr-patch-replies-live`), and the reply-publishing path (`FR-sri-comment-publish-on-submit`), with the PR event as the thread root.
3. **Enter the review.** The empty state is replaced by the standard multi-file review layout (one tab per changed file), adapted to the form factor per `FR-crp-ios-adaptive-layout`. The reviewer adds inline comments on the diff and publishes them to the PR thread under their identity exactly as in a patch review.

There is no agent-generated neutral/review context for an in-app-opened PR (no LLM runs in this path); per-file review context is absent and the review-context panel hides for tabs that have none.

### Relay configuration

#### `FR-sri-relay-settings` — Configure Nostr relays in-app
The reviewer configures the Nostr relays the app subscribes and publishes to from a Settings surface inside the app — the iOS counterpart to macOS's `NOSTR_RELAYS` env var and `~/.config/nostr/relays.txt` (`FR-sr-relay-client`), since iOS exposes neither to the user. The reviewer can add and remove relay URLs and toggle a "use defaults" mode that resets to the default public relay set (the same defaults the macOS client falls back to). A saved custom list is persisted across launches and takes effect for every subsequent subscription and publish (relay hints encoded in a `nevent1` reference still take preference for that fetch, per `FR-sri-patch-open-fetch`). A relay URL that is not a valid `wss://`/`ws://` URL is rejected with an inline validation message and is not saved. When no custom list is saved, the default public relay set is used.

Identity is configured in the Identity sheet (`./identity.md`), not in Settings; Settings links out to it. On macOS the same Settings surface is offered for parity (`FR-srm-relay-settings`), reachable from the app menu (⌘,); the out-of-band env/file sources continue to apply when no in-app list is saved.

### Patch-thread reply publishing (bidirectional)

These are the iOS implementation of the shared `FR-sr-patch-reply-publish`, `FR-sr-reviewer-identity`, and `FR-sr-patch-reply-respond`, ported from the macOS variants (`../macos/shepherd-review.md`). They apply only to patch reviews; there is no non-patch review on iOS.

#### `FR-sri-identity-load` — Load the reviewer's Nostr identity
The app loads a reviewer-owned Nostr identity so the reviewer can publish signed replies to patch threads. The identity takes one of two forms, both configured by the reviewer in-app via the Identity feature (see `./identity.md`): the reviewer pastes an existing local key or bunker URI, or generates a brand-new local key in-app (`FR-id-create-new`). The identity-load requirement here covers how the loaded identity is used for publishing; the login/create/persist/logout surface is specified in `./identity.md`.

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

#### `NFR-sri-no-git` — No local git repository or git tooling required
In-app patch review requires no local git repository, no git tooling, and no shell subprocess. The patch is loaded from the event contents alone, fetched over the relay client in-process. Because the app invokes no shell process, it cannot run `git` to fetch objects or compute a diff — so NIP-34 pull requests (kind `1618`) are reviewed on iOS via the inline diffs of the kind `1617` patch events the PR references (`FR-sri-pr-open-patches`), not via the git-fetch acquisition macOS uses (`FR-sr-pr-diff-acquisition`). A git-only PR whose changes were never published as patch events cannot be reviewed on iOS in v1; that graceful-degradation case is the documented ceiling (see Open Questions).

#### `NFR-sri-platform-restriction` — iOS only
The app targets iOS and runs on iPhone and iPad. It is not available on other operating systems.

## Acceptance Criteria

### In-app patch open

- [ ] **Open Patch from empty state** `AC-sri-patch-open-happy`: Given the app is in its empty state, when the reviewer opens the "Open Patch" affordance, pastes a 64-character hex event id for a valid NIP-34 patch (kind `1617`) whose content is a unified diff, and submits, then the app fetches the event in-process, splits the diff into one tab per changed file named by file path, attaches patch metadata (author, message, parent, status `open`, repo coordinate), and enters the review layout with the patch metadata section, live patch-thread replies, and reply-publishing path active — without invoking any shell process and without a local git repository.
- [ ] **nevent reference accepted** `AC-sri-patch-open-nevent`: Given the reviewer pastes a `nevent1…` reference encoding a patch event id, when the app decodes it, then it fetches from the relays encoded in the reference (preferred) and proceeds as in `AC-sri-patch-open-happy`.
- [ ] **Invalid reference rejected inline** `AC-sri-patch-open-invalid-id`: Given text that is neither a 64-char hex id nor a `nevent1`, when submitted, then the entry shows a clear message, no fetch is attempted, and the entry stays open.
- [ ] **Patch event not found** `AC-sri-patch-open-not-found`: Given no event with the id exists on the configured relays, when the wait window elapses with no match, then the entry reports "Patch event <short-id> not found on the configured relays." and no review starts.
- [ ] **Non-patch/PR event rejected** `AC-sri-patch-open-wrong-kind`: Given the id of a kind:1 note (or kind:1621 issue, or any event that is not kind `1617` or `1618`) that exists, when fetched and validated, then the entry reports "Event <short-id> is not a NIP-34 patch or PR (kind <k>)." and no review starts. A kind `1618` event is routed to the PR load path (`AC-sri-pr-open-happy`), not rejected here.
- [ ] **Malformed diff rejected** `AC-sri-patch-open-bad-diff`: Given the fetched content does not begin with `diff --git` or lacks valid `@@` hunks, then the entry reports "Patch event <short-id> does not contain a valid unified diff." and no review starts.
- [ ] **No relays reachable** `AC-sri-patch-open-no-relays`: Given no configured relay is reachable, when the reviewer submits, then the entry reports "No Nostr relays reachable — check your relay configuration." and no fetch is attempted.

### Relay configuration

- [ ] **Defaults active** `AC-sri-relay-defaults`: Given the reviewer has never saved a custom relay list, when Settings is opened, then it shows the "use defaults" mode active with the default public relay set displayed, and subscriptions/publishes use exactly that set.
- [ ] **Custom relays saved and used** `AC-sri-relay-custom`: Given the reviewer enters one or more valid `wss://`/`ws://` URLs and saves, then the list persists, subsequent subscriptions and publishes contact exactly the saved relays, and reopening Settings shows the saved list.
- [ ] **Invalid relay URL rejected inline** `AC-sri-relay-invalid`: Given the reviewer enters text that is not a valid `wss://`/`ws://` URL, when adding it, then Settings shows an inline validation message, the URL is not added, and the saved list is unchanged.
- [ ] **Defaults restored** `AC-sri-relay-persist`: Given a custom list is saved, when the reviewer re-enables "use defaults", then the default public relay set is used again (the custom list is cleared) and the change persists across launches.

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

### In-app PR open (iterate patches)

- [ ] **Open PR from empty state (happy path)** `AC-sri-pr-open-happy`: Given the app is in its empty state, when the reviewer opens the "Open Patch or PR" affordance, pastes a 64-character hex event id for a valid NIP-34 PR (kind `1618`) that references one or more kind `1617` patch events via `e` tags, and submits, then the app fetches the PR event in-process, fetches each referenced patch event in-process over the relay client, splits and unions their inline diffs into one tab per distinct changed file, attaches PR metadata (author, subject, parent/merge-base if present, status `open`, repo coordinate, short event id), and enters the review layout with the metadata section, live thread replies, and reply-publishing path active — with the PR event as thread root, no shell process invoked, and no local git repository required.

- [ ] **PR with no patch references rejected** `AC-sri-pr-open-no-patches`: Given a kind `1618` PR event whose changes exist only on its `clone` URL (no `e` tags referencing kind `1617` patches), when the reviewer submits its id, then the entry reports "PR <short-id> has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS." and no review is started.

- [ ] **Referenced patch not found is skipped** `AC-sri-pr-open-patch-not-found`: Given a PR references two kind `1617` patch events but one does not exist on the configured relays, when the app fetches the referenced patches, then the missing patch is skipped with a not-found warning and the PR still loads from the remaining valid patch (one tab per changed file in that patch).

- [ ] **Referenced event of wrong kind is skipped** `AC-sri-pr-open-patch-wrong-kind`: Given a PR references an event that, when fetched, is kind `1621` (an issue) rather than kind `1617`, when the app validates the referenced event, then it is skipped with a warning and the PR still loads from any remaining valid referenced patches.

- [ ] **PR metadata displayed** `AC-sri-pr-open-metadata`: Given a PR event with a `subject` tag and a `merge-base` tag, when the review opens, then the metadata section displays the author (display name if known, else short pubkey), subject, merge-base short hash if present, status `open`, repo coordinate, and short event id.

- [ ] **In-app opened PR activates the thread** `AC-sri-pr-open-activates-thread`: Given an in-app-opened PR review, when new replies arrive over the live subscription, then they appear in the patch-thread section and inline at their anchors, and submitting a comment with an identity publishes to the PR thread (root `e` tag on the PR event) under that identity — with the PR event as thread root, identical to a patch review.

## Open Questions

1. **Relay configuration UI**: Resolved by `FR-sri-relay-settings` — in-app Settings with add/remove relay URLs, a "use defaults" toggle, and the default public relay set as fallback, mirroring the identity configuration path. Design: `../../design/ios/shepherd-review.md` (Settings (Relays)).

2. **Identity persistence**: Resolved by `./identity.md` — the identity persists across launches via the iOS Keychain (`FR-id-ios-keychain-storage`), not in-memory only. See `./identity.md` for the full login/create/persist/logout flow.

3. **Roster / display-name resolution on iOS**: The macOS app resolves author display names via a roster file. iOS has no dotfiles. Does the iOS app ship a bundled roster, fetch NIP-05, or show truncated npubs only for v1? Deferred — truncated npub is the safe fallback; richer resolution is a follow-up.

4. **Same NIP-34 spec corrections as macOS**: The shared `product/shepherd-review.md` kind set and status-tag claims are pre-existing errors (see `../macos/shepherd-review.md` Open Question 5). The iOS path is written NIP-34-correctly and does not inherit them. Correcting the shared spec is a separate follow-up, shared with the macOS path.

5. **Git-only PRs on iOS**: iOS reviews a kind `1618` PR via the inline diffs of the kind `1617` patch events the PR references (`FR-sri-pr-open-patches`), reusing the existing patch infrastructure with no git and no subprocess. A PR whose changes exist only on its `clone` server and were never published as patch events (no valid `e`-tagged kind `1617` references) cannot be reviewed on iOS in v1 and is rejected with a message pointing the reviewer to macOS. Covering those PRs without a local git client would require a remote diff endpoint (e.g. a grasp server or HTTP `diff <base>..<tip>` service); deferred to a roadmap follow-up.

## Dependencies

- Shared `shepherd-review` requirements (`../shepherd-review.md`) — patch metadata display, live replies, reply publishing contracts.
- macOS in-app patch open (`../macos/shepherd-review.md`, In-app patch open) — the pattern this ports; same NIP-34-correct kind/diff handling.
- iOS CRPG requirements (`./code-review-prompt.md`) — the review surface (file tabs, commenting, prompt preview) that the opened patch loads into.
