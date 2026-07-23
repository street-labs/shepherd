Orchestrate a guided, multi-file code review of uncommitted changes using the macOS CRPG.

<!-- Implements: FR-srm-command-file, FR-srm-multi-file-launch, FR-srm-context-handoff, FR-srm-scope-modes, FR-srm-branch-scope, FR-srm-commit-scope, FR-srm-range-scope, FR-srm-commit-mode-no-untracked, FR-srm-no-blank-window, FR-sr-patch-source, FR-sr-patch-fetch, FR-sr-patch-validation, FR-sr-patch-application, FR-sr-patch-replies-display, FR-sr-patch-replies-live -->

Allowed tools: Bash, Read, Write

Arguments: $ARGUMENTS

Suggested arguments: [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | --patch <event-id> | <ref>]

## Instructions

You are orchestrating a guided code review. The user has invoked `/shepherd-review` to open all interesting changed files at once in the **macOS** Code Review Prompt Generator (CRPG), using the batch-open feature of `shepherd-launch.sh`.

You provide context up front: a changeset overview with per-file summaries, then open all files in one go. After the user finishes reviewing in the macOS app, you collect the prompt output and present feedback options.

**Efficiency rule: Do not comment on changeset size.** Never say the changeset is "huge", "large", or "significant", and never deliberate about whether to narrow the scope or use a different git strategy. Apply the filtering rules mechanically and proceed. The steps below handle noise reduction — your job is to execute them exactly, not editorialize about volume or improvise alternative approaches.

**CWD rule:** All git commands MUST use `git -C "$REPO_ROOT"` to ensure they run from the repository root, regardless of your current working directory. This prevents silent failures in monorepos where the CWD may be a subdirectory.

Follow these steps in order.

---

### Step 1: Verify git repo, get root, locate Shepherd, and parse arguments

Run a single command to verify the repo and get the root:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git rev-parse --show-toplevel
```

If `--is-inside-work-tree` fails (non-zero exit on the first command), output exactly:

```
Not a git repository. /shepherd-review must be run from within a git repo.
```

Then stop.

Store the second line as REPO_ROOT.

Next, resolve the Shepherd repo root. This skill may be invoked from any repo via a global symlink, so we cannot assume REPO_ROOT contains the launch script. Try these in order:

1. **Saved repo path** (set during install):
```bash
SHEPHERD_ROOT="$(cat ~/.shepherd/repo-path 2>/dev/null)"
```

2. **Symlink resolution** (if installed via manual symlink):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$(cd "$(dirname "$(readlink -f "$(echo ~/.claude/commands/shepherd-review.md)")")"/../.. && pwd)"
```

3. **Current repo fallback** (if running from within the Shepherd repo):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$REPO_ROOT"
```

If `$SHEPHERD_ROOT/scripts/shepherd-launch.sh` still doesn't exist, output: "Could not find shepherd-launch.sh. Run `./scripts/install-command.sh` from the Shepherd repo to set it up." and stop.

Parse the argument: `$ARGUMENTS`. There are three families of scope: **working-tree** scopes (review what's on disk; include untracked files), **commit** scopes (review committed history; never include untracked files), and **patch** scope (review a NIP-34 Nostr patch). Match in this precedence order (first match wins):

- If empty or blank → SCOPE = `working` (default: all uncommitted changes vs HEAD).
- If `--staged` → SCOPE = `staged`.
- If `--unstaged` → SCOPE = `unstaged`.
- If the first token is `--branch` → SCOPE = `branch`. The optional second token is the base; `BASE` = that token or `main` if omitted. Verify the base resolves:
  ```bash
  git -C "$REPO_ROOT" rev-parse --verify "$BASE" 2>/dev/null
  ```
  If it does NOT resolve → output the usage message below and stop.
- If the first token is `--commit` → SCOPE = `commit`. The optional second token is the ref; `REF` = that token or `HEAD` if omitted. Verify the ref resolves with `git -C "$REPO_ROOT" rev-parse --verify "$REF"`. If it does NOT resolve → usage message, stop. Then determine the parent base: if `git -C "$REPO_ROOT" rev-parse --verify "$REF^"` succeeds, set `COMMIT_BASE="$REF^"`; otherwise (root commit, no parent) set `COMMIT_BASE=4b825dc642cb6eb9a060e54bf8d69288fbee4904` (git's canonical empty-tree object).
- If the first token is `--range` → SCOPE = `range`. The second token is `RANGE` and MUST contain `..` (two-dot `A..B` or three-dot `A...B`). Split it on `..`/`...` and verify each endpoint with `git -C "$REPO_ROOT" rev-parse --verify`. If `RANGE` has no `..`, or either endpoint fails to resolve → usage message, stop.
- If the first token is `--patch` → SCOPE = `patch`. The second token is `EVENT_ID` (required — a 64-character lowercase hex string). Validate EVENT_ID format: must be exactly 64 characters of `[0-9a-f]`. If format is invalid → output "Invalid event ID format. Expected 64-character hex string." and stop. If `--patch` is combined with any other scope flag (`--staged`, `--unstaged`, `--branch`, `--commit`, `--range`) → output "Cannot combine --patch with --staged, --unstaged, --branch, --commit, or --range" and show usage message, then stop.
- Otherwise → treat the whole argument as a git ref (commit, branch, tag). Verify it resolves:
  ```bash
  git -C "$REPO_ROOT" rev-parse --verify "$ARGUMENTS" 2>/dev/null
  ```
  If it resolves → SCOPE = `ref`, DIFF_REF = the resolved value.
  If it does NOT resolve → output the usage message below and stop.

```
Usage: /shepherd-review [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | --patch <event-id> | <ref>]

Review changes in the macOS CRPG.

Scopes:
  (default)          All uncommitted changes (staged + unstaged + untracked) vs HEAD
  --staged           Only staged changes
  --unstaged         Only unstaged changes and untracked files
  --branch [base]    Commits on the current branch vs <base> (default: main)
  --commit [ref]     A single commit vs its parent (default: HEAD — your last commit)
  --range <range>    A commit range, e.g. main..HEAD or v1.0..v1.1
  --patch <event-id> Review a NIP-34 patch from Nostr (64-char hex event ID)
  <ref>              Working tree vs a commit, branch, or tag
```

---

### Step 2: Find changeset

Run the appropriate git commands based on SCOPE. All commands use `git -C "$REPO_ROOT"`. **Working-tree scopes append untracked files; commit scopes never do.**

**SCOPE = `working`** (default — working tree vs HEAD):

```bash
git -C "$REPO_ROOT" diff HEAD --name-status && git -C "$REPO_ROOT" diff --cached --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

This captures staged changes, unstaged changes, and untracked files in a single command chain.

**SCOPE = `staged`**:

```bash
git -C "$REPO_ROOT" diff --cached --name-status
```

**SCOPE = `unstaged`**:

```bash
git -C "$REPO_ROOT" diff --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

**SCOPE = `ref`** (working tree vs an arbitrary ref):

```bash
git -C "$REPO_ROOT" diff "$DIFF_REF" --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

**SCOPE = `branch`** (the current branch's commits vs `$BASE`, three-dot from the merge base — **no untracked**):

```bash
git -C "$REPO_ROOT" diff --name-status "$BASE"...HEAD
```

**SCOPE = `commit`** (a single commit vs its parent or the empty tree — **no untracked**):

```bash
git -C "$REPO_ROOT" diff --name-status "$COMMIT_BASE" "$REF"
```

**SCOPE = `range`** (net diff across a commit range — **no untracked**):

```bash
git -C "$REPO_ROOT" diff --name-status "$RANGE"
```

**SCOPE = `patch`** (NIP-34 patch from Nostr — **no untracked**):

This workflow is detailed below (Step 2-patch). Fetch the patch event from Nostr relays, validate it, apply to a temporary review branch, then detect the changeset vs the parent commit. The output is the same `--name-status` format as other scopes.

Merge and deduplicate all output by path. Untracked files (from `ls-files`, working-tree scopes only) get change type `added`.

**Parse statuses:**

- `M` = modified. `A` = added. `D` = deleted (exclude, count as filtered). `R` = renamed (use new path). `C` = added. `T` = modified.

For untracked files, add as `added` unless already present.

**Empty-changeset guard (`FR-srm-no-blank-window`).** If the combined output is empty (no changed files for this scope), output the scope-specific message below and **stop**. Do NOT write a session payload, do NOT invoke the launcher, do NOT open a window:

| SCOPE | Message |
|---|---|
| `working` | `No uncommitted changes to review.` |
| `staged` | `No staged changes to review.` |
| `unstaged` | `No unstaged changes to review.` |
| `ref` | `No changes relative to <ref>. Nothing to review.` |
| `branch` | `No commits on <current-branch> relative to <base>. Nothing to review.` |
| `commit` | `Commit <ref> has no changes to review.` |
| `range` | `No changes in range <range>. Nothing to review.` |
| `patch` | `Patch <short-event-id> has no reviewable changes.` |

---

### Step 2-patch: NIP-34 Patch Workflow (when SCOPE = `patch`)

**This section only runs when SCOPE = `patch`. Skip it for all other scopes.**

#### Configure Nostr relays

Read relay URLs in this order:
1. Environment variable `NOSTR_RELAYS` (comma-separated)
2. Config file `~/.config/nostr/relays.txt` (one URL per line, ignoring blank lines and `#` comments)
3. Default public relays: `wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band`

Store as RELAYS (comma-separated list).

#### Fetch NIP-34 patch event

Use `nak` if available; otherwise construct a manual WebSocket query.

**Try `nak` first:**
```bash
if command -v nak >/dev/null 2>&1; then
  RELAY_LIST=$(echo "$RELAYS" | tr ',' ' ')
  EVENT_JSON=$(nak req -k 1617 -k 1621 -i "$EVENT_ID" $RELAY_LIST 2>/dev/null | head -1)
fi
```

`nak req` takes relays as space-separated positional arguments (not a `--relay` flag), and the event-ID filter flag is `-i`/`--id` (not `-e`). `$RELAYS` is comma-separated per the relay-configuration step above, so it must be word-split into positional args before being passed to `nak`. An empty `EVENT_JSON` means the event was not found on any of the given relays.

If `nak` is not available or returns empty, output a warning:
```
Warning: nak CLI not found. Fetching patch via manual WebSocket query.
For better reliability, install nak: https://github.com/fiatjaf/nak
```

Then fall back to `curl` + WebSocket (implementation: construct `REQ` filter `{"ids":["$EVENT_ID"],"kinds":[1617,1621]}`, send to each relay until one responds, parse JSON response).

If no event is found on any relay, output:
```
Patch event ${EVENT_ID:0:8}... not found on relays: $RELAYS
```
Then stop.

#### Validate event

Parse `EVENT_JSON` to extract:
- `.kind` (must be 1617 or 1621)
- `.content` (the patch diff)
- `.pubkey` (author)
- `.tags[]` where `[0]` is tag name

Required validations:
1. **Event kind**: Must be 1617 or 1621. If not → output "Event ${EVENT_ID:0:8} has invalid kind (expected 1617 or 1621)" and stop.
2. **Diff format**: `.content` must start with `diff --git` and contain `+++` and `---` headers. If not → output "Invalid patch diff format in event ${EVENT_ID:0:8}" and stop.
3. **Repo match** (optional): If an `a` tag exists, compare against local repo config (if available). Mismatch → warning but don't stop.
4. **Parent commit** (optional): If `parent-commit` tag exists, verify with `git -C "$REPO_ROOT" rev-parse --verify --quiet <parent>`. Missing parent → warning but don't stop.

Extract metadata:
- `PATCH_AUTHOR`: `.pubkey` or value from `author` tag
- `PATCH_MESSAGE`: First line of `.content` before `diff --git`, or value from `m` tag (default: "(no message)")
- `PATCH_PARENT`: Value from `parent-commit` tag (or null if absent)
- `PATCH_STATUS`: Value from `status` tag (default: "open")
- `SHORT_EVENT_ID`: First 8 characters of `EVENT_ID`

#### Fetch patch-thread replies

Implements FR-sr-patch-replies-display (initial snapshot) and FR-sr-patch-replies-live (live refresh). After the patch event is validated, fetch the review-thread replies so other agents' and humans' comments render in the macOS app alongside the review context. The initial-snapshot fetch+map logic lives in `scripts/shepherd-patch-poll.sh --once`; the live path is the in-app `RelayClient` subscription (FR-sr-relay-client), which reuses the same mapping rules via the Swift `PatchReplyMapper`.

Agent and human comments on a patch are published as **kind:1** text notes tagged `["e", "<patch-event-id>", "", "root"]` plus an `["a", "30617:<owner>:<repo>"]` repo tag. Status transitions (open/merged/closed) are separate NIP-34 events (kinds 1630–1633), NOT comments — the script excludes them.

**Initial snapshot** — call the script in `--once` mode to produce the replies JSON array:
```bash
PATCH_REPLIES_JSON=$(bash "$SHEPHERD_ROOT/scripts/shepherd-patch-poll.sh" --once "$EVENT_ID" 2>/dev/null || echo "[]")
```
The script reads relays from `NOSTR_RELAYS` / `~/.config/nostr/relays.txt` / defaults, runs `nak req -k 1 -e "$EVENT_ID"`, and maps each kind:1 root reply to a `PatchReply` object (author resolved from `~/.config/nostr/roster.json` else truncated pubkey, `isBot` from roster bot flag, optional `lineAnchor` parsed from a `["range", file, start, end]` tag). It prints `[]` when `nak` is missing or no replies are found. This is best-effort: a relay failure or empty result does not block the review.

Embed `PATCH_REPLIES_JSON` into `patchMetadata.replies` of the context JSON (see "Structured context JSON" below).

#### Apply patch to review branch

1. **Stash uncommitted changes** (if any):
```bash
STASHED=0
if [[ -n $(git -C "$REPO_ROOT" status --porcelain) ]]; then
  git -C "$REPO_ROOT" stash push -u -m "shepherd-review --patch stash" >/dev/null 2>&1
  STASHED=1
fi
```

2. **Store original branch**:
```bash
ORIGINAL_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
```

3. **Determine base commit**:
If `PATCH_PARENT` exists and resolves locally, use it. Otherwise, fallback to merge-base with main:
```bash
if [[ -n "$PATCH_PARENT" ]] && git -C "$REPO_ROOT" rev-parse --verify --quiet "$PATCH_PARENT" >/dev/null 2>&1; then
  BASE_COMMIT="$PATCH_PARENT"
else
  BASE_COMMIT=$(git -C "$REPO_ROOT" merge-base main HEAD 2>/dev/null || echo "main")
fi
```

4. **Create review branch**:
```bash
REVIEW_BRANCH="review/patch-$SHORT_EVENT_ID"
git -C "$REPO_ROOT" branch -D "$REVIEW_BRANCH" 2>/dev/null  # delete if exists
git -C "$REPO_ROOT" checkout -b "$REVIEW_BRANCH" "$BASE_COMMIT" >/dev/null 2>&1
```

5. **Apply patch**:
Write `.content` to a temp file, then apply:
```bash
PATCH_FILE=$(mktemp -t patch-$SHORT_EVENT_ID.XXXXXX.patch)
echo "$EVENT_CONTENT" > "$PATCH_FILE"
if ! git -C "$REPO_ROOT" apply --index "$PATCH_FILE" 2>&1; then
  ERROR_MSG=$(git -C "$REPO_ROOT" apply --index "$PATCH_FILE" 2>&1)
  rm -f "$PATCH_FILE"
  # Restore original state
  git -C "$REPO_ROOT" checkout "$ORIGINAL_BRANCH" >/dev/null 2>&1
  [[ $STASHED -eq 1 ]] && git -C "$REPO_ROOT" stash pop >/dev/null 2>&1
  output "Patch application failed:\n$ERROR_MSG"
  stop
fi
rm -f "$PATCH_FILE"
```

6. **Detect changeset**:
```bash
git -C "$REPO_ROOT" diff --name-status "$BASE_COMMIT" HEAD
```

This output replaces the changeset for Step 3 (filtering).

7. **Register cleanup hook**:
After the review session ends (after Step 10), run:
```bash
git -C "$REPO_ROOT" checkout "$ORIGINAL_BRANCH" >/dev/null 2>&1
[[ $STASHED -eq 1 ]] && git -C "$REPO_ROOT" stash pop >/dev/null 2>&1
```

The review branch `$REVIEW_BRANCH` is kept (not auto-deleted).

---

### Step 3: Filter files

A file is excluded if it matches **any** exclusion rule. **Exclusion rules take precedence over inclusion rules.**

**Lockfiles** (exact filename): `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`

**Generated files**: directories `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`; extensions `.min.js`, `.min.css`, `.map`, `.d.ts`; basenames containing `.generated.` or `.auto.`

**Binary files**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.webp`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.webm`, `.avi`, `.zip`, `.tar`, `.gz`, `.bz2`, `.7z`, `.pdf`, `.exe`, `.dll`, `.so`, `.dylib`

**IDE/editor**: `.idea/`, `.vscode/`, `.DS_Store`

**Snapshots**: `.snap`, `.snapshot`

**Included config** (NOT excluded unless in an excluded directory): `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`, `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.claude/commands/*.md`

If zero files remain after filtering, output: `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` and stop.

---

### Step 4: Read all diffs in one batch, generate context, and proceed

Get diffs for **all** reviewable files in a single command. Separate modified/renamed files (which have diffs) from new/untracked files (which don't).

For files that have diffs, run **one** command with all paths, using the same diff base as Step 2:

| SCOPE | Diff command |
|---|---|
| `working` | `git -C "$REPO_ROOT" diff HEAD -- <path1> <path2> ...` |
| `staged` | `git -C "$REPO_ROOT" diff --cached -- <path1> <path2> ...` |
| `unstaged` | `git -C "$REPO_ROOT" diff -- <path1> <path2> ...` |
| `ref` | `git -C "$REPO_ROOT" diff "$DIFF_REF" -- <path1> <path2> ...` |
| `branch` | `git -C "$REPO_ROOT" diff "$BASE"...HEAD -- <path1> <path2> ...` |
| `commit` | `git -C "$REPO_ROOT" diff "$COMMIT_BASE" "$REF" -- <path1> <path2> ...` |
| `range` | `git -C "$REPO_ROOT" diff "$RANGE" -- <path1> <path2> ...` |

For new/untracked files (working-tree scopes only), read their contents using the Read tool (they have no diff to compare against — note them as entirely new). Commit scopes (`branch`, `commit`, `range`) have no untracked files.

This gives you all the information you need in one Bash call plus Read calls for new files only. Use this to:
1. Rank files by importance.
2. Generate structured review context JSON.
3. Display a brief summary.

**4a. Prioritize files by review importance.**

Rank files using these heuristics (highest priority first):
1. **Core source code** (application logic, components, business logic) — most important to review
2. **Configuration that affects behavior** (build config, CI, command definitions)
3. **Specs and documentation** (markdown specs, READMEs, design docs)
4. **Supporting files** (index files, glossaries, changelogs, decision logs)
5. **Test files** — usually least urgent to review manually

Within each tier, rank by the size/significance of the change (larger diffs first). Use your judgment — the goal is that the reviewer sees the most important files first.

**4b. Derive the session ID.**

Compute the session ID the same way the launch script does:

```bash
SESSION_ID=$(basename "$REPO_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
```

**4c. Generate structured review context JSON in a temp file.**

Create a temp file path the launcher will read:

```bash
CTX=$(mktemp -t shepherd-review-context.XXXXXX.json)
```

Build a JSON object with the following structure and write it to `$CTX` using the Write tool:

```json
{
  "overall": {
    "neutral": "<factual 2-4 sentence summary of what changed across the changeset>",
    "review": "<your opinion: what looks good, what deserves attention, potential concerns>"
  },
  "files": {
    "<absolute-file-path>": {
      "neutral": "<factual 1-2 sentence summary of what changed in this file>",
      "review": "<your opinion on this file's changes: quality, concerns, suggestions>"
    }
  },
  "patchMetadata": "<only when SCOPE = patch — see below>"
}
```

**When SCOPE = `patch`, add `patchMetadata` object (with `replies`):**

```json
{
  "overall": { ... },
  "files": { ... },
  "patchMetadata": {
    "eventID": "<full 64-char EVENT_ID>",
    "shortEventID": "<SHORT_EVENT_ID (first 8 chars)>",
    "author": "<resolved author name or truncated npub from PATCH_AUTHOR>",
    "commitMessage": "<PATCH_MESSAGE (truncated to 60 chars if longer)>",
    "parentCommit": "<short 8-char hash from PATCH_PARENT, or null if absent>",
    "status": "<PATCH_STATUS (open|merged|closed|draft)>",
    "replies": [
      {
        "id": "<reply event id (64-char hex)>",
        "author": "<resolved display name or truncated npub>",
        "authorPubkey": "<raw author pubkey>",
        "isBot": <true | false>,
        "content": "<reply text>",
        "timestamp": <created_at seconds (integer)>,
        "lineAnchor": {
          "filePath": "<absolute path matching a files[].path entry>",
          "startLine": <1-indexed>,
          "endLine": <1-indexed>
        }
      }
    ]
  }
}
```

Set `replies` to `[]` when there are no thread replies. `lineAnchor` is `null` for replies without a line-range anchor.

For author resolution, try:
1. Check `~/.config/nostr/roster.json` for a display name for `PATCH_AUTHOR` pubkey
2. Otherwise, convert pubkey to npub (bech32) and truncate to 12 chars: `npub1...`

For patch mode only, the `patchMetadata` field must be present. For all other scopes, omit it entirely.

The `neutral` fields should be purely factual — what changed, which functions/sections were modified, structural changes. No opinions.

The `review` fields contain your agent assessment — what looks good, what might be risky, suggestions for the reviewer to focus on.

Use **absolute file paths** as keys in the `files` object. These keys MUST exactly match the absolute paths passed to `shepherd-launch.sh` so the macOS app can correlate per-file context to its tab. Use the same `REPO_ROOT/<relative-path>` form for both.

The launcher inlines this file's contents into `session.json` at launch time and the macOS app reads it directly via `SessionClient.loadSession`. There is no Vite endpoint and no `~/.shepherd/sessions/<id>/review-context.json` file involved.

**4d. Display a brief summary and proceed immediately.**

Output a brief summary (no per-file details — those are now in the macOS app):

```
Reviewing: <scope-label>
Opening <N> files in the macOS app for review.
<M> files excluded (lockfiles, generated, binary).
```

Where `<scope-label>` is derived from SCOPE:

| SCOPE | `<scope-label>` |
|---|---|
| `working` | `all uncommitted changes` |
| `staged` | `staged changes only` |
| `unstaged` | `unstaged changes only` |
| `ref` | `changes vs <ref>` |
| `branch` | `commits on <current-branch> vs <base>` |
| `commit` | `commit <short-sha> — <subject>` (from `git show -s --format='%h — %s' "$REF"`) |
| `range` | `commit range <range>` |
| `patch` | `NIP-34 patch <short-event-id>` |

The "excluded" line is omitted if zero files were filtered. **Do not use `AskUserQuestion` here — proceed directly to Step 5.**

---

### Step 5: Open all files in the macOS CRPG and wait for review

**5a. Clean stale prompt output.**

Remove any previous prompt output file so we can detect a fresh one:

```bash
rm -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md
```

**5b. Launch all files in the macOS CRPG.**

Build the command with `--context "$CTX"` and all absolute file paths, then invoke the launch script:

```bash
bash "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" --context "$CTX" "<absolute-path-1>" "<absolute-path-2>" ... "<absolute-path-N>"
```

Use the absolute paths (`REPO_ROOT/<relative-path>`) for each file in the prioritized list. Quote each path properly. After the launcher returns, delete the temp context file:

```bash
rm -f "$CTX"
```

After launching, output:

```
Opened <N> files in the macOS app. Review them in the native window, then come back here when you're done.
```

**5c. Ask the user about their review.**

Use `AskUserQuestion` to present the user with these options:

- **"Added comments"** (description: "I reviewed files in the macOS app and clicked Done")
- **"Reviewed, no comments"** (description: "I looked at the files but have no comments to add")
- **"Cancel"** (description: "Abandon this review session")

Based on the response:

- **"Added comments"**: Read `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` with the Read tool. Store the contents as PROMPT_OUTPUT. If the file does not exist, tell the user "Could not find prompt output. Make sure you clicked 'Done' in the macOS app." and re-ask.
- **"Reviewed, no comments"**: Set PROMPT_OUTPUT to empty. Proceed to Step 6.
- **"Cancel"**: Output "Review session cancelled." and stop. The native window stays open — the user closes it via standard macOS chrome whenever they want. Do not proceed to Step 6.

---

### Step 6: Summary and feedback actions

**6a. Display the review summary.**

```
Review complete.
  <N> files opened in macOS CRPG
  <M> files filtered out (lockfiles, generated, binary)
```

Right-align numbers. The "filtered out" line is omitted if zero.

**6b. Display prompt output (if available).**

If PROMPT_OUTPUT was collected, display it:

```
---

Prompt output from CRPG:

<PROMPT_OUTPUT contents>

---
```

**6c. Clean up session directory.**

```bash
rm -rf ~/.shepherd/sessions/$SESSION_ID
```

**6d. Ask what to do with the feedback.**

Use `AskUserQuestion` to let the user choose:

- **"Apply changes"** (description: "Implement the changes described in the review feedback") → Begin implementing, file by file. Follow the project's cardinal rule (update specs first if behavior changes, then code).
- **"Discuss first"** (description: "Let's talk through the feedback before acting") → Engage in conversation about the feedback. Ask clarifying questions if needed.
- **"Save for later"** (description: "Write the review output to a file I can come back to") → Write to `review-feedback-<date>.md` in the repo root. Tell the user where it was saved.
- **"Done"** (description: "I'll handle it myself") → End the session.

If PROMPT_OUTPUT is empty (from "Reviewed, no comments"), display the summary with "0 files with comments" and output: "No comments were added during the review. Session complete." Do NOT present the feedback action options. Just end.

---

### Important notes

- Provide helpful context but keep it concise. The per-file summaries should orient the reviewer, not overwhelm them.
- The `shepherd-launch.sh` script handles file validation, `session.json` writing, and launching the prebuilt native binary. No browser opens. No Vite server starts.
- Each invocation starts fresh — the launcher overwrites `session.json` for the current session ID.
- When reading diffs for context, use the Read tool or Bash — whichever is more practical.
