# Shepherd Review -- Test Plan

> Based on requirements in `../product/shepherd-review.md`
> Based on design in `../design/shepherd-review.md`
> Based on technical spec in `../engineering/shepherd-review.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sr-happy-path` | `TC-sr-happy-path-full-loop` | Not started |
| `AC-sr-filters-lockfiles` | `TC-sr-filters-lockfiles` | Not started |
| `AC-sr-filters-generated` | `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions` | Not started |
| `AC-sr-filters-binary` | `TC-sr-filters-binary` | Not started |
| `AC-sr-includes-config` | `TC-sr-includes-config-files` | Not started |
| `AC-sr-excludes-deleted` | `TC-sr-excludes-deleted-files` | Not started |
| `AC-sr-skip-file` | `TC-sr-skip-file` | Not started |
| `AC-sr-quit-early` | `TC-sr-quit-early` | Not started |
| `AC-sr-no-changes` | `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence` | Not started |
| `AC-sr-all-filtered` | `TC-sr-all-filtered` | Not started |
| `AC-sr-not-git-repo` | `TC-sr-not-git-repo` | Not started |
| `AC-sr-invokes-shepherd` | `TC-sr-invokes-shepherd-per-file` | Not started |
| `AC-sr-list-command` | `TC-sr-list-command-mid-review` | Not started |
| `AC-sr-completion-summary` | `TC-sr-completion-summary-full`, `TC-sr-completion-summary-quit-early` | Not started |
| `AC-sr-sorted-file-list` | `TC-sr-sorted-file-list` | Not started |
| `AC-sr-install-global` | `TC-sr-install-global-symlink` | Not started |
| `FR-sr-changeset-detection` | `TC-sr-happy-path-full-loop`, `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`, `TC-sr-changeset-merge-base`, `TC-sr-renamed-files` | Not started |
| `FR-sr-file-filtering` | `TC-sr-filters-lockfiles`, `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`, `TC-sr-filters-binary`, `TC-sr-filters-ide-files`, `TC-sr-filters-snapshot-files`, `TC-sr-includes-config-files`, `TC-sr-unknown-file-included` | Not started |
| `FR-sr-file-list-display` | `TC-sr-file-list-format`, `TC-sr-sorted-file-list`, `TC-sr-file-list-exclusion-count` | Not started |
| `FR-sr-iteration-loop` | `TC-sr-happy-path-full-loop`, `TC-sr-skip-file`, `TC-sr-quit-early`, `TC-sr-list-command-mid-review`, `TC-sr-user-input-synonyms`, `TC-sr-unrecognized-input` | Not started |
| `FR-sr-completion-summary` | `TC-sr-completion-summary-full`, `TC-sr-completion-summary-quit-early`, `TC-sr-completion-summary-all-skipped` | Not started |
| `FR-sr-command-file` | `TC-sr-command-file-exists` | Not started |
| `FR-sr-install` | `TC-sr-install-global-symlink` | Not started |
| `FR-sr-no-args` | `TC-sr-happy-path-full-loop` | Not started |
| `FR-sr-git-required` | `TC-sr-not-git-repo` | Not started |
| `NFR-sr-startup-speed` | `TC-sr-startup-speed` | Not started |
| `NFR-sr-no-dependencies` | `TC-sr-no-external-dependencies` | Not started |
| `NFR-sr-agent-native` | `TC-sr-happy-path-full-loop` | Not started |
| `NFR-sr-cross-platform` | `TC-sr-cross-platform-git-commands` | Not started |

---

## Test Cases

---

### Happy Path and Core Loop

---

#### `TC-sr-happy-path-full-loop`: Full review loop from start to finish

- **Type**: Manual
- **Covers**: `AC-sr-happy-path`, `FR-sr-changeset-detection`, `FR-sr-iteration-loop`, `FR-sr-no-args`, `NFR-sr-agent-native`
- **Preconditions**: The user is on a feature branch that has 5 modified source files (e.g., `.ts`, `.tsx`, `.py`) and 3 excluded files (e.g., `package-lock.json`, `dist/bundle.js`, `logo.png`) relative to `main`. The `/shepherd` command is installed and functional. The CRPG dev server is running or will be started by `/shepherd`.
- **Steps**:
  1. Open a Claude Code session inside the repository.
  2. Type `/shepherd-review`.
  3. Observe the agent output. Verify the file list shows "Found 5 files to review" with a numbered list of the 5 source files, a note "3 files excluded (lockfiles, generated, binary)", and the prompt "Ready to start? Say "go" to begin, or "quit" to cancel."
  4. Type "go".
  5. Observe the agent announces file 1 with the format `[1/5] <path>  [<change-type>]` followed by "Opening in the Code Review Prompt Generator..." and then invokes `/shepherd` with the absolute path.
  6. After the file loads in the browser, observe the user prompt with the menu (next, skip, list, quit).
  7. Type "next".
  8. Repeat steps 5-7 for files 2 through 4.
  9. For file 5, type "next" after reviewing.
  10. Observe the completion summary.
- **Expected Result**: All 5 files are iterated in order. For each file, `/shepherd` is invoked and the CRPG opens in the browser. The completion summary shows:
  ```
  Review complete.
    8 files in changeset
    3 filtered out (lockfiles, generated, binary)
    5 files to review
    5 reviewed
    0 skipped
  ```
  No "remaining" line appears because the review completed fully.
- **Edge Cases**:
  - User types "done" or "continue" instead of "next": should be recognized as synonyms and advance to the next file.
  - User types "n" (single character): should be recognized as "next".

---

#### `TC-sr-invokes-shepherd-per-file`: Each file is opened via the /shepherd command

- **Type**: Manual
- **Covers**: `AC-sr-invokes-shepherd`, `FR-sr-iteration-loop`
- **Preconditions**: A feature branch with at least 2 reviewable files. The file `src/utils.ts` is one of them. `/shepherd` is installed.
- **Steps**:
  1. Run `/shepherd-review` and type "go" to start.
  2. When the iteration reaches `src/utils.ts`, observe the agent output.
  3. Verify the browser opens with the CRPG showing `src/utils.ts`.
- **Expected Result**: The agent invokes `/shepherd <absolute-path-to-src/utils.ts>`. The absolute path is constructed by combining the repo root (from `git rev-parse --show-toplevel`) with the relative path `src/utils.ts`. The CRPG opens in the browser with `src/utils.ts` loaded. The file announcement shows `[<position>/<total>] src/utils.ts  [modified]` (or `[added]` etc. depending on change type).
- **Edge Cases**:
  - If `/shepherd` reports an error for one file (e.g., the file was deleted between detection and iteration), the error is displayed and the user prompt still appears, allowing the user to say "next" to continue.
  - The file path uses forward slashes on all platforms in the display, but the absolute path passed to `/shepherd` uses the OS-native separator.

---

### File Filtering

---

#### `TC-sr-filters-lockfiles`: Lockfiles are excluded from the review list

- **Type**: Manual
- **Covers**: `AC-sr-filters-lockfiles`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `package-lock.json`, `pnpm-lock.yaml`, and at least one reviewable source file (e.g., `src/index.ts`).
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: Neither `package-lock.json` nor `pnpm-lock.yaml` appears in the numbered file list. The exclusion count includes them (e.g., "2 files excluded (lockfiles, generated, binary)"). Only `src/index.ts` (and any other non-excluded files) appears in the review list.
- **Edge Cases**:
  - `yarn.lock`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`: all should be excluded.
  - A file named `my-lock.json` (contains "lock" but is not a recognized lockfile): should NOT be excluded.
  - A file named `package-lock.json` nested inside a subdirectory (e.g., `packages/foo/package-lock.json`): should still be excluded.

---

#### `TC-sr-filters-generated-dirs`: Files in generated/build directories are excluded

- **Type**: Manual
- **Covers**: `AC-sr-filters-generated`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes files at `dist/bundle.js`, `build/output.css`, `.next/static/chunk.js`, `coverage/lcov.info`, `__generated__/types.ts`, and `node_modules/lodash/index.js`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: None of the files in `dist/`, `build/`, `.next/`, `coverage/`, `__generated__/`, or `node_modules/` appear in the review list. All are counted in the exclusion total.
- **Edge Cases**:
  - A file in `out/` directory (e.g., `out/index.html`): should be excluded.
  - A file in a directory named `distribution/` (not `dist/`): should NOT be excluded.
  - A deeply nested path like `packages/foo/dist/bar.js`: should be excluded because it contains a `dist/` segment.

---

#### `TC-sr-filters-generated-extensions`: Generated file extensions and naming patterns are excluded

- **Type**: Manual
- **Covers**: `AC-sr-filters-generated`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `app.min.js`, `styles.min.css`, `source.map`, `types.d.ts`, `schema.generated.ts`, `api.auto.ts`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: All of `app.min.js`, `styles.min.css`, `source.map`, `types.d.ts`, `schema.generated.ts`, and `api.auto.ts` are excluded from the review list.
- **Edge Cases**:
  - A file named `my-generator.ts` (contains "generated" as a substring but does not match the `*.generated.*` pattern): should NOT be excluded.
  - A file named `auto-format.ts` (contains "auto" but does not match `*.auto.*`): should NOT be excluded.
  - A file named `index.d.tsx` (not `.d.ts`): should NOT be excluded by the `.d.ts` rule.

---

#### `TC-sr-filters-binary`: Binary files are excluded from the review list

- **Type**: Manual
- **Covers**: `AC-sr-filters-binary`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `logo.png`, `font.woff2`, `archive.zip`, and `app.pdf`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: None of the binary files appear in the review list. All are counted in the exclusion total.
- **Edge Cases**:
  - `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.woff`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.tar`, `.gz`, `.exe`, `.dll`, `.so`, `.dylib`: all should be excluded.
  - A file with extension `.bin`: should NOT be excluded (not in the explicit list) unless it matches another rule.
  - A file named `README.png.md` (`.md` is the actual extension): should NOT be excluded.

---

#### `TC-sr-filters-ide-files`: IDE and editor configuration files are excluded

- **Type**: Manual
- **Covers**: `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `.idea/workspace.xml`, `.vscode/settings.json`, `.vscode/launch.json`, and `.DS_Store`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: All IDE/editor files are excluded from the review list.
- **Edge Cases**:
  - `.vscode/extensions.json`: the product spec only lists `settings.json` and `launch.json` under `.vscode/`; other `.vscode/` files may or may not be excluded depending on how broadly the rule is interpreted. Flag if behavior is ambiguous.
  - A file named `.DS_Store` in a subdirectory (e.g., `src/.DS_Store`): should still be excluded.

---

#### `TC-sr-filters-snapshot-files`: Snapshot/test snapshot files are excluded

- **Type**: Manual
- **Covers**: `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `__tests__/Button.test.tsx.snap` and `login.snapshot`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: Both `.snap` and `.snapshot` files are excluded.
- **Edge Cases**:
  - A file named `snapshot-utils.ts` (the word "snapshot" is in the filename, but the extension is `.ts`): should NOT be excluded.

---

#### `TC-sr-includes-config-files`: Meaningful config files are included in the review list

- **Type**: Manual
- **Covers**: `AC-sr-includes-config`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `vite.config.ts`, `tsconfig.json`, `package.json`, `jest.config.js`, `eslint.config.mjs`, `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows/ci.yml`, `.claude/commands/shepherd.md`, and `Makefile`.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: All of the above config files appear in the numbered review list. None are excluded by filtering.
- **Edge Cases**:
  - `tsconfig.build.json` (matches `tsconfig.*.json`): should be included.
  - `vitest.config.ts` (matches `vitest.config.*`): should be included.
  - `babel.config.js`, `rollup.config.mjs`, `esbuild.config.ts`: should be included.
  - `webpack.config.js`: should be included.
  - `go.mod`, `Cargo.toml`, `pyproject.toml`: should be included.
  - `.gitlab-ci.yml`, `Jenkinsfile`: should be included.

---

#### `TC-sr-unknown-file-included`: Files not matching any exclusion rule are included

- **Type**: Manual
- **Covers**: `FR-sr-file-filtering`
- **Preconditions**: The changeset includes a file with an uncommon extension (e.g., `data.csv`, `notes.txt`, `config.toml`).
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: Files that do not match any exclusion pattern are included in the review list. The filtering is allowlist-on-top-of-denylist: if a file is not explicitly excluded, it is included.
- **Edge Cases**:
  - A file with no extension (e.g., `Procfile`, `LICENSE`): should be included.
  - A dotfile that is not an IDE config (e.g., `.gitignore`, `.npmrc`): should be included.

---

#### `TC-sr-excludes-deleted-files`: Deleted files do not appear in the review list

- **Type**: Manual
- **Covers**: `AC-sr-excludes-deleted`, `FR-sr-changeset-detection`
- **Preconditions**: The changeset includes a file that exists on `main` but has been deleted on the current branch, plus at least one modified file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list output.
- **Expected Result**: The deleted file does not appear in the numbered review list. It is counted in the total changeset count and in the exclusion count (per design spec, deleted files are included in `<T>` and `<E>`).
- **Edge Cases**:
  - Multiple deleted files: none should appear in the review list.
  - A file that was deleted and then re-added with different content (git shows as D+A or as M): should appear as modified or added, not deleted.

---

### File List Display and Sorting

---

#### `TC-sr-file-list-format`: File list matches the specified format

- **Type**: Manual
- **Covers**: `FR-sr-file-list-display`
- **Preconditions**: A branch with at least 3 reviewable files and at least 1 excluded file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Inspect the output format.
- **Expected Result**: The output matches this structure exactly:
  ```
  Found <N> files to review.

    1. <relative-path>  [<change-type>]
    2. <relative-path>  [<change-type>]
    ...

  <M> files excluded (lockfiles, generated, binary).

  Ready to start? Say "go" to begin, or "quit" to cancel.
  ```
  Blank lines separate the count, list, exclusion note, and prompt. Change types are one of `modified`, `added`, or `renamed from <old-path>`. Position numbers are right-aligned when there are 10 or more files.
- **Edge Cases**:
  - Zero excluded files: the exclusion line is omitted entirely.
  - Exactly 1 excluded file: the line reads "1 files excluded (lockfiles, generated, binary)." (uses "files" not "file" -- or verify against the design spec's exact wording).
  - 10+ files: position numbers are padded (e.g., ` 1.` through `12.`).

---

#### `TC-sr-sorted-file-list`: Files are sorted by directory then by name alphabetically

- **Type**: Manual
- **Covers**: `AC-sr-sorted-file-list`, `FR-sr-file-list-display`
- **Preconditions**: The changeset includes `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `README.md`, and `src/components/Button.tsx`.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the ordering of files in the numbered list.
- **Expected Result**: The files are sorted as:
  ```
    1. README.md                          [modified]
    2. lib/helpers.ts                     [added]
    3. src/app.tsx                        [modified]
    4. src/components/Button.tsx           [added]
    5. src/utils.ts                       [modified]
  ```
  Root-level files come first, then directories sorted alphabetically, then files within each directory sorted alphabetically. Files in a parent directory sort before files in its subdirectories.
- **Edge Cases**:
  - Case sensitivity: sorting should be case-insensitive (e.g., `README.md` sorts near `readme.md`, not in a separate block).
  - Deeply nested files: `src/components/forms/Input.tsx` sorts after `src/components/Button.tsx`.
  - Files at the same directory depth but different directories: `api/routes.ts` sorts before `src/app.ts`.

---

#### `TC-sr-file-list-exclusion-count`: Exclusion count accurately reflects filtered files

- **Type**: Manual
- **Covers**: `FR-sr-file-list-display`, `FR-sr-file-filtering`
- **Preconditions**: The changeset has 10 total files: 4 source files, 2 lockfiles, 1 binary, 1 generated, 1 deleted, 1 snapshot.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the exclusion count and the file list count.
- **Expected Result**: The file list shows "Found 4 files to review." The exclusion count shows "6 files excluded (lockfiles, generated, binary)." The total (4 + 6 = 10) matches the total changeset count. Deleted files are included in the exclusion count, not shown separately.
- **Edge Cases**:
  - All files are excluded: handled by `TC-sr-all-filtered`.
  - No files are excluded: the exclusion line is omitted.

---

#### `TC-sr-renamed-files`: Renamed files show old path and use new path for review

- **Type**: Manual
- **Covers**: `FR-sr-changeset-detection`, `FR-sr-file-list-display`
- **Preconditions**: The changeset includes a file renamed from `src/helpers.ts` to `src/utils/helpers.ts`.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the file list entry for the renamed file.
  3. Start the review and advance to the renamed file.
- **Expected Result**: The file list shows:
  ```
    3. src/utils/helpers.ts               [renamed from src/helpers.ts]
  ```
  When the file is opened for review, `/shepherd` is invoked with the absolute path to `src/utils/helpers.ts` (the new path, which exists on disk).
- **Edge Cases**:
  - A file renamed with content changes (git reports as rename with a similarity index): should still show as renamed.
  - A file renamed to a different directory: the new path is used for display and for invoking `/shepherd`.

---

### Iteration Control

---

#### `TC-sr-skip-file`: User can skip a file during iteration

- **Type**: Manual
- **Covers**: `AC-sr-skip-file`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 5 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. For file 1, type "next" (review normally).
  3. For file 2, type "skip".
  4. Observe the agent advances to file 3.
  5. Complete the remaining files with "next".
  6. Observe the completion summary.
- **Expected Result**: After typing "skip" for file 2, the agent immediately moves to file 3 with the announcement `[3/5] <path>  [<change-type>]`. Note: per the design spec, `/shepherd` has already been invoked for file 2 before the prompt appears, so the file was opened in the browser. The "skip" is a bookkeeping distinction. The completion summary shows:
  ```
  Review complete.
    ...
    5 files to review
    4 reviewed
    1 skipped
  ```
- **Edge Cases**:
  - "skip this" and "pass" should be recognized as synonyms for "skip".
  - Skipping the last file: the summary appears immediately after the skip, with the file counted as skipped.
  - Skipping all files: see `TC-sr-completion-summary-all-skipped`.

---

#### `TC-sr-quit-early`: User can quit the review before completing all files

- **Type**: Manual
- **Covers**: `AC-sr-quit-early`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 5 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. For file 1, type "next".
  3. For file 2, type "next".
  4. For file 3, type "quit".
  5. Observe the completion summary.
- **Expected Result**: The review ends immediately after "quit" is typed on file 3. File 3 counts as "reviewed" (since `/shepherd` was already invoked for it). The summary shows:
  ```
  Review complete.
    <T> files in changeset
    <E> filtered out (lockfiles, generated, binary)
    5 files to review
    3 reviewed
    0 skipped
    2 remaining (quit early)
  ```
- **Edge Cases**:
  - "stop", "exit", "q", "quit review" should all be recognized as synonyms for "quit".
  - Quitting on the very first file: 1 reviewed, 0 skipped, N-1 remaining.
  - Quitting on the last file: 0 remaining, same as completing normally (file is counted as reviewed).

---

#### `TC-sr-list-command-mid-review`: User can re-display the file list during iteration

- **Type**: Manual
- **Covers**: `AC-sr-list-command`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with 7 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. Advance to file 3 by typing "next" for files 1 and 2.
  3. On file 3, type "list".
  4. Observe the re-displayed file list.
  5. Type "next" to continue with file 3.
- **Expected Result**: After typing "list", the agent re-displays the full numbered file list with file 3 indicated by a `>` character:
  ```
    1. README.md                          [modified]
    2. lib/helpers.ts                     [added]
  > 3. src/app.tsx                        [modified]
    4. src/components/Button.tsx           [added]
    5. src/index.ts                       [modified]
    6. src/styles.css                     [modified]
    7. tests/app.test.tsx                 [added]

  Currently reviewing file 3 of 7.
  ```
  After the list display, the user prompt (with next/skip/list/quit options) appears again for file 3. The `/shepherd` command is NOT re-invoked. Typing "next" advances to file 4.
- **Edge Cases**:
  - "show files", "show list", and "files" should be recognized as synonyms for "list".
  - Typing "list" on the first file: file 1 is indicated.
  - Typing "list" on the last file: the last file is indicated.
  - Typing "list" multiple times in a row: the list is displayed each time, no state change.

---

#### `TC-sr-user-input-synonyms`: All documented synonyms are recognized

- **Type**: Manual
- **Covers**: `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 3 reviewable files.
- **Steps**:
  1. Run `/shepherd-review`.
  2. At the pre-iteration prompt, test each synonym for "go": type "yes", "start", "y", "ok", "begin", "ready" (one per test run or by restarting). Verify each starts the iteration.
  3. During iteration, test each synonym for "next": "done", "continue", "n", "next file". Verify each advances to the next file.
  4. During iteration, test each synonym for "skip": "skip this", "pass". Verify each skips the file.
  5. During iteration, test each synonym for "list": "show files", "show list", "files". Verify each shows the file list.
  6. During iteration, test each synonym for "quit": "stop", "exit", "q", "quit review", "cancel", "no". Verify each ends the review.
- **Expected Result**: All synonyms listed in the design spec's User Input Recognition table are recognized. Input matching is case-insensitive (e.g., "Go", "GO", "gO" all work).
- **Edge Cases**:
  - Leading/trailing whitespace in user input (e.g., " next "): should be trimmed and recognized.
  - Input with extra words (e.g., "please next"): may or may not be recognized. Document observed behavior.

---

#### `TC-sr-unrecognized-input`: Unrecognized input produces a help message

- **Type**: Manual
- **Covers**: `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 1 reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. At the pre-iteration prompt, type "banana".
  3. Observe the agent response.
  4. Start the review by typing "go".
  5. During iteration, type "banana".
  6. Observe the agent response.
- **Expected Result**: At the pre-iteration prompt, the agent responds:
  ```
  I did not understand that. Say "go" to begin the review, or "quit" to cancel.

  >
  ```
  During iteration, the agent responds:
  ```
  I did not understand that. Your options are:

    next     Move to the next file
    skip     Skip this file
    list     Show the file list
    quit     End the review

  >
  ```
  The agent remains on the same file and waits for valid input. No state change occurs.
- **Edge Cases**:
  - Empty input (user presses enter with no text): should produce the unrecognized input message.
  - Very long input (100+ characters of gibberish): should produce the same message without error.

---

#### `TC-sr-cancel-before-start`: User cancels at the pre-iteration prompt

- **Type**: Manual
- **Covers**: `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 1 reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. The file list is displayed with the "Ready to start?" prompt.
  3. Type "quit" (or "no", "cancel", "stop", "exit", "q").
- **Expected Result**: The agent outputs:
  ```
  Review cancelled.
  ```
  No summary is displayed. No files are iterated. The command ends.
- **Edge Cases**:
  - Typing "quit" vs "no" vs "cancel" at the pre-iteration prompt: all should cancel.

---

### Error Scenarios and Boundary Conditions

---

#### `TC-sr-not-git-repo`: Error when invoked outside a git repository

- **Type**: Manual
- **Covers**: `AC-sr-not-git-repo`, `FR-sr-git-required`
- **Preconditions**: The working directory is not inside a git repository (e.g., `/tmp/not-a-repo/`).
- **Steps**:
  1. Open a Claude Code session with the working directory set to a non-git directory.
  2. Type `/shepherd-review`.
- **Expected Result**: The agent outputs exactly:
  ```
  Not a git repository. /shepherd-review must be run from within a git repo.
  ```
  No file list is displayed. No iteration occurs. The command stops.
- **Edge Cases**:
  - A directory that used to be a git repo but had `.git/` removed: should show the same error.
  - A subdirectory of a git repo (e.g., `repo/src/`): should work correctly (git searches upward).

---

#### `TC-sr-no-changes-on-main`: No changes when on the main branch itself

- **Type**: Manual
- **Covers**: `AC-sr-no-changes`, `FR-sr-changeset-detection`
- **Preconditions**: The user is checked out on `main` (or the branch has no divergence from main).
- **Steps**:
  1. Run `git checkout main`.
  2. Type `/shepherd-review`.
- **Expected Result**: The agent outputs:
  ```
  No changes found relative to main.
  ```
  No file list is displayed. No iteration occurs.
- **Edge Cases**:
  - Branch named `main` with uncommitted changes (not yet committed): the changeset detection uses committed differences, so uncommitted changes are not included. The command should report no changes.
  - Freshly created branch off main with zero commits: should report no changes.

---

#### `TC-sr-no-changes-no-divergence`: No changes when branch has no divergence

- **Type**: Manual
- **Covers**: `AC-sr-no-changes`, `FR-sr-changeset-detection`
- **Preconditions**: A branch was created from `main` but no commits have been made on it.
- **Steps**:
  1. Run `git checkout -b test-branch-no-changes` from `main`.
  2. Type `/shepherd-review`.
- **Expected Result**: The agent outputs:
  ```
  No changes found relative to main.
  ```
- **Edge Cases**:
  - A branch that was once ahead of main but has since been fully merged (main caught up): should report no changes if there is no diff.

---

#### `TC-sr-all-filtered`: All files in the changeset are filtered out

- **Type**: Manual
- **Covers**: `AC-sr-all-filtered`, `FR-sr-file-filtering`
- **Preconditions**: The changeset contains only `package-lock.json`, `yarn.lock`, `dist/bundle.js`, and `logo.png` (all excluded by filtering rules).
- **Steps**:
  1. Run `/shepherd-review`.
- **Expected Result**: The agent outputs:
  ```
  No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary).
  ```
  No file list is displayed. No iteration occurs.
- **Edge Cases**:
  - Changeset with exactly 1 file that is excluded: should show "All 1 changed files were filtered out."
  - A mix of deleted files and excluded files (all filtered for different reasons): the total count reflects all of them.

---

#### `TC-sr-changeset-merge-base`: Changeset uses merge base, not tip of main

- **Type**: Manual
- **Covers**: `FR-sr-changeset-detection`
- **Preconditions**: The feature branch was created from `main` at commit A. Since then, `main` has advanced to commit B with new files. The feature branch has its own changes that do not overlap with main's new files.
- **Steps**:
  1. Verify that `main` has commits not on the feature branch.
  2. Run `/shepherd-review` from the feature branch.
  3. Examine the file list.
- **Expected Result**: The file list only contains files changed by the feature branch (relative to the merge base), NOT files that were changed on `main` since the branch point. The `git merge-base` approach ensures only the branch's own changes are shown.
- **Edge Cases**:
  - Merge commits on the feature branch (branch merged main into itself): the merge base may shift. The command should still show only the branch's net changes.

---

### Completion Summary

---

#### `TC-sr-completion-summary-full`: Summary after completing all files

- **Type**: Manual
- **Covers**: `AC-sr-completion-summary`, `FR-sr-completion-summary`
- **Preconditions**: A branch with 10 total files, 3 excluded, 7 reviewable. User reviews 6 and skips 1.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. Type "next" for files 1-3.
  3. Type "skip" for file 4.
  4. Type "next" for files 5-7.
  5. Observe the completion summary.
- **Expected Result**: The summary displays:
  ```
  Review complete.
    10 files in changeset
     3 filtered out (lockfiles, generated, binary)
     7 files to review
     6 reviewed
     1 skipped
  ```
  No "remaining" line appears. Numbers are right-aligned.
- **Edge Cases**:
  - All 7 files reviewed with zero skips: the "skipped" line shows 0 (or is omitted -- verify against the design spec).
  - Zero excluded files: the "filtered out" line is omitted.

---

#### `TC-sr-completion-summary-quit-early`: Summary after quitting early

- **Type**: Manual
- **Covers**: `AC-sr-completion-summary`, `FR-sr-completion-summary`, `AC-sr-quit-early`
- **Preconditions**: A branch with 12 total files, 5 excluded, 7 reviewable.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. Type "next" for files 1-3.
  3. Type "skip" for file 4.
  4. Type "quit" on file 5.
  5. Observe the completion summary.
- **Expected Result**: The summary displays:
  ```
  Review complete.
    12 files in changeset
     5 filtered out (lockfiles, generated, binary)
     7 files to review
     4 reviewed
     1 skipped
     2 remaining (quit early)
  ```
  File 5 counts as "reviewed" (since `/shepherd` was invoked before the quit). Files 6 and 7 are "remaining".
- **Edge Cases**:
  - Quitting on the first file: 1 reviewed, 0 skipped, N-1 remaining.
  - Quitting after skipping every file: 0 reviewed, N-1 skipped (for files before quit), 1 remaining (or 0 if quit is on the last file).

---

#### `TC-sr-completion-summary-all-skipped`: Summary when every file is skipped

- **Type**: Manual
- **Covers**: `FR-sr-completion-summary`
- **Preconditions**: A branch with 3 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and type "go".
  2. Type "skip" for every file.
  3. Observe the completion summary.
- **Expected Result**: The summary displays:
  ```
  Review complete.
    ...
    3 files to review
    0 reviewed
    3 skipped
  ```
  The review completes normally (no "remaining" line) since all files were processed, just skipped.
- **Edge Cases**:
  - This is an unusual but valid workflow. The command should not warn or behave differently.

---

### Installation

---

#### `TC-sr-install-global-symlink`: Install script creates the symlink for shepherd-review

- **Type**: Manual
- **Covers**: `AC-sr-install-global`, `FR-sr-install`
- **Preconditions**: The repository is cloned. `~/.claude/commands/shepherd-review.md` does not exist (or will be overwritten). The `scripts/install-command.sh` script exists and is executable.
- **Steps**:
  1. Run `./scripts/install-command.sh`.
  2. Check that `~/.claude/commands/shepherd-review.md` exists.
  3. Verify it is a symlink pointing to `<repo>/.claude/commands/shepherd-review.md`.
  4. Type `/shepherd-review` in a Claude Code session (in any git repository) to verify the command is available.
- **Expected Result**: The symlink exists at `~/.claude/commands/shepherd-review.md` and points to the correct file in the repository. The `/shepherd-review` command is recognized by Claude Code and begins execution (git check, changeset detection, etc.).
- **Edge Cases**:
  - Running the install script when the symlink already exists: should overwrite or re-create the symlink without error.
  - Running the install script when `~/.claude/commands/` directory does not exist: the script should create the directory.
  - After `git pull` updates the command file: the symlink should automatically reflect the changes (since it points to the repo file).

---

#### `TC-sr-command-file-exists`: The command file exists at the expected path

- **Type**: Manual
- **Covers**: `FR-sr-command-file`
- **Preconditions**: The repository is cloned.
- **Steps**:
  1. Check that `.claude/commands/shepherd-review.md` exists in the repository.
  2. Verify it is a markdown file containing prompt instructions (not empty).
- **Expected Result**: The file exists, is non-empty, and contains instructions that the AI coding agent can execute. The file follows the same pattern as `.claude/commands/shepherd.md`.
- **Edge Cases**:
  - File permissions: the file should be readable (644 or similar).

---

### Non-Functional Requirements

---

#### `TC-sr-startup-speed`: Changeset detection completes in under 3 seconds

- **Type**: Manual
- **Covers**: `NFR-sr-startup-speed`
- **Preconditions**: A repository with up to 1,000 changed files on the feature branch relative to main.
- **Steps**:
  1. Create or use a branch with a large changeset (several hundred files).
  2. Run `/shepherd-review`.
  3. Measure the time from invocation to the file list being displayed.
- **Expected Result**: The file list is displayed within 3 seconds. The bottleneck is the `git diff` and `git merge-base` commands, which are fast even for large repositories.
- **Edge Cases**:
  - Very large repository (monorepo with 100,000+ files but only 50 changed): should still be fast because `git diff` only reports changed files.
  - Repository with extensive rename detection (many files moved): rename detection can be slow; verify the command does not time out.

---

#### `TC-sr-no-external-dependencies`: No additional dependencies beyond git and /shepherd

- **Type**: Manual
- **Covers**: `NFR-sr-no-dependencies`
- **Preconditions**: The command file exists.
- **Steps**:
  1. Read the `.claude/commands/shepherd-review.md` file.
  2. Verify it only references git commands, standard shell utilities, and the `/shepherd` command.
  3. Verify no npm packages, binaries, or external tools are required.
- **Expected Result**: The command file is pure prompt engineering. It instructs the agent to use `git` (for changeset detection), standard shell (for path manipulation), and `/shepherd` (for per-file review). No additional dependencies are introduced.
- **Edge Cases**:
  - If the prompt instructs the agent to run `jq`, `python`, `node`, or any non-standard utility: this would be a failure.

---

#### `TC-sr-cross-platform-git-commands`: Git commands work across platforms

- **Type**: Manual
- **Covers**: `NFR-sr-cross-platform`
- **Preconditions**: Access to macOS, Linux, and Windows (Git Bash or WSL) environments.
- **Steps**:
  1. On each platform, set up a git repository with a feature branch.
  2. Run `/shepherd-review`.
  3. Verify the file list is displayed correctly.
- **Expected Result**: The git commands used (`git rev-parse`, `git merge-base`, `git diff --name-status`) work identically on all three platforms. File paths in the display use forward slashes on all platforms.
- **Edge Cases**:
  - Windows paths with backslashes: the display should normalize to forward slashes.
  - Git Bash vs. WSL on Windows: both should work.

---

## Edge Cases & Error Scenarios

---

### Git Edge Cases

#### Detached HEAD state
- **Trigger**: The user runs `git checkout <commit-hash>` (detached HEAD) and then runs `/shepherd-review`.
- **Expected behavior**: The command should either detect the changeset relative to `main` (if the detached HEAD is not on main) or report "No changes found relative to main." The command should not crash or produce an unclear error.
- **Test case**: `TC-sr-detached-head`

#### Shallow clone
- **Trigger**: The repository is a shallow clone (`git clone --depth 1`). The merge base with `main` may not be available.
- **Expected behavior**: The `git merge-base` command may fail because the history is incomplete. The command should produce a clear error message rather than an opaque git error.
- **Test case**: `TC-sr-shallow-clone`

#### No `main` branch
- **Trigger**: The repository uses `master` or another branch name as the default branch. There is no branch named `main`.
- **Expected behavior**: The `git merge-base HEAD main` command fails because `main` does not exist. The command should report a clear error (e.g., "Could not find base branch 'main'.") rather than a raw git error. Per the product spec, v1 assumes `main`; this is a known limitation.
- **Test case**: `TC-sr-no-main-branch`

#### Merge conflicts in progress
- **Trigger**: The user is in the middle of a merge or rebase (merge conflicts exist).
- **Expected behavior**: The command should still detect the changeset. Conflicted files should appear in the list if they are modified. The command should not fail because of the merge state.
- **Test case**: `TC-sr-merge-in-progress`

---

### Filtering Boundary Cases

#### File at the boundary of exclusion rules
- **Trigger**: A file named `package.json` (included by the config inclusion rule) vs. `package-lock.json` (excluded by the lockfile rule). Both are in the changeset.
- **Expected behavior**: `package.json` appears in the review list. `package-lock.json` does not. The inclusion rules for config files take priority for `package.json`, and the exclusion rules catch `package-lock.json`.
- **Test case**: `TC-sr-includes-config-files`

#### File matching both inclusion and exclusion patterns
- **Trigger**: A file at `dist/vite.config.ts` -- it is in the `dist/` directory (excluded) but matches the `vite.config.*` inclusion pattern.
- **Expected behavior**: The behavior depends on rule priority. Per the product spec, the exclusion rules list `dist/` as a directory to skip. The inclusion list does not override directory-level exclusions (it only lists specific file names/patterns, not "files in excluded directories should be rescued"). The file should be excluded. Flag this if the behavior is unclear.
- **Test case**: `TC-sr-exclusion-priority`

---

### Iteration Edge Cases

#### Single file in the review list
- **Trigger**: The changeset has only 1 reviewable file.
- **Expected behavior**: The file list shows "Found 1 files to review." with a single entry. The iteration processes the one file and then shows the completion summary. The `[1/1]` position indicator is displayed.
- **Test case**: `TC-sr-single-file`

#### Large number of files (100+)
- **Trigger**: The changeset has 100+ reviewable files.
- **Expected behavior**: All files are listed (with right-aligned position numbers, e.g., `  1.` through `127.`). The iteration loop works for all files. The completion summary is accurate. There is no truncation of the file list.
- **Test case**: `TC-sr-many-files`

#### File deleted between detection and iteration
- **Trigger**: Between the initial `git diff` and the iteration reaching a specific file, the file is deleted from disk (e.g., by another process or a git operation).
- **Expected behavior**: When `/shepherd` is invoked for the now-missing file, `/shepherd` reports its own error ("File not found"). The error is displayed. The user can say "next" to continue. The file is counted as "reviewed" (the attempt was made).
- **Test case**: `TC-sr-file-deleted-during-review`

---

## Regression Considerations

### Existing `/shepherd` command
- The `/shepherd-review` command depends on `/shepherd` for per-file review. Changes to `/shepherd`'s behavior (e.g., different error messages, different URL format, different server management) could affect the review workflow.
- Verify that `/shepherd` still works correctly when invoked programmatically by the review command (not just when the user types it manually).

### Install script
- The `scripts/install-command.sh` script is modified to also install `shepherd-review.md`. Verify that the existing `/shepherd` symlink is still created correctly and that the script is idempotent (running it multiple times does not cause issues).

### Git operations
- The changeset detection uses `git diff --name-status` and `git merge-base`. If the repository's git configuration changes (e.g., different rename detection settings, different merge strategies), the changeset output could change. Verify that the command produces consistent results across standard git configurations.

### Agent conversation context
- The `/shepherd-review` command runs as a multi-turn interaction within the agent conversation. If the agent's conversation context is limited or the conversation becomes very long (e.g., after reviewing 50+ files), the agent may lose track of the iteration state. This is an inherent limitation of prompt-based commands. Verify that the command remains coherent for at least 20 files in a single session.
