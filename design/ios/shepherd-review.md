---
product-hash: 3690acf162292d9c87169800429f77532c40192326fcf3225ba44915e0f24463
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-bunker-signing, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-patch-reply-publish, AC-sr-patch-reply-respond, AC-sr-pr-conflicting-args, AC-sr-pr-event-not-found, AC-sr-pr-fetch-fails, AC-sr-pr-happy-path, AC-sr-pr-metadata-displayed, AC-sr-pr-missing-tags, AC-sr-pr-wrong-kind, AC-sr-quit-early, AC-sr-reviewer-identity, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-bunker-signing, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-reply-publish, FR-sr-patch-reply-respond, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-pr-diff-acquisition, FR-sr-pr-fetch, FR-sr-pr-metadata-display, FR-sr-pr-source, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-reviewer-identity, FR-sr-scope-argument, FR-sri-relay-settings, AC-sri-relay-defaults, AC-sri-relay-custom, AC-sri-relay-invalid, AC-sri-relay-persist, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---
# Shepherd Review — iOS Design Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/ios/shepherd-review.md` for iOS-specific requirements.
> The review surface the opened patch loads into is specified in `./code-review-prompt.md`.

## What We're Designing

The iOS presentation of the in-app patch open and the bidirectional patch-thread review loop — the port of the macOS in-app patch open (`../../design/macos/shepherd-review.md`). On iOS there is no CLI, no local git, and no agent context: the reviewer opens a NIP-34 patch by event id or `nevent1`, the app fetches it in-process, and the reviewer reads other participants' replies and publishes their own comments back to the Nostr thread under their configured identity. The Open Patch sheet, the patch metadata section, the live Patch Thread section, the reviewer identity indicator, and the reply-publishing flow are specified here.

## Screen Inventory

These surfaces live within the Review State layout from `./code-review-prompt.md` (inspector right column on iPad; inspector detail screens on iPhone), plus one modal sheet presented from the Empty State.

| Surface | Compact (iPhone) | Expanded (iPad) |
|---|---|---|
| **Open Patch Sheet** | Modal sheet centered on screen. | Modal sheet, centered or form-sheet. |
| **Patch/PR Metadata Section** | Inspector "Patch Info" detail screen. | Top of the inspector right column. |
| **Patch Thread Section** | Inspector "Thread" detail screen. | Inspector right column, below metadata. |
| **Reviewer Identity Indicator** | Top of the Thread detail screen. | Above the Patch Thread section in the inspector. |
| **Inline Anchored Replies** | Inline in the CodeViewer at their anchor line. | Same. |

## Screen Definitions

### Open Patch or PR Sheet

The reviewer enters a NIP-34 patch or PR reference to start a review. The same sheet serves both kinds: the app fetches the event by id and dispatches on its kind — kind `1617` loads as a patch, kind `1618` loads as a PR (`FR-sri-pr-open-patches`).

- **Entry points**: `OpenPatchButton` in the Empty State (`./code-review-prompt.md`).
- **Layout**: A modal sheet with a title (`Open Patch or PR`), a single-line text field (`Paste a patch or PR event id or nevent1…`), a primary `Open` button, and a `Cancel` button. An inline message area below the field shows validation/fetch errors.
- **Components**:
  - `PatchReferenceField` — text field; auto-detects paste; trims whitespace.
  - `OpenButton` — disabled until the field is non-empty; shows `Opening…` during fetch.
- **States**:
  - **idle** — empty field, `Open` disabled.
  - **fetching** — `Opening…`, field and button disabled.
  - **invalid-input** — `Enter a 64-character hex event id or a nevent1 reference` inline; sheet stays open.
  - **not-found** — `Patch event <short-id> not found on the configured relays.`
  - **wrong-kind** — `Event <short-id> is not a NIP-34 patch or PR (kind <k>).`
  - **bad-diff** — `Patch event <short-id> does not contain a valid unified diff.`
  - **no-relays** — `No Nostr relays reachable — check your relay configuration.`
  - **PR — no reviewable patches** — `PR <short-id> has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS.` (`FR-sri-pr-open-patches`)
  - **success** — sheet dismisses; app transitions into the Review State (the loaded review is the confirmation).
- **Actions**: Enter reference → `Open`; on success dismiss + load; on error stay open with the message.
- **Requirements satisfied**: `FR-sri-patch-open-entry`, `FR-sri-patch-open-input`, `FR-sri-patch-open-fetch`, `FR-sri-pr-open-patches`, `FR-sri-pr-open-load`, `AC-sri-patch-open-happy`, `AC-sri-patch-open-nevent`, `AC-sri-patch-open-invalid-id`, `AC-sri-patch-open-not-found`, `AC-sri-patch-open-wrong-kind`, `AC-sri-patch-open-bad-diff`, `AC-sri-patch-open-no-relays`.

### Patch/PR Metadata Section

Read-only patch/PR orientation shown once a patch or PR is loaded.

- **Entry points**: loaded patch or PR review.
- **Layout**: A compact card. Rows: Author (display name or truncated npub), Commit message (first line — the PR `subject` for a PR), Parent (short hash, when present — the PR `merge-base` for a PR), Status badge (`open` in v1), Repo coordinate (the `a` tag, when present), Event id (short, tappable to copy full id).
- **Components**: `StatusBadge` — `open` rendered neutral for v1.
- **States**: populated (always, for a loaded patch/PR); rows with no data (no parent/merge-base tag) are omitted.
- **Actions**: Tap the event id to copy the full 64-char id.
- **Requirements satisfied**: `FR-sr-patch-metadata-display`, `FR-sr-pr-metadata-display`, `FR-sri-patch-open-load`, `FR-sri-pr-open-load` (metadata attach), `AC-sri-patch-open-happy`.

### Reviewer Identity Indicator

Surfaces which identity will sign published replies, before the reviewer publishes.

- **Entry points**: loaded patch review (always shown for patch reviews).
- **Layout**: A single row above the Patch Thread section. Glyph + label + (for bunker) status dot.
- **States**:
  - **local-key loaded** — key glyph + reviewer display name (or truncated npub). Tooltip/label carries the full npub.
  - **bunker loaded** — shield glyph + display name + status dot (`BUNKER` capsule). Status dot: green = connected, amber = connecting, red = failed.
  - **no identity** — warning glyph + `No identity — replies won't publish`, with a hint to sign in via the Identity sheet (see `./identity.md`). No publish action is offered; comments save locally only.
  - **malformed bunker** — warning glyph + the parse error; publishing unavailable.
- **Actions**: Tap to open the Identity sheet (`./identity.md`) to view, switch, or log out the active identity; relays are configured in Settings (see below).
- **Requirements satisfied**: `FR-sri-identity-load`, `FR-sri-identity-indicator`, `AC-sri-identity-load`.

### Patch Thread Section

The live conversation from other agents and humans on the patch.

- **Entry points**: loaded patch review.
- **Layout**: A section `Patch Thread (<count>)` listing every reply. Each row: author (with `BOT` badge for agent replies, person glyph for human), timestamp, content, and — when anchored — a `file:line` chip. The section is hidden entirely when there are zero replies (no empty placeholder is shown). Replies anchored to a line range also render inline in the CodeViewer at their anchor, with the same bot/human marker, visually distinct from the reviewer's own editable comments.
- **Components**: `PatchReplyRow`; `PatchReplyInlineView` (inline in CodeViewer).
- **States**: populated; live-updating (new replies prepend/animate in). The empty state is not rendered: the section is hidden when there are zero replies.
- **Actions**: Tap a reply's `Reply` affordance → opens the inline comment editor pre-targeted at that reply (`FR-sri-reply-to-reply`).
- **Requirements satisfied**: `FR-sr-patch-replies-display`, `FR-sr-patch-replies-live`, `FR-sri-reply-to-reply`, `AC-sri-patch-open-activates-thread`.

### Settings (Relays)

Where the reviewer configures their Nostr relays in-app — the iOS counterpart to macOS's `~/.config/nostr/relays.txt`. Identity is configured in the Identity sheet (`./identity.md`), not here; Settings links out to it.

- **Entry points**: app settings.
- **Layout**: A form. **Relays** section: a list of relay URLs with add/remove, plus a "use defaults" toggle. A footer link opens the Identity sheet (`./identity.md`) for login/logout/switch.
- **States**: defaults active; custom relays entered; invalid relay URL (inline validation message).
- **Actions**: Add/remove a relay; toggle "use defaults"; Save → relays take effect for the session. Open the Identity sheet via the footer link.
- **Requirements satisfied**: `FR-sri-relay-settings`, `FR-sr-relay-client` (relay resolution source on iOS); identity UI is `./identity.md` (`FR-id-ios-screen-is-only-path`).

## Interaction Flows

### Open a patch and review it

A reviewer away from their machine receives a patch event id and wants to review it.

1. Reviewer opens the app → Empty State → taps **Open Patch or PR**.
2. Pastes a 64-char hex id (or `nevent1…`) → taps **Open** → sheet shows `Opening…`.
3. The app fetches the event in-process, validates kind `1617` + diff; on success the sheet dismisses and the Review State appears with one tab per changed file, the Patch Metadata section, the identity indicator, and the live Patch Thread section.
4. Reviewer taps a line, types a comment, taps **Publish** (identity loaded) → the reply is signed and sent; it appears immediately inline and in the Thread section with a `YOU` badge.

### Reply to another participant's reply

1. Reviewer scrolls the Patch Thread section to a reply from another participant → taps its **Reply** affordance.
2. The inline comment editor opens pre-targeted at that reply; on **Publish** the app publishes a kind:1 note with root `e` on the patch, reply `e` on the target reply, and a `p` tag naming its author.
3. The response appears alongside the replied-to reply.

### Publish fails (bunker)

1. Reviewer submits a comment with a bunker identity that can't sign → the editor reopens with `Couldn't publish reply — the bunker didn't respond. Your comment is saved locally.`, the indicator's status dot turns red, and the local comment is retained.
2. Reviewer retries → on success the reply publishes.

## Component Specs

### InlineCommentEditor (publishing extension)

The editor owned by `./code-review-prompt.md` gains publish behavior for patch reviews.

- **Variants**: local-only (no identity — button reads `Save locally`); publish (identity loaded — button reads `Publish`); publishing (`Publishing…`, disabled); bunker-failed (reopens with error, `Retry`).
- **Inputs**: the comment text; anchor (line/range); identity state; target reply (when responding).
- **Behavior**: on submit with an identity, signs + publishes a kind:1 reply with the patch as root, the repo `a` tag, and a line-range anchor when anchored; records locally and dedupes the echo. On submit without identity, records locally only and informs the reviewer.
- **Requirements satisfied**: `FR-sri-comment-publish-on-submit`, `FR-sri-event-sign`, `FR-sri-event-publish`, `FR-sri-bunker-sign-failure`, `AC-sri-comment-publish`, `AC-sri-bunker-sign`, `AC-sri-bunker-sign-failure`, `AC-sri-publish-no-dup`, `AC-sri-publish-relay-failure`.

### PatchReplyRow / PatchReplyInlineView

Read-only rendered reply surfaces.

- **Variants**: inspector row; inline bubble.
- **Inputs**: a `PatchReply` (author, bot/human flag, content, timestamp, optional anchor).
- **States**: incoming; reviewer's own (subtle `YOU` badge + stronger tint, when `authorPubkey` == loaded identity pubkey).
- **Behavior**: bot replies show a robot glyph + purple tint + `BOT` badge; human replies a person glyph + orange tint. Both surfaces carry a `Reply` affordance.
- **Requirements satisfied**: `FR-sr-patch-replies-display`, `FR-sri-reply-to-reply`.

## Responsive Behavior

The Open Patch sheet and Settings are modal and present identically on both form factors (sized to the screen). The Patch Metadata, Patch Thread, and identity indicator surfaces follow the inspector placement rules from `./code-review-prompt.md` (right column on iPad; detail screen on iPhone). Inline anchored replies render in the CodeViewer on both form factors.

## Accessibility

- **Identity indicator**: exposes the full npub and the connection state ("connected" / "connecting" / "failed" / "no identity") via VoiceOver labels.
- **Patch metadata**: each row is an accessibility element; the event-id copy action has an explicit accessibility label.
- **Patch thread**: each reply row announces author, bot/human, time, and (when anchored) the `file:line` chip; the `Reply` affordance is announced as "Reply to <author>".
- **Open Patch sheet**: the field has a clear accessibility label; error messages are announced when they appear (status update).
- **Inline replies**: anchored bubbles expose their anchor line and author.

## Open Questions

1. **Relay configuration UI shape**: a plain editable list vs. a curated set of presets + custom. v1 uses an editable list with a "use defaults" toggle; exact affordance deferred.
2. **Identity persistence**: resolved — the identity persists across launches via the iOS Keychain (`FR-id-ios-keychain-storage`, see `./identity.md`). Whether to use a keychain-access-group for future iCloud Keychain sharing with the macOS app is an engineering decision (see `../../engineering/ios/identity.md` Open Question 2); v1 uses the app's default Keychain.
3. **Roster / display-name resolution**: v1 falls back to truncated npub. Whether to bundle a roster or fetch NIP-05 is a follow-up (product Open Question 3); design will render whatever display name the app resolves, npub as fallback.


## PR approval (FR-sri-pr-approve)

The patch/PR metadata section (shared view) shows an Approve affordance on iOS identical to macOS (`FR-srm-pr-approve`): one tap publishes a signed kind:1 approval note to the thread; progress/outcome render inline.
