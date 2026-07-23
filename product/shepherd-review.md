# Shepherd Review

## Overview

A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Instead of manually identifying which files changed, finding the interesting ones, and invoking `/shepherd` on each one individually, the developer types `/shepherd-review` and the command automatically discovers the changeset of the current branch versus main, filters out uninteresting files (lockfiles, generated code, binaries), generates structured review context (both neutral descriptions and the agent's review feedback), and immediately auto-opens all reviewable files in a single CRPG session — each file appearing as a tab that the user can navigate freely, with context and feedback visible in the tool UI.

This addresses the workflow gap between "I have a branch with changes" and "I want to review my changed files in the CRPG." Today, the developer must manually run `git diff --name-only`, mentally filter out noise files, and invoke `/shepherd` repeatedly. `/shepherd-review` collapses that entire workflow into a single command that batch-opens every reviewable file in one CRPG session with full review context.

For patch reviews (`--patch`), the loop is bidirectional: the reviewer reads other participants' patch-thread replies and publishes their own comments back to the Nostr thread from within the review tool, under their own Nostr identity. This turns the patch review into a shared conversation across every agent and human reviewing the same patch, rather than a private annotation that must be exported and handed around manually.

The CRPG already supports multi-file tabs, per-file comments, and multi-file prompt generation. `/shepherd-review` leverages this by passing all files and structured context data to a single launch, letting the user review files in any order with the agent's context and feedback visible alongside each diff. The user adds comments on whichever files they choose and clicks "Done" once to produce a unified multi-file prompt covering all reviewed files. The context is split into neutral (factual descriptions of what changed) and review feedback (the agent's opinions and suggestions), displayed as visually distinct sections so the reviewer always knows which is which.

## User Stories

### US-SR-1: Review all interesting changed files in my branch
**As a** developer who has been working with an AI coding agent on a feature branch, **I want to** invoke a single command that opens all meaningfully changed files at once in the CRPG, **so that** I can review every change in a single session without manually tracking which files I have and haven't reviewed.

### US-SR-2: Skip uninteresting files automatically
**As a** developer, **I want** the review command to automatically exclude lockfiles, generated files, and binary files from the review list, **so that** I only spend time reviewing files that contain meaningful, human-authored changes.

### US-SR-3: Get straight into the review without unnecessary prompts
**As a** developer, **I want** the CRPG to open immediately after I invoke `/shepherd-review` without asking me to confirm, **so that** I can start reviewing right away instead of typing "go" in a confirmation step that adds no value.

### US-SR-4: Control the pace of review
**As a** developer, **I want to** navigate between file tabs freely in the CRPG, reviewing files in whatever order and at whatever pace I choose, **so that** I am never forced into a fixed sequence and can spend as much time as I need on each file.

### US-SR-5: Review only the files I care about
**As a** developer, **I want to** leave comments only on the files I care about and click "Done" at any point to end the session, **so that** I am not forced to visit every file and can focus my attention where it matters most.

### US-SR-6: Use the command from any branch
**As a** developer, **I want** the command to work on whatever branch I am currently on and compare against main (or the appropriate base branch), **so that** I do not need to specify branches manually.

### US-SR-7: Review all files in a single CRPG session
**As a** developer, **I want** all reviewable files to open together in one CRPG session with a tab per file, **so that** I can see the full scope of changes, navigate between related files, and produce a single unified review prompt covering all my comments.

### US-SR-8: See context and review feedback in the tool, not the terminal
**As a** developer, **I want** the changeset context and the agent's review feedback to appear in the CRPG UI alongside the diffs I am reviewing, **so that** I do not have to scroll back through the agent conversation in a separate terminal window to find the context about what changed and what the agent thinks. The review context should be where I am doing the review.

### US-SR-9: Distinguish factual context from the agent's opinions
**As a** developer, **I want** the CRPG to clearly separate neutral descriptions of what changed from the agent's review opinions, **so that** I can quickly get oriented on the facts and then decide how much weight to give the agent's suggestions. I do not want the two mixed together as if they are the same kind of information.

### US-SR-10: Review patches submitted via Nostr
**As a** developer receiving code contributions via NIP-34 Nostr patches, **I want to** invoke `/shepherd-review --patch <event-id>` to review the patch in the CRPG, **so that** I can review Nostr-submitted code using the same workflow as local branch reviews without manually applying patches or switching tools.

### US-SR-11: Participate in the patch review thread from the review tool
**As a** reviewer collaborating with multiple agents and humans on a NIP-34 patch, **I want to** publish my own comments back to the patch thread from within the review tool under my Nostr identity, **so that** my feedback is visible to every other participant in the shared review loop rather than trapped in a local export. I also want to respond directly to other participants' replies, **so that** I can hold focused sub-conversations within the broader thread.

## Requirements

### Functional Requirements

### Changeset Sources

The review workflow supports multiple changeset sources. Each produces a list of changed files that flows through the same filtering, ordering, context generation, and CRPG launch pipeline.

#### `FR-sr-changeset-detection` -- Detect the changeset of the current branch
The command determines which files have been modified, added, or deleted by comparing the **working tree** (not just committed changes) to the base branch. The base branch defaults to `main`. The comparison uses the merge base of the current branch and the base branch as the reference point, and compares the working tree against it. This captures all changes: committed changes on the branch, staged but uncommitted changes, and unstaged modifications. Additionally, untracked new files (not `git add`ed) are included as `added` files. This means the review covers the full set of changes a developer would see before committing — which is the primary use case for local code review. If no changes are found (the working tree matches the merge base), the command reports "No changes found relative to main" and stops. Deleted files are counted in the total changeset but excluded from the review list and counted as filtered (there is nothing to open in the CRPG for a deleted file). Renamed files are included using their new path.

#### `FR-sr-patch-source` -- Review NIP-34 patches from Nostr
When invoked with `--patch <event-id>`, the command fetches and reviews a NIP-34 patch event instead of local git changes. NIP-34 is the Nostr protocol for git patches: each patch event contains a unified diff, commit metadata (author pubkey, commit message, parent commit hash), and patch status (open/merged/closed/draft). The command fetches the patch event from configured Nostr relays, extracts the diff, applies it to a temporary review branch, and detects the changeset from the applied patch. The patch metadata (author, commit message, parent commit, status) is displayed in the CRPG UI alongside the review context. The workflow after patch application is identical to branch review: filter files, generate context, open in CRPG. This enables code review of Nostr-submitted patches without leaving the Shepherd review workflow.

#### `FR-sr-patch-fetch` -- Fetch NIP-34 patch event from Nostr relays
When `--patch <event-id>` is specified, the command queries configured Nostr relays for the event with the given ID. NIP-34 patch events are kind `1617` (proposal) or `1621` (patch). The event content contains the patch diff as a unified diff. The event tags include:
- `a` tag: repository reference (e.g., `30617:<repo-owner-pubkey>:<repo-d-tag>`)
- `commit` tag: commit hash
- `parent-commit` tag: parent commit hash (if not initial commit)
- `author` tag: commit author information
- `status` tag: patch status (`open`, `merged`, `closed`, `draft`)

The command reads relay URLs from the user's Nostr configuration (environment variable, config file, or default public relays). If the event is not found or cannot be fetched, the command reports an error with the relay URLs attempted and stops. The event ID is a 64-character hex string (Nostr event ID format). Invalid event ID format is rejected with a clear error message.

#### `FR-sr-patch-validation` -- Validate fetched patch before application
After fetching the patch event, the command validates:
1. **Event kind**: Must be `1617` (proposal) or `1621` (patch). Other event kinds are rejected.
2. **Diff format**: Event content must be a valid unified diff (starts with `diff --git`, contains `+++`/`---` headers, and `@@` hunks). Malformed diffs are rejected with a descriptive error.
3. **Repository match**: The `a` tag repository reference is compared against the current repository's configured Nostr repo ID (if available). A mismatch produces a warning but does not block (the user may be reviewing a patch for a fork or different remote). If no repo ID is configured locally, this check is skipped.
4. **Parent commit**: If a `parent-commit` tag exists, verify that commit exists in the local repository. If it doesn't exist, report a warning (the patch may be based on a commit not pulled) but do not block. The patch is still applied; conflicts may result.

#### `FR-sr-patch-application` -- Apply patch to a temporary review branch
After validation, the command applies the patch diff to a temporary review branch. The branch name is `review/patch-<short-event-id>` where `<short-event-id>` is the first 8 characters of the event ID. The workflow:
1. Stash any uncommitted local changes (both staged and unstaged) to preserve the working tree state.
2. Check out the parent commit (from the `parent-commit` tag) if it exists locally. If the parent commit doesn't exist, check out the current branch's merge-base with main as a fallback.
3. Create and check out the review branch (`review/patch-<short-event-id>`). If the branch already exists, delete it first (previous review of the same patch).
4. Apply the patch diff using `git apply` or `git am` (depending on whether full commit metadata is desired). If application fails (conflicts, missing files), report the specific git error and stop. The user must resolve conflicts manually if they want to proceed.
5. After successful application, detect the changeset by comparing the review branch to its parent commit. This produces the file list for review.

After the review session ends (user completes or cancels), the command automatically returns to the original branch and pops the stash if one was created. The review branch remains (it is not auto-deleted) so the user can inspect it, merge it, or delete it manually.

#### `FR-sr-patch-metadata-display` -- Display patch metadata in CRPG
When reviewing a patch (not a local branch), the CRPG displays patch-specific metadata alongside the review context:
- **Author**: Nostr pubkey of the patch author (from the `author` tag or event pubkey). If a local display name or NIP-05 identifier is known for this pubkey (e.g., from a contacts list or roster file), display that instead of the raw hex pubkey.
- **Commit message**: First line of the patch event content (before the diff starts) or extracted from an `m` tag if present.
- **Parent commit**: Short hash (8 chars) from the `parent-commit` tag, if present.
- **Patch status**: Value from the `status` tag (`open`, `merged`, `closed`, `draft`). Displayed with color coding: open (neutral), merged (green), closed (red), draft (gray).
- **Event ID**: Short form (first 8 characters) with a way to view or copy the full 64-char ID.

This metadata appears in a dedicated section of the CRPG UI, visually distinct from the file list and review context. It is read-only display; the user cannot edit it within the CRPG. Changing patch status (e.g., marking as merged) is a separate action outside the review workflow.

#### `FR-sr-patch-replies-display` -- Display other agents' and humans' patch-thread replies
When reviewing a patch, the command also fetches the patch's review-thread replies from Nostr and passes them to the CRPG so the reviewer sees the live conversation from other agents and humans alongside the review context. Replies are published as **kind:1** text notes tagged `["e", "<patch-event-id>", "", "root"]` plus an `["a", "30617:<owner>:<repo>"]` repo tag. The command queries relays with an `e`-tag filter `{"#e": ["<patch-event-id>"], "kinds": [1]}` (or `nak req -k 1 -e <id>`), then filters:
- Keep only `kind:1` events. Exclude NIP-34 status-transition events (kinds `1630`–`1633`) and the patch event itself — those are status changes, not comments.
- Keep events whose root `e` tag points at the patch event id (tolerate a missing `root` marker when the first `e` tag value matches).

Each reply is mapped to a `PatchReply` with: resolved author display name (NIP-05 / roster / truncated npub) and raw pubkey, a bot-vs-human flag (bot when the author is a known agent/bot by roster or NIP-05 host pattern; default human when uncertain), the reply content, the event timestamp, and an optional line-range anchor (`filePath` + `startLine`/`endLine`) parsed from a range tag when the reply pins to specific lines.

The CRPG renders replies two ways, both read-only and not user-editable:
- **Inspector section** -- a distinct "Patch Thread" section listing every reply with a visual marker distinguishing bot/agent replies (robot glyph + purple tint + `BOT` badge) from human replies (person glyph + orange tint).
- **Inline on the diff** -- replies carrying a line-range anchor are also rendered inline at their anchored file + line span, with the same bot/human marker, alongside (but visually distinct from) the reviewer's own editable comments.

Reply fetch is best-effort: if relays return no replies or the query fails, the review proceeds with an empty reply list. This requirement enables the shared NIP-34 patch/PR review loop where multiple agents and the human hold one conversation over Buzz/Nostr and each agent's UI surfaces the others' comments.

#### `FR-sr-patch-reply-publish` -- Reviewer publishes replies to the patch thread
When reviewing a patch, the reviewer can publish their own comments back to the Nostr patch thread from within the review tool, so their feedback is visible to every other agent and human participating in the same patch review loop. Publishing a reply creates a kind:1 text note tagged with the patch event as the thread root (an `e` tag pointing at the patch event id with the `root` marker) plus the repository `a` tag, mirroring the reply format the tool already ingests (`FR-sr-patch-replies-display`). A reply may optionally anchor to a file and line range in the applied patch, using the same line-anchor convention incoming replies use, so the reviewer's comment lands both on the thread and inline on the diff.

The published reply is authored under the reviewer's Nostr identity (see `FR-sr-reviewer-identity`). After publishing, the reply appears immediately in the reviewer's own tool (in the patch-thread section and inline at its anchor, indistinguishable from incoming replies except that it is the reviewer's own) without waiting for a relay round-trip, and other participants' tools surface it via their live subscriptions. This makes the patch review loop bidirectional: the reviewer is not a passive reader of the thread but a participant who writes back to it.

This requirement applies only to patch reviews. In non-patch review scopes (working-tree, branch, commit, range, or ref reviews) there is no Nostr thread to publish to, so the reviewer's comments remain local and are exported via the existing prompt-output mechanism (`FR-sr-feedback-collection`).

#### `FR-sr-reviewer-identity` -- Reviewer's published replies are authored under their Nostr identity
A reviewer who publishes to a patch thread does so under a Nostr identity they control. The identity is one of two forms the reviewer configures out of band: either a **secret key** the reviewer holds, or a **NIP-46 bunker connection** to a remote signer that holds the secret key on the reviewer's behalf. In both cases every published reply is signed under the reviewer's own public key, so each reply's author is the reviewer's own public key rather than an anonymous or tool-generated identity. Other participants see the reviewer's replies attributed to that identity (resolvable to a display name via the same roster/name-resolution path as incoming replies).

The identity is configured by the reviewer before publishing; the tool does not generate or assume an identity (it does not create keys; for a bunker it may generate an ephemeral session keypair used only for the NIP-46 control channel, never as the reviewer's identity). If no identity is configured when the reviewer attempts to publish a reply, the tool does not publish and surfaces a clear indication that an identity is required (see the platform-specific requirements for configuration). The identity persists across review sessions; the reviewer does not re-enter it per reply. The tool surfaces the active identity in its UI so the reviewer knows which identity their replies will be attributed to before they publish, including, for a bunker, whether the remote signer is currently reachable.

#### `FR-sr-bunker-signing` -- Sign published replies via a NIP-46 remote signer when a bunker identity is configured
When the reviewer's configured identity is a NIP-46 bunker connection rather than a local secret key, the review tool does not hold the reviewer's secret key. Instead it delegates event signing to the remote bunker: for each reply it would publish, the tool sends a NIP-46 `sign_event` request to the bunker over a Nostr relay and publishes the event the bunker returns. The published event is indistinguishable from one signed with a local key — same `pubkey`, `id`, and `sig` — so other participants and the reviewer's own live subscription treat it identically. The tool handles the bunker control channel (connect handshake, encrypted request/response) per NIP-46; the specifics of the transport and encryption are platform-specific (see the platform-specific requirements). If the bunker cannot be reached or refuses to sign, the tool does not publish, retains the comment locally, and informs the reviewer — it never silently drops a reply.

#### `FR-sr-patch-reply-respond` -- Reviewer can respond to an existing patch-thread reply
The reviewer can respond not only to the patch as a whole but to a specific existing patch-thread reply, threading the conversation. Responding to a reply publishes a kind:1 note that, in addition to the root `e` tag on the patch event, carries a reply `e` tag pointing at the replied-to reply's event id (with the `reply` marker) and a `p` tag naming the replied-to reply's author, following the standard NIP-10 threaded-reply convention. This lets the reviewer hold a focused sub-conversation with a specific agent or human within the broader patch thread.

The response is authored under the reviewer's identity (`FR-sr-reviewer-identity`) and, like a top-level reply, may optionally anchor to a file and line range. After publishing, the response appears in the reviewer's tool alongside the reply it responds to and is delivered to other participants' live subscriptions.

#### `FR-sr-patch-replies-live` -- Live refresh of patch-thread replies during a review
The initial reply snapshot (`FR-sr-patch-replies-display`) is captured at launch. For a live review loop, replies posted after the window opens must also appear without relaunching. The macOS app opens a relay subscription (see `FR-sr-relay-client`) for kind:1 events whose root `e` tag is the patch event id, maps each incoming event to a `PatchReply`, and appends it to `patchMetadata.replies` in timestamp order (skipping duplicates by id). The existing inspector section and inline anchored bubbles re-render automatically because they are derived from that reply array.

The subscription delivers stored replies first (so the inspector populates immediately) and stays open for new live replies. It starts when a patch review window opens and `patchMetadata` is present, and is cancelled when the window closes. Non-patch reviews never subscribe. If no relays are reachable, the app renders the initial session.json snapshot only and the review is unaffected.

#### `FR-sr-relay-client` -- In-process Nostr relay client
The macOS app includes a Nostr relay client that subscribes to relays in-process (no external CLI or background process required) so the app can receive patch-thread events directly. This is the cross-platform transport that the live patch-thread reply loop (`FR-sr-patch-replies-live`) is built on.

The client exposes a subscription that takes a NIP-01 filter (an `e` tag value and a kinds list) and yields matching events as an async stream, deduplicated by event id across all configured relays, keeping the subscription open so new events arrive live. Relay URLs are resolved with the same precedence as the `/shepherd-review` command prompt: the `NOSTR_RELAYS` environment variable, `~/.config/nostr/relays.txt`, then the default public relays. The stream stays open until the consumer cancels it (the app cancels on window close). If the transport is unavailable, the client yields nothing and the app renders the initial `session.json` snapshot only. The initial snapshot is still produced by the `/shepherd-review` command prompt at launch so the inspector has a baseline before the subscription delivers.

#### `FR-sr-file-filtering` -- Filter out uninteresting files
The command filters the changeset to exclude files that are not worth reviewing. The filtering rules are:

**Excluded by default** (these file patterns are skipped):
- Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`
- Generated files: files in directories named `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`; files with extensions `.min.js`, `.min.css`, `.map`, `.d.ts`; files named `*.generated.*` or `*.auto.*`
- Binary files: common binary extensions including `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.zip`, `.tar`, `.gz`, `.pdf`, `.exe`, `.dll`, `.so`, `.dylib`
- IDE/editor files: `.idea/` (entire directory), `.vscode/` (entire directory), `.DS_Store`
- Snapshot files: `*.snap`, `*.snapshot`

**Included** (these are meaningful to review even though they are "config"):
- Build configuration: `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`
- Project configuration: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`
- CI configuration: files in `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- Command files: `.claude/commands/*.md`

The filtering is heuristic-based and applied by file path and extension. The command does not read file contents to determine whether a file is interesting; it uses path patterns only. **Exclusion rules take precedence over inclusion rules.** If a file matches an exclusion rule (e.g., it is inside `dist/`), it is excluded even if it also matches an inclusion pattern (e.g., `vite.config.ts`). The inclusion list only prevents exclusion of files that are *not* in an excluded directory. If a file does not match any exclusion rule, it is included.

#### `FR-sr-priority-ordering` -- Sort files by review importance
After filtering, the command sorts files by review importance rather than alphabetically. The ordering uses a general-purpose heuristic:
1. Core source code (application logic, components, business logic) — most important
2. Configuration that affects behavior (build config, CI, command definitions)
3. Specs and documentation (markdown specs, design docs)
4. Supporting files (indexes, glossaries, changelogs)
5. Test files — least urgent for manual review

Within each tier, larger/more significant changes rank higher. The goal is that the reviewer sees the most impactful files first, so they can focus attention where it matters most.

#### `FR-sr-changeset-overview` -- Generate a structured changeset overview for the CRPG
After detecting and filtering the changeset, the command reads the diffs for all reviewable files and generates a structured overview with two distinct parts:

- **Neutral context** (overall): A factual summary of what the changeset contains — what features or areas are touched, what files changed, the structural nature of the changes (new feature, refactor, bug fix, etc.). This is objective description only; no opinions, quality judgments, or suggestions.
- **Review feedback** (overall): The agent's assessment of the changes — quality observations, potential concerns, patterns worth noting, suggestions for improvement, and things that look good. This is explicitly the agent's take on the changeset.

This overview is not displayed in the agent conversation. Instead, it is passed as structured data to the CRPG (see `FR-sr-context-handoff`) where it is displayed in the tool UI. The separation between neutral context and review feedback must be preserved so the CRPG can present them distinctly, making it clear to the reviewer what is factual description versus the agent's opinion.

#### `FR-sr-file-list-display` -- Show a brief summary in the conversation before auto-opening
After ordering and generating context, the command displays a brief summary in the agent conversation before auto-opening the CRPG. The summary includes:
1. The scope label (all changes vs main, staged only, or unstaged only)
2. The total count of files to review (e.g., "Opening 7 files for review")
3. If any files were filtered out, a note indicating how many were excluded

The detailed file list with per-file context and review feedback is not displayed in the conversation. That information is passed to the CRPG (see `FR-sr-context-handoff`) where it is displayed in the tool UI alongside the actual diffs. The conversation summary is intentionally minimal — just enough to confirm what is happening before the CRPG opens.

#### `FR-sr-per-file-context` -- Generate per-file context with neutral and review separation
For each reviewable file, the command generates context with two distinct parts:

- **Neutral context** (per-file): A factual description of what changed in this file — functions added, modified, or removed; lines changed; structural changes (new exports, renamed parameters, moved logic). This is derived from the diff and should mention specific names and locations. No opinions or quality judgments.
- **Review feedback** (per-file): The agent's observations about this specific file — code quality notes, potential issues, suggestions for improvement, things done well, patterns that look unusual. This is explicitly the agent's opinion.

Per-file context is not displayed in the agent conversation. It is passed as structured data to the CRPG (see `FR-sr-context-handoff`) where each file's context appears alongside its diff in the tool UI. This keeps the review context co-located with the code being reviewed, rather than in a separate conversation window the developer must scroll back to.

#### `FR-sr-context-handoff` -- Pass structured context data to the CRPG
The command passes all generated context to the CRPG as structured data so the tool can display it in its UI. The context data is scoped to the session (tied to the session ID from `FR-sc-session-id`), so concurrent reviews from different worktrees do not clobber each other's context. The data includes:

1. **Overall neutral context**: The factual changeset summary (from `FR-sr-changeset-overview`)
2. **Overall review feedback**: The agent's assessment of the changeset (from `FR-sr-changeset-overview`)
3. **Per-file entries**, each containing:
   - File path (relative to repo root)
   - Change type (added, modified, renamed)
   - Neutral context for this file (from `FR-sr-per-file-context`)
   - Review feedback for this file (from `FR-sr-per-file-context`)
4. **File ordering**: The priority order from `FR-sr-priority-ordering`

The specific mechanism for passing this data (file on disk, URL parameters, or other approach) is an engineering decision. The product requirement is that the CRPG receives all of the above as structured data with the neutral/review distinction preserved, scoped to the session so that concurrent reviews are isolated, and displays both parts in its UI with clear visual separation so the reviewer can distinguish factual context from the agent's opinions.

#### `FR-sr-iteration-loop` -- Auto-open all files in a single CRPG session
Immediately after changeset detection, context generation, and the brief conversation summary (see `FR-sr-file-list-display`), the command auto-opens all reviewable files in a single CRPG session. There is no confirmation prompt — the user invoked `/shepherd-review`, so the intent to review is already established. The CRPG opens automatically.

The files appear as tabs in the CRPG, ordered by review priority (see `FR-sr-priority-ordering`). The structured context data (overall and per-file, neutral and review) is passed to the CRPG alongside the file list (see `FR-sr-context-handoff`). The user navigates between tabs freely, reviewing files in whatever order they choose and adding comments on whichever files they want.

The command invokes the launch script (see `FR-sr-multi-file-launch`) with all file paths and context data, which opens the CRPG with one tab per file. After launching the CRPG, the command presents an interactive prompt (via `AskUserQuestion`) asking the user about their review outcome. The prompt offers three choices:

- **"Added comments"** — The user reviewed files in the CRPG and clicked "Done" (which writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`). The agent reads the session-scoped prompt output file to collect feedback.
- **"Reviewed, no comments"** — The user looked at the files but did not add any comments. The session proceeds to the completion summary with zero comments.
- **"Cancel"** — The user abandons the review session entirely. The session ends immediately with no summary.

There is no sequential iteration, no "next" or "skip" commands, no per-file prompting, no pre-launch confirmation prompt, and no file-watcher or polling loop. The user controls their review entirely within the CRPG UI and signals completion through the interactive prompt.

#### `FR-sr-feedback-collection` -- Receive unified multi-file feedback from CRPG
After the user selects "Added comments" from the interactive prompt, the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`, written by the CRPG's "Done" action). This file contains a single multi-file prompt with all comments across all files, organized by file. The CRPG handles aggregation internally and produces one unified output. If the user selects "Reviewed, no comments", the session proceeds to the completion summary with zero comments. If the user selects "Cancel", the session ends immediately with no summary. The command does NOT need to collect feedback file-by-file — the CRPG aggregates all per-file comments into one prompt output file.

#### `FR-sr-completion-summary` -- Display a review summary and feedback handoff
When the user selects "Added comments" from the interactive prompt and the agent successfully reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), the command displays a summary including: total files opened, filtered count, and files that received comments.

If the prompt output file contains feedback, the command presents the full prompt content and asks the user what to do:
- **apply** — implement the changes described in the feedback
- **discuss** — talk through the feedback before acting
- **save** — write feedback to a file for later
- **nothing** — end the session

When the user selects "Reviewed, no comments" from the interactive prompt, the summary notes that the review was completed with no comments and the session ends cleanly.

When the user selects "Cancel" from the interactive prompt, the session ends immediately with no summary.

#### `FR-sr-command-file` -- Implemented as a Claude Code or opencode command file
The command is implemented as a Claude Code or opencode custom command file at `.claude/commands/shepherd-review.md`, following the same pattern as the existing `/shepherd` command at `.claude/commands/shepherd.md`. The command file contains the prompt instructions that the AI coding agent executes. No compiled code or external binary is required — the command is pure prompt engineering executed by the agent. The command invokes the launch script with multiple file paths to open all reviewable files in a single CRPG session (see `FR-sr-multi-file-launch`).

#### `FR-sr-multi-file-launch` -- Open multiple files in a single CRPG session
The command opens all reviewable files in a single CRPG session by passing multiple file paths to the launch script (`shepherd-launch.sh`). The launch script constructs a launch URL that tells the CRPG to load all specified files, each appearing as a tab. The tab order matches the priority ordering from `FR-sr-priority-ordering`. The CRPG's existing multi-file support handles tab navigation, per-file comments, and unified prompt generation. The launch script must accept multiple file path arguments (updating its current single-file interface). The application must support receiving multiple files via launch parameters (new engineering work).

#### `FR-sr-install` -- Installable via the existing symlink mechanism
The command can be made globally available using the same `scripts/install-command.sh` script that installs the `/shepherd` command. The install script is updated to also create a symlink for `shepherd-review.md` at `~/.claude/commands/shepherd-review.md`. Since the global command is a symlink, `git pull` in the repo automatically updates it.

#### `FR-sr-scope-argument` -- Optional scope argument
The command accepts an optional argument to control which changes are reviewed:

- **No argument (default)**: Review all changes in the working tree relative to main. This includes committed branch changes, staged changes, unstaged changes, and untracked new files. This is the broadest view — "everything that differs from main."
- **`--staged`**: Review only staged changes (files in the git index). This is useful after `git add` when the user wants to review exactly what will be committed. Uses `git diff --name-status --cached` against the merge base.
- **`--unstaged`**: Review only unstaged changes and untracked files. This is useful after staging some files to review what's left. Uses `git diff --name-status` (working tree vs HEAD) plus untracked files.
- **`--patch <event-id>`**: Review a NIP-34 patch event from Nostr. Fetches the patch, applies it to a temporary review branch, and reviews the applied changes. See `FR-sr-patch-source` for full behavior. Cannot be combined with `--staged` or `--unstaged`.

If an unrecognized argument is provided, or if `--patch` is combined with `--staged`/`--unstaged`, the command displays a usage message and stops.

#### `FR-sr-git-required` -- Requires a git repository
The command must be invoked from within a git repository. If the current working directory is not inside a git repository, the command reports an error: "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

### Non-Functional Requirements

#### `NFR-sr-startup-speed` -- Fast changeset detection and context generation
The time from invoking `/shepherd-review` to auto-opening the CRPG must be under 5 seconds for repositories with up to 1,000 changed files. The changeset detection relies on git commands that are inherently fast. Context generation (neutral and review, overall and per-file) adds agent processing time but should not introduce significant delay.

#### `NFR-sr-no-dependencies` -- No additional dependencies
The command requires only git (available on the PATH) and the existing `/shepherd` command infrastructure. It does not introduce any new runtime dependencies, npm packages, or compiled binaries.

#### `NFR-sr-agent-native` -- Runs entirely within the agent conversation
The command runs entirely within the AI coding agent's conversation context. It uses only bash commands (git, standard shell utilities) and the existing `/shepherd` command. There is no separate process, daemon, or server beyond what `/shepherd` already manages.

#### `NFR-sr-cross-platform` -- Cross-platform git compatibility
The git commands used by the command must work on macOS, Linux, and Windows (Git Bash or WSL). The command does not rely on platform-specific shell features beyond what is available in bash.

## Acceptance Criteria

#### `AC-sr-happy-path` -- Full review session completes successfully
**Given** the user is on a feature branch with 5 modified source files and 3 lockfiles/generated files relative to main, **when** the user types `/shepherd-review`, **then** the command displays a brief summary ("Opening 5 files for review (3 excluded)") in the conversation and immediately auto-opens all 5 files in a single CRPG session with one tab per file, using a unique session ID. The CRPG displays the overall neutral context and review feedback, and each file tab shows its per-file neutral context and review feedback alongside the diff. There is no confirmation prompt before opening the CRPG. The agent then presents an interactive prompt with three options. The user reviews files freely, clicks "Done" in the CRPG, selects "Added comments" from the interactive prompt, the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), and the command displays a summary with feedback action options.

#### `AC-sr-filters-lockfiles` -- Lockfiles are excluded
**Given** the changeset includes `package-lock.json` and `pnpm-lock.yaml`, **when** the file list is displayed, **then** neither lockfile appears in the review list and the exclusion count reflects them.

#### `AC-sr-filters-generated` -- Generated/build output files are excluded
**Given** the changeset includes files in `dist/` and a file named `schema.generated.ts`, **when** the file list is displayed, **then** those files are excluded from the review list.

#### `AC-sr-filters-binary` -- Binary files are excluded
**Given** the changeset includes `logo.png` and `font.woff2`, **when** the file list is displayed, **then** those files are excluded from the review list.

#### `AC-sr-includes-config` -- Meaningful config files are included
**Given** the changeset includes `vite.config.ts`, `tsconfig.json`, and `package.json`, **when** the file list is displayed, **then** all three appear in the review list.

#### `AC-sr-excludes-deleted` -- Deleted files are excluded
**Given** the changeset includes a file that was deleted (exists on main but not on the current branch), **when** the file list is displayed, **then** the deleted file does not appear in the review list.

#### `AC-sr-skip-file` -- User can skip files implicitly
**Given** 5 files are open as tabs in the CRPG, **when** the user reviews only 3 files and adds comments to those 3, then clicks "Done", **then** the generated prompt includes only the 3 files with comments. The 2 files without comments are effectively skipped without any explicit action required.

#### `AC-sr-quit-early` -- User can end the session at any point
**Given** 5 files are open as tabs in the CRPG, **when** the user clicks "Done" after reviewing only 2 files and selects "Added comments" from the interactive prompt, **then** the agent reads the prompt output and the session proceeds with whatever comments exist at that point. Alternatively, the user can select "Cancel" from the interactive prompt to abandon the session entirely without completing the CRPG review — the session ends immediately with no summary. There is no concept of "remaining" files — the user simply finishes whenever they are ready.

#### `AC-sr-no-changes` -- No changes produces a clear message
**Given** the user is on a branch with no changes relative to main (or is on main itself), **when** the user types `/shepherd-review`, **then** the command outputs "No changes found relative to main." and stops without presenting a file list.

#### `AC-sr-all-filtered` -- All files filtered produces a clear message
**Given** the changeset contains only lockfiles and binary files (every file is excluded by filtering), **when** the file list is computed, **then** the command outputs "No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary)." and stops.

#### `AC-sr-not-git-repo` -- Error outside a git repository
**Given** the current working directory is not inside a git repository, **when** the user types `/shepherd-review`, **then** the command outputs "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

#### `AC-sr-invokes-shepherd` -- All files open in a single CRPG session
**Given** the reviewable files are `src/utils.ts`, `src/app.tsx`, and `lib/helpers.ts`, **when** the command launches the review, **then** it invokes the launch script with all three file paths, opening a single CRPG session with three tabs (one per file) in priority order.

#### `AC-sr-list-command` -- File list and context are available in the CRPG
**Given** the command has opened the CRPG with 5 files, **when** the user wants to reference the file list and context while reviewing, **then** the overall neutral context and review feedback are visible in the CRPG UI (not in the agent conversation). Each file tab shows its per-file neutral context and review feedback alongside the diff. The CRPG tab bar shows all file names for navigation.

#### `AC-sr-completion-summary` -- Summary displays after CRPG prompt is returned
**Given** the user completes a review of 5 files and selects "Added comments" from the interactive prompt, **when** the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), **then** the command displays a summary showing the total files opened, the number of files that received comments, and presents the action options (apply, discuss, save, nothing).

#### `AC-sr-sorted-file-list` -- Files are sorted by review priority and tab order matches
**Given** the changeset includes `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `tests/utils.test.ts`, and `README.md`, **when** the file list is displayed and the CRPG opens, **then** the files appear in priority order (core source first, then config, then docs, then tests) both in the displayed list and in the CRPG tab order.

#### `AC-sr-batch-open` -- All files open as tabs in a single CRPG session
**Given** there are 5 reviewable files, **when** the command finishes changeset detection and context generation, **then** a single CRPG session auto-opens with 5 tabs (one per file), without any confirmation prompt. The user does not need to wait for sequential prompts or invoke any per-file commands.

#### `AC-sr-unified-prompt` -- CRPG generates a single multi-file prompt
**Given** the user has added comments on 3 of 5 open files in the CRPG, **when** the user clicks "Done", **then** the CRPG generates a single prompt that includes all comments organized by file and writes it to the session-scoped path (`~/.shepherd/sessions/<session-id>/prompt-output.md`). The agent reads this file after the user selects "Added comments" from the interactive prompt.

#### `AC-sr-install-global` -- Command is available globally via symlink
**Given** the user runs `./scripts/install-command.sh`, **when** the script completes, **then** a symlink exists at `~/.claude/commands/shepherd-review.md` pointing to the repo's `.claude/commands/shepherd-review.md`, and `/shepherd-review` is available as a global command in Claude Code or opencode.

#### `AC-sr-context-in-crpg` -- Context is displayed in the CRPG with clear neutral/review separation
**Given** the command has generated overall and per-file context (both neutral and review), **when** the CRPG opens, **then** the overall neutral context and overall review feedback are displayed in the CRPG UI as visually distinct sections. For each file tab, the per-file neutral context and per-file review feedback are displayed alongside the diff, also as visually distinct sections. The reviewer can tell at a glance which text is factual description and which is the agent's opinion.

#### `AC-sr-auto-open` -- CRPG opens without confirmation prompt
**Given** the user types `/shepherd-review` and there are reviewable files, **when** changeset detection and context generation complete, **then** the CRPG opens automatically. The user is not asked "Ready to start?" or any similar confirmation question. The brief summary appears in the conversation and the CRPG opens immediately.

#### `AC-sr-interactive-prompt` -- Interactive prompt presented after CRPG launch
**Given** the CRPG has been opened with N files, **when** the agent finishes launching the CRPG, **then** it presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments", "Reviewed, no comments", and "Cancel". There is no file-watcher polling loop. The agent waits for the user's selection before proceeding.

#### `AC-sr-patch-happy-path` -- Review NIP-34 patch successfully
**Given** a valid NIP-34 patch event exists on configured Nostr relays with event ID `abc123...`, **when** the user types `/shepherd-review --patch abc123...`, **then** the command fetches the patch event, validates it, applies it to a temporary branch `review/patch-abc123ab`, detects the changeset, filters and sorts files, generates context, displays patch metadata (author, commit message, parent commit, status) in the CRPG, and opens all reviewable files for review. After the review session ends, the original branch is restored and any stashed changes are popped.

#### `AC-sr-patch-event-not-found` -- Clear error when patch event doesn't exist
**Given** no event with ID `xyz789...` exists on configured relays, **when** the user types `/shepherd-review --patch xyz789...`, **then** the command reports "Patch event xyz789... not found on relays: [relay URLs]" and stops without creating a review branch.

#### `AC-sr-patch-invalid-diff` -- Reject malformed patch diffs
**Given** a NIP-34 event contains content that is not a valid unified diff (missing `diff --git` headers or malformed hunks), **when** the command attempts to validate the patch, **then** it reports "Invalid patch diff format in event <id>" and stops without applying the patch.

#### `AC-sr-patch-application-conflicts` -- Handle patch application conflicts
**Given** a patch diff conflicts with the local repository state (files don't exist, hunks don't apply), **when** the command attempts to apply the patch via `git apply`, **then** it reports the git error (e.g., "error: patch failed: src/utils.ts:42") and stops. The review branch is created but the patch is not applied. The user must resolve conflicts manually.

#### `AC-sr-patch-metadata-displayed` -- Patch metadata visible in CRPG
**Given** a patch event with author pubkey `npub1abc...`, commit message "Add new feature", parent commit `deadbeef`, and status `open`, **when** the CRPG opens for review, **then** the patch metadata section displays the author (as display name if known, otherwise short pubkey), commit message, parent commit short hash, and status with appropriate color coding (open = neutral color).

#### `AC-sr-patch-invalid-event-id` -- Reject invalid event ID format
**Given** the user types `/shepherd-review --patch not-a-valid-hex-string`, **when** the command validates the event ID, **then** it reports "Invalid event ID format. Expected 64-character hex string." and stops.

#### `AC-sr-patch-conflicting-args` -- Reject conflicting scope arguments
**Given** the user types `/shepherd-review --patch abc123... --staged`, **when** the command parses arguments, **then** it reports "Cannot combine --patch with --staged or --unstaged" and displays a usage message.

#### `AC-sr-patch-reply-publish` -- Reviewer publishes a reply to the patch thread
**Given** the reviewer is reviewing a patch with their Nostr identity configured, **when** the reviewer writes a comment anchored to a file and line range in the applied patch and submits it, **then** the review tool publishes a kind:1 note to the configured relays tagged with the patch event as root (plus the repository `a` tag and a line-range anchor matching the comment's location), signed under the reviewer's identity. The reply appears immediately in the reviewer's own patch-thread section and inline at its anchor, and is delivered to other participants' live subscriptions.

#### `AC-sr-patch-reply-respond` -- Reviewer responds to an existing reply
**Given** the patch thread contains a reply from another participant, **when** the reviewer responds to that reply from within the review tool, **then** the tool publishes a kind:1 note that carries a root `e` tag on the patch event, a reply `e` tag on the responded-to reply's event id, and a `p` tag naming that reply's author, signed under the reviewer's identity. The response appears in the reviewer's tool alongside the reply it responds to.

#### `AC-sr-reviewer-identity` -- Replies are authored under the reviewer's identity
**Given** the reviewer has configured a Nostr identity (either a secret key or a NIP-46 bunker connection), **when** the reviewer publishes any reply to a patch thread, **then** the published event's `pubkey` is the reviewer's own public key and other participants resolve it to the reviewer's display name. **Given** no identity is configured, **when** the reviewer attempts to publish a reply, **then** the tool does not publish and surfaces a clear indication that an identity is required.

#### `AC-sr-bunker-signing` -- Replies are signed by a NIP-46 bunker when configured
**Given** the reviewer has configured a NIP-46 bunker connection (and no local secret key), **when** the reviewer submits an inline comment to publish, **then** the tool sends a `sign_event` request to the bunker, receives the signed event back, and publishes it under the reviewer's public key — without the reviewer's secret key ever being present on the host. **Given** the bunker is unreachable or refuses to sign, **when** the reviewer submits a comment, **then** the tool retains the comment locally, informs the reviewer the reply could not be published, and does not silently drop it.

## Open Questions

1. **Base branch detection**: The spec defaults to `main` as the base branch. Some repositories use `master`, `develop`, or other branch names. Should the command attempt to auto-detect the default branch (e.g., by reading `git symbolic-ref refs/remotes/origin/HEAD`), or should it accept an optional argument to override the base branch? The command assumes `main`; auto-detection or an override argument is a roadmap candidate.

11. **NIP-34 relay configuration**: How should the user configure which Nostr relays to query for patch events? Options: (a) environment variable `NOSTR_RELAYS` (comma-separated URLs), (b) config file at `~/.config/nostr/relays.txt`, (c) hardcoded default public relays, (d) read from an existing Nostr client config if available (e.g., `nak`, `alby`). Engineering will determine the most user-friendly approach that minimizes setup friction.

12. **Patch author display name resolution**: When displaying patch author, should the command attempt to resolve the author's pubkey to a human-readable name? Options: (a) check local contacts/roster file, (b) query NIP-05 for verification, (c) just show short pubkey form. Deferred to design/engineering — product requirement is that a display name is shown *if available*, otherwise short pubkey.

13. **Review branch cleanup**: After a patch review session ends, should the `review/patch-*` branch be auto-deleted, kept for inspection, or prompt the user? The command keeps the branch (user can delete manually). Auto-cleanup is a roadmap candidate.

14. **Patch status update workflow**: After reviewing and merging a patch, the user may want to update its status to `merged` on Nostr. This is a separate action from the review itself — it would involve publishing a status update event. Should `/shepherd-review` offer to do this, or should it remain a separate command/script? Deferred; review is the only action, status updates are manual.

2. ~~**File ordering strategy**: Resolved — files are sorted by review priority (see `FR-sr-priority-ordering`). Priority ordering determines both the displayed list order and the CRPG tab order. Core source files appear first, tests last.~~

3. **Resumable sessions**: If the user quits early and later runs `/shepherd-review` again, should it offer to resume where they left off? This would require some form of state persistence (e.g., a dotfile in the repo). Deferred; each invocation starts fresh in v1.

4. ~~**Per-file context/summary**: Resolved — per-file context is generated by the agent and passed to the CRPG as structured data (see `FR-sr-per-file-context`, `FR-sr-context-handoff`). Each file's context appears in the CRPG UI alongside its diff, split into neutral context (factual) and review feedback (agent's opinion). Context is displayed in the tool where the review happens, not in the agent conversation.~~

5. **Custom exclusion patterns**: Should the user be able to customize which files are filtered out (e.g., via a `.shepherd-review.yml` config file)? Deferred. The built-in heuristics should cover the vast majority of cases for v1.

6. **Diff view vs. file view**: When `/shepherd` opens a file in the CRPG, the user can choose file view or diff view. Should `/shepherd-review` default to diff view (since the whole point is reviewing changes)? This is a UX question best resolved in the design phase. The product spec does not mandate a default view mode; that is left to the existing CRPG and `/shepherd` behavior.

7. **Renamed file handling**: Git reports renames as a pair (old path, new path). The command should use the new path (which exists on disk). Should it also mention the old path in the file list annotation? Deferred to design.

8. **Maximum batch size**: Is there a practical upper limit on how many files can be batch-opened as tabs in a single CRPG session? For very large changesets (e.g., 50+ files), the file list may become unwieldy and the launch mechanism may hit platform limits. Should the command warn or paginate above a threshold? Deferred to design/engineering to determine practical limits.

9. **URL parameter format for multiple files**: The CRPG currently supports `?file=<path>` for a single file. The multi-file URL format (e.g., repeated `file` params, comma-separated, or a different mechanism) needs to be defined in engineering. This is a technical design decision, not a product decision.

10. ~~**Prompt return mechanism**: Resolved — the CRPG writes the unified multi-file prompt to `~/.shepherd/prompt-output.md` when the user clicks "Done." After opening the CRPG, the agent presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments" (reads the prompt output file), "Reviewed, no comments" (proceeds with no-feedback summary), or "Cancel" (ends session). No file-watcher or polling is needed.~~

## Dependencies

- **`shepherd-launch.sh` script**: The launch script must be updated to accept multiple file path arguments, context data, and construct a URL that loads all files as tabs in a single CRPG session. Currently supports a single `?file=<path>` parameter. Must also support passing structured context data (overall and per-file, neutral and review) to the CRPG.
- **CRPG multi-file URL support**: The CRPG must support loading multiple files from launch parameters (new engineering work). The in-app multi-file support already exists; this dependency is specifically about initializing a multi-file session from the launch mechanism.
- **CRPG context display**: The CRPG must support receiving and displaying structured context data (see `FR-sr-context-handoff`). This includes overall neutral context and review feedback displayed in the UI, plus per-file neutral context and review feedback displayed alongside each file's diff. The neutral and review sections must be visually distinct. This is new engineering work.
- **CRPG patch metadata display**: The CRPG must support displaying NIP-34 patch metadata (see `FR-sr-patch-metadata-display`) in a dedicated UI section. This includes author (with pubkey-to-name resolution), commit message, parent commit, status, and event ID. This is new engineering work specific to patch review.
- **CRPG multi-file prompt generation**: The CRPG already supports generating a unified multi-file prompt from comments across tabs and writing it to the session-scoped path (`~/.shepherd/sessions/<session-id>/prompt-output.md`). No new work needed here beyond session-scoping (see `FR-sc-session-scoped-output`). The agent uses an interactive prompt (`AskUserQuestion`) rather than a file-watcher or polling mechanism to determine when the user is done and which outcome to process. The prompt output file is still written by the CRPG; only the path is now session-scoped.
- **Git**: The command requires git to be installed and the working directory to be inside a git repository. Git is used for changeset detection (`git diff`, `git merge-base`) and patch application (`git apply` or `git am`, `git checkout`, `git stash`).
- **Nostr relay access**: For `--patch` mode, the command requires access to Nostr relays to fetch NIP-34 patch events. Relay URLs are read from user configuration (environment variable, config file, or default public relays). No authentication is required for read-only event fetching.
- **Reviewer Nostr identity**: For publishing replies to a patch thread (`FR-sr-patch-reply-publish`), the review tool requires a reviewer-owned Nostr identity (a secret key the reviewer has configured). The identity is used to sign published replies so they are attributed to the reviewer. If no identity is configured, reply publishing is unavailable; read-only patch review and local comment export still work.
- **NIP-34 protocol understanding**: The command must parse NIP-34 event structure (kind `1617`/`1621`, specific tags for commit metadata and status). This is implemented as part of the patch fetching logic, not a separate library dependency.
- **Claude Code or opencode custom commands**: The command is implemented as a `.claude/commands/` markdown file and relies on Claude Code or opencode's custom command execution model. The command uses `AskUserQuestion` (a standard agent capability) to present the interactive prompt after launching the CRPG.
- **`scripts/install-command.sh`**: The existing install script must be updated to also symlink the new command file for global availability.
