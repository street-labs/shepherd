# Shepherd Review — macOS Platform

> macOS-specific requirements for `shepherd-review`. See `../shepherd-review.md` for shared requirements.

## Overview

The Shepherd Review slash command (`/shepherd-review`) orchestrates a multi-file code review workflow and launches the native macOS Code Review Prompt Generator. There is no automatic platform detection.

Behaviorally the macOS variant matches the shared spec for filtering, priority ordering, structured-context generation (overall + per-file, neutral + review), brief conversation summary, auto-open, interactive prompt, and feedback handoff. It differs from the shared spec in two areas. First, the launch and context-delivery mechanism writes a session JSON payload to disk and launches the prebuilt native binary, identical to the existing `/shepherd` handoff contract. Second, the macOS variant has a richer set of **review scope modes**: in addition to the working-tree scopes, it can review a branch against a base, a single commit, or a commit range — letting the developer review committed history, not just the working copy. These modes are defined in the "Review scope modes" section below and supersede the shared `FR-sr-changeset-detection` / `FR-sr-scope-argument` for `/shepherd-review`.

## User Stories

The macOS variant adds one platform-choice user story on top of the shared spec's stories.

### US-SRM-1: Review a batch changeset in the native macOS app
**As a** developer who wants to review my changeset in the native macOS CRPG, **I want to** invoke `/shepherd-review`, **so that** every reviewable file in my changeset opens as a tab in the native app, with structured context displayed in the native UI.

### US-SRM-2: Review committed history, not just the working copy
**As a** developer reviewing my own work before opening a PR, **I want to** review my whole branch against `main`, or a single commit, or a range of commits — not only my uncommitted edits, **so that** I can do a focused review of exactly the slice of history I care about. When I have nothing uncommitted, I want a clear message rather than a blank review window.

### US-SRM-3: Publish my review comments to the patch thread from the native app
**As a** reviewer collaborating on a NIP-34 patch in the native macOS app, **I want to** submit my inline comments and have them published to the Nostr patch thread under my own identity, and respond directly to other participants' replies, **so that** my feedback joins the shared conversation every participant sees instead of staying local to my window.

### US-SRM-4: Sign my replies without exposing my raw secret key
**As a** reviewer who keeps my Nostr secret key in a bunker (a NIP-46 remote signer), **I want to** point Shepherd at my bunker connection instead of pasting my raw `nsec`, **so that** my secret key never has to live in an env var or config file on my review machine yet my published replies are still signed under my own identity.

### US-SRM-5: Open a patch directly in the app, without the CLI
**As a** reviewer who has a NIP-34 patch event id (an ngit patch), **I want to** open that patch directly in the Shepherd app from its empty start screen — alongside opening files or pasting content — **so that** I can review the patch and participate in its thread without first dropping into a terminal to run `/shepherd-review --patch`. The app fetches the patch from Nostr itself and loads it for review.

All other shared user stories (`US-SR-1` through `US-SR-9`) apply to the macOS variant unchanged — the review experience itself is the same.

## Shared Requirements — Applicability on macOS

### Apply as-is (no macOS-specific changes needed)

The following shared requirements apply identically on macOS:

- `FR-sr-file-filtering` — Filter out uninteresting files
- `FR-sr-priority-ordering` — Sort files by review importance
- `FR-sr-changeset-overview` — Generate a structured changeset overview
- `FR-sr-per-file-context` — Generate per-file context with neutral and review separation
- `FR-sr-file-list-display` — Brief summary in the conversation before auto-opening
- `FR-sr-iteration-loop` — Auto-open all files in a single review session (one tab per file in the native window; the AskUserQuestion / Done / Cancel flow is identical)
- `FR-sr-feedback-collection` — Receive unified multi-file feedback via session-scoped `prompt-output.md`
- `FR-sr-completion-summary` — Display a review summary and feedback handoff
- `FR-sr-git-required` — Requires a git repository
- `FR-sr-patch-replies-display` — Display other participants' patch-thread replies (read-only; the reviewer's own publishing is covered by the macOS-specific patch-thread reply publishing requirements below)
- `FR-sr-patch-replies-live` — Live refresh of patch-thread replies
- `FR-sr-relay-client` — In-process Nostr relay client
- `NFR-sr-startup-speed` — Fast changeset detection and context generation
- `NFR-sr-no-dependencies` — No additional dependencies (the prebuilt native binary is provided by the existing `/shepherd` infrastructure, not a new runtime dependency)
- `NFR-sr-agent-native` — Runs entirely within the agent conversation (the native binary launch is a standard `Bash` invocation, no additional process model)
- `NFR-sr-cross-platform` — Not a constraint here; the git commands themselves remain cross-platform, but the launch path is macOS-only by design (see `NFR-srm-platform-restriction` below)

### Implemented via macOS-specific requirements

The following shared requirements describe platform-neutral behavior that the macOS variant realizes through the macOS-specific requirements in the "Patch-thread reply publishing" section:

- `FR-sr-patch-reply-publish` — realized by `FR-srm-comment-publish-on-submit` + `FR-srm-event-sign` + `FR-srm-event-publish`
- `FR-sr-reviewer-identity` — realized by `FR-srm-identity-load` + `FR-srm-identity-indicator`
- `FR-sr-bunker-signing` — realized by `FR-srm-bunker-connect` + the bunker half of `FR-srm-event-sign`
- `FR-sr-patch-reply-respond` — realized by `FR-srm-reply-to-reply`

### Modified on macOS

- **`FR-sr-changeset-detection`** — The shared spec defines the default changeset as the working tree compared to the merge base of the current branch and `main`. On macOS the default is narrower and matches what developers actually use day-to-day: the working tree compared to `HEAD` (uncommitted work only). Branch-vs-base review is still available, but as an explicit opt-in mode rather than the default. The macOS detection rules — including which modes include untracked files — are defined by `FR-srm-scope-modes` below, which supersedes `FR-sr-changeset-detection` for `/shepherd-review`.

- **`FR-sr-scope-argument`** — The shared spec defines three scopes (default working-tree-vs-main, `--staged`, `--unstaged`). The macOS variant keeps the working-tree scopes but redefines the default (uncommitted vs `HEAD`, not vs `main`) and adds three commit-scoped modes — branch, single commit, and commit range — plus a bare `<ref>` mode. The full macOS scope grammar is defined by `FR-srm-scope-modes`, `FR-srm-branch-scope`, `FR-srm-commit-scope`, and `FR-srm-range-scope` below, which supersede `FR-sr-scope-argument` for `/shepherd-review`.

- **`FR-sr-command-file`** — Implementation surface is the same (a Claude Code or opencode custom command file plus opencode skill), but the command name is `/shepherd-review` and the command file lives at `.claude/commands/shepherd-review.md` with a peer opencode skill at `.config/opencode/skills/shepherd-review/SKILL.md`. See `FR-srm-command-file`.

- **`FR-sr-multi-file-launch`** — The macOS mechanism writes a multi-file `session.json` to the per-session staging directory and launches the prebuilt native binary directly. See `FR-srm-multi-file-launch`.

- **`FR-sr-context-handoff`** — On macOS the context fields are embedded directly in the session JSON payload that the native binary reads on startup. The neutral/review separation contract is preserved. See `FR-srm-context-handoff`.

- **`FR-sr-install`** — The install script is extended further to symlink the new command file and ensure the prebuilt macOS binary is available. The macOS variant inherits the `/shepherd` prebuild path: if the Swift toolchain is missing, the installer reports a degraded state without aborting the rest of the install. See `FR-srm-install`.

### Do not apply on macOS

None. Every shared functional requirement either applies as-is or is supplanted by a macOS variant above.

## macOS-Specific Functional Requirements

### Patch-thread reply publishing (bidirectional)

These requirements make the patch-thread review loop bidirectional on macOS. They are the macOS implementation of the shared `FR-sr-patch-reply-publish`, `FR-sr-reviewer-identity`, and `FR-sr-patch-reply-respond`. They apply only to patch reviews (`--patch`); non-patch reviews are unaffected and comments remain local.

#### `FR-srm-identity-load` -- Load the reviewer's Nostr identity
The native macOS application loads a reviewer-owned Nostr identity at launch so the reviewer can publish signed replies to patch threads. The identity takes one of two forms, both configured by the reviewer out of band (the app neither generates nor manages keys):

- **Local key** — a Nostr secret key (`nsec1...` or hex), as today.
- **Bunker connection** — a NIP-46 bunker URI (`bunker://<remote-signer-pubkey>?relay=<wss-url>[&secret=<token>]`) pointing at a remote signer that holds the reviewer's secret key.

The app resolves the identity with this configuration precedence (first non-empty wins), preferring the bunker form so the reviewer need not place a raw secret key on the host:

1. `SHEPHERD_BUNKER` environment variable — a `bunker://` URI.
2. `~/.config/nostr/bunker` config file — first non-blank, non-`#` line, a `bunker://` URI.
3. `SHEPHERD_NSEC` environment variable — bech32 `nsec1...` or hex secret key (existing).
4. `~/.config/nostr/identity` config file — first non-blank, non-`#` line, `nsec1...` or hex (existing).
5. No identity.

For a **local key**, the app derives the corresponding public key (secp256k1) to attribute and display the active identity; the secret key is held in memory for the app's lifetime and never written to disk. For a **bunker connection**, the app derives the reviewer's public key from the bunker (the URI's remote-signer pubkey identifies the bunker, not the reviewer; the reviewer's pubkey is obtained from the bunker per `FR-srm-bunker-connect`) and holds no secret key at all — only the connection parameters and an ephemeral NIP-46 session keypair used solely for the encrypted control channel. A malformed `bunker://` URI is treated as no identity with a clear indication of the parse error (see `FR-srm-identity-indicator`). When no identity is configured, the app launches normally for read-only patch review and local commenting, and reply publishing is unavailable with a clear indication (see `FR-srm-identity-indicator`).

#### `FR-srm-bunker-connect` -- Establish the NIP-46 bunker control channel
When the loaded identity is a bunker connection, the native app opens a NIP-46 session with the remote signer over the Nostr relay named in the bunker URI (reusing the in-process `RelayClient` transport, `FR-sr-relay-client`). The app generates an ephemeral session keypair (used only for the NIP-46 control channel, never as the reviewer's identity), sends a NIP-46 `connect` request (kind `24133`) NIP-44-encrypted to the bunker's (remote-signer) pubkey, and includes the `secret` token from the URI when the URI carries one. Once connected, the app obtains the reviewer's (user) public key via a NIP-46 `get_public_key` request and uses it to attribute and display the active identity and to mark the reviewer's own replies. The control channel stays open for the life of the review window so repeated `sign_event` requests do not re-handshake per reply; it is cancelled when the window closes. If the bunker does not respond to `connect`, refuses the connection (e.g. bad secret), or `get_public_key` fails, the identity is treated as unavailable for publishing and the indicator reflects the failure (see `FR-srm-identity-indicator`) while read-only review and local commenting remain available.

#### `FR-srm-event-sign` -- Sign Nostr events under the loaded identity
The native macOS application signs the Nostr events it publishes under the loaded reviewer identity, without shelling out to an external signing tool or background process. Signing produces a valid NIP-01 event (correct `id`, `pubkey`, `sig`) for a kind:1 reply. The signing path has two modes selected by the loaded identity form:

- **Local key** — signing is in-process (secp256k1 Schnorr), as today. This is the publish-side counterpart of the existing in-process `RelayClient` subscription (`FR-sr-relay-client`): reads and writes both happen in-process.
- **Bunker connection** — signing is delegated to the remote bunker (`FR-sr-bunker-signing`): the app sends a NIP-46 `sign_event` request carrying the unsigned event over the control channel from `FR-srm-bunker-connect` and awaits the bunker's response, which carries the signed event. The app never holds the reviewer's secret key in this mode.

Signing is an async operation (a bunker round-trip is a network call); the publish path awaits it before publishing. The two modes share one signing interface so the rest of the publish path is unaware which form is active. If bunker signing fails (timeout, refusal, or a dropped control channel), the sign returns no event and the publish path degrades per `FR-srm-bunker-sign-failure`.

#### `FR-srm-bunker-sign-failure` -- Degrade gracefully when the bunker cannot sign
When the loaded identity is a bunker connection and a `sign_event` request fails (the bunker is unreachable, the control channel has dropped, the bunker refuses to sign the event, or the response times out), the app does not publish and does not silently drop the reviewer's comment. The comment is retained locally, the editor reopens with an inline error naming the bunker as the cause (e.g. `Couldn't publish reply — the bunker didn't respond. Your comment is saved locally.`), and the identity indicator reflects the connection problem (see `FR-srm-identity-indicator`). The reviewer may retry, which reattempts the bunker sign (reconnecting the control channel first if it was dropped) and publishes on success. Read-only review and local commenting are unaffected.

#### `FR-srm-event-publish` -- Publish signed events to relays
The native macOS application publishes signed Nostr events to the configured relays over the same relay transport it already uses for subscriptions. Publishing sends an `EVENT` frame to each reachable relay and tolerates individual relay failures best-effort (a publish is considered successful when at least one relay accepts the event; failures do not block the review or surface hard errors). Relay URL resolution reuses the existing precedence (`NOSTR_RELAYS` / config file / defaults). Publishing is only invoked for patch reviews when an identity is loaded.

#### `FR-srm-comment-publish-on-submit` -- Submitting an inline comment publishes it as a patch-thread reply
When the reviewer submits an inline comment during a patch review and an identity is loaded, the native application publishes that comment as a kind:1 patch-thread reply (`FR-sr-patch-reply-publish`) in addition to recording it locally. The published reply carries the patch event as root, the repository `a` tag, and -- when the comment is anchored to a line range -- a line-range anchor matching the file's absolute path and the comment's line span. The locally-recorded comment and the published reply stay associated (so the reviewer's own published reply is not duplicated when it arrives back over the live subscription). When no identity is loaded, submitting a comment records it locally only and the reviewer is informed that it was not published.

#### `FR-srm-reply-to-reply` -- Respond to an existing patch-thread reply from inline
The reviewer can initiate a response to an existing patch-thread reply directly from that reply's rendered surface (both the inspector patch-thread section and the inline anchored bubble). Initiating a response opens the inline comment editor pre-targeted at the replied-to reply; on submit, the app publishes a kind:1 note with the root `e` tag on the patch event, a reply `e` tag on the responded-to reply's event id, and a `p` tag naming that reply's author (`FR-sr-patch-reply-respond`), signed under the reviewer's identity. The response may also carry a line-range anchor when the reviewer pins it to a location.

#### `FR-srm-identity-indicator` -- Surface the active reviewer identity
The native macOS application surfaces the active reviewer identity in its UI so the reviewer knows, before they publish, which identity their replies will be attributed to. When an identity is loaded, the indicator shows the reviewer's resolved display name (or truncated npub) at or near the patch-thread surface, and, for a bunker connection, a small status dot/state reflecting whether the bunker control channel is connected, connecting, or in a failed state. When no identity is configured, or a configured bunker URI is malformed or its control channel could not be established, the indicator makes clear that replies will not be published and names what is needed (a configured identity, or a reachable bunker). The indicator is present only for patch reviews; non-patch reviews do not show it.

### Coexistence

#### `FR-srm-coexists` — `/shepherd` and `/shepherd-review` coexist
Both `/shepherd` and `/shepherd-review` are available simultaneously after install. Invoking one does not affect the other. There is no automatic platform detection.

### Command and launch

#### `FR-srm-command-file` — Implemented as a Claude Code or opencode command
The command is implemented as `.claude/commands/shepherd-review.md` plus an opencode skill at `.config/opencode/skills/shepherd-review/SKILL.md`, following the same pattern as `/shepherd` and `/shepherd-review`. The command file contains the prompt instructions; no compiled code is required beyond the existing macOS application binary.

#### `FR-srm-multi-file-launch` — Open multiple files in a single native session
After changeset detection, filtering, priority ordering, and context generation, the command opens all reviewable files in a single native macOS application session. The mechanism is:

1. The command writes a session payload to the per-session staging directory at `~/.shepherd/sessions/<session-id>/session.json`. The payload contains the session ID, project root, an entry per reviewable file (absolute path and contents), and the review-context fields (see `FR-srm-context-handoff`).
2. The command launches the prebuilt macOS binary with `--session <id>`, identically to `/shepherd`.
3. The native application reads the session payload, opens its window, and presents each file as a tab. The tab order matches the priority order from `FR-sr-priority-ordering`.

There is no local web server; the launch contract is identical to the existing `/shepherd` handoff, extended to multiple files.

#### `FR-srm-context-handoff` — Pass structured context data via session payload
The structured context data required by `FR-sr-changeset-overview` and `FR-sr-per-file-context` is delivered to the native application by embedding it inside the same `session.json` payload used for the file list. The payload includes:

1. **Overall neutral context**: factual changeset summary
2. **Overall review feedback**: agent's assessment of the changeset
3. **Per-file entries**, each containing the file path, change type, neutral context, and review feedback
4. **File ordering**: priority order from `FR-sr-priority-ordering` (encoded by the order of entries in the payload)

The neutral/review distinction is preserved as separate fields at both the overall and per-file level so the application can render them as visually distinct sections. The session ID isolates concurrent reviews per `FR-sc-session-id` — each invocation writes to its own `~/.shepherd/sessions/<session-id>/` directory and the binary opens a window scoped to that session.

#### `FR-srm-install` — Install command and prepare the macOS binary
The install script (`scripts/install-command.sh`) is extended to:

1. Symlink `~/.claude/commands/shepherd-review.md` to the repo's `.claude/commands/shepherd-review.md`, alongside the existing `shepherd` symlink.
2. Reuse the macOS prebuild step already established for `/shepherd`. No additional build is performed for the review variant — the same binary serves both single-file and multi-file launches.

If the Swift toolchain is missing or the build fails, the installer reports the degraded state without aborting the rest of the install. `/shepherd` and `/shepherd-review` both become unavailable until the user installs Swift and re-runs the installer.

### Review scope modes

These requirements define what `/shepherd-review` reviews. They supersede the shared `FR-sr-changeset-detection` and `FR-sr-scope-argument` for the macOS variant. Every mode produces a list of changed files that then flows through the same filtering (`FR-sr-file-filtering`), priority ordering (`FR-sr-priority-ordering`), and context generation (`FR-sr-changeset-overview`, `FR-sr-per-file-context`) as before — only the *source* of the changed-file list differs by mode.

#### `FR-srm-scope-modes` — Scope is selected by an optional argument
The command accepts an optional argument that selects one of several review scopes. There are two families:

**Working-tree scopes** review what is currently on disk relative to a base, and include untracked new files (not `git add`ed) as `added`:

- **Default (no argument)** — All uncommitted changes: staged + unstaged + untracked, compared to `HEAD`. This is the everyday "review what I'm about to commit" case.
- **`--staged`** — Only staged changes (the git index).
- **`--unstaged`** — Only unstaged modifications plus untracked files.
- **`<ref>`** — The working tree compared to an arbitrary commit, branch, or tag. Includes untracked files.

**Commit scopes** review committed history and do **not** include untracked files (see `FR-srm-commit-mode-no-untracked`):

- **`--branch [base]`** — The commits on the current branch, relative to a base branch (see `FR-srm-branch-scope`).
- **`--commit [ref]`** — A single commit (see `FR-srm-commit-scope`).
- **`--range <range>`** — A range of commits (see `FR-srm-range-scope`).

If an unrecognized argument or malformed value is provided, the command prints a usage message listing all scopes and stops. Deleted files are excluded from the review list in every mode (nothing to open), and renamed files use their new path — identical to the shared spec.

#### `FR-srm-branch-scope` — Review the current branch against a base
With `--branch [base]`, the command reviews the changes introduced by the current branch's own commits relative to a base branch, using the merge base (divergence point) so that commits landed on the base after the branch diverged are not shown. The base defaults to `main` and may be overridden by an explicit argument (e.g. `--branch develop`). This is the answer to "show me everything my branch changes versus main, excluding my uncommitted edits." If the base does not resolve to a valid ref, the command prints a usage/error message and stops. If the current branch has no commits beyond the merge base (nothing to review), the empty-changeset behavior of `FR-srm-no-blank-window` applies.

#### `FR-srm-commit-scope` — Review a single commit
With `--commit [ref]`, the command reviews the changes introduced by exactly one commit — the difference between that commit and its parent. The ref defaults to `HEAD`, so `--commit` with no argument reviews the most recent commit ("review my last commit"). An explicit ref (e.g. `--commit abc123` or `--commit HEAD~2`) reviews that commit. If the commit is a root commit (no parent), the command reviews it against the empty tree (every line is an addition). If the ref does not resolve, the command prints a usage/error message and stops.

#### `FR-srm-range-scope` — Review a range of commits
With `--range <range>`, the command reviews the aggregate changes across a span of commits. The range is expressed in standard git range syntax — two-dot (`A..B`, changes reachable from `B` but not `A`) or three-dot (`A...B`, changes since the merge base). Both endpoints must resolve to valid refs; otherwise the command prints a usage/error message and stops. The review shows the net diff across the range, not a per-commit breakdown.

#### `FR-srm-commit-mode-no-untracked` — Commit scopes exclude untracked files
The commit scopes (`--branch`, `--commit`, `--range`) review committed history only and therefore do **not** include untracked working-tree files in the changeset. Untracked files are included only in the working-tree scopes (default, `--unstaged`, `<ref>`). This keeps a commit-scoped review faithful to what is actually recorded in the commits being reviewed.

#### `FR-srm-no-blank-window` — Never open an empty or stale review window
The command must never launch the native app with nothing to review. Two guarantees:

1. **Empty changeset never launches** — If the selected scope yields zero changed files (or zero *reviewable* files after filtering), the command prints a clear, scope-specific message explaining that there is nothing to review and stops **without** launching the native app. The message names the scope so the user understands why (e.g. no uncommitted changes, no commits on the branch versus the base, an empty commit, or an empty range). This prevents the failure mode where the app opens to a blank window because the changeset was empty.
2. **Each launch reflects the current changeset** — When the command does launch, it refreshes the session payload and clears any stale prompt output from a previous run, so a reused window shows the files for the current invocation, never leftover state from an earlier review.

### In-app patch open

These requirements add a second, in-app way to start a patch review. The existing `--patch <event-id>` path (`FR-sr-patch-source` and friends) is driven by the `/shepherd-review` command prompt, which fetches the patch, applies it to a temporary git review branch, generates review context, and hands the session to the native app. The in-app path is independent of the CLI and of any local git repository: the reviewer is in the native app's empty state (standalone mode, no files loaded) and initiates the patch review themselves. The app fetches the NIP-34 patch event in-process (reusing `FR-sr-relay-client`), and loads the patch for review using only what the event itself contains. Once loaded, the patch review surface is the one already specified for the CLI path — patch metadata display (`FR-sr-patch-metadata-display`), the live patch-thread replies (`FR-sr-patch-replies-live`), and bidirectional reply publishing (`FR-srm-comment-publish-on-submit` et al.) all activate as if the session had been launched by the command.

The reviewer's identity is handled by the existing in-app identity flow (`FR-srm-identity-load`); the in-app patch open does not introduce a new identity path. If no identity is loaded when a patch is opened, review and local commenting work and the identity indicator surfaces that replies will not publish, identical to the CLI-launched case.

#### `FR-srm-patch-open-entry` — Empty state exposes an "Open Patch" affordance
The native app's empty state (the drop zone shown when no files are loaded, per `product/macos/code-review-prompt.md`) exposes an "Open Patch…" affordance alongside the existing "Open Files…" (native file open panel) and "Paste from Clipboard" entry points. Activating it opens a lightweight dialog (see design spec) in which the reviewer enters or pastes a NIP-34 patch reference. This affordance is present only in the empty state; it is not shown once files are loaded. It initiates an in-app patch review and does not invoke the `/shepherd-review` command or any shell process.

#### `FR-srm-patch-open-input` — Accept a patch event reference and validate its format
The Open Patch dialog accepts a patch reference in either of two forms:

1. A 64-character hex Nostr event id.
2. A NIP-19 `nevent1…` or `naddr1…` bech32 entity that encodes a patch event (the app decodes it to its referenced event id and relays).

Leading/trailing whitespace is trimmed. An input that matches neither form is rejected inline with a clear message ("Enter a 64-character hex event id or a nevent1/naddr1 reference") and the dialog stays open; no fetch is attempted. Pasted text that contains extra surrounding prose is not parsed — the whole (trimmed) field must be one valid reference.

#### `FR-srm-patch-open-fetch` — Fetch and validate the NIP-34 patch event in-process
When the reviewer submits a valid reference, the app fetches the patch event in-process using `FR-sr-relay-client`: it opens a NIP-01 subscription whose filter is the event id (and kinds `1617`, `1621`) across the configured relays. When `nevent1`/`naddr1` relays are present, those are preferred; otherwise the standard relay resolution (`NOSTR_RELAYS`, `~/.config/nostr/relays.txt`, default public relays) is used.

The first matching event delivered is taken as the patch. The app then validates it (the same semantics as `FR-sr-patch-validation`, performed in Swift rather than shell):

- **Event kind**: must be `1617` (proposal) or `1621` (patch). Any other kind (or an event whose content is not a diff) is rejected with "Event <short-id> is not a NIP-34 patch (kind <k>)."
- **Diff format**: the event content must be a valid unified diff beginning with `diff --git` and containing `+++`/`---` headers and `@@` hunks. A malformed diff is rejected with "Patch event <short-id> does not contain a valid unified diff."

A fetch that returns no event within the relay wait window is rejected with "Patch event <short-id> not found on the configured relays." If no relay is reachable, the dialog reports "No Nostr relays reachable — check your relay configuration." and no review is started.

#### `FR-srm-patch-open-load` — Load the patch for review from the event alone
On a successfully fetched and validated patch event, the app loads a patch review session using only the event's contents — no local git repository is required and no temporary review branch is created:

1. **Parse the unified diff per file.** The diff is split on each `diff --git a/<path> b/<path>` boundary into one block per changed file. Each block becomes a tab in the file browser, named by the file path, with the block's diff text as the tab's content. (A file that appears in the diff only via binary or removal-only markers is still loaded as a tab so the reviewer can see and comment on its removal.) This is the v1 in-app review surface: the reviewer annotates the diff. Reconstructing full post-patch file contents would require the base files the diff is against, which the app does not have without a git checkout; that richer view is a roadmap fast-follow (see `roadmap/patch-watcher.md`).
2. **Attach patch metadata.** The app builds a patch metadata record from the event — full and short event id, author (event pubkey, resolved to a display name via the roster when available), commit message (first line of the event content before the diff, or an `m`/commit tag), parent commit short hash (from a `parent-commit` tag, if present), status (from a `status` tag, defaulting to `open`), and repo coordinate (the `a` tag, when present) — and sets it on the session's patch metadata. This activates the patch metadata section, the live patch-thread reply subscription (`FR-sr-patch-replies-live`), and the reply-publishing path (`FR-srm-comment-publish-on-submit`).
3. **Enter the review.** The empty state is replaced by the standard multi-file review layout (one tab per changed file). The reviewer adds inline comments on the diff and publishes them to the patch thread under their identity exactly as in the CLI-launched patch review.

There is no agent-generated neutral/review context for an in-app-opened patch (no LLM runs in this path); per-file review context is simply absent, and the review-context panel hides for tabs that have none (graceful-missing, per `AC-crp-context-graceful-missing`). The patch metadata section and patch thread are the orientation the reviewer gets instead.

## macOS-Specific Non-Functional Requirements

#### `NFR-srm-launch-budget` — Launch within the macOS app budget
The time from invoking `/shepherd-review` to the native window appearing with all tabs loaded must fit within the existing macOS launch budget — `NFR-crp-macos-launch-time` (1 second cold launch) plus the agent's context-generation time. The slash command itself adds no measurable overhead beyond writing the session payload and invoking the prebuilt binary.

#### `NFR-srm-no-server` — No local web server is started
Launching `/shepherd-review` does not start or rely on any local web server. The native binary is self-contained.

#### `NFR-srm-platform-restriction` — macOS-only
The command is intended for macOS and depends on the prebuilt macOS application binary. On other operating systems the command is unavailable.

## Acceptance Criteria

### Coexistence

- [ ] **Both commands available** `AC-srm-coexists`: Given the installer has run successfully, when the user lists available slash commands, then `/shepherd` and `/shepherd-review` are both present, and invoking one does not affect the other.

### Patch-thread reply publishing

- [ ] **Identity loaded from config** `AC-srm-identity-load`: Given the reviewer has configured a Nostr identity via either supported configuration path (local secret key or bunker URI), when the native app launches a patch review, then the app loads the identity, resolves the reviewer's public key (derived locally for a key, obtained from the bunker for a bunker connection), and surfaces the active identity per `FR-srm-identity-indicator`. Given no identity is configured, when the app launches a patch review, then read-only review and local commenting work, the identity indicator shows that replies will not be published, and no publish action is offered. Given a malformed `bunker://` URI is configured, when the app launches, then the indicator names the parse error and publishing is unavailable.

- [ ] **Bunker connect handshake** `AC-srm-bunker-connect`: Given the reviewer has configured a `bunker://` URI pointing at a reachable NIP-46 bunker, when the native app launches a patch review, then the app opens the NIP-46 control channel, completes the `connect` handshake (supplying the `secret` when present), obtains the reviewer's public key via `get_public_key`, and surfaces the identity as connected per `FR-srm-identity-indicator`. Given the bunker is unreachable or refuses the connection, when the app launches, then the identity is treated as unavailable for publishing, the indicator reflects the failure, and read-only review and local commenting remain available.

- [ ] **Reply signed by bunker** `AC-srm-bunker-sign`: Given a patch review is open with a connected bunker identity (and no local secret key), when the reviewer submits an inline comment, then the app sends a NIP-46 `sign_event` request, receives the signed event back from the bunker, publishes it to the configured relays under the reviewer's public key, and the reply appears immediately in the reviewer's own patch-thread section and inline at its anchor — without the reviewer's secret key ever being present on the host.

- [ ] **Bunker sign failure degrades gracefully** `AC-srm-bunker-sign-failure`: Given a bunker identity is loaded but the bunker cannot sign (unreachable, dropped channel, refusal, or timeout), when the reviewer submits a comment, then the app retains the comment locally, reopens the editor with an inline error naming the bunker as the cause, does not publish, and the reviewer can retry; on a successful retry the reply publishes.

- [ ] **Comment publishes on submit** `AC-srm-comment-publish`: Given a patch review is open and an identity is loaded, when the reviewer submits an inline comment anchored to a file and line range, then the app signs and publishes a kind:1 reply to the configured relays tagged with the patch event as root, the repository `a` tag, and a matching line-range anchor, and the reply appears immediately in the reviewer's own patch-thread section and inline at its anchor without waiting for a relay round-trip. Given no identity is loaded, when the reviewer submits a comment, then the comment is recorded locally only and the reviewer is informed it was not published.

- [ ] **Respond to a reply** `AC-srm-reply-to-reply`: Given the patch thread contains a reply from another participant, when the reviewer initiates a response from that reply's rendered surface and submits it, then the app publishes a kind:1 note carrying a root `e` tag on the patch event, a reply `e` tag on the responded-to reply's event id, and a `p` tag naming that reply's author, signed under the reviewer's identity, and the response appears alongside the replied-to reply.

- [ ] **Published reply not duplicated** `AC-srm-publish-no-dup`: Given the reviewer has published a reply from within the app, when the same reply arrives back over the live relay subscription, then the app does not render it twice (the locally-recorded copy and the relay-delivered copy are deduplicated by event id).

- [ ] **Publish tolerates relay failure** `AC-srm-publish-relay-failure`: Given the reviewer submits a reply and some configured relays are unreachable, when the app attempts to publish, then as long as at least one relay accepts the event the publish succeeds without surfacing a hard error; if no relay accepts the event, the reviewer is informed the reply could not be published and the local copy is retained.

### Launch and tabs

- [ ] **Native window with tabs** `AC-srm-batch-open-native`: Given a changeset of 5 reviewable files, when the user invokes `/shepherd-review`, then the macOS application opens with 5 tabs (one per file) in priority order, and no local web server is started.

- [ ] **No server side effects** `AC-srm-no-server`: Given `/shepherd-review` is invoked, when changeset detection and context generation complete, then no local web server is started or required.

### Context handoff

- [ ] **Context visible in native UI** `AC-srm-context-in-app`: Given the agent has generated overall and per-file context, when the macOS application opens, then the overall neutral context and overall review feedback appear in the application UI as visually distinct sections, and each file tab displays its per-file neutral context and per-file review feedback alongside the diff, also as visually distinct sections.

- [ ] **Context isolated per session** `AC-srm-session-isolation`: Given two concurrent `/shepherd-review` invocations from different working directories, when each runs to completion, then each launches its own session window with its own files and context, and neither sees the other's data — both reading and writing are scoped to their own `~/.shepherd/sessions/<session-id>/` directory.

### Feedback round-trip

- [ ] **Done writes session-scoped prompt** `AC-srm-prompt-roundtrip`: Given the user has reviewed files in the native window and added comments, when the user clicks Done, then the application writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`, and the agent — after the user selects "Added comments" from the interactive prompt — reads that file and presents the standard completion summary and feedback action menu (apply, discuss, save, nothing).

- [ ] **Cancel ends without summary** `AC-srm-cancel`: Given the macOS window is open, when the user selects "Cancel" in the agent's interactive prompt, then the session ends immediately, no summary is shown, and the user remains free to close the application window manually.

### Review scope modes

- [ ] **Default reviews uncommitted work** `AC-srm-default-scope`: Given a branch with both committed changes and uncommitted edits, when the user invokes `/shepherd-review` with no argument, then the review contains the uncommitted changes (staged + unstaged + untracked) relative to `HEAD` and does not include changes that exist only in already-committed history.

- [ ] **Branch scope reviews branch commits** `AC-srm-branch-scope`: Given a feature branch with 3 commits ahead of `main` and a clean working tree, when the user invokes `/shepherd-review --branch`, then the review contains exactly the files changed by those 3 commits relative to the merge base with `main`, and excludes files changed on `main` after the branch diverged. Given `--branch develop`, the comparison base is `develop` instead of `main`.

- [ ] **Single commit scope reviews one commit** `AC-srm-commit-scope`: Given the user invokes `/shepherd-review --commit` with no ref, then the review contains exactly the files changed by the most recent commit (`HEAD` versus its parent). Given `--commit <ref>`, the review contains the files changed by that commit. Given the target is a root commit with no parent, the review treats every file as newly added.

- [ ] **Range scope reviews a commit span** `AC-srm-range-scope`: Given the user invokes `/shepherd-review --range A..B` with valid refs `A` and `B`, then the review contains the net set of files changed across that range. Given an endpoint that does not resolve, the command prints a usage/error message and does not launch the app.

- [ ] **Commit scopes exclude untracked files** `AC-srm-commit-excludes-untracked`: Given an untracked file exists in the working tree, when the user invokes any commit-scoped mode (`--branch`, `--commit`, or `--range`), then the untracked file does not appear in the review list. The same file does appear when the default or `--unstaged` scope is used.

- [ ] **Empty changeset shows a message, no window** `AC-srm-empty-no-launch`: Given the selected scope yields no reviewable files (e.g. a clean working tree on the default scope, a branch with no commits beyond its base, an empty commit, or all files filtered out), when the user invokes the command, then a clear scope-specific message is printed, no native window opens, and no blank window appears.

### Install

- [ ] **Installer creates symlink** `AC-srm-install-symlink`: Given the user runs `./scripts/install-command.sh`, when the script completes, then a symlink exists at `~/.claude/commands/shepherd-review.md` pointing to the repo's `.claude/commands/shepherd-review.md`, and `/shepherd-review` is available globally in Claude Code or opencode.

- [ ] **Install tolerates missing toolchain** `AC-srm-install-degraded`: Given the Swift toolchain is missing on the host, when the installer runs, then the installer reports that `/shepherd` and `/shepherd-review` are unavailable, and the install process exits with a success-or-warning state rather than aborting.

- [ ] **Updates propagate via git pull** `AC-srm-install-git-pull`: Given the install symlink exists, when the user runs `git pull` in the repo, then changes to `shepherd-review.md` are picked up automatically the next time the command is invoked, with no re-install required.

### In-app patch open

- [ ] **Open Patch from empty state** `AC-srm-patch-open-happy`: Given the native app is in its empty state (no files loaded), when the reviewer opens the "Open Patch…" affordance, pastes a 64-character hex event id for a valid NIP-34 patch event (kind `1617` or `1621`) whose content is a unified diff, and submits, then the app fetches the event in-process from the configured relays, splits the diff into one tab per changed file named by file path, attaches patch metadata (author, message, parent, status, repo coordinate), and enters the multi-file review layout with the patch metadata section, live patch-thread replies, and reply-publishing path all active — without invoking `/shepherd-review` or any shell process and without requiring a local git repository.

- [ ] **nevent/naddr reference accepted** `AC-srm-patch-open-nevent`: Given the reviewer pastes a `nevent1…` (or `naddr1…`) reference that encodes a patch event id, when the app decodes it, then it fetches the referenced event from the relays encoded in the reference (preferred over the default relay list) and proceeds as in `AC-srm-patch-open-happy`.

- [ ] **Invalid reference rejected inline** `AC-srm-patch-open-invalid-id`: Given the reviewer enters text that is neither a 64-character hex event id nor a `nevent1`/`naddr1` reference, when they submit, then the dialog shows "Enter a 64-character hex event id or a nevent1/naddr1 reference", no fetch is attempted, and the dialog stays open for correction.

- [ ] **Patch event not found** `AC-srm-patch-open-not-found`: Given no event with the submitted id exists on the configured relays, when the relay wait window elapses with no match, then the dialog reports "Patch event <short-id> not found on the configured relays." and no review is started.

- [ ] **Non-patch event rejected** `AC-srm-patch-open-wrong-kind`: Given the fetched event's kind is not `1617` or `1621`, when the app validates it, then the dialog reports "Event <short-id> is not a NIP-34 patch (kind <k>)." and no review is started.

- [ ] **Malformed diff rejected** `AC-srm-patch-open-bad-diff`: Given the fetched event's content does not begin with `diff --git` or lacks valid `@@` hunks, when the app validates it, then the dialog reports "Patch event <short-id> does not contain a valid unified diff." and no review is started.

- [ ] **No relays reachable** `AC-srm-patch-open-no-relays`: Given no configured relay is reachable, when the reviewer submits a reference, then the dialog reports "No Nostr relays reachable — check your relay configuration." and no fetch is attempted.

- [ ] **In-app patch open activates the thread** `AC-srm-patch-open-activates-thread`: Given an in-app-opened patch review is loaded, when new patch-thread replies arrive over the live relay subscription, then they appear in the inspector Patch Thread section and inline at their anchors, and when the reviewer submits an inline comment with an identity loaded, then it publishes to the patch thread under that identity — identical to a CLI-launched patch review.

## Open Questions

1. **Single binary or separate binary**: The proposed approach reuses the existing `/shepherd` binary with an extended `session.json` (multi-file `files[]`). An alternative would be a dedicated review-mode binary. Reusing the existing binary is the default; engineering may revisit if the multi-file path significantly diverges from single-file behavior.

2. **Persistent window across reviews**: When a previous `/shepherd-review` window is still open and the user invokes the command again with the same session ID (rare, but possible if the project root resolves to the same basename), the existing-window behavior follows `AC-crp-macos-window-deduplicate`. Whether the second invocation should always force a new session ID is deferred — the current convention from `/shepherd` (project-root basename as session ID) is reused.

3. **Missing-binary behavior**: If a user runs `/shepherd-review` but the macOS binary is missing (toolchain not installed), should the command error out with instructions? Current decision: error out and instruct the user to install Swift and re-run the installer. No silent fallback.

4. **Diff-as-tabs vs full-file view for in-app patch open**: The v1 in-app path (`FR-srm-patch-open-load`) loads each changed file as a tab whose content is that file's diff block, because reconstructing full post-patch file contents requires the base files the diff is against (which need a git checkout). The CLI path shows full post-patch file content because it applies the patch to a real review branch. Should the in-app path fetch base files from the NIP-34 repo coordinate (or a configured git remote) to reconstruct full files and match the CLI experience? Deferred to the roadmap; the diff-as-tabs view is shipped first and is useful on its own.

## Dependencies

- macOS variant of the Code Review Prompt Generator (`product/macos/code-review-prompt.md`) — provides the native multi-tab review UI and the session-handoff contract.
- macOS slash-command launcher infrastructure (`product/macos/slash-command.md`) — provides the install pattern, prebuild step, and `~/.shepherd/sessions/<session-id>/` staging directory contract.
- Shared `shepherd-review` requirements (`product/shepherd-review.md`) — provides the changeset detection, filtering, priority ordering, context generation, and feedback flow.
- Shared session-scoping primitives (`FR-sc-session-id`, `FR-sc-session-scoped-output`, `FR-sc-session-cleanup`) from `product/slash-command.md`.
