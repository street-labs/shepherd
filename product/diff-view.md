# Working Copy Diff View

## Overview

An alternative viewing mode for the Code Review Prompt Generator (CRPG) that shows a unified diff between a file's git HEAD version (baseline) and its current working copy on disk. Instead of viewing an entire file and commenting on it, the user sees only what changed — added lines, removed lines, and a configurable amount of surrounding context — and comments on the diff itself.

This feature is motivated by the primary use case of the CRPG: a developer is working alongside an AI coding agent that modifies files. After the agent makes changes, the developer wants to review what changed, annotate specific additions or removals, and generate a prompt with feedback. Viewing the full file obscures what actually changed. A diff view surfaces exactly the information the reviewer needs.

The diff view is an alternative mode alongside the existing file view. It is available only for files loaded via the `/shepherd` slash command (which provides server-side file access), because computing the diff requires fetching both the working copy and the git HEAD version from the local filesystem. Files loaded via paste, upload, or drag-and-drop do not have a baseline to diff against, so diff view is unavailable for those files.

## User Stories

### US-DIFF-1: See what changed in a file
**As a** developer reviewing AI-generated code changes, **I want to** see a diff between the original file and its current state, **so that** I can focus my review on what actually changed rather than reading the entire file.

### US-DIFF-2: Collapse unchanged code
**As a** developer reviewing a diff, **I want** large blocks of unchanged code to be collapsed by default with only a few lines of context around each change, **so that** I can focus on the changes without scrolling through hundreds of unchanged lines.

### US-DIFF-3: Expand collapsed sections
**As a** developer reviewing a diff, **I want to** expand collapsed sections of unchanged code when I need more context, **so that** I can understand the surrounding code without switching to file view.

### US-DIFF-4: Comment on diff lines
**As a** developer reviewing a diff, **I want to** add inline comments on any visible line in the diff (added, removed, or context), **so that** I can annotate specific changes with feedback for the AI agent.

### US-DIFF-5: Generate a prompt from diff comments
**As a** developer who has annotated a diff, **I want to** generate a structured prompt that includes my comments alongside the relevant diff context, **so that** the AI agent understands exactly which changes I am responding to.

### US-DIFF-6: Switch between file view and diff view
**As a** developer, **I want to** toggle between the full file view and the diff view, **so that** I can use whichever perspective is most useful for the feedback I want to give.

## Requirements

### Functional Requirements

#### `FR-diff-mode-toggle` -- Toggle between file view and diff view
The application provides a toggle control (e.g., a segmented button or tab) that switches between "File" view (the existing full-file code viewer) and "Diff" view (the unified diff viewer). The toggle is visible in the toolbar area whenever a file is loaded. Switching modes preserves the preamble but does not preserve comments, because comments are anchored to different line models in each mode (absolute line numbers in file view vs. diff line identifiers in diff view). Switching modes displays a confirmation dialog if any comments exist, warning the user that comments will be cleared.

#### `FR-diff-mode-availability` -- Diff view is only available for server-loaded files
The diff view toggle is only enabled when the file was loaded via the file-serving API (i.e., via the `/shepherd` slash command or a `?file=` URL parameter). For files loaded via paste, upload, or drag-and-drop, the toggle is visible but disabled, with a tooltip explaining that diff view requires the file to be loaded from the local filesystem via the slash command.

#### `FR-diff-baseline-fetch` -- Fetch the git HEAD version of a file
When the user activates diff view (or when a server-loaded file is first loaded and diff view is the active mode), the application fetches the git HEAD version of the file from the server. The server provides this via a new API endpoint (e.g., `GET /api/file/head?path=<encoded-path>`). If the file has no git history (untracked file), the endpoint returns a 404 and the application treats the entire file as added (the diff shows all lines as additions with no removals). If the file is unchanged from HEAD, the application shows an "No changes" empty state.

#### `FR-diff-compute` -- Compute the unified diff client-side
The application computes the diff between the baseline (HEAD) and the working copy entirely in the browser. The diff algorithm produces a list of hunks, where each hunk contains a sequence of added, removed, and unchanged (context) lines. The diff operates on a line-by-line basis. The diff computation must use a standard algorithm (Myers diff or equivalent) that produces minimal, human-readable diffs.

#### `FR-diff-display` -- Display the unified diff with line gutters
The diff is displayed in a unified format within the code viewer area. Each line in the diff view has:
1. A **line type indicator**: a gutter column showing `+` for added lines, `-` for removed lines, and a blank space for context lines.
2. A **background color**: green-tinted for added lines, red-tinted for removed lines, no tint for context lines.
3. **Line numbers**: Two gutter columns — the left showing the line number in the old (HEAD) version, and the right showing the line number in the new (working copy) version. Added lines have no old line number; removed lines have no new line number.
4. **Syntax highlighting**: Both added and removed lines are syntax-highlighted based on the detected language, consistent with `FR-crp-syntax-highlight`.

#### `FR-diff-collapse` -- Collapse unchanged sections by default
Blocks of unchanged (context) lines are collapsed by default when the gap between two change hunks exceeds `2 * contextLines + 1` lines (default: 7 lines, with a context size of 3). If the gap is 7 or fewer unchanged lines, all lines are shown in full rather than collapsed. When a gap is collapsed, the application shows 3 context lines below the preceding hunk and 3 context lines above the following hunk, with a visual separator in between indicating how many lines are hidden (e.g., "... 47 unchanged lines ..."). At the top and bottom of the file, unchanged lines beyond the context window are also collapsed — the first hunk shows 3 context lines above it (collapsing everything before), and the last hunk shows 3 context lines below it (collapsing everything after).

#### `FR-diff-expand` -- Expand collapsed sections
The user can click on a collapsed section separator to expand it. Expansion reveals all hidden lines in that section. Once expanded, a section remains expanded until the user switches away from diff view or loads a new file. There is no mechanism to re-collapse an expanded section within the same session (consistent with GitHub's behavior).

#### `FR-diff-comment-create` -- Add inline comments on diff lines
The user can add inline comments on any visible line in the diff view — added lines, removed lines, or context lines. The comment attachment model uses a diff-specific line identifier that encodes the line type and position (e.g., old line 42, new line 50, or context line 30). Comments on collapsed/hidden lines are not possible; the user must expand the section first. The comment creation interaction (click gutter, type, submit) is identical to the existing file view behavior described in `FR-crp-line-comment-create`.

#### `FR-diff-comment-on-range` -- Comment on a range of diff lines
The user can select a contiguous range of visible diff lines and attach a single comment to the range, consistent with `FR-crp-line-range-comment`. The range can span across line types (e.g., a range that includes both added and context lines). The range cannot span across a collapsed section.

#### `FR-diff-prompt-format` -- Diff-aware prompt format
When generating a prompt from diff view, the prompt format adapts to include diff context. Instead of pairing comments with plain code snippets, each comment is paired with the diff hunk that surrounds it, using unified diff notation (`+`/`-` prefixes). The prompt clearly indicates which lines are additions and which are removals, so the AI agent understands the change context. The prompt structure follows the same overall format as `FR-crp-prompt-format` (instructions section, file heading, requested changes section), but the code blocks use diff syntax.

#### `FR-diff-empty-state` -- Empty diff state
When the working copy is identical to the HEAD version (no changes), the diff view displays an empty state message: "No changes detected. The working copy matches the git HEAD version." The user can still switch to file view to see and comment on the full file.

#### `FR-diff-refresh` -- Refresh the diff
The user can manually trigger a refresh of the diff by clicking a refresh button in the diff view toolbar. This re-fetches both the working copy and the HEAD version from the server and recomputes the diff. Refreshing clears all existing comments in diff view (because line positions may have shifted) and displays a confirmation dialog if comments exist, similar to the mode-switch behavior.

### Non-Functional Requirements

#### `NFR-diff-compute-perf` -- Diff computation performance
The diff computation must complete within 500ms for files up to 10,000 lines. For files between 10,000 and 50,000 lines, the diff should complete within 2 seconds. The computation runs on the main thread but should not block UI rendering for more than 100ms at a time; if files are large enough to cause blocking, the computation should be deferred to a Web Worker.

#### `NFR-diff-render-perf` -- Diff view rendering performance
The diff view must use the same virtualized scrolling approach as the file view (`NFR-crp-large-file-perf`). Scrolling through a diff of a 10,000-line file must be smooth with no visible jank exceeding 200ms.

#### `NFR-diff-client-compute` -- Client-side diff computation
Consistent with `NFR-crp-client-only`, the diff computation happens entirely in the browser. The server provides the two file versions (HEAD and working copy) as plain text; the server does not run `git diff` or any diff algorithm. This keeps the server simple and the architecture consistent.

#### `NFR-diff-baseline-fetch-speed` -- Baseline fetch latency
Fetching the git HEAD version of a file via the API should complete within 500ms for files up to 10,000 lines. This is a server-side target; the endpoint reads the file from the git object store (e.g., via `git show HEAD:<path>`).

#### `NFR-diff-accessibility` -- Diff view keyboard accessibility
All diff view interactions — toggling diff mode, expanding collapsed sections, adding comments on diff lines, navigating between comments — must be achievable via keyboard alone, consistent with `NFR-crp-accessibility-keyboard`.

## Acceptance Criteria

#### `AC-diff-toggle-to-diff` -- User can switch to diff view
**Given** a file is loaded via the slash command and has changes relative to git HEAD, **when** the user clicks the "Diff" toggle in the toolbar, **then** the code viewer switches to show a unified diff with added lines highlighted green and removed lines highlighted red.

#### `AC-diff-toggle-to-file` -- User can switch back to file view
**Given** the diff view is active, **when** the user clicks the "File" toggle in the toolbar, **then** the code viewer switches back to showing the full file content, and any diff-mode comments are cleared (with confirmation if comments existed).

#### `AC-diff-collapse-default` -- Unchanged sections are collapsed by default
**Given** a file has changes on lines 10-12 and lines 200-205 with 185 unchanged lines between them, **when** the diff view renders, **then** 3 lines of context are shown above and below each change, and the unchanged lines between them are collapsed with a separator showing the count of hidden lines.

#### `AC-diff-expand-section` -- Collapsed section can be expanded
**Given** a collapsed section showing "... 47 unchanged lines ...", **when** the user clicks on the collapsed section separator, **then** all 47 hidden lines are revealed and the separator disappears.

#### `AC-diff-comment-added-line` -- Comment can be placed on an added line
**Given** the diff view is active and shows line 15 as an added line (green, with `+` indicator), **when** the user clicks the gutter for that line and submits the comment "This variable name is unclear", **then** the comment is attached to that added line and the comment gutter shows an indicator.

#### `AC-diff-comment-removed-line` -- Comment can be placed on a removed line
**Given** the diff view is active and shows an old line 42 as a removed line (red, with `-` indicator), **when** the user clicks the gutter for that line and submits the comment "This should not have been removed", **then** the comment is attached to that removed line.

#### `AC-diff-comment-context-line` -- Comment can be placed on a context line
**Given** the diff view is active and shows line 30 as a context (unchanged) line, **when** the user clicks the gutter for that line and submits a comment, **then** the comment is attached to that context line.

#### `AC-diff-prompt-includes-diff` -- Generated prompt includes diff notation
**Given** the diff view is active with comments on added and removed lines, **when** the user generates a prompt, **then** the prompt contains code blocks using unified diff notation (lines prefixed with `+`, `-`, or space) so the AI agent can see the change context alongside each comment.

#### `AC-diff-no-git-history` -- Untracked file shows all lines as added
**Given** a file loaded via the slash command has no git history (newly created, untracked), **when** the user activates diff view, **then** all lines are displayed as additions (green, with `+` indicator) and no removed or context lines are shown.

#### `AC-diff-no-changes` -- Unchanged file shows empty state
**Given** a file loaded via the slash command is identical to its git HEAD version, **when** the user activates diff view, **then** the diff view displays "No changes detected" and the user can switch to file view.

#### `AC-diff-paste-upload-disabled` -- Diff toggle is disabled for paste/upload files
**Given** a file is loaded via paste or upload (not via the slash command), **when** the user looks at the toolbar, **then** the diff view toggle is visible but disabled, with a tooltip explaining that diff view requires a server-loaded file.

#### `AC-diff-line-numbers` -- Diff shows old and new line numbers
**Given** the diff view is active, **when** the user looks at any diff line, **then** added lines show only a new (right) line number, removed lines show only an old (left) line number, and context lines show both old and new line numbers.

#### `AC-diff-syntax-highlight` -- Diff lines are syntax highlighted
**Given** a TypeScript file is loaded and diff view is active, **when** the diff renders, **then** both added and removed lines display syntax-appropriate coloring for keywords, strings, and comments, consistent with `FR-crp-syntax-highlight`.

#### `AC-diff-refresh-updates` -- Refresh re-fetches and recomputes the diff
**Given** the diff view is active and the file has been modified on disk since the diff was last computed, **when** the user clicks the refresh button, **then** the diff is recomputed with the latest file content and the view updates accordingly.

#### `AC-diff-switch-clears-comments` -- Switching modes clears comments with confirmation
**Given** the user has added comments in diff view, **when** the user clicks the "File" toggle, **then** a confirmation dialog appears warning that comments will be cleared. If confirmed, comments are cleared and the mode switches. If cancelled, the mode stays on diff view and comments are preserved.

#### `AC-diff-comment-range` -- Comment can span a range of diff lines
**Given** the diff view is active, **when** the user selects a contiguous range of 3 visible diff lines (e.g., one removed line and two added lines) and adds a comment, **then** the comment is attached to all 3 lines and the gutter shows indicators for the entire range.

#### `AC-diff-expand-then-comment` -- User can comment on lines after expanding a collapsed section
**Given** a collapsed section is expanded revealing previously hidden context lines, **when** the user clicks the gutter on one of the newly revealed lines and submits a comment, **then** the comment is attached to that line.

## Open Questions

1. **Context line count configuration**: The default context is 3 lines (matching GitHub). Should this be user-configurable (e.g., a dropdown allowing 1, 3, 5, 10, or "all")? If so, where does the control live? For v1, a fixed default of 3 lines is assumed. Configuration can be added later.

2. **Word-level diff highlighting**: GitHub highlights the specific changed words/characters within changed lines (intraline diff). Should this feature include word-level highlighting within added/removed lines, or is line-level highlighting sufficient for v1? Line-level is assumed for v1 to keep scope tight.

3. **Side-by-side view**: Should the diff support a side-by-side (split) view in addition to the unified view? Deferred; unified-only for v1.

4. **Comment preservation across refresh**: Currently, refreshing the diff clears comments because line positions may shift. Could we attempt to re-anchor comments based on content matching? Deferred for v1; clear-on-refresh is simpler and safer.

5. **Multiple baseline sources**: This PRD assumes the baseline is always git HEAD. Should other baselines be supported (e.g., a specific commit, a branch, or the staged version)? Deferred; HEAD-only for v1.

6. **Binary file handling in HEAD endpoint**: If the HEAD version of a file is binary (e.g., the file was converted from binary to text), how should the endpoint respond? For v1, the HEAD endpoint applies the same binary detection as the existing file API and returns 415 for binary HEAD content.

7. **Submodule and worktree support**: Files inside git submodules or secondary worktrees may require different `git show` invocations. Should v1 handle these cases or treat them as out of scope? Flagged for engineering to evaluate.

8. **Large diff performance**: For files where nearly every line has changed (e.g., a reformatter ran), the diff may be as large as the file itself. Should there be a warning or alternative rendering for extremely large diffs (e.g., > 5,000 changed lines)? Deferred; the same large-file warning from `NFR-crp-large-file-perf` should apply.

## Dependencies

- **`FR-crp-file-display`**: The diff view renders within the same code viewer component, extending it with diff-specific rendering (line type indicators, dual line numbers, background colors).
- **`FR-crp-syntax-highlight`**: Both added and removed lines in the diff are syntax-highlighted using the same Shiki-based highlighting.
- **`FR-crp-line-comment-create`**: The comment creation interaction in diff view mirrors the existing file view interaction.
- **`FR-crp-line-range-comment`**: Range commenting in diff view extends the existing range comment mechanism.
- **`FR-crp-prompt-format`**: The diff-aware prompt format builds on the existing structured prompt format, adapting it for diff context.
- **`FR-sc-file-api`**: The existing file-serving API endpoint is extended with a new `/api/file/head` endpoint to serve the git HEAD version.
- **`FR-sc-auto-load-file`**: Diff view relies on the server-loaded file mechanism to know the file's path, which is needed to fetch the HEAD version.
- **`NFR-crp-client-only`**: The diff computation must happen client-side. The server provides raw file content only.
- **`NFR-crp-large-file-perf`**: The diff view must meet the same scrolling performance targets as the file view.
- **Git**: The file-serving server must have access to the git repository containing the target file to serve the HEAD version. If git is not available or the file is outside a git repository, the HEAD endpoint returns an appropriate error.
