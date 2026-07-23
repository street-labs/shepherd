---
product-hash: 72eba4558b538ad77ca4b4593719d1cb13efb0987d3f774a64d15094b8bddc9e
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — macOS Technical Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/macos/shepherd-review.md` for macOS-specific requirements.
> Based on design in `../../design/macos/shepherd-review.md`

## Technical Approach

`/shepherd-review` is a thin orchestration layer on top of infrastructure that already exists. There is no new application code, no new Swift target, no new model, and no new service. The macOS-specific work is confined to two places:

1. **Command file** — `.claude/commands/shepherd-review.md` (and peer opencode skill) that orchestrates the review and invokes `scripts/shepherd-launch.sh`, writing the structured review context to a temp JSON file passed via `--context`.
2. **Launcher extension** — `scripts/shepherd-launch.sh` gains an optional `--context <path>` flag. When provided, the launcher reads the file's JSON contents and substitutes them for the existing hard-coded `"reviewContext": null` value in the generated `session.json`.

Everything else is reused unchanged:

- The native binary (`ShepherdApp`) already supports `--session <id>` and already reads `session.json` via `SessionClient.loadSession`.
- `SessionData` and `ReviewContext` Codable models already encode the overall + per-file neutral/review structure (`engineering/apps/macos/Sources/SharedModels/SessionData.swift`, `.../ReviewContext.swift`).
- The multi-file three-column layout, ReviewContextSection (overall), and ReviewContextPanel (per-file) are all implemented for `code-review-prompt` on macOS.
- The Done-writes-`prompt-output.md` round-trip is unchanged from `/shepherd`.
- Session ID derivation (project-root basename) is unchanged.

The agent prompt itself — changeset detection, filtering, priority ordering, neutral/review context generation, brief conversation summary, `AskUserQuestion` interactive prompt, completion summary, feedback action menu — lives canonically in the `/shepherd-review` command prompt (`.claude/commands/shepherd-review.md` and its opencode mirror). **This spec does not duplicate that content; it documents only the macOS-specific delta.**

> Implements: `FR-srm-command-file`, `FR-srm-multi-file-launch`, `FR-srm-context-handoff`, `NFR-srm-no-server`

---

## Components / Files Touched

| File | Change | Purpose |
|---|---|---|
| `.claude/commands/shepherd-review.md` | **MODIFIED** | Claude Code prompt that orchestrates the review and invokes the macOS launcher with `--context`. Extended with the commit-scoped modes (`--branch`/`--commit`/`--range`) and the empty-changeset guard. Patch mode now calls `scripts/shepherd-patch-poll.sh --once` for the initial reply snapshot and spawns the poller detached after launch (`FR-sr-patch-replies-live`). |
| `.config/opencode/skills/shepherd-review/SKILL.md` | **MODIFIED** | Opencode mirror of the Claude command (kept byte-aligned, including the new scope modes). |
| `scripts/shepherd-launch.sh` | **MODIFIED** | Accept optional `--context <path>` before positional file args; inline its JSON into `session.json.reviewContext`. |
| `scripts/install-command.sh` | **MODIFIED** | Append `"shepherd-review"` to the `COMMANDS` array; update help text and final summary. |
| `scripts/shepherd-patch-poll.sh` | **NEW** | Background poller that fetches+maps NIP-34 patch-thread replies (`nak req -k 1 -e`) and atomically writes `~/.shepherd/sessions/<sid>/patch-replies.json`. `--once` mode prints the JSON array for the initial snapshot. Implements `FR-sr-patch-replies-live`. |
| `engineering/apps/macos/Sources/SharedModels/SessionData.swift` | **UNCHANGED** | Already declares `reviewContext: ReviewContext?`. |
| `engineering/apps/macos/Sources/SharedModels/ReviewContext.swift` | **UNCHANGED** | Already declares `overall` and `files` with neutral/review fields. |
| `engineering/apps/macos/Sources/Dependencies/SessionClient.swift` | **MODIFIED** | Adds `loadPatchReplies: @Sendable (String) async throws -> [ReviewContext.PatchReply]` reading the `patch-replies.json` sidecar (returns `[]` when absent). |
| Native app feature reducers (CodeReview, MultiFile, etc.) | **UNCHANGED** | Already handle multi-file `files[]` and render `reviewContext` in ReviewContextSection / ReviewContextPanel. `AppFeature` gains the patch-reply poll timer (`FR-sr-patch-replies-live`). |

The change footprint is intentionally minimal: two new prompt files, one bash flag, and one array entry. No Swift code is touched.

---

## Why session.json instead of a separate context file

An alternative would be to write the review context to a separate file (e.g. `review-context.json`) that the app reads independently of `session.json`. That extra indirection buys nothing here.

The macOS app has no server. It already reads everything it needs from a single `session.json` payload at startup, including a `reviewContext: ReviewContext?` field that the existing launcher hard-codes to `null`. Inlining the context into that payload:

- Eliminates a second file read on the native side and a second async load in the UI's startup path.
- Keeps the handoff atomic — the binary either has full context or none, no mid-load race.
- Reuses the `ReviewContext` Codable model that already exists for future expansion.
- Avoids inventing a new file format or a second IPC mechanism.

### Path-key convention

`reviewContext.files` is a string-keyed map. The keys MUST be the same absolute path strings that appear in the corresponding `files[].path` entries of the same `session.json` payload — i.e., whatever `realpath` produced for each positional argument to the launcher. Any other key form (repo-relative, basename, lowercased) is unsupported. The native side matches per-file context to its tab by exact string equality on this key, so QA fixtures (`TC-srm-launcher-context-flag`) and the agent's context generator must both emit absolute paths.

The cost is that the launcher must inline the agent-supplied context into the JSON it generates. That cost is one bash flag and a substring substitution; see Implementation Plan step 1.

---

## Why `--context <file>` rather than a JSON string argv

Two pragmatic reasons:

1. **Argv length and quoting.** A typical multi-file changeset's structured context (overall + per-file neutral + review for, say, 10 files) is several KB of JSON. macOS's `ARG_MAX` is generous (~256KB), but shells in between (zsh quoting, the agent's `Bash` tool, opencode's command runner) all have edge cases with embedded newlines, double quotes, and backslashes. A file path is one argv slot, no escaping required.
2. **Compatibility with the existing single-file launcher contract.** `/shepherd` invokes the launcher as `shepherd-launch.sh <path>` with positional file args only. Putting `--context <path>` ahead of those positional args (parsed by a small `getopts`-style loop) preserves the existing invocation shape — `/shepherd` does not pass `--context` and continues to work unchanged.

The agent writes the context to a temp file (e.g. `mktemp -t shepherd-review-context.XXXXXX.json`) and passes its path to the launcher. The launcher reads the file, validates it parses (best-effort: a quick `python3 -c 'import json,sys; json.load(open(sys.argv[1]))'` or equivalent — on failure we fall back to embedding the raw bytes and let Swift's `Codable` decoder reject it on load), and substitutes its content for the literal `null` in the generated `session.json`. The agent deletes the temp file after launch returns.

---

## Review Scope Modes — git command mapping

`FR-srm-scope-modes` and its sub-requirements are realized entirely in the command prompt (`.claude/commands/shepherd-review.md` and the opencode mirror) — no Swift or launcher change. The agent parses `$ARGUMENTS`, selects a `SCOPE`, and runs the matching git commands. All commands use `git -C "$REPO_ROOT"` per the CWD rule. The changed-file list each mode produces then flows unchanged through filtering, ordering, and context generation.

Argument parsing precedence (first match wins):

1. empty/blank → `working`
2. `--staged` → `staged`
3. `--unstaged` → `unstaged`
4. `--branch [base]` → `branch`, `BASE="${base:-main}"`
5. `--commit [ref]` → `commit`, `REF="${ref:-HEAD}"`
6. `--range <range>` → `range`, `RANGE="<range>"` (must contain `..`)
7. otherwise treat the token as a ref; if `git rev-parse --verify` succeeds → `ref`, else print usage and stop

### Changed-file detection per scope

| SCOPE | Name-status command(s) | Untracked appended? |
|---|---|---|
| `working` | `git diff HEAD --name-status` + `git diff --cached --name-status` | yes (`git ls-files --others --exclude-standard`) |
| `staged` | `git diff --cached --name-status` | no |
| `unstaged` | `git diff --name-status` | yes |
| `ref` | `git diff "$DIFF_REF" --name-status` | yes |
| `branch` | `git diff --name-status "$BASE"...HEAD` | **no** (`FR-srm-commit-mode-no-untracked`) |
| `commit` | `git diff --name-status "$PARENT" "$REF"` | **no** |
| `range` | `git diff --name-status "$RANGE"` | **no** |

### Diff-base command per scope (Step "read all diffs")

The per-file diff command must use the same base as detection so the diffs match the file list:

| SCOPE | Diff command |
|---|---|
| `working` | `git diff HEAD -- <paths>` |
| `staged` | `git diff --cached -- <paths>` |
| `unstaged` | `git diff -- <paths>` |
| `ref` | `git diff "$DIFF_REF" -- <paths>` |
| `branch` | `git diff "$BASE"...HEAD -- <paths>` |
| `commit` | `git diff "$PARENT" "$REF" -- <paths>` |
| `range` | `git diff "$RANGE" -- <paths>` |

### Validation and edge cases

- **`--branch` base resolution** — `git rev-parse --verify "$BASE"` must succeed; otherwise usage/error + stop. The three-dot form (`"$BASE"...HEAD`) diffs from the merge base, so commits landed on `base` after divergence are excluded (`FR-srm-branch-scope`). `git merge-base --is-ancestor`/empty-output is handled by the empty-changeset guard, not a special case.
- **`--commit` parent / root commit** — resolve `REF` (default `HEAD`) via `git rev-parse --verify`. Determine the parent: if `git rev-parse --verify "$REF^" ` succeeds, `PARENT="$REF^"`; if it fails (root commit, no parent), use the canonical empty-tree object `PARENT=4b825dc642cb6eb9a060e54bf8d69288fbee4904` so every line counts as an addition (`FR-srm-commit-scope`). The short-sha and subject for the scope label come from `git show -s --format='%h — %s' "$REF"`.
- **`--range` validation** — the argument must contain `..`. Split on `..`/`...`, `git rev-parse --verify` each endpoint; any failure → usage/error + stop. The range string is then passed verbatim to `git diff` (`FR-srm-range-scope`).
- **Untracked exclusion** — only `working`, `unstaged`, and `ref` append `git ls-files --others --exclude-standard`. The commit scopes and `staged` never do (`FR-srm-commit-mode-no-untracked`).

### Empty-changeset guard and fresh session (`FR-srm-no-blank-window`)

After detection + filtering, the command computes the reviewable-file count. **If it is zero, the command prints the scope-specific message (see design spec "Nothing to Review") and stops — it does not write `session.json`, does not invoke `shepherd-launch.sh`, and no window opens.** This is the deterministic fix for the blank-window symptom: a blank window can only appear if the launcher is invoked with no files or with stale state, and this guard removes the first case.

For the non-empty path, before invoking the launcher the command removes any stale `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` (already done today) and the launcher overwrites `session.json` for the session ID (existing behavior). Together these satisfy clause 2 of `FR-srm-no-blank-window`: a reused window (same project-root basename) always reflects the current invocation.

> Note (operational): the prebuilt `ShepherdApp` binary is produced at install time (`FR-srm-install`). Editing Swift sources without re-running `./scripts/install-command.sh` leaves a stale binary — a separate cause of "the app looks wrong" that is not a `/shepherd-review` behavior bug. The empty-changeset guard above addresses the changeset-driven blank window; binary staleness is resolved by rebuilding.

---

## NIP-34 Patch Review Support

When invoked with `--patch <event-id>`, the command fetches a NIP-34 patch event from Nostr, applies it to a temporary review branch, and reviews the applied changes using the same filtering, ordering, and context generation pipeline as local branch reviews. Patch metadata (author, commit message, parent commit, status) is passed to the native macOS app for display.

### NIP-34 Protocol Overview

NIP-34 defines git patches as Nostr events:
- **Event kind**: `1617` (proposal) or `1621` (patch)
- **Event content**: Unified diff (starts with `diff --git`, contains `+++`/`---` headers, `@@` hunks)
- **Event tags**:
  - `a`: Repository reference (`30617:<repo-owner-pubkey>:<repo-d-tag>`)
  - `commit`: Commit hash
  - `parent-commit`: Parent commit hash (omitted for initial commit)
  - `author`: Commit author info
  - `status`: Patch status (`open`, `merged`, `closed`, `draft`)

### Argument parsing for `--patch`

Argument parsing precedence is extended (first match wins):

1. empty/blank → `working`
2. `--staged` → `staged`
3. `--unstaged` → `unstaged`
4. `--branch [base]` → `branch`
5. `--commit [ref]` → `commit`
6. `--range <range>` → `range`
7. **`--patch <event-id>` → `patch`, `EVENT_ID="<event-id>"`** (new)
8. otherwise treat as ref

Conflicting arguments (`--patch` combined with `--staged`, `--unstaged`, `--branch`, `--commit`, or `--range`) are rejected with a usage message per `AC-sr-patch-conflicting-args`.

Event ID validation: must be a 64-character lowercase hex string. Invalid format is rejected immediately with `AC-sr-patch-invalid-event-id` error message.

### NIP-34 fetch and validation workflow

The command prompt implements patch mode via bash commands using generic Nostr relay queries (not Buzz-specific CLI). The workflow:

1. **Relay configuration** — Read relay URLs from:
   - Environment variable `NOSTR_RELAYS` (comma-separated list), or
   - Config file `~/.config/nostr/relays.txt` (one URL per line), or
   - Default public relays: `wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band`

2. **Fetch event** — Query relays for the event ID using a generic Nostr client (e.g., `nak`, if available; otherwise fallback to `curl` + relay WebSocket protocol). The query is a standard `REQ` subscription filter: `{"ids": ["<event-id>"]}`. If the event is not found on any relay, report `AC-sr-patch-event-not-found` error and stop.

3. **Validate event** (`FR-sr-patch-validation`):
   - Event kind must be `1617` or `1621`. Reject others.
   - Event content must start with `diff --git` and contain `+++`/`---`/`@@` markers. Reject malformed diffs with `AC-sr-patch-invalid-diff` error.
   - If `a` tag exists, compare repo ID against local config (if available). Mismatch produces a warning but does not block.
   - If `parent-commit` tag exists, check if commit exists locally (`git rev-parse --verify --quiet <parent>`). Missing parent produces a warning but does not block.

4. **Extract patch diff and metadata**:
   - Diff: event `.content` field
   - Author: event `.pubkey` or `author` tag
   - Commit message: first line of `.content` before the diff starts, or `m` tag if present
   - Parent commit: `parent-commit` tag value (if present)
   - Status: `status` tag value (default `open` if tag absent)
   - Short event ID: first 8 characters of event ID

### Patch application workflow (`FR-sr-patch-application`)

After successful fetch and validation:

1. **Stash uncommitted changes**:
   ```bash
   if [[ -n $(git status --porcelain) ]]; then
     git stash push -u -m "shepherd-review --patch stash"
     STASHED=1
   fi
   ```

2. **Determine base commit**:
   - If `parent-commit` tag exists and resolves locally: use it
   - Otherwise: fallback to merge-base of current branch with `main`

3. **Create review branch**:
   ```bash
   REVIEW_BRANCH="review/patch-${EVENT_ID:0:8}"
   git branch -D "$REVIEW_BRANCH" 2>/dev/null  # delete if exists
   git checkout -b "$REVIEW_BRANCH" "$BASE_COMMIT"
   ```

4. **Apply patch**:
   - Write event `.content` to a temp file
   - Apply via `git apply --index <temp-file>` (adds changes to index)
   - If apply fails, report `AC-sr-patch-application-conflicts` error with the git error message and stop. The review branch exists but patch is not applied. User must resolve manually.

5. **Detect changeset**:
   - After successful apply, compare review branch to its parent: `git diff --name-status <parent> HEAD`
   - This produces the file list that flows through filtering, ordering, and context generation

6. **Post-review cleanup** (after user completes or cancels review):
   - Return to original branch: `git checkout <original-branch>`
   - Pop stash if one was created: `if [ "$STASHED" = 1 ]; then git stash pop; fi`
   - **Do not auto-delete review branch** — user may want to inspect, merge, or delete it manually

### Patch metadata handoff to native app

The patch metadata (now including thread replies) is included in the structured context JSON passed via `--context`:

```json
{
  "overall": { "neutral": "...", "review": "..." },
  "files": { "/abs/path": { "neutral": "...", "review": "..." } },
  "patchMetadata": {
    "eventID": "abc123...def789 (64-char full ID)",
    "shortEventID": "abc12345",
    "author": "npub1abc..." or "alice@example.com",
    "commitMessage": "Add NIP-34 patch review support",
    "parentCommit": "deadbeef" or null,
    "status": "open" | "merged" | "closed" | "draft",
    "replies": [
      {
        "id": "<reply event id>",
        "author": "borg" or "npub1...",
        "authorPubkey": "<raw pubkey>",
        "isBot": true | false,
        "content": "nits on line 12",
        "timestamp": 1700000000,
        "lineAnchor": {
          "filePath": "/abs/path/matching/a/files[].path",
          "startLine": 12,
          "endLine": 14
        } or null
      }
    ]
  }
}
```

The native macOS app reads `session.json.reviewContext.patchMetadata` and displays it in a dedicated UI section (see design spec "NIP-34 Patch Metadata Display"). If `patchMetadata` is absent (non-patch review), the section is not shown.

### Patch-thread replies fetch and handoff (FR-sr-patch-replies-display)

After the patch event is validated, the command prompt fetches the review-thread replies so other agents' and humans' comments render in the native app. The fetch is a second relay query keyed on the patch event id:

```bash
if command -v nak >/dev/null 2>&1; then
  RELAY_LIST=$(echo "$RELAYS" | tr ',' ' ')
  REPLIES_JSON=$(nak req -k 1 -e "$EVENT_ID" $RELAY_LIST 2>/dev/null)
fi
```

`nak req -e <id>` filters on the `e` tag. Without `nak`, fall back to a WebSocket query with filter `{"#e": ["$EVENT_ID"], "kinds": [1]}`.

Filtering rules (implemented in the command prompt):
- Keep only `kind:1` events. Exclude kinds `1630`–`1633` (NIP-34 patch status transitions) and the patch event itself — those are status changes, not comments.
- Root check: keep events whose `e` tag has marker `"root"` pointing at `$EVENT_ID`, OR whose first `e` tag value equals `$EVENT_ID` (tolerate a missing marker).

Each surviving event is mapped to a `PatchReply`:
- `id`: the reply event's 64-char id.
- `author` / `authorPubkey`: resolve `.pubkey` to a display name (roster → NIP-05 → truncated npub) and keep the raw pubkey.
- `isBot`: true when the author is a known agent/bot (roster flag, NIP-05 host pattern containing `agent`/`bot`, or a kind:0 `bot` profile flag). Default `false` (human) when uncertain.
- `content`: `.content`. `timestamp`: `.created_at` (seconds).
- `lineAnchor`: optional, parsed from a range tag. `filePath` MUST be the absolute path matching a `files[].path` entry so the native app can correlate it to a tab; `startLine`/`endLine` are 1-indexed. Absent anchor → `null`.

The assembled array is placed in `patchMetadata.replies` (`[]` when there are none). The fetch is best-effort: a relay failure or empty result does not block the review.

The native app renders replies in two places (see design spec "NIP-34 Patch Thread Replies Display"):
- A `PatchRepliesSectionView` in the inspector, gated on `patchMetadata != nil && !replies.isEmpty`.
- Anchored replies rendered inline in `CodeViewerView` via `PatchReplyInlineView`, filtered to the active file's absolute path. These are read-only and visually distinct from the user's editable `Comment` bubbles.

`ReviewContext.PatchMetadata` carries `replies: [PatchReply]`. A custom `Codable` init decodes `replies` with `decodeIfPresent ?? []` so pre-`FR-sr-patch-replies-display` payloads (which omit the key) still decode without error.

### Patch-thread replies live refresh (FR-sr-patch-replies-live)

The initial snapshot is baked into `session.json` at launch. For live updates, a background poller and an app-side timer cooperate via a sidecar file -- poll-and-reload, no in-app relay client.

**Poller** (`scripts/shepherd-patch-poll.sh`, new): the single source of truth for fetch+map. `--once <event-id>` prints a `PatchReply` JSON array to stdout (used by the command prompt for the initial snapshot, replacing the inline `nak`/mapping recipe). Loop mode `<session-id> <event-id> [interval=30] [max-minutes=60]` re-runs `nak req -k 1 -e "$EVENT_ID"` every `interval` seconds, maps events (kind:1 root replies only; excludes 1630-1633 status transitions and the patch event itself; author from `~/.config/nostr/roster.json` else truncated hex pubkey; `isBot` from roster `bot` flag; `lineAnchor` parsed from a `["range", file, start, end]` tag), and atomically writes `~/.shepherd/sessions/<sid>/patch-replies.json` (temp file + `mv`). It exits when `prompt-output.md` appears or after `max-minutes`. Best-effort: if `nak` or `python3` is missing, `--once` prints `[]` and loop mode exits 0 immediately.

The command prompt spawns it detached after launch (patch mode only):
```bash
nohup bash "$SHEPHERD_ROOT/scripts/shepherd-patch-poll.sh" "$SESSION_ID" "$EVENT_ID" 30 60 >/dev/null 2>&1 & disown
```

**App side** (`SessionClient` + `AppFeature`):
- `SessionClient.loadPatchReplies(sessionID)` reads `~/.shepherd/sessions/<sid>/patch-replies.json`, returning `[]` when the file is absent.
- `AppFeature` starts a `continuousClock` timer (every 30s) when session data loads and `patchMetadata != nil` with a non-nil session ID. Each tick calls `loadPatchReplies` and sends `.patchRepliesRefreshed([PatchReply])`. The reducer deduplicates by `id`, orders oldest-first, and replaces `reviewContextData.patchMetadata?.replies`. The inspector section and inline bubbles re-render automatically because they derive from that array in `@ObservableState` state. The effect is cancellable (`CancelID.patchReplyPolling`) and is cancelled on `windowClosed` or `.stopPatchReplyPolling`.

The first refresh fires immediately on start (so a sidecar already written by the poller is picked up without waiting 30s), then on the interval.

### Author pubkey-to-name resolution

The command prompt attempts to resolve the author pubkey to a human-readable name:
1. Check local roster file `~/.config/nostr/roster.json` (if exists) for a display name mapping
2. Otherwise, check if a NIP-05 identifier is cached
3. Fallback: convert to bech32 `npub1...` and truncate to 12 characters

The resolved name is what appears in `patchMetadata.author`. The native app displays it as-is (no further resolution on the Swift side).

### Scope label for patch mode

When reviewing a patch, the scope label in the brief summary is:
```
Reviewing: NIP-34 patch abc12345
```

Where `abc12345` is the first 8 characters of the event ID.

### Requirements satisfied

- `FR-sr-patch-source`: Full patch review workflow
- `FR-sr-patch-fetch`: Relay queries, event parsing
- `FR-sr-patch-validation`: Event kind, diff format, repo match, parent commit checks
- `FR-sr-patch-application`: Stash, review branch creation, patch apply, changeset detection, cleanup
- `FR-sr-patch-metadata-display`: Metadata JSON passed to native app
- `AC-sr-patch-happy-path`: End-to-end patch review flow
- `AC-sr-patch-event-not-found`, `AC-sr-patch-invalid-diff`, `AC-sr-patch-application-conflicts`, `AC-sr-patch-invalid-event-id`, `AC-sr-patch-conflicting-args`, `AC-sr-patch-metadata-displayed`: Error and validation cases

## Coexistence and Concurrency

Per `FR-srm-coexists` and `AC-srm-coexists`: `/shepherd` and `/shepherd-review` are independent slash commands installed as separate symlinks. Invoking one has no effect on the other.

Per `AC-srm-session-isolation`: each invocation derives `SESSION_ID` inside the launcher from the project-root basename (existing logic at `scripts/shepherd-launch.sh:20`). Two concurrent invocations from different working directories produce different session IDs, write to different `~/.shepherd/sessions/<id>/` directories, and open independent native windows. Two concurrent invocations from the **same** working directory share a session ID and follow the existing window-deduplication behavior from `/shepherd` (`AC-crp-macos-window-deduplicate`); the second invocation overwrites the first's `session.json` (including `reviewContext`) and brings the existing window to front.

---

## Implementation Plan

### Step 1: Extend `scripts/shepherd-launch.sh` to accept `--context`

Insert an option-parser ahead of the existing positional-argument loop. Pseudocode:

```bash
CONTEXT_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --context)
      CONTEXT_FILE="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done
```

After validating files and building the `files[]` array, replace the literal `"reviewContext": null` line with:

```bash
if [ -n "$CONTEXT_FILE" ] && [ -r "$CONTEXT_FILE" ]; then
  # Read the file and use it directly as the reviewContext value.
  CONTEXT_JSON=$(cat "$CONTEXT_FILE")
  printf '  "reviewContext": %s\n' "$CONTEXT_JSON"
else
  printf '  "reviewContext": null\n'
fi
```

Validation is best-effort — if the file is missing or unreadable, fall back to `null` and emit a warning to stderr. If the JSON is malformed, the native side's `JSONDecoder` will fail; the existing `SessionClient` error path surfaces that to the agent's stdout-watcher.

The existing `/shepherd` invocation (no `--context` flag) is unaffected: the parser sees no `--context`, leaves `CONTEXT_FILE=""`, and the launcher produces the same `"reviewContext": null` payload it does today.

**Slug coverage**: `FR-srm-multi-file-launch`, `FR-srm-context-handoff`

### Step 2: Create `.claude/commands/shepherd-review.md`

Create `.claude/commands/shepherd-review.md` implementing the review flow (see `../../product/shepherd-review.md` for the shared behavior) with the following macOS specifics:

1. **Brief summary wording** — the brief summary reads "Opening N files in the macOS app for review." per the design spec's Conversation Surface section.
2. **Launcher path and arguments** — invoke the launcher with `--context`:
   ```bash
   CTX=$(mktemp -t shepherd-review-context.XXXXXX.json)
   # ... agent uses Write tool to populate $CTX with the structured review context JSON
   bash "$REPO/scripts/shepherd-launch.sh" --context "$CTX" "<file1>" "<file2>" ...
   rm -f "$CTX"
   ```
   Writing to a temp file path the agent already knows (rather than to `~/.shepherd/sessions/<id>/review-context.json`) avoids the chicken-and-egg of needing the session ID before it's been generated by the launcher. The launcher inlines the JSON into `session.json` at launch time, so the temp file is no longer needed afterward.
3. **Context source** — the macOS native binary reads the context directly from `session.json` via `SessionClient.loadSession`; there is no separate context endpoint.
4. **Cancel branch** — note that selecting "Cancel" in the `AskUserQuestion` does not close the native window (per `AC-srm-cancel` and `AC-crp-macos-close-last-window`); the user retains the window via standard macOS chrome.

All other prompt content (Step 1 git-repo check, Step 2 repo-root, Step 3 changeset detection, Step 4 filtering, Step 5 priority sort, Step 6 context generation, Step 7 brief summary, Step 8 `AskUserQuestion`, Step 9 completion summary + feedback menu, error-message wording) implements the shared review flow described in `../../product/shepherd-review.md`.

**Slug coverage**: `FR-srm-command-file`, plus inheritance of every shared `FR-sr-*` / `AC-sr-*` slug listed in the macOS product variant's "Apply as-is" section.

### Step 3: Create `.config/opencode/skills/shepherd-review/SKILL.md`

Byte-for-byte mirror of the Claude command file from Step 2, formatted as an opencode skill (matching the structure of the existing `.config/opencode/skills/shepherd/SKILL.md`).

**Slug coverage**: `FR-srm-command-file`

### Step 4: Update `scripts/install-command.sh`

One-line change to the `COMMANDS` array (currently at line 18):

```bash
COMMANDS=("shepherd" "shepherd-review")
```

The existing for-loop at lines 94–100 already handles both Claude Code and opencode symlinks for every entry in the array — no other changes to the symlink logic are needed.

**Slug coverage**: `FR-srm-install`, `AC-srm-install-symlink`, `AC-srm-install-git-pull`

### Step 5: Update help text and final summary in `install-command.sh`

The `--help` block (lines 25–35) and the final "Installed:" summary (lines 134–140) currently mention `/shepherd`. Add `/shepherd-review` to both. The `AC-srm-install-degraded` branch — when Swift is missing, both `/shepherd` and `/shepherd-review` are unavailable — is already handled by the existing `MAC_APP_DIR` block at lines 115–131; the new command transparently inherits that degraded-install behavior because it depends on the same prebuilt binary.

**Symlink behavior on degraded install.** The symlinks for `/shepherd` and `/shepherd-review` are still created when the toolchain is missing — only the prebuild step is skipped, with a stderr warning. At runtime, the launcher's existing missing-binary check (`shepherd-launch.sh:82–86`) surfaces a clear "binary not found" error and exits non-zero, which the slash command surfaces to the user. This is the path exercised by `TC-srm-binary-missing-error` and is the implementation answer to QA's `TC-srm-install-degraded-no-swift` step 4 (the symlink IS present; the binary is what's missing).

**Slug coverage**: `FR-srm-install`, `AC-srm-install-degraded`

### Step 6: Manual smoke test

On a branch with several modified files of mixed types (a TS source file, a config file, a lockfile, a `.png`):

1. Run `./scripts/install-command.sh --force` to refresh symlinks.
2. Confirm `~/.claude/commands/shepherd-review.md` and `~/.config/opencode/skills/shepherd-review/SKILL.md` exist as symlinks.
3. From a Claude Code or opencode session, invoke `/shepherd-review`.
4. Verify: brief summary mentions the macOS app and correct file count; lockfile and PNG are excluded; the native window opens with one tab per reviewable file in priority order; the inspector shows the overall neutral + review sections; switching tabs swaps the per-file ReviewContextPanel; no local web server starts.
5. Click Done in the native window with comments on 1–2 files; select "Added comments" in the agent's `AskUserQuestion`; verify the agent reads `~/.shepherd/sessions/<id>/prompt-output.md` and presents the standard apply/discuss/save/nothing menu.
6. Repeat with no comments and "Reviewed, no comments"; repeat with "Cancel"; repeat from a non-git directory and a branch with no diffs to confirm error messages match those defined in the shared review flow.

---

## Code Map

Only macOS-specific functional requirements appear here. Shared `FR-sr-*` slugs are covered by the prompt content in `.claude/commands/shepherd-review.md` and traced via the shared product spec `../../product/shepherd-review.md`; this spec does not duplicate them.

| Slug | Planned location | Status |
|---|---|---|
| `FR-srm-coexists` | scripts/install-command.sh | implemented |
| `FR-srm-command-file` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-multi-file-launch` | scripts/shepherd-launch.sh; .claude/commands/shepherd-review.md | implemented |
| `FR-srm-context-handoff` | scripts/shepherd-launch.sh; .claude/commands/shepherd-review.md | implemented |
| `FR-srm-install` | scripts/install-command.sh | implemented |
| `FR-srm-scope-modes` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-branch-scope` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-commit-scope` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-range-scope` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-commit-mode-no-untracked` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-srm-no-blank-window` | .claude/commands/shepherd-review.md; .config/opencode/skills/shepherd-review/SKILL.md | implemented |
| `FR-sr-patch-source` | .claude/commands/shepherd-review.md | implemented |
| `FR-sr-patch-fetch` | .claude/commands/shepherd-review.md | implemented |
| `FR-sr-patch-validation` | .claude/commands/shepherd-review.md | implemented |
| `FR-sr-patch-application` | .claude/commands/shepherd-review.md | implemented |
| `FR-sr-patch-metadata-display` | engineering/apps/macos/Sources/SharedModels/ReviewContext.swift; engineering/apps/macos/Sources/ReviewContextFeature/PatchMetadataSectionView.swift | implemented |
| `FR-sr-patch-replies-display` | engineering/apps/macos/Sources/SharedModels/ReviewContext.swift; engineering/apps/macos/Sources/ReviewContextFeature/PatchRepliesSectionView.swift; engineering/apps/macos/Sources/CommentFeature/PatchReplyInlineView.swift; engineering/apps/macos/Sources/CodeViewerFeature/CodeViewerView.swift; engineering/apps/macos/Sources/AppFeature/CodeViewerPanelView.swift; .claude/commands/shepherd-review.md | implemented |
| `FR-sr-patch-replies-live` | scripts/shepherd-patch-poll.sh; engineering/apps/macos/Sources/Dependencies/SessionClient.swift; engineering/apps/macos/Sources/AppFeature/AppFeature.swift; .claude/commands/shepherd-review.md | implemented |

All rows are `implemented`: the existing scope modes, launcher infrastructure, and new NIP-34 patch support. The command prompt implements fetch/validation/application logic via bash + generic Nostr protocol, and the native macOS app displays patch metadata via the `PatchMetadataSectionView` component in the inspector pane.

---

## Performance

`NFR-srm-launch-budget` constrains end-to-end startup to the existing macOS launch budget plus agent context-generation time. Breakdown:

| Phase | Expected time | Notes |
|---|---|---|
| Git repo / changeset / filter / sort | < 100 ms | Identical git commands to the shared flow. |
| Agent context generation | Bounded by agent reasoning | Dominant term for 5–20 files; outside this command's control. |
| Temp context file write | ~5 ms | Single `Write` tool call; KB-scale JSON. |
| Launcher: validate + build session.json | ~50 ms | One `cat` per file plus the new `cat $CONTEXT_FILE` substitution. |
| Native binary cold launch | ≤ 1 s | Per `NFR-crp-macos-launch-time` (existing `/shepherd` budget). |
| Native binary warm launch | ~200 ms | Existing window-deduplicate path. |
| **Total to window-on-screen** | Well under `NFR-srm-launch-budget` | The native path launches the prebuilt binary directly — no web-server startup or browser launch on the critical path. |

The `--context` flag adds a single file read in the launcher and a single substring substitution; the cost is dominated by the existing `cat | json_escape` pass over each file's contents.

---

## Out of Scope

- **Code-signing and notarization.** Inherited from `/shepherd`'s deferred items. The binary continues to run unsigned; first-launch Gatekeeper prompt is acceptable.
- **Auto-rebuild on `git pull`.** Users re-run `./scripts/install-command.sh` to refresh the prebuilt binary; same policy as `/shepherd`.
- **Missing-binary fallback.** Per the macOS product spec's Open Question, no silent fallback if the binary is missing. The launcher emits its existing "binary not found" error and the agent stops; the user installs Swift and re-runs the installer.
- **Resumable sessions** and **custom exclusion patterns** — both deferred at the shared product level; no macOS-specific behavior here.

---

## Requirement Traceability

### macOS-specific (from `product/macos/shepherd-review.md`)

| Slug | Engineering coverage |
|---|---|
| `FR-srm-coexists` | Coexistence and Concurrency; install-command.sh `COMMANDS` array entry |
| `FR-srm-command-file` | Components / Files Touched; Implementation Plan steps 2–3 |
| `FR-srm-multi-file-launch` | Technical Approach; Why session.json; Implementation Plan step 1 |
| `FR-srm-context-handoff` | Technical Approach; Why session.json; Why `--context <file>`; Implementation Plan step 1 |
| `FR-srm-install` | Components / Files Touched; Implementation Plan steps 4–5 |
| `FR-srm-scope-modes` | Review Scope Modes — git command mapping (argument parsing precedence; detection table) |
| `FR-srm-branch-scope` | Review Scope Modes (`branch` row; `"$BASE"...HEAD`; base resolution) |
| `FR-srm-commit-scope` | Review Scope Modes (`commit` row; parent / root-commit empty-tree handling) |
| `FR-srm-range-scope` | Review Scope Modes (`range` row; `..` validation) |
| `FR-srm-commit-mode-no-untracked` | Review Scope Modes (untracked-append column / exclusion note) |
| `FR-srm-no-blank-window` | Review Scope Modes (empty-changeset guard and fresh session) |
| `NFR-srm-launch-budget` | Performance |
| `NFR-srm-no-server` | Technical Approach; Why session.json (no context endpoint) |
| `NFR-srm-platform-restriction` | Out of Scope (no fallback); install script Swift-toolchain check inherits the degraded branch |
| `AC-srm-coexists` | Coexistence and Concurrency |
| `AC-srm-batch-open-native` | Implementation Plan steps 1–2; Performance (no web server) |
| `AC-srm-no-server` | Technical Approach; Why session.json |
| `AC-srm-context-in-app` | Why session.json (inlined into `session.json.reviewContext` for native rendering) |
| `AC-srm-session-isolation` | Coexistence and Concurrency |
| `AC-srm-prompt-roundtrip` | Implementation Plan step 6; existing SessionClient round-trip unchanged |
| `AC-srm-cancel` | Implementation Plan step 2 (Cancel branch note) |
| `AC-srm-install-symlink` | Implementation Plan step 4 |
| `AC-srm-install-degraded` | Implementation Plan step 5; existing toolchain check inherited |
| `AC-srm-install-git-pull` | Implementation Plan step 4 (symlink-based install) |

### Shared (from `product/shepherd-review.md`) — applied as-is on macOS

These slugs are covered by the prompt content in the `/shepherd-review` command prompt. The macOS engineering work does not modify their behavior; it only changes the launcher invoked at the end of the prompt and how context is delivered.

| Slug | Coverage on macOS |
|---|---|
| `FR-sr-changeset-detection`, `FR-sr-file-filtering`, `FR-sr-priority-ordering`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-file-list-display`, `FR-sr-iteration-loop`, `FR-sr-feedback-collection`, `FR-sr-completion-summary`, `FR-sr-scope-argument`, `FR-sr-git-required` | Implemented by the `.claude/commands/shepherd-review.md` prompt content; defined in `../../product/shepherd-review.md`. |
| `FR-sr-command-file` | Supplanted by `FR-srm-command-file`; the macOS variant uses a separate command file. |
| `FR-sr-multi-file-launch` | Supplanted by `FR-srm-multi-file-launch`; the macOS variant launches via `session.json`. |
| `FR-sr-context-handoff` | Supplanted by `FR-srm-context-handoff`; context is embedded in `session.json`. |
| `FR-sr-install` | Supplanted by `FR-srm-install`; same install script extended with one more entry. |
| `NFR-sr-startup-speed` | Performance section (well within budget). |
| `NFR-sr-no-dependencies` | No new packages, no new binaries — only the existing prebuilt `ShepherdApp` and standard shell tools. |
| `NFR-sr-agent-native` | The launcher invocation is a standard `Bash` tool call; no new process model. |
| `NFR-sr-cross-platform` | Not a constraint here — the macOS variant is macOS-only by design (`NFR-srm-platform-restriction`). The git commands themselves remain cross-platform. |
| `AC-sr-happy-path`, `AC-sr-auto-open`, `AC-sr-interactive-prompt`, `AC-sr-completion-summary`, `AC-sr-skip-file`, `AC-sr-quit-early`, `AC-sr-no-changes`, `AC-sr-not-git-repo`, `AC-sr-all-filtered`, `AC-sr-list-command`, `AC-sr-sorted-file-list`, `AC-sr-unified-prompt`, `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`, `AC-sr-excludes-deleted` | Inherited by the new command file's prompt content. Covered via the smoke test in Implementation Plan step 6. |
| `AC-sr-batch-open` | Supplanted by `AC-srm-batch-open-native` (native window with tabs). |
| `AC-sr-context-in-crpg` | Supplanted by `AC-srm-context-in-app`. |
| `AC-sr-invokes-shepherd` | Implementation Plan step 2: single `shepherd-launch.sh` invocation with all paths plus `--context`. |
| `AC-sr-install-global` | Supplanted by `AC-srm-install-symlink` and `AC-srm-install-git-pull`. |
| `FR-sr-patch-source`, `FR-sr-patch-fetch`, `FR-sr-patch-validation`, `FR-sr-patch-application` | NIP-34 Patch Review Support section; implemented by the `.claude/commands/shepherd-review.md` prompt content via bash + generic Nostr protocol queries. |
| `FR-sr-patch-metadata-display` | NIP-34 Patch Review Support section (metadata JSON structure); native macOS app will render via new `PatchMetadataSection` view component. |
| `FR-sr-patch-replies-display` | NIP-34 Patch Review Support section (patch-thread replies fetch + handoff); `PatchRepliesSectionView` + `PatchReplyInlineView` native components. |
| `FR-sr-patch-replies-live` | NIP-34 Patch Review Support section (patch-thread replies live refresh); `scripts/shepherd-patch-poll.sh` poller + `SessionClient.loadPatchReplies` + `AppFeature` poll timer. |
| `AC-sr-patch-happy-path`, `AC-sr-patch-event-not-found`, `AC-sr-patch-invalid-diff`, `AC-sr-patch-application-conflicts`, `AC-sr-patch-metadata-displayed`, `AC-sr-patch-invalid-event-id`, `AC-sr-patch-conflicting-args` | NIP-34 Patch Review Support section (error handling, validation, metadata display). |
