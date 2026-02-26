# Working Copy Diff View -- Test Plan

> Based on requirements in `../../product/diff-view.md`
> Based on design in `../../design/web/diff-view.md`
> Based on technical spec in `../../engineering/web/diff-view.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-diff-toggle-to-diff` | `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-keyboard`, `TC-diff-toggle-to-diff-loading-state` | Not started |
| `AC-diff-toggle-to-file` | `TC-diff-toggle-to-file-happy`, `TC-diff-toggle-to-file-no-comments` | Not started |
| `AC-diff-collapse-default` | `TC-diff-collapse-default-happy`, `TC-diff-collapse-gap-boundary`, `TC-diff-collapse-leading-trailing`, `TC-diff-collapse-adjacent-hunks-small-gap` | Not started |
| `AC-diff-expand-section` | `TC-diff-expand-section-click`, `TC-diff-expand-section-keyboard`, `TC-diff-expand-section-no-recollapse` | Not started |
| `AC-diff-comment-added-line` | `TC-diff-comment-added-line-happy`, `TC-diff-comment-added-line-label` | Not started |
| `AC-diff-comment-removed-line` | `TC-diff-comment-removed-line-happy`, `TC-diff-comment-removed-line-label` | Not started |
| `AC-diff-comment-context-line` | `TC-diff-comment-context-line-happy`, `TC-diff-comment-context-line-label` | Not started |
| `AC-diff-prompt-includes-diff` | `TC-diff-prompt-includes-diff-happy`, `TC-diff-prompt-diff-notation`, `TC-diff-prompt-comment-labels`, `TC-diff-prompt-collapsed-markers` | Not started |
| `AC-diff-no-git-history` | `TC-diff-no-git-history-all-added`, `TC-diff-no-git-history-no-collapse` | Not started |
| `AC-diff-no-changes` | `TC-diff-no-changes-empty-state`, `TC-diff-no-changes-switch-to-file` | Not started |
| `AC-diff-paste-upload-disabled` | `TC-diff-paste-disabled`, `TC-diff-upload-disabled`, `TC-diff-drag-drop-disabled`, `TC-diff-disabled-tooltip` | Not started |
| `AC-diff-line-numbers` | `TC-diff-line-numbers-added`, `TC-diff-line-numbers-removed`, `TC-diff-line-numbers-context` | Not started |
| `AC-diff-syntax-highlight` | `TC-diff-syntax-highlight-happy`, `TC-diff-syntax-highlight-removed-lines` | Not started |
| `AC-diff-refresh-updates` | `TC-diff-refresh-happy`, `TC-diff-refresh-with-comments-confirm`, `TC-diff-refresh-with-comments-cancel`, `TC-diff-refresh-no-comments` | Not started |
| `AC-diff-switch-clears-comments` | `TC-diff-switch-clears-comments-confirm`, `TC-diff-switch-clears-comments-cancel`, `TC-diff-switch-no-comments-no-dialog` | Not started |
| `AC-diff-comment-range` | `TC-diff-comment-range-same-type`, `TC-diff-comment-range-mixed-types`, `TC-diff-comment-range-blocked-by-collapsed` | Not started |
| `AC-diff-expand-then-comment` | `TC-diff-expand-then-comment-happy`, `TC-diff-expand-then-comment-gutter-hover` | Not started |

---

## Test Cases

---

### View Mode Toggle

---

#### `TC-diff-toggle-to-diff-happy`: Switch from file view to diff view

- **Type**: E2E
- **Covers**: `AC-diff-toggle-to-diff`, `FR-diff-mode-toggle`, `FR-diff-baseline-fetch`
- **Preconditions**: A file with changes relative to git HEAD is loaded via the `/shepherd` slash command (server-loaded). The toolbar shows the view mode toggle with "File" active.
- **Steps**:
  1. Observe the toolbar: the view mode toggle shows "File" as the active (blue background) segment and "Diff" as inactive but enabled.
  2. Click the "Diff" segment.
  3. Observe the loading state in the code viewer panel.
  4. Wait for the diff to render.
- **Expected Result**: After clicking "Diff", the code viewer panel briefly shows "Loading baseline..." with a spinner. Once loading completes, the panel displays a unified diff with added lines highlighted green (`#F0FDF4` background, `+` indicator), removed lines highlighted red (`#FEF2F2` background, `-` indicator), and context lines with white background. The "Diff" segment is now active (blue background) and the "File" segment is inactive. The refresh button appears in the toolbar.
- **Edge Cases**:
  - Clicking "Diff" when it is already active: nothing happens, no re-fetch.
  - Clicking "Diff" while a baseline fetch is already in progress: should not trigger a second fetch.

---

#### `TC-diff-toggle-to-diff-keyboard`: Switch to diff view via keyboard

- **Type**: E2E
- **Covers**: `AC-diff-toggle-to-diff`, `NFR-diff-accessibility`
- **Preconditions**: A file is loaded via the slash command. Focus is anywhere on the page.
- **Steps**:
  1. Press `Tab` until focus reaches the view mode toggle.
  2. Press `ArrowRight` to move focus to the "Diff" segment.
  3. Press `Enter`.
- **Expected Result**: The view switches to diff mode, identical to the mouse interaction. Focus ring is visible on the "Diff" segment before activation. After activation, focus moves to the first visible diff line.
- **Edge Cases**:
  - Pressing `Space` instead of `Enter`: should also activate the segment.
  - Pressing `ArrowLeft` when already on the "File" segment: focus stays on "File" (no wrap-around).

---

#### `TC-diff-toggle-to-diff-loading-state`: Loading state while baseline is fetched

- **Type**: Integration
- **Covers**: `AC-diff-toggle-to-diff`, `FR-diff-baseline-fetch`
- **Preconditions**: A file is loaded via the slash command. Network latency is simulated or the file is large enough to observe a loading state.
- **Steps**:
  1. Click the "Diff" segment.
  2. Observe the code viewer panel during the fetch.
  3. Observe the refresh button in the toolbar.
- **Expected Result**: The code viewer panel shows a centered spinner (24px, primary blue) with "Loading baseline..." text below it. The toolbar refresh button is visible and in its spinning/disabled state. After the fetch completes, the loading state is replaced by the diff viewer or an appropriate state (empty diff, error, or all-added for untracked files).
- **Edge Cases**:
  - If the fetch fails with a network error: `DiffErrorState` banner is shown with "Failed to fetch the baseline version." and a "Retry" link.

---

#### `TC-diff-toggle-to-file-happy`: Switch back from diff view to file view

- **Type**: E2E
- **Covers**: `AC-diff-toggle-to-file`, `FR-diff-mode-toggle`
- **Preconditions**: Diff view is active with a rendered diff. No comments exist in diff mode.
- **Steps**:
  1. Click the "File" segment in the view mode toggle.
- **Expected Result**: The code viewer switches back to showing the full file content with absolute line numbers. The "File" segment becomes active. The "Diff" segment becomes inactive. The refresh button disappears from the toolbar. The preamble text is preserved (not cleared). The view shows the complete file with the standard single line-number gutter.
- **Edge Cases**:
  - Clicking "File" when it is already active: nothing happens.

---

#### `TC-diff-toggle-to-file-no-comments`: Switch to file view with no comments does not show dialog

- **Type**: Integration
- **Covers**: `AC-diff-switch-clears-comments`, `FR-diff-mode-toggle`
- **Preconditions**: Diff view is active. Zero comments exist in diff mode.
- **Steps**:
  1. Click the "File" segment.
- **Expected Result**: The view switches immediately to file mode without any confirmation dialog.
- **Edge Cases**: None.

---

### Diff Toggle Disabled State

---

#### `TC-diff-paste-disabled`: Diff toggle is disabled for pasted files

- **Type**: E2E
- **Covers**: `AC-diff-paste-upload-disabled`, `FR-diff-mode-availability`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Click "Paste content" and paste valid code into the text area.
  2. Click "Load".
  3. Observe the view mode toggle in the toolbar.
  4. Attempt to click the "Diff" segment.
- **Expected Result**: The view mode toggle is visible. The "File" segment is active. The "Diff" segment is visually disabled (off-white background `#F1F5F9`, muted text `#94A3B8`). Clicking the "Diff" segment does nothing. The cursor shows `not-allowed` when hovering over it.
- **Edge Cases**: None.

---

#### `TC-diff-upload-disabled`: Diff toggle is disabled for uploaded files

- **Type**: E2E
- **Covers**: `AC-diff-paste-upload-disabled`, `FR-diff-mode-availability`
- **Preconditions**: Application is in the initial empty state. A text file exists on the filesystem.
- **Steps**:
  1. Click "Choose file" and select a text file.
  2. Observe the view mode toggle.
- **Expected Result**: The "Diff" segment is disabled, identical to paste behavior. Clicking it does nothing.
- **Edge Cases**: None.

---

#### `TC-diff-drag-drop-disabled`: Diff toggle is disabled for drag-and-drop files

- **Type**: E2E
- **Covers**: `AC-diff-paste-upload-disabled`, `FR-diff-mode-availability`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Drag and drop a text file onto the application drop zone.
  2. Observe the view mode toggle.
- **Expected Result**: The "Diff" segment is disabled.
- **Edge Cases**: None.

---

#### `TC-diff-disabled-tooltip`: Disabled diff segment shows explanatory tooltip

- **Type**: E2E
- **Covers**: `AC-diff-paste-upload-disabled`, `FR-diff-mode-availability`
- **Preconditions**: A file is loaded via paste, upload, or drag-and-drop. The "Diff" segment is disabled.
- **Steps**:
  1. Hover the mouse over the disabled "Diff" segment and hold for 300ms.
  2. Observe the tooltip.
  3. Move the mouse away.
- **Expected Result**: After a 300ms delay, a tooltip appears below the "Diff" segment with the text: "Diff view requires a file loaded via the /shepherd command". The tooltip has a dark background (`#1E293B`), white text (`#FFFFFF`), 12px font, and a box-shadow. When the mouse moves away, the tooltip disappears immediately.
- **Edge Cases**:
  - Moving the mouse onto the tooltip itself: tooltip should remain visible while the hover is within the segment area.
  - Tooltip is also accessible via `aria-describedby` for screen readers.

---

### Diff Computation

---

#### `TC-diff-compute-correct-hunks`: Diff correctly identifies added, removed, and context lines

- **Type**: Unit
- **Covers**: `FR-diff-compute`, `AC-diff-line-numbers`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Call `computeFileDiff` with old content:
     ```
     line one
     line two
     line three
     ```
     and new content:
     ```
     line one
     line TWO
     line three
     ```
- **Expected Result**: The result contains 3 `DiffLine` entries: one context line ("line one" with oldLineNumber=1, newLineNumber=1), one removed line ("line two" with oldLineNumber=2, newLineNumber=null), one added line ("line TWO" with oldLineNumber=null, newLineNumber=2), and one context line ("line three" with oldLineNumber=3, newLineNumber=3). `isEmpty` is false.
- **Edge Cases**:
  - Blank lines in the diff: should be treated as context lines if unchanged, or added/removed if changed.

---

#### `TC-diff-compute-empty-diff`: Diff computation detects no changes

- **Type**: Unit
- **Covers**: `FR-diff-compute`, `AC-diff-no-changes`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Call `computeFileDiff` with identical old and new content.
- **Expected Result**: The result has `isEmpty: true`, `diffLines` is an empty array, and `collapsedSections` is an empty array.
- **Edge Cases**:
  - Both files are empty strings: `isEmpty` should be true.
  - Both files are a single empty line (`\n`): `isEmpty` should be true.

---

#### `TC-diff-compute-all-added`: Untracked file produces all-added diff

- **Type**: Unit
- **Covers**: `FR-diff-compute`, `AC-diff-no-git-history`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Call `computeFileDiff` with an empty string as old content and a 10-line file as new content.
- **Expected Result**: All lines in the result are type `'added'`. Each line has `oldLineNumber: null` and a sequential `newLineNumber` starting at 1. No context or removed lines exist. `collapsedSections` is empty (no unchanged sections to collapse).
- **Edge Cases**:
  - Single-line new content: one added line.

---

#### `TC-diff-compute-all-removed`: File emptied produces all-removed diff

- **Type**: Unit
- **Covers**: `FR-diff-compute`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Call `computeFileDiff` with a 10-line file as old content and an empty string as new content.
- **Expected Result**: All lines in the result are type `'removed'`. Each line has `newLineNumber: null` and a sequential `oldLineNumber` starting at 1. No context or added lines exist.
- **Edge Cases**:
  - Single-line old content being removed: one removed line.

---

#### `TC-diff-compute-every-line-changed`: Reformatter changes every line

- **Type**: Unit
- **Covers**: `FR-diff-compute`, `NFR-diff-compute-perf`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Create old content with 100 lines using 2-space indentation.
  2. Create new content with the same 100 lines using 4-space indentation (every line differs).
  3. Call `computeFileDiff`.
- **Expected Result**: The diff contains 100 removed lines and 100 added lines, interleaved in hunks. No context lines appear because every line changed. `collapsedSections` is empty (no unchanged sections). The computation completes without error.
- **Edge Cases**:
  - File where trailing whitespace is added to every line: all lines show as changed.

---

#### `TC-diff-compute-no-newline-at-end`: File with no trailing newline

- **Type**: Unit
- **Covers**: `FR-diff-compute`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Call `computeFileDiff` with old content `"line one\nline two"` (no trailing newline) and new content `"line one\nline two\n"` (trailing newline added).
- **Expected Result**: The diff shows the last line as changed (removed version without newline, added version with newline) or as a context line with a "no newline at end of file" marker, depending on the jsdiff output. The diff completes without error and does not crash.
- **Edge Cases**:
  - Both files have no trailing newline: should diff correctly without artifacts.
  - Old file has newline, new file does not: diff should show this as a change.

---

#### `TC-diff-compute-performance-10k`: Diff computation under 500ms for 10K lines

- **Type**: Unit (performance)
- **Covers**: `NFR-diff-compute-perf`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Generate a 10,000-line old file.
  2. Generate a new file with ~20% of lines changed (every 5th line modified).
  3. Record the start time.
  4. Call `computeFileDiff`.
  5. Record the end time.
- **Expected Result**: The computation completes in under 500ms. The result is a valid diff with the expected number of added and removed lines.
- **Edge Cases**:
  - 50,000-line file with moderate changes: should complete in under 2 seconds.
  - 10,000-line file where every line is different: should still complete in under 500ms.

---

### Collapse / Expand

---

#### `TC-diff-collapse-default-happy`: Unchanged sections are collapsed by default

- **Type**: E2E
- **Covers**: `AC-diff-collapse-default`, `FR-diff-collapse`
- **Preconditions**: A file is loaded via the slash command. The file has changes on lines 10-12 and lines 200-205, with approximately 185 unchanged lines between them.
- **Steps**:
  1. Switch to diff view.
  2. Observe the rendered diff.
- **Expected Result**: Three lines of context are shown above the first change (lines 7-9). Three lines of context are shown below the first change (lines 13-15). A collapsed section separator is shown between the two change regions, indicating the count of hidden unchanged lines (approximately "... N unchanged lines ..."). Three lines of context are shown above the second change (lines 197-199). Three lines of context are shown below the second change (lines 206-208). Leading context before line 7 and trailing context after line 208 are also collapsed.
- **Edge Cases**:
  - Changes on the first 3 lines of the file: no leading collapsed section (no context lines above to collapse).
  - Changes on the last 3 lines of the file: no trailing collapsed section.

---

#### `TC-diff-collapse-gap-boundary`: Boundary case for collapse threshold (2*context+1 lines)

- **Type**: Unit
- **Covers**: `AC-diff-collapse-default`, `FR-diff-collapse`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Create a file where two changes are separated by exactly 7 unchanged lines (2*3 + 1, with default context of 3).
  2. Compute the diff.
  3. Create another file where two changes are separated by exactly 8 unchanged lines.
  4. Compute the diff.
- **Expected Result**: With 7 unchanged lines between changes: all 7 lines are shown without collapsing (the gap is not large enough to collapse). With 8 unchanged lines between changes: the gap is collapsed -- 3 lines of trailing context after the first change, a collapsed separator hiding 2 lines, and 3 lines of leading context before the second change are shown.
- **Edge Cases**:
  - Gap of exactly 6 unchanged lines: shown without collapsing (6 <= 2*3).
  - Gap of exactly 1 unchanged line: shown without collapsing.

---

#### `TC-diff-collapse-leading-trailing`: Leading and trailing context are collapsed

- **Type**: Unit
- **Covers**: `AC-diff-collapse-default`, `FR-diff-collapse`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Create a file with 100 lines. Add a change on line 50.
  2. Compute the diff.
- **Expected Result**: Lines 1-46 are collapsed (leading context, showing only lines 47-49 as context before the change). Lines 51-53 are shown as trailing context. Lines 54-100 are collapsed (trailing context).
- **Edge Cases**:
  - Change on line 1: no leading collapsed section; 3 trailing context lines shown, rest collapsed.
  - Change on the last line: no trailing collapsed section; 3 leading context lines shown, rest collapsed.
  - Change on line 4: lines 1-3 shown as leading context (exactly 3), no leading collapse.

---

#### `TC-diff-collapse-adjacent-hunks-small-gap`: Adjacent hunks with small gap show all lines

- **Type**: Unit
- **Covers**: `AC-diff-collapse-default`, `FR-diff-collapse`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Create a file with changes on lines 10-12 and lines 16-18 (3 unchanged lines between: 13, 14, 15).
  2. Compute the diff.
- **Expected Result**: All lines between the two changes (13, 14, 15) are shown as context. No collapsed separator appears between the hunks because the gap (3 lines) is well below the threshold (7 lines).
- **Edge Cases**: None.

---

#### `TC-diff-expand-section-click`: Expand a collapsed section by clicking

- **Type**: E2E
- **Covers**: `AC-diff-expand-section`, `FR-diff-expand`
- **Preconditions**: Diff view is active with at least one collapsed section separator visible, showing "... N unchanged lines ...".
- **Steps**:
  1. Note the number N of hidden lines shown on the separator.
  2. Click anywhere on the collapsed section separator row.
  3. Observe the expansion animation and resulting view.
- **Expected Result**: The separator fades out (100ms). The hidden N lines appear with a height-expansion animation (150ms ease-out). The newly revealed lines are context lines (white background, both old and new line numbers, blank type indicator). The separator is gone and cannot be re-collapsed. The scroll position is adjusted to keep the surrounding content stable.
- **Edge Cases**:
  - Clicking the "Expand" text link specifically: should work the same as clicking anywhere on the row.
  - Rapidly clicking the separator multiple times: only one expansion occurs, no errors.

---

#### `TC-diff-expand-section-keyboard`: Expand a collapsed section via keyboard

- **Type**: E2E
- **Covers**: `AC-diff-expand-section`, `NFR-diff-accessibility`
- **Preconditions**: Diff view is active with at least one collapsed section. Focus is in the diff viewer.
- **Steps**:
  1. Use `ArrowDown` to navigate focus to the collapsed section separator.
  2. Verify the focus ring is visible on the separator.
  3. Press `Enter`.
- **Expected Result**: The section expands. Focus moves to the first newly revealed line. The separator is replaced by the revealed context lines.
- **Edge Cases**:
  - Pressing `Space` instead of `Enter`: should also trigger expansion.
  - Pressing `Tab` to land on the separator (rather than ArrowDown): should also work because the separator has `tabindex="0"`.

---

#### `TC-diff-expand-section-no-recollapse`: Expanded sections cannot be re-collapsed

- **Type**: E2E
- **Covers**: `AC-diff-expand-section`, `FR-diff-expand`
- **Preconditions**: Diff view is active with a collapsed section.
- **Steps**:
  1. Expand a collapsed section by clicking on it.
  2. Look for any mechanism to re-collapse the section (a toggle, a button, a double-click, etc.).
- **Expected Result**: There is no UI mechanism to re-collapse an expanded section. The lines remain visible until the user switches away from diff view or loads a new file. This matches GitHub's behavior.
- **Edge Cases**: None.

---

### Comments on Diff Lines

---

#### `TC-diff-comment-added-line-happy`: Add a comment on an added line

- **Type**: E2E
- **Covers**: `AC-diff-comment-added-line`, `FR-diff-comment-create`
- **Preconditions**: Diff view is active and shows at least one added line (green background, `+` indicator).
- **Steps**:
  1. Hover over an added line. Observe the comment gutter.
  2. Click the "+" icon in the comment gutter for that added line.
  3. Type "This variable name is unclear" in the inline comment editor.
  4. Click the "Comment" button (or press `Cmd+Enter`).
- **Expected Result**: A faint "+" icon appears in the comment gutter on hover. After clicking, the InlineCommentEditor opens below the line. After submitting, a CommentBubble appears below the line with the text "This variable name is unclear". The comment gutter shows a blue dot indicator on that line. The toolbar comment count increments to 1.
- **Edge Cases**:
  - Submitting an empty comment: the "Comment" button should be disabled when the text area is empty.
  - Cancelling the comment (pressing Escape or clicking Cancel): the editor closes, no comment is created, comment count stays the same.

---

#### `TC-diff-comment-added-line-label`: Comment bubble for added line shows correct label

- **Type**: Integration
- **Covers**: `AC-diff-comment-added-line`, `FR-diff-comment-create`
- **Preconditions**: A comment has been placed on an added line (new line number 15).
- **Steps**:
  1. Observe the CommentBubble label text.
- **Expected Result**: The CommentBubble shows the label "Line +15" (using the `+` prefix and the new line number).
- **Edge Cases**: None.

---

#### `TC-diff-comment-removed-line-happy`: Add a comment on a removed line

- **Type**: E2E
- **Covers**: `AC-diff-comment-removed-line`, `FR-diff-comment-create`
- **Preconditions**: Diff view is active and shows at least one removed line (red background, `-` indicator).
- **Steps**:
  1. Click the comment gutter for a removed line (old line number 42).
  2. Type "This should not have been removed" in the editor.
  3. Submit the comment.
- **Expected Result**: The comment is created and a CommentBubble appears below the removed line. The comment gutter shows a blue dot on that line. The toolbar comment count increments.
- **Edge Cases**:
  - Commenting on consecutive removed lines individually: each gets its own CommentBubble with the correct old line number.

---

#### `TC-diff-comment-removed-line-label`: Comment bubble for removed line shows correct label

- **Type**: Integration
- **Covers**: `AC-diff-comment-removed-line`, `FR-diff-comment-create`
- **Preconditions**: A comment has been placed on a removed line (old line number 42).
- **Steps**:
  1. Observe the CommentBubble label text.
- **Expected Result**: The CommentBubble shows the label "Line -42" (using the `-` prefix and the old line number).
- **Edge Cases**: None.

---

#### `TC-diff-comment-context-line-happy`: Add a comment on a context line

- **Type**: E2E
- **Covers**: `AC-diff-comment-context-line`, `FR-diff-comment-create`
- **Preconditions**: Diff view is active and shows context (unchanged) lines.
- **Steps**:
  1. Click the comment gutter for a context line (old line 30, new line 30).
  2. Type a comment and submit.
- **Expected Result**: The comment is created and attached to the context line. The CommentBubble appears below the line with the correct label. The gutter shows a blue dot indicator.
- **Edge Cases**:
  - Context line that appears after an expansion (previously collapsed): commenting should work identically.

---

#### `TC-diff-comment-context-line-label`: Comment bubble for context line shows correct label

- **Type**: Integration
- **Covers**: `AC-diff-comment-context-line`, `FR-diff-comment-create`
- **Preconditions**: A comment has been placed on a context line (new line number 30).
- **Steps**:
  1. Observe the CommentBubble label text.
- **Expected Result**: The CommentBubble shows the label "Line 30" (using the new line number, no prefix).
- **Edge Cases**: None.

---

### Range Comments

---

#### `TC-diff-comment-range-same-type`: Range comment spanning multiple added lines

- **Type**: E2E
- **Covers**: `AC-diff-comment-range`, `FR-diff-comment-on-range`
- **Preconditions**: Diff view is active and shows at least 3 consecutive added lines.
- **Steps**:
  1. Click the gutter on the first added line in the group.
  2. Hold `Shift` and click the gutter on the third added line.
  3. Type a comment in the editor and submit.
- **Expected Result**: A blue selection overlay appears on all 3 lines. After submitting, the CommentBubble shows a range label like "Lines +4 to +6". The gutter shows indicators for all 3 lines.
- **Edge Cases**:
  - Range of 2 added lines: label shows "Lines +N to +M".
  - Single line selected via Shift+click on the same line: treated as a single-line comment.

---

#### `TC-diff-comment-range-mixed-types`: Range comment spanning removed and added lines

- **Type**: E2E
- **Covers**: `AC-diff-comment-range`, `FR-diff-comment-on-range`
- **Preconditions**: Diff view is active and shows adjacent removed and added lines (e.g., one removed line followed by two added lines).
- **Steps**:
  1. Click the gutter on the removed line.
  2. Hold `Shift` and click on the second added line.
  3. Type a comment and submit.
- **Expected Result**: The selection highlight shows over all 3 lines, with the blue overlay composited over each line's type-specific background color. After submitting, the CommentBubble label shows "Lines -10 to +12" (using the old line number for the removed start and the new line number for the added end).
- **Edge Cases**:
  - Range spanning context, removed, and added lines: label uses appropriate prefixes for each endpoint. Type descriptor in the prompt is "(mixed)".
  - Range of only context lines: label shows "Lines 5-8" (new line numbers, no prefix).

---

#### `TC-diff-comment-range-blocked-by-collapsed`: Range selection cannot span a collapsed section

- **Type**: E2E
- **Covers**: `AC-diff-comment-range`, `FR-diff-comment-on-range`
- **Preconditions**: Diff view is active with a collapsed section between two visible regions.
- **Steps**:
  1. Click the gutter on a visible line above the collapsed section.
  2. Hold `Shift` and click on a visible line below the collapsed section.
- **Expected Result**: The selection stops at the last visible line before the collapsed section. The selection does not span across the separator. The user is not able to create a range comment that includes hidden lines.
- **Edge Cases**:
  - Using `Shift+ArrowDown` from the last line before a separator: selection stops at that line.

---

### Expand Then Comment

---

#### `TC-diff-expand-then-comment-happy`: Comment on a line after expanding a collapsed section

- **Type**: E2E
- **Covers**: `AC-diff-expand-then-comment`, `FR-diff-expand`, `FR-diff-comment-create`
- **Preconditions**: Diff view is active with a collapsed section.
- **Steps**:
  1. Click the collapsed section separator to expand it.
  2. Identify one of the newly revealed context lines.
  3. Click the comment gutter on that line.
  4. Type a comment and submit.
- **Expected Result**: The comment is created and attached to the newly revealed context line. A CommentBubble appears below the line. The gutter shows a blue dot indicator. The comment is included in any subsequent prompt generation.
- **Edge Cases**:
  - Expanding multiple sections and commenting on lines in each: all comments are tracked and ordered correctly.

---

#### `TC-diff-expand-then-comment-gutter-hover`: Gutter hover works on newly expanded lines

- **Type**: E2E
- **Covers**: `AC-diff-expand-then-comment`
- **Preconditions**: Diff view is active. A collapsed section has just been expanded.
- **Steps**:
  1. Hover over the comment gutter area of a newly revealed line.
- **Expected Result**: A faint "+" icon appears in the comment gutter, identical to the behavior on lines that were visible from the start.
- **Edge Cases**: None.

---

### Prompt Generation from Diff

---

#### `TC-diff-prompt-includes-diff-happy`: Generated prompt includes diff notation

- **Type**: Integration
- **Covers**: `AC-diff-prompt-includes-diff`, `FR-diff-prompt-format`
- **Preconditions**: Diff view is active. At least one comment exists on an added line and one on a removed line.
- **Steps**:
  1. Click "Generate" in the toolbar.
  2. Examine the generated prompt in the sidebar preview.
- **Expected Result**: The prompt contains:
  - A `## File: [filename] ([language]) -- Diff View` heading.
  - A fixed preamble explaining diff notation ("Lines prefixed with `+` are additions...").
  - A code block with the `diff` language identifier.
  - Lines within the code block prefixed with `+`, `-`, or space.
  - A `## Requested Changes` section listing comments with diff-aware labels (e.g., "Line +15 (added): ...", "Line -42 (removed): ...").
- **Edge Cases**:
  - Generating with no preamble: the `## Instructions` section is omitted.
  - Generating with a preamble: the `## Instructions` section appears with the preamble text.

---

#### `TC-diff-prompt-diff-notation`: Diff code block uses correct line format

- **Type**: Unit
- **Covers**: `AC-diff-prompt-includes-diff`, `FR-diff-prompt-format`
- **Preconditions**: The `buildDiffPrompt` function is available.
- **Steps**:
  1. Call `buildDiffPrompt` with a diff containing added, removed, and context lines, plus comments.
  2. Parse the output to inspect the diff code block.
- **Expected Result**: Each line in the diff block follows the format: `<prefix><padded-line-number> | <content>`. Added lines use `+` prefix and the new line number. Removed lines use `-` prefix and the old line number. Context lines use ` ` (space) prefix and the new line number. Line numbers are right-aligned and padded to 4 characters.
- **Edge Cases**:
  - Line numbers exceeding 4 digits (e.g., line 10000): padding should accommodate larger numbers.

---

#### `TC-diff-prompt-comment-labels`: Comment labels in prompt use correct type descriptors

- **Type**: Unit
- **Covers**: `AC-diff-prompt-includes-diff`, `FR-diff-prompt-format`
- **Preconditions**: The `buildDiffPrompt` function is available with comments on different line types.
- **Steps**:
  1. Create a `DiffComment` on an added line, a removed line, a context line, and a range spanning added+removed lines.
  2. Call `buildDiffPrompt`.
  3. Parse the "Requested Changes" section.
- **Expected Result**:
  - Added-line comment: "**Line +N** (added): ..."
  - Removed-line comment: "**Line -N** (removed): ..."
  - Context-line comment: "**Line N** (context): ..."
  - Mixed-range comment: "**Lines -A to +B** (mixed): ..."
  - Comments are listed in top-to-bottom order as they appear in the diff.
- **Edge Cases**:
  - Range comment spanning only added lines: "(added)" descriptor.
  - Range comment spanning only removed lines: "(removed)" descriptor.
  - Range comment spanning only context lines: "(context)" descriptor.

---

#### `TC-diff-prompt-collapsed-markers`: Collapsed sections appear as markers in the prompt

- **Type**: Unit
- **Covers**: `AC-diff-prompt-includes-diff`, `FR-diff-prompt-format`
- **Preconditions**: The `buildDiffPrompt` function is available.
- **Steps**:
  1. Call `buildDiffPrompt` with a diff that has collapsed sections (not expanded).
  2. Parse the diff code block.
- **Expected Result**: Collapsed (non-expanded) sections appear in the diff block as `@@ ... N unchanged lines ... @@`. The hidden lines are NOT included in the output. Expanded sections include all their revealed lines.
- **Edge Cases**:
  - All sections expanded: no `@@ ... @@` markers in the output; all lines are included.
  - Multiple collapsed sections: each gets its own marker with the correct line count.

---

### Refresh Behavior

---

#### `TC-diff-refresh-happy`: Refresh re-fetches and recomputes the diff

- **Type**: E2E
- **Covers**: `AC-diff-refresh-updates`, `FR-diff-refresh`
- **Preconditions**: Diff view is active with no comments. The underlying file has been modified on disk since the diff was last computed.
- **Steps**:
  1. Click the refresh button in the toolbar.
  2. Observe the loading state.
  3. Wait for the diff to re-render.
- **Expected Result**: The refresh button enters its spinning/disabled state. The code viewer shows the loading state briefly. After re-fetching, the diff updates to reflect the current file state. New changes appear; previously shown changes may have shifted or disappeared. No confirmation dialog is shown (because no comments existed).
- **Edge Cases**:
  - Refresh when the file has not changed on disk: the diff re-renders identically.

---

#### `TC-diff-refresh-with-comments-confirm`: Refresh with comments shows confirmation, user confirms

- **Type**: E2E
- **Covers**: `AC-diff-refresh-updates`, `FR-diff-refresh`, `AC-diff-switch-clears-comments`
- **Preconditions**: Diff view is active with 3 comments.
- **Steps**:
  1. Click the refresh button.
  2. Observe the confirmation dialog.
  3. Click "Refresh and clear comments".
- **Expected Result**: A confirmation dialog appears with title "Refresh diff?" and body mentioning that all 3 comments will be cleared. After confirming, all comments are cleared (comment count goes to 0), the diff is re-fetched and recomputed.
- **Edge Cases**:
  - Dialog body should show the actual count ("All 3 comments will be cleared").

---

#### `TC-diff-refresh-with-comments-cancel`: Refresh with comments, user cancels

- **Type**: E2E
- **Covers**: `AC-diff-refresh-updates`, `FR-diff-refresh`
- **Preconditions**: Diff view is active with comments.
- **Steps**:
  1. Click the refresh button.
  2. Observe the confirmation dialog.
  3. Click "Cancel" (or press `Escape`).
- **Expected Result**: The dialog closes. The diff is not refreshed. All comments are preserved. The comment count is unchanged.
- **Edge Cases**: None.

---

#### `TC-diff-refresh-no-comments`: Refresh with no comments skips confirmation

- **Type**: Integration
- **Covers**: `AC-diff-refresh-updates`, `FR-diff-refresh`
- **Preconditions**: Diff view is active with zero comments.
- **Steps**:
  1. Click the refresh button.
- **Expected Result**: No confirmation dialog appears. The diff is immediately re-fetched and recomputed. The refresh button enters its spinning state during the fetch.
- **Edge Cases**: None.

---

### Mode Switch with Comments

---

#### `TC-diff-switch-clears-comments-confirm`: Mode switch with comments, user confirms

- **Type**: E2E
- **Covers**: `AC-diff-switch-clears-comments`, `FR-diff-mode-toggle`
- **Preconditions**: Diff view is active with 2 comments.
- **Steps**:
  1. Click the "File" segment in the view mode toggle.
  2. Observe the confirmation dialog.
  3. Click "Switch and clear comments".
- **Expected Result**: A confirmation dialog appears with title "Switch view mode?" and body: "Switching to File view will clear all 2 comments. Comments cannot be transferred between view modes because they are anchored to different line models." After confirming, comments are cleared, the view switches to file mode, the comment count goes to 0, and the preamble is preserved.
- **Edge Cases**:
  - Switching from file mode to diff mode with file-mode comments: the same confirmation dialog appears, but referencing "Diff view" and file-mode comment count.

---

#### `TC-diff-switch-clears-comments-cancel`: Mode switch with comments, user cancels

- **Type**: E2E
- **Covers**: `AC-diff-switch-clears-comments`, `FR-diff-mode-toggle`
- **Preconditions**: Diff view is active with comments.
- **Steps**:
  1. Click the "File" segment.
  2. Click "Cancel" on the confirmation dialog.
- **Expected Result**: The dialog closes. The view stays in diff mode. All comments are preserved. The "Diff" segment remains active.
- **Edge Cases**:
  - Pressing `Escape` instead of clicking Cancel: same behavior.

---

#### `TC-diff-switch-no-comments-no-dialog`: Mode switch with zero comments does not show dialog

- **Type**: Integration
- **Covers**: `AC-diff-switch-clears-comments`, `FR-diff-mode-toggle`
- **Preconditions**: Diff view is active with zero comments.
- **Steps**:
  1. Click the "File" segment.
- **Expected Result**: The view switches immediately to file mode. No confirmation dialog appears.
- **Edge Cases**:
  - Switching from file mode to diff mode with zero file-mode comments: no confirmation dialog.

---

### Line Numbers in Diff View

---

#### `TC-diff-line-numbers-added`: Added lines show only new line number

- **Type**: E2E
- **Covers**: `AC-diff-line-numbers`, `FR-diff-display`
- **Preconditions**: Diff view is active with added lines visible.
- **Steps**:
  1. Inspect an added line (green background, `+` indicator).
  2. Check the old line number (OldLN) and new line number (NewLN) columns.
- **Expected Result**: The OldLN column is empty for added lines. The NewLN column shows the new line number. Both are monospace, 13px, right-aligned, color `#94A3B8`.
- **Edge Cases**: None.

---

#### `TC-diff-line-numbers-removed`: Removed lines show only old line number

- **Type**: E2E
- **Covers**: `AC-diff-line-numbers`, `FR-diff-display`
- **Preconditions**: Diff view is active with removed lines visible.
- **Steps**:
  1. Inspect a removed line (red background, `-` indicator).
  2. Check the OldLN and NewLN columns.
- **Expected Result**: The OldLN column shows the old line number. The NewLN column is empty.
- **Edge Cases**: None.

---

#### `TC-diff-line-numbers-context`: Context lines show both old and new line numbers

- **Type**: E2E
- **Covers**: `AC-diff-line-numbers`, `FR-diff-display`
- **Preconditions**: Diff view is active with context lines visible.
- **Steps**:
  1. Inspect a context line (white background, blank type indicator).
  2. Check the OldLN and NewLN columns.
- **Expected Result**: Both the OldLN and NewLN columns show their respective line numbers.
- **Edge Cases**:
  - After several additions, the old and new line numbers diverge. Verify that the numbering remains correct and synchronized.

---

### Syntax Highlighting in Diff View

---

#### `TC-diff-syntax-highlight-happy`: Added and context lines are syntax highlighted

- **Type**: Integration
- **Covers**: `AC-diff-syntax-highlight`, `FR-diff-display`
- **Preconditions**: A TypeScript file with changes is loaded via the slash command and diff view is active.
- **Steps**:
  1. Observe added lines in the diff that contain TypeScript keywords, strings, or type annotations.
  2. Observe context lines in the diff.
- **Expected Result**: Both added and context lines display syntax highlighting consistent with the `github-light` Shiki theme. Keywords like `const`, `function`, `return` are colored distinctly from strings, comments, and type annotations. The green background of added lines does not interfere with the readability of syntax colors.
- **Edge Cases**:
  - File with no recognized language: lines render as plain text without syntax coloring.

---

#### `TC-diff-syntax-highlight-removed-lines`: Removed lines are syntax highlighted

- **Type**: Integration
- **Covers**: `AC-diff-syntax-highlight`, `FR-diff-display`
- **Preconditions**: A TypeScript file with removed lines is loaded via the slash command and diff view is active.
- **Steps**:
  1. Observe removed lines in the diff that contain TypeScript syntax.
- **Expected Result**: Removed lines are highlighted using tokens from the baseline (HEAD) version's syntax highlighting. The red background does not interfere with syntax color readability.
- **Edge Cases**:
  - A line that was valid syntax in the old version but would not be in the new version (e.g., a removed import that is no longer used): the removed line is highlighted based on the old file's context.

---

### Untracked File (No Git History)

---

#### `TC-diff-no-git-history-all-added`: Untracked file shows all lines as additions

- **Type**: E2E
- **Covers**: `AC-diff-no-git-history`, `FR-diff-baseline-fetch`
- **Preconditions**: A newly created, untracked file (not yet committed to git) is loaded via the slash command.
- **Steps**:
  1. Switch to diff view.
  2. Observe the loading state (the HEAD endpoint will return 404).
  3. Observe the rendered diff.
- **Expected Result**: No error is shown. All lines in the file are displayed as added lines (green background, `+` indicator, only new line numbers shown). No removed or context lines exist. There is no "No changes detected" empty state. The user can add comments on any line.
- **Edge Cases**:
  - A single-line untracked file: one added line displayed.
  - An empty untracked file: this may show as "No changes detected" since the diff between empty and empty is empty. (Flag: behavior for empty untracked file should be clarified -- is it all-added with zero lines or empty diff?)

---

#### `TC-diff-no-git-history-no-collapse`: Untracked file has no collapsed sections

- **Type**: Integration
- **Covers**: `AC-diff-no-git-history`, `FR-diff-collapse`
- **Preconditions**: An untracked file with 50 lines is loaded via the slash command.
- **Steps**:
  1. Switch to diff view.
- **Expected Result**: All 50 lines are visible as added lines. No collapsed section separators appear, because there are no unchanged sections to collapse.
- **Edge Cases**: None.

---

### Empty Diff State

---

#### `TC-diff-no-changes-empty-state`: Unchanged file shows "No changes detected"

- **Type**: E2E
- **Covers**: `AC-diff-no-changes`, `FR-diff-empty-state`
- **Preconditions**: A file loaded via the slash command is identical to its git HEAD version (no modifications).
- **Steps**:
  1. Switch to diff view.
  2. Wait for the baseline to load.
- **Expected Result**: The code viewer panel shows an empty state with a document-equals icon, the title "No changes detected", the description "The working copy matches the git HEAD version. Switch to File view to see and comment on the full file.", and a "Switch to File view" button. The prompt preview shows a placeholder message (no prompt is generated because there are no comments). The comment count is 0.
- **Edge Cases**:
  - File with only whitespace differences (e.g., trailing space added): depends on the diff algorithm -- jsdiff considers whitespace changes as changes, so this should NOT show the empty state.

---

#### `TC-diff-no-changes-switch-to-file`: "Switch to File view" button works

- **Type**: E2E
- **Covers**: `AC-diff-no-changes`, `FR-diff-empty-state`
- **Preconditions**: The empty diff state is displayed.
- **Steps**:
  1. Click the "Switch to File view" button.
- **Expected Result**: The view mode switches to file mode. The code viewer shows the full file content. The view mode toggle shows "File" as active. No confirmation dialog appears (there are no comments to clear).
- **Edge Cases**:
  - Activating the button via keyboard (Tab to it, then Enter): same behavior.

---

### API Endpoint

---

#### `TC-diff-api-head-happy`: HEAD endpoint returns file content at HEAD

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`, `NFR-diff-baseline-fetch-speed`
- **Preconditions**: The Vite dev server is running. A file at a known path exists in the git repository and has been committed.
- **Steps**:
  1. Send `GET /api/file/head?path=<encoded-absolute-path>` to the server.
- **Expected Result**: Response status is 200. `Content-Type` is `text/plain; charset=utf-8`. The body contains the file content as it exists at git HEAD. The `X-File-Lines` header contains the line count.
- **Edge Cases**:
  - Path with spaces or special characters: properly URL-encoded path should work.
  - Path with Unicode characters: should work if the filesystem and git support it.

---

#### `TC-diff-api-head-untracked-404`: HEAD endpoint returns 404 for untracked files

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`, `AC-diff-no-git-history`
- **Preconditions**: A newly created file exists on disk but has never been committed to git.
- **Steps**:
  1. Send `GET /api/file/head?path=<path-to-untracked-file>` to the server.
- **Expected Result**: Response status is 404. Body is JSON: `{"error": "File has no git history: <path>"}`.
- **Edge Cases**:
  - File that was previously committed but then deleted from git tracking: depends on git state, should return 404 if `HEAD:<path>` fails.

---

#### `TC-diff-api-head-not-git-repo`: HEAD endpoint returns 404 for files outside git repo

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: A file exists in a directory that is not inside any git repository.
- **Steps**:
  1. Send `GET /api/file/head?path=<path-outside-git>` to the server.
- **Expected Result**: Response status is 404. Body is JSON: `{"error": "Not a git repository: <path>"}`.
- **Edge Cases**: None.

---

#### `TC-diff-api-head-binary-415`: HEAD endpoint returns 415 for binary HEAD content

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: A file exists that was binary at HEAD (e.g., an image file that was committed).
- **Steps**:
  1. Send `GET /api/file/head?path=<path-to-binary-file>` to the server.
- **Expected Result**: Response status is 415. Body is JSON: `{"error": "Binary file at HEAD not supported: <path>"}`.
- **Edge Cases**:
  - File that was text at HEAD but is now binary on disk: HEAD endpoint returns 200 with text content (the HEAD version is text). The diff may fail on the client side if the working copy is binary, but that is handled by the existing file-loading logic.

---

#### `TC-diff-api-head-missing-path`: HEAD endpoint returns 400 when path is missing

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: The Vite dev server is running.
- **Steps**:
  1. Send `GET /api/file/head` (no `path` query parameter).
- **Expected Result**: Response status is 400. Body is JSON: `{"error": "Missing required query parameter: path"}`.
- **Edge Cases**: None.

---

#### `TC-diff-api-head-git-unavailable`: HEAD endpoint handles git not being installed

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: The Vite dev server is running. Git is not available on the system PATH (or is simulated as unavailable).
- **Steps**:
  1. Send `GET /api/file/head?path=<valid-path>`.
- **Expected Result**: Response status is 404 or 500 with an appropriate error message indicating that git could not be found.
- **Edge Cases**:
  - Git is installed but the `.git` directory is corrupted: `git show` fails with an error, and the endpoint returns 500.

---

#### `TC-diff-api-routing-no-collision`: `/api/file/head` and `/api/file` routes do not collide

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: The Vite dev server is running with both routes active.
- **Steps**:
  1. Send `GET /api/file?path=<path>` and verify the working copy is returned.
  2. Send `GET /api/file/head?path=<path>` and verify the HEAD version is returned.
- **Expected Result**: Each endpoint returns its expected content. The routing uses exact pathname matching so `/api/file/head` is not mistakenly handled by the `/api/file` route.
- **Edge Cases**: None.

---

### Keyboard Accessibility

---

#### `TC-diff-keyboard-toggle-modes`: Toggle between file and diff via keyboard

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`, `AC-diff-toggle-to-diff`, `AC-diff-toggle-to-file`
- **Preconditions**: A file is loaded via the slash command.
- **Steps**:
  1. Press `Tab` until the view mode toggle receives focus.
  2. Press `ArrowRight` to focus the "Diff" segment.
  3. Press `Enter` to activate diff view.
  4. After diff loads, press `Tab` back to the toggle.
  5. Press `ArrowLeft` to focus the "File" segment.
  6. Press `Enter` to switch back.
- **Expected Result**: All mode switches are performed entirely via keyboard. Focus rings are visible throughout. The view mode toggle uses `role="tablist"` with `role="tab"` on each segment.
- **Edge Cases**:
  - Using `Space` instead of `Enter`: should also activate.
  - Toggle receives `aria-selected="true"` on the active segment.

---

#### `TC-diff-keyboard-navigate-lines`: Navigate diff lines with arrow keys

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`
- **Preconditions**: Diff view is active with multiple visible lines.
- **Steps**:
  1. Press `Tab` to focus the first visible line in the diff viewer.
  2. Press `ArrowDown` several times to move through lines.
  3. Press `ArrowUp` to move back.
- **Expected Result**: Focus moves between visible diff lines. Each focused line has a visible 2px `#2563EB` focus ring. Screen readers announce the line type and content (e.g., "Added line, new line 15: const x = 1;"). Collapsed section separators are focusable stops in the navigation.
- **Edge Cases**:
  - Pressing `ArrowDown` at the last visible line: focus stays on the last line (no wrap).
  - Pressing `ArrowUp` at the first visible line: focus stays on the first line.

---

#### `TC-diff-keyboard-add-comment`: Add a comment on a diff line via keyboard

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`, `FR-diff-comment-create`
- **Preconditions**: Diff view is active with lines visible.
- **Steps**:
  1. Focus a diff line using `Tab` and `ArrowDown`.
  2. Press `Enter` (or `c`) to open the InlineCommentEditor.
  3. Type a comment.
  4. Press `Cmd+Enter` (or `Ctrl+Enter`) to submit.
- **Expected Result**: The InlineCommentEditor opens below the focused line. After submitting, the comment is created and a CommentBubble appears. The editor closes and focus returns to the diff line.
- **Edge Cases**:
  - Pressing `Escape` while the editor is open: editor closes without creating a comment.

---

#### `TC-diff-keyboard-range-select`: Select a range of diff lines via keyboard

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`, `FR-diff-comment-on-range`
- **Preconditions**: Diff view is active.
- **Steps**:
  1. Focus a diff line.
  2. Press `Shift+ArrowDown` three times to extend the selection.
  3. Press `Enter` to open the editor for the range.
  4. Type a comment and submit.
- **Expected Result**: The selection highlight covers 4 lines (the initially focused line plus 3 more). After opening the editor and submitting, a range comment is created covering all 4 lines.
- **Edge Cases**:
  - `Shift+ArrowDown` stopping at a collapsed separator: selection does not extend past it.
  - Pressing `Escape` while a range is selected (before opening editor): the range selection is cleared.

---

#### `TC-diff-keyboard-comment-navigation`: Navigate between comments via keyboard

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`
- **Preconditions**: Diff view is active with 3 comments.
- **Steps**:
  1. Press `]` to navigate to the first (or next) comment.
  2. Press `]` again to navigate to the second comment.
  3. Press `[` to navigate back to the first comment.
  4. Keep pressing `]` to wrap from the last comment back to the first.
- **Expected Result**: Each press of `]` navigates to the next comment, scrolling the diff viewer to center the comment. The CommentBubble receives the focused style (blue left border). The toolbar shows "Comment N of M". Pressing `[` navigates in reverse. Wrapping works at both ends.
- **Edge Cases**: None.

---

#### `TC-diff-keyboard-expand-section`: Expand a collapsed section via keyboard

- **Type**: E2E
- **Covers**: `NFR-diff-accessibility`, `AC-diff-expand-section`
- **Preconditions**: Diff view is active with a collapsed section.
- **Steps**:
  1. Use `ArrowDown` to navigate to the collapsed section separator.
  2. Verify the separator has a focus ring and `aria-label="Expand N unchanged lines"`.
  3. Press `Enter` or `Space`.
- **Expected Result**: The section expands. Focus moves to the first newly revealed line. The separator is removed from the DOM.
- **Edge Cases**:
  - `Tab` can also land on the separator (it has `tabindex="0"`).

---

### Performance

---

#### `TC-diff-render-perf-scroll`: Scrolling through a large diff is smooth

- **Type**: Manual / Performance
- **Covers**: `NFR-diff-render-perf`
- **Preconditions**: Diff view is active for a file with 10,000+ lines and moderate changes (~20% changed).
- **Steps**:
  1. Scroll through the diff view rapidly using the scroll wheel or trackpad.
  2. Observe rendering smoothness.
  3. Use browser DevTools Performance panel to measure frame times.
- **Expected Result**: Scrolling is smooth with no visible jank exceeding 200ms. The virtualized rendering keeps DOM node count low (~90 nodes). Frame times stay under 16ms for the majority of frames.
- **Edge Cases**:
  - Scrolling past collapsed sections: should be equally smooth.
  - Scrolling after expanding a large collapsed section (e.g., 500 lines): no noticeable performance degradation.

---

#### `TC-diff-compute-perf-large-file`: Diff computation for very large files

- **Type**: Unit (performance)
- **Covers**: `NFR-diff-compute-perf`
- **Preconditions**: The `computeFileDiff` function is available.
- **Steps**:
  1. Generate a 50,000-line file pair with ~10% of lines changed.
  2. Measure computation time.
- **Expected Result**: Computation completes within 2 seconds. For 10,000 lines, under 500ms.
- **Edge Cases**:
  - 50,000-line file where every line changed: the diff is as large as both files combined. Should still complete within 2 seconds or gracefully indicate that performance may be degraded.

---

### Error Handling

---

#### `TC-diff-error-network-failure`: Network failure during baseline fetch

- **Type**: E2E
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: A file is loaded via the slash command. Network connectivity is simulated as unavailable (or the server is stopped).
- **Steps**:
  1. Switch to diff view.
  2. The baseline fetch fails due to a network error.
- **Expected Result**: An error banner appears at the top of the code viewer panel: "Failed to fetch the baseline version. Check that the file is in a git repository." with a "Retry" link. The error banner has a pale red background (`#FEF2F2`), dark red text (`#991B1B`), and a light red border (`#FECACA`). The refresh button returns to its default state (not spinning). The user can click "Retry" to re-attempt or switch back to file view.
- **Edge Cases**:
  - Clicking "Retry" after the network is restored: the fetch succeeds and the diff renders.
  - Clicking "Retry" while the network is still down: the error banner persists with an updated or unchanged error message.

---

#### `TC-diff-error-git-unavailable`: Git not available on the server

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: The server is running but git is not available in the system PATH.
- **Steps**:
  1. Load a file via the slash command.
  2. Switch to diff view.
- **Expected Result**: The baseline fetch returns an error. The `DiffErrorState` component renders with an appropriate message. The user can switch to file view.
- **Edge Cases**: None.

---

#### `TC-diff-error-file-deleted-refresh`: Refresh when file was deleted from disk

- **Type**: E2E
- **Covers**: `FR-diff-refresh`
- **Preconditions**: Diff view is active. The underlying file is deleted from disk while the user is viewing the diff.
- **Steps**:
  1. Delete the file from disk (outside the application).
  2. Click the refresh button in the toolbar.
- **Expected Result**: The refresh fails because the working copy can no longer be read. An error state is shown. The user can switch to file view (which may also show an error or stale content).
- **Edge Cases**:
  - File deleted but HEAD version still exists: HEAD fetch succeeds but working copy fetch fails.

---

#### `TC-diff-error-file-outside-git`: File outside any git repository

- **Type**: Integration
- **Covers**: `FR-diff-baseline-fetch`
- **Preconditions**: A file is loaded via the slash command from a directory that is not part of any git repository.
- **Steps**:
  1. Switch to diff view.
- **Expected Result**: The baseline fetch returns 404 ("Not a git repository"). The `DiffErrorState` component renders with the error message and a "Retry" link. The user can switch to file view.
- **Edge Cases**: None.

---

## Edge Cases & Error Scenarios

---

### File with no newline at end of file

- **Trigger**: A file where the last line has no trailing newline is diffed against a version that does (or vice versa).
- **Expected behavior**: The diff should correctly show the change without crashing. The jsdiff library handles this case by producing a "no newline at end of file" indicator in the patch output. The `transformHunksToDiffLines` function should handle this gracefully (either ignoring the marker or representing it as a special line).
- **Test case**: `TC-diff-compute-no-newline-at-end`

---

### File with only additions (new/untracked file)

- **Trigger**: The HEAD endpoint returns 404, so the baseline is treated as an empty file.
- **Expected behavior**: Every line in the working copy appears as an added line (green, `+`). No collapsed sections. No context lines.
- **Test case**: `TC-diff-no-git-history-all-added`, `TC-diff-no-git-history-no-collapse`

---

### File with only deletions (file emptied)

- **Trigger**: The working copy is empty but the HEAD version has content.
- **Expected behavior**: Every line from HEAD appears as a removed line (red, `-`). No added or context lines. This is a valid diff state.
- **Test case**: `TC-diff-compute-all-removed`

---

### File with every line changed (reformatter)

- **Trigger**: An automated reformatter changes indentation, line endings, or style on every line.
- **Expected behavior**: The diff shows all lines as removed then added (or interleaved hunks). No collapsed sections because there are no unchanged lines. Performance should be acceptable per `NFR-diff-compute-perf`.
- **Test case**: `TC-diff-compute-every-line-changed`

---

### Very large diff (>5000 changed lines)

- **Trigger**: A file with >5000 changed lines is loaded into diff view.
- **Expected behavior**: The diff renders using virtualized scrolling. Performance targets from `NFR-diff-render-perf` are met. The same large-file warning from the existing `NFR-crp-large-file-perf` should apply if the total file exceeds the threshold.
- **Test case**: `TC-diff-render-perf-scroll`, `TC-diff-compute-perf-large-file`

---

### Collapsed section with exactly 2*context+1 lines (boundary)

- **Trigger**: Two change hunks are separated by exactly 7 unchanged lines (with default context=3).
- **Expected behavior**: All 7 lines are shown without collapsing. The boundary between "show all" and "collapse" is at 7 lines (inclusive). At 8 lines, collapsing occurs.
- **Test case**: `TC-diff-collapse-gap-boundary`

---

### Comment on last line of file in diff view

- **Trigger**: The user adds a comment on the very last line of the diff (whether it is an added, removed, or context line).
- **Expected behavior**: The InlineCommentEditor opens below the last line. After submitting, the CommentBubble renders below the last line. The virtualizer correctly accounts for the additional height. Scrolling to the comment works correctly.
- **Test case**: `TC-diff-comment-added-line-happy` (edge case variant)

---

### Mode switch with zero comments should not show confirmation

- **Trigger**: The user switches between file and diff view when no comments exist in the current mode.
- **Expected behavior**: The mode switches immediately without any confirmation dialog.
- **Test case**: `TC-diff-toggle-to-file-no-comments`, `TC-diff-switch-no-comments-no-dialog`

---

### Refresh when file was deleted from disk

- **Trigger**: The user clicks "Refresh" after the underlying file has been deleted from the filesystem.
- **Expected behavior**: The working copy fetch fails. An error state is shown. The user can switch to file view.
- **Test case**: `TC-diff-error-file-deleted-refresh`

---

### Concurrent file changes while viewing diff

- **Trigger**: The file is modified on disk (e.g., by an AI agent or another editor) while the user is viewing the diff and adding comments.
- **Expected behavior**: The diff does not auto-update. The displayed diff reflects the state at the time of the last fetch. The user must click "Refresh" to see the latest changes. If the user has comments, the refresh confirmation dialog warns that comments will be cleared.
- **Test case**: `TC-diff-refresh-happy` (the scenario assumes file was modified since last fetch)

---

### File renamed but content similar

- **Trigger**: A file is renamed (e.g., `old.ts` to `new.ts`) but the content is largely the same. The user loads `new.ts` via the slash command.
- **Expected behavior**: The HEAD endpoint fetches `git show HEAD:new.ts`. If the rename is not tracked by git (or HEAD does not have `new.ts`), the endpoint returns 404 and the file is treated as untracked (all additions). If git tracks the file under the new name at HEAD, the diff is computed normally. Git rename detection is not explicitly used by the `git show HEAD:<path>` command, so the behavior depends on whether the file exists at the given path in HEAD.
- **Test case**: No dedicated test case -- this is an informational edge case. The existing `TC-diff-no-git-history-all-added` covers the 404 case.

---

### Preamble preserved across mode switches

- **Trigger**: The user types a preamble, switches to diff view, then switches back to file view.
- **Expected behavior**: The preamble text is preserved across all mode switches. It is never cleared by mode switching.
- **Test case**: `TC-diff-toggle-to-file-happy` (verifies preamble preservation)

---

### No prompt when no comments exist in diff view

- **Trigger**: Diff view is active but the user has not added any comments.
- **Expected behavior**: The prompt preview shows a placeholder state because no prompt is generated until comments exist (same behavior as file mode with no comments).
- **Test case**: `TC-diff-no-changes-empty-state` (verifies prompt preview placeholder state)

---

## Regression Considerations

### Existing File View Functionality

The diff view feature modifies the `Toolbar`, `App`, and `CommentBubble` components. Regression tests should verify:

- **File view continues to work as before**: Loading files via paste/upload/drag-and-drop still works. Syntax highlighting, line numbers, comments, prompt generation, and all existing features are unaffected when "File" mode is active.
- **Comment operations in file view**: Adding, editing, deleting comments in file mode should not be affected by the presence of diff-mode state in the store.
- **Prompt generation in file view**: The existing `buildPrompt` function is unchanged. Generating prompts in file mode should produce identical output to before the diff feature was added.
- **Toolbar button states**: The Copy, Clear, and Navigation buttons should continue to respect the correct comment set based on the active view mode.
- **File loading resets diff state**: Loading a new file (via any method) resets the view mode to "File" and clears all diff state. Verify that stale diff data from a previously loaded file does not appear.
- **Clear session resets diff state**: Clicking "Clear" and confirming should reset everything, including diff state.

### API Routing

- **`/api/file` route unchanged**: The existing file-serving endpoint must continue to work after the routing refactor (from prefix matching to exact pathname matching). Verify that `GET /api/file?path=...` still returns working copy content.
- **No route collision**: `GET /api/file/head` should not be intercepted by the `/api/file` handler, and vice versa.

### Performance

- **File view rendering unaffected**: The addition of diff-related state to the Zustand store should not cause unnecessary re-renders in file mode. The `CodeViewer` component should not re-render when `diffLines` or other diff state changes.
- **Memory**: Loading a file and computing a diff increases memory usage. Verify that switching back to file mode or loading a new file properly clears the baseline content and diff lines from memory.

### Accessibility

- **File view keyboard navigation unchanged**: All keyboard shortcuts and navigation patterns in file mode should work identically after the diff feature is added.
- **Screen reader announcements in file mode**: ARIA attributes on the existing `CodeViewer` should not be affected by the diff feature additions.
