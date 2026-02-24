# Slash Command Launcher -- Design Spec

> Based on requirements in `../product/slash-command.md`

## Overview

The Slash Command Launcher is a Claude Code custom command with a small web-app integration surface. Unlike the CRPG design spec (see `design/code-review-prompt.md`), which describes a full single-page application, this spec covers:

1. **Claude Code custom command**: The `.claude/commands/shepherd.md` file that defines the `/shepherd` slash command. The agent validates the file, manages the Vite dev server, and opens the browser.
2. **Local Vite dev server**: How the dev server starts and serves the CRPG with the file API plugin.
3. **CRPG web app modifications**: Changes to the existing App root component and FileDropZone to support auto-loading a file from URL query parameters.
4. **Installation flow**: What the user does to make `/shepherd` available globally.

The user never interacts with a "slash command UI." The CLI output appears inline in the agent conversation (stdout/stderr), and the browser experience is the existing CRPG (with modifications for auto-load).

---

## Interface Inventory

This feature spans two surfaces: the agent conversation (Claude Code) and the existing CRPG web app (browser). There are no new screens or pages; the CRPG modifications are behavioral changes to existing components.

| Surface | What Changes |
|---|---|
| **Agent conversation (Claude Code)** | New -- the `/shepherd` custom command produces output inline in the conversation, then enters a waiting state for the prompt feedback loop |
| **CRPG web app -- Standalone window** | New -- the CRPG opens in a chromeless app-mode browser window (no address bar, no tabs) via Chrome's `--app` flag, rather than a regular browser tab. Falls back to a normal browser tab if Chrome is unavailable. |
| **CRPG web app -- App root** | Modified -- reads `?file=` query parameter on load and triggers file fetch |
| **CRPG web app -- Toolbar** | Modified -- Done button appears in slash command mode (see `design/code-review-prompt.md`, Toolbar component spec) |
| **CRPG web app -- FileDropZone** | Modified -- bypassed when a file is auto-loaded via URL parameter |
| **CRPG web app -- FileHeader** | Unchanged -- displays the basename from the auto-loaded file path |
| **CRPG web app -- Window title** | Modified -- displays session context (project/worktree name) to identify concurrent sessions (`FR-crp-session-identity`) |
| **CRPG web app -- Toolbar** | Unchanged -- session clear behavior applies when a new file replaces an existing one |

---

## Command Syntax (`FR-sc-invoke-command`, `FR-sc-file-resolution`)

```
/shepherd <filepath>
/shepherd --help
```

- `<filepath>` is a required positional argument. It is a path to a local file, either relative (resolved against the current working directory) or absolute.
- `--help` displays the usage message (same content as the no-args output).
- No other flags or options exist in v1.

When invoked as a slash command in Claude Code (e.g., `/shepherd src/utils.ts`), the agent executes the instructions in the custom command file. The agent validates the file, ensures the Vite dev server is running, opens the browser with the appropriate URL, and then enters a **waiting state** where it runs a blocking file watcher for `~/.shepherd/sessions/<session-id>/prompt-output.md`. The agent remains blocked until the user clicks "Done" in the CRPG (which writes the prompt to the watched file) or the watcher times out after 30 minutes (`FR-sc-prompt-receive`).

### Output Format (`FR-sc-output-feedback`)

All output is plain text reported by the agent in the conversation. No colors, no ANSI escape codes, no emoji. This ensures output renders correctly in the agent conversation UI.

#### Successful launch

```
Opened Code Review Prompt Generator at http://localhost:4821
Loaded: src/utils.ts (142 lines, TypeScript)
Session: my-project
The file is loaded in the Code Review Prompt Generator. Annotate your code and click Done when you're finished. I'll wait for your prompt.
```

Output fields:
- **Line 1**: The full URL where the CRPG is accessible. The port is dynamically assigned (`FR-sc-dynamic-port`). Always present.
- **Line 2**: The file that was loaded. Format: `Loaded: <relative-or-original-path> (<line-count> lines, <language>)`. The path shown is the same path the user typed (not the resolved absolute path), so it matches their mental model. The line count is the number of newline-delimited lines. The language is detected from the file extension using the same detection logic as `FR-crp-syntax-highlight`; if unknown, shows "Plain Text".
- **Line 3**: The session ID. A human-readable identifier derived from the project directory name (`FR-sc-session-id`). Helps identify which session/worktree this window belongs to.
- **Line 4**: The waiting message. Tells the user to annotate and click Done, and confirms the agent will wait. Always present after a successful launch.

#### Prompt received (`FR-sc-prompt-receive`)

After the user clicks "Done" in the CRPG and the watcher detects the prompt output file:

```
Received review prompt (3 comments on src/utils.ts)
```

Output fields:
- **Line 1**: Confirmation that the prompt was received. Format: `Received review prompt (<comment-count> comments on <filename>)`. The comment count and filename are extracted from the prompt content.

#### Watcher timeout (`AC-sc-prompt-watcher-timeout`)

If the user does not click Done within 30 minutes:

```
The annotation session timed out. You can still paste your prompt here -- it should be on your clipboard if you clicked Copy or Done in the tool.
```

#### Large file warning (`AC-sc-large-file-warning`)

When the file exceeds 10,000 lines (consistent with `NFR-crp-large-file-perf`):

```
Warning: src/big-file.ts has 15000 lines. Performance may be degraded for very large files.
Opened Code Review Prompt Generator at http://localhost:4821
Loaded: src/big-file.ts (15000 lines, TypeScript)
Session: my-project
```

The warning is reported before the success output.

#### Usage message (`AC-sc-no-args-usage`)

Displayed when the user runs `/shepherd` with no arguments or with `--help`:

```
Usage: /shepherd <filepath>

Open a file in the Code Review Prompt Generator.

Arguments:
  <filepath>    Path to a text file (relative or absolute)

Options:
  --help        Show this help message

Examples:
  /shepherd src/utils.ts
  /shepherd /Users/dev/project/main.py
```

### Error Message Format (`FR-sc-file-validation`)

All error messages are reported by the agent. Each error is a single line starting with `Error:` followed by a specific message. The browser is never opened when an error occurs.

| Condition | Message | Requirement |
|---|---|---|
| File not found | `Error: File not found: /absolute/resolved/path/to/file.ts` | `AC-sc-file-not-found` |
| Permission denied | `Error: Permission denied: /absolute/resolved/path/to/secret.txt` | `AC-sc-permission-denied` |
| Binary file | `Error: Binary file not supported: /absolute/resolved/path/to/image.png` | `AC-sc-binary-file-rejected` |
| Directory given | `Error: Path is a directory, not a file: /absolute/resolved/path/to/src/` | `AC-sc-directory-rejected` |
| No arguments | _(usage message, not an error)_ | `AC-sc-no-args-usage` |

Error messages always show the **resolved absolute path** (after path resolution per `FR-sc-file-resolution`). This helps the user understand exactly which path was checked when the error occurred, even if they provided a relative path.

---

## Interaction Flows

### Flow 1: Happy Path -- Launch CRPG with a File (`AC-sc-launch-happy-path`)

1. User types `/shepherd src/utils.ts` in their Claude Code session.
2. The agent reads the custom command file and follows its instructions.
3. Agent resolves the path relative to the current working directory (`FR-sc-file-resolution`). Symlinks are followed.
4. Agent validates the file (`FR-sc-file-validation`):
   - Checks existence (stat). If not found, reports error.
   - Checks that it is a file, not a directory. If directory, reports error.
   - Checks read permission. If denied, reports error.
   - Reads the first 8,192 bytes and checks for null bytes. If binary, reports error.
   - Counts lines. If > 10,000, reports warning (but continues).
5. Agent checks whether a Vite dev server is already running for the current worktree (by checking the recorded port from a previous invocation in this worktree).
   - If a server is running for this worktree, reuse it (`AC-sc-server-reuse`).
   - If no server is running for this worktree, start one with `pnpm dev`. The server binds to a dynamically assigned port (`FR-sc-dynamic-port`).
6. Agent derives the session ID from the project directory basename (`FR-sc-session-id`).
7. Agent opens a standalone app-mode window with `http://localhost:<port>?session=<id>&file=<url-encoded-absolute-path>` (`FR-sc-browser-open`, `FR-sc-concurrent-windows`). See Cross-Platform Behavior for the fallback chain.
8. Agent reports the success output in the conversation.
9. In the browser, the CRPG app reads the `?file=` and `?session=` query parameters, fetches the file content from `GET /api/file?path=<encoded-path>`, and loads it into the code viewer (`FR-sc-auto-load-file`). The session ID is stored in app state for use when calling `POST /api/prompt-output`. Any existing session is cleared without confirmation (`AC-sc-session-clear-on-new-file`).

**Timing**: The agent should complete file validation and server check quickly. The Vite dev server starts fast since it does not require a build step (`NFR-sc-launch-speed`).

### Flow 2: Subsequent Invocation -- Same Worktree (`AC-sc-server-reuse`)

1. User has previously run `/shepherd file1.ts` from worktree A. The Vite dev server is still running on a dynamic port (e.g., 4821).
2. User types `/shepherd file2.ts` from the same worktree A.
3. Agent resolves and validates `file2.ts` (same as Flow 1, steps 3-4).
4. Agent detects a server is already running for this worktree and reuses it.
5. Agent generates a new session ID for this invocation (`FR-sc-session-id`).
6. Agent opens the browser with `http://localhost:4821?session=<new-id>&file=<url-encoded-absolute-path-to-file2>`.
7. Agent reports success output in the conversation.
8. In the browser:
   - If the previous CRPG window is still open, a new app-mode window opens for the new session (`FR-sc-concurrent-windows`). Both windows share the same server.
   - If the previous window was closed, the new window opens and the app starts fresh with the new file.

### Flow 2b: Concurrent Sessions -- Different Worktrees (`AC-sc-concurrent-sessions`)

1. User types `/shepherd src/utils.ts` from worktree `myproject`. A server starts on a dynamic port (e.g., 4821). Session `myproject` opens in a new app-mode window.
2. User switches to worktree `other-repo` in a different terminal/session.
3. User types `/shepherd lib/helpers.ts` from worktree `other-repo`. A separate server starts on a different dynamic port (e.g., 4822). Session `other-repo` opens in its own app-mode window.
4. Both browser windows are now active simultaneously. Each shows its own file from its own worktree. The window titles show different project names ("Shepherd — myproject" vs "Shepherd — other-repo") (`FR-crp-session-identity`).
5. User clicks "Done" in session `myproject`. The prompt is written to `~/.shepherd/sessions/myproject/prompt-output.md` (`FR-sc-session-scoped-output`). Session `other-repo` is unaffected (`AC-sc-session-output-isolation`).
6. The agent watching worktree A reads the prompt output. Worktree B's agent continues waiting for its own session.

### Flow 3: File Not Found (`AC-sc-file-not-found`)

1. User types `/shepherd nonexistent.js`.
2. Agent resolves the path to an absolute path (e.g., `/Users/dev/project/nonexistent.js`).
3. Agent checks file existence. The file does not exist.
4. Agent reports: `Error: File not found: /Users/dev/project/nonexistent.js`
5. The browser is not opened. No server is started.

### Flow 4: Binary File Rejected (`AC-sc-binary-file-rejected`)

1. User types `/shepherd image.png`.
2. Agent resolves the path and confirms the file exists and is readable.
3. Agent reads the first 8,192 bytes and detects null bytes.
4. Agent reports: `Error: Binary file not supported: /Users/dev/project/image.png`
5. The browser is not opened.

### Flow 5: Permission Denied (`AC-sc-permission-denied`)

1. User types `/shepherd secret.txt`.
2. Agent resolves the path and confirms the file exists.
3. Agent attempts to read the file. The OS returns a permission error.
4. Agent reports: `Error: Permission denied: /Users/dev/project/secret.txt`

### Flow 6: Directory Rejected (`AC-sc-directory-rejected`)

1. User types `/shepherd src/`.
2. Agent resolves the path and stats it. It is a directory.
3. Agent reports: `Error: Path is a directory, not a file: /Users/dev/project/src/`

### Flow 7: No Arguments -- Usage Message (`AC-sc-no-args-usage`)

1. User types `/shepherd` with no arguments.
2. Agent reports the usage message (see Output Format section above).

### Flow 8: Absolute Path (`AC-sc-absolute-path`)

1. User types `/shepherd /Users/dev/project/main.py`.
2. Agent detects the path is already absolute (starts with `/` on Unix, drive letter on Windows).
3. Validation and launch proceed identically to Flow 1. The path is used as-is (after symlink resolution).

### Flow 9: Installation (`AC-sc-install-symlink`, `FR-sc-install`)

1. User clones the Shepherd repository.
2. User runs `./scripts/install-command.sh` from the repo root.
3. The script creates a symlink at `~/.claude/commands/shepherd.md` pointing to the repo's `.claude/commands/shepherd.md` file.
4. The `/shepherd` command is now available globally in all Claude Code sessions.
5. Updates to the command file propagate automatically through the symlink -- when the user runs `git pull`, any changes to `.claude/commands/shepherd.md` are immediately reflected without re-running the install script.

### Flow 10: Prompt Feedback Loop -- Agent Receives Prompt (`FR-sc-prompt-receive`, `FR-sc-prompt-output-api`, `AC-sc-prompt-received`)

1. User types `/shepherd src/utils.ts` in their Claude Code session.
2. Agent validates the file and opens the CRPG in the browser (existing Flow 1, steps 1-7).
3. Agent prints: "The file is loaded in the Code Review Prompt Generator. Annotate your code and click Done when you're finished. I'll wait for your prompt."
4. Agent cleans up any stale prompt output file at `~/.shepherd/sessions/<session-id>/prompt-output.md` (`FR-sc-prompt-cleanup`, `AC-sc-prompt-cleanup-stale`).
5. Agent runs the file watcher -- a blocking shell loop that polls for the existence of `~/.shepherd/sessions/<session-id>/prompt-output.md`. The loop checks once per second and exits on one of two conditions: the file appears, or 30 minutes elapse.
6. User annotates code in the CRPG (minutes pass). The agent conversation is blocked during this time.
7. User clicks "Done" in the CRPG toolbar.
8. The CRPG sends a POST request to `/api/prompt-output?session=<session-id>` with the generated prompt text. The server-side handler writes the prompt content to `~/.shepherd/sessions/<session-id>/prompt-output.md` (`FR-sc-prompt-output-api`, `AC-sc-prompt-output-api-success`, `FR-sc-session-scoped-output`).
9. On POST success, the CRPG calls `window.close()`. In app-mode, the window closes and focus returns to the terminal (the last active window). If the window cannot be closed (not in app-mode), the CRPG falls back to showing the "Sent" confirmation state (see `design/code-review-prompt.md`, Flow 15).
10. The watcher detects the file on its next poll iteration (within 1 second). It reads the file contents, outputs them to stdout, and deletes the file. The session directory (`~/.shepherd/sessions/<session-id>/`) is cleaned up (`FR-sc-session-cleanup`).
11. The agent receives the prompt text from the watcher's stdout. It reports: "Received review prompt (3 comments on src/utils.ts)" and proceeds to act on the prompt content.

### Flow 11: Prompt Feedback Loop -- Timeout (`AC-sc-prompt-watcher-timeout`)

1. User types `/shepherd src/utils.ts` in their Claude Code session.
2. Agent validates, launches, and enters the waiting state (Flow 10, steps 1-5).
3. User does not click "Done" within 30 minutes. The user may have closed the browser, gotten distracted, or chosen to copy the prompt manually instead.
4. The watcher's timeout elapses. The loop exits with a timeout status.
5. Agent reports: "The annotation session timed out. You can still paste your prompt here -- it should be on your clipboard if you clicked Copy or Done in the tool."
6. The agent conversation is unblocked. The user can paste the prompt manually or run `/shepherd` again.

---

## Server Management

The Vite dev server is a standard development server. The agent manages it as follows:

### Server Start

- On the first `/shepherd <file>` invocation in a given worktree, the agent starts a Vite dev server with `pnpm dev`. The server binds to a dynamically assigned port (`FR-sc-dynamic-port`) rather than the fixed port 5173. The agent records the assigned port so subsequent invocations from the same worktree can reuse the server.
- The server serves the CRPG web app with hot module replacement and the file API plugin.
- Startup is fast since Vite does not perform a full build in dev mode (`NFR-sc-launch-speed`).

### Server Reuse

- On subsequent invocations from the same worktree, the agent detects that a server is already running for this worktree (via the recorded port) and reuses it. No new server is started. Each new invocation generates a fresh session ID but connects to the existing server.

### Multiple Concurrent Servers

- Multiple servers can run simultaneously, one per worktree. Each server binds to its own dynamically assigned port. This supports concurrent review sessions across different codebases or worktrees (`AC-sc-concurrent-sessions`).

### Server Stop

- The user stops the Vite dev server manually when done (e.g., Ctrl+C in the terminal where `pnpm dev` is running, or by closing the terminal).
- There is no automatic idle shutdown. The dev server runs until explicitly stopped.

---

## CRPG Web App Changes

The following changes are required to the existing CRPG web application (designed in `design/code-review-prompt.md`). These are modifications to existing components, not new components.

### App Root Component -- URL Parameter Handling (`FR-sc-auto-load-file`)

**Current behavior**: The App root component renders the Empty State (FileDropZone) on initial load and waits for user interaction to load a file.

**New behavior**: On mount, the App root component checks for `?file=` and `?session=` query parameters in the URL.

- **If `?file=` is present**:
  1. Extract the file path from the `?file=` query parameter (URL-decoded).
  2. If `?session=` is also present, extract the session ID and store it in app state. The session ID is used when calling `POST /api/prompt-output?session=<session-id>` (`FR-sc-session-id`).
  3. Fetch the file content from the local server API: `GET /api/file?path=<encoded-path>`.
  4. While fetching, show a brief loading state (the FileDropZone in its `loading` variant with text "Loading file...").
  5. On success: transition directly to the File Loaded state. The file name is derived from the path basename (e.g., `/Users/dev/project/src/utils.ts` yields `utils.ts`). Language is detected from the file extension per `FR-crp-syntax-highlight`. If a session already exists (file loaded, comments present), it is cleared without confirmation (`AC-sc-session-clear-on-new-file`).
  6. On error (4xx/5xx from the API): show the FileDropZone in its `error` variant with the error message from the API response. The user can then manually load a file through the normal drop zone interactions.
- **If `?file=` is not present**: existing behavior is unchanged. The Empty State renders normally.

**Navigation/URL handling**: After loading a file from a `?file=` parameter, the app clears the query parameter from the URL (using `history.replaceState`) so that refreshing the page returns to the Empty State rather than re-fetching the file. This is consistent with the session being in-memory only (`NFR-crp-no-data-persistence`).

### FileDropZone Component -- Auto-Load Bypass

**Current behavior**: The FileDropZone is the only entry point for loading files (see FileDropZone component spec in `design/code-review-prompt.md`).

**New behavior**: The FileDropZone is not rendered when a file is being auto-loaded via URL parameter. Instead, the App root component shows the FileDropZone's `loading` variant briefly (reusing its visual appearance), then transitions directly to the File Loaded state. If auto-load fails, the FileDropZone renders in its `error` variant with the server error message, allowing the user to fall back to manual loading.

No changes to the FileDropZone component itself are required. The bypass logic lives in the App root component.

### Session Clear on New File (`AC-sc-session-clear-on-new-file`)

When a new file is loaded via the slash command (i.e., the app receives a new `?file=` parameter while a session is already active):

- The existing file content is replaced.
- All inline comments are removed.
- The preamble is cleared.
- The generated prompt (if any) is cleared.
- No confirmation dialog is shown, even if comments exist. This overrides the normal clear session behavior defined in Flow 12 of `design/code-review-prompt.md` (`AC-crp-clear-confirmation`).

This is intentional: the slash command is a "start fresh with this file" operation. The user is invoking it from their agent conversation with the explicit intent to review a specific file.

### File-Serving API Endpoint (`FR-sc-file-api`)

The Vite dev server exposes a file API endpoint via a Vite plugin. The CRPG web app calls this endpoint to load files:

```
GET /api/file?path=<url-encoded-absolute-path>
```

**Responses**:

| Status | Condition | Body |
|---|---|---|
| 200 OK | File read successfully | File content as `text/plain; charset=utf-8` |
| 403 Forbidden | Permission denied | `{"error": "Permission denied: <path>"}` as `application/json` |
| 404 Not Found | File does not exist | `{"error": "File not found: <path>"}` as `application/json` |
| 415 Unsupported Media Type | Binary file detected | `{"error": "Binary file not supported: <path>"}` as `application/json` |

The endpoint only accepts requests from the same origin (localhost). The `Origin` or `Host` header must reference `127.0.0.1` or `localhost`. Requests from other origins are rejected with 403 (`NFR-sc-localhost-only`).

The response for a 200 also includes a `X-File-Lines` header with the total line count and a `X-File-Language` header with the detected language (e.g., `TypeScript`, `Python`, `Plain Text`). This allows the CRPG app to display file metadata without parsing the content itself.

### Prompt Output API Endpoint (`FR-sc-prompt-output-api`, `AC-sc-prompt-output-api-success`, `AC-sc-prompt-output-api-localhost-only`)

The Vite dev server exposes a prompt output endpoint via the same Vite plugin as the file API. The CRPG web app calls this endpoint when the user clicks "Done" (see `design/code-review-prompt.md`, Flow 15).

```
POST /api/prompt-output?session=<session-id>
```

**Request**:
- Content-Type: `text/plain; charset=utf-8`
- Body: The full generated prompt text.
- Query parameter: `session` -- the session ID that was passed to the CRPG via the URL (`FR-sc-session-id`). Required when in slash command mode.

**Responses**:

| Status | Condition | Body |
|---|---|---|
| 200 OK | Prompt written successfully | `{"status": "ok"}` as `application/json` |
| 400 Bad Request | Missing session parameter | `{"error": "Missing session parameter"}` as `application/json` |
| 403 Forbidden | Request not from localhost | `{"error": "Forbidden"}` as `application/json` |
| 500 Internal Server Error | Failed to write file | `{"error": "Failed to write prompt output"}` as `application/json` |

**Server-side behavior**:
1. Validate that the request originates from localhost (`127.0.0.1` or `::1`), same as the file API endpoint (`AC-sc-prompt-output-api-localhost-only`).
2. Read the `session` query parameter. If missing, return 400.
3. Read the request body as UTF-8 text.
4. Ensure the `~/.shepherd/sessions/<session-id>/` directory exists (create if needed) (`FR-sc-session-scoped-output`).
5. Write the prompt text to `~/.shepherd/sessions/<session-id>/prompt-output.md`, overwriting any existing content.
6. Return 200 with `{"status": "ok"}`.

If the write fails for any reason (permission denied, disk full, etc.), return 500.

---

### Error Display in the CRPG App

When the `/api/file` endpoint returns an error, the CRPG app displays the error in the FileDropZone's existing `error` variant (defined in `design/code-review-prompt.md`):

| API Status | Error Message Displayed |
|---|---|
| 403 | "Permission denied. The file could not be read." |
| 404 | "File not found. It may have been moved or deleted." |
| 415 | "This file doesn't appear to be a text file. Only plain-text files are supported." (reuses existing binary file error message from `AC-crp-binary-file-rejected`) |
| Network error | "Could not connect to the local server. Try running the shepherd command again." |

After an error, the FileDropZone is fully functional -- the user can load a different file via drag-and-drop, upload, or paste.

---

## Installation Flow (`FR-sc-install`, `AC-sc-install-symlink`)

### Prerequisites

- Node.js 18+ (for running the Vite dev server)
- pnpm (for `pnpm dev`)
- Claude Code (for the `/shepherd` slash command)

### Steps

1. **Clone the repository**:
   ```
   git clone <repo-url>
   cd shepherd
   ```

2. **Run the install script**:
   ```
   ./scripts/install-command.sh
   ```
   This creates a symlink at `~/.claude/commands/shepherd.md` pointing to the repo's `.claude/commands/shepherd.md` file. The `/shepherd` command is now available globally in all Claude Code sessions.

3. **Verify installation**:
   ```
   ls -la ~/.claude/commands/shepherd.md
   ```
   Should show a symlink pointing to the repo's command file.

### How Updates Work

Because the global command is a symlink, updates propagate automatically:

```
cd shepherd
git pull
```

Any changes to `.claude/commands/shepherd.md` in the repo are immediately available to all Claude Code sessions without re-running the install script.

### What Gets Installed

The install script creates a single symlink. No binaries, no npm packages, no global dependencies. The Vite dev server and CRPG assets live in the repo and are used in place.

---

## Cross-Platform Behavior (`NFR-sc-cross-platform`, `AC-sc-cross-platform-open`)

### Browser Opening (`FR-sc-browser-open`, `AC-sc-standalone-window`)

The agent opens the CRPG in a **standalone app-mode window** -- a chromeless browser window with no address bar, tabs, or browser chrome. This uses Chrome/Chromium's `--app=<url>` flag. If Chrome is not available, the agent falls back through a chain until one succeeds.

**Why app-mode**: App-mode windows feel like a standalone tool rather than a website. More importantly, when the user clicks Done and the window closes, focus naturally returns to the terminal -- the last active window before the CRPG opened.

| Platform | Primary (app mode) | Fallback |
|---|---|---|
| macOS | `open -na "Google Chrome" --args --app=<url>` | Try Chromium, then `open <url>` |
| Linux | `google-chrome --app=<url>` | Try `chromium --app=<url>`, then `xdg-open <url>` |
| Windows | `start chrome --app=<url>` | `start <url>` |

The fallback chain is: Chrome app mode -> Chromium app mode -> default browser. Each step is tried only if the previous one fails (e.g., the command is not found or returns an error). The final fallback (default browser) opens a regular browser tab, which still works but does not have the chromeless appearance or the auto-close-on-Done behavior.

If all browser-open attempts fail (e.g., `xdg-open` not installed on a headless Linux server), the agent reports the URL and a note:

```
Opened Code Review Prompt Generator at http://localhost:4821
Loaded: src/utils.ts (142 lines, TypeScript)
Session: my-project
Warning: Could not open the browser automatically. Open the URL above in your browser.
```

The file is still loaded and the server is still running. The user can manually open the URL.

### Path Handling

- On Unix (macOS, Linux): paths use `/` separators. Home directory is `$HOME`.
- On Windows: paths use `\` separators but `/` is also accepted. Home directory is `%USERPROFILE%`.
- The `?file=` query parameter always uses the OS-native path format, URL-encoded.

---

## Requirement Traceability

This section maps every product requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-sc-invoke-command` | Command Syntax; Flow 1 (happy path) |
| `FR-sc-file-resolution` | Command Syntax (relative/absolute); Flow 1 step 3; Flow 8 (absolute path) |
| `FR-sc-file-validation` | Error Message Format; Flow 1 step 4; Flows 3-6 (error cases) |
| `FR-sc-app-serve` | Server Management section; Flow 1 step 5-6 |
| `FR-sc-browser-open` | Flow 1 step 6; Cross-Platform Behavior (browser opening, app-mode window, fallback chain) |
| `FR-sc-auto-load-file` | CRPG Web App Changes -- App Root Component; Flow 1 step 8 |
| `FR-sc-file-api` | CRPG Web App Changes -- File-Serving API Endpoint |
| `FR-sc-install` | Installation Flow section |
| `FR-sc-output-feedback` | Output Format |
| `FR-sc-prompt-receive` | Command Syntax (waiting state); Flow 10; Output Format -- Prompt received |
| `FR-sc-prompt-output-api` | Prompt Output API Endpoint section; Flow 10 step 8 |
| `FR-sc-prompt-cleanup` | Flow 10 step 4 |
| `FR-sc-session-id` | Output Format -- Successful launch (Line 3); Flow 1 step 6; Flow 2 step 5; App Root Component (session parameter extraction) |
| `FR-sc-dynamic-port` | Output Format -- Successful launch (Line 1); Flow 1 step 5; Server Management -- Server Start |
| `FR-sc-session-scoped-output` | Flow 10 steps 4-5, 8, 10; Prompt Output API Endpoint (session-scoped write path) |
| `FR-sc-concurrent-windows` | Flow 1 step 7; Flow 2 step 6; Flow 2b (concurrent sessions) |
| `FR-sc-session-cleanup` | Flow 10 step 10 (session directory cleanup) |
| `FR-crp-session-identity` | Interface Inventory (window title); Flow 2b step 4 |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-sc-launch-speed` | Flow 1 timing note; Server Management -- Server Start |
| `NFR-sc-no-global-deps` | Installation Flow -- Prerequisites (Node.js and pnpm only) |
| `NFR-sc-cross-platform` | Cross-Platform Behavior section |
| `NFR-sc-localhost-only` | File-Serving API Endpoint (origin check) |
| `NFR-sc-no-telemetry` | Implicit -- no outbound network calls in any flow or component |
| `NFR-sc-minimal-footprint` | Installation Flow -- What Gets Installed (single symlink) |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-sc-launch-happy-path` | Flow 1 |
| `AC-sc-absolute-path` | Flow 8 |
| `AC-sc-file-not-found` | Flow 3; Error Message Format table |
| `AC-sc-binary-file-rejected` | Flow 4; Error Message Format table |
| `AC-sc-permission-denied` | Flow 5; Error Message Format table |
| `AC-sc-directory-rejected` | Flow 6; Error Message Format table |
| `AC-sc-no-args-usage` | Flow 7; Usage message format |
| `AC-sc-large-file-warning` | Output Format -- Large file warning; Flow 1 step 4 |
| `AC-sc-server-reuse` | Flow 2 |
| `AC-sc-install-symlink` | Installation Flow section |
| `AC-sc-session-clear-on-new-file` | CRPG Web App Changes -- Session Clear on New File |
| `AC-sc-standalone-window` | Cross-Platform Behavior -- Browser Opening (app-mode window); Interface Inventory; Flow 1 step 6 |
| `AC-sc-cross-platform-open` | Cross-Platform Behavior -- Browser Opening (platform table, fallback chain) |
| `AC-sc-prompt-received` | Flow 10 steps 10-11; Output Format -- Prompt received |
| `AC-sc-prompt-watcher-timeout` | Flow 11; Output Format -- Watcher timeout |
| `AC-sc-prompt-cleanup-stale` | Flow 10 step 4 |
| `AC-sc-prompt-output-api-success` | Prompt Output API Endpoint (200 response); Flow 10 step 8 |
| `AC-sc-prompt-output-api-localhost-only` | Prompt Output API Endpoint (403 response, localhost check) |
| `AC-sc-concurrent-sessions` | Flow 2b (concurrent sessions from different worktrees); Server Management -- Multiple Concurrent Servers |
| `AC-sc-session-output-isolation` | Flow 2b step 5 (session-scoped output does not affect other sessions) |
