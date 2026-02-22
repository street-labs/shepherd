# Slash Command Launcher

## Overview

A slash command (`/shepherd`) that lets developers launch the Code Review Prompt Generator (CRPG) directly from within an AI coding agent. Instead of manually opening the web app, navigating to it in a browser, and dragging a file in, the developer types `/shepherd <filepath>` in their agent conversation and the CRPG opens in their browser with the specified file already loaded and ready for annotation.

This eliminates the friction of switching context between the AI agent conversation and the CRPG web application. The current workflow requires the developer to remember the app's URL or how to start it, open it manually, and then load the file through drag-and-drop, upload, or paste. The slash command collapses that into a single command issued from the place the developer is already working.

The slash command is distributed as a command file in the Shepherd repository (`.claude/commands/shepherd.md`). It works with AI coding agents that support custom slash commands or skills, such as Claude Code. Within the repo it is available automatically; a symlink script provides global availability.

## User Stories

### US-SC-1: Launch the CRPG with a file from an AI agent conversation
**As a** developer using an AI coding agent, **I want to** type `/shepherd <filepath>` in my agent conversation, **so that** the CRPG web app opens in my browser with that file already loaded and I can immediately start annotating.

### US-SC-2: Install the slash command from the repo
**As a** developer, **I want to** install the `/shepherd` slash command from the Shepherd repository, **so that** it is available in my AI coding agent without manual setup beyond the initial install.

### US-SC-3: Use the command from any working directory
**As a** developer, **I want to** invoke `/shepherd` from any working directory on my machine, **so that** I am not restricted to being inside the Shepherd repository to use it.

### US-SC-4: Get clear feedback when something goes wrong
**As a** developer, **I want to** see a clear error message if the file I specify does not exist or cannot be loaded, **so that** I can correct my command without confusion.

### US-SC-5: Launch without worrying about the server lifecycle
**As a** developer, **I want** the command to handle starting and stopping the local server for me, **so that** I do not need to manually manage a dev server or build process.

### US-SC-6: Receive the prompt back automatically after annotation
**As a** developer, **I want** the prompt I create in the CRPG to automatically return to my agent conversation when I click Done, **so that** I don't have to copy-paste between the browser and terminal.

### US-SC-7: Fast launch with minimal agent overhead
**As a** developer, **I want** the `/shepherd` command to launch the CRPG as fast as possible, **so that** the command feels instant and I don't lose my train of thought waiting for the app to open.

## Requirements

### Functional Requirements

#### `FR-sc-invoke-command` -- Invoke the CRPG via slash command
The user can type `/shepherd <filepath>` in a supported AI coding agent to launch the CRPG. The `<filepath>` argument is a path to a file on the local filesystem. The command reads the file, starts the CRPG web application (if not already running), opens it in the user's default browser, and loads the specified file into the code viewer automatically. The filepath argument is required; invoking `/shepherd` with no arguments displays a usage message explaining the expected syntax and available options.

#### `FR-sc-file-resolution` -- Resolve file paths
The command resolves the `<filepath>` argument relative to the current working directory of the agent session. It also accepts absolute paths. Symlinks are followed to their target. The resolved absolute path is what gets passed to the CRPG. If the path points to a directory rather than a file, the command rejects it with an error message indicating that only files are accepted, not directories.

#### `FR-sc-file-validation` -- Validate the target file before launch
Before launching the CRPG, the command validates the target file:
1. **Existence**: The file must exist on disk. If it does not, the command reports an error: "File not found: `<resolved-path>`".
2. **Readability**: The file must be readable by the current user. If permission is denied, the command reports an error: "Permission denied: `<resolved-path>`".
3. **Binary detection**: The file must be a text file. Binary detection follows the same heuristic used by the CRPG web app (scan the first 8,192 bytes for null bytes `0x00`). If the file is binary, the command reports an error: "Binary file not supported: `<resolved-path>`". This is consistent with `FR-crp-file-load`.
4. **Size warning**: If the file exceeds 10,000 lines, the command prints a warning that performance may be degraded (consistent with `NFR-crp-large-file-perf`), but proceeds with the launch. It does not block.

#### `FR-sc-app-serve` -- Serve the CRPG web application
The command instructs the agent to start the Vite dev server (`pnpm dev`) in the Shepherd repository if it is not already running. The agent detects a running instance by checking whether the expected port is responding. If the server is already running, it is reused. The server binds to `localhost` and the port is communicated to the browser URL. No pre-built assets or standalone server binary is required — the user must have the repo cloned.

#### `FR-sc-browser-open` -- Open the CRPG in a standalone app window
After the server is running, the command opens the CRPG in a standalone app-mode browser window (not a regular browser tab). The URL includes a query parameter that tells the app which file to load (e.g., `http://localhost:<port>?file=<encoded-path>`). App-mode windows have no address bar, tabs, or browser chrome — they look and feel like a standalone application. The command attempts to open in app mode using Chrome/Chromium's `--app` flag; if Chrome is not available, it falls back to opening in the default browser as a regular tab. If the CRPG app window is already open from a previous invocation, the new file replaces the previously loaded file.

#### `FR-sc-auto-load-file` -- Automatically load the file in the CRPG
When the CRPG web app starts (or is already open) and receives a file path via the URL query parameter, it reads the file from the local filesystem via the local server and loads it into the code viewer. The file name displayed in the UI is derived from the file path (the basename). The language detection and syntax highlighting follow the existing behavior defined in `FR-crp-syntax-highlight`. The app clears any existing session (file, comments, preamble) when a new file is loaded via the slash command, without requiring confirmation even if comments exist. This is intentional: the slash command is a "start fresh with this file" operation.

#### `FR-sc-file-api` -- Local file-serving API endpoint
The local server exposes an API endpoint (e.g., `GET /api/file?path=<encoded-path>`) that reads a file from the local filesystem and returns its content as plain text. This endpoint is what the CRPG web app calls when it receives a file path via URL query parameter. The endpoint only accepts requests from `localhost` (same-origin). It applies the same binary detection check as `FR-sc-file-validation` and returns an appropriate HTTP error (415 Unsupported Media Type) for binary files. The endpoint returns a 404 for files that do not exist and a 403 for files that are not readable.

#### `FR-sc-install` -- Available via repository command file
The slash command lives at `.claude/commands/shepherd.md` in the Shepherd repository. When working inside the repo, it is automatically available as a project-level command — no installation required. For global availability (so `/shepherd` works from any directory), a script (`scripts/install-command.sh`) creates a symlink from `~/.claude/commands/shepherd.md` to the repo's `.claude/commands/shepherd.md`. Because the global command is a symlink, running `git pull` in the repo automatically updates the command everywhere. No npm package or standalone CLI binary is needed for Claude Code users.

#### `FR-sc-server-shutdown` -- Server lifecycle management
The local server is the Vite dev server (`pnpm dev`), managed by the agent or manually by the user. The agent starts the dev server if it is not already running (detected by checking whether the expected port is responding). The user can stop the server manually (e.g., Ctrl-C in the terminal) or the agent can stop it when appropriate. No lockfile, PID tracking, or idle timeout is required.

#### `FR-sc-launcher-script` -- Launcher shell script
The command delegates all validation and launch logic to a shell script (`scripts/shepherd-launch.sh`) rather than having the AI agent perform each step individually. The script handles file path resolution, file validation (existence, readability, binary detection, size warning), server lifecycle (detect running server, start if needed, wait for readiness), URL encoding, and browser opening. The slash command file (`.claude/commands/shepherd.md`) invokes this single script and relays its output. This minimizes the number of agent tool calls required to a single shell invocation, eliminating the per-step AI inference overhead that dominates launch latency.

#### `FR-sc-output-feedback` -- Command output and feedback
After a successful launch, the command outputs a brief confirmation message to the agent conversation:
- The URL where the CRPG is running (e.g., `Opened Code Review Prompt Generator at http://localhost:3847`)
- The file that was loaded (e.g., `Loaded: src/utils.ts (142 lines, TypeScript)`)
- If the server was already running, a note indicating reuse (e.g., `(reusing existing server on port 3847)`)

Error messages are written to stderr. Success messages are written to stdout.

#### `FR-sc-prompt-receive` -- Receive prompt back from CRPG
After launching the CRPG, the slash command instructs the agent to wait for the user to finish annotating. The agent runs a blocking watcher that monitors for the prompt output file (`~/.shepherd/prompt-output.md`). When the file appears (written by the CRPG's Done action per `FR-crp-done-action`), the agent reads its contents and receives the complete generated prompt. The watcher then deletes the output file to prevent stale data. The watcher has a configurable timeout (default: 30 minutes) after which it exits with a message that the user can still paste the prompt manually.

#### `FR-sc-prompt-output-api` -- Prompt output API endpoint
The local server exposes `POST /api/prompt-output` that accepts the generated prompt text in the request body and writes it to `~/.shepherd/prompt-output.md`. The endpoint creates the `~/.shepherd/` directory if it doesn't exist. The endpoint only accepts requests from localhost (same security model as `FR-sc-file-api`). The endpoint overwrites any existing file at that path (in case of stale output from a previous session).

#### `FR-sc-prompt-cleanup` -- Cleanup of stale output files
On startup, the slash command checks for and removes any existing `~/.shepherd/prompt-output.md` file before starting the watcher. This prevents the watcher from immediately picking up stale output from a previous session.

### Non-Functional Requirements

#### `NFR-sc-launch-speed` -- Fast launch time
The time from invoking `/shepherd <filepath>` to the app window opening must be under 2 seconds when the Vite dev server is already running (warm launch). The file should be visible in the code viewer within 4 seconds total (including browser render time). Cold launch (server not running) should complete within 8 seconds. These targets assume a warm filesystem cache and a reasonably modern machine. The previous target of 3 seconds for warm launch assumed agent-mediated step-by-step execution; the launcher script architecture reduces this by eliminating per-step AI inference overhead.

#### `NFR-sc-no-global-deps` -- No global dependencies beyond Node.js
The slash command must not require any global dependencies beyond Node.js (v18+). It must not require the user to have Vite, React, or any other tool installed globally. All dependencies are installed locally via the repo's `node_modules`.

#### `NFR-sc-cross-platform` -- Cross-platform support
The slash command must work on macOS, Linux, and Windows. App-mode window opening uses Chrome/Chromium's `--app` flag where available, with platform-appropriate fallbacks (`open` on macOS, `xdg-open` on Linux, `start` on Windows) when Chrome is not installed.

#### `NFR-sc-localhost-only` -- Localhost-only server binding
The local server must bind exclusively to `127.0.0.1` (localhost). It must not be accessible from other machines on the network. This prevents accidental exposure of local file contents over the network.

#### `NFR-sc-no-telemetry` -- No telemetry or network calls
The slash command and its local server must not make any outbound network requests. No telemetry, analytics, update checks, or external API calls. All functionality is entirely local. This is consistent with the CRPG's existing `NFR-crp-client-only` constraint.

#### `NFR-sc-minimal-footprint` -- Minimal disk and memory footprint
The running Vite dev server process should use less than 100 MB of memory. This is a target guideline, not a hard limit. Disk footprint is governed by the repo and its `node_modules`.

#### `NFR-sc-watcher-low-overhead` -- Low-overhead file watcher
The file watcher that monitors for the prompt output file must use minimal system resources. A simple polling loop with 1-second sleep intervals is sufficient. No filesystem event libraries (inotify, fsevents) are required.

## Acceptance Criteria

#### `AC-sc-launch-happy-path` -- Slash command launches CRPG with a file
**Given** the slash command is installed and a file `src/utils.ts` exists in the current directory, **when** the user types `/shepherd src/utils.ts` in their AI coding agent, **then** the CRPG opens in a standalone app-mode browser window with `src/utils.ts` loaded in the code viewer, syntax highlighted as TypeScript, with the file name "utils.ts" displayed.

#### `AC-sc-standalone-window` -- CRPG opens as a standalone app window
**Given** Chrome or Chromium is installed, **when** the user runs `/shepherd <filepath>`, **then** the CRPG opens in a chromeless app-mode window (no address bar, no tabs, no browser navigation chrome). If Chrome is not available, the CRPG falls back to opening in the default browser as a regular tab.

#### `AC-sc-absolute-path` -- Absolute paths are accepted
**Given** a file exists at `/Users/dev/project/main.py`, **when** the user types `/shepherd /Users/dev/project/main.py`, **then** the CRPG opens with that file loaded, regardless of the current working directory.

#### `AC-sc-file-not-found` -- Missing file produces an error
**Given** no file exists at the path `nonexistent.js`, **when** the user types `/shepherd nonexistent.js`, **then** the command outputs an error message "File not found: `<resolved-absolute-path>/nonexistent.js`" and does not open the browser.

#### `AC-sc-binary-file-rejected` -- Binary files are rejected
**Given** a binary file `image.png` exists in the current directory, **when** the user types `/shepherd image.png`, **then** the command outputs an error message "Binary file not supported: `<resolved-path>/image.png`" and does not open the browser.

#### `AC-sc-permission-denied` -- Unreadable files produce an error
**Given** a file `secret.txt` exists but is not readable by the current user, **when** the user types `/shepherd secret.txt`, **then** the command outputs an error message "Permission denied: `<resolved-path>/secret.txt`" and does not open the browser.

#### `AC-sc-directory-rejected` -- Directories are rejected
**Given** a directory `src/` exists, **when** the user types `/shepherd src/`, **then** the command outputs an error message indicating that only files are accepted, not directories.

#### `AC-sc-no-args-usage` -- No arguments shows usage
**Given** the slash command is installed, **when** the user types `/shepherd` with no arguments, **then** the command outputs a usage message explaining the expected syntax (e.g., "Usage: /shepherd <filepath>").

#### `AC-sc-large-file-warning` -- Large files show a warning but still load
**Given** a text file with 15,000 lines exists, **when** the user types `/shepherd large-file.ts`, **then** the command prints a warning about potential performance degradation, but still launches the CRPG and loads the file.

#### `AC-sc-server-reuse` -- Subsequent invocations reuse the running server
**Given** the user has already run `/shepherd file1.ts` and the server is still running, **when** the user runs `/shepherd file2.ts`, **then** the CRPG opens (or reloads) in the browser with `file2.ts` loaded, reusing the existing server on the same port, and the output message indicates the server was reused.

#### `AC-sc-server-manual-stop` -- Server can be stopped manually
**Given** a Vite dev server is running from a previous `/shepherd` invocation, **when** the user stops the server process (e.g., Ctrl-C in the terminal running `pnpm dev`), **then** the server terminates and the port is freed.

#### `AC-sc-install-global` -- Command is available globally via symlink
**Given** the user has cloned the Shepherd repository, **when** they run `./scripts/install-command.sh`, **then** a symlink is created at `~/.claude/commands/shepherd.md` pointing to the repo's `.claude/commands/shepherd.md`, and `/shepherd` is available globally in Claude Code.

#### `AC-sc-session-clear-on-new-file` -- New file via slash command clears existing session
**Given** the CRPG is already open with a file loaded and comments added, **when** the user runs `/shepherd another-file.ts`, **then** the previous file, all comments, and the preamble are cleared, and the new file is loaded without any confirmation dialog.

#### `AC-sc-cross-platform-open` -- App window opens on all supported platforms
**Given** the slash command is installed on macOS, Linux, or Windows, **when** the user runs `/shepherd <filepath>`, **then** the CRPG opens in an app-mode window using the platform-appropriate mechanism. Falls back to the default browser if app-mode is not available.

#### `AC-sc-prompt-received` -- Agent receives prompt automatically after Done
**Given** the user has launched `/shepherd file.ts` and the agent is waiting (the watcher is running), **when** the user clicks Done in the CRPG, **then** the agent receives the generated prompt text and can proceed to act on it without the user needing to copy-paste.

#### `AC-sc-prompt-watcher-timeout` -- Watcher exits after timeout
**Given** the watcher has been waiting for 30 minutes without receiving a prompt output file, **then** it exits gracefully and the agent informs the user that the session timed out, with instructions to paste the prompt manually.

#### `AC-sc-prompt-cleanup-stale` -- Stale output file is cleaned up on launch
**Given** a stale `~/.shepherd/prompt-output.md` file exists from a previous session, **when** the user runs `/shepherd file.ts`, **then** the stale file is deleted before the watcher starts, so the watcher does not pick up old output.

#### `AC-sc-prompt-output-api-success` -- Prompt output API writes file and returns 200
**Given** the CRPG sends a `POST` to `/api/prompt-output` with the generated prompt text in the request body, **then** the server writes the text to `~/.shepherd/prompt-output.md` and returns HTTP 200.

#### `AC-sc-prompt-output-api-localhost-only` -- Prompt output API rejects non-localhost requests
**Given** a `POST` to `/api/prompt-output` originates from a non-localhost source, **then** the server rejects it with HTTP 403.

#### `AC-sc-warm-launch-2s` -- Warm launch completes within 2 seconds
**Given** the Vite dev server is already running and a valid file path is provided, **when** the user types `/shepherd <filepath>`, **then** the browser tab opens within 2 seconds of the command being invoked.

#### `AC-sc-cold-launch-8s` -- Cold launch completes within 8 seconds
**Given** the Vite dev server is not running and a valid file path is provided, **when** the user types `/shepherd <filepath>`, **then** the browser tab opens within 8 seconds of the command being invoked, including server startup time.

#### `AC-sc-single-tool-call` -- Command uses a single agent tool call
**Given** the `/shepherd` command is invoked with a file path, **when** the agent processes the command, **then** the entire launch operation (validation, server check, browser open) is completed in a single shell invocation rather than multiple sequential agent tool calls. This ensures launch speed is bounded by shell execution time, not AI inference time.

## Open Questions

1. **Agent-specific registration**: Different AI coding agents have different mechanisms for custom slash commands. Claude Code uses a `.claude/commands/` directory. Other agents may use different configuration formats. Should v1 target only Claude Code, or should the install step produce configurations for multiple agents? This PRD assumes Claude Code as the primary target for v1, with the architecture allowing other agents to be supported later.

2. **Multiple files**: Should `/shepherd` accept multiple file paths (e.g., `/shepherd file1.ts file2.ts`) and load them all? The CRPG currently only supports single-file sessions (`FR-crp-file-load`). This PRD scopes to single-file only, consistent with the existing CRPG behavior. Multi-file support would require changes to both the slash command and the CRPG.

3. **Glob patterns**: Should `/shepherd src/*.ts` expand globs and load matching files? Deferred for the same reason as multi-file support.

4. **Remote/URL file loading**: Should the command support loading a file from a URL or GitHub path (e.g., `/shepherd https://github.com/org/repo/blob/main/file.ts`)? Deferred; local files only for v1, consistent with `FR-crp-file-load`.

5. **Hot reload on file change**: Should the CRPG automatically reload the file if it changes on disk while the app is open (file watching)? This could be useful but adds complexity. Deferred to a future iteration.

6. **Security of the file-serving API**: The `FR-sc-file-api` endpoint serves arbitrary local files. While it is localhost-only (`NFR-sc-localhost-only`), a malicious webpage could potentially make requests to localhost. Should the endpoint require a one-time token or use a non-standard port to mitigate this? Engineering should evaluate the threat model.

7. **Standalone CLI for non-Claude-Code users**: The current approach targets Claude Code exclusively via the `.claude/commands/` mechanism. A standalone CLI (e.g., an npm package providing a `shepherd` binary) could be added later for users of other AI coding agents or for direct invocation from the terminal. This is deferred to a future iteration.

## Dependencies

- **Shepherd repository (cloned)**: The slash command and CRPG source live in the repo. The user must have the repo cloned locally.
- **Node.js runtime**: The Vite dev server requires Node.js 18+.
- **CRPG web application**: The slash command depends on the existing CRPG at `engineering/apps/web/` and the ability to load files into the code viewer.
- **`FR-crp-file-load`**: The auto-load behavior builds on the existing file loading mechanism, extending it to accept a file path from a URL query parameter rather than only user interaction (drag-drop, upload, paste).
- **`FR-crp-syntax-highlight`**: Language detection for the auto-loaded file uses the same detection logic.
- **`NFR-crp-client-only`**: The CRPG itself remains client-side. The local server is only for serving the app and providing the file-reading API endpoint. No file content leaves the machine.
