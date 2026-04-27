# Shepherd Review — macOS Platform

> macOS-specific requirements for `shepherd-review`. See `../shepherd-review.md` for shared requirements.

## Overview

A macOS variant of the Shepherd Review slash command (`/shepherd-mac-review`) that orchestrates the same multi-file code review workflow but launches the native macOS Code Review Prompt Generator instead of the browser-based one. The two commands coexist — developers choose per-invocation which surface they want to review in. Like `/shepherd` and `/shepherd-mac`, the choice is explicit; there is no automatic platform detection.

Behaviorally the macOS variant matches the shared spec: the same changeset detection, filtering, priority ordering, structured-context generation (overall + per-file, neutral + review), brief conversation summary, auto-open, interactive prompt, and feedback handoff. The only differences are how files are launched and how context is delivered to the review surface — the web flow uses URL parameters and a Vite plugin endpoint; the macOS flow writes a session JSON payload to disk and launches the prebuilt native binary, identical to the existing `/shepherd-mac` handoff contract.

## User Stories

The macOS variant adds one platform-choice user story on top of the shared spec's stories.

### US-SRM-1: Choose the macOS surface for batch review
**As a** developer who prefers the native macOS CRPG over the web app, **I want to** invoke `/shepherd-mac-review` instead of `/shepherd-review`, **so that** every reviewable file in my changeset opens as a tab in the native app, with structured context displayed in the native UI, without launching a browser or running a local web server.

All other shared user stories (`US-SR-1` through `US-SR-9`) apply to the macOS variant unchanged — the review experience itself is the same.

## Shared Requirements — Applicability on macOS

### Apply as-is (no macOS-specific changes needed)

The following shared requirements apply identically on macOS:

- `FR-sr-changeset-detection` — Detect the changeset of the current branch
- `FR-sr-file-filtering` — Filter out uninteresting files
- `FR-sr-priority-ordering` — Sort files by review importance
- `FR-sr-changeset-overview` — Generate a structured changeset overview
- `FR-sr-per-file-context` — Generate per-file context with neutral and review separation
- `FR-sr-file-list-display` — Brief summary in the conversation before auto-opening
- `FR-sr-iteration-loop` — Auto-open all files in a single review session (one tab per file in the native window; the AskUserQuestion / Done / Cancel flow is identical)
- `FR-sr-feedback-collection` — Receive unified multi-file feedback via session-scoped `prompt-output.md`
- `FR-sr-completion-summary` — Display a review summary and feedback handoff
- `FR-sr-scope-argument` — Optional scope argument (`--staged`, `--unstaged`, `<ref>`)
- `FR-sr-git-required` — Requires a git repository
- `NFR-sr-startup-speed` — Fast changeset detection and context generation
- `NFR-sr-no-dependencies` — No additional dependencies (the prebuilt native binary is provided by the existing `/shepherd-mac` infrastructure, not a new runtime dependency)
- `NFR-sr-agent-native` — Runs entirely within the agent conversation (the native binary launch is a standard `Bash` invocation, no additional process model)
- `NFR-sr-cross-platform` — Not a constraint here; the git commands themselves remain cross-platform, but the launch path is macOS-only by design (see `NFR-srm-platform-restriction` below)

### Modified on macOS

- **`FR-sr-command-file`** — Implementation surface is the same (a Claude Code or opencode custom command file plus opencode skill), but the command name is `/shepherd-mac-review` and the command file lives at `.claude/commands/shepherd-mac-review.md` with a peer opencode skill at `.config/opencode/skills/shepherd-mac-review/SKILL.md`. See `FR-srm-command-file`.

- **`FR-sr-multi-file-launch`** — The mechanism is replaced. The web variant constructs a multi-`?file=` URL and opens a browser; the macOS variant writes a multi-file `session.json` to the per-session staging directory and launches the prebuilt native binary directly. See `FR-srm-multi-file-launch`.

- **`FR-sr-context-handoff`** — The mechanism is replaced. The web variant writes `review-context.json` for a Vite plugin endpoint to serve back to the browser; the macOS variant embeds equivalent context fields directly in the session JSON payload that the native binary reads on startup. The neutral/review separation contract is preserved. See `FR-srm-context-handoff`.

- **`FR-sr-install`** — The install script is extended further to symlink the new command file and ensure the prebuilt macOS binary is available. The macOS variant inherits the `/shepherd-mac` prebuild path: if the Swift toolchain is missing, the installer reports a degraded state without aborting the rest of the install. See `FR-srm-install`.

### Do not apply on macOS

None. Every shared functional requirement either applies as-is or is supplanted by a macOS variant above.

## macOS-Specific Functional Requirements

### Coexistence

#### `FR-srm-coexists` — Web and macOS commands coexist
Both `/shepherd-review` and `/shepherd-mac-review` are available simultaneously after install. Invoking one does not affect the other. The user chooses per-invocation which review surface to launch. There is no automatic platform detection — the choice is explicit, mirroring the existing `/shepherd` vs `/shepherd-mac` split.

### Command and launch

#### `FR-srm-command-file` — Implemented as a Claude Code or opencode command
The command is implemented as `.claude/commands/shepherd-mac-review.md` plus an opencode skill at `.config/opencode/skills/shepherd-mac-review/SKILL.md`, following the same pattern as `/shepherd-mac` and `/shepherd-review`. The command file contains the prompt instructions; no compiled code is required beyond the existing macOS application binary.

#### `FR-srm-multi-file-launch` — Open multiple files in a single native session
After changeset detection, filtering, priority ordering, and context generation, the command opens all reviewable files in a single native macOS application session. The mechanism is:

1. The command writes a session payload to the per-session staging directory at `~/.shepherd/sessions/<session-id>/session.json`. The payload contains the session ID, project root, an entry per reviewable file (absolute path and contents), and the review-context fields (see `FR-srm-context-handoff`).
2. The command launches the prebuilt macOS binary with `--session <id>`, identically to `/shepherd-mac`.
3. The native application reads the session payload, opens its window, and presents each file as a tab. The tab order matches the priority order from `FR-sr-priority-ordering`.

There is no browser, no local web server, and no URL-parameter mechanism. The launch contract is identical to the existing `/shepherd-mac` handoff, extended to multiple files.

#### `FR-srm-context-handoff` — Pass structured context data via session payload
The structured context data required by `FR-sr-changeset-overview` and `FR-sr-per-file-context` is delivered to the native application by embedding it inside the same `session.json` payload used for the file list. The payload includes:

1. **Overall neutral context**: factual changeset summary
2. **Overall review feedback**: agent's assessment of the changeset
3. **Per-file entries**, each containing the file path, change type, neutral context, and review feedback
4. **File ordering**: priority order from `FR-sr-priority-ordering` (encoded by the order of entries in the payload)

The neutral/review distinction is preserved as separate fields at both the overall and per-file level so the application can render them as visually distinct sections. The session ID isolates concurrent reviews per `FR-sc-session-id` — each invocation writes to its own `~/.shepherd/sessions/<session-id>/` directory and the binary opens a window scoped to that session.

#### `FR-srm-install` — Install command and prepare the macOS binary
The install script (`scripts/install-command.sh`) is extended to:

1. Symlink `~/.claude/commands/shepherd-mac-review.md` to the repo's `.claude/commands/shepherd-mac-review.md`, alongside the existing `shepherd`, `shepherd-mac`, and `shepherd-review` symlinks.
2. Reuse the macOS prebuild step already established for `/shepherd-mac`. No additional build is performed for the review variant — the same binary serves both single-file and multi-file launches.

If the Swift toolchain is missing or the build fails, the installer reports the degraded state without aborting the install of the web commands. `/shepherd-mac` and `/shepherd-mac-review` both become unavailable until the user installs Swift and re-runs the installer; the web variants remain usable.

## macOS-Specific Non-Functional Requirements

#### `NFR-srm-launch-budget` — Launch within the macOS app budget
The time from invoking `/shepherd-mac-review` to the native window appearing with all tabs loaded must fit within the existing macOS launch budget — `NFR-crp-macos-launch-time` (1 second cold launch) plus the agent's context-generation time. The slash command itself adds no measurable overhead beyond writing the session payload and invoking the prebuilt binary.

#### `NFR-srm-no-server` — No local web server is started
Launching `/shepherd-mac-review` does not start, rely on, or coexist with the local Vite dev server used by the web variant. The native binary is self-contained.

#### `NFR-srm-platform-restriction` — macOS-only
The command is intended for macOS and depends on the prebuilt macOS application binary. On other operating systems the command is unavailable; users on those platforms use the web variant (`/shepherd-review`).

## Acceptance Criteria

### Coexistence

- [ ] **Both commands available** `AC-srm-coexists`: Given the installer has run successfully, when the user lists available slash commands, then `/shepherd-review`, `/shepherd-mac-review`, `/shepherd`, and `/shepherd-mac` are all present, and invoking any one does not affect the others.

### Launch and tabs

- [ ] **Native window with tabs** `AC-srm-batch-open-native`: Given a changeset of 5 reviewable files, when the user invokes `/shepherd-mac-review`, then the macOS application opens with 5 tabs (one per file) in priority order, no browser is launched, and no local web server is started.

- [ ] **No server side effects** `AC-srm-no-server`: Given `/shepherd-mac-review` is invoked, when changeset detection and context generation complete, then no Vite or other local web server is started or required, and any port bindings used by `/shepherd-review` are not affected.

### Context handoff

- [ ] **Context visible in native UI** `AC-srm-context-in-app`: Given the agent has generated overall and per-file context, when the macOS application opens, then the overall neutral context and overall review feedback appear in the application UI as visually distinct sections, and each file tab displays its per-file neutral context and per-file review feedback alongside the diff, also as visually distinct sections.

- [ ] **Context isolated per session** `AC-srm-session-isolation`: Given two concurrent `/shepherd-mac-review` invocations from different working directories, when each runs to completion, then each launches its own session window with its own files and context, and neither sees the other's data — both reading and writing are scoped to their own `~/.shepherd/sessions/<session-id>/` directory.

### Feedback round-trip

- [ ] **Done writes session-scoped prompt** `AC-srm-prompt-roundtrip`: Given the user has reviewed files in the native window and added comments, when the user clicks Done, then the application writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`, and the agent — after the user selects "Added comments" from the interactive prompt — reads that file and presents the standard completion summary and feedback action menu (apply, discuss, save, nothing).

- [ ] **Cancel ends without summary** `AC-srm-cancel`: Given the macOS window is open, when the user selects "Cancel" in the agent's interactive prompt, then the session ends immediately, no summary is shown, and the user remains free to close the application window manually.

### Install

- [ ] **Installer creates symlink** `AC-srm-install-symlink`: Given the user runs `./scripts/install-command.sh`, when the script completes, then a symlink exists at `~/.claude/commands/shepherd-mac-review.md` pointing to the repo's `.claude/commands/shepherd-mac-review.md`, and `/shepherd-mac-review` is available globally in Claude Code or opencode.

- [ ] **Install tolerates missing toolchain** `AC-srm-install-degraded`: Given the Swift toolchain is missing on the host, when the installer runs, then the web slash commands install successfully, the installer reports that `/shepherd-mac` and `/shepherd-mac-review` are unavailable, and the install process exits with a success-or-warning state rather than aborting.

- [ ] **Updates propagate via git pull** `AC-srm-install-git-pull`: Given the install symlink exists, when the user runs `git pull` in the repo, then changes to `shepherd-mac-review.md` are picked up automatically the next time the command is invoked, with no re-install required.

## Open Questions

1. **Single binary or separate binary**: The proposed approach reuses the existing `/shepherd-mac` binary with an extended `session.json` (multi-file `files[]`). An alternative would be a dedicated review-mode binary. Reusing the existing binary is the default; engineering may revisit if the multi-file path significantly diverges from single-file behavior.

2. **Persistent window across reviews**: When a previous `/shepherd-mac-review` window is still open and the user invokes the command again with the same session ID (rare, but possible if the project root resolves to the same basename), the existing-window behavior follows `AC-crp-macos-window-deduplicate`. Whether the second invocation should always force a new session ID is deferred — the current convention from `/shepherd-mac` (project-root basename as session ID) is reused.

3. **Web ↔ native fallback**: If a user runs `/shepherd-mac-review` but the macOS binary is missing (toolchain not installed), should the command fall back to launching `/shepherd-review` automatically, or error out with instructions? Current decision: error out and instruct the user to either install Swift or use `/shepherd-review`. No silent fallback.

## Dependencies

- macOS variant of the Code Review Prompt Generator (`product/macos/code-review-prompt.md`) — provides the native multi-tab review UI and the session-handoff contract.
- macOS slash-command launcher infrastructure (`product/macos/slash-command.md`) — provides the install pattern, prebuild step, and `~/.shepherd/sessions/<session-id>/` staging directory contract.
- Shared `shepherd-review` requirements (`product/shepherd-review.md`) — provides the changeset detection, filtering, priority ordering, context generation, and feedback flow.
- Shared session-scoping primitives (`FR-sc-session-id`, `FR-sc-session-scoped-output`, `FR-sc-session-cleanup`) from `product/slash-command.md`.
