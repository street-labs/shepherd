# Code Review Prompt Generator -- Test Plan

> Based on requirements in `../product/code-review-prompt.md`
> Based on design in `../design/code-review-prompt.md`
> Based on technical spec in `../engineering/code-review-prompt.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-crp-load-paste` | `TC-crp-load-paste-happy`, `TC-crp-load-paste-with-filename`, `TC-crp-load-paste-empty-rejected` | Not started |
| `AC-crp-load-upload` | `TC-crp-load-upload-happy`, `TC-crp-load-upload-shows-filename` | Not started |
| `AC-crp-load-drag-drop` | `TC-crp-load-drag-drop-happy`, `TC-crp-load-drag-drop-hover-state` | Not started |
| `AC-crp-syntax-highlight-detected` | `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback` | Not started |
| `AC-crp-add-comment-single-line` | `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-gutter-indicator`, `TC-crp-add-comment-count-increments` | Not started |
| `AC-crp-add-comment-line-range` | `TC-crp-add-comment-line-range-happy`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-add-comment-line-range-prompt-format` | Not started |
| `AC-crp-edit-comment` | `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line` | Not started |
| `AC-crp-delete-comment` | `TC-crp-delete-comment-happy`, `TC-crp-delete-comment-gutter-clears`, `TC-crp-delete-comment-count-decrements` | Not started |
| `AC-crp-generate-prompt-structure` | `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order` | Not started |
| `AC-crp-generate-prompt-no-comments` | `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-generate-prompt-no-comments-after-delete-all` | Not started |
| `AC-crp-copy-clipboard` | `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast` | Not started |
| `AC-crp-preview-matches-copy` | `TC-crp-preview-matches-copy-exact` | Not started |
| `AC-crp-clear-confirmation` | `TC-crp-clear-confirmation-shows-dialog`, `TC-crp-clear-confirmation-cancel-preserves`, `TC-crp-clear-confirmation-confirm-clears` | Not started |
| `AC-crp-clear-no-confirm-empty` | `TC-crp-clear-no-confirm-empty-happy` | Not started |
| `AC-crp-empty-state` | `TC-crp-empty-state-instructions`, `TC-crp-empty-state-buttons-disabled` | Not started |
| `AC-crp-large-file-scroll` | `TC-crp-large-file-scroll-no-jank`, `TC-crp-large-file-scroll-warning-banner` | Not started |
| `AC-crp-comment-navigation-next` | `TC-crp-comment-navigation-next-happy`, `TC-crp-comment-navigation-prev-happy`, `TC-crp-comment-navigation-wrap-around` | Not started |
| `AC-crp-keyboard-add-comment` | `TC-crp-keyboard-add-comment-happy`, `TC-crp-keyboard-range-select` | Not started |
| `AC-crp-binary-file-rejected` | `TC-crp-binary-file-rejected-upload`, `TC-crp-binary-file-rejected-drag-drop`, `TC-crp-binary-file-rejected-no-crash` | Not started |

---

## Test Cases

---

### File Loading

---

#### `TC-crp-load-paste-happy`: Load file content via paste

- **Type**: E2E
- **Covers**: `AC-crp-load-paste`, `FR-crp-file-load`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Click the "Paste content" button in the drop zone.
  2. Paste or type the following text into the text area:
     ```
     function hello() {
       console.log("world");
     }
     ```
  3. Click the "Load" button.
- **Expected Result**: The code viewer displays the pasted content with line numbers starting at 1 (line 1: `function hello() {`, line 2: `  console.log("world");`, line 3: `}`). The FileHeader shows "Untitled" (or an editable placeholder). The sidebar panel appears with the preamble input.
- **Edge Cases**:
  - Pasting an empty string and clicking Load: the Load button should be disabled when the text area is empty.
  - Pasting content with Windows-style line endings (`\r\n`): line numbers should still be correct and no extra blank lines should appear.
  - Pasting a single line of text (no line breaks): viewer shows 1 line, numbered as line 1.

---

#### `TC-crp-load-paste-with-filename`: Load pasted content with an optional file name

- **Type**: E2E
- **Covers**: `AC-crp-load-paste`, `FR-crp-filename-display`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Click "Paste content".
  2. Enter "utils.ts" in the file name input field.
  3. Paste valid TypeScript content into the text area.
  4. Click "Load".
- **Expected Result**: The FileHeader displays "utils.ts". The language badge shows "TypeScript". Syntax highlighting is applied.
- **Edge Cases**:
  - Providing a file name with an unknown extension (e.g., "data.xyz"): language should default to "Plain Text".

---

#### `TC-crp-load-paste-empty-rejected`: Paste mode rejects empty content

- **Type**: Integration
- **Covers**: `AC-crp-load-paste`
- **Preconditions**: Application is in the empty state, paste mode is active.
- **Steps**:
  1. Click "Paste content" to enter paste mode.
  2. Leave the text area empty.
  3. Observe the "Load" button state.
- **Expected Result**: The "Load" button is disabled and cannot be clicked. No file is loaded.
- **Edge Cases**:
  - Typing text then deleting it all: Load button should return to disabled state.
  - Whitespace-only content: depending on implementation, this may or may not be accepted. (Flag: product spec does not explicitly address whitespace-only content.)

---

#### `TC-crp-load-upload-happy`: Load a file via the file picker

- **Type**: E2E
- **Covers**: `AC-crp-load-upload`, `FR-crp-file-load`, `FR-crp-filename-display`
- **Preconditions**: Application is in the initial empty state. A text file named `example.py` exists on the local filesystem with content:
  ```python
  def greet(name):
      print(f"Hello, {name}")
  ```
- **Steps**:
  1. Click the "Choose file" button in the drop zone.
  2. Select `example.py` from the file picker.
- **Expected Result**: The code viewer displays the file content with line numbers. The FileHeader displays "example.py". The language badge shows "Python".
- **Edge Cases**:
  - Selecting a file with no extension: language defaults to "Plain Text".
  - Selecting a file with a mixed-case extension (e.g., `.PY`): language detection should be case-insensitive (per engineering spec).

---

#### `TC-crp-load-upload-shows-filename`: Uploaded file name is displayed

- **Type**: Integration
- **Covers**: `AC-crp-load-upload`, `FR-crp-filename-display`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Upload a file named `my-component.tsx`.
- **Expected Result**: FileHeader displays "my-component.tsx". Language badge shows "TypeScript".
- **Edge Cases**:
  - File name with spaces (e.g., `my file.js`): name should display correctly without encoding artifacts.
  - Very long file name: name should be truncated with ellipsis per design spec.

---

#### `TC-crp-load-drag-drop-happy`: Load a file via drag and drop

- **Type**: E2E
- **Covers**: `AC-crp-load-drag-drop`, `FR-crp-file-load`, `FR-crp-filename-display`
- **Preconditions**: Application is in the initial empty state. A text file named `app.go` exists.
- **Steps**:
  1. Drag the file `app.go` from the filesystem onto the application drop zone.
  2. Drop the file.
- **Expected Result**: The code viewer displays the file content with line numbers. The FileHeader displays "app.go". The language badge shows "Go".
- **Edge Cases**:
  - Dropping multiple files simultaneously: only the first file should be loaded (or an appropriate message shown). Product spec does not specify multi-file behavior, so this should be handled gracefully.
  - Dragging a file but dropping outside the drop zone: nothing should happen, the empty state persists.

---

#### `TC-crp-load-drag-drop-hover-state`: Drop zone visual feedback during drag

- **Type**: E2E
- **Covers**: `AC-crp-load-drag-drop`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Drag a file from the filesystem over the drop zone (do not drop).
  2. Observe the visual state of the drop zone.
  3. Move the dragged file away from the drop zone without dropping.
- **Expected Result**: While the file is hovering over the drop zone, the border becomes solid and highlighted (blue), the background tints, and the text changes to "Drop file to load" (per design spec). When the file is dragged away, the drop zone returns to its default dashed-border state.
- **Edge Cases**:
  - Rapid drag-in/drag-out cycling: visual state should always be in sync without flickering.

---

### Syntax Highlighting

---

#### `TC-crp-syntax-highlight-typescript`: Syntax highlighting applies for a known language

- **Type**: Integration
- **Covers**: `AC-crp-syntax-highlight-detected`, `FR-crp-syntax-highlight`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Upload a file named `utils.ts` containing:
     ```typescript
     const greeting: string = "hello";
     // A comment
     function add(a: number, b: number): number {
       return a + b;
     }
     ```
  2. Observe the code viewer.
- **Expected Result**: The code is displayed with syntax-appropriate coloring: keywords (`const`, `function`, `return`) are highlighted distinctly from strings (`"hello"`), comments (`// A comment`), and type annotations (`: string`, `: number`). Colors correspond to the Shiki `github-light` theme.
- **Edge Cases**:
  - File with only comments and no code: highlighting should still apply to comment tokens.
  - File with mixed syntax (e.g., JSX in a `.tsx` file): JSX tokens should also be highlighted.

---

#### `TC-crp-syntax-highlight-unknown-fallback`: Unknown file type renders as plain text

- **Type**: Integration
- **Covers**: `AC-crp-syntax-highlight-detected`, `FR-crp-syntax-highlight`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Upload a file named `data.xyz` containing arbitrary text.
- **Expected Result**: The file is displayed as plain text with no syntax coloring applied. The language badge shows "Plain Text". No errors occur.
- **Edge Cases**:
  - File with no extension loaded via paste (no file name provided): defaults to "Plain Text".

---

### Comments -- Creation

---

#### `TC-crp-add-comment-single-line-happy`: Add a comment on a single line

- **Type**: E2E
- **Covers**: `AC-crp-add-comment-single-line`, `FR-crp-line-comment-create`, `FR-crp-comment-indicator`, `FR-crp-comment-count`
- **Preconditions**: A file is loaded in the viewer with at least 10 lines.
- **Steps**:
  1. Click on the gutter or line number for line 5.
  2. The InlineCommentEditor opens below line 5.
  3. Type "Rename this variable" in the text area.
  4. Click the "Comment" button (or press `Cmd+Enter` / `Ctrl+Enter`).
- **Expected Result**: The editor closes. A CommentBubble appears below line 5 showing "Rename this variable". The gutter for line 5 shows a blue dot comment indicator. The toolbar comment count shows "1 comment".
- **Edge Cases**:
  - Clicking "Cancel" instead of "Comment": no comment is created, editor closes, comment count stays at 0.
  - Pressing `Escape`: same as clicking Cancel.
  - Submitting with an empty text area: the "Comment" button should be disabled when text is empty.

---

#### `TC-crp-add-comment-gutter-indicator`: Gutter shows comment indicator on commented lines

- **Type**: Integration
- **Covers**: `AC-crp-add-comment-single-line`, `FR-crp-comment-indicator`
- **Preconditions**: A file is loaded. No comments exist.
- **Steps**:
  1. Add a comment on line 3.
  2. Add a comment on line 7.
  3. Observe the gutter for lines 1 through 10.
- **Expected Result**: Lines 3 and 7 show blue dot indicators in the gutter. All other lines show no indicator (but show a faint "+" icon on hover per design spec).
- **Edge Cases**:
  - Adding two comments to the same line: the gutter indicator should still show a single dot (not two).

---

#### `TC-crp-add-comment-count-increments`: Comment count updates correctly

- **Type**: Integration
- **Covers**: `AC-crp-add-comment-single-line`, `FR-crp-comment-count`
- **Preconditions**: A file is loaded. Comment count shows "0 comments".
- **Steps**:
  1. Add a comment on line 1. Observe the toolbar.
  2. Add a comment on line 5. Observe the toolbar.
  3. Add a second comment on line 1. Observe the toolbar.
- **Expected Result**: After step 1: "1 comment". After step 2: "2 comments". After step 3: "3 comments".
- **Edge Cases**:
  - Singular vs plural label: "1 comment" (singular) vs "2 comments" (plural).

---

#### `TC-crp-add-comment-line-range-happy`: Add a comment on a range of lines

- **Type**: E2E
- **Covers**: `AC-crp-add-comment-line-range`, `FR-crp-line-range-comment`
- **Preconditions**: A file is loaded with at least 20 lines.
- **Steps**:
  1. Click on line number 10 and Shift+click on line number 15.
  2. The selected range (lines 10-15) is highlighted with a blue background.
  3. The InlineCommentEditor opens below line 15.
  4. Type "Extract this to a helper function".
  5. Click "Comment".
- **Expected Result**: A CommentBubble appears below the range showing "Lines 10-15" label and the comment text "Extract this to a helper function". The gutter shows indicators for all lines 10 through 15. The comment count increments by 1.
- **Edge Cases**:
  - Selecting a range of just 1 line (start == end): should behave identically to a single-line comment.
  - Selecting lines in reverse order (click line 15 first, then Shift+click line 10): the range should still be normalized to lines 10-15.

---

#### `TC-crp-add-comment-line-range-gutter-indicators`: Gutter indicators for range comments

- **Type**: Integration
- **Covers**: `AC-crp-add-comment-line-range`, `FR-crp-comment-indicator`
- **Preconditions**: A file is loaded.
- **Steps**:
  1. Add a range comment on lines 5-8.
  2. Observe the gutter for lines 1 through 10.
- **Expected Result**: Lines 5, 6, 7, and 8 all show blue dot indicators in the gutter. Lines 1-4 and 9-10 show no indicator.
- **Edge Cases**:
  - Overlapping ranges (e.g., comment on 5-8 and another on 7-10): lines 5-10 all show indicators. Line 7 and 8 have indicators even if one comment is deleted (as long as the other remains).

---

#### `TC-crp-add-comment-line-range-prompt-format`: Range comment appears correctly in generated prompt

- **Type**: Unit
- **Covers**: `AC-crp-add-comment-line-range`, `FR-crp-prompt-format`
- **Preconditions**: The `buildPrompt` function is available for direct testing.
- **Steps**:
  1. Call `buildPrompt` with a file, a comment on lines 10-15 with text "Refactor this", and no preamble.
  2. Inspect the "Requested Changes" section of the output.
- **Expected Result**: The comment appears as `- **Lines 10-15**: Refactor this` (not "Line 10 to 15" or any other format).
- **Edge Cases**:
  - Range of one line: should format as `- **Line N**: ...` (singular), not `- **Lines N-N**: ...`.

---

### Comments -- Editing

---

#### `TC-crp-edit-comment-happy`: Edit an existing comment

- **Type**: E2E
- **Covers**: `AC-crp-edit-comment`, `FR-crp-line-comment-edit`
- **Preconditions**: A file is loaded. A comment "Fix this" exists on line 3.
- **Steps**:
  1. Hover over the CommentBubble on line 3 to reveal action buttons.
  2. Click the "Edit" button (pencil icon).
  3. The InlineCommentEditor opens with the text "Fix this" pre-populated.
  4. Change the text to "Fix this null check".
  5. Click "Save" (or press `Cmd+Enter` / `Ctrl+Enter`).
- **Expected Result**: The CommentBubble now shows "Fix this null check". The comment remains attached to line 3. The comment count does not change.
- **Edge Cases**:
  - Editing a comment and clicking "Cancel": the original text "Fix this" is preserved.
  - Editing a comment to be empty and trying to save: the "Save" button should be disabled.
  - Double-clicking the comment text to enter edit mode (per design spec Flow 6): should also open the editor.

---

#### `TC-crp-edit-comment-stays-on-line`: Edited comment retains its line association

- **Type**: Integration
- **Covers**: `AC-crp-edit-comment`, `FR-crp-line-comment-edit`
- **Preconditions**: A file is loaded. A comment exists on lines 10-12 (range comment).
- **Steps**:
  1. Edit the comment text from "Old text" to "New text".
  2. Save the edit.
  3. Generate the prompt and inspect the output.
- **Expected Result**: The generated prompt shows the comment on "Lines 10-12" with the new text. The line association is unchanged.
- **Edge Cases**:
  - N/A (focused test).

---

### Comments -- Deletion

---

#### `TC-crp-delete-comment-happy`: Delete a comment

- **Type**: E2E
- **Covers**: `AC-crp-delete-comment`, `FR-crp-line-comment-delete`
- **Preconditions**: A file is loaded. A comment exists on line 7. Comment count shows "1 comment".
- **Steps**:
  1. Hover over the CommentBubble on line 7 to reveal action buttons.
  2. Click the "Delete" button (trash icon).
- **Expected Result**: The CommentBubble is immediately removed from the viewer. No confirmation dialog appears for individual comment deletion (per design spec). Comment count shows "0 comments".
- **Edge Cases**:
  - Deleting the last comment and then trying to generate a prompt: the Generate button should become disabled.

---

#### `TC-crp-delete-comment-gutter-clears`: Gutter indicator clears when last comment on a line is deleted

- **Type**: Integration
- **Covers**: `AC-crp-delete-comment`, `FR-crp-comment-indicator`
- **Preconditions**: A file is loaded. Two comments exist on line 5 and one comment exists on line 10.
- **Steps**:
  1. Delete one comment on line 5.
  2. Observe the gutter for line 5.
  3. Delete the remaining comment on line 5.
  4. Observe the gutter for line 5.
- **Expected Result**: After step 2: the gutter indicator for line 5 is still visible (one comment remains). After step 4: the gutter indicator for line 5 disappears. The gutter indicator for line 10 is unaffected.
- **Edge Cases**:
  - Deleting a range comment: all gutter indicators for lines in the range should clear (if no other comments cover those lines).

---

#### `TC-crp-delete-comment-count-decrements`: Comment count decrements on deletion

- **Type**: Integration
- **Covers**: `AC-crp-delete-comment`, `FR-crp-comment-count`
- **Preconditions**: A file is loaded. Three comments exist. Toolbar shows "3 comments".
- **Steps**:
  1. Delete one comment.
  2. Observe the toolbar.
- **Expected Result**: Toolbar shows "2 comments".
- **Edge Cases**:
  - Deleting all comments one by one: count should go 3 -> 2 -> 1 -> 0, with correct singular/plural labels.

---

### Prompt Generation

---

#### `TC-crp-generate-prompt-structure-happy`: Generated prompt has all required sections

- **Type**: Unit
- **Covers**: `AC-crp-generate-prompt-structure`, `FR-crp-prompt-generate`, `FR-crp-prompt-format`
- **Preconditions**: The `buildPrompt` function is available. Input: file named "utils.ts" (language: TypeScript), preamble "Refactor for readability", comments on line 3 ("Rename this"), lines 10-12 ("Extract to function"), and line 25 ("Add error handling").
- **Steps**:
  1. Call `buildPrompt(fileInfo, comments, preamble)`.
  2. Parse the output string for structure.
- **Expected Result**: The output contains, in order:
  1. `## Instructions` section with "Refactor for readability".
  2. `## File: utils.ts (TypeScript)` section.
  3. A code block with numbered lines (all lines of the file, padded line numbers, pipe separator).
  4. `## Requested Changes` section listing:
     - `- **Line 3**: Rename this`
     - `- **Lines 10-12**: Extract to function`
     - `- **Line 25**: Add error handling`
  5. Comments are in ascending line order.
- **Edge Cases**:
  - Line number padding: for a file with 1000+ lines, line numbers should be right-padded (e.g., `   1 |`, `  10 |`, ` 100 |`, `1000 |`).

---

#### `TC-crp-generate-prompt-structure-no-preamble`: Prompt omits Instructions section when no preamble

- **Type**: Unit
- **Covers**: `AC-crp-generate-prompt-structure`, `FR-crp-prompt-format`
- **Preconditions**: The `buildPrompt` function is available. Input: file with one comment, empty preamble.
- **Steps**:
  1. Call `buildPrompt(fileInfo, comments, "")`.
  2. Inspect the output.
- **Expected Result**: The output does NOT contain a `## Instructions` section. The prompt starts with the `## File:` section.
- **Edge Cases**:
  - Preamble that is only whitespace (spaces, tabs, newlines): should be treated as empty -- no Instructions section.

---

#### `TC-crp-generate-prompt-structure-line-order`: Comments are listed in ascending line order

- **Type**: Unit
- **Covers**: `AC-crp-generate-prompt-structure`, `FR-crp-prompt-format`
- **Preconditions**: The `buildPrompt` function is available.
- **Steps**:
  1. Create comments in this order: line 25 (created first), line 3 (created second), line 10 (created third).
  2. Call `buildPrompt`.
  3. Inspect the Requested Changes section.
- **Expected Result**: Comments appear in the order: line 3, line 10, line 25 -- sorted by start line, regardless of creation order.
- **Edge Cases**:
  - Two comments on the same line: should be sorted by `createdAt` (earlier first) per engineering spec.
  - A range comment on lines 5-8 and a single-line comment on line 6: the range comment (starting at line 5) should appear first.

---

#### `TC-crp-generate-prompt-no-comments-disabled`: Generate button is disabled with zero comments

- **Type**: Integration
- **Covers**: `AC-crp-generate-prompt-no-comments`
- **Preconditions**: A file is loaded. No comments have been added.
- **Steps**:
  1. Observe the Generate button in the toolbar.
  2. Attempt to click the Generate button.
- **Expected Result**: The Generate button is visually disabled (grayed out, `aria-disabled="true"`). Clicking it does nothing. No prompt is generated.
- **Edge Cases**:
  - Keyboard shortcut (`Cmd+Shift+G`): should also be non-functional when no comments exist.

---

#### `TC-crp-generate-prompt-no-comments-after-delete-all`: Generate button disables after all comments are deleted

- **Type**: E2E
- **Covers**: `AC-crp-generate-prompt-no-comments`, `AC-crp-delete-comment`
- **Preconditions**: A file is loaded. One comment exists. Generate button is enabled.
- **Steps**:
  1. Delete the only comment.
  2. Observe the Generate button.
- **Expected Result**: The Generate button becomes disabled after the last comment is deleted.
- **Edge Cases**:
  - If a prompt was previously generated, the prompt preview should show the stale indicator, and then after the last comment is deleted, generate should be disabled.

---

### Copy to Clipboard

---

#### `TC-crp-copy-clipboard-happy`: Prompt is copied to clipboard

- **Type**: E2E
- **Covers**: `AC-crp-copy-clipboard`, `FR-crp-prompt-copy`
- **Preconditions**: A prompt has been generated and is displayed in the preview panel.
- **Steps**:
  1. Click the "Copy" button in the toolbar (or the "Copy" button in the prompt preview panel).
  2. Observe the UI feedback.
  3. Paste into an external text editor.
- **Expected Result**: The clipboard contains the full prompt text. A toast notification appears at the bottom-center: "Copied to clipboard". The toast auto-dismisses after 3 seconds. The Copy button temporarily shows "Copied!" with a checkmark icon for 2 seconds.
- **Edge Cases**:
  - Clicking Copy multiple times rapidly: each click should succeed and the toast should reset its timer.
  - Copy button in the prompt preview panel: should behave identically to the toolbar Copy button.

---

#### `TC-crp-copy-clipboard-toast`: Toast notification appears and auto-dismisses

- **Type**: Integration
- **Covers**: `AC-crp-copy-clipboard`
- **Preconditions**: A prompt has been generated.
- **Steps**:
  1. Click "Copy".
  2. Observe the toast notification.
  3. Wait 3 seconds.
- **Expected Result**: Toast appears with slide-up animation. Text: "Copied to clipboard". After 3 seconds, the toast fades out and disappears. Toast has `role="status"` and `aria-live="polite"` for screen reader announcement.
- **Edge Cases**:
  - If the user triggers another copy while the toast is visible, the toast should reset (not stack a second toast).

---

#### `TC-crp-preview-matches-copy-exact`: Preview text is byte-for-byte identical to clipboard content

- **Type**: E2E
- **Covers**: `AC-crp-preview-matches-copy`
- **Preconditions**: A prompt has been generated with a preamble, file content, and multiple comments.
- **Steps**:
  1. Capture the full text displayed in the prompt preview panel.
  2. Click "Copy".
  3. Paste the clipboard content into a comparison tool.
  4. Compare the preview text with the pasted text byte-for-byte.
- **Expected Result**: The two texts are identical -- same line breaks, same whitespace, same characters. No trailing newlines added or removed. No formatting differences.
- **Edge Cases**:
  - Prompt containing special characters (backticks, angle brackets, etc.): they should not be HTML-encoded or escaped in the clipboard.
  - Prompt preview renders inside a `<pre>` tag as plain text (per design spec): the clipboard content should match this plain text exactly.

---

### Session Management

---

#### `TC-crp-clear-confirmation-shows-dialog`: Clear session shows confirmation when comments exist

- **Type**: E2E
- **Covers**: `AC-crp-clear-confirmation`, `FR-crp-clear-session`
- **Preconditions**: A file is loaded with at least one comment.
- **Steps**:
  1. Click the "Clear" button in the toolbar.
  2. Observe the UI.
- **Expected Result**: A modal confirmation dialog appears with title "Clear session?", body text mentioning the file, comments, and preamble will be removed, and two buttons: "Cancel" and "Clear session" (red/destructive style).
- **Edge Cases**:
  - The dialog body should include the actual comment count (e.g., "all 5 comments" per design spec).

---

#### `TC-crp-clear-confirmation-cancel-preserves`: Cancelling the clear dialog preserves everything

- **Type**: E2E
- **Covers**: `AC-crp-clear-confirmation`
- **Preconditions**: A file is loaded with comments and a preamble. The clear confirmation dialog is open.
- **Steps**:
  1. Click "Cancel" in the confirmation dialog.
  2. Observe the application state.
- **Expected Result**: The dialog closes. The file, all comments, and the preamble are preserved exactly as they were.
- **Edge Cases**:
  - Pressing `Escape` to dismiss the dialog: should have the same effect as clicking Cancel.
  - Clicking the close button [X] in the dialog: should also cancel.
  - Clicking outside the dialog (on the overlay): should close the dialog without clearing (per standard modal behavior).

---

#### `TC-crp-clear-confirmation-confirm-clears`: Confirming the clear dialog resets the session

- **Type**: E2E
- **Covers**: `AC-crp-clear-confirmation`, `FR-crp-clear-session`
- **Preconditions**: A file is loaded with comments and a preamble. The clear confirmation dialog is open.
- **Steps**:
  1. Click "Clear session" (the red destructive button).
  2. Observe the application state.
- **Expected Result**: The dialog closes. The application returns to the initial empty state: drop zone is displayed, no file content, no comments, no preamble, no prompt. All toolbar buttons are disabled. Comment count shows "0 comments".
- **Edge Cases**:
  - If a prompt was previously generated, it should also be cleared.

---

#### `TC-crp-clear-no-confirm-empty-happy`: Clear session skips confirmation when no comments exist

- **Type**: E2E
- **Covers**: `AC-crp-clear-no-confirm-empty`, `FR-crp-clear-session`
- **Preconditions**: A file is loaded. No comments exist. A preamble may or may not be present.
- **Steps**:
  1. Click the "Clear" button in the toolbar.
- **Expected Result**: No confirmation dialog appears. The session clears immediately. The application returns to the empty state.
- **Edge Cases**:
  - File loaded with a preamble but no comments: should still skip confirmation (the condition is based on comment count, not preamble).

---

### Empty State

---

#### `TC-crp-empty-state-instructions`: Empty state displays file loading instructions

- **Type**: E2E
- **Covers**: `AC-crp-empty-state`
- **Preconditions**: Application is freshly loaded, no file has been loaded.
- **Steps**:
  1. Open the application.
  2. Observe the main content area.
- **Expected Result**: The viewer area displays a drop zone with instructions for how to load a file. The instructions mention or provide access to three loading methods: paste, upload (Choose file), and drag-and-drop. The drop zone has a dashed border and centered content per design spec.
- **Edge Cases**:
  - After clearing a session, the empty state should look identical to the initial page load.

---

#### `TC-crp-empty-state-buttons-disabled`: Toolbar buttons are disabled in empty state

- **Type**: Integration
- **Covers**: `AC-crp-empty-state`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Observe the toolbar buttons: Generate, Copy, Clear, Previous Comment, Next Comment.
- **Expected Result**: All five buttons are disabled (`aria-disabled="true"`, visually grayed out). Comment count shows "0 comments". Tooltips provide appropriate messages (e.g., "Load a file to get started" on Generate).
- **Edge Cases**:
  - Keyboard shortcuts should not function in the empty state (e.g., `Cmd+Shift+G` does nothing).

---

### Large File Performance

---

#### `TC-crp-large-file-scroll-no-jank`: 10,000-line file scrolls smoothly

- **Type**: E2E / Performance
- **Covers**: `AC-crp-large-file-scroll`, `NFR-crp-large-file-perf`
- **Preconditions**: A text file with exactly 10,000 lines is prepared (e.g., generated programmatically).
- **Steps**:
  1. Load the 10,000-line file into the application.
  2. Scroll from the top to approximately line 5,000 using continuous scrolling (mouse wheel or scrollbar drag).
  3. Scroll from line 5,000 to line 10,000.
  4. Scroll back to the top.
  5. Measure frame timing during scrolling (using Playwright's performance.mark or browser DevTools Performance panel).
- **Expected Result**: Scrolling is smooth with no visible stutter. No frame drops exceed 200ms. The application remains responsive (UI is not frozen at any point).
- **Edge Cases**:
  - File with 10,000 lines and 50 comments interspersed: comments add variable-height rows to the virtualizer. Scrolling should still be smooth.
  - File with more than 10,000 lines (e.g., 15,000): a warning banner appears but the file is still loadable and scrollable.

---

#### `TC-crp-large-file-scroll-warning-banner`: Warning banner for files over 10,000 lines

- **Type**: Integration
- **Covers**: `AC-crp-large-file-scroll`, `NFR-crp-large-file-perf`
- **Preconditions**: A text file with 15,000 lines is prepared.
- **Steps**:
  1. Load the 15,000-line file.
  2. Observe the code viewer.
- **Expected Result**: A dismissible yellow warning banner appears at the top of the code viewer: "This file has 15000 lines. Performance may be affected for very large files." The file is still loaded and functional.
- **Edge Cases**:
  - Exactly 10,000 lines: no warning banner (the threshold is "over 10,000").
  - 10,001 lines: warning banner appears.
  - Dismissing the banner: it should not reappear during the session.

---

### Comment Navigation

---

#### `TC-crp-comment-navigation-next-happy`: Next comment navigation scrolls to next comment

- **Type**: E2E
- **Covers**: `AC-crp-comment-navigation-next`, `FR-crp-comment-navigation`
- **Preconditions**: A file is loaded. Comments exist on lines 5, 20, and 100.
- **Steps**:
  1. Click the "Next" arrow button in the toolbar (or press `]`).
  2. Observe the code viewer.
  3. Click "Next" again.
  4. Observe the code viewer.
- **Expected Result**: After step 2: the viewer scrolls to center line 5's comment, and the CommentBubble is highlighted with a brief pulse animation. The toolbar shows "Comment 1 of 3". After step 4: the viewer scrolls to line 20's comment, toolbar shows "Comment 2 of 3".
- **Edge Cases**:
  - Navigation when no comment is currently focused: the first "Next" press should go to the first comment (line 5).

---

#### `TC-crp-comment-navigation-prev-happy`: Previous comment navigation scrolls to previous comment

- **Type**: E2E
- **Covers**: `AC-crp-comment-navigation-next`, `FR-crp-comment-navigation`
- **Preconditions**: A file is loaded. Comments exist on lines 5, 20, and 100. The current focus is on line 20's comment (comment 2 of 3).
- **Steps**:
  1. Click the "Previous" arrow button in the toolbar (or press `[`).
- **Expected Result**: The viewer scrolls to center line 5's comment. The toolbar shows "Comment 1 of 3".
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-crp-comment-navigation-wrap-around`: Navigation wraps from last to first and first to last

- **Type**: E2E
- **Covers**: `AC-crp-comment-navigation-next`, `FR-crp-comment-navigation`
- **Preconditions**: A file is loaded. Comments exist on lines 5, 20, and 100. Current focus is on line 100's comment (comment 3 of 3).
- **Steps**:
  1. Click "Next".
  2. Observe the viewer and toolbar.
  3. Now press "Previous" to go to line 100, then press "Previous" again to go to line 20, then "Previous" again to go to line 5, then "Previous" once more.
- **Expected Result**: After step 2: the viewer wraps to line 5's comment, toolbar shows "Comment 1 of 3". After the final "Previous" in step 3: the viewer wraps to line 100's comment, toolbar shows "Comment 3 of 3".
- **Edge Cases**:
  - Only one comment exists: Next and Previous should both stay on that single comment. Toolbar shows "Comment 1 of 1".

---

### Keyboard Accessibility

---

#### `TC-crp-keyboard-add-comment-happy`: Add a comment using only the keyboard

- **Type**: E2E
- **Covers**: `AC-crp-keyboard-add-comment`, `NFR-crp-accessibility-keyboard`
- **Preconditions**: A file is loaded in the viewer.
- **Steps**:
  1. Press `Tab` to move focus into the code viewer area.
  2. Press `ArrowDown` to navigate to line 3 (visible focus ring on line 3).
  3. Press `Enter` (or `c`) to open the InlineCommentEditor for line 3.
  4. Type "Fix this bug".
  5. Press `Cmd+Enter` (or `Ctrl+Enter`) to submit the comment.
- **Expected Result**: The InlineCommentEditor opens on line 3 without any mouse interaction. After submission, a CommentBubble appears on line 3 with "Fix this bug". Focus returns to line 3 in the code viewer.
- **Edge Cases**:
  - Pressing `Escape` after opening the editor: the editor closes, no comment is created, focus returns to the code viewer.
  - Using `Tab` within the editor: focus should cycle through the text area, Comment button, and Cancel button.

---

#### `TC-crp-keyboard-range-select`: Select a line range using keyboard

- **Type**: E2E
- **Covers**: `AC-crp-keyboard-add-comment`, `NFR-crp-accessibility-keyboard`, `AC-crp-add-comment-line-range`
- **Preconditions**: A file is loaded. Focus is in the code viewer on line 5.
- **Steps**:
  1. Hold `Shift` and press `ArrowDown` three times (to extend selection to lines 5-8).
  2. Observe the highlighted lines.
  3. Press `Enter` to open the InlineCommentEditor for the selected range.
  4. Type "Refactor this block" and submit with `Cmd+Enter`.
- **Expected Result**: Lines 5-8 are highlighted with a blue background during selection. The editor opens for "Lines 5-8". After submission, a range comment is created for lines 5-8.
- **Edge Cases**:
  - Pressing `Escape` during range selection: the selection clears, no editor opens.

---

### Binary File Rejection

---

#### `TC-crp-binary-file-rejected-upload`: Binary file rejected via upload

- **Type**: E2E
- **Covers**: `AC-crp-binary-file-rejected`
- **Preconditions**: Application is in the initial empty state. A binary file (e.g., a PNG image or compiled executable) is available.
- **Steps**:
  1. Click "Choose file".
  2. Select the binary file.
- **Expected Result**: The application displays an error message inside the drop zone: "This file doesn't appear to be a text file. Only plain-text files are supported." The error state shows a red border. A "Dismiss" link is present to return to the default state. No garbled content is shown. The application does not crash.
- **Edge Cases**:
  - A file that is mostly text but contains a few null bytes (e.g., a corrupted text file): should still be rejected (null byte detection in first 8,192 bytes).

---

#### `TC-crp-binary-file-rejected-drag-drop`: Binary file rejected via drag and drop

- **Type**: E2E
- **Covers**: `AC-crp-binary-file-rejected`
- **Preconditions**: Application is in the initial empty state. A binary file is available.
- **Steps**:
  1. Drag the binary file onto the drop zone and drop it.
- **Expected Result**: Same error message and behavior as `TC-crp-binary-file-rejected-upload`. The application shows the error state inside the drop zone and does not crash.
- **Edge Cases**:
  - N/A (mirrors upload test for different loading method).

---

#### `TC-crp-binary-file-rejected-no-crash`: Application remains functional after binary file rejection

- **Type**: E2E
- **Covers**: `AC-crp-binary-file-rejected`
- **Preconditions**: A binary file was just rejected (error state is shown).
- **Steps**:
  1. Click the "Dismiss" link to return to the default drop zone state.
  2. Upload a valid text file.
- **Expected Result**: The error state clears. The valid text file loads normally in the code viewer. All functionality works as expected.
- **Edge Cases**:
  - Uploading another binary file after dismissing the first error: the error should appear again correctly.

---

## Edge Cases & Error Scenarios

This section covers additional edge cases and error conditions not directly mapped to a single AC slug but important for comprehensive coverage.

---

### `TC-crp-edge-multiple-comments-same-line`: Multiple comments on the same line

- **Type**: Integration
- **Covers**: `FR-crp-line-comment-create`, `AC-crp-add-comment-single-line`
- **Preconditions**: A file is loaded.
- **Steps**:
  1. Add a comment "First comment" on line 5.
  2. Add a second comment "Second comment" on line 5.
  3. Observe the code viewer.
  4. Generate the prompt.
- **Expected Result**: Both comments are displayed below line 5 as separate CommentBubbles. The gutter shows one indicator for line 5. Comment count shows "2 comments". In the generated prompt, both comments appear under line 5 in creation order.
- **Edge Cases**:
  - Deleting one of two comments on the same line: the remaining comment stays, the gutter indicator stays, the count decrements by 1.

---

### `TC-crp-edge-very-long-comment-text`: Very long comment text

- **Type**: Integration
- **Covers**: `FR-crp-line-comment-create`
- **Preconditions**: A file is loaded.
- **Steps**:
  1. Add a comment with 5,000 characters of text on line 1.
  2. Observe the CommentBubble.
  3. Generate the prompt.
- **Expected Result**: The CommentBubble displays the full text (scrollable within the bubble if needed, or wrapping). The InlineCommentEditor text area should have scrolled when the text exceeded 200px height (per design spec). The generated prompt includes the full comment text. No truncation occurs.
- **Edge Cases**:
  - Comment with multiple paragraphs (containing newlines): line breaks should be preserved in the bubble and in the generated prompt.

---

### `TC-crp-edge-file-with-empty-lines`: File containing empty lines

- **Type**: Integration
- **Covers**: `FR-crp-file-display`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Load a file with content:
     ```
     line one

     line three

     ```
  2. Observe the code viewer.
- **Expected Result**: Empty lines are displayed with their line numbers (lines 2 and 4 are empty but still numbered). Adding a comment on an empty line (e.g., line 2) should work normally.
- **Edge Cases**:
  - File consisting entirely of empty lines: all lines should be numbered sequentially.
  - File ending with multiple trailing newlines: each newline produces a numbered line.

---

### `TC-crp-edge-file-with-very-long-lines`: File with very long lines (horizontal overflow)

- **Type**: Integration
- **Covers**: `FR-crp-file-display`, `NFR-crp-large-file-perf`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Load a file containing a line that is 10,000 characters long (e.g., a minified JavaScript file).
  2. Observe the code viewer.
- **Expected Result**: The code viewer enables horizontal scrolling for the code content area. The gutter and line numbers remain fixed (sticky) and do not scroll horizontally. The long line is not wrapped. Scrolling horizontally reveals the rest of the line.
- **Edge Cases**:
  - Multiple long lines at different widths: horizontal scrollbar should accommodate the longest line.
  - Adding a comment on a very long line: the comment editor and bubble should span the code content column width, not the full line length.

---

### `TC-crp-edge-special-characters-in-comments`: Special characters in comment text

- **Type**: Unit
- **Covers**: `FR-crp-line-comment-create`, `FR-crp-prompt-format`
- **Preconditions**: The `buildPrompt` function is available.
- **Steps**:
  1. Create a comment with text containing special characters: backticks (`` ` ``), angle brackets (`<`, `>`), ampersands (`&`), asterisks (`**`), and markdown formatting (`# heading`, `- list`).
  2. Generate the prompt.
  3. Inspect the output.
- **Expected Result**: The comment text appears in the generated prompt exactly as typed, with no HTML encoding, no markdown interpretation, and no escaping. The characters are preserved verbatim.
- **Edge Cases**:
  - Comment containing triple backticks (`` ``` ``): should not break the code block formatting in the prompt. (Note: this could be a real formatting issue -- flag if the prompt structure uses markdown fences around the code block.)

---

### `TC-crp-edge-unicode-content`: Unicode content in files and comments

- **Type**: Integration
- **Covers**: `FR-crp-file-display`, `FR-crp-line-comment-create`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Load a file containing Unicode content:
     ```
     const greeting = "Hello";
     const emoji = "rocket ship";
     const chinese = "Hello";
     const arabic = "mrhba";
     ```
  2. Add a comment on line 2 with text containing emoji and CJK characters.
  3. Generate the prompt.
- **Expected Result**: All Unicode characters are displayed correctly in the code viewer, in the comment bubble, and in the generated prompt. Line numbers align correctly. No garbled or replaced characters.
- **Edge Cases**:
  - RTL text (Arabic, Hebrew): the code viewer uses a monospace font and LTR layout -- RTL characters may display in logical order within the LTR context. This is acceptable per the design spec (no RTL layout support required).
  - Combining diacritical marks: characters with combining marks should render as a single visual glyph.

---

### `TC-crp-edge-rapid-successive-comments`: Rapid successive comment additions

- **Type**: E2E
- **Covers**: `FR-crp-line-comment-create`, `FR-crp-comment-count`
- **Preconditions**: A file is loaded.
- **Steps**:
  1. Quickly add 10 comments in succession on different lines (using keyboard shortcuts for speed: click line, type text, Cmd+Enter, immediately click next line).
  2. Observe the application state after all 10 comments are added.
- **Expected Result**: All 10 comments are created successfully. Comment count shows "10 comments". All CommentBubbles are visible at their correct lines. No comments are lost or duplicated. The application remains responsive throughout.
- **Edge Cases**:
  - Opening a new comment editor while another is already open: the existing editor should close (cancel) before the new one opens, per typical UI behavior. (Note: the specs do not explicitly address this -- flag if behavior is ambiguous.)

---

### `TC-crp-edge-clipboard-permission-denied`: Browser clipboard permission denied

- **Type**: Integration
- **Covers**: `AC-crp-copy-clipboard`, `FR-crp-prompt-copy`
- **Preconditions**: A prompt has been generated. The browser's Clipboard API permission is denied (simulated via Playwright's `browserContext.grantPermissions` or by mocking `navigator.clipboard.writeText` to reject).
- **Steps**:
  1. Click the "Copy" button.
- **Expected Result**: The application falls back to the `execCommand('copy')` method (per engineering spec `clipboard.ts`). If the fallback also fails, a toast notification appears with an error message: "Failed to copy. Try selecting the text manually." The application does not crash. The user can still manually select text in the prompt preview and copy.
- **Edge Cases**:
  - Safari-specific behavior where the Clipboard API requires secure context (HTTPS): the fallback should handle this.
  - Both modern API and fallback failing: error toast is shown, application remains functional.

---

### `TC-crp-edge-stale-prompt-indicator`: Prompt staleness after comment changes

- **Type**: Integration
- **Covers**: `AC-crp-generate-prompt-structure`, `AC-crp-edit-comment`, `AC-crp-delete-comment`
- **Preconditions**: A prompt has been generated. The prompt preview shows the generated content.
- **Steps**:
  1. Edit an existing comment (change its text).
  2. Observe the prompt preview panel.
  3. Add a new comment.
  4. Observe the prompt preview panel.
  5. Delete a comment.
  6. Observe the prompt preview panel.
- **Expected Result**: After each modification (steps 1, 3, 5), the prompt preview shows a yellow stale banner: "Prompt is outdated. Regenerate to include latest changes." with a "Regenerate" link. The previously generated prompt text is still visible but marked as stale.
- **Edge Cases**:
  - Changing the preamble text: should also trigger the stale indicator.
  - Clicking "Regenerate": the prompt is regenerated with the latest comments and preamble, and the stale indicator disappears.

---

### `TC-crp-edge-prompt-gen-performance`: Prompt generation completes within 300ms for large inputs

- **Type**: Unit / Performance
- **Covers**: `NFR-crp-prompt-gen-time`, `FR-crp-prompt-generate`
- **Preconditions**: A test file with 10,000 lines and 200 comments is programmatically created.
- **Steps**:
  1. Call `buildPrompt` with the large input.
  2. Measure the execution time using `performance.now()`.
- **Expected Result**: The function completes in under 300ms.
- **Edge Cases**:
  - 200 comments all on the same line: sort should still be fast.
  - Comments with very long text (1,000 characters each): string assembly should still be within budget.

---

### `TC-crp-edge-initial-render-time`: File under 1,000 lines renders within 500ms

- **Type**: E2E / Performance
- **Covers**: `NFR-crp-render-time`
- **Preconditions**: A text file with 999 lines is prepared.
- **Steps**:
  1. Load the file.
  2. Measure time from file load to visible text with line numbers (using Playwright performance marks or DOM observation).
- **Expected Result**: Text with line numbers is visible within 500ms. Syntax highlighting may load progressively after this initial render.
- **Edge Cases**:
  - File with exactly 500 lines: well within the budget.
  - File with exactly 1,000 lines: at the boundary, should still meet the 500ms target.

---

### `TC-crp-edge-responsive-below-1024`: Application shows message below 1024px viewport

- **Type**: E2E
- **Covers**: `NFR-crp-responsive-layout`
- **Preconditions**: Application is open.
- **Steps**:
  1. Resize the browser window to 1023px wide.
  2. Observe the application.
- **Expected Result**: A full-screen overlay message appears recommending a wider viewport. The application content is hidden behind the overlay. No functionality is accessible.
- **Edge Cases**:
  - Resizing from 1023px back to 1024px: the overlay disappears and the application is fully functional.
  - Viewport exactly at 1024px: the application should be usable, no overlay.

---

### `TC-crp-edge-cross-browser-clipboard`: Clipboard works across browsers

- **Type**: E2E
- **Covers**: `NFR-crp-browser-support`, `AC-crp-copy-clipboard`
- **Preconditions**: The full application is running. Tests are executed against Chrome, Firefox, and WebKit (Safari proxy) via Playwright.
- **Steps**:
  1. Load a file, add a comment, generate a prompt, and copy to clipboard in each browser.
- **Expected Result**: The copy operation succeeds in all three browsers. The clipboard content matches the preview in all browsers.
- **Edge Cases**:
  - Firefox may require different permission grants for clipboard access.
  - WebKit/Safari may use the `execCommand` fallback path.

---

### `TC-crp-edge-no-data-persistence`: Session does not persist across page reloads

- **Type**: E2E
- **Covers**: `NFR-crp-no-data-persistence`
- **Preconditions**: A file is loaded with comments and a preamble.
- **Steps**:
  1. Reload the page (F5 or `location.reload()`).
  2. Observe the application state.
- **Expected Result**: The application returns to the initial empty state. No file, comments, or preamble are preserved. No data is stored in localStorage, sessionStorage, IndexedDB, or cookies.
- **Edge Cases**:
  - N/A (this confirms a deliberate non-feature).

---

### `TC-crp-edge-focus-management-editor`: Focus management when editor opens and closes

- **Type**: Integration
- **Covers**: `NFR-crp-accessibility-keyboard`, `AC-crp-keyboard-add-comment`
- **Preconditions**: A file is loaded. Focus is in the code viewer.
- **Steps**:
  1. Open the InlineCommentEditor on line 5 (via click or keyboard).
  2. Observe where focus is placed.
  3. Submit a comment.
  4. Observe where focus returns.
  5. Open the editor again, then cancel.
  6. Observe where focus returns.
- **Expected Result**: Step 2: focus is in the text area of the editor. Step 4: focus returns to line 5 in the code viewer. Step 6: focus returns to line 5 in the code viewer.
- **Edge Cases**:
  - Opening the editor via the edit button on a CommentBubble: after save or cancel, focus should return to the CommentBubble.
  - Focus trap in the confirmation dialog: Tab should cycle within the dialog, not escape to the page behind it.

---

### `TC-crp-edge-untitled-file-prompt`: Untitled file name in generated prompt

- **Type**: Unit
- **Covers**: `FR-crp-prompt-format`, `FR-crp-filename-display`
- **Preconditions**: The `buildPrompt` function is available.
- **Steps**:
  1. Call `buildPrompt` with a file that has name "Untitled" and language "plaintext".
- **Expected Result**: The prompt contains `## File: Untitled (Plain Text)`.
- **Edge Cases**:
  - User edits the file name from "Untitled" to a custom name after paste: the updated name should appear in subsequently generated prompts.

---

### `TC-crp-edge-client-side-only`: No network requests are made

- **Type**: E2E
- **Covers**: `NFR-crp-client-only`
- **Preconditions**: The application is running with network monitoring enabled (e.g., Playwright's `page.route` to intercept all requests).
- **Steps**:
  1. Load a file, add comments, generate a prompt, copy to clipboard, clear the session.
  2. Inspect all network requests made during the entire workflow.
- **Expected Result**: No outbound network requests are made to external services. The only requests are for the application's own static assets (JS bundles, CSS, WASM grammars) served from the same origin.
- **Edge Cases**:
  - Shiki WASM grammar loading: these should be bundled and served from the same origin, not fetched from a CDN.

---

## Regression Considerations

### What existing functionality could changes to this feature break?

Since this is a greenfield single-page application with no existing features, traditional regression concerns are minimal. However, the following cross-cutting concerns should be monitored during iterative development:

1. **Virtualization changes affecting comment rendering**: Modifications to TanStack Virtual configuration (overscan, row height estimation) could cause comment bubbles to misalign with their target lines or disappear from the viewport.

2. **State management changes**: Adding new fields to the Zustand store or changing action semantics could break the prompt generation pipeline. The `buildPrompt` pure function should always be tested against the current store shape.

3. **Shiki version upgrades**: Updating the Shiki dependency could change syntax highlighting behavior, token structure, or WASM loading. Visual regression tests for highlighted code are recommended.

4. **Clipboard API browser compatibility**: Browser updates may change Clipboard API behavior or permissions. The fallback path (`execCommand`) should always be maintained and tested.

5. **Tailwind CSS v4 updates**: Tailwind v4 uses CSS-native cascade layers. Changes to the Tailwind configuration could affect component styling globally (e.g., color tokens, spacing).

6. **Comment order consistency**: The sort-by-startLine-then-createdAt behavior is critical for prompt generation and navigation. Any changes to comment data structures or insertion logic should verify sort order.

### Recommended regression suite

Run the following test cases as a minimum regression suite before any release:

- `TC-crp-load-upload-happy` (file loading works)
- `TC-crp-add-comment-single-line-happy` (comment creation works)
- `TC-crp-edit-comment-happy` (comment editing works)
- `TC-crp-delete-comment-happy` (comment deletion works)
- `TC-crp-generate-prompt-structure-happy` (prompt generation works)
- `TC-crp-copy-clipboard-happy` (clipboard copy works)
- `TC-crp-preview-matches-copy-exact` (preview matches clipboard)
- `TC-crp-clear-confirmation-confirm-clears` (session clear works)
- `TC-crp-keyboard-add-comment-happy` (keyboard accessibility works)
- `TC-crp-large-file-scroll-no-jank` (performance holds)
- `TC-crp-binary-file-rejected-upload` (error handling works)
