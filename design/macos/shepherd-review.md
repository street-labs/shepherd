---
product-hash: 8ba09106a87a74e22edfa0a753a8972b0ff0fa9955d99a0af80cd8438ecd2250
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — macOS Design Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/macos/shepherd-review.md` for macOS-specific requirements.
> Reuses the native multi-file UI defined in `./code-review-prompt.md`.

## What We're Designing

The conversational and native-app interaction for `/shepherd-review`. The orchestration layer (agent conversation) is defined by the `/shepherd-review` command prompt (`.claude/commands/shepherd-review.md` and its opencode mirror) and the shared product spec `../../product/shepherd-review.md` — the design here documents only the platform-specific differences: command syntax, launch surface, and how structured context is presented inside the native macOS window. The native window itself follows the multi-file layout already specified in `./code-review-prompt.md`; this spec does not redefine that UI, it only describes how `shepherd-review` populates and uses it.

## Surface Inventory

| Surface | Role |
|---|---|
| **Agent conversation (Claude Code or opencode)** | Orchestration: changeset detection, filtering, priority ordering, context generation, brief summary, auto-launch, `AskUserQuestion` interactive prompt, completion summary, feedback action menu. |
| **Native macOS application window** | Review surface. Multi-file three-column layout (file browser left, code viewer center, inspector right) per `./code-review-prompt.md`. Each reviewable file appears as a row in the file browser; the priority-ordered first file is the initial active tab. Overall and per-file review context render in the inspector and code viewer per `FR-crp-review-context-display`. |

The agent conversation is defined by the `/shepherd-review` command prompt (`.claude/commands/shepherd-review.md` and its opencode mirror). Refer there for the conversation transcript, the brief-summary format, the interactive prompt, the completion summary, and the feedback action menu. The launch step invokes a launcher script that writes a session payload and runs the prebuilt native binary.

## Command Syntax

```
/shepherd-review [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | --patch <event-id> | <ref>]
```

The macOS scope grammar adds three commit-scoped modes and one patch mode on top of the working-tree scopes (`FR-srm-scope-modes`, `FR-srm-branch-scope`, `FR-srm-commit-scope`, `FR-srm-range-scope`, `FR-sr-patch-source`):

| Argument | Scope label (shown in summary) | What it reviews |
|---|---|---|
| _no argument_ | `all uncommitted changes` | Working tree vs `HEAD` — staged + unstaged + untracked |
| `--staged` | `staged changes only` | The git index |
| `--unstaged` | `unstaged changes only` | Unstaged modifications + untracked |
| `--branch [base]` | `commits on <branch> vs <base>` | The branch's own commits vs the merge base with `base` (default `main`) |
| `--commit [ref]` | `commit <short-sha> — <subject>` | A single commit vs its parent (`ref` default `HEAD`) |
| `--range <range>` | `commit range <range>` | The net diff across a git range (`A..B` or `A...B`) |
| `--patch <event-id>` | `NIP-34 patch <short-event-id>` | Nostr patch event applied to temporary review branch |
| `<ref>` | `changes vs <ref>` | Working tree vs an arbitrary commit/branch/tag |

The working-tree scopes (no-argument, `--staged`, `--unstaged`, `<ref>`) include untracked files; the commit scopes (`--branch`, `--commit`, `--range`) and patch mode do not (`FR-srm-commit-mode-no-untracked`). The scope label appears in the brief summary's `Reviewing:` line (see Conversation Surface).

An unrecognized argument, a malformed `--range`, or a ref/base that does not resolve prints a usage block listing every scope and stops:

```
Usage: /shepherd-review [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | <ref>]

Review changes in the macOS CRPG.

Scopes:
  (default)        All uncommitted changes (staged + unstaged + untracked) vs HEAD
  --staged         Only staged changes
  --unstaged       Only unstaged changes and untracked files
  --branch [base]  Commits on the current branch vs <base> (default: main)
  --commit [ref]   A single commit vs its parent (default: HEAD — your last commit)
  --range <range>  A commit range, e.g. main..HEAD or v1.0..v1.1
  <ref>            Working tree vs a commit, branch, or tag
```

The command is implemented as `.claude/commands/shepherd-review.md` plus an opencode skill at `.config/opencode/skills/shepherd-review/SKILL.md`. Installed globally via `scripts/install-command.sh` (`AC-srm-install-symlink`).

## Conversation Surface

The agent conversation flow follows the shared review flow (see `../../product/shepherd-review.md` and the `/shepherd-review` command prompt) with three macOS-specific details:

1. The brief summary mentions the native app:
   ```
   Session: <session-id>
   Reviewing: <scope-label>

   Opening <N> files in the macOS app for review.
   <M> files excluded (lockfiles, generated, binary).
   ```
   The remaining lines (counts, exclusion suffix, blank-line separators) match the shared brief-summary format.

2. The launch step invokes the launcher script `scripts/shepherd-launch.sh` (see "Launch and Handoff" below).

3. The "Cancel" branch of the interactive prompt does **not** close the native window. The user keeps full control over the window via standard macOS chrome (`AC-crp-macos-close-last-window`); cancelling only ends the agent's part of the session. This matches `AC-srm-cancel`.

All other surface details — error messages, `AskUserQuestion` options ("Added comments", "Reviewed, no comments", "Cancel"), completion summary numbers, feedback action menu (apply, discuss, save, nothing), input-recognition synonyms — are defined by the `/shepherd-review` command prompt (`.claude/commands/shepherd-review.md`).

## Launch and Handoff

After context generation, the agent invokes:

```
<repo-root>/scripts/shepherd-launch.sh [--context <context-json-path>] <abs-path-1> <abs-path-2> ... <abs-path-N>
```

The launcher (existing) writes `~/.shepherd/sessions/<session-id>/session.json` with:

- `sessionID`, `workingDirectory`, `projectName` — derived as today
- `files[]` — one entry per validated file, in priority order from `FR-sr-priority-ordering`
- `reviewContext` — the structured context object (overall + files), populated from the agent-supplied context JSON when `--context` is provided; `null` when invoked single-file from `/shepherd` (existing behavior). The `<context-json-path>` is an agent-owned temp file (e.g. produced via `mktemp`) — not a session-scoped file — so the agent does not need to know the session ID before invoking the launcher. The launcher inlines the JSON into `session.json.reviewContext` at launch time; the temp file is no longer needed afterward and the agent deletes it.

The launcher then runs the prebuilt `ShepherdApp` binary detached with `--session <id>` and prints `Session: <id>` plus a "loaded N files" summary on stdout — matching the existing contract so the agent's stdout-parsing logic is identical to `/shepherd`.

The native window opens, reads the session JSON via `SessionClient.loadSession`, and presents:

- **Multi-file three-column layout** when `files.count >= 2` (per `./code-review-prompt.md` Multi-File State).
- **Single-file two-column layout** when only one file is reviewable.
- **Inspector ReviewContextSection** populated with `reviewContext.overall.neutral` and `reviewContext.overall.review` as visually distinct sections (`AC-srm-context-in-app`, inheriting `FR-crp-review-context-overall`).
- **Per-file ReviewContextPanel** populated with `reviewContext.files[<active-path>]` for the currently active tab; updates when the user switches files (`FR-crp-review-context-per-file`). When a file's per-file context is missing, the panel hides for that tab (graceful-missing per `AC-crp-context-graceful-missing`).

After launch the agent presents the standard `AskUserQuestion`. When the user clicks **Done** in the native window, the application writes `~/.shepherd/sessions/<session-id>/prompt-output.md` and closes the window per `FR-crp-macos-auto-close`. The agent reads that file when the user selects "Added comments" and proceeds with the standard completion summary.

## Tab Order and File Browser

The file browser sidebar lists the `files[]` entries in the order they appear in the session payload, which is the priority order defined by `FR-sr-priority-ordering`. The first file is the active tab on launch (`AC-sr-sorted-file-list`). Per-file comment counts and review-status indicators are owned by `./code-review-prompt.md` and apply unchanged.

When the user adds comments and clicks Done, the prompt aggregator (`PromptBuilder` in `SharedModels`) emits one section per file in priority order, per `FR-crp-multi-file-prompt-format`. Files without comments are omitted from the prompt.

## Nothing to Review (Empty Changeset)

Per `FR-srm-no-blank-window`, the agent never launches the native app when the selected scope resolves to zero reviewable files — this is the design fix for the "blank window" symptom. Before invoking the launcher, the agent checks the changed-file count (after filtering). If it is zero, it prints a scope-specific message and stops. No `session.json` is written, the launcher is not called, and no window appears. Messages by scope:

| Scope | Message |
|---|---|
| default | `No uncommitted changes to review.` |
| `--staged` | `No staged changes to review.` |
| `--unstaged` | `No unstaged changes to review.` |
| `--branch [base]` | `No commits on <branch> relative to <base>. Nothing to review.` |
| `--commit [ref]` | `Commit <ref> has no changes to review.` |
| `--range <range>` | `No changes in range <range>. Nothing to review.` |
| any scope, all filtered | `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` |

When the agent *does* launch, it first clears any stale `prompt-output.md` and overwrites `session.json` for the session ID, so a reused window (same project root) reflects the current invocation rather than leftover tabs from a prior review (`FR-srm-no-blank-window` clause 2; consistent with `AC-crp-macos-window-deduplicate`).

## Error Cases

All error messages follow the `/shepherd-review` command prompt verbatim, with two macOS-only additions:

- **Binary missing** — when the launcher cannot find `.build/release/ShepherdApp`:
  ```
  macOS app binary not found at <path>.
  Re-run ./scripts/install-command.sh from the Shepherd repo to build it.
  ```
  This is the existing message emitted by `shepherd-launch.sh`. The agent surfaces it as-is and stops.

- **Toolchain missing at install time** — handled by the install script per `AC-srm-install-degraded`. The slash command itself never sees this branch; if the binary is missing at invocation time, the previous case applies.

## NIP-34 Patch Metadata Display

When reviewing a patch via `--patch <event-id>`, the native macOS window displays patch-specific metadata in a dedicated section above the overall review context in the right inspector pane. The metadata section appears only for patch reviews; it is absent for all other review modes.

### Patch Metadata Section Layout

The section has a distinct visual style to separate it from the review context sections below:
- **Background**: Subtle gray background (`NSColor.quaternaryLabelColor` with reduced opacity) to distinguish from the white review context sections
- **Padding**: 12pt all sides
- **Corner radius**: 8pt
- **Margin bottom**: 16pt (spacing before the overall review context section)

### Metadata Fields

Each field is laid out as a **label-value pair** in a vertical stack:

1. **Patch ID**
   - **Label**: "Patch ID" (secondary text color, 11pt system font)
   - **Value**: First 8 characters of event ID (e.g., `abc12345`) in monospace font with a "Copy Full ID" button inline. Clicking the button copies the full 64-char hex ID to clipboard and shows a brief checkmark animation.

2. **Author**
   - **Label**: "Author" (secondary text color, 11pt)
   - **Value**: Display name if known (resolved from local roster or NIP-05), otherwise `npub1...` (bech32-encoded pubkey, truncated to first 12 chars). Regular system font, 13pt.

3. **Commit Message**
   - **Label**: "Message" (secondary text color, 11pt)
   - **Value**: First line of patch commit message (truncated to 60 chars with `…` if longer). System font, 13pt. If message is empty, show `(no message)` in tertiary label color.

4. **Parent Commit**
   - **Label**: "Parent" (secondary text color, 11pt)
   - **Value**: Short hash (8 chars) in monospace font. If no parent commit tag exists (initial commit patch), show `(none)` in tertiary label color.

5. **Status**
   - **Label**: "Status" (secondary text color, 11pt)
   - **Value**: Status tag from NIP-34 event (`open`, `merged`, `closed`, `draft`) with color-coded badge:
     - **Open**: Blue background (`NSColor.systemBlue.withAlphaComponent(0.15)`), blue text
     - **Merged**: Green background (`NSColor.systemGreen.withAlphaComponent(0.15)`), green text
     - **Closed**: Red background (`NSColor.systemRed.withAlphaComponent(0.15)`), red text
     - **Draft**: Gray background (`NSColor.systemGray.withAlphaComponent(0.15)`), gray text
   - Badge has 4pt padding, 4pt corner radius, medium system font weight.

### Visual Example

```
┌─────────────────────────────────────────┐
│ Patch ID: abc12345 [Copy Full ID]      │
│ Author: Alice (alice@example.com)      │
│ Message: Add NIP-34 patch review spp…  │
│ Parent: deadbeef                        │
│ Status: [OPEN]                          │
└─────────────────────────────────────────┘
   ↓ (16pt spacing)
┌─────────────────────────────────────────┐
│ Overall Review Context                  │
│ (neutral + review sections)             │
└─────────────────────────────────────────┘
```

### Requirements Satisfied

- `FR-sr-patch-metadata-display`: All five metadata fields displayed
- `AC-sr-patch-metadata-displayed`: Author name resolution, status color coding
- Author pubkey-to-name resolution: engineering dependency (see Dependencies below)

## NIP-34 Patch Thread Replies Display

When reviewing a patch, the native window surfaces the live review-thread conversation from other agents and humans alongside the patch metadata, so a reviewer sees what other participants already said before adding their own comments. Implements `FR-sr-patch-replies-display`.

### Data source

Replies are fetched by the `/shepherd-review` command prompt (see engineering spec) and delivered inside `reviewContext.patchMetadata.replies` as a JSON array. Each entry carries: `id`, `author` (resolved display name), `authorPubkey`, `isBot`, `content`, `timestamp` (seconds), and an optional `lineAnchor` (`filePath` + `startLine`/`endLine`). The native app does not fetch from relays itself — it only renders what the command handed off. Replies are read-only conversation context, not user-editable comments.

### Two render surfaces

1. **Inspector "Patch Thread" section** -- a distinct section directly below the patch metadata section, listing every reply regardless of anchoring. Each row shows the author (with a `BOT` badge for agent replies), timestamp, content, and -- when anchored -- a `file:line` chip. The section header reads `Patch Thread (<count>)` and shows a "No replies yet on this patch." placeholder when empty (in which case the section is hidden entirely per the gating rule below).

2. **Inline on the diff** -- replies carrying a `lineAnchor` are also rendered inline at their anchored file + line span, inside the code viewer, alongside the reviewer's own editable Comment bubbles. They are visually distinct: read-only, no edit/delete chrome, and a bot/human marker (robot glyph + purple tint for bots, person glyph + orange tint for humans) so the reviewer can tell at a glance which comments are theirs versus the thread's.

### Bot vs human visual marker

| Author type | Glyph | Tint | Badge |
|---|---|---|---|
| Bot / agent | `cpu` | Purple (`Color.purple`, 0.08 fill) | `BOT` capsule |
| Human | `person.fill` | Orange (`Color.orange`, 0.08 fill) | none |

### Gating

The inspector section renders only when `patchMetadata` is present (patch review) AND `patchMetadata.replies` is non-empty. Inline rendering applies only to the subset of replies whose `lineAnchor.filePath` equals the active file's absolute path. Non-patch reviews never show either surface.

### Requirements Satisfied

- `FR-sr-patch-replies-display`: Both render surfaces; bot/human marker; status events excluded upstream
- Live NIP-34 review loop: shared thread visible across agents reviewing the same patch

## Patch Thread Replies -- Live Refresh

The section above renders the launch-time snapshot baked into `session.json`. `FR-sr-patch-replies-live` makes it live: replies posted after the window opens appear without relaunching, via an in-app Nostr relay subscription (`FR-sr-relay-client`).

### Architecture (in-process relay subscription)

The native app subscribes to Nostr relays itself through a `RelayClient` -- no sidecar file, no poll timer, no external `nak` process. The live implementation speaks NIP-01 over `URLSessionWebSocketTask` (cross-platform macOS/iOS): it opens one WebSocket per configured relay, sends a `REQ` frame for kind:1 events whose root `e` tag is the patch event id, and yields events as they arrive (stored replies first, then live), deduplicated by event id. Each incoming event is mapped to a `PatchReply` and appended to the reply list in timestamp order, skipping duplicates by id. The inspector section and inline bubbles re-render automatically from that single reply list -- no per-view wiring. Because the transport is `URLSessionWebSocketTask`, the same live path serves a future iOS app with no change.

The initial snapshot baked into `session.json` at launch (produced by the command prompt via `scripts/shepherd-patch-poll.sh --once`) remains as a baseline so the inspector has replies to show before the subscription delivers; the in-app subscription then provides liveness on top.

### Gating and lifecycle

The subscription starts when a patch review window opens and `patchMetadata` is present, and is cancelled when the window closes. Non-patch reviews never subscribe. If no relays are reachable, the app renders the initial snapshot only -- the review is unaffected.

### Why a relay client, not poll-and-reload

An in-process relay subscription is the cross-platform transport: `URLSessionWebSocketTask` works on macOS and iOS, so the same live-reply path serves a future mobile app with no shell-side poller. It also gives sub-second liveness (events arrive as published) at lower relay load than polling. The cost is a small Swift Nostr event model + WebSocket relay client in the app -- no third-party dependency. The shell-side `--once` snapshot keeps `nak` as a launch-time convenience only.

### Requirements Satisfied

- `FR-sr-patch-replies-live`: in-process relay subscription + reactive append; subscription lifecycle

## Concurrency

Two `/shepherd-review` invocations from different working directories produce different session IDs (basename of project root), open independent windows (`FR-crp-macos-window-management`), and read/write disjoint session directories (`AC-srm-session-isolation`). A second invocation from the same project root with the same session ID brings the existing window to front and updates that window's session JSON before reload — same behavior as `/shepherd` (`AC-crp-macos-window-deduplicate`).

## Accessibility

Inherited from `./code-review-prompt.md`:
- `NFR-crp-accessibility-keyboard` — full keyboard navigation across the file browser, code viewer, and inspector
- VoiceOver labels for ReviewContextSection ("Overall changeset context") and ReviewContextPanel ("Review context for `<filename>`") so screen-reader users can distinguish neutral context from review feedback by their respective subsection labels

The orchestration surface (agent conversation) inherits accessibility from the host agent.

## Requirement Traceability

| Slug | Design coverage |
|---|---|
| `FR-sr-changeset-detection` | Conversation Surface (inherited from the `/shepherd-review` command prompt) |
| `FR-sr-file-filtering` | Conversation Surface (inherited) |
| `FR-sr-priority-ordering` | Tab Order and File Browser |
| `FR-sr-changeset-overview` | Launch and Handoff (`reviewContext.overall`) |
| `FR-sr-per-file-context` | Launch and Handoff (`reviewContext.files`); Tab Order |
| `FR-sr-context-handoff` | Launch and Handoff (session-JSON-embedded `reviewContext`) — supplanted by `FR-srm-context-handoff` per `../../product/macos/shepherd-review.md` |
| `FR-sr-file-list-display` | Conversation Surface (brief summary format) |
| `FR-sr-iteration-loop` | Conversation Surface (auto-open, AskUserQuestion); Launch and Handoff |
| `FR-sr-multi-file-launch` | Launch and Handoff — supplanted by `FR-srm-multi-file-launch` |
| `FR-sr-feedback-collection` | Conversation Surface (Done → prompt-output.md → "Added comments") |
| `FR-sr-completion-summary` | Conversation Surface (inherited summary + feedback menu) |
| `FR-sr-command-file` | Command Syntax — supplanted by `FR-srm-command-file` |
| `FR-sr-install` | Command Syntax (install reference) — supplanted by `FR-srm-install` |
| `FR-sr-scope-argument` | Command Syntax — superseded on macOS by `FR-srm-scope-modes` |
| `FR-srm-scope-modes` | Command Syntax (scope table, usage block) |
| `FR-srm-branch-scope` | Command Syntax (`--branch` row) |
| `FR-srm-commit-scope` | Command Syntax (`--commit` row) |
| `FR-srm-range-scope` | Command Syntax (`--range` row) |
| `FR-srm-commit-mode-no-untracked` | Command Syntax (untracked-files note) |
| `FR-srm-no-blank-window` | Nothing to Review (Empty Changeset) |
| `AC-srm-default-scope`, `AC-srm-branch-scope`, `AC-srm-commit-scope`, `AC-srm-range-scope`, `AC-srm-commit-excludes-untracked` | Command Syntax (scope table) |
| `AC-srm-empty-no-launch` | Nothing to Review (Empty Changeset) |
| `FR-sr-git-required` | Conversation Surface (inherited error message) |
| `AC-sr-happy-path` | Conversation Surface + Launch and Handoff (full flow) |
| `AC-sr-auto-open` | Conversation Surface (no confirmation prompt) |
| `AC-sr-batch-open` | Launch and Handoff; Tab Order — supplanted by `AC-srm-batch-open-native` |
| `AC-sr-context-in-crpg` | Launch and Handoff — supplanted by `AC-srm-context-in-app` |
| `AC-sr-interactive-prompt` | Conversation Surface |
| `AC-sr-completion-summary` | Conversation Surface |
| `AC-sr-sorted-file-list` | Tab Order and File Browser |
| `AC-sr-unified-prompt` | Launch and Handoff (Done → prompt-output.md) |
| `AC-sr-skip-file`, `AC-sr-quit-early` | Conversation Surface (inherited) |
| `AC-sr-no-changes`, `AC-sr-not-git-repo`, `AC-sr-all-filtered` | Conversation Surface (inherited error messages) |
| `AC-sr-invokes-shepherd` | Launch and Handoff (single launcher invocation with all paths + context) |
| `AC-sr-list-command` | Launch and Handoff (file browser shows all files; ReviewContext sections show overall + per-file) |
| `AC-sr-install-global` | Command Syntax (install reference) — supplanted by `AC-srm-install-symlink` |
| `AC-sr-filters-*`, `AC-sr-includes-config`, `AC-sr-excludes-deleted` | Conversation Surface (inherited filtering) |
| `FR-sr-patch-source` | Command Syntax (`--patch` mode); NIP-34 Patch Metadata Display |
| `FR-sr-patch-fetch` | Conversation Surface (inherited from command prompt - relay queries, event validation) |
| `FR-sr-patch-validation` | Conversation Surface (inherited - event kind, diff format, repo match, parent commit checks) |
| `FR-sr-patch-application` | Conversation Surface (inherited - review branch creation, patch apply, changeset detection, stash/restore) |
| `FR-sr-patch-metadata-display` | NIP-34 Patch Metadata Display (all five fields: ID, author, message, parent, status) |
| `FR-sr-patch-replies-display` | NIP-34 Patch Thread Replies Display (inspector section + inline anchored bubbles; bot/human marker) |
| `FR-sr-patch-replies-live` | Patch Thread Replies -- Live Refresh (in-app relay subscription + reactive append) |
| `FR-sr-relay-client` | Patch Thread Replies -- Live Refresh (in-process Nostr WebSocket relay client) |
| `AC-sr-patch-happy-path` | Command Syntax + Conversation Surface + NIP-34 Patch Metadata Display (full patch review flow) |
| `AC-sr-patch-event-not-found` | Conversation Surface (inherited error handling) |
| `AC-sr-patch-invalid-diff` | Conversation Surface (inherited validation) |
| `AC-sr-patch-application-conflicts` | Conversation Surface (inherited git apply error handling) |
| `AC-sr-patch-metadata-displayed` | NIP-34 Patch Metadata Display (author resolution, status color coding) |
| `AC-sr-patch-invalid-event-id` | Conversation Surface (inherited validation) |
| `AC-sr-patch-conflicting-args` | Command Syntax (usage message for conflicting args) |
