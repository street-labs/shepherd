# Slash Command Launcher -- Test Plan

> Based on requirements in `../product/slash-command.md`
> Based on design in `../design/slash-command.md`
> Based on technical spec in `../engineering/slash-command.md`

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
| `FR-sc-invoke-command` | `TC-sc-launch-happy-inrepo`, `TC-sc-no-args-usage` | Not started |
| `FR-sc-file-resolution` | `TC-sc-absolute-path-inrepo`, `TC-sc-resolve-relative-path`, `TC-sc-resolve-symlink` | Not started |
| `FR-sc-file-validation` | `TC-sc-file-not-found-cli`, `TC-sc-binary-rejected-cli`, `TC-sc-permission-denied-cli`, `TC-sc-directory-rejected-cli`, `TC-sc-large-file-warning-cli` | Not started |
| `FR-sc-app-serve` | `TC-sc-server-starts-vite`, `TC-sc-server-serves-static-assets` | Not started |
| `FR-sc-browser-open` | `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows` | Not started |
| `FR-sc-auto-load-file` | `TC-sc-auto-load-from-url-param`, `TC-sc-auto-load-clears-url-param`, `TC-sc-auto-load-error-state`, `TC-sc-auto-load-no-param` | Not started |
| `FR-sc-file-api` | `TC-sc-api-200-valid-file`, `TC-sc-api-400-missing-param`, `TC-sc-api-403-permission`, `TC-sc-api-403-non-localhost`, `TC-sc-api-404-not-found`, `TC-sc-api-404-directory`, `TC-sc-api-415-binary`, `TC-sc-api-headers` | Not started |
| `FR-sc-install` | `TC-sc-install-symlink`, `TC-sc-install-update-propagation`, `TC-sc-install-claude-code-command` | Not started |
| `FR-sc-output-feedback` | `TC-sc-output-success-format`, `TC-sc-output-reuse-note`, `TC-sc-output-errors-stderr` | Not started |
| `NFR-sc-launch-speed` | `TC-sc-launch-speed-cold`, `TC-sc-launch-speed-warm` | Not started |
| `NFR-sc-no-global-deps` | `TC-sc-install-symlink` | Not started |
| `NFR-sc-cross-platform` | `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-path-handling-windows` | Not started |
| `NFR-sc-localhost-only` | `TC-sc-api-403-non-localhost` | Not started |
| `NFR-sc-no-telemetry` | `TC-sc-no-outbound-network` | Not started |
| `NFR-sc-minimal-footprint` | `TC-sc-install-symlink` | Not started |

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
- **Expected Result**: The agent reports a URL (`http://localhost:5173?file=<encoded-path>`). The default browser opens to the CRPG with `App.tsx` loaded in the code viewer. Syntax highlighting shows TypeScript. The file name "App.tsx" is displayed in the file header.
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
  3. Verify the server is running by accessing `http://localhost:5173`.
- **Expected Result**: The agent detects no running server, starts it with `pnpm dev`, and then proceeds to open the browser with the file URL. The server serves the CRPG correctly.
- **Edge Cases**:
  - `pnpm` not installed: the agent should report a clear error.
  - Port 5173 already in use by another process: Vite's built-in port conflict handling increments the port (e.g., 5174). The agent should adapt to the actual port.

---

#### `TC-sc-server-serves-static-assets`: Vite dev server serves the CRPG web assets

- **Type**: Integration
- **Covers**: `FR-sc-app-serve`
- **Preconditions**: The Vite dev server is running.
- **Steps**:
  1. Send `GET /` to `http://localhost:5173`.
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
  2. Observe whether the default browser opens.
- **Expected Result**: The default macOS browser opens with the CRPG URL. The agent uses the `open` command.
- **Edge Cases**:
  - Default browser is not set: `open` command may fail; the agent should report the URL and a warning.

---

#### `TC-sc-cross-platform-linux`: Browser opens correctly on Linux

- **Type**: E2E
- **Covers**: `AC-sc-cross-platform-open`, `NFR-sc-cross-platform`, `FR-sc-browser-open`
- **Preconditions**: Running on Linux with `xdg-open` installed. The `/shepherd` command is available.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether the default browser opens.
- **Expected Result**: The default Linux browser opens. The agent uses `xdg-open`.
- **Edge Cases**:
  - Headless Linux server without `xdg-open`: the agent should report the URL and a warning: `Warning: Could not open the browser automatically. Open the URL above in your browser.` The server is still started and the file is still served.
  - Linux with Wayland vs X11: `xdg-open` should work in both environments.

---

#### `TC-sc-cross-platform-windows`: Browser opens correctly on Windows

- **Type**: E2E
- **Covers**: `AC-sc-cross-platform-open`, `NFR-sc-cross-platform`, `FR-sc-browser-open`
- **Preconditions**: Running on Windows. The `/shepherd` command is available.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe whether the default browser opens.
- **Expected Result**: The default Windows browser opens. The agent uses `cmd /c start`.
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

### Performance

---

#### `TC-sc-launch-speed-cold`: Cold launch completes quickly

- **Type**: E2E / Performance
- **Covers**: `NFR-sc-launch-speed`
- **Preconditions**: The Vite dev server is not running.
- **Steps**:
  1. Type `/shepherd somefile.ts` in Claude Code.
  2. Observe the time from invocation to browser opening.
- **Expected Result**: The agent completes file validation, starts the Vite dev server, and opens the browser within a reasonable time. Vite's dev server starts quickly since it does not require a full build.
- **Edge Cases**:
  - Cold filesystem cache (first run after reboot): may be slightly slower due to disk I/O.

---

#### `TC-sc-launch-speed-warm`: Warm launch (server reuse) completes quickly

- **Type**: E2E / Performance
- **Covers**: `NFR-sc-launch-speed`
- **Preconditions**: The Vite dev server is already running from a previous invocation.
- **Steps**:
  1. Type `/shepherd anotherfile.ts` in Claude Code.
  2. Observe the time from invocation to browser opening.
- **Expected Result**: The agent completes file validation and opens the browser quickly. Expected to be faster than cold start (no server startup needed).
- **Edge Cases**:
  - N/A (focused performance test).

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

### `TC-sc-edge-port-in-use`: Default Vite port is occupied by another process

- **Type**: Unit
- **Covers**: `FR-sc-app-serve`
- **Preconditions**: Another process is listening on port 5173.
- **Steps**:
  1. Start another process listening on port 5173.
  2. Type `/shepherd somefile.ts` in Claude Code.
  3. Observe the agent's behavior.
- **Expected Result**: Vite's built-in port conflict handling increments the port (e.g., 5174). The agent should adapt to the actual port.
- **Edge Cases**:
  - N/A (focused test).

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

Also run the existing CRPG regression suite from `qa/code-review-prompt.md`:
- `TC-crp-load-upload-happy`
- `TC-crp-add-comment-single-line-happy`
- `TC-crp-generate-prompt-structure-happy`
- `TC-crp-copy-clipboard-happy`
- `TC-crp-clear-confirmation-confirm-clears`
