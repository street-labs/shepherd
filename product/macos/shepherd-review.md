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
The native macOS application loads a reviewer-owned Nostr identity at launch so the reviewer can publish signed replies to patch threads. The identity is a Nostr secret key the reviewer has configured out of band (not generated or managed by the app). The app resolves the secret key with the same configuration precedence it uses for relay URLs: an environment variable, then a config file under the reviewer's Nostr configuration directory, then no identity. When an identity is loaded, the app derives the corresponding public key so it can attribute and display the active identity; the secret key is held only for as long as needed to sign published events and is never written to disk by the app. When no identity is configured, the app launches normally for read-only patch review and local commenting, and reply publishing is unavailable with a clear indication to the reviewer (see `FR-srm-identity-indicator`).

#### `FR-srm-event-sign` -- Sign Nostr events in-process
The native macOS application signs the Nostr events it publishes using the loaded reviewer identity, in-process, without shelling out to an external signing tool or background process. Signing produces a valid NIP-01 event (correct `id`, `pubkey`, `sig`) for a kind:1 reply. The signing path is the publish-side counterpart of the existing in-process `RelayClient` subscription (`FR-sr-relay-client`): reads and writes both happen in-process so the patch-thread loop is self-contained.

#### `FR-srm-event-publish` -- Publish signed events to relays
The native macOS application publishes signed Nostr events to the configured relays over the same relay transport it already uses for subscriptions. Publishing sends an `EVENT` frame to each reachable relay and tolerates individual relay failures best-effort (a publish is considered successful when at least one relay accepts the event; failures do not block the review or surface hard errors). Relay URL resolution reuses the existing precedence (`NOSTR_RELAYS` / config file / defaults). Publishing is only invoked for patch reviews when an identity is loaded.

#### `FR-srm-comment-publish-on-submit` -- Submitting an inline comment publishes it as a patch-thread reply
When the reviewer submits an inline comment during a patch review and an identity is loaded, the native application publishes that comment as a kind:1 patch-thread reply (`FR-sr-patch-reply-publish`) in addition to recording it locally. The published reply carries the patch event as root, the repository `a` tag, and -- when the comment is anchored to a line range -- a line-range anchor matching the file's absolute path and the comment's line span. The locally-recorded comment and the published reply stay associated (so the reviewer's own published reply is not duplicated when it arrives back over the live subscription). When no identity is loaded, submitting a comment records it locally only and the reviewer is informed that it was not published.

#### `FR-srm-reply-to-reply` -- Respond to an existing patch-thread reply from inline
The reviewer can initiate a response to an existing patch-thread reply directly from that reply's rendered surface (both the inspector patch-thread section and the inline anchored bubble). Initiating a response opens the inline comment editor pre-targeted at the replied-to reply; on submit, the app publishes a kind:1 note with the root `e` tag on the patch event, a reply `e` tag on the responded-to reply's event id, and a `p` tag naming that reply's author (`FR-sr-patch-reply-respond`), signed under the reviewer's identity. The response may also carry a line-range anchor when the reviewer pins it to a location.

#### `FR-srm-identity-indicator` -- Surface the active reviewer identity
The native macOS application surfaces the active reviewer identity in its UI so the reviewer knows, before they publish, which identity their replies will be attributed to. When an identity is loaded, the indicator shows the reviewer's resolved display name (or truncated npub) at or near the patch-thread surface. When no identity is loaded, the indicator makes clear that replies will not be published and that configuring an identity is required to participate in the thread. The indicator is present only for patch reviews; non-patch reviews do not show it.

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

- [ ] **Identity loaded from config** `AC-srm-identity-load`: Given the reviewer has configured a Nostr secret key via the supported configuration path, when the native app launches a patch review, then the app loads the identity, derives the reviewer's public key, and surfaces the active identity per `FR-srm-identity-indicator`. Given no identity is configured, when the app launches a patch review, then read-only review and local commenting work, the identity indicator shows that replies will not be published, and no publish action is offered.

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

## Open Questions

1. **Single binary or separate binary**: The proposed approach reuses the existing `/shepherd` binary with an extended `session.json` (multi-file `files[]`). An alternative would be a dedicated review-mode binary. Reusing the existing binary is the default; engineering may revisit if the multi-file path significantly diverges from single-file behavior.

2. **Persistent window across reviews**: When a previous `/shepherd-review` window is still open and the user invokes the command again with the same session ID (rare, but possible if the project root resolves to the same basename), the existing-window behavior follows `AC-crp-macos-window-deduplicate`. Whether the second invocation should always force a new session ID is deferred — the current convention from `/shepherd` (project-root basename as session ID) is reused.

3. **Missing-binary behavior**: If a user runs `/shepherd-review` but the macOS binary is missing (toolchain not installed), should the command error out with instructions? Current decision: error out and instruct the user to install Swift and re-run the installer. No silent fallback.

## Dependencies

- macOS variant of the Code Review Prompt Generator (`product/macos/code-review-prompt.md`) — provides the native multi-tab review UI and the session-handoff contract.
- macOS slash-command launcher infrastructure (`product/macos/slash-command.md`) — provides the install pattern, prebuild step, and `~/.shepherd/sessions/<session-id>/` staging directory contract.
- Shared `shepherd-review` requirements (`product/shepherd-review.md`) — provides the changeset detection, filtering, priority ordering, context generation, and feedback flow.
- Shared session-scoping primitives (`FR-sc-session-id`, `FR-sc-session-scoped-output`, `FR-sc-session-cleanup`) from `product/slash-command.md`.
