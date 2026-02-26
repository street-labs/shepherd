# Slash Command Launcher -- Test Plan

> Based on requirements in `../../product/slash-command.md`
> Based on design in `../../design/web/slash-command.md`
> Based on technical spec in `../../engineering/web/slash-command.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sc-launch-happy-path` | `TC-sc-launch-happy-inrepo` | Not started |
| `AC-sc-absolute-path` | `TC-sc-absolute-path-inrepo` | Not started |
| `AC-sc-file-not-found` | `TC-sc-file-not-found-cli` | Not started |
| `AC-sc-binary-file-rejected` | `TC-sc-binary-rejected-cli` | Not started |
| `AC-sc-permission-denied` | `TC-sc-permission-denied-cli` | Not started |
| `AC-sc-directory-rejected` | `TC-sc-directory-rejected-cli` | Not started |
| `AC-sc-no-args-usage` | `TC-sc-no-args-usage`, `TC-sc-help-flag` | Not started |
| `AC-sc-large-file-warning` | `TC-sc-large-file-warning-cli`, `TC-sc-large-file-warning-e2e` | Not started |
| `AC-sc-server-reuse` | `TC-sc-server-reuse-vite` | Not started |
| `AC-sc-install-symlink` | `TC-sc-install-symlink`, `TC-sc-install-update-propagation` | Not started |
| `AC-sc-session-clear-on-new-file` | `TC-sc-session-clear-on-new-file` | Not started |
| `AC-sc-cross-platform-open` | `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows` | Not started |
| `AC-sc-standalone-window` | `TC-sc-app-window-chrome`, `TC-sc-app-window-chromium-fallback`, `TC-sc-app-window-browser-fallback`, `TC-sc-app-window-subsequent` | Not started |
| `FR-sc-invoke-command` | `TC-sc-launch-happy-inrepo`, `TC-sc-no-args-usage` | Not started |
| `FR-sc-file-resolution` | `TC-sc-absolute-path-inrepo`, `TC-sc-resolve-relative-path`, `TC-sc-resolve-symlink` | Not started |
| `FR-sc-file-validation` | `TC-sc-file-not-found-cli`, `TC-sc-binary-rejected-cli`, `TC-sc-permission-denied-cli`, `TC-sc-directory-rejected-cli`, `TC-sc-large-file-warning-cli` | Not started |
| `FR-sc-app-serve` | `TC-sc-server-starts-vite`, `TC-sc-server-serves-static-assets` | Not started |
| `FR-sc-browser-open` | `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-app-window-chrome`, `TC-sc-app-window-browser-fallback` | Not started |
| `FR-sc-auto-load-file` | `TC-sc-auto-load-from-url-param`, `TC-sc-auto-load-clears-url-param`, `TC-sc-auto-load-error-state`, `TC-sc-auto-load-no-param` | Not started |
| `FR-sc-file-api` | `TC-sc-api-200-valid-file`, `TC-sc-api-400-missing-param`, `TC-sc-api-403-permission`, `TC-sc-api-403-non-localhost`, `TC-sc-api-404-not-found`, `TC-sc-api-404-directory`, `TC-sc-api-415-binary`, `TC-sc-api-headers` | Not started |
| `FR-sc-install` | `TC-sc-install-symlink`, `TC-sc-install-update-propagation`, `TC-sc-install-claude-code-command` | Not started |
| `FR-sc-output-feedback` | `TC-sc-output-success-format`, `TC-sc-output-reuse-note`, `TC-sc-output-errors-stderr` | Not started |
| `AC-sc-warm-launch-2s` | `TC-sc-launcher-warm-launch` | Not started |
| `AC-sc-cold-launch-8s` | `TC-sc-launcher-cold-launch` | Not started |
| `AC-sc-single-tool-call` | `TC-sc-single-tool-call` | Not started |
| `FR-sc-launcher-script` | `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch`, `TC-sc-single-tool-call`, `TC-sc-launcher-script-validation`, `TC-sc-launcher-server-start` | Not started |
| `NFR-sc-launch-speed` | `TC-sc-launch-speed-cold`, `TC-sc-launch-speed-warm`, `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch` | Not started |
| `NFR-sc-no-global-deps` | `TC-sc-install-symlink` | Not started |
| `NFR-sc-cross-platform` | `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-path-handling-windows` | Not started |
| `NFR-sc-localhost-only` | `TC-sc-api-403-non-localhost` | Not started |
| `NFR-sc-no-telemetry` | `TC-sc-no-outbound-network` | Not started |
| `NFR-sc-minimal-footprint` | `TC-sc-install-symlink` | Not started |
| `FR-sc-prompt-receive` | `TC-sc-watcher-detects-file`, `TC-sc-watcher-deletes-after-read`, `TC-sc-feedback-loop-e2e`, `TC-sc-feedback-loop-resend` | Not started |
| `FR-sc-prompt-output-api` | `TC-sc-prompt-api-write-happy`, `TC-sc-prompt-api-creates-dir`, `TC-sc-prompt-api-overwrites`, `TC-sc-prompt-api-method-check`, `TC-sc-prompt-api-no-collision`, `TC-sc-feedback-loop-e2e` | Not started |
| `FR-sc-prompt-cleanup` | `TC-sc-watcher-cleanup-stale` | Not started |
| `NFR-sc-watcher-low-overhead` | `TC-sc-watcher-timeout` | Not started |
| `AC-sc-prompt-received` | `TC-sc-watcher-detects-file`, `TC-sc-feedback-loop-e2e` | Not started |
| `AC-sc-prompt-watcher-timeout` | `TC-sc-watcher-timeout` | Not started |
| `AC-sc-prompt-cleanup-stale` | `TC-sc-watcher-cleanup-stale` | Not started |
| `AC-sc-prompt-output-api-success` | `TC-sc-prompt-api-write-happy` | Not started |
| `AC-sc-prompt-output-api-localhost-only` | `TC-sc-prompt-api-localhost-only` | Not started |
| `FR-sc-session-id` | `TC-sc-session-id-generated`, `TC-sc-session-id-unique` | Not started |
| `FR-sc-dynamic-port` | `TC-sc-dynamic-port`, `TC-sc-separate-servers-different-worktrees` | Not started |
| `FR-sc-session-scoped-output` | `TC-sc-session-scoped-output-path`, `TC-sc-session-output-isolation`, `TC-sc-prompt-api-write-happy` | Not started |
| `FR-sc-concurrent-windows` | `TC-sc-concurrent-sessions-happy` | Not started |
| `FR-sc-session-cleanup` | `TC-sc-session-cleanup-after-read`, `TC-sc-watcher-cleanup-stale` | Not started |
| `FR-crp-session-identity` | `TC-sc-window-title-shows-project` | Not started |
| `AC-sc-concurrent-sessions` | `TC-sc-concurrent-sessions-happy` | Not started |
| `AC-sc-session-output-isolation` | `TC-sc-session-output-isolation` | Not started |
| `AC-sc-server-reuse` | `TC-sc-server-reuse-same-worktree`, `TC-sc-server-reuse-vite` | Not started |

---

## Test Cases

---

### Command Invocation and Output

---

#### `TC-sc-launch-happy-inrepo`: Launch CRPG with a file via custom command

- **Type**: E2E
- **Covers**: `AC-sc-launch-happy-path`, `FR-sc-invoke-command`, `FR-sc-browser-open`, `FR-sc-auto-load-file`
- **Preconditions**: The Shepherd repository is cloned. The Vite dev server is running (`pnpm dev` in `engineering/apps/web/`). A file `engineering/apps/web/src/App.tsx` exists.
- **Steps**:
  1. Open a Claude Code session inside the Shepherd repository.
  2. Type `/shepherd engineering/apps/web/src/App.tsx`.
  3. Observe the agent conversation output.
  4. Observe the browser.
- **Expected Result**: The agent reports a session ID derived from the project directory (e.g., `Session: shepherd-1`) and a URL (`http://localhost:<port>?session=<id>&file=<encoded-path>`) where `<port>` is a dynamically assigned port. The default browser opens to the CRPG with `App.tsx` loaded in the code viewer. Syntax highlighting shows TypeScript. The file name "App.tsx" is displayed in the file header.
- **Edge Cases**:
  - Vite dev server not running when command is invoked: the agent should start it (per the custom command instructions).
  - The file path contains the repo-relative path; the agent resolves it to an absolute path before constructing the URL.

---

#### `TC-sc-no-args-usage`: No arguments shows usage message

- **Type**: Unit
- **Covers**: `AC-sc-no-args-usage`, `FR-sc-invoke-command`, `FR-sc-output-feedback`
- **Preconditions**: The `/shepherd` custom command is available in Claude Code.
- **Steps**:
  1. Type `/shepherd` with no arguments in Claude Code.
  2. Observe the agent output.
- **Expected Result**: The agent reports the usage message:
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
  The browser is not opened.
- **Edge Cases**:
  - Running with only whitespace arguments (e.g., `/shepherd ""`): should be treated as a missing or invalid file path, not as no-args.

---

#### `TC-sc-help-flag`: `--help` shows usage message

- **Type**: Unit
- **Covers**: `AC-sc-no-args-usage`, `FR-sc-invoke-command`
- **Preconditions**: The `/shepherd` custom command is available.
- **Steps**:
  1. Type `/shepherd --help` in Claude Code.
  2. Observe the agent output.
- **Expected Result**: The agent reports the same usage message as `TC-sc-no-args-usage`.
- **Edge Cases**:
  - `/shepherd --help somefile.ts`: `--help` flag should take priority and show usage, not attempt to load the file.

---

#### `TC-sc-output-success-format`: Success output format matches spec

- **Type**: Integration
- **Covers**: `FR-sc-output-feedback`, `AC-sc-launch-happy-path`
- **Preconditions**: The Vite dev server is running. A file `main.py` (50 lines, Python) exists.
- **Steps**:
  1. Type `/shepherd main.py` in Claude Code.
  2. Parse the agent output.
- **Expected Result**: Line 1 matches the pattern `Opened Code Review Prompt Generator at http://localhost:<port>` where `<port>` is a numeric value. Line 2 matches `Loaded: main.py (50 lines, Python)`. All output is plain text.
- **Edge Cases**:
  - File with an unknown extension (e.g., `data.xyz`): line 2 should show `Plain Text` as the language.
  - File with zero lines (empty file): should show `(0 lines, <language>)`.

---

#### `TC-sc-output-reuse-note`: Server reuse is seamless on subsequent invocations

- **Type**: Integration
- **Covers**: `FR-sc-output-feedback`, `AC-sc-server-reuse`
- **Preconditions**: The Vite dev server is already running from a previous invocation or manual start.
- **Steps**:
  1. Type `/shepherd file2.ts` in Claude Code.
  2. Observe the agent output.
- **Expected Result**: The agent reports success. The Vite dev server is reused (no new server started). The output shows the URL and file info.
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-sc-output-errors-stderr`: All error messages are reported correctly

- **Type**: Unit
- **Covers**: `FR-sc-output-feedback`, `FR-sc-file-validation`
- **Preconditions**: The `/shepherd` custom command is available.
- **Steps**:
  1. Type `/shepherd nonexistent.js`. Observe the agent output.
  2. Type `/shepherd image.png` (binary file). Observe the agent output.
  3. Type `/shepherd src/` (directory). Observe the agent output.
- **Expected Result**: In all three cases, the agent reports an error message starting with `Error:`. The browser is not opened.
- **Edge Cases**:
  - N/A (focused test).

---

### File Resolution

---

#### `TC-sc-resolve-relative-path`: Relative path is resolved against CWD

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`
- **Preconditions**: A file exists at `/Users/dev/project/src/utils.ts`. The current working directory is `/Users/dev/project`.
- **Steps**:
  1. Type `/shepherd src/utils.ts` from the `/Users/dev/project` context.
  2. Observe the URL opened in the browser.
- **Expected Result**: The `?file=` query parameter in the browser URL contains the absolute path `/Users/dev/project/src/utils.ts` (URL-encoded). The success message shows the relative path `src/utils.ts` (the path the user typed).
- **Edge Cases**:
  - Path with `..` components (e.g., `/shepherd ../other-project/file.ts`): should resolve correctly.
  - Path with `.` component (e.g., `/shepherd ./src/utils.ts`): should resolve to the same path as `src/utils.ts`.

---

#### `TC-sc-absolute-path-inrepo`: Absolute path accepted

- **Type**: E2E
- **Covers**: `AC-sc-absolute-path`, `FR-sc-file-resolution`
- **Preconditions**: The Vite dev server is running. A file exists at `/Users/dev/project/main.py`.
- **Steps**:
  1. Type `/shepherd /Users/dev/project/main.py` from any working directory within the Shepherd repo.
  2. Observe the browser.
- **Expected Result**: The CRPG opens with `main.py` loaded, regardless of the current working directory. The file name "main.py" is displayed.
- **Edge Cases**:
  - Absolute path pointing to a file outside the Shepherd repo: should work (the file API reads from the local filesystem, not restricted to the repo).

---

#### `TC-sc-resolve-symlink`: Symlinks are resolved to their target

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`
- **Preconditions**: A symlink `link.ts` exists that points to `/Users/dev/project/src/real-file.ts`.
- **Steps**:
  1. Type `/shepherd link.ts`.
  2. Observe the `?file=` parameter in the browser URL.
- **Expected Result**: The `?file=` parameter contains the resolved real path `/Users/dev/project/src/real-file.ts`, not the symlink path. The file loads correctly in the CRPG.
- **Edge Cases**:
  - Dangling symlink (target does not exist): should produce "File not found" error with the resolved path.
  - Symlink chain (symlink -> symlink -> file): should resolve to the final target.
  - Circular symlinks: should produce a meaningful error rather than hanging or crashing.

---

### File Validation

---

#### `TC-sc-file-not-found-cli`: Missing file produces an error

- **Type**: Unit
- **Covers**: `AC-sc-file-not-found`, `FR-sc-file-validation`
- **Preconditions**: No file named `nonexistent.js` exists in the current directory.
- **Steps**:
  1. Type `/shepherd nonexistent.js` from a directory where the file does not exist.
  2. Observe the agent output.
- **Expected Result**: The agent reports `Error: File not found: /absolute/resolved/path/to/nonexistent.js`. The browser is not opened. No server is started.
- **Edge Cases**:
  - File that existed moments ago but was deleted between command invocation and validation: should produce "File not found" error.

---

#### `TC-sc-binary-rejected-cli`: Binary file is rejected

- **Type**: Unit
- **Covers**: `AC-sc-binary-file-rejected`, `FR-sc-file-validation`
- **Preconditions**: A binary file `image.png` exists in the current directory.
- **Steps**:
  1. Type `/shepherd image.png`.
  2. Observe the agent output.
- **Expected Result**: The agent reports `Error: Binary file not supported: /absolute/resolved/path/to/image.png`. The browser is not opened.
- **Edge Cases**:
  - A file that is technically binary but has a text extension (e.g., `data.txt` containing null bytes): should still be rejected.
  - A file whose first 8,192 bytes are all text but has null bytes after byte 8,192: should NOT be rejected (binary detection only scans the first 8,192 bytes per `FR-sc-file-validation`).
  - An empty file (0 bytes): no null bytes to detect, so it should be treated as text and allowed through.

---

#### `TC-sc-permission-denied-cli`: Unreadable file produces an error

- **Type**: Unit
- **Covers**: `AC-sc-permission-denied`, `FR-sc-file-validation`
- **Preconditions**: A file `secret.txt` exists but has permissions set to `000` (not readable by the current user). This test requires running on Unix (macOS/Linux) where file permissions are supported.
- **Steps**:
  1. Run `chmod 000 secret.txt` to make the file unreadable.
  2. Type `/shepherd secret.txt`.
  3. Observe the agent output.
  4. Restore permissions: `chmod 644 secret.txt`.
- **Expected Result**: The agent reports `Error: Permission denied: /absolute/resolved/path/to/secret.txt`.
- **Edge Cases**:
  - File owned by root with no read permission for the current user: same error.
  - On Windows, file permission semantics differ; this test may need platform-specific adaptation.

---

#### `TC-sc-directory-rejected-cli`: Directory is rejected

- **Type**: Unit
- **Covers**: `AC-sc-directory-rejected`, `FR-sc-file-validation`
- **Preconditions**: A directory `src/` exists in the current working directory.
- **Steps**:
  1. Type `/shepherd src/`.
  2. Observe the agent output.
- **Expected Result**: The agent reports `Error: Path is a directory, not a file: /absolute/resolved/path/to/src/`.
- **Edge Cases**:
  - `/shepherd src` (without trailing slash): should still detect as directory and reject.
  - `/shepherd .` (current directory): should be rejected as a directory.

---

#### `TC-sc-large-file-warning-cli`: Large file shows warning but proceeds

- **Type**: Integration
- **Covers**: `AC-sc-large-file-warning`, `FR-sc-file-validation`
- **Preconditions**: A text file `large-file.ts` with 15,000 lines exists.
- **Steps**:
  1. Type `/shepherd large-file.ts`.
  2. Observe the agent output.
- **Expected Result**: The agent reports `Warning: large-file.ts has 15000 lines. Performance may be degraded for very large files.` followed by the normal success output: the URL line and `Loaded: large-file.ts (15000 lines, TypeScript)`. The browser opens.
- **Edge Cases**:
  - File with exactly 10,000 lines: no warning (threshold is "exceeds 10,000").
  - File with 10,001 lines: warning appears.
  - File with 100,000 lines: warning appears but command still proceeds.

---

### File-Serving API Endpoint

---

#### `TC-sc-api-200-valid-file`: API returns 200 with file content for valid path

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `AC-sc-launch-happy-path`
- **Preconditions**: A text file exists at a known absolute path with content `const x = 1;\n`. The Vite dev server is running.
- **Steps**:
  1. Send `GET /api/file?path=<url-encoded-absolute-path>` from localhost.
  2. Inspect the response.
- **Expected Result**: Status is 200. `Content-Type` is `text/plain; charset=utf-8`. Body is the raw file content (`const x = 1;\n`). `X-File-Lines` header is present with value `1`. `X-File-Language` header is present with the detected language (e.g., `TypeScript` for a `.ts` file).
- **Edge Cases**:
  - File with BOM (byte order mark): BOM should be included in the response as-is.
  - File with mixed line endings (`\r\n` and `\n`): content returned as-is; line count based on `\n`.
  - Very large file (>1 MB): should still return 200 with full content.

---

#### `TC-sc-api-400-missing-param`: API returns 400 for missing path parameter

- **Type**: Unit
- **Covers**: `FR-sc-file-api`
- **Preconditions**: The Vite dev server is running.
- **Steps**:
  1. Send `GET /api/file` (no query parameters).
  2. Inspect the response.
- **Expected Result**: Status is 400. `Content-Type` is `application/json`. Body is `{"error": "Missing path parameter"}`.
- **Edge Cases**:
  - `GET /api/file?path=` (empty path value): should return 400.
  - `GET /api/file?path=%20` (whitespace-only path): should return 404 (path does not exist after trimming).

---

#### `TC-sc-api-403-permission`: API returns 403 for unreadable file

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `AC-sc-permission-denied`
- **Preconditions**: A file exists at an absolute path but is not readable by the server process (`chmod 000`).
- **Steps**:
  1. Send `GET /api/file?path=<url-encoded-path>` from localhost.
  2. Inspect the response.
- **Expected Result**: Status is 403. Body is `{"error": "Permission denied: <path>"}` as `application/json`.
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-sc-api-403-non-localhost`: API rejects requests from non-localhost origin

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `NFR-sc-localhost-only`
- **Preconditions**: The Vite dev server is running. A valid file path exists.
- **Steps**:
  1. Send `GET /api/file?path=<url-encoded-path>` with an `Origin` header set to `http://evil.com`.
  2. Inspect the response.
- **Expected Result**: Status is 403. Body is `{"error": "Forbidden"}` as `application/json`. The file content is not returned.
- **Edge Cases**:
  - `Origin: http://localhost:9999` (different port but still localhost): should be accepted.
  - `Origin: http://127.0.0.1:<port>` (IP address form): should be accepted.
  - No `Origin` header (same-origin request from the served app): should be accepted.
  - `Origin: http://localhost.evil.com`: should be rejected (substring match is not sufficient; must be exact `localhost` or `127.0.0.1`).

---

#### `TC-sc-api-404-not-found`: API returns 404 for non-existent file

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `AC-sc-file-not-found`
- **Preconditions**: The Vite dev server is running. No file exists at `/tmp/nonexistent-test-file.ts`.
- **Steps**:
  1. Send `GET /api/file?path=%2Ftmp%2Fnonexistent-test-file.ts` from localhost.
  2. Inspect the response.
- **Expected Result**: Status is 404. Body is `{"error": "File not found: /tmp/nonexistent-test-file.ts"}` as `application/json`.
- **Edge Cases**:
  - Path with Unicode characters that does not exist: should return 404 with the Unicode path in the error message.

---

#### `TC-sc-api-404-directory`: API returns 404 for directory path

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `AC-sc-directory-rejected`
- **Preconditions**: The Vite dev server is running. The directory `/tmp` exists.
- **Steps**:
  1. Send `GET /api/file?path=%2Ftmp` from localhost.
  2. Inspect the response.
- **Expected Result**: Status is 404. Body is `{"error": "Path is a directory, not a file: /tmp"}` as `application/json`.
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-sc-api-415-binary`: API returns 415 for binary file

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `AC-sc-binary-file-rejected`
- **Preconditions**: The Vite dev server is running. A binary file (e.g., a PNG) exists at a known absolute path.
- **Steps**:
  1. Send `GET /api/file?path=<url-encoded-path-to-png>` from localhost.
  2. Inspect the response.
- **Expected Result**: Status is 415. Body is `{"error": "Binary file not supported: <path>"}` as `application/json`.
- **Edge Cases**:
  - A `.wasm` file: should be detected as binary (contains null bytes).
  - An ELF or Mach-O executable: should be detected as binary.

---

#### `TC-sc-api-headers`: API returns correct metadata headers

- **Type**: Unit
- **Covers**: `FR-sc-file-api`
- **Preconditions**: A TypeScript file with 42 lines exists.
- **Steps**:
  1. Send a valid `GET /api/file?path=<path>` request for the TypeScript file.
  2. Inspect the response headers.
- **Expected Result**: `X-File-Lines` header is `42`. `X-File-Language` header is `TypeScript`. `Content-Type` is `text/plain; charset=utf-8`.
- **Edge Cases**:
  - Python file: `X-File-Language` should be `Python`.
  - Unknown extension (`.xyz`): `X-File-Language` should be `Plain Text`.
  - No extension: `X-File-Language` should be `Plain Text`.

---

#### `TC-sc-api-path-traversal`: API rejects relative path traversal attempts

- **Type**: Unit
- **Covers**: `FR-sc-file-api`, `NFR-sc-localhost-only`
- **Preconditions**: The Vite dev server is running.
- **Steps**:
  1. Send `GET /api/file?path=../../../etc/passwd` from localhost.
  2. Send `GET /api/file?path=..%2F..%2F..%2Fetc%2Fpasswd` from localhost.
  3. Send `GET /api/file?path=relative/path/file.ts` from localhost.
  4. Inspect all responses.
- **Expected Result**: All three requests are rejected with status 400 (relative paths are not accepted per the engineering spec -- the path must be absolute). The error message should indicate that an absolute path is required. No file content from sensitive locations is returned.
- **Edge Cases**:
  - Path that starts with `/` but includes `..` traversal (e.g., `/Users/dev/../../etc/passwd`): the path is absolute so it passes the absolute-path check, but `fs.realpath()` resolves it to `/etc/passwd`. Since we serve arbitrary local files to localhost, this is technically valid per the spec -- the threat model assumes localhost trust. However, the test should verify that `fs.realpath()` is called (i.e., the resolved path is what gets read, not the raw input).

---

### Web App -- Auto-Load from URL Parameter

---

#### `TC-sc-auto-load-from-url-param`: App loads file from `?file=` parameter

- **Type**: E2E
- **Covers**: `FR-sc-auto-load-file`, `AC-sc-launch-happy-path`
- **Preconditions**: The CRPG web app is served via the Vite dev server. A text file `utils.ts` exists at a known absolute path.
- **Steps**:
  1. Navigate the browser to `http://localhost:<port>?file=<url-encoded-absolute-path>`.
  2. Observe the CRPG UI.
- **Expected Result**: The code viewer displays the content of `utils.ts` with syntax highlighting (TypeScript). The file name "utils.ts" is displayed in the file header. The drop zone is not visible. The sidebar panel is visible with the preamble input.
- **Edge Cases**:
  - URL with extra query parameters (e.g., `?file=<path>&foo=bar`): the extra parameters should be ignored; the file loads normally.

---

#### `TC-sc-auto-load-clears-url-param`: App clears `?file=` from URL after loading

- **Type**: Integration
- **Covers**: `FR-sc-auto-load-file`
- **Preconditions**: The CRPG web app is running.
- **Steps**:
  1. Navigate to `http://localhost:<port>?file=<url-encoded-path>`.
  2. Wait for the file to load.
  3. Inspect `window.location.search`.
- **Expected Result**: After loading, `window.location.search` is empty (the `?file=` parameter has been removed via `history.replaceState`). The URL in the address bar shows only `http://localhost:<port>` (or `http://localhost:<port>/`).
- **Edge Cases**:
  - Refreshing the page after the parameter is cleared: the app should show the empty state (drop zone), not attempt to re-fetch the file.

---

#### `TC-sc-auto-load-error-state`: App shows error on API failure

- **Type**: Integration
- **Covers**: `FR-sc-auto-load-file`
- **Preconditions**: The CRPG web app is running.
- **Steps**:
  1. Navigate to `http://localhost:<port>?file=%2Ftmp%2Fnonexistent-file.ts` (a path that does not exist).
  2. Observe the UI.
- **Expected Result**: The drop zone renders in its error variant with the message "File not found. It may have been moved or deleted." The drop zone is fully functional -- the user can load a different file via drag-and-drop, upload, or paste.
- **Edge Cases**:
  - Binary file path in URL: error message should be "This file doesn't appear to be a text file. Only plain-text files are supported."
  - Permission denied: error message should be "Permission denied. The file could not be read."
  - Network error (server not running): error message should be "Could not connect to the local server. Try running the shepherd command again."

---

#### `TC-sc-auto-load-no-param`: App shows normal empty state without `?file=` param

- **Type**: Integration
- **Covers**: `FR-sc-auto-load-file`
- **Preconditions**: The CRPG web app is running.
- **Steps**:
  1. Navigate to `http://localhost:<port>` (no query parameters).
  2. Observe the UI.
- **Expected Result**: The app renders the normal empty state (drop zone with instructions). No API requests to `/api/file` are made. Behavior is identical to the pre-slash-command CRPG.
- **Edge Cases**:
  - N/A (regression test).

---

#### `TC-sc-session-clear-on-new-file`: New file via slash command clears existing session

- **Type**: E2E
- **Covers**: `AC-sc-session-clear-on-new-file`, `FR-sc-auto-load-file`
- **Preconditions**: The CRPG is open with a file loaded. The user has added 3 inline comments, typed a preamble, and generated a prompt.
- **Steps**:
  1. Navigate to `http://localhost:<port>?file=<url-encoded-path-to-another-file>` (simulating a second `/shepherd` invocation).
  2. Observe the UI.
- **Expected Result**: The previous file, all 3 comments, the preamble, and the generated prompt are cleared. The new file is loaded in the code viewer. No confirmation dialog appears. The comment count shows "0 comments".
- **Edge Cases**:
  - New file is the same file as the previous one: session should still be cleared (fresh start).

---

#### `TC-sc-large-file-warning-e2e`: Large file loaded via URL shows warning in agent output

- **Type**: E2E
- **Covers**: `AC-sc-large-file-warning`
- **Preconditions**: A text file with 15,000 lines exists. The Vite dev server is running.
- **Steps**:
  1. Type `/shepherd large-file.ts` in Claude Code.
  2. Observe the agent output and the browser.
- **Expected Result**: The agent reports the large-file warning. The CRPG loads the file in the browser and displays the code viewer. If the CRPG has its own large-file warning banner (from `NFR-crp-large-file-perf`), that banner also appears in the web app.
- **Edge Cases**:
  - N/A (combined agent + web check).

---

### Server Management

---

#### `TC-sc-server-starts-vite`: Vite dev server is started when not running

- **Type**: Integration
- **Covers**: `FR-sc-app-serve`
- **Preconditions**: The Shepherd repository is cloned. No Vite dev server is currently running.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether the agent starts the Vite dev server.
  3. Verify the server is running by accessing `http://localhost:<port>` (the dynamically assigned port reported in the output).
- **Expected Result**: The agent detects no running server for this worktree, starts it on a dynamic port, and then proceeds to open the browser with the file URL. The server serves the CRPG correctly. The output shows the assigned port.
- **Edge Cases**:
  - `pnpm` not installed: the agent should report a clear error.
  - Multiple servers running for different worktrees: each gets its own dynamic port.

---

#### `TC-sc-server-serves-static-assets`: Vite dev server serves the CRPG web assets

- **Type**: Integration
- **Covers**: `FR-sc-app-serve`
- **Preconditions**: The Vite dev server is running on a dynamically assigned port.
- **Steps**:
  1. Send `GET /` to `http://localhost:<port>` (the port reported during server startup).
  2. Inspect the response.
- **Expected Result**: `GET /` returns 200 with `text/html` content type and the CRPG's `index.html`. The static assets are served correctly.
- **Edge Cases**:
  - Requesting a non-existent static asset (e.g., `GET /assets/nope.js`): should return 404.

---

#### `TC-sc-server-reuse-vite`: Running Vite server is detected and reused

- **Type**: Integration
- **Covers**: `AC-sc-server-reuse`
- **Preconditions**: The Vite dev server is already running from a previous invocation.
- **Steps**:
  1. Type `/shepherd file2.ts` in Claude Code.
  2. Observe whether the agent starts a new server or reuses the existing one.
- **Expected Result**: The agent detects the running server and reuses it. No new server process is started. The success output shows the existing server's URL.
- **Edge Cases**:
  - N/A (focused test).

---

### Installation

---

#### `TC-sc-install-symlink`: Symlink install script creates correct symlink

- **Type**: E2E
- **Covers**: `AC-sc-install-symlink`, `FR-sc-install`, `NFR-sc-no-global-deps`, `NFR-sc-minimal-footprint`
- **Preconditions**: The Shepherd repository is cloned. No symlink exists at `~/.claude/commands/shepherd.md`.
- **Steps**:
  1. Run `./scripts/install-command.sh` from the repo root.
  2. Verify the symlink exists: `ls -la ~/.claude/commands/shepherd.md`.
  3. Verify the symlink target: `readlink ~/.claude/commands/shepherd.md`.
  4. Open Claude Code and verify `/shepherd` is available as a command.
- **Expected Result**: A symlink exists at `~/.claude/commands/shepherd.md` pointing to the repo's `.claude/commands/shepherd.md` file. The `/shepherd` command is recognized by Claude Code. No npm packages were installed globally. No binaries were placed on PATH.
- **Edge Cases**:
  - `~/.claude/commands/` directory does not exist: the install script should create it.
  - A file (not symlink) already exists at `~/.claude/commands/shepherd.md`: the script should warn the user and ask for confirmation or provide instructions.
  - Running the install script a second time: should be idempotent (replace or confirm the existing symlink).

---

#### `TC-sc-install-update-propagation`: Updates propagate through symlink automatically

- **Type**: Integration
- **Covers**: `AC-sc-install-symlink`, `FR-sc-install`
- **Preconditions**: The symlink is installed via `./scripts/install-command.sh`. The `/shepherd` command works.
- **Steps**:
  1. Read the current content of `~/.claude/commands/shepherd.md`.
  2. Run `git pull` in the repo (or simulate by modifying `.claude/commands/shepherd.md` in the repo).
  3. Read the content of `~/.claude/commands/shepherd.md` again.
- **Expected Result**: The content at `~/.claude/commands/shepherd.md` reflects the updated repo file without re-running the install script. This confirms the symlink is working correctly -- changes propagate automatically.
- **Edge Cases**:
  - The repo is moved to a different directory after installation: the symlink breaks. The user must re-run the install script.

---

#### `TC-sc-install-claude-code-command`: Claude Code custom command file works

- **Type**: E2E / Manual
- **Covers**: `FR-sc-install`, `FR-sc-invoke-command`
- **Preconditions**: The `.claude/commands/shepherd.md` file exists in the Shepherd repo (or is symlinked globally).
- **Steps**:
  1. Open Claude Code in the Shepherd repo.
  2. Type `/shepherd` and observe auto-complete.
  3. Type `/shepherd README.md`.
  4. Observe the agent's actions and output.
- **Expected Result**: Claude Code recognizes `/shepherd` as a custom command. The agent follows the instructions in the command file: validates the file, checks/starts the dev server, opens the browser with the `?file=` parameter, and reports success.
- **Edge Cases**:
  - The command file references `$ARGUMENTS`; if no arguments are provided, the agent should print usage instructions per the command file's logic.

---

### Cross-Platform Behavior

---

#### `TC-sc-cross-platform-macos`: Browser opens correctly on macOS

- **Type**: E2E
- **Covers**: `AC-sc-cross-platform-open`, `NFR-sc-cross-platform`, `FR-sc-browser-open`
- **Preconditions**: Running on macOS. The `/shepherd` command is available.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether a browser window opens.
- **Expected Result**: If Chrome or Chromium is installed, the CRPG opens in a chromeless app-mode window (no address bar, no tab strip). If neither is installed, the default macOS browser opens the CRPG as a regular tab via the `open` command.
- **Edge Cases**:
  - Default browser is not set and Chrome/Chromium not installed: `open` command may fail; the agent should report the URL and a warning.

---

#### `TC-sc-cross-platform-linux`: Browser opens correctly on Linux

- **Type**: E2E
- **Covers**: `AC-sc-cross-platform-open`, `NFR-sc-cross-platform`, `FR-sc-browser-open`
- **Preconditions**: Running on Linux. The `/shepherd` command is available.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether a browser window opens.
- **Expected Result**: If Chrome or Chromium is installed, the CRPG opens in a chromeless app-mode window (no address bar, no tab strip). If neither is installed, the default Linux browser opens the CRPG as a regular tab via `xdg-open`.
- **Edge Cases**:
  - Headless Linux server without `xdg-open` and no Chrome/Chromium: the agent should report the URL and a warning: `Warning: Could not open the browser automatically. Open the URL above in your browser.` The server is still started and the file is still served.
  - Linux with Wayland vs X11: `xdg-open` should work in both environments.

---

#### `TC-sc-cross-platform-windows`: Browser opens correctly on Windows

- **Type**: E2E
- **Covers**: `AC-sc-cross-platform-open`, `NFR-sc-cross-platform`, `FR-sc-browser-open`
- **Preconditions**: Running on Windows. The `/shepherd` command is available.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether a browser window opens.
- **Expected Result**: If Chrome or Chromium is installed, the CRPG opens in a chromeless app-mode window (no address bar, no tab strip). If neither is installed, the default Windows browser opens the CRPG as a regular tab via `cmd /c start`.
- **Edge Cases**:
  - N/A (focused platform test).

---

#### `TC-sc-path-handling-windows`: Windows path separators are handled correctly

- **Type**: Unit
- **Covers**: `NFR-sc-cross-platform`, `FR-sc-file-resolution`
- **Preconditions**: Running on Windows. A file exists at `C:\Users\dev\project\main.py`.
- **Steps**:
  1. Type `/shepherd C:\Users\dev\project\main.py`.
  2. Type `/shepherd C:/Users/dev/project/main.py` (forward slashes).
  3. Observe the `?file=` parameter in both cases.
- **Expected Result**: Both commands succeed. The `?file=` parameter contains the OS-native path format (`C:\Users\dev\project\main.py`), URL-encoded.
- **Edge Cases**:
  - UNC paths (e.g., `\\server\share\file.txt`): behavior is unspecified in the product spec; this should be flagged if it fails.

---

### Standalone App Window

---

#### `TC-sc-app-window-chrome`: Opens as app-mode window with Chrome

- **Type**: E2E
- **Covers**: `AC-sc-standalone-window`, `FR-sc-browser-open`
- **Preconditions**: Chrome is installed.
- **Steps**:
  1. Run `/shepherd <file>`. Observe the opened window.
- **Expected Result**: CRPG opens in a chromeless window -- no address bar, no tab strip, no browser navigation buttons. The window title is the page title, not a URL.
- **Edge Cases**:
  - Chrome is installed but not the default browser: should still use Chrome's `--app` flag for the chromeless window.

---

#### `TC-sc-app-window-chromium-fallback`: Falls back to Chromium if Chrome not installed

- **Type**: E2E
- **Covers**: `AC-sc-standalone-window`
- **Preconditions**: Chrome is NOT installed, Chromium IS installed.
- **Steps**:
  1. Run `/shepherd <file>`.
- **Expected Result**: CRPG opens in a Chromium app-mode window (same chromeless appearance).
- **Edge Cases**:
  - Multiple Chromium-based browsers installed (e.g., Brave, Edge): the agent should prefer Chromium over other Chromium-based browsers for app-mode consistency.

---

#### `TC-sc-app-window-browser-fallback`: Falls back to default browser if no Chrome/Chromium

- **Type**: E2E
- **Covers**: `AC-sc-standalone-window`, `FR-sc-browser-open`
- **Preconditions**: Neither Chrome nor Chromium is installed.
- **Steps**:
  1. Run `/shepherd <file>`.
- **Expected Result**: CRPG opens in the default browser as a regular tab. No error.
- **Edge Cases**:
  - Default browser is also a Chromium-based browser (e.g., Edge): the fallback should still open as a regular tab, not attempt `--app` mode on an untested browser.

---

#### `TC-sc-app-window-subsequent`: Subsequent invocation reuses or opens new app window

- **Type**: E2E
- **Covers**: `AC-sc-standalone-window`
- **Preconditions**: Chrome installed, CRPG already open in app-mode window.
- **Steps**:
  1. Run `/shepherd <another-file>`.
- **Expected Result**: New file loads in the browser (new window or URL navigation). No duplicate windows pile up.
- **Edge Cases**:
  - Running `/shepherd` with the same file that's already open: should not create a second window or error.

---

### Performance

---

#### `TC-sc-launch-speed-cold`: Cold launch completes quickly

- **Type**: E2E / Performance
- **Covers**: `NFR-sc-launch-speed`, `AC-sc-cold-launch-8s`
- **Preconditions**: The Vite dev server is not running.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe the time from invocation to browser opening.
- **Expected Result**: The agent completes file validation, starts the Vite dev server, and opens the browser within 8 seconds. Vite's dev server starts quickly since it does not require a full build. With the launcher script optimization, this includes one AI inference round-trip plus the launcher script handling server startup.
- **Edge Cases**:
  - Cold filesystem cache (first run after reboot): may be slightly slower due to disk I/O.

---

#### `TC-sc-launch-speed-warm`: Warm launch (server reuse) completes quickly

- **Type**: E2E / Performance
- **Covers**: `NFR-sc-launch-speed`, `AC-sc-warm-launch-2s`
- **Preconditions**: The Vite dev server is already running from a previous invocation.
- **Steps**:
  1. Type `/shepherd anotherfile.ts` in Claude Code.
  2. Observe the time from invocation to browser opening.
- **Expected Result**: The agent completes file validation and opens the browser within 2 seconds. Expected to be faster than cold start (no server startup needed). With the launcher script optimization, this is achieved via a single shell invocation (~265ms) plus one AI inference round-trip.
- **Edge Cases**:
  - N/A (focused performance test).

---

### Launcher Script

---

#### `TC-sc-launcher-warm-launch`: Warm launch timing

- **Priority**: High
- **Type**: Performance / Automated
- **Covers**: `AC-sc-warm-launch-2s`, `NFR-sc-launch-speed`, `FR-sc-launcher-script`
- **Preconditions**: Vite dev server is running on a dynamic port for this worktree. A valid text file exists.
- **Steps**:
  1. Record the current timestamp.
  2. Invoke `/shepherd <filepath>` in Claude Code.
  3. Record the timestamp when the browser tab opens (or when the `open` command returns).
  4. Calculate elapsed time.
- **Expected Result**: Elapsed time is under 2 seconds.
- **Notes**: The timing includes one agent tool call overhead plus the launcher script execution (~265ms). Most of the budget is consumed by the single AI inference round-trip.

---

#### `TC-sc-launcher-cold-launch`: Cold launch timing

- **Priority**: High
- **Type**: Performance / Manual
- **Covers**: `AC-sc-cold-launch-8s`, `NFR-sc-launch-speed`, `FR-sc-launcher-script`
- **Preconditions**: Vite dev server is NOT running. A valid text file exists. The Shepherd repository is cloned with `node_modules` installed.
- **Steps**:
  1. Ensure no Vite dev server is running for this worktree.
  2. Record the current timestamp.
  3. Invoke `/shepherd <filepath>` in Claude Code.
  4. Record the timestamp when the browser tab opens.
  5. Calculate elapsed time.
- **Expected Result**: Elapsed time is under 8 seconds (including Vite dev server startup on a dynamic port).

---

#### `TC-sc-single-tool-call`: Single tool call execution

- **Priority**: High
- **Type**: Functional / Manual
- **Covers**: `AC-sc-single-tool-call`, `FR-sc-launcher-script`
- **Preconditions**: The `/shepherd` command is installed. A valid text file exists.
- **Steps**:
  1. Invoke `/shepherd <filepath>` in Claude Code.
  2. Observe the agent's execution (tool calls made).
- **Expected Result**: The agent makes exactly one Bash tool call to execute the launcher script. It does NOT make multiple sequential tool calls for file validation, server checking, and browser opening separately.

---

#### `TC-sc-launcher-script-validation`: Launcher script handles all validation

- **Priority**: Medium
- **Type**: Functional / Automated
- **Covers**: `FR-sc-launcher-script`, `FR-sc-file-validation`
- **Preconditions**: `scripts/shepherd-launch.sh` exists and is executable.
- **Steps**:
  1. Run `scripts/shepherd-launch.sh` with a non-existent file path.
  2. Run `scripts/shepherd-launch.sh` with a directory path.
  3. Run `scripts/shepherd-launch.sh` with a binary file (e.g., a PNG).
  4. Run `scripts/shepherd-launch.sh` with no arguments.
- **Expected Result**:
  - Non-existent file: exits 1, stderr contains "File not found"
  - Directory: exits 1, stderr contains error about directories
  - Binary file: exits 1, stderr contains "Binary file not supported"
  - No arguments: exits 1, stderr contains usage information

---

#### `TC-sc-launcher-server-start`: Launcher script starts server when needed

- **Priority**: High
- **Type**: Functional / Manual
- **Covers**: `FR-sc-launcher-script`, `FR-sc-app-serve`, `AC-sc-cold-launch-8s`
- **Preconditions**: Vite dev server is NOT running. A valid text file exists.
- **Steps**:
  1. Verify no Vite dev server is running for this worktree.
  2. Run `scripts/shepherd-launch.sh <filepath>`.
  3. Verify the Vite dev server is now running on a dynamically assigned port.
  4. Verify the browser opened with the correct URL including `?session=<id>&file=<encoded-path>`.
- **Expected Result**: The script starts the dev server on a dynamic port, waits for it to be ready, and opens the browser. Exit code is 0. Output summary indicates server was started (not reused) and reports the session ID and port.

---

### Security

---

#### `TC-sc-no-outbound-network`: No outbound network requests

- **Type**: Integration
- **Covers**: `NFR-sc-no-telemetry`
- **Preconditions**: Network monitoring is enabled (e.g., `tcpdump`, `lsof -i`, or a proxy).
- **Steps**:
  1. Start the Vite dev server via `/shepherd somefile.ts`.
  2. Make several file requests to the API.
  3. Monitor all outbound network connections from the server process.
- **Expected Result**: Zero outbound network connections are made. The server only listens for inbound connections on `127.0.0.1`. No DNS lookups, no HTTP requests to external services, no telemetry, no update checks.
- **Edge Cases**:
  - Vite may perform HMR-related operations during development, but these should be limited to the localhost WebSocket connection.

---

### Prompt Feedback Loop -- API

---

#### `TC-sc-prompt-api-write-happy`: POST /api/prompt-output writes file to session-scoped path

- **Type**: Unit
- **Covers**: `FR-sc-prompt-output-api`, `AC-sc-prompt-output-api-success`, `FR-sc-session-scoped-output`
- **Preconditions**: Vite dev server running. A session with ID `<session-id>` is active.
- **Steps**:
  1. Send `POST /api/prompt-output?session=<session-id>` with text body "test prompt content" from localhost.
  2. Inspect the response status.
  3. Read the file at `~/.shepherd/sessions/<session-id>/prompt-output.md`.
- **Expected Result**: Response status is 200. The file `~/.shepherd/sessions/<session-id>/prompt-output.md` exists with content "test prompt content".
- **Edge Cases**:
  - Empty body: should still write the file (with empty content) and return 200.
  - Very large body (1 MB of text): should write successfully.

---

#### `TC-sc-prompt-api-creates-dir`: API creates session directory if missing

- **Type**: Unit
- **Covers**: `FR-sc-prompt-output-api`, `FR-sc-session-scoped-output`
- **Preconditions**: Vite dev server running. `~/.shepherd/sessions/<session-id>/` directory does NOT exist. A session with ID `<session-id>` is active.
- **Steps**:
  1. Ensure `~/.shepherd/sessions/<session-id>/` does not exist.
  2. Send `POST /api/prompt-output?session=<session-id>` with text body "test content" from localhost.
  3. Inspect the response status and filesystem.
- **Expected Result**: Response status is 200. The `~/.shepherd/sessions/<session-id>/` directory was created (including intermediate directories). The file `~/.shepherd/sessions/<session-id>/prompt-output.md` exists with content "test content".
- **Edge Cases**:
  - `~/.shepherd/` directory does not exist at all: the API should create the full directory tree (`~/.shepherd/sessions/<session-id>/`).

---

#### `TC-sc-prompt-api-overwrites`: API overwrites existing output file

- **Type**: Unit
- **Covers**: `FR-sc-prompt-output-api`
- **Preconditions**: Vite dev server running. `~/.shepherd/sessions/<session-id>/prompt-output.md` already exists with content "old content". A session with ID `<session-id>` is active.
- **Steps**:
  1. Send `POST /api/prompt-output?session=<session-id>` with text body "new content" from localhost.
  2. Read the file at `~/.shepherd/sessions/<session-id>/prompt-output.md`.
- **Expected Result**: Response status is 200. File content is "new content" (the old content is fully replaced).
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-sc-prompt-api-localhost-only`: API rejects non-localhost requests

- **Type**: Unit
- **Covers**: `AC-sc-prompt-output-api-localhost-only`
- **Preconditions**: Vite dev server running.
- **Steps**:
  1. Send `POST /api/prompt-output?session=<session-id>` with an `Origin` header set to `http://evil.com` and text body "malicious content".
  2. Inspect the response status.
  3. Check that `~/.shepherd/sessions/<session-id>/prompt-output.md` was NOT written (or not overwritten if it existed).
- **Expected Result**: Response status is 403. The file is not written.
- **Edge Cases**:
  - `Origin: http://localhost:9999` (different port but still localhost): should be accepted.
  - `Origin: http://127.0.0.1:<port>` (IP address form): should be accepted.
  - No `Origin` header (same-origin request): should be accepted.
  - `Origin: http://localhost.evil.com`: should be rejected.

---

#### `TC-sc-prompt-api-method-check`: API rejects non-POST methods

- **Type**: Unit
- **Covers**: `FR-sc-prompt-output-api`
- **Preconditions**: Vite dev server running.
- **Steps**:
  1. Send `GET /api/prompt-output?session=<session-id>` from localhost.
  2. Inspect the response status.
- **Expected Result**: Response status is 405 or another appropriate error (not 200). The file is not written.
- **Edge Cases**:
  - `PUT /api/prompt-output`: should also be rejected.
  - `DELETE /api/prompt-output`: should also be rejected.

---

#### `TC-sc-prompt-api-no-collision`: Prompt API and file API don't interfere

- **Type**: Integration
- **Covers**: `FR-sc-prompt-output-api`, `FR-sc-file-api`
- **Preconditions**: Vite dev server running. A valid text file exists at a known path.
- **Steps**:
  1. Send `GET /api/file?path=<url-encoded-path>` from localhost.
  2. Inspect the response (should be 200 with file content).
  3. Send `POST /api/prompt-output?session=<session-id>` with text body "prompt text" from localhost.
  4. Inspect the response (should be 200).
  5. Send `GET /api/file?path=<url-encoded-path>` again.
  6. Inspect the response (should be 200 with same file content as step 2).
- **Expected Result**: Both endpoints work correctly and independently. The file API returns the correct file content before and after the prompt API is called. The prompt API writes its own file without affecting the file API.
- **Edge Cases**:
  - Calling both endpoints concurrently: both should succeed without interference.

---

### Prompt Feedback Loop -- Watcher

---

#### `TC-sc-watcher-detects-file`: Watcher detects prompt output file in session directory

- **Type**: Integration
- **Covers**: `FR-sc-prompt-receive`, `AC-sc-prompt-received`, `FR-sc-session-scoped-output`
- **Preconditions**: The watcher script/polling loop is running for session `<session-id>`. `~/.shepherd/sessions/<session-id>/prompt-output.md` does NOT exist.
- **Steps**:
  1. Write content "Test prompt from CRPG" to `~/.shepherd/sessions/<session-id>/prompt-output.md`.
  2. Wait up to 2 seconds.
  3. Observe the watcher output.
- **Expected Result**: The watcher detects the file within 2 seconds (1-second polling interval + processing time). The watcher outputs the file content ("Test prompt from CRPG"). The file is deleted after being read.
- **Edge Cases**:
  - File appears then disappears before watcher polls: this is a race condition; the watcher should handle "file not found" gracefully (retry on next poll).

---

#### `TC-sc-watcher-cleanup-stale`: Stale session directory cleaned up before watcher starts

- **Type**: Unit
- **Covers**: `FR-sc-prompt-cleanup`, `AC-sc-prompt-cleanup-stale`, `FR-sc-session-cleanup`
- **Preconditions**: `~/.shepherd/sessions/<session-id>/prompt-output.md` exists from a previous session (stale file).
- **Steps**:
  1. Run the stale cleanup command as part of the watcher startup sequence for a new session.
  2. Verify the stale session's `prompt-output.md` is not processed.
  3. Start the watcher for the new session.
  4. Observe the watcher state.
- **Expected Result**: The watcher starts fresh for its own session directory and waits for a new file to appear. It does NOT process stale files from other sessions. Stale session directories older than 24 hours are cleaned up by the session cleanup mechanism.
- **Edge Cases**:
  - No stale session directories exist: cleanup should be a no-op.
  - `~/.shepherd/sessions/` directory does not exist: cleanup should not error.

---

#### `TC-sc-watcher-timeout`: Watcher times out after configured period

- **Type**: Integration
- **Covers**: `AC-sc-prompt-watcher-timeout`, `NFR-sc-watcher-low-overhead`
- **Preconditions**: Watcher running with a short timeout (e.g., 5 seconds for testing purposes instead of the full 30 minutes).
- **Steps**:
  1. Start the watcher with a 5-second timeout.
  2. Do NOT create the `~/.shepherd/sessions/<session-id>/prompt-output.md` file.
  3. Wait for the timeout to expire.
  4. Observe the watcher output.
- **Expected Result**: The watcher exits gracefully with a timeout message after 5 seconds. No crash occurs. No zombie processes remain.
- **Edge Cases**:
  - File appears 1 second before timeout: watcher should still detect and process it (the file check happens before the timeout check in each iteration).
  - File appears exactly at timeout boundary: behavior may vary; either detection or timeout is acceptable.

---

#### `TC-sc-watcher-deletes-after-read`: Watcher deletes file after reading

- **Type**: Integration
- **Covers**: `FR-sc-prompt-receive`
- **Preconditions**: Watcher is running.
- **Steps**:
  1. Write "prompt content" to `~/.shepherd/sessions/<session-id>/prompt-output.md`.
  2. Wait for the watcher to detect and process the file.
  3. Check if `~/.shepherd/sessions/<session-id>/prompt-output.md` still exists.
- **Expected Result**: The file is deleted after being read. The watcher output contains "prompt content". Subsequent watcher polls do not re-process the same content.
- **Edge Cases**:
  - File deletion fails (e.g., permissions changed): the watcher should still output the content but may log a warning about the failed deletion.

---

### Prompt Feedback Loop -- End-to-End

---

#### `TC-sc-feedback-loop-e2e`: Full feedback loop from Done click to agent

- **Type**: E2E
- **Covers**: `FR-sc-prompt-receive`, `FR-sc-prompt-output-api`, `FR-crp-done-action`, `FR-crp-prompt-handoff`, `AC-sc-prompt-received`
- **Preconditions**: The `/shepherd` command has been run. The CRPG is open with a file loaded via `?file=` URL param. The watcher is running (started by the slash command). A comment has been added.
- **Steps**:
  1. Add a comment in the CRPG (e.g., "Rename this variable").
  2. Click the Done button.
  3. Observe the CRPG UI (button state, toast).
  4. Observe the watcher/agent output.
  5. Check that the file `~/.shepherd/sessions/<session-id>/prompt-output.md` is cleaned up.
- **Expected Result**: The CRPG sends a POST to `/api/prompt-output?session=<session-id>` with the generated prompt. The server writes the prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`. The watcher detects the file, reads its content, outputs the prompt, and deletes the file. The CRPG shows "Sent ✓" and the success toast. The full loop completes without manual intervention.
- **Edge Cases**:
  - Watcher detects the file before the CRPG receives the 200 response: this is fine -- the file write is what matters, not the HTTP response timing.

---

#### `TC-sc-feedback-loop-resend`: Can send multiple prompts in one session

- **Type**: E2E
- **Covers**: `FR-sc-prompt-receive`, `FR-crp-done-action`
- **Preconditions**: Same as `TC-sc-feedback-loop-e2e`. The first Done was successful and the watcher consumed the file.
- **Steps**:
  1. Add another comment in the CRPG.
  2. Observe the Done button (should have reverted to "Done" after the comment was added).
  3. Click Done again.
  4. Observe the watcher/agent output.
- **Expected Result**: A new prompt (including the new comment) is sent via POST. A new file is written. A new watcher instance (or the continued watcher loop) detects and processes the new file. The previous output does not interfere.
- **Edge Cases**:
  - Rapid successive Done clicks across multiple edits: each should be treated independently.

---

### Session Isolation

---

#### `TC-sc-session-id-generated`: Each invocation produces a unique session ID visible in output and URL

- **Type**: Integration
- **Covers**: `FR-sc-session-id`
- **Preconditions**: The `/shepherd` custom command is available. A valid text file exists.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe the agent output.
  3. Observe the browser URL.
- **Expected Result**: The agent output includes a session identifier (e.g., `Session: my-project`). The session ID is derived from the working directory basename — it should be a slugified version of the directory name (lowercase alphanumeric and hyphens, e.g., `shepherd-1`, `my-project`). The browser URL contains `?session=<id>&file=<encoded-path>` where `<id>` matches the session ID in the agent output.
- **Edge Cases**:
  - The session ID should contain only lowercase alphanumeric characters and hyphens. No uppercase, underscores, spaces, or special characters.

---

#### `TC-sc-session-id-deterministic`: Same worktree produces same session ID

- **Type**: Integration
- **Covers**: `FR-sc-session-id`
- **Preconditions**: The `/shepherd` custom command is available. A valid text file exists.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code from directory `/path/to/my-project`. Note the session ID from the output.
  2. Type `/shepherd somefile.ts` again from the same directory. Note the session ID from the output.
  3. Compare the two session IDs.
- **Expected Result**: The two session IDs are identical (e.g., both are `my-project`). The session ID is derived from the working directory, so the same worktree always produces the same ID.
- **Edge Cases**:
  - Different worktrees with different names produce different session IDs (e.g., `project-a` vs `project-b`).
  - Two directories with the same basename in different parent paths (e.g., `/home/alice/myapp` and `/home/bob/myapp`) produce the same session ID (`myapp`). This is acceptable — users rarely have two repos with the same name on the same machine.

---

#### `TC-sc-dynamic-port`: Server uses a dynamic port instead of fixed 5173

- **Type**: Integration
- **Covers**: `FR-sc-dynamic-port`
- **Preconditions**: The `/shepherd` custom command is available. A valid text file exists. No existing server is running for this worktree.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe the port number in the agent output URL.
- **Expected Result**: The URL shows a dynamically assigned port (not necessarily 5173). The port is a valid TCP port number. The server is accessible at the reported port.
- **Edge Cases**:
  - The port may happen to be 5173 if that port is available, but it is not guaranteed to be 5173.

---

#### `TC-sc-concurrent-sessions-happy`: Two sessions from different worktrees run simultaneously

- **Type**: E2E
- **Covers**: `AC-sc-concurrent-sessions`, `FR-sc-concurrent-windows`, `FR-sc-dynamic-port`
- **Preconditions**: Two separate worktrees (or clones) of a repository exist at different paths. Valid text files exist in each. The `/shepherd` command is available.
- **Steps**:
  1. Open a Claude Code session in worktree A. Type `/shepherd file1.ts`. Note the session ID (A) and port (A).
  2. Open a Claude Code session in worktree B. Type `/shepherd file2.ts`. Note the session ID (B) and port (B).
  3. Verify both browser windows are open and functional.
  4. In browser window A, add a comment to file1.ts.
  5. In browser window B, add a comment to file2.ts.
- **Expected Result**: Session IDs A and B are different. Ports A and B are different (separate server instances). Both browser windows are open simultaneously. Each shows its respective file. Adding a comment in window A does not affect window B, and vice versa. Neither session is clobbered by the other.
- **Edge Cases**:
  - Starting session B while session A is still active: session A should remain fully functional.
  - Both sessions using the same file name (but from different worktrees): both should work independently.

---

#### `TC-sc-session-output-isolation`: Clicking Done in one session does not affect another

- **Type**: E2E
- **Covers**: `AC-sc-session-output-isolation`, `FR-sc-session-scoped-output`
- **Preconditions**: Two concurrent sessions (A and B) are running from different worktrees. Comments have been added in both sessions.
- **Steps**:
  1. In session A's browser window, click "Done".
  2. Verify session A's output is written to `~/.shepherd/sessions/<session-id-A>/prompt-output.md`.
  3. Verify session B's directory (`~/.shepherd/sessions/<session-id-B>/`) is unaffected -- no `prompt-output.md` exists there yet.
  4. Verify session B's browser window remains fully functional (can still navigate, add comments, etc.).
  5. In session B's browser window, click "Done".
  6. Verify session B's output is written to `~/.shepherd/sessions/<session-id-B>/prompt-output.md`.
- **Expected Result**: Each session writes output only to its own session-scoped directory. Clicking Done in session A has no effect on session B's files or UI. Both outputs contain only their respective session's comments.
- **Edge Cases**:
  - Clicking Done in both sessions within a few milliseconds of each other: both should write independently without race conditions.

---

#### `TC-sc-session-scoped-output-path`: Prompt output is written to session-scoped path

- **Type**: Integration
- **Covers**: `AC-sc-prompt-output-api-success`, `FR-sc-session-scoped-output`
- **Preconditions**: A session is active with session ID `<session-id>`. A file is loaded and a comment has been added.
- **Steps**:
  1. Click "Done" in the CRPG.
  2. Check the filesystem for the output file.
- **Expected Result**: The output file is written to `~/.shepherd/sessions/<session-id>/prompt-output.md`. The file does NOT exist at the legacy path `~/.shepherd/prompt-output.md`. The session-scoped directory was created automatically.
- **Edge Cases**:
  - `~/.shepherd/sessions/` directory does not exist before the first session: it should be created automatically.

---

#### `TC-sc-session-cleanup-after-read`: Session directory is cleaned up after agent reads the output

- **Type**: Integration
- **Covers**: `FR-sc-session-cleanup`
- **Preconditions**: A session has completed -- the user clicked Done and the output was written to `~/.shepherd/sessions/<session-id>/prompt-output.md`.
- **Steps**:
  1. Observe the agent reading the output file.
  2. Check if `~/.shepherd/sessions/<session-id>/` directory exists after the agent reads the output.
- **Expected Result**: After the agent reads the output, the session directory `~/.shepherd/sessions/<session-id>/` is deleted (along with its contents). The `~/.shepherd/sessions/` parent directory may still exist for other active sessions.
- **Edge Cases**:
  - If the directory deletion fails (e.g., permissions), the agent should log a warning but not crash.
  - Other session directories (from concurrent sessions) must NOT be affected by this cleanup.

---

#### `TC-sc-server-reuse-same-worktree`: Server is reused for the same worktree

- **Type**: Integration
- **Covers**: `AC-sc-server-reuse`, `FR-sc-dynamic-port`
- **Preconditions**: A server is already running from a previous `/shepherd` invocation in worktree A.
- **Steps**:
  1. Type `/shepherd file1.ts` from worktree A. Note the port number.
  2. Type `/shepherd file2.ts` from the same worktree A. Note the port number.
- **Expected Result**: The port number is the same for both invocations. The agent output indicates the server was reused (e.g., "reusing existing server" or similar). A new session ID is generated for each invocation, but the underlying server is shared. The second invocation opens faster (warm launch) because no server startup is needed.
- **Edge Cases**:
  - The second invocation uses a different session ID than the first, even though the server is reused.

---

#### `TC-sc-separate-servers-different-worktrees`: Different worktrees get different servers

- **Type**: Integration
- **Covers**: `FR-sc-dynamic-port`, `FR-sc-concurrent-windows`
- **Preconditions**: Two separate worktrees exist. No servers are running.
- **Steps**:
  1. Type `/shepherd file.ts` from worktree A. Note the port.
  2. Type `/shepherd file.ts` from worktree B. Note the port.
  3. List running server processes.
- **Expected Result**: Different ports are assigned for worktree A and worktree B. Two separate server processes are running. Each server serves the CRPG independently.
- **Edge Cases**:
  - Stopping the server for worktree A should not affect the server for worktree B.

---

#### `TC-sc-window-title-shows-project`: Browser window title shows project context

- **Type**: E2E
- **Covers**: `FR-crp-session-identity`
- **Preconditions**: The `/shepherd` command is available. A valid text file exists in a project directory named `my-project`.
- **Steps**:
  1. Type `/shepherd somefile.ts` from the `my-project` directory.
  2. Observe the browser window title.
- **Expected Result**: The browser window title displays "Shepherd -- my-project" (where "my-project" is derived from the working directory or git repository name). This helps distinguish multiple concurrent sessions when switching between browser windows.
- **Edge Cases**:
  - Project directory with a long name: the title should still be readable (may be truncated by the OS window manager).
  - Project directory with special characters in the name: should be displayed correctly.
  - Running in a subdirectory of the project: the title should still show the project root name, not the subdirectory.

---

## Edge Cases & Error Scenarios

---

### `TC-sc-edge-spaces-in-path`: File path with spaces

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`, `FR-sc-file-api`
- **Preconditions**: A file exists at `/Users/dev/my project/my file.ts`.
- **Steps**:
  1. Type `/shepherd "/Users/dev/my project/my file.ts"`.
  2. Observe the `?file=` parameter in the browser URL.
  3. Verify the file loads in the CRPG.
- **Expected Result**: The path is correctly URL-encoded in the `?file=` parameter (spaces become `%20`). The file API correctly URL-decodes the path and reads the file. The file loads in the CRPG with file name "my file.ts".
- **Edge Cases**:
  - Tab characters in path: should be URL-encoded and handled.
  - Path with percent sign (e.g., `100%.txt`): should be double-encoded correctly.

---

### `TC-sc-edge-unicode-filename`: File path with unicode characters

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`, `FR-sc-file-api`
- **Preconditions**: A file exists at a path containing Unicode characters (e.g., `/Users/dev/projet/fichier.ts` with accented characters, or CJK characters in the path).
- **Steps**:
  1. Type `/shepherd <path-with-unicode>`.
  2. Observe the `?file=` parameter.
  3. Verify the file loads in the CRPG.
- **Expected Result**: The Unicode path is correctly URL-encoded, transmitted to the API, decoded, and read from the filesystem. The file loads with the correct file name displayed.
- **Edge Cases**:
  - Emoji in filename: should be handled if the OS supports it.
  - Right-to-left characters in path: should be preserved correctly.

---

### `TC-sc-edge-very-long-path`: File path exceeding 255 characters

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`, `FR-sc-file-api`
- **Preconditions**: A file exists at a path with deeply nested directories resulting in a total path length over 255 characters (but under the OS limit, typically 1024 on macOS/Linux or 260 on Windows).
- **Steps**:
  1. Create a deeply nested directory structure and a file at the bottom.
  2. Type `/shepherd <very-long-path>`.
  3. Observe whether the file loads.
- **Expected Result**: The file loads correctly. The URL-encoded path may be very long but should still be handled by the browser and the file API.
- **Edge Cases**:
  - Path exceeding the OS maximum (e.g., 1024 characters on macOS): the OS itself will reject the path; the agent should report the OS error cleanly rather than crashing.
  - URL exceeding typical browser URL length limits (~2048 characters): may cause issues with browser navigation. This is an inherent limitation.

---

### `TC-sc-edge-symlink-to-directory`: Symlink that resolves to a directory

- **Type**: Unit
- **Covers**: `FR-sc-file-resolution`, `FR-sc-file-validation`
- **Preconditions**: A symlink `link-to-dir` exists that points to a directory `/Users/dev/project/src/`.
- **Steps**:
  1. Type `/shepherd link-to-dir`.
  2. Observe the agent output.
- **Expected Result**: The agent follows the symlink, detects the target is a directory, and reports `Error: Path is a directory, not a file: /Users/dev/project/src/`.
- **Edge Cases**:
  - N/A (focused test).

---

### `TC-sc-edge-empty-file`: Empty file (0 bytes) is accepted

- **Type**: Unit
- **Covers**: `FR-sc-file-validation`, `FR-sc-file-api`
- **Preconditions**: An empty file `empty.ts` (0 bytes) exists.
- **Steps**:
  1. Type `/shepherd empty.ts`.
  2. Observe the output and browser.
- **Expected Result**: The command succeeds. Output shows `Loaded: empty.ts (0 lines, TypeScript)`. The CRPG opens and displays an empty code viewer. No binary detection error (no null bytes to find in 0 bytes).
- **Edge Cases**:
  - N/A (focused test).

---

### `TC-sc-edge-file-with-only-null-bytes`: File containing only null bytes

- **Type**: Unit
- **Covers**: `FR-sc-file-validation`
- **Preconditions**: A file exists containing only `0x00` bytes (e.g., created with `dd if=/dev/zero of=nullfile bs=1 count=100`).
- **Steps**:
  1. Type `/shepherd nullfile`.
  2. Observe the agent output.
- **Expected Result**: The agent detects binary content and reports `Error: Binary file not supported: <path>`.
- **Edge Cases**:
  - N/A (focused test).

---

### `TC-sc-edge-browser-open-fails`: Browser fails to open

- **Type**: Unit
- **Covers**: `FR-sc-browser-open`
- **Preconditions**: Running on a headless server without `xdg-open` or similar.
- **Steps**:
  1. Type `/shepherd somefile.ts`.
  2. Observe the agent output.
- **Expected Result**: The agent still reports the success output (URL and file info) plus a warning: `Warning: Could not open the browser automatically. Open the URL above in your browser.` The server is running and accessible at the printed URL.
- **Edge Cases**:
  - N/A (focused test).

---

### `TC-sc-edge-port-in-use`: Dynamic port assignment avoids conflicts

- **Type**: Unit
- **Covers**: `FR-sc-app-serve`, `FR-sc-dynamic-port`
- **Preconditions**: Several other processes are listening on various ports.
- **Steps**:
  1. Start several processes on common ports (e.g., 3000, 5173, 8080).
  2. Type `/shepherd somefile.ts` in Claude Code.
  3. Observe the assigned port in the output.
- **Expected Result**: The server is assigned a dynamic port that does not conflict with existing processes. The browser opens with the correct dynamically assigned port.
- **Edge Cases**:
  - Extremely rare but theoretically possible: all ports in the dynamic range are occupied. The agent should report a clear error.

---

### `TC-sc-edge-api-concurrent-requests`: Multiple simultaneous API requests

- **Type**: Integration
- **Covers**: `FR-sc-file-api`
- **Preconditions**: The Vite dev server is running. Multiple valid file paths exist.
- **Steps**:
  1. Send 10 concurrent `GET /api/file?path=<path>` requests (each for a different file) using a tool like `ab` or `curl` in parallel.
  2. Inspect all responses.
- **Expected Result**: All 10 requests return 200 with the correct file content. No race conditions, no mixed-up responses, no crashes.
- **Edge Cases**:
  - 100 concurrent requests: server should handle this without degradation.

---

### `TC-sc-edge-file-deleted-after-validation`: File is deleted between agent validation and API request

- **Type**: Integration
- **Covers**: `FR-sc-file-validation`, `FR-sc-file-api`
- **Preconditions**: A file exists. The agent has validated it and opened the browser, but the file is then deleted before the web app fetches it via the API.
- **Steps**:
  1. Type `/shepherd tempfile.ts` (agent validates and opens browser).
  2. Before the browser finishes loading, delete `tempfile.ts`.
  3. Observe the CRPG in the browser.
- **Expected Result**: The CRPG's `GET /api/file` request returns 404. The drop zone shows the error variant: "File not found. It may have been moved or deleted." The drop zone is functional for manual file loading.
- **Edge Cases**:
  - This is a TOCTOU (time-of-check-time-of-use) scenario. It is expected and handled by design -- the agent validation is a convenience check; the API performs its own validation.

---

## Regression Considerations

### What existing functionality could this feature break?

The slash command introduces changes to the existing CRPG web application and adds a Vite plugin. The following existing features could be affected:

1. **File loading via drag-and-drop, upload, or paste**: The `App.tsx` modifications add URL parameter handling before the normal empty state rendering. If the `useFileFromUrl` hook has bugs in its "no parameter" path, it could interfere with the existing drop zone. **Regression test**: `TC-sc-auto-load-no-param` verifies that the app behaves identically to before when no `?file=` parameter is present.

2. **Session state (comments, preamble, prompt)**: The auto-load path calls `store.loadFile()` which resets all session state. If the hook fires unexpectedly (e.g., on URL changes within the app), it could clear a user's work. **Regression test**: `TC-sc-auto-load-clears-url-param` verifies the parameter is cleared from the URL after load, preventing re-execution on page interactions.

3. **Vite dev server configuration**: Adding the `fileApiPlugin` to `vite.config.ts` could potentially interfere with existing middleware or routing. **Regression test**: `TC-sc-auto-load-no-param` and general CRPG E2E tests should be run to ensure no regressions.

4. **Prompt output API and file API coexistence**: Adding the `/api/prompt-output` POST endpoint could interfere with the existing `/api/file` GET endpoint if route matching is not specific enough. **Regression test**: `TC-sc-prompt-api-no-collision` verifies both endpoints work independently.

5. **Watcher polling and file cleanup**: The file watcher uses simple polling with file deletion. If the cleanup logic has bugs, stale files could trigger false prompts on the next session. **Regression test**: `TC-sc-watcher-cleanup-stale` verifies stale files are removed before the watcher starts.

6. **Session isolation and concurrent sessions**: The move from a single fixed output path (`~/.shepherd/prompt-output.md`) to session-scoped paths (`~/.shepherd/sessions/<session-id>/prompt-output.md`) could break existing single-session workflows if the path migration is incomplete. **Regression tests**: `TC-sc-session-scoped-output-path` verifies the new path is used. `TC-sc-session-output-isolation` verifies concurrent sessions do not interfere.

7. **Dynamic port assignment**: The move from fixed port 5173 to dynamic ports could break URL construction, server detection, and server reuse logic. **Regression tests**: `TC-sc-dynamic-port` verifies dynamic ports work. `TC-sc-server-reuse-same-worktree` verifies server reuse still works within a worktree.

### Recommended regression suite

Run the following test cases as a minimum regression suite after any slash command changes:

- `TC-sc-auto-load-no-param` (existing app behavior is unaffected)
- `TC-sc-launch-happy-inrepo` (full end-to-end flow works)
- `TC-sc-api-200-valid-file` (file API serves content correctly)
- `TC-sc-api-404-not-found` (error handling works)
- `TC-sc-api-415-binary` (binary rejection works)
- `TC-sc-api-403-non-localhost` (security check works)
- `TC-sc-server-reuse-vite` (server reuse works)
- `TC-sc-session-clear-on-new-file` (session clearing works)
- `TC-sc-no-args-usage` (command argument handling works)
- `TC-sc-output-errors-stderr` (error output works)
- `TC-sc-launcher-warm-launch` (warm launch under 2s with launcher script)
- `TC-sc-single-tool-call` (single tool call execution via launcher script)
- `TC-sc-launcher-script-validation` (launcher script handles all validation)

Also run the existing CRPG regression suite from `qa/code-review-prompt.md`:
- `TC-crp-load-upload-happy`
- `TC-crp-add-comment-single-line-happy`
- `TC-crp-generate-prompt-structure-happy`
- `TC-crp-copy-clipboard-happy`
- `TC-crp-clear-confirmation-confirm-clears`

And the prompt feedback loop tests:
- `TC-sc-prompt-api-write-happy` (prompt output API writes to session-scoped path)
- `TC-sc-prompt-api-localhost-only` (security check works for prompt API)
- `TC-sc-prompt-api-no-collision` (prompt API doesn't break file API)
- `TC-sc-watcher-detects-file` (watcher detects prompt file in session directory)
- `TC-sc-watcher-cleanup-stale` (stale session cleanup works)
- `TC-sc-feedback-loop-e2e` (full end-to-end feedback loop)

And the session isolation tests:
- `TC-sc-session-id-generated` (session ID is generated and visible)
- `TC-sc-dynamic-port` (server uses dynamic port)
- `TC-sc-concurrent-sessions-happy` (two sessions run simultaneously)
- `TC-sc-session-output-isolation` (Done in one session doesn't affect another)
- `TC-sc-session-scoped-output-path` (output uses session-scoped path)
- `TC-sc-session-cleanup-after-read` (session directory cleaned up after use)
- `TC-sc-server-reuse-same-worktree` (server reused within same worktree)
- `TC-sc-window-title-shows-project` (window title shows project context)
