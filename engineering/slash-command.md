# Slash Command Launcher -- Technical Spec

> Based on requirements in `../product/slash-command.md`
> Based on design in `../design/slash-command.md`

## Technical Approach

The slash command feature uses a single-mode architecture: a Claude Code custom command backed by a Vite dev server plugin.

When a developer types `/shepherd README.md` in Claude Code, the custom command file at `.claude/commands/shepherd.md` instructs the agent to start the CRPG dev server (if not already running), then open the browser to `http://localhost:5173?file=<encoded-path>`. The web app reads the URL parameter and fetches the file from an API endpoint served by a Vite plugin.

- **In-repo use**: Works automatically. Claude Code discovers project-level commands from `.claude/commands/` in the repo.
- **Global use**: `scripts/install-command.sh` creates a symlink from `~/.claude/commands/shepherd.md` to the repo's `.claude/commands/shepherd.md`. This means updates propagate automatically via `git pull` -- no reinstall needed.
- **Server**: The Vite dev server (with the file API plugin) is the only server. No standalone server, no bundled assets, no lockfile/PID management.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Command mechanism | Claude Code custom command (`.claude/commands/shepherd.md`) | Zero code needed for the command itself -- it is a markdown prompt file that Claude Code natively supports. The agent reads the file, follows instructions, and executes shell commands. No CLI binary required. |
| Dev server file API | Vite plugin | Vite's plugin API supports the `configureServer` hook, which gives access to the underlying Connect middleware stack. A custom plugin can register an Express-style route handler for `/api/file` without adding any npm dependencies. This keeps the dev server self-contained. |
| Global install mechanism | Symlink via install script | A symlink from `~/.claude/commands/shepherd.md` to the repo file means the command stays in sync with the repo. No package manager, no version management, no publish step. `git pull` is the update mechanism. |

---

## Claude Code Custom Command Design

> Implements: `FR-sc-invoke-command`, `FR-sc-install`

### File: `.claude/commands/shepherd.md`

This is a Claude Code custom slash command file. When a user types `/shepherd README.md`, Claude Code reads this file, substitutes `$ARGUMENTS` with `README.md`, and the agent follows the instructions as a prompt.

The command file instructs the agent to:

**Note**: The command file has been simplified to delegate all heavy lifting to `scripts/shepherd-launch.sh`. The agent's role is reduced to a single shell invocation.

1. Validate that `$ARGUMENTS` is provided. If empty, print usage instructions and stop (`AC-sc-no-args-usage`).
2. Run `scripts/shepherd-launch.sh "$ARGUMENTS"` and relay the output to the user. The launcher script handles all of the following in a single invocation: resolve the file path relative to the current working directory (`FR-sc-file-resolution`), validate the file (existence, not a directory, readability, binary detection, line count) (`FR-sc-file-validation`, `AC-sc-file-not-found`, `AC-sc-binary-file-rejected`, `AC-sc-permission-denied`, `AC-sc-directory-rejected`), warn if lines > 10,000 (`AC-sc-large-file-warning`), check if the Vite dev server is running and start it if needed (`FR-sc-app-serve`), open the CRPG in a Chrome/Chromium app-mode window with platform-specific fallback chain (`FR-sc-browser-open`, `AC-sc-standalone-window`), and print the success message (`FR-sc-output-feedback`).

### Why a Prompt File, Not a Script

Claude Code custom commands are markdown prompt files, not shell scripts. The agent interprets the instructions and uses its tool-calling capabilities (shell execution, file reading) to carry out the steps. This means:

- File validation logic is performed by the agent using shell commands (`stat`, `file`, `head -c 8192 | tr -d '\0'`, `wc -l`), not by custom code.
- The agent handles error cases by reading command output and deciding what to report.
- No build step or compilation is needed for the command itself.

This is the simplest possible architecture. It requires no npm packages, no compilation, and no server beyond the existing Vite dev server that the developer would use anyway during development.

### Limitations

- Only works with Claude Code (other AI agents have different command mechanisms).
- Depends on the Vite dev server, which binds to a fixed port (5173 by default).
- The agent performs the validation, so exact error message formatting depends on the prompt instructions rather than deterministic code.

---

## Launcher Shell Script

> Implements: `FR-sc-launcher-script`, `AC-sc-single-tool-call`, `AC-sc-warm-launch-2s`, `AC-sc-cold-launch-8s`

### Problem: Agent Overhead Dominates Launch Time

The original architecture had the Claude Code agent interpret the `shepherd.md` prompt step-by-step. Each step (resolve path, validate file, check server, start server, URL-encode, open browser) required a separate AI inference round-trip and tool call. While the shell operations themselves take ~255ms total, the agent overhead adds multiple seconds of AI inference time per step.

### Solution: Single Shell Script Invocation

A shell script at `scripts/shepherd-launch.sh` encapsulates all launch logic. The slash command file (`.claude/commands/shepherd.md`) invokes this single script, reducing the agent's role to one tool call: `bash scripts/shepherd-launch.sh <filepath>`.

### File: `scripts/shepherd-launch.sh`

#### Interface

```bash
shepherd-launch.sh <filepath>
```

- **Input**: A file path (relative or absolute).
- **Stdout**: A one-line summary on success (e.g., `Opened CRPG at http://localhost:5173 — loaded utils.ts (142 lines) (reusing server)`).
- **Stderr**: Error messages and warnings (e.g., large file warning).
- **Exit codes**: 0 on success, 1 on validation error, 2 on server startup failure.

#### Algorithm

1. **Resolve path**: Resolve `$1` to an absolute path using `realpath` (or `readlink -f` on Linux). If the path does not exist, print error to stderr and exit 1.
2. **Validate file**:
   - Check it is not a directory (`-d` test). If it is, print error and exit 1.
   - Check readability (`-r` test). If not readable, print error and exit 1.
   - Binary detection: read first 8,192 bytes and check for null bytes (`head -c 8192 | tr -cd '\0' | wc -c`). If null bytes found, print error and exit 1.
   - Count lines: `wc -l < "$filepath"`. If > 10,000, print warning to stderr (but continue).
3. **Check server**: `curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 http://localhost:5173` — if 200, set `server_reused=true`.
4. **Start server if needed**: If server is not running:
   - Determine the repo root by finding the script's own directory and navigating up.
   - Start `pnpm dev` in the background: `cd "$repo_root/engineering/apps/web" && pnpm dev &>/dev/null &`
   - Poll `http://localhost:5173` every 0.5s for up to 8 seconds. If it never responds, print error to stderr and exit 2.
   - Set `server_reused=false`.
5. **URL-encode the path**: Use a portable shell-based percent-encoding function (encode everything except `[A-Za-z0-9._~/-]`).
6. **Open browser**: Platform-aware:
   - macOS: `open "http://localhost:5173?file=$encoded_path"`
   - Linux: `xdg-open "http://localhost:5173?file=$encoded_path"`
   - Windows (Git Bash/WSL): `cmd.exe /c start "http://localhost:5173?file=$encoded_path"`
7. **Print summary**: Print the one-line summary to stdout with filename, line count, and whether the server was reused.

#### Portability

- Uses only POSIX shell builtins plus `curl`, `head`, `tr`, `wc`, `realpath`/`readlink` — all standard on macOS and Linux.
- No Node.js, Python, or other runtime required for the script itself (Node.js is only needed for the Vite server).
- The `realpath` command is available on macOS 13+ and all modern Linux distros. For older macOS, the script falls back to `cd "$(dirname "$1")" && pwd -P)/$(basename "$1")`.

#### Performance Budget (Shell Execution Only)

These timings cover the script's shell execution. The agent tool call overhead (~500-1500ms) is additional. See the Performance Considerations section for the full end-to-end budget.

| Step | Expected Time |
|---|---|
| Path resolution + validation | ~10ms |
| Server check (warm) | ~50ms |
| URL encoding | ~5ms |
| Browser open | ~200ms |
| **Total warm (shell only)** | **~265ms** |
| Server startup (cold) | ~3-6s |
| **Total cold (shell only)** | **~3-6s** |

The shell execution total (~265ms warm) is well under the 2-second `NFR-sc-launch-speed` target. The remaining budget (~1.7s) accommodates the single agent tool call. End-to-end warm launch: ~760-1760ms; cold launch: ~3.5-7.5s.

---

## Install Script

> Implements: `FR-sc-install`

### File: `scripts/install-command.sh`

A shell script that enables global use of the `/shepherd` command from any Claude Code session, not just when working inside the Shepherd repo.

#### Behavior

1. Determine the absolute path to `.claude/commands/shepherd.md` in the repo (relative to the script's own location).
2. Verify the source file exists. If not, print an error and exit 1.
3. Create the `~/.claude/commands/` directory if it does not exist (`mkdir -p`).
4. Check if `~/.claude/commands/shepherd.md` already exists:
   - If it is already a symlink pointing to the correct target, print "Already installed" and exit 0.
   - If it is a symlink pointing elsewhere or a regular file, print a warning explaining what exists and exit 1. If the `--force` flag is provided, remove the existing file/symlink and continue.
5. Create a symlink: `~/.claude/commands/shepherd.md` -> `<repo>/.claude/commands/shepherd.md`.
6. Print a success message:
   ```
   Installed: ~/.claude/commands/shepherd.md -> <repo>/.claude/commands/shepherd.md

   The /shepherd command is now available globally in Claude Code.
   Updates will propagate automatically when you git pull.
   ```

#### Flags

| Flag | Effect |
|---|---|
| `--force` | Overwrite an existing file or symlink at the target path without prompting |
| `--help` | Print usage and exit |

#### Why a Symlink

A symlink means the global command file is always identical to the repo's version. When the repo updates (via `git pull`), the global command updates too. There is no version drift, no publish step, and no need for the user to re-run the install script after updates.

---

## CRPG Web App Modifications

### URL Parameter Handling in `App.tsx`

> Implements: `FR-sc-auto-load-file`, `AC-sc-launch-happy-path`, `AC-sc-session-clear-on-new-file`

The existing `App` component (at `engineering/apps/web/src/App.tsx`) is modified to check for a `?file=` query parameter on mount.

#### New Hook: `useFileFromUrl`

A custom hook in `src/hooks/useFileFromUrl.ts` encapsulates the URL parameter handling:

```typescript
interface UseFileFromUrlResult {
  /** Whether a file is currently being fetched from the URL parameter. */
  isLoading: boolean;
  /** Error message if the fetch failed, or null. */
  error: string | null;
}
```

Behavior:

1. On mount, read `window.location.search` for a `file` parameter using `URLSearchParams`.
2. If `file` is not present, do nothing (`isLoading: false`, `error: null`).
3. If `file` is present:
   - Set `isLoading: true`.
   - Fetch `GET /api/file?path=<encoded-path>` from the same origin.
   - On success (200): extract the file content (response body as text), the line count from the `X-File-Lines` header, and the language from the `X-File-Language` header. Compute the basename from the path. Call `store.loadFile(content, basename, language)`. This clears any existing session without confirmation (`AC-sc-session-clear-on-new-file`).
   - On error (403/404/415): set `error` to the message from the JSON response body.
   - On network error: set `error` to `"Could not connect to the local server. Try running the shepherd command again."`.
   - After success or error, clear the `?file=` parameter from the URL using `history.replaceState(null, '', window.location.pathname)`. This prevents re-fetching on page refresh, consistent with `NFR-crp-no-data-persistence`.
   - Set `isLoading: false`.

#### Integration in `App.tsx`

The `App` component calls `useFileFromUrl()` and uses the result to modify its render:

- **If `isLoading` is true**: Render the `FileDropZone` in its loading variant (displaying "Loading file...") instead of the normal empty state. This provides immediate visual feedback while the file is being fetched.
- **If `error` is not null and no file is loaded**: Render the `FileDropZone` in its error variant with the error message. The drop zone remains fully functional so the user can manually load a different file.
- **Otherwise**: Normal existing behavior (empty state or file-loaded state).

The hook runs once on mount and does not re-run. Navigation to a new `?file=` URL (from a subsequent `/shepherd` invocation while the tab is still open) triggers a full page load because the browser navigates to a new URL, which remounts the app and re-runs the hook.

### FileDropZone Component -- No Changes Required

The `FileDropZone` component already supports `loading` and `error` variants (implemented per the existing design spec in `design/code-review-prompt.md`). The URL parameter bypass logic lives entirely in `App.tsx` and the `useFileFromUrl` hook. No changes to `FileDropZone` itself are needed.

---

## File-Serving API Endpoint

> Implements: `FR-sc-file-api`, `NFR-sc-localhost-only`

The file API is served at `GET /api/file?path=<url-encoded-absolute-path>` and returns file content as plain text. It is implemented as a Vite plugin for the dev server.

### API Contract

**Request**: `GET /api/file?path=<url-encoded-absolute-path>`

**Response**:

| Status | Condition | Content-Type | Body | Headers |
|---|---|---|---|---|
| 200 | File read successfully | `text/plain; charset=utf-8` | Raw file content | `X-File-Lines: <count>`, `X-File-Language: <language>` |
| 400 | Missing `path` parameter | `application/json` | `{"error": "Missing path parameter"}` | -- |
| 403 | Permission denied | `application/json` | `{"error": "Permission denied: <path>"}` | -- |
| 403 | Non-localhost origin | `application/json` | `{"error": "Forbidden"}` | -- |
| 404 | File not found | `application/json` | `{"error": "File not found: <path>"}` | -- |
| 404 | Path is a directory | `application/json` | `{"error": "Path is a directory, not a file: <path>"}` | -- |
| 415 | Binary file | `application/json` | `{"error": "Binary file not supported: <path>"}` | -- |

### Security Design

> Implements: `NFR-sc-localhost-only`, `NFR-sc-no-telemetry`

1. **Localhost binding**: The Vite dev server binds to `127.0.0.1` by default.

2. **Origin validation**: The `/api/file` endpoint checks the `Origin` header (if present) and the `Host` header. Requests are only accepted if the host references `127.0.0.1` or `localhost`. This mitigates the risk of a malicious web page making cross-origin requests to the local server (the browser would set the `Origin` header to the malicious page's origin, which would not match). This addresses the security concern raised in Open Question 8 of the product spec.

3. **CORS headers**: The endpoint does not set any `Access-Control-Allow-Origin` headers. This means cross-origin `fetch` requests from other pages will be blocked by the browser's same-origin policy. Only the CRPG app (served from the same origin) can call the endpoint.

4. **Path validation**: The endpoint URL-decodes the `path` parameter and performs the following checks before reading the file:
   - The path must be absolute (starts with `/` on Unix, drive letter on Windows). Relative paths are rejected with 400.
   - Symlinks are resolved with `fs.realpath()` before any checks. This prevents symlink-based traversal attacks, although since we serve from localhost the threat model is limited.
   - Standard `fs.stat()` and `fs.access()` checks for existence, type (file vs directory), and readability.

5. **Binary detection**: Same heuristic as the CRPG web app: read the first 8,192 bytes and scan for null bytes (`0x00`). Consistent with `FR-sc-file-validation`.

6. **No outbound network calls**: The server makes zero outbound network requests. No analytics, no update checks, no crash reporting (`NFR-sc-no-telemetry`).

### Language Detection

The API endpoint detects the file's language from its extension to populate the `X-File-Language` response header. This reuses the same extension-to-language mapping logic defined in `engineering/apps/web/src/lib/languageDetect.ts`. The Vite plugin can import the function directly since it runs in the same Node.js process. The language name in the header uses the display name format (e.g., `TypeScript`, `Python`, `Plain Text`) rather than the Shiki ID, matching the design spec's output format (`FR-sc-output-feedback`).

### Vite Plugin Implementation

> Implements: `FR-sc-file-api` (dev mode), `FR-sc-app-serve` (dev mode)

A Vite plugin at `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts` uses the `configureServer` hook to register middleware on the Vite dev server:

```typescript
import type { Plugin } from 'vite';

export function fileApiPlugin(): Plugin {
  return {
    name: 'shepherd-file-api',
    configureServer(server) {
      server.middlewares.use('/api/file', async (req, res) => {
        // Parse query parameter, validate, read file, respond
      });
    },
  };
}
```

This approach:
- Adds zero npm dependencies.
- Uses Node.js built-in `fs` and `path` modules.
- Is registered in `vite.config.ts` alongside the existing React and Tailwind plugins.
- Only runs in dev mode (the plugin's `configureServer` hook is not invoked during `vite build`).

The `vite.config.ts` changes:

```typescript
import { fileApiPlugin } from './src/vite-plugins/fileApiPlugin';

export default defineConfig({
  plugins: [react(), tailwindcss(), fileApiPlugin()],
  // ... existing config
});
```

---

## State Management

### Web App State Changes

The existing Zustand store (`engineering/apps/web/src/store/appStore.ts`) is extended with two new state fields and two new actions for the prompt feedback loop. See `../engineering/code-review-prompt.md` section "Done Action & Prompt Handoff" for full details.

**New state fields:**
- `isSlashCommandMode: boolean` -- set to `true` by `useFileFromUrl` after successful URL file load; reset by `clearSession`.
- `doneState: 'idle' | 'sending' | 'sent'` -- tracks the Done button lifecycle; resets to `'idle'` on comment/preamble changes.

**New actions:**
- `setSlashCommandMode(mode: boolean)` -- called by `useFileFromUrl` hook and `clearSession`.
- `sendPromptToAgent()` -- POSTs generated prompt to `/api/prompt-output` and copies to clipboard in parallel.

The existing `loadFile` action behavior is unchanged -- it still accepts `(content, fileName, language)` and resets all session state, which is exactly what the URL-parameter auto-load needs (`AC-sc-session-clear-on-new-file`). The `useFileFromUrl` hook now additionally calls `store.setSlashCommandMode(true)` after `store.loadFile()`.

### Loading and Error State

The `useFileFromUrl` hook manages its own local state (`isLoading`, `error`) via `useState`. This state is not stored in the Zustand store because:
- It is transient (only relevant during the initial mount).
- It does not affect other components.
- It is cleared once the file is loaded or the error is displayed.

---

## Error Handling

### Web App Errors (API Fetch)

| API Response | User Sees |
|---|---|
| 200 | File loaded normally |
| 403 | FileDropZone error variant: "Permission denied. The file could not be read." |
| 404 | FileDropZone error variant: "File not found. It may have been moved or deleted." |
| 415 | FileDropZone error variant: "This file doesn't appear to be a text file. Only plain-text files are supported." |
| Network error | FileDropZone error variant: "Could not connect to the local server. Try running the shepherd command again." |

In all error cases, the FileDropZone remains functional -- the user can manually load a file via drag-and-drop, upload, or paste.

---

## Prompt Feedback Loop

> Implements: `FR-sc-prompt-receive`, `FR-sc-prompt-output-api`, `FR-sc-prompt-cleanup`, `NFR-sc-watcher-low-overhead`
> See requirements in `../product/slash-command.md`
> See design in `../design/slash-command.md`

This section covers the mechanism by which the CRPG web app sends the completed prompt back to the Claude Code agent. The handoff uses a file-based approach: the web app POSTs the prompt to a Vite dev server endpoint, the server writes it to a well-known file path, and the slash command's file watcher detects and reads the file.

### Prompt Output API Endpoint

A new route handler is added to the existing Vite plugin at `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`.

#### API Contract

**Request**: `POST /api/prompt-output`

| Header | Value |
|---|---|
| `Content-Type` | `text/plain` |

The request body is the generated prompt text (plain text string).

**Response**:

| Status | Condition | Content-Type | Body |
|---|---|---|---|
| 200 | Prompt written successfully | `application/json` | `{"status": "ok"}` |
| 403 | Non-localhost origin | `application/json` | `{"error": "Forbidden"}` |
| 405 | Non-POST method | `application/json` | `{"error": "Method not allowed"}` |
| 500 | File write error | `application/json` | `{"error": "Failed to write prompt output"}` |

#### Implementation

```typescript
server.middlewares.use('/api/prompt-output', async (req, res) => {
  // Only accept POST
  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  // Reuse the same localhost/origin validation as /api/file
  if (!isLocalhostRequest(req)) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Forbidden' }));
    return;
  }

  // Read request body as text (no body-parser dependency)
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  const body = Buffer.concat(chunks).toString('utf-8');

  try {
    const shepherdDir = path.join(os.homedir(), '.shepherd');
    fs.mkdirSync(shepherdDir, { recursive: true });
    const outputPath = path.join(shepherdDir, 'prompt-output.md');
    fs.writeFileSync(outputPath, body, 'utf-8');

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Failed to write prompt output' }));
  }
});
```

Key implementation details:
- **Localhost validation**: Reuses the same `isLocalhostRequest()` function already implemented for the `GET /api/file` endpoint. This function checks the `Origin` and `Host` headers to ensure the request comes from `127.0.0.1` or `localhost` (`AC-sc-prompt-output-api-localhost-only`).
- **No body-parser**: The request body is read via Node.js async iteration on the request stream, avoiding any additional npm dependency.
- **Directory creation**: `fs.mkdirSync(path.join(os.homedir(), '.shepherd'), { recursive: true })` ensures the `~/.shepherd/` directory exists before writing. The `recursive: true` flag is a no-op if the directory already exists.
- **File write**: `fs.writeFileSync(outputPath, body, 'utf-8')` provides an atomic-ish write. For the expected use case (single writer, single reader), this is sufficient.
- **Imports**: Uses `os` (for `homedir()`), `path`, and `fs` -- all Node.js built-ins already used by the existing plugin.

### Claude Code Custom Command Changes

> Modifies: `.claude/commands/shepherd.md`

The existing slash command prompt is extended with three additional steps after the browser-open step. These steps implement the prompt feedback loop (`FR-sc-prompt-receive`, `FR-sc-prompt-cleanup`).

After the existing steps (validate file, start server, open browser, print success), add:

**Step 8: Clean up stale prompt output**

```bash
rm -f ~/.shepherd/prompt-output.md
```

This ensures any stale file from a previous session does not immediately trigger the watcher (`AC-sc-prompt-cleanup-stale`).

**Step 9: Inform the user**

Print a message to the conversation:

> "The file is loaded in the Code Review Prompt Generator. Annotate your code and click Done when you're finished. I'll wait for your prompt."

This sets expectations that the agent is in a waiting state.

**Step 10: Run the file watcher**

A blocking loop that polls for the existence of `~/.shepherd/prompt-output.md`:

```bash
i=0; while [ ! -f ~/.shepherd/prompt-output.md ] && [ $i -lt 1800 ]; do sleep 1; i=$((i+1)); done
if [ -f ~/.shepherd/prompt-output.md ]; then cat ~/.shepherd/prompt-output.md; rm ~/.shepherd/prompt-output.md; else echo "SHEPHERD_TIMEOUT"; fi
```

The agent interprets the output:
- **If the file exists** (loop exited because the file appeared, exit is not `SHEPHERD_TIMEOUT`): The output is the prompt text. The agent reads it and proceeds to execute the code review based on the prompt content (`AC-sc-prompt-received`).
- **If the output is `SHEPHERD_TIMEOUT`** (loop ran for 1800 iterations = 30 minutes): The agent tells the user the session timed out and they can paste the prompt manually from their clipboard (`AC-sc-prompt-watcher-timeout`).
- **If the command fails for another reason**: The agent tells the user to paste the prompt manually.

#### Cross-Platform Watcher Considerations

The watcher script uses only POSIX shell built-ins (`[`, `sleep`, arithmetic expansion) and standard utilities (`cat`, `rm`), ensuring compatibility across platforms:

- **macOS**: Works natively. No dependency on `timeout` (which requires coreutils/Homebrew).
- **Linux**: Works natively.
- **Windows**: The slash command is a markdown prompt, so the Claude Code agent adapts the shell commands to the available shell. On Windows, the file path is `%USERPROFILE%\.shepherd\prompt-output.md` and the agent uses PowerShell equivalents:
  ```powershell
  $i=0; while (-not (Test-Path "$env:USERPROFILE\.shepherd\prompt-output.md") -and $i -lt 1800) { Start-Sleep -Seconds 1; $i++ }
  if (Test-Path "$env:USERPROFILE\.shepherd\prompt-output.md") { Get-Content "$env:USERPROFILE\.shepherd\prompt-output.md"; Remove-Item "$env:USERPROFILE\.shepherd\prompt-output.md" } else { Write-Output "SHEPHERD_TIMEOUT" }
  ```

The portable POSIX version is preferred in the command file since Claude Code primarily runs on macOS and Linux. The agent can adapt for Windows when it detects a Windows environment (`NFR-sc-watcher-low-overhead`).

#### Watcher Performance

The watcher uses 1-second `sleep` intervals. This means:
- **CPU overhead**: Negligible. Each iteration is one `stat` syscall (file existence check) plus a 1-second sleep. No inotify/fswatch dependency.
- **Latency**: Up to 1 second between the file being written and the agent reading it. This is imperceptible to the user who just clicked Done.
- **Memory**: The watcher runs in the agent's shell session. No background processes, no daemons.

### Cross-Platform Browser Opening

> Implements: `AC-sc-standalone-window`

The slash command opens the CRPG in a Chrome/Chromium **app-mode window** (`--app` flag) rather than a regular browser tab. App-mode windows have no address bar, tabs, or browser chrome -- they look and behave like a standalone application. This also enables `window.close()` to work after the Done action (see `../engineering/code-review-prompt.md`), since the browser permits closing windows that were opened programmatically.

The agent detects the platform (via `uname` on Unix or by recognizing the shell environment on Windows) and uses the appropriate fallback chain. Each chain tries Chrome/Chromium variants first, then falls back to the default system browser (which opens a regular tab).

**macOS:**

```bash
URL="http://localhost:5173?file=<encoded-path>"
open -na "Google Chrome" --args --app="$URL" 2>/dev/null || \
open -na "Google Chrome Canary" --args --app="$URL" 2>/dev/null || \
open -na "Chromium" --args --app="$URL" 2>/dev/null || \
open "$URL"
```

**Linux:**

```bash
URL="http://localhost:5173?file=<encoded-path>"
google-chrome --app="$URL" 2>/dev/null || \
chromium-browser --app="$URL" 2>/dev/null || \
chromium --app="$URL" 2>/dev/null || \
xdg-open "$URL"
```

**Windows (PowerShell):**

```powershell
$URL = "http://localhost:5173?file=<encoded-path>"
try { Start-Process chrome -ArgumentList "--app=$URL" -ErrorAction Stop }
catch { Start-Process $URL }
```

**Fallback behavior**: If none of the Chrome/Chromium variants are found, the final command in each chain opens the URL in the system's default browser. In this case, the CRPG opens in a regular browser tab. The `window.close()` auto-close behavior will not work in a regular tab (browsers block it), so the CRPG falls back to showing a toast notification instead (see `AC-crp-done-auto-close`).

### Security

The POST endpoint follows the same security model as the existing `GET /api/file`:
- **Localhost-only**: Origin/Host header validation ensures only requests from `127.0.0.1` or `localhost` are accepted (`AC-sc-prompt-output-api-localhost-only`).
- **No CORS headers**: Cross-origin requests from other pages are blocked by the browser's same-origin policy.
- **No outbound network calls**: The server writes to a local file and responds. No external communication.

The output file is written to `~/.shepherd/prompt-output.md`:
- The `~/.shepherd/` directory is created under the user's home directory, inheriting the home directory's permissions (typically `700` on Unix systems).
- The file is ephemeral -- it is deleted immediately after the agent reads it.
- The file contains only the prompt text that the user explicitly chose to send. No secrets or credentials are written.

---

## Performance Considerations

### Launch Speed (`NFR-sc-launch-speed`)

Target: Browser tab opening under 2 seconds from command invocation (warm launch); under 8 seconds for cold launch.

The launcher script architecture (`FR-sc-launcher-script`) eliminates the dominant source of latency: per-step AI inference overhead. The previous architecture required the agent to make 5-7 sequential tool calls, each with AI inference time. The new architecture requires exactly one tool call (invoking the script).

| Step | Expected Time | Notes |
|---|---|---|
| Agent processes command + invokes script | ~500-1500ms | Single AI inference + tool call |
| Script: file validation | ~10ms | `stat` + read 8 KB + line count |
| Script: server check | ~50ms | HTTP request to localhost:5173 |
| Script: browser open | ~200-600ms | App-mode fallback chain tries Chrome first, then falls back (see [Cross-Platform Browser Opening](#cross-platform-browser-opening)). Each failed attempt adds ~100ms before the next try. |
| **Total warm launch** | **~760-2150ms** | Under 2s budget (typical ~1s) |
| Script: server startup (cold) | ~3-6s | Vite cold start |
| **Total cold launch** | **~3.5-7.5s** | Under 8s budget |

---

## Security Considerations

### File API Threat Model

The file-serving API endpoint reads arbitrary files from the local filesystem. While localhost-only binding (`NFR-sc-localhost-only`) limits the attack surface, the following mitigations are in place:

1. **Same-origin enforcement**: No CORS headers are set. The browser's same-origin policy prevents other web pages from reading the API responses, even if they can make requests to localhost. The `Origin` header check adds defense-in-depth.

2. **No directory listing**: The API only accepts explicit file paths. There is no endpoint for listing directory contents, browsing the filesystem, or discovering files.

3. **Controlled file writing**: The `POST /api/prompt-output` endpoint writes only to a single well-known path (`~/.shepherd/prompt-output.md`). The path is not user-controllable -- there is no path parameter. The existing `GET /api/file` endpoint remains read-only.

4. **Binary file rejection**: Binary files are rejected before their content is transmitted, preventing accidental exposure of binary secrets (e.g., SSH keys in binary format).

### No Telemetry (`NFR-sc-no-telemetry`)

The server makes no outbound network requests. No analytics, no update checks, no crash reporting. All functionality is entirely local.

---

## Testing Strategy

### Vite Plugin Tests

Unit tests for the file API plugin (`fileApiPlugin.ts`) using Vitest:

| Test Case | Coverage |
|---|---|
| Returns 200 with file content for valid path | `FR-sc-file-api` |
| Returns correct `X-File-Lines` and `X-File-Language` headers | `FR-sc-file-api` |
| Returns 400 for missing path parameter | `FR-sc-file-api` |
| Returns 404 for non-existent file | `FR-sc-file-api`, `AC-sc-file-not-found` |
| Returns 404 for directory path | `FR-sc-file-api`, `AC-sc-directory-rejected` |
| Returns 403 for unreadable file | `FR-sc-file-api`, `AC-sc-permission-denied` |
| Returns 415 for binary file | `FR-sc-file-api`, `AC-sc-binary-file-rejected` |
| Rejects non-localhost origin | `NFR-sc-localhost-only` |
| POST /api/prompt-output writes file to ~/.shepherd/ | `FR-sc-prompt-output-api`, `AC-sc-prompt-output-api-success` |
| POST /api/prompt-output creates ~/.shepherd/ directory if missing | `FR-sc-prompt-output-api` |
| POST /api/prompt-output rejects non-localhost origin | `AC-sc-prompt-output-api-localhost-only` |
| POST /api/prompt-output returns 405 for GET requests | `FR-sc-prompt-output-api` |
| POST /api/prompt-output returns 500 on write error | `FR-sc-prompt-output-api` |
| GET /api/file still works after adding prompt-output route (regression) | Regression |

### Web App Integration Tests

Component/integration tests for the `useFileFromUrl` hook and `App.tsx` changes:

| Test Case | Coverage |
|---|---|
| App loads file from `?file=` parameter on mount | `FR-sc-auto-load-file`, `AC-sc-launch-happy-path` |
| App shows loading state while fetching | `FR-sc-auto-load-file` |
| App shows error state on API error | `FR-sc-auto-load-file` |
| App clears `?file=` from URL after load | `NFR-crp-no-data-persistence` |
| Existing session is cleared without confirmation | `AC-sc-session-clear-on-new-file` |
| App works normally when `?file=` is not present | Regression check |
| `isSlashCommandMode` set to true after URL file load | `FR-crp-done-action` |
| `sendPromptToAgent` posts to /api/prompt-output | `FR-crp-prompt-handoff`, `AC-crp-done-sends-prompt` |
| `sendPromptToAgent` copies to clipboard in parallel | `FR-crp-done-action`, `AC-crp-done-sends-prompt` |
| `doneState` transitions: idle -> sending -> sent | `AC-crp-done-confirmation` |
| `doneState` resets to idle on comment change | `FR-crp-done-action` |
| `doneState` resets to idle on preamble change | `FR-crp-done-action` |
| Done button hidden when not in slash command mode | `AC-crp-done-standalone-hidden` |
| Done button disabled when no comments | `AC-crp-done-disabled-no-comments` |
| Fallback to clipboard on POST failure | `AC-crp-done-fallback-clipboard` |

### Launcher Script Tests

Shell-based tests for `scripts/shepherd-launch.sh`:

| Test Case | Coverage |
|---|---|
| Exits 0 and prints summary for valid file (server running) | `FR-sc-launcher-script`, `AC-sc-warm-launch-2s` |
| Exits 1 with error for missing file | `FR-sc-file-validation`, `AC-sc-file-not-found` |
| Exits 1 with error for directory path | `FR-sc-file-validation`, `AC-sc-directory-rejected` |
| Exits 1 with error for binary file | `FR-sc-file-validation`, `AC-sc-binary-file-rejected` |
| Exits 1 with error for unreadable file | `FR-sc-file-validation`, `AC-sc-permission-denied` |
| Prints warning to stderr for files > 10,000 lines | `AC-sc-large-file-warning` |
| Starts server when not running, exits 0 | `FR-sc-app-serve`, `AC-sc-cold-launch-8s` |
| Prints "reusing server" when server already running | `AC-sc-server-reuse` |
| Opens browser with correct URL | `FR-sc-browser-open` |

### End-to-End Tests

Playwright E2E tests that validate the full flow (these test the Vite plugin path and the web app changes):

| Test Case | Coverage |
|---|---|
| Navigate to `?file=<path>` loads file in code viewer | `AC-sc-launch-happy-path`, `FR-sc-auto-load-file` |
| Navigate to `?file=<absolute-path>` works | `AC-sc-absolute-path` |
| Navigate to `?file=<nonexistent>` shows error | `AC-sc-file-not-found` |
| Navigate to `?file=<binary>` shows error | `AC-sc-binary-file-rejected` |
| File loaded via URL clears existing session | `AC-sc-session-clear-on-new-file` |
| Large file loaded via URL shows warning | `AC-sc-large-file-warning` |
| Done button visible when loaded via URL, click sends prompt to /api/prompt-output | `FR-crp-done-action`, `AC-crp-done-sends-prompt`, `FR-crp-prompt-handoff` |
| Done button shows sent confirmation after successful send | `AC-crp-done-confirmation` |
| Done button hidden when file loaded via paste (no URL param) | `AC-crp-done-standalone-hidden` |

---

## Implementation Plan

### Phase 1: Vite File API Plugin + Web App Changes (estimated 2-3 days)

**Goal**: The CRPG web app can auto-load a file from a `?file=` URL parameter when served by the Vite dev server.

1. Create the Vite plugin at `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`. Implement the `GET /api/file` endpoint with all validation (existence, directory, permission, binary, language detection, line count). Register the plugin in `vite.config.ts`.
2. Create the `useFileFromUrl` hook at `engineering/apps/web/src/hooks/useFileFromUrl.ts`. Implement URL parameter reading, API fetching, error handling, and URL cleanup.
3. Modify `App.tsx` to call `useFileFromUrl()` and integrate the loading/error states with the existing layout.
4. Write unit tests for the Vite plugin's file API handler.
5. Write integration tests for the `useFileFromUrl` hook.
6. Write Playwright E2E tests for the `?file=` URL parameter flow.

**Delivers**: A developer can navigate to `http://localhost:5173?file=/path/to/file.ts` and the file loads automatically in the CRPG. All error cases are handled.

**Slug coverage**: `FR-sc-file-api`, `FR-sc-auto-load-file`, `AC-sc-launch-happy-path`, `AC-sc-absolute-path`, `AC-sc-file-not-found`, `AC-sc-binary-file-rejected`, `AC-sc-permission-denied`, `AC-sc-directory-rejected`, `AC-sc-session-clear-on-new-file`, `AC-sc-large-file-warning`, `NFR-sc-localhost-only`.

### Phase 2: Launcher Shell Script (estimated 0.5 day)

**Goal**: All slash command logic (validation, server management, browser open) runs in a single shell invocation.

1. Create `scripts/shepherd-launch.sh` implementing the algorithm defined in the Launcher Shell Script section of this spec.
2. Update `.claude/commands/shepherd.md` to invoke the script instead of instructing the agent to perform each step.
3. Test warm launch (server already running): verify browser opens within 2 seconds.
4. Test cold launch (server not running): verify browser opens within 8 seconds.
5. Test all error cases: missing file, directory, binary file, permission denied, no arguments.

**Delivers**: The `/shepherd` command launches in under 2 seconds (warm) by executing a single shell script instead of multiple agent tool calls.

**Slug coverage**: `FR-sc-launcher-script`, `AC-sc-warm-launch-2s`, `AC-sc-cold-launch-8s`, `AC-sc-single-tool-call`.

### Phase 3: Claude Code Command File + Install Script (estimated 0.5-1 day)

**Goal**: The `/shepherd` command is usable from within any Claude Code session.

1. Create `.claude/commands/shepherd.md` with instructions for the agent to validate the file, start the dev server if needed, and open the browser with the `?file=` parameter.
2. Create `scripts/install-command.sh` with symlink creation, existing file detection, `--force` flag, and success messaging.
3. Test the command manually by typing `/shepherd <filepath>` in a Claude Code session within the repo.
4. Test global install by running `scripts/install-command.sh` and then using `/shepherd` from a Claude Code session outside the repo.
5. Iterate on the prompt instructions to ensure reliable behavior across edge cases (file not found, binary file, no arguments).

**Delivers**: A developer working in the Shepherd repo can type `/shepherd src/utils.ts` in Claude Code and the CRPG opens with the file loaded. After running the install script, the command works globally.

**Slug coverage**: `FR-sc-invoke-command`, `FR-sc-install`, `FR-sc-file-resolution`, `FR-sc-file-validation`, `FR-sc-browser-open`, `FR-sc-output-feedback`, `AC-sc-no-args-usage`, `NFR-sc-launch-speed`.

---

## Project Structure

New and modified files across the monorepo:

```
shepherd/                                 (project root)
  .claude/
    commands/
      shepherd.md                         NEW -- Claude Code custom slash command (includes watcher steps)

  scripts/
    install-command.sh                    NEW -- symlink installer for global use
    shepherd-launch.sh                    NEW -- all-in-one launch script (validation, server, browser)

  engineering/
    slash-command.md                       NEW -- this spec
    apps/
      web/                                EXISTING -- CRPG web app
        vite.config.ts                    MODIFIED -- add fileApiPlugin
        src/
          App.tsx                          MODIFIED -- integrate useFileFromUrl hook
          store/
            appStore.ts                   MODIFIED -- add isSlashCommandMode, doneState, sendPromptToAgent
          components/
            Toolbar.tsx                   MODIFIED -- add Done button (conditional, state-driven)
          hooks/
            useFileFromUrl.ts             NEW -- URL parameter handling hook (sets slash command mode)
          vite-plugins/
            fileApiPlugin.ts              NEW -- Vite dev server file API plugin (GET /api/file + POST /api/prompt-output)
```

---

## Requirement Traceability

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-sc-invoke-command` | Claude Code command file (`.claude/commands/shepherd.md`); argument validation in prompt instructions |
| `FR-sc-file-resolution` | Claude Code command file (agent resolves paths via shell commands) |
| `FR-sc-file-validation` | Claude Code command file (agent validates via shell commands: `stat`, `file`, `head`, `wc`); Vite plugin `fileApiPlugin.ts` (server-side validation) |
| `FR-sc-app-serve` | Vite dev server started by Claude Code command if not already running |
| `FR-sc-browser-open` | Claude Code command file (agent runs `open` command via shell) |
| `FR-sc-auto-load-file` | `useFileFromUrl` hook (`apps/web/src/hooks/useFileFromUrl.ts`); `App.tsx` modifications; store `loadFile` action |
| `FR-sc-file-api` | Vite plugin (`fileApiPlugin.ts`); API contract defined in this spec |
| `FR-sc-install` | Claude Code project-level commands (automatic for in-repo); `scripts/install-command.sh` (symlink for global use) |
| `FR-sc-output-feedback` | Claude Code command file (prompt instructs agent to print output with URL, file info, and line count) |
| `FR-sc-prompt-receive` | Claude Code command file (`.claude/commands/shepherd.md`) -- file watcher loop polls for `~/.shepherd/prompt-output.md`, reads and deletes on detection |
| `FR-sc-prompt-output-api` | Vite plugin (`fileApiPlugin.ts`) -- `POST /api/prompt-output` endpoint; writes request body to `~/.shepherd/prompt-output.md` |
| `FR-sc-prompt-cleanup` | Claude Code command file -- `rm -f ~/.shepherd/prompt-output.md` before starting watcher |
| `FR-sc-launcher-script` | Shell script (`scripts/shepherd-launch.sh`); invoked by `.claude/commands/shepherd.md` |

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-sc-launch-speed` | Vite dev server typically already running; file validation and browser open are sub-second. Performance budget analysis in this spec. |
| `NFR-sc-localhost-only` | Vite dev server binds to `127.0.0.1` by default; origin validation in file API plugin |
| `NFR-sc-no-telemetry` | No outbound network requests in any component |
| `NFR-sc-watcher-low-overhead` | File watcher uses 1-second `sleep` polling loop; single `stat` syscall per iteration; no inotify/fswatch dependency; no background daemon |

### Acceptance Criteria

| Slug | Engineering Coverage |
|---|---|
| `AC-sc-launch-happy-path` | `useFileFromUrl` hook; Vite plugin file API; `App.tsx` integration; E2E test |
| `AC-sc-absolute-path` | `useFileFromUrl` hook (path is always absolute in the URL parameter); file API accepts absolute paths only |
| `AC-sc-file-not-found` | Vite plugin `fileApiPlugin.ts` (404 response); `useFileFromUrl` error handling |
| `AC-sc-binary-file-rejected` | Vite plugin `fileApiPlugin.ts` (415 response); `useFileFromUrl` error handling |
| `AC-sc-permission-denied` | Vite plugin `fileApiPlugin.ts` (403 response); `useFileFromUrl` error handling |
| `AC-sc-directory-rejected` | Vite plugin `fileApiPlugin.ts` (404 with directory message); `useFileFromUrl` error handling |
| `AC-sc-no-args-usage` | Claude Code command file (prompt handles no-args case) |
| `AC-sc-large-file-warning` | Claude Code command file (agent warns when lines > 10,000); web app shows large file warning banner (existing behavior in `CodeViewer`) |
| `AC-sc-session-clear-on-new-file` | `useFileFromUrl` hook calls `store.loadFile()` which resets all state; no confirmation dialog |
| `AC-sc-prompt-received` | Claude Code command file watcher detects `~/.shepherd/prompt-output.md`, reads contents, deletes file, agent proceeds with prompt |
| `AC-sc-prompt-watcher-timeout` | Claude Code command file watcher loop exits after 1800 iterations (30 minutes), agent prints timeout message |
| `AC-sc-prompt-cleanup-stale` | Claude Code command file runs `rm -f ~/.shepherd/prompt-output.md` before starting watcher |
| `AC-sc-prompt-output-api-success` | Vite plugin `POST /api/prompt-output` returns 200 and writes body to `~/.shepherd/prompt-output.md` |
| `AC-sc-standalone-window` | Claude Code command file (`.claude/commands/shepherd.md`) -- platform-specific Chrome/Chromium app-mode fallback chain opens CRPG in a standalone window; falls back to default browser if Chrome unavailable |
| `AC-sc-prompt-output-api-localhost-only` | Vite plugin `POST /api/prompt-output` returns 403 for non-localhost requests (reuses `isLocalhostRequest()` from `GET /api/file`) |
| `AC-sc-warm-launch-2s` | Launcher script warm path (~265ms shell time); single agent tool call budget (~1.7s) |
| `AC-sc-cold-launch-8s` | Launcher script cold path (server startup ~3-6s + validation + browser open) |
| `AC-sc-single-tool-call` | `.claude/commands/shepherd.md` delegates to single `scripts/shepherd-launch.sh` invocation |
