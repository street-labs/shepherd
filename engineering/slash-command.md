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

1. Validate that `$ARGUMENTS` is provided. If empty, print usage instructions and stop (`AC-sc-no-args-usage`).
2. Resolve the file path relative to the current working directory (`FR-sc-file-resolution`).
3. Validate the file: check existence, check it is not a directory, check readability, check for binary content (first 8,192 bytes for null bytes), count lines (`FR-sc-file-validation`, `AC-sc-file-not-found`, `AC-sc-binary-file-rejected`, `AC-sc-permission-denied`, `AC-sc-directory-rejected`).
4. If lines > 10,000, warn about potential performance degradation (`AC-sc-large-file-warning`).
5. Check if the Vite dev server is already running by looking for a process listening on port 5173 (or by checking if `http://localhost:5173` responds). If not running, start it with `cd engineering/apps/web && pnpm dev` in the background (`FR-sc-app-serve`).
6. Open the default browser to `http://localhost:5173?file=<url-encoded-absolute-path>` (`FR-sc-browser-open`).
7. Print the success message with the URL and file info to the conversation (`FR-sc-output-feedback`).

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

The existing Zustand store (`engineering/apps/web/src/store/appStore.ts`) requires no changes. The `loadFile` action already accepts `(content, fileName, language)` and resets all session state, which is exactly what the URL-parameter auto-load needs (`AC-sc-session-clear-on-new-file`).

The `useFileFromUrl` hook calls `store.loadFile()` on successful API fetch. This:
- Sets the file content, name, and language.
- Clears all comments, preamble, and generated prompt.
- Resets the UI state (editor closed, no focused comment, no selection).

No new store actions are needed. The hook is a consumer of the existing store API.

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

## Performance Considerations

### Launch Speed (`NFR-sc-launch-speed`)

Target: Browser tab opening under 3 seconds from command invocation.

For the Claude Code custom command, the agent overhead adds time for command interpretation and shell execution, but the actual operations (file validation, server check, browser open) are fast:

| Step | Expected Time | Notes |
|---|---|---|
| File validation | ~5ms | Single `stat` + read 8 KB + line count |
| Dev server check | ~50ms | HTTP request to localhost:5173 |
| Browser open | ~200ms | Shell command to open URL |
| **Total (server already running)** | **~255ms** | Well under 3s budget |

If the Vite dev server is not already running, startup adds several seconds (Vite cold start). However, this is a one-time cost per development session, and the developer would typically already have the dev server running.

---

## Security Considerations

### File API Threat Model

The file-serving API endpoint reads arbitrary files from the local filesystem. While localhost-only binding (`NFR-sc-localhost-only`) limits the attack surface, the following mitigations are in place:

1. **Same-origin enforcement**: No CORS headers are set. The browser's same-origin policy prevents other web pages from reading the API responses, even if they can make requests to localhost. The `Origin` header check adds defense-in-depth.

2. **No directory listing**: The API only accepts explicit file paths. There is no endpoint for listing directory contents, browsing the filesystem, or discovering files.

3. **No file writing**: The API is read-only. There are no write, delete, or modify endpoints.

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

### Phase 2: Claude Code Command File + Install Script (estimated 0.5-1 day)

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
      shepherd.md                         NEW -- Claude Code custom slash command

  scripts/
    install-command.sh                    NEW -- symlink installer for global use

  engineering/
    slash-command.md                       NEW -- this spec
    apps/
      web/                                EXISTING -- CRPG web app
        vite.config.ts                    MODIFIED -- add fileApiPlugin
        src/
          App.tsx                          MODIFIED -- integrate useFileFromUrl hook
          hooks/
            useFileFromUrl.ts             NEW -- URL parameter handling hook
          vite-plugins/
            fileApiPlugin.ts              NEW -- Vite dev server file API plugin
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

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-sc-launch-speed` | Vite dev server typically already running; file validation and browser open are sub-second. Performance budget analysis in this spec. |
| `NFR-sc-localhost-only` | Vite dev server binds to `127.0.0.1` by default; origin validation in file API plugin |
| `NFR-sc-no-telemetry` | No outbound network requests in any component |

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
