# Shepherd Review -- Test Plan

> Based on requirements in `../product/shepherd-review.md`
> Based on design in `../design/shepherd-review.md`
> Based on technical spec in `../engineering/shepherd-review.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sr-happy-path` | `TC-sr-happy-path-batch-open` | Not started |
| `AC-sr-filters-lockfiles` | `TC-sr-filters-lockfiles` | Not started |
| `AC-sr-filters-generated` | `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions` | Not started |
| `AC-sr-filters-binary` | `TC-sr-filters-binary` | Not started |
| `AC-sr-includes-config` | `TC-sr-includes-config-files` | Not started |
| `AC-sr-excludes-deleted` | `TC-sr-excludes-deleted-files` | Not started |
| `AC-sr-skip-file` | `TC-sr-implicit-skip` | Not started |
| `AC-sr-quit-early` | `TC-sr-done-at-any-point` | Not started |
| `AC-sr-no-changes` | `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence` | Not started |
| `AC-sr-all-filtered` | `TC-sr-all-filtered` | Not started |
| `AC-sr-not-git-repo` | `TC-sr-not-git-repo` | Not started |
| `AC-sr-invokes-shepherd` | `TC-sr-batch-launch-all-files` | Not started |
| `AC-sr-list-command` | `TC-sr-changeset-overview-with-context` | Not started |
| `AC-sr-completion-summary` | `TC-sr-completion-summary-full`, `TC-sr-completion-summary-no-feedback` | Not started |
| `AC-sr-sorted-file-list` | `TC-sr-sorted-file-list`, `TC-sr-tab-order-matches-priority` | Not started |
| `AC-sr-batch-open` | `TC-sr-batch-open-all-tabs`, `TC-sr-happy-path-batch-open` | Not started |
| `AC-sr-unified-prompt` | `TC-sr-unified-prompt-return`, `TC-sr-implicit-skip` | Not started |
| `AC-sr-install-global` | `TC-sr-install-global-symlink` | Not started |
| `FR-sr-changeset-detection` | `TC-sr-happy-path-batch-open`, `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`, `TC-sr-changeset-merge-base`, `TC-sr-renamed-files` | Not started |
| `FR-sr-file-filtering` | `TC-sr-filters-lockfiles`, `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`, `TC-sr-filters-binary`, `TC-sr-filters-ide-files`, `TC-sr-filters-snapshot-files`, `TC-sr-includes-config-files`, `TC-sr-unknown-file-included` | Not started |
| `FR-sr-file-list-display` | `TC-sr-file-list-format`, `TC-sr-sorted-file-list`, `TC-sr-file-list-exclusion-count` | Not started |
| `FR-sr-multi-file-launch` | `TC-sr-batch-launch-all-files`, `TC-sr-multi-file-url-params` | Not started |
| `FR-sr-per-file-context` | `TC-sr-changeset-overview-with-context`, `TC-sr-context-handoff` | Not started |
| `FR-sr-changeset-overview` | `TC-sr-changeset-overview-with-context`, `TC-sr-context-handoff` | Not started |
| `FR-sr-priority-ordering` | `TC-sr-sorted-file-list`, `TC-sr-tab-order-matches-priority` | Not started |
| `FR-sr-iteration-loop` | `TC-sr-happy-path-batch-open`, `TC-sr-batch-open-all-tabs`, `TC-sr-done-at-any-point`, `TC-sr-implicit-skip`, `TC-sr-auto-open`, `TC-sr-no-pre-launch-prompt` | Not started |
| `FR-sr-feedback-collection` | `TC-sr-unified-prompt-return`, `TC-sr-implicit-skip`, `TC-sr-no-comments-done` | Not started |
| `FR-sr-completion-summary` | `TC-sr-completion-summary-full`, `TC-sr-completion-summary-no-feedback`, `TC-sr-feedback-action-apply`, `TC-sr-feedback-action-save` | Not started |
| `FR-sr-command-file` | `TC-sr-command-file-exists` | Not started |
| `FR-sr-install` | `TC-sr-install-global-symlink` | Not started |
| `FR-sr-scope-argument` | `TC-sr-scope-staged`, `TC-sr-scope-unstaged`, `TC-sr-scope-invalid` | Not started |
| `FR-sr-git-required` | `TC-sr-not-git-repo` | Not started |
| `FR-sr-context-handoff` | `TC-sr-context-handoff` | Not started |
| `AC-sr-context-in-crpg` | `TC-sr-context-in-crpg` | Not started |
| `AC-sr-auto-open` | `TC-sr-auto-open`, `TC-sr-happy-path-batch-open` | Not started |
| `NFR-sr-startup-speed` | `TC-sr-startup-speed` | Not started |
| `NFR-sr-no-dependencies` | `TC-sr-no-external-dependencies` | Not started |
| `NFR-sr-agent-native` | `TC-sr-happy-path-batch-open` | Not started |
| `NFR-sr-cross-platform` | `TC-sr-cross-platform-git-commands` | Not started |

---

## Test Cases

---

### Happy Path and Core Loop

---

#### `TC-sr-happy-path-batch-open`: Full review session from start to finish

- **Type**: Manual
- **Covers**: `AC-sr-happy-path`, `AC-sr-batch-open`, `AC-sr-auto-open`, `FR-sr-changeset-detection`, `FR-sr-iteration-loop`, `NFR-sr-agent-native`
- **Preconditions**: The user is on a feature branch that has 5 modified source files (e.g., `.ts`, `.tsx`, `.py`) and 3 excluded files (e.g., `package-lock.json`, `dist/bundle.js`, `logo.png`) relative to `main`. The `shepherd-launch.sh` script is functional. The CRPG dev server is running or will be started by the launch script.
- **Steps**:
  1. Open a Claude Code session inside the repository.
  2. Type `/shepherd-review`.
  3. Observe the agent output. Verify a brief summary is displayed: the scope label (e.g., "all changes vs main"), the file count ("Opening 5 files for review"), and a note about excluded files (e.g., "3 excluded"). There is no detailed file list, no per-file context, and no confirmation prompt.
  4. Verify the CRPG auto-opens immediately after the brief summary -- no "Ready to start?" or "go" prompt appears.
  5. Observe that the agent invokes `shepherd-launch.sh` once with all 5 file paths and structured context data.
  6. Verify the browser opens a single CRPG session with 5 tabs (one per file) in priority order.
  7. Verify the CRPG displays overall neutral context and review feedback, and each file tab shows per-file neutral context and review feedback alongside the diff.
  8. Review files freely in the CRPG: navigate between tabs, add comments on 3 of the 5 files.
  9. Click "Done" in the CRPG.
  10. The unified multi-file prompt is returned (via `~/.shepherd/prompt-output.md`).
  11. Observe the completion summary and action options.
- **Expected Result**: The brief summary appears in the conversation (scope, file count, exclusion count only -- no detailed file list or per-file summaries). The CRPG auto-opens without any confirmation prompt. All 5 files appear as tabs in a single CRPG session in priority order. The CRPG UI shows overall and per-file context (both neutral and review) with clear visual distinction. The user reviews files in any order they choose. Clicking "Done" generates a single multi-file prompt containing comments from the 3 files that received feedback. The completion summary shows:
  ```
  Review complete.
    8 files in changeset
    3 filtered out (lockfiles, generated, binary)
    5 files opened
    3 files with comments
  ```
  The agent presents the prompt content and asks the user what to do: apply, discuss, save, or nothing.
- **Edge Cases**:
  - User adds comments to all 5 files: all 5 appear in the unified prompt.
  - User switches between tabs multiple times before clicking Done: no issues; the CRPG tracks per-file comments regardless of navigation order.

---

#### `TC-sr-batch-launch-all-files`: All files are opened via a single launch script invocation

- **Type**: Manual
- **Covers**: `AC-sr-invokes-shepherd`, `FR-sr-multi-file-launch`, `FR-sr-iteration-loop`
- **Preconditions**: A feature branch with 3 reviewable files: `src/utils.ts`, `src/app.tsx`, and `lib/helpers.ts`. The `shepherd-launch.sh` script is functional.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Observe the brief summary in the conversation and the auto-launch invocation.
  3. Verify the browser opens a single CRPG session.
- **Expected Result**: The agent invokes `shepherd-launch.sh` once with all 3 file paths and structured context data as arguments. The absolute paths are constructed by combining the repo root (from `git rev-parse --show-toplevel`) with each relative path. The CRPG opens in the browser with 3 tabs in priority order (core source files first). All tabs are available immediately without sequential prompts. No confirmation prompt is shown before the launch.
- **Edge Cases**:
  - The file paths use forward slashes on all platforms in the display, but the absolute paths passed to the launch script use the OS-native separator.
  - If the launch script fails (e.g., CRPG server not running), the error is displayed and the command stops with a clear message.

---

### File Filtering

---

#### `TC-sr-filters-lockfiles`: Lockfiles are excluded from the review

- **Type**: Manual
- **Covers**: `AC-sr-filters-lockfiles`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `package-lock.json`, `pnpm-lock.yaml`, and at least one reviewable source file (e.g., `src/index.ts`).
- **Steps**:
  1. Run `/shepherd-review`.
  2. Wait for the CRPG to auto-open. Examine the brief summary in the conversation and the CRPG tabs.
- **Expected Result**: Neither `package-lock.json` nor `pnpm-lock.yaml` appears as a tab in the CRPG. The brief summary's exclusion count includes them (e.g., "2 files excluded (lockfiles, generated, binary)"). Only `src/index.ts` (and any other non-excluded files) appears as a CRPG tab.
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
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: None of the files in `dist/`, `build/`, `.next/`, `coverage/`, `__generated__/`, or `node_modules/` appear as CRPG tabs. All are counted in the exclusion total.
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
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: All of `app.min.js`, `styles.min.css`, `source.map`, `types.d.ts`, `schema.generated.ts`, and `api.auto.ts` are excluded — none appear as CRPG tabs.
- **Edge Cases**:
  - A file named `my-generator.ts` (contains "generated" as a substring but does not match the `*.generated.*` pattern): should NOT be excluded.
  - A file named `auto-format.ts` (contains "auto" but does not match `*.auto.*`): should NOT be excluded.
  - A file named `index.d.tsx` (not `.d.ts`): should NOT be excluded by the `.d.ts` rule.

---

#### `TC-sr-filters-binary`: Binary files are excluded — none appear as CRPG tabs

- **Type**: Manual
- **Covers**: `AC-sr-filters-binary`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `logo.png`, `font.woff2`, `archive.zip`, and `app.pdf`, plus at least one reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: None of the binary files appear as CRPG tabs. All are counted in the exclusion total.
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
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: All IDE/editor files are excluded — none appear as CRPG tabs.
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
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: Both `.snap` and `.snapshot` files are excluded.
- **Edge Cases**:
  - A file named `snapshot-utils.ts` (the word "snapshot" is in the filename, but the extension is `.ts`): should NOT be excluded.

---

#### `TC-sr-includes-config-files`: Meaningful config files are included in the review

- **Type**: Manual
- **Covers**: `AC-sr-includes-config`, `FR-sr-file-filtering`
- **Preconditions**: The changeset includes `vite.config.ts`, `tsconfig.json`, `package.json`, `jest.config.js`, `eslint.config.mjs`, `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows/ci.yml`, `.claude/commands/shepherd.md`, and `Makefile`.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: All of the above config files appear as CRPG tabs. None are excluded by filtering.
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
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: Files that do not match any exclusion pattern appear as CRPG tabs. The filtering is allowlist-on-top-of-denylist: if a file is not explicitly excluded, it is included.
- **Edge Cases**:
  - A file with no extension (e.g., `Procfile`, `LICENSE`): should be included.
  - A dotfile that is not an IDE config (e.g., `.gitignore`, `.npmrc`): should be included.

---

#### `TC-sr-excludes-deleted-files`: Deleted files do not appear as CRPG tabs

- **Type**: Manual
- **Covers**: `AC-sr-excludes-deleted`, `FR-sr-changeset-detection`
- **Preconditions**: The changeset includes a file that exists on `main` but has been deleted on the current branch, plus at least one modified file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Wait for the CRPG to auto-open. Examine the brief summary and CRPG tabs.
- **Expected Result**: The deleted file does not appear as CRPG tabs. It is counted in the total changeset count and in the exclusion count (per design spec, deleted files are included in `<T>` and `<E>`).
- **Edge Cases**:
  - Multiple deleted files: none should appear as CRPG tabs.
  - A file that was deleted and then re-added with different content (git shows as D+A or as M): should appear as modified or added, not deleted.

---

### File List Display and Sorting

---

#### `TC-sr-file-list-format`: Conversation summary matches the brief summary format

- **Type**: Manual
- **Covers**: `FR-sr-file-list-display`
- **Preconditions**: A branch with at least 3 reviewable files and at least 1 excluded file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Inspect the conversation output before the CRPG auto-opens.
- **Expected Result**: The conversation output includes only a brief summary:
  1. A scope label indicating what changes are being reviewed (e.g., "all changes vs main", "staged only", "unstaged only").
  2. The file count (e.g., "Opening 7 files for review").
  3. If any files were excluded, a note indicating how many were excluded.

  The conversation does NOT include: a detailed numbered file list, per-file context summaries, a changeset overview paragraph, or a confirmation prompt. The detailed context (overall and per-file, neutral and review) is passed to the CRPG and displayed in the tool UI. The CRPG auto-opens immediately after the brief summary.
- **Edge Cases**:
  - Zero excluded files: the exclusion note is omitted entirely.
  - Exactly 1 excluded file: verify wording is appropriate (e.g., "1 excluded").
  - Large changeset (20+ files): the summary remains brief (scope, count, exclusions only).

---

#### `TC-sr-sorted-file-list`: Files are sorted by review priority

- **Type**: Manual
- **Covers**: `AC-sr-sorted-file-list`, `FR-sr-file-list-display`, `FR-sr-priority-ordering`
- **Preconditions**: The changeset includes `src/utils.ts`, `src/app.tsx`, `vite.config.ts`, `README.md`, and `tests/utils.test.ts`.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the ordering of files in the numbered list.
- **Expected Result**: The files are sorted by review importance, not alphabetically:
  ```
    1. src/app.tsx                        [modified]
    2. src/utils.ts                       [modified]
    3. vite.config.ts                     [modified]
    4. README.md                          [modified]
    5. tests/utils.test.ts                [added]
  ```
  The ordering follows the priority tiers:
  1. Core source code (application logic, components, business logic) -- most important
  2. Configuration that affects behavior (build config, CI, command definitions)
  3. Specs and documentation (markdown specs, design docs)
  4. Supporting files (indexes, glossaries, changelogs)
  5. Test files -- least urgent for manual review

  Within each tier, larger/more significant changes rank higher.
- **Edge Cases**:
  - Multiple files in the same priority tier: their relative ordering should be consistent and based on significance of changes.
  - A config file that is also core source (e.g., a `Makefile` with build logic): should be categorized by its primary role.
  - Files with ambiguous priority (e.g., `src/test-utils.ts` -- source code that supports tests): should be in the source tier, not the test tier.

---

#### `TC-sr-file-list-exclusion-count`: Exclusion count accurately reflects filtered files

- **Type**: Manual
- **Covers**: `FR-sr-file-list-display`, `FR-sr-file-filtering`
- **Preconditions**: The changeset has 10 total files: 4 source files, 2 lockfiles, 1 binary, 1 generated, 1 deleted, 1 snapshot.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Examine the brief summary in the conversation.
- **Expected Result**: The brief summary shows "Opening 4 files for review" and indicates "6 excluded." The total (4 + 6 = 10) matches the total changeset count. Deleted files are included in the exclusion count, not shown separately.
- **Edge Cases**:
  - All files are excluded: handled by `TC-sr-all-filtered`.
  - No files are excluded: the exclusion line is omitted.

---

#### `TC-sr-renamed-files`: Renamed files show old path and use new path for review

- **Type**: Manual
- **Covers**: `FR-sr-changeset-detection`, `FR-sr-file-list-display`
- **Preconditions**: The changeset includes a file renamed from `src/helpers.ts` to `src/utils/helpers.ts`.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. Examine the CRPG tabs for the renamed file.
- **Expected Result**: The renamed file appears as a tab in the CRPG with the new path `src/utils/helpers.ts`. The launch script receives the new path (which exists on disk). The per-file context in the CRPG notes that the file was renamed.
- **Edge Cases**:
  - A file renamed with content changes (git reports as rename with a similarity index): should still show as renamed.
  - A file renamed to a different directory: the new path is used for display and for the launch script invocation.

---

### Batch Open and Review Control

---

#### `TC-sr-batch-open-all-tabs`: All files appear as CRPG tabs in a single session

- **Type**: Manual
- **Covers**: `AC-sr-batch-open`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with 5 reviewable files. The `shepherd-launch.sh` script is functional and the CRPG supports multi-file URL loading.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Observe the brief summary in the conversation and wait for the browser to auto-open.
  3. Inspect the CRPG session in the browser.
- **Expected Result**: A single browser tab opens with the CRPG automatically (no confirmation prompt). Within the CRPG, 5 file tabs are visible (one per reviewable file). All 5 tabs are immediately accessible. The user can click any tab to view that file's diff. No sequential prompts or per-file invocations occur in the agent conversation.
- **Edge Cases**:
  - If the browser was already open with a previous CRPG session, the new session should replace or open in a new tab (depending on the launch script behavior).
  - If the CRPG takes time to load all files, a loading state should be visible in the UI.

---

#### `TC-sr-tab-order-matches-priority`: CRPG tab order matches priority ordering

- **Type**: Manual
- **Covers**: `AC-sr-sorted-file-list`, `FR-sr-priority-ordering`
- **Preconditions**: A branch with files spanning multiple priority tiers: `src/app.tsx` (core source), `vite.config.ts` (config), `README.md` (docs), `tests/app.test.tsx` (test).
- **Steps**:
  1. Run `/shepherd-review` and observe the brief summary in the conversation.
  2. Wait for the CRPG to auto-open and observe the tabs.
  3. Compare the tab order in the CRPG to the expected priority ordering (core source first, config second, docs third, tests last).
- **Expected Result**: The CRPG tab order exactly matches the priority ordering. Core source files appear as the leftmost tabs, followed by config, docs, and tests as the rightmost tabs:
  ```
  Tab order: src/app.tsx | vite.config.ts | README.md | tests/app.test.tsx
  ```
  This matches the numbered list shown in the agent conversation.
- **Edge Cases**:
  - If two files are in the same priority tier, their relative order within that tier should be consistent between the list and the tabs.

---

#### `TC-sr-implicit-skip`: Files without comments are implicitly skipped

- **Type**: Manual
- **Covers**: `AC-sr-skip-file`, `AC-sr-unified-prompt`, `FR-sr-iteration-loop`, `FR-sr-feedback-collection`
- **Preconditions**: A branch with 5 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, add comments on files 1, 3, and 5 only. Leave files 2 and 4 without comments.
  3. Click "Done" in the CRPG.
  4. Observe the returned prompt and the completion summary.
- **Expected Result**: The unified multi-file prompt includes only files 1, 3, and 5 (the files that received comments). Files 2 and 4 are not mentioned in the prompt. The completion summary shows:
  ```
  Review complete.
    ...
    5 files opened
    3 files with comments
  ```
  No explicit "skip" action was required. Not commenting on a file is equivalent to skipping it.
- **Edge Cases**:
  - Adding a comment then deleting it before clicking Done: the file should not appear in the prompt (zero net comments).
  - Adding comments to all 5 files: all 5 appear in the prompt; "files with comments" shows 5.

---

#### `TC-sr-done-at-any-point`: User can click Done after reviewing any subset of files

- **Type**: Manual
- **Covers**: `AC-sr-quit-early`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with 5 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, view only the first tab and add a comment on it.
  3. Click "Done" without visiting the other 4 tabs.
  4. Observe the returned prompt and the completion summary.
- **Expected Result**: The session ends cleanly. The unified prompt contains the comment from the one file that received feedback. The completion summary shows:
  ```
  Review complete.
    ...
    5 files opened
    1 files with comments
  ```
  There is no concept of "remaining" files or "quit early." The user simply finishes whenever they are ready. The command does not warn or ask for confirmation before ending.
- **Edge Cases**:
  - Clicking Done immediately after the CRPG opens, without viewing any file in detail: session ends cleanly with zero comments (see `TC-sr-no-comments-done`).
  - Clicking Done after visiting all tabs but only commenting on some: session ends normally.

---

#### `TC-sr-unified-prompt-return`: Multi-file prompt is returned via prompt-output.md

- **Type**: Manual
- **Covers**: `AC-sr-unified-prompt`, `FR-sr-feedback-collection`
- **Preconditions**: A branch with 3 reviewable files. The `~/.shepherd/prompt-output.md` file-watcher mechanism is functional.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, add comments on 2 of the 3 files.
  3. Click "Done" in the CRPG.
  4. Verify the prompt is returned to the agent conversation.
- **Expected Result**: The CRPG writes the unified multi-file prompt to `~/.shepherd/prompt-output.md`. The agent detects this via the file-watcher mechanism and reads the content. The prompt is organized by file, with each file's comments grouped together. The agent displays the prompt content in the conversation and presents the action options (apply, discuss, save, nothing).
- **Edge Cases**:
  - If `~/.shepherd/prompt-output.md` already existed from a previous session, it should be overwritten or the agent should handle staleness (e.g., by checking a timestamp or clearing the file before launch).
  - Very large prompt (many comments across many files): the agent should still read and display the full content.

---

#### `TC-sr-no-comments-done`: Clicking Done with zero comments ends the session cleanly

- **Type**: Manual
- **Covers**: `FR-sr-feedback-collection`, `FR-sr-completion-summary`
- **Preconditions**: A branch with at least 2 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, view the files but do not add any comments.
  3. Click "Done" in the CRPG.
  4. Observe the agent output.
- **Expected Result**: The agent detects that no comments were made (empty prompt or explicit "no feedback" signal from the CRPG). The completion summary shows:
  ```
  Review complete.
    ...
    <N> files opened
    0 files with comments
  ```
  The agent displays a message indicating no feedback was collected (e.g., "No comments were added during the review.") and the session ends. No action options (apply, discuss, save) are presented since there is nothing to act on.
- **Edge Cases**:
  - User opened all tabs and scrolled through diffs but added zero comments: same behavior as not viewing any tabs.

---

#### `TC-sr-no-pre-launch-prompt`: No confirmation prompt is shown before auto-open

- **Type**: Manual
- **Covers**: `AC-sr-auto-open`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 1 reviewable file.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Observe the agent output carefully between the brief summary and the CRPG opening.
- **Expected Result**: The agent does NOT display any confirmation prompt such as "Ready to start?", "Say 'go' to begin", or any variation asking the user whether to proceed. After the brief summary (scope, file count, exclusion count), the CRPG auto-opens immediately. There is no intermediate step where the user must type "go", "yes", or any other confirmation. The user's intent to review was established by invoking `/shepherd-review`.
- **Edge Cases**:
  - The user cannot cancel the review before the CRPG opens. To "cancel," the user simply clicks "Done" in the CRPG without adding comments, which produces a zero-comment completion summary.

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
  - Branch named `main` with uncommitted changes (not yet committed): per the product spec, the changeset detection compares the working tree to the merge base, so uncommitted changes ARE included. If there are uncommitted changes on `main`, those files should appear as CRPG tabs.
  - Freshly created branch off main with zero commits and no working tree changes: should report no changes.

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

#### `TC-sr-completion-summary-full`: Summary after completing a review with feedback

- **Type**: Manual
- **Covers**: `AC-sr-completion-summary`, `FR-sr-completion-summary`
- **Preconditions**: A branch with 10 total files, 3 excluded, 7 reviewable. User opens all 7 in the CRPG and adds comments on 5 of them.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, add comments on 5 of the 7 files.
  3. Click "Done" in the CRPG.
  4. Observe the completion summary.
- **Expected Result**: The summary displays:
  ```
  Review complete.
    10 files in changeset
     3 filtered out (lockfiles, generated, binary)
     7 files opened
     5 files with comments
  ```
  Numbers are right-aligned. The agent then presents the full prompt content and asks what the user wants to do: apply, discuss, save, or nothing.
- **Edge Cases**:
  - All 7 files receive comments: "7 files with comments" is shown.
  - Zero excluded files: the "filtered out" line is omitted.
  - The summary is displayed after the prompt is returned, not before.

---

#### `TC-sr-completion-summary-no-feedback`: Summary when no comments are made

- **Type**: Manual
- **Covers**: `FR-sr-completion-summary`, `FR-sr-feedback-collection`
- **Preconditions**: A branch with 3 reviewable files.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, view files but do not add any comments.
  3. Click "Done" in the CRPG.
  4. Observe the completion summary.
- **Expected Result**: The summary displays:
  ```
  Review complete.
    ...
    3 files opened
    0 files with comments
  ```
  The agent notes that no feedback was collected and ends the session. No action options (apply, discuss, save) are presented since there is nothing to act on.
- **Edge Cases**:
  - This is an unusual but valid workflow. The command should not warn or behave differently.
  - The user may have thoroughly reviewed files and decided everything looks good -- zero comments is a valid outcome.

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

### Changeset Overview

---

#### `TC-sr-changeset-overview-with-context`: Changeset context is passed to and displayed in the CRPG

- **Type**: Manual
- **Covers**: `AC-sr-list-command`, `AC-sr-context-in-crpg`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-context-handoff`
- **Preconditions**: A branch with 4 reviewable files that have meaningful diffs: `src/app.tsx` (added a new route), `src/utils.ts` (refactored a helper function), `vite.config.ts` (added a new alias), `tests/app.test.tsx` (added tests for the new route).
- **Steps**:
  1. Run `/shepherd-review`.
  2. Observe that the agent conversation shows only a brief summary (scope, file count, exclusions) -- NOT a changeset overview paragraph or per-file summaries.
  3. After the CRPG auto-opens, inspect the CRPG UI.
  4. Check for overall changeset context (neutral + review) in the CRPG.
  5. Switch between file tabs and check for per-file context (neutral + review) in the CRPG.
- **Expected Result**: The agent conversation contains only the brief summary. The CRPG UI displays:
  1. **Overall neutral context**: A factual summary of the changeset (what features/areas are touched, structural nature of changes). No opinions.
  2. **Overall review feedback**: The agent's assessment (quality observations, concerns, suggestions). Clearly the agent's take.
  3. **Per-file neutral context** (for each file tab): Factual description of what changed in this file -- functions added/modified/removed, structural changes. Mentions specific names.
  4. **Per-file review feedback** (for each file tab): Agent's observations about this specific file -- code quality, potential issues, suggestions.

  The neutral and review sections are visually distinct (different colors, borders, or styling). Per-file context updates when switching tabs.
- **Edge Cases**:
  - A file with a very large diff (hundreds of lines): the per-file context should still be concise, not enumerate every change.
  - A file with only whitespace or formatting changes: the per-file context should note this.
  - A new file (added): the context should describe what the file does.

---

### Scope Argument

---

#### `TC-sr-scope-staged`: Reviewing only staged changes with --staged

- **Type**: Manual
- **Covers**: `FR-sr-scope-argument`
- **Preconditions**: A branch with 3 staged files and 2 unstaged files relative to main.
- **Steps**:
  1. Stage 3 files with `git add`.
  2. Run `/shepherd-review --staged`.
  3. Examine the file list.
- **Expected Result**: Only the 3 staged files appear in the CRPG as tabs. The 2 unstaged files are not shown. The brief conversation summary indicates "staged only" or equivalent. The context data passed to the CRPG (overall and per-file) reflects only the staged changes.
- **Edge Cases**:
  - No staged files: the command reports "No changes found" and stops.
  - A file that is both staged and has unstaged modifications: only the staged version of the changes is included.

---

#### `TC-sr-scope-unstaged`: Reviewing only unstaged changes with --unstaged

- **Type**: Manual
- **Covers**: `FR-sr-scope-argument`
- **Preconditions**: A branch with 2 staged files and 3 unstaged files (including 1 untracked new file) relative to HEAD.
- **Steps**:
  1. Stage 2 files with `git add`.
  2. Modify 2 other files without staging them.
  3. Create a new file without staging it.
  4. Run `/shepherd-review --unstaged`.
  5. Examine the file list.
- **Expected Result**: Only the 3 unstaged/untracked files appear as CRPG tabs. The 2 staged files are not shown. The untracked new file appears with change type `added`. The scope label indicates "unstaged only" or equivalent.
- **Edge Cases**:
  - No unstaged changes and no untracked files: the command reports "No changes found" and stops.
  - A file that is staged but also has additional unstaged modifications: only the unstaged modifications appear.

---

#### `TC-sr-scope-invalid`: Invalid argument shows usage message

- **Type**: Manual
- **Covers**: `FR-sr-scope-argument`
- **Preconditions**: A branch with at least 1 changed file.
- **Steps**:
  1. Run `/shepherd-review --invalid-flag`.
  2. Observe the agent output.
- **Expected Result**: The agent displays a usage message indicating the valid options (no argument, `--staged`, `--unstaged`) and stops. No file list is displayed and no files are opened.
- **Edge Cases**:
  - Multiple arguments (e.g., `/shepherd-review --staged --unstaged`): should show usage message.
  - A valid-looking but unsupported argument (e.g., `/shepherd-review --all`): should show usage message.

---

### Auto-Open and Context Handoff

---

#### `TC-sr-auto-open`: CRPG opens automatically without confirmation prompt

- **Type**: Manual
- **Covers**: `AC-sr-auto-open`, `FR-sr-iteration-loop`
- **Preconditions**: A branch with at least 3 reviewable files. The `shepherd-launch.sh` script is functional and the CRPG dev server is running.
- **Steps**:
  1. Run `/shepherd-review`.
  2. Observe the agent conversation output carefully.
  3. Time the interval between the brief summary appearing and the CRPG opening.
- **Expected Result**: After changeset detection and context generation, the agent displays a brief summary in the conversation (scope, file count, exclusion count) and then immediately auto-opens the CRPG. No confirmation prompt appears -- no "Ready to start?", no "Say 'go'", no "Proceed? (yes/no)", no similar question. The CRPG opens without any user interaction after the `/shepherd-review` invocation. The transition from brief summary to CRPG launch is seamless.
- **Edge Cases**:
  - Single file in the changeset: the CRPG still auto-opens without a prompt.
  - Large changeset (20+ files): the CRPG still auto-opens without a prompt (context generation may take a few seconds, but no confirmation is requested).

---

#### `TC-sr-context-handoff`: Structured context data is passed to the CRPG

- **Type**: Manual
- **Covers**: `FR-sr-context-handoff`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`
- **Preconditions**: A branch with at least 3 reviewable files with meaningful diffs.
- **Steps**:
  1. Run `/shepherd-review`.
  2. After the CRPG auto-opens, inspect the context data received by the CRPG (e.g., via browser DevTools network tab, URL parameters, or by checking the context file used for handoff).
- **Expected Result**: The CRPG receives structured context data containing all four components:
  1. **Overall neutral context**: A factual changeset summary. Contains no opinions or quality judgments.
  2. **Overall review feedback**: The agent's assessment of the changeset. Contains opinions, suggestions, concerns.
  3. **Per-file neutral context** (keyed by file path): For each reviewable file, a factual description of what changed. Mentions specific function names, structural changes.
  4. **Per-file review feedback** (keyed by file path): For each reviewable file, the agent's observations and suggestions.

  The neutral/review distinction is preserved in the data structure (not mixed together). The per-file data is keyed by file path matching the files opened as tabs.
- **Edge Cases**:
  - A file with minimal changes (1-2 lines): context should still be present, even if brief.
  - A file with only additions (new file): neutral context should describe what the file does; review feedback may note patterns or suggestions.
  - The conversation does NOT contain the detailed context -- only the brief summary appears there.

---

#### `TC-sr-context-in-crpg`: Context appears in the CRPG with neutral/review visual distinction

- **Type**: Manual
- **Covers**: `AC-sr-context-in-crpg`, `FR-sr-context-handoff`
- **Preconditions**: A branch with at least 2 reviewable files. The CRPG has been opened via `/shepherd-review` with context data.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. In the CRPG, look for the overall context section.
  3. Verify the overall neutral context and overall review feedback are displayed with visually distinct styling.
  4. Switch to a file tab and look for per-file context.
  5. Verify the per-file neutral context and per-file review feedback are displayed with visually distinct styling.
  6. Switch to another file tab and verify per-file context updates.
- **Expected Result**: The CRPG displays:
  - **Overall context**: Both neutral (factual) and review (opinion) sections are visible. They have different visual styling (e.g., different background colors, different border colors, different section headers/labels, different icons). A user can tell at a glance which is which.
  - **Per-file context**: Each file tab shows its own neutral and review context alongside the diff. The styling matches the overall context distinction. When switching tabs, the per-file context updates to the new file's data.

  The neutral context uses informational styling (e.g., blue tones). The review feedback uses a distinct styling (e.g., violet/purple tones) that conveys it is the agent's subjective assessment.
- **Edge Cases**:
  - A file with no review feedback (only neutral context): the review feedback section is either absent or shows no content. The neutral context is still displayed.
  - Switching rapidly between tabs: per-file context updates correctly without flicker or stale data.

---

### Multi-File URL and Launch

---

#### `TC-sr-multi-file-url-params`: Launch script constructs correct URL with multiple file params

- **Type**: Manual
- **Covers**: `FR-sr-multi-file-launch`
- **Preconditions**: A branch with 3 reviewable files. The `shepherd-launch.sh` script is functional.
- **Steps**:
  1. Run `/shepherd-review` and wait for the CRPG to auto-open.
  2. Observe or inspect the URL opened by `shepherd-launch.sh` (e.g., via browser address bar or by adding debug output to the script).
- **Expected Result**: The launch script constructs a URL that includes all 3 file paths as parameters. The CRPG web app receives these parameters and loads each file as a separate tab. The exact URL format is determined by the engineering spec (e.g., repeated `file` query parameters, comma-separated paths, or another mechanism). All 3 files load successfully as tabs.
- **Edge Cases**:
  - File paths with spaces or special characters: must be properly URL-encoded.
  - Very long URL (many files): verify the URL does not exceed browser limits (typically ~2000 characters for GET URLs). If it does, verify the launch script uses an alternative mechanism (e.g., a temp file or POST).
  - File paths with non-ASCII characters: must be handled correctly.

---

### Feedback Actions

---

#### `TC-sr-feedback-action-apply`: User selects "apply" after prompt return

- **Type**: Manual
- **Covers**: `FR-sr-completion-summary`
- **Preconditions**: A completed review session with at least 1 file that received comments. The unified prompt has been returned.
- **Steps**:
  1. Complete a review session (run `/shepherd-review`, wait for CRPG to auto-open, add comments, click Done).
  2. After the summary and prompt are displayed, select "apply".
  3. Observe the agent behavior.
- **Expected Result**: The agent begins implementing the changes described in the feedback prompt. It reads the prompt content (which contains per-file review comments) and starts making code changes based on the feedback. This is equivalent to the user having pasted the prompt manually.
- **Edge Cases**:
  - Very large prompt with many files and comments: the agent should process all feedback, not truncate.
  - Feedback that contradicts itself (e.g., "add this function" in one file, "remove this function" in another): the agent should follow the instructions as stated and flag any confusion.

---

#### `TC-sr-feedback-action-save`: User selects "save for later" after prompt return

- **Type**: Manual
- **Covers**: `FR-sr-completion-summary`
- **Preconditions**: A completed review session with at least 1 file that received comments. The unified prompt has been returned.
- **Steps**:
  1. Complete a review session (run `/shepherd-review`, wait for CRPG to auto-open, add comments, click Done).
  2. After the summary and prompt are displayed, select "save".
  3. Observe the agent behavior.
- **Expected Result**: The agent writes the feedback prompt content to a file for later use. The file location should be communicated to the user (e.g., "Saved review feedback to `<path>`"). The session ends after saving.
- **Edge Cases**:
  - The save path should be deterministic and not conflict with other files.
  - Saving when a previous save file exists: should overwrite or use a timestamped name.

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
  3. Measure the time from invocation to the CRPG auto-opening.
- **Expected Result**: The CRPG auto-opens within 5 seconds (per `NFR-sr-startup-speed`). The bottleneck is the `git diff` and `git merge-base` commands plus context generation, which should be fast even for large repositories.
- **Edge Cases**:
  - Very large repository (monorepo with 100,000+ files but only 50 changed): should still be fast because `git diff` only reports changed files.
  - Repository with extensive rename detection (many files moved): rename detection can be slow; verify the command does not time out.

---

#### `TC-sr-no-external-dependencies`: No additional dependencies beyond git and shepherd-launch.sh

- **Type**: Manual
- **Covers**: `NFR-sr-no-dependencies`
- **Preconditions**: The command file exists.
- **Steps**:
  1. Read the `.claude/commands/shepherd-review.md` file.
  2. Verify it only references git commands, standard shell utilities, and the `shepherd-launch.sh` script.
  3. Verify no npm packages, binaries, or external tools are required.
- **Expected Result**: The command file is pure prompt engineering. It instructs the agent to use `git` (for changeset detection), standard shell (for path manipulation), and `shepherd-launch.sh` (for launching the CRPG with multiple files). No additional dependencies are introduced.
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
- **Expected behavior**: `package.json` appears as a CRPG tab. `package-lock.json` does not. The inclusion rules for config files take priority for `package.json`, and the exclusion rules catch `package-lock.json`.
- **Test case**: `TC-sr-includes-config-files`

#### File matching both inclusion and exclusion patterns
- **Trigger**: A file at `dist/vite.config.ts` -- it is in the `dist/` directory (excluded) but matches the `vite.config.*` inclusion pattern.
- **Expected behavior**: The behavior depends on rule priority. Per the product spec, the exclusion rules list `dist/` as a directory to skip. The inclusion list does not override directory-level exclusions (it only lists specific file names/patterns, not "files in excluded directories should be rescued"). The file should be excluded. Flag this if the behavior is unclear.
- **Test case**: `TC-sr-exclusion-priority`

---

### Batch Open Edge Cases

#### Single file in the review list
- **Trigger**: The changeset has only 1 reviewable file.
- **Expected behavior**: The file list shows "Found 1 files to review." with a single entry. After confirmation, the CRPG opens with a single tab. The user reviews and clicks Done. The completion summary is displayed.
- **Test case**: `TC-sr-single-file`

#### Large batch size (30+ files)
- **Trigger**: The changeset has 30+ reviewable files, all opened as tabs in a single CRPG session.
- **Expected behavior**: All files are listed in the file list (with right-aligned position numbers). The launch script constructs a URL with all file paths. The CRPG opens with all files as tabs. The tab bar may become crowded but should remain navigable (scrollable tab bar or similar). The completion summary is accurate. There is no truncation of the file list or the tab set. If the URL exceeds browser limits, the launch script should use an alternative mechanism.
- **Test case**: `TC-sr-many-files-batch`

#### CRPG timeout
- **Trigger**: The user opens all files in the CRPG but never clicks Done. The session remains idle for an extended period.
- **Expected behavior**: The CRPG or the agent's file-watcher mechanism has a timeout (30 minutes, matching the `/shepherd` command's timeout). If the timeout is reached, the agent reports that the session timed out and displays a summary with zero comments. The user can re-run `/shepherd-review` to start a fresh session.
- **Test case**: `TC-sr-crpg-timeout`

---

## Regression Considerations

### `shepherd-launch.sh` script dependency
- The `/shepherd-review` command depends on `shepherd-launch.sh` for opening files in the CRPG. Changes to the launch script's behavior (e.g., different URL format, different server management, different argument handling) could affect the review workflow.
- Verify that `shepherd-launch.sh` works correctly when invoked with multiple file path arguments (the new multi-file interface) and that single-file invocation (used by `/shepherd` directly) is not broken.

### CRPG multi-file URL loading regression
- The CRPG web app is updated to support loading multiple files from URL parameters (new `useFileFromUrl` behavior). Changes to the URL parameter format or the file-loading logic could break the batch-open workflow.
- Verify that the CRPG correctly loads all files passed via URL parameters and creates one tab per file in the correct order.
- Verify that the existing single-file URL loading (used by `/shepherd` for individual files) still works correctly.

### `prompt-output.md` multi-file content regression
- The CRPG generates a unified multi-file prompt and writes it to `~/.shepherd/prompt-output.md`. Changes to the prompt format, the file-write mechanism, or the agent's file-watcher could break the feedback return workflow.
- Verify that the prompt-output file contains all comments from all files, organized by file.
- Verify that the agent correctly detects and reads the prompt-output file after the user clicks Done.

### Install script
- The `scripts/install-command.sh` script is modified to also install `shepherd-review.md`. Verify that the existing `/shepherd` symlink is still created correctly and that the script is idempotent (running it multiple times does not cause issues).

### Git operations
- The changeset detection uses `git diff --name-status` and `git merge-base`. If the repository's git configuration changes (e.g., different rename detection settings, different merge strategies), the changeset output could change. Verify that the command produces consistent results across standard git configurations.

### Agent conversation context
- The `/shepherd-review` command runs as a multi-turn interaction within the agent conversation. With the auto-open model, the agent's context requirements are simpler (no confirmation prompt, no per-file iteration state). The conversation now contains only a brief summary (scope, file count, exclusion count) instead of a detailed file list with per-file summaries. The detailed context (overall and per-file, neutral and review) is passed to the CRPG. Verify that the brief summary is concise and the context data reaches the CRPG correctly.

### Context handoff to CRPG
- The structured context data (overall neutral, overall review, per-file neutral, per-file review) must reach the CRPG via the launch mechanism. Changes to the launch script, the CRPG's context receiving mechanism, or the data format could break context display. Verify that context data round-trips correctly from the agent through the launch script to the CRPG.
- The neutral/review distinction must be preserved in the data structure. If the handoff mechanism flattens or merges the two types, the CRPG cannot display them with distinct styling.
- Per-file context is keyed by file path. If file paths in the context data don't match the file paths used for tab creation, the CRPG won't be able to associate context with the correct tab.
