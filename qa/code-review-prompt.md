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
| `AC-crp-done-sends-prompt` | `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-clipboard-parallel`, `TC-crp-done-auto-close-clipboard` | Not started |
| `AC-crp-done-auto-close` | `TC-crp-done-auto-close-app-mode`, `TC-crp-done-auto-close-fallback`, `TC-crp-done-auto-close-clipboard` | Not started |
| `AC-crp-done-confirmation` | `TC-crp-done-happy`, `TC-crp-done-auto-close-fallback` | Not started |
| `AC-crp-done-fallback-clipboard` | `TC-crp-done-fallback-clipboard`, `TC-crp-done-resend-after-failure` | Not started |
| `AC-crp-done-disabled-no-comments` | `TC-crp-done-disabled-no-comments` | Not started |
| `AC-crp-done-standalone-hidden` | `TC-crp-done-hidden-standalone`, `TC-crp-done-hidden-after-clear` | Not started |
| `FR-crp-done-action` | `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-reset-on-comment-add`, `TC-crp-done-reset-on-comment-edit`, `TC-crp-done-reset-on-comment-delete`, `TC-crp-done-reset-on-preamble-change`, `TC-crp-done-resend-after-failure`, `TC-crp-done-rapid-double-click`, `TC-crp-done-copy-still-works`, `TC-crp-done-auto-close-app-mode` | Not started |
| `FR-crp-prompt-handoff` | `TC-crp-done-happy` | Not started |
| `AC-crp-multi-file-load-adds` | `TC-crp-multi-file-load-second`, `TC-crp-multi-file-load-paste-adds` | Not started |
| `AC-crp-multi-file-drop-multiple` | `TC-crp-multi-file-drop-multiple-happy`, `TC-crp-multi-file-drop-mixed-binary` | Not started |
| `AC-crp-multi-file-nav-preserves-state` | `TC-crp-multi-file-switch-preserves-comments`, `TC-crp-multi-file-switch-preserves-scroll` | Not started |
| `AC-crp-multi-file-remove-with-comments` | `TC-crp-multi-file-remove-with-comments-confirm`, `TC-crp-multi-file-remove-with-comments-cancel` | Not started |
| `AC-crp-multi-file-remove-no-comments` | `TC-crp-multi-file-remove-no-comments-immediate` | Not started |
| `AC-crp-multi-file-prompt-structure` | `TC-crp-multi-file-prompt-structure-happy`, `TC-crp-multi-file-prompt-order` | Not started |
| `AC-crp-multi-file-prompt-omits-uncommented` | `TC-crp-multi-file-prompt-omits-uncommented` | Not started |
| `AC-crp-multi-file-comment-count` | `TC-crp-multi-file-comment-count-global` | Not started |
| `AC-crp-multi-file-clear-all` | `TC-crp-multi-file-clear-all-confirm`, `TC-crp-multi-file-clear-all-resets` | Not started |
| `AC-crp-multi-file-empty-after-remove-last` | `TC-crp-multi-file-remove-last-empty-state` | Not started |
| `FR-crp-multi-file-load` | `TC-crp-multi-file-load-second`, `TC-crp-multi-file-load-paste-adds`, `TC-crp-multi-file-drop-multiple-happy` | Not started |
| `FR-crp-multi-file-nav` | `TC-crp-multi-file-switch-preserves-comments`, `TC-crp-multi-file-tab-shows-info` | Not started |
| `FR-crp-multi-file-remove` | `TC-crp-multi-file-remove-with-comments-confirm`, `TC-crp-multi-file-remove-no-comments-immediate`, `TC-crp-multi-file-remove-active-switches` | Not started |
| `FR-crp-multi-file-prompt` | `TC-crp-multi-file-prompt-structure-happy` | Not started |
| `FR-crp-multi-file-prompt-format` | `TC-crp-multi-file-prompt-structure-happy`, `TC-crp-multi-file-prompt-order` | Not started |
| `FR-crp-review-context-receive` | `TC-crp-context-graceful-missing`, `TC-crp-context-overall-visible` | Not started |
| `FR-crp-review-context-display` | `TC-crp-context-overall-visible`, `TC-crp-context-per-file-visible`, `TC-crp-context-neutral-vs-review`, `TC-crp-context-dark-mode` | Not started |
| `FR-crp-review-context-overall` | `TC-crp-context-overall-visible`, `TC-crp-context-collapse` | Not started |
| `FR-crp-review-context-per-file` | `TC-crp-context-per-file-visible`, `TC-crp-context-per-file-switches` | Not started |
| `AC-crp-context-overall-visible` | `TC-crp-context-overall-visible` | Not started |
| `AC-crp-context-per-file-visible` | `TC-crp-context-per-file-visible` | Not started |
| `AC-crp-context-per-file-switches` | `TC-crp-context-per-file-switches` | Not started |
| `AC-crp-context-neutral-vs-review` | `TC-crp-context-neutral-vs-review` | Not started |
| `AC-crp-context-graceful-missing` | `TC-crp-context-graceful-missing` | Not started |
| `AC-crp-context-readonly` | `TC-crp-context-readonly` | Not started |
| `AC-crp-file-mark-reviewed` | `TC-crp-mark-reviewed-happy`, `TC-crp-mark-reviewed-via-tab`, `TC-crp-mark-reviewed-keyboard` | Not started |
| `AC-crp-file-unmark-reviewed` | `TC-crp-unmark-reviewed-happy`, `TC-crp-mark-reviewed-keyboard` | Not started |
| `AC-crp-file-reviewed-grouping` | `TC-crp-reviewed-grouping-display`, `TC-crp-reviewed-grouping-all-reviewed`, `TC-crp-reviewed-grouping-none-reviewed` | Not started |
| `AC-crp-file-reviewed-progress-count` | `TC-crp-reviewed-progress-display`, `TC-crp-reviewed-progress-updates`, `TC-crp-reviewed-progress-hidden-single` | Not started |
| `AC-crp-file-reviewed-survives-tab-switch` | `TC-crp-reviewed-survives-tab-switch` | Not started |
| `AC-crp-file-reviewed-with-comments` | `TC-crp-reviewed-independent-of-comments` | Not started |
| `AC-crp-file-reviewed-clear-session` | `TC-crp-reviewed-clear-session-resets` | Not started |
| `FR-crp-file-reviewed-toggle` | `TC-crp-mark-reviewed-happy`, `TC-crp-unmark-reviewed-happy`, `TC-crp-mark-reviewed-via-tab`, `TC-crp-mark-reviewed-keyboard` | Not started |
| `FR-crp-file-reviewed-visual` | `TC-crp-mark-reviewed-happy`, `TC-crp-unmark-reviewed-happy`, `TC-crp-reviewed-visual-tab-states` | Not started |
| `FR-crp-file-reviewed-grouping` | `TC-crp-reviewed-grouping-display`, `TC-crp-reviewed-grouping-all-reviewed`, `TC-crp-reviewed-grouping-none-reviewed`, `TC-crp-reviewed-new-file-unreviewed` | Not started |
| `FR-crp-file-reviewed-progress` | `TC-crp-reviewed-progress-display`, `TC-crp-reviewed-progress-updates`, `TC-crp-reviewed-progress-hidden-single`, `TC-crp-reviewed-remove-file-discards` | Not started |
| `FR-crp-file-reviewed-persistence` | `TC-crp-reviewed-survives-tab-switch`, `TC-crp-reviewed-clear-session-resets` | Not started |

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
  - Dropping multiple files simultaneously: all files should be loaded as separate file rows in the FileBrowser sidebar per `AC-crp-multi-file-drop-multiple`.
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
  3. Observe the prompt preview (which auto-updates).
- **Expected Result**: The prompt preview shows the comment on "Lines 10-12" with the new text. The line association is unchanged.
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
  - Deleting the last comment: the prompt preview clears and returns to the placeholder state, and the Copy button becomes disabled.

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

#### `TC-crp-generate-prompt-no-comments-disabled`: Prompt preview is empty when no comments exist

- **Type**: Integration
- **Covers**: `AC-crp-generate-prompt-no-comments`
- **Preconditions**: A file is loaded. No comments have been added.
- **Steps**:
  1. Load a file into the code viewer.
  2. Observe the prompt preview area in the sidebar.
- **Expected Result**: The prompt preview shows a placeholder message: "Add comments to the code to generate your AI prompt." The prompt value is empty/null. The Copy button is disabled.
- **Edge Cases**:
  - Loading a file with a preamble but no comments: the placeholder should still be shown (comments are required for prompt generation).

---

#### `TC-crp-generate-prompt-no-comments-after-delete-all`: Prompt clears when all comments are deleted

- **Type**: E2E
- **Covers**: `AC-crp-generate-prompt-no-comments`, `AC-crp-delete-comment`
- **Preconditions**: A file is loaded. One comment exists (the prompt is automatically generated and displayed in the preview).
- **Steps**:
  1. Observe the prompt preview -- a prompt is displayed because a comment exists.
  2. Delete the only comment.
  3. Observe the prompt preview.
- **Expected Result**: After adding a comment, the prompt appears automatically in the preview. After deleting the last comment, the prompt clears and the placeholder message returns ("Add comments to the code to generate your AI prompt."). The Copy button becomes disabled.
- **Edge Cases**:
  - Deleting multiple comments one by one until none remain: the prompt should update after each deletion, and the placeholder should appear only after the very last comment is removed.

---

### Copy to Clipboard

---

#### `TC-crp-copy-clipboard-happy`: Prompt is copied to clipboard

- **Type**: E2E
- **Covers**: `AC-crp-copy-clipboard`, `FR-crp-prompt-copy`
- **Preconditions**: A file is loaded with at least one comment (the prompt is automatically generated and displayed in the preview panel).
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
- **Preconditions**: A file is loaded with at least one comment.
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
- **Preconditions**: A file is loaded with a preamble and multiple comments (the prompt is automatically generated).
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
  1. Observe the toolbar buttons: Copy, Clear, Previous Comment, Next Comment.
- **Expected Result**: All buttons are disabled (`aria-disabled="true"`, visually grayed out). Comment count shows "0 comments". Tooltips provide appropriate messages (e.g., "Load a file to get started").
- **Edge Cases**:
  - Keyboard shortcuts should not function in the empty state.

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

### Done Action & Prompt Handoff

---

#### `TC-crp-done-happy`: Done sends prompt and shows confirmation

- **Type**: E2E
- **Covers**: `AC-crp-done-sends-prompt`, `AC-crp-done-confirmation`, `FR-crp-done-action`, `FR-crp-prompt-handoff`
- **Preconditions**: File loaded via slash command mode (`?file=` URL param). At least one comment exists.
- **Steps**:
  1. Click the Done button in the toolbar.
  2. Observe the network request, button state, and window/toast behavior.
  3. Paste into an external text editor to verify clipboard content.
- **Expected Result**: A POST request is sent to `/api/prompt-output` with the prompt text as the body. The prompt is also copied to the clipboard. If opened in app-mode window (via Chrome/Chromium `--app` flag), the window closes automatically after POST succeeds (see `TC-crp-done-auto-close-app-mode`). If opened as a regular browser tab, the button changes to "Sending..." then to "Sent ✓" and a toast notification appears: "Prompt sent to agent! Switch back to your terminal." (see `TC-crp-done-auto-close-fallback`).
- **Edge Cases**:
  - Done button is positioned to the left of the Copy button, with primary styling (per design spec).

---

#### `TC-crp-done-keyboard-shortcut`: Done triggered via keyboard

- **Type**: E2E
- **Covers**: `FR-crp-done-action`
- **Preconditions**: File loaded via slash command mode (`?file=` URL param). At least one comment exists.
- **Steps**:
  1. Press `Cmd+Shift+D` (macOS) or `Ctrl+Shift+D` (other platforms).
  2. Observe the button state and toast notification.
- **Expected Result**: Same behavior as clicking Done: POST request sent, button transitions through "Sending..." -> "Sent ✓", toast appears, prompt copied to clipboard.
- **Edge Cases**:
  - Pressing the shortcut when Done is disabled (no comments): nothing should happen.
  - Pressing the shortcut when Done is hidden (standalone mode): nothing should happen.

---

#### `TC-crp-done-clipboard-parallel`: Clipboard copy happens in parallel with POST

- **Type**: Integration
- **Covers**: `AC-crp-done-sends-prompt`
- **Preconditions**: Slash command mode, comments exist.
- **Steps**:
  1. Click Done.
  2. Verify clipboard content immediately after the POST completes.
- **Expected Result**: Clipboard contains the same prompt text that was POSTed. The clipboard write is not blocked by or dependent on the POST response.
- **Edge Cases**:
  - If clipboard write fails but POST succeeds: the "Sent ✓" state should still show (the primary action succeeded).

---

#### `TC-crp-done-auto-close-app-mode`: Window closes after Done in app-mode

- **Type**: E2E
- **Covers**: `AC-crp-done-auto-close`, `FR-crp-done-action`
- **Preconditions**: CRPG opened in app-mode window (via `/shepherd`), comments exist.
- **Steps**:
  1. Click Done. Observe what happens after POST succeeds.
- **Expected Result**: Window closes automatically via `window.close()`. No toast or "Sent" state is shown (user is back at terminal).
- **Edge Cases**:
  - If `window.close()` is called but the browser blocks it (e.g., the window was not opened via script): falls back to "Sent ✓" state and toast (see `TC-crp-done-auto-close-fallback`).

---

#### `TC-crp-done-auto-close-fallback`: Toast shown when auto-close fails

- **Type**: E2E
- **Covers**: `AC-crp-done-auto-close`, `AC-crp-done-confirmation`
- **Preconditions**: CRPG opened as regular browser tab (not app-mode), comments exist.
- **Steps**:
  1. Click Done.
- **Expected Result**: Window does NOT close. Done button shows "Sent ✓". Toast appears: "Prompt sent to agent! Switch back to your terminal."
- **Edge Cases**:
  - Opening CRPG directly by navigating to the URL manually (not via `/shepherd`): should also show the toast fallback since `window.close()` only works for script-opened windows.

---

#### `TC-crp-done-auto-close-clipboard`: Clipboard has prompt even when window auto-closes

- **Type**: Integration
- **Covers**: `AC-crp-done-auto-close`, `AC-crp-done-sends-prompt`
- **Preconditions**: CRPG in app-mode, comments exist.
- **Steps**:
  1. Click Done. After window closes, check clipboard contents.
- **Expected Result**: Clipboard contains the generated prompt text (copied in parallel before close).
- **Edge Cases**:
  - If clipboard write is slower than the window close: the clipboard write should be initiated before `window.close()` is called. Both operations (POST + clipboard write) happen in parallel, and `window.close()` is called only after POST succeeds.

---

#### `TC-crp-done-reset-on-comment-add`: Done resets after adding a comment

- **Type**: Integration
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode. Done was clicked and shows "Sent ✓".
- **Steps**:
  1. Add a new comment on any line.
  2. Observe the Done button state.
- **Expected Result**: Done button reverts to "Done" (idle state), ready to send again.
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-crp-done-reset-on-comment-edit`: Done resets after editing a comment

- **Type**: Integration
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode. Done was clicked and shows "Sent ✓". At least one comment exists.
- **Steps**:
  1. Edit an existing comment's text.
  2. Observe the Done button state.
- **Expected Result**: Done button reverts to "Done" (idle state).
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-crp-done-reset-on-comment-delete`: Done resets after deleting a comment

- **Type**: Integration
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode. Done was clicked and shows "Sent ✓". At least 2 comments exist (so deleting one doesn't disable Done).
- **Steps**:
  1. Delete a comment.
  2. Observe the Done button state.
- **Expected Result**: Done button reverts to "Done" (idle state).
- **Edge Cases**:
  - Deleting the last comment: Done should revert to idle AND become disabled (no comments remain).

---

#### `TC-crp-done-reset-on-preamble-change`: Done resets after preamble change

- **Type**: Integration
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode. Done was clicked and shows "Sent ✓".
- **Steps**:
  1. Modify the preamble text.
  2. Observe the Done button state.
- **Expected Result**: Done button reverts to "Done" (idle state).
- **Edge Cases**:
  - Clearing the preamble entirely: Done should still revert to idle (the prompt content changed).

---

#### `TC-crp-done-disabled-no-comments`: Done disabled when no comments

- **Type**: Integration
- **Covers**: `AC-crp-done-disabled-no-comments`
- **Preconditions**: Slash command mode (`?file=` URL param), no comments exist.
- **Steps**:
  1. Observe the Done button in the toolbar.
  2. Attempt to click the Done button.
- **Expected Result**: Done button is visible but disabled (grayed out, `aria-disabled="true"`). Clicking it has no effect. No POST request is sent.
- **Edge Cases**:
  - Adding a comment after observing the disabled state: Done should become enabled.
  - Adding a comment then deleting it: Done should return to disabled.

---

#### `TC-crp-done-hidden-standalone`: Done hidden in standalone mode

- **Type**: E2E
- **Covers**: `AC-crp-done-standalone-hidden`
- **Preconditions**: File loaded via paste, upload, or drag-and-drop (NOT via `?file=` URL param).
- **Steps**:
  1. Load a file using any non-slash-command method.
  2. Add a comment.
  3. Observe the toolbar.
- **Expected Result**: Done button is NOT shown in the toolbar. The Copy button has primary styling. All other toolbar buttons function normally.
- **Edge Cases**:
  - The keyboard shortcut `Cmd+Shift+D` / `Ctrl+Shift+D` should have no effect in standalone mode.

---

#### `TC-crp-done-hidden-after-clear`: Done hidden after session clear

- **Type**: E2E
- **Covers**: `AC-crp-done-standalone-hidden`
- **Preconditions**: File loaded via slash command mode (`?file=` URL param). Done button is visible.
- **Steps**:
  1. Clear the session (click Clear, confirm if prompted).
  2. Load a new file via paste (standalone mode).
  3. Observe the toolbar.
- **Expected Result**: Done button is NOT shown (the app is no longer in slash command mode after clearing and loading a new file manually).
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-crp-done-fallback-clipboard`: Fallback to clipboard on POST failure

- **Type**: E2E
- **Covers**: `AC-crp-done-fallback-clipboard`
- **Preconditions**: Slash command mode, comments exist. The server `/api/prompt-output` endpoint is unreachable or returns an error (simulated via Playwright network interception or by stopping the server).
- **Steps**:
  1. Click Done.
  2. Observe the button state, toast notification, and clipboard content.
- **Expected Result**: Button shows "Sending..." briefly, then reverts to "Done" (idle state, not "Sent ✓"). A toast notification appears: "Could not send to agent. Prompt copied to clipboard -- paste it manually." The clipboard contains the prompt text.
- **Edge Cases**:
  - Server returns 500: same fallback behavior.
  - Network timeout: same fallback behavior (button should not stay in "Sending..." indefinitely).

---

#### `TC-crp-done-resend-after-failure`: Can retry Done after failure

- **Type**: E2E
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Previous Done attempt failed (per `TC-crp-done-fallback-clipboard`). The server issue has been resolved.
- **Steps**:
  1. Click Done again.
  2. Observe the button state and toast notification.
- **Expected Result**: POST succeeds. Button transitions through "Sending..." -> "Sent ✓". Success toast appears.
- **Edge Cases**:
  - N/A (focused test).

---

#### `TC-crp-done-rapid-double-click`: Double-clicking Done doesn't send twice

- **Type**: E2E
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode, comments exist.
- **Steps**:
  1. Double-click Done rapidly.
  2. Monitor network requests.
- **Expected Result**: Only one POST request is sent to `/api/prompt-output`. The button transitions normally through its states. No duplicate toasts appear.
- **Edge Cases**:
  - Triple-clicking: still only one POST.

---

#### `TC-crp-done-copy-still-works`: Copy button still works alongside Done

- **Type**: Integration
- **Covers**: `FR-crp-done-action`
- **Preconditions**: Slash command mode, comments exist.
- **Steps**:
  1. Click the Copy button (not Done).
  2. Observe clipboard content, toast, and network requests.
  3. Observe the Done button state.
- **Expected Result**: Prompt is copied to clipboard. The "Copied to clipboard" toast appears. No POST request is sent. The Done button is not affected (remains in its current state).
- **Edge Cases**:
  - Clicking Copy after Done shows "Sent ✓": Copy should work normally, and Done should remain in "Sent ✓" state.

---

### Multi-File Support

---

#### `TC-crp-multi-file-load-second`: Load a second file into an existing session

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-load-adds`, `FR-crp-multi-file-load`
- **Preconditions**: A file "utils.ts" is loaded in the viewer with 2 comments.
- **Steps**:
  1. Click the "+" button in the FileBrowser sidebar header.
  2. The FileDropZone modal appears.
  3. Upload "helpers.ts".
  4. The modal closes.
- **Expected Result**: Two file rows appear in the FileBrowser sidebar: "utils.ts" and "helpers.ts". "helpers.ts" is the active file (its content is displayed). The 2 comments on "utils.ts" are preserved (switching back shows them). The total comment count still shows "2 comments".
- **Edge Cases**: Loading a file with the same name as an existing file should still work (each has a unique ID).

---

#### `TC-crp-multi-file-load-paste-adds`: Load via paste adds to session

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-load-adds`, `FR-crp-multi-file-load`
- **Preconditions**: A file is already loaded.
- **Steps**:
  1. Click "+" in the FileBrowser sidebar header.
  2. In the modal, click "Paste content".
  3. Paste code and enter "config.json" as the file name.
  4. Click "Load".
- **Expected Result**: The modal closes. A new file row "config.json" appears in the FileBrowser sidebar and is active. The previous file's row is still present.

---

#### `TC-crp-multi-file-drop-multiple-happy`: Drop multiple files at once

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-drop-multiple`, `FR-crp-multi-file-load`
- **Preconditions**: Application has one file loaded.
- **Steps**:
  1. Drag 3 text files from the filesystem onto the application window.
  2. Drop them.
- **Expected Result**: All 3 files are loaded. The FileBrowser sidebar shows 4 file rows total (1 original + 3 new). The last dropped file is the active file. An info toast shows "Loaded 3 files."

---

#### `TC-crp-multi-file-drop-mixed-binary`: Drop mix of text and binary files

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-drop-multiple`
- **Preconditions**: Application is open (with or without existing files).
- **Steps**:
  1. Drag 3 files: 2 text files and 1 PNG image.
  2. Drop them all.
- **Expected Result**: The 2 text files are loaded as file rows in the FileBrowser sidebar. The PNG is rejected. A toast shows "Loaded 2 files. 1 file was skipped (binary)."

---

#### `TC-crp-multi-file-switch-preserves-comments`: Switching files preserves comments

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-nav-preserves-state`, `FR-crp-multi-file-nav`
- **Preconditions**: Two files loaded. "utils.ts" has 3 comments on lines 5, 10, and 15. "helpers.ts" has 1 comment on line 3.
- **Steps**:
  1. Active file is "utils.ts" -- verify 3 comments visible.
  2. Click "helpers.ts" row in the FileBrowser sidebar.
  3. Verify "helpers.ts" content shows with 1 comment on line 3.
  4. Click "utils.ts" row in the FileBrowser sidebar.
  5. Verify "utils.ts" content shows with 3 comments on lines 5, 10, and 15.
- **Expected Result**: All comments are preserved across switches. No data loss.

---

#### `TC-crp-multi-file-switch-preserves-scroll`: Switching files preserves scroll position

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-nav-preserves-state`
- **Preconditions**: Two files loaded. "utils.ts" is a long file (500+ lines).
- **Steps**:
  1. Scroll "utils.ts" to line 200.
  2. Switch to "helpers.ts".
  3. Switch back to "utils.ts".
- **Expected Result**: "utils.ts" is scrolled to approximately line 200 (the position saved when switching away).

---

#### `TC-crp-multi-file-tab-shows-info`: File rows show file name and comment count

- **Type**: Integration
- **Covers**: `FR-crp-multi-file-nav`
- **Preconditions**: Three files loaded. "utils.ts" has 3 comments, "helpers.ts" has 0 comments, "config.json" has 1 comment.
- **Steps**:
  1. Observe the FileBrowser sidebar.
- **Expected Result**: "utils.ts" file row shows a badge "3". "helpers.ts" file row shows no badge. "config.json" file row shows a badge "1". The active file row has distinct styling (highlighted background).

---

#### `TC-crp-multi-file-remove-with-comments-confirm`: Remove file with comments shows confirmation

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-remove-with-comments`, `FR-crp-multi-file-remove`
- **Preconditions**: Two files loaded. "utils.ts" has 2 comments. It is the active file.
- **Steps**:
  1. Click the close (X) button on the "utils.ts" file row in the FileBrowser sidebar.
  2. A confirmation dialog appears.
  3. Click "Remove" (destructive button).
- **Expected Result**: "utils.ts" and its 2 comments are removed. "helpers.ts" becomes the active file. The FileBrowser sidebar shows only "helpers.ts". The total comment count decreases by 2.
- **Edge Cases**: Clicking "Cancel" in the dialog preserves "utils.ts" and all its comments.

---

#### `TC-crp-multi-file-remove-with-comments-cancel`: Cancel removal preserves file

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-remove-with-comments`
- **Preconditions**: File with comments, removal dialog open.
- **Steps**:
  1. Click "Cancel" in the confirmation dialog.
- **Expected Result**: Dialog closes. File and all comments preserved. No changes.

---

#### `TC-crp-multi-file-remove-no-comments-immediate`: Remove file without comments, no confirmation

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-remove-no-comments`, `FR-crp-multi-file-remove`
- **Preconditions**: Two files loaded. "helpers.ts" has 0 comments.
- **Steps**:
  1. Click the close (X) button on the "helpers.ts" file row in the FileBrowser sidebar.
- **Expected Result**: "helpers.ts" is removed immediately. No confirmation dialog appears. The remaining file becomes active.

---

#### `TC-crp-multi-file-remove-active-switches`: Removing active file switches to next file in list

- **Type**: E2E
- **Covers**: `FR-crp-multi-file-remove`
- **Preconditions**: Three files loaded in order: A.ts, B.ts, C.ts. B.ts is active and has no comments.
- **Steps**:
  1. Remove B.ts.
- **Expected Result**: C.ts becomes the active file (the next file in the list below). If the last file in the list is removed, the file above it becomes active.

---

#### `TC-crp-multi-file-remove-last-empty-state`: Removing last file returns to empty state

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-empty-after-remove-last`
- **Preconditions**: Only one file loaded, no comments.
- **Steps**:
  1. Remove the only file.
- **Expected Result**: Application returns to the empty state. The FileBrowser sidebar disappears. The FileDropZone (full variant) is shown. Toolbar buttons are disabled.

---

#### `TC-crp-multi-file-prompt-structure-happy`: Combined prompt has correct multi-file structure

- **Type**: Unit
- **Covers**: `AC-crp-multi-file-prompt-structure`, `FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`
- **Preconditions**: `buildPrompt` function available. Input: preamble "Refactor for consistency", "utils.ts" (TypeScript) with comments on lines 3 and 10, "helpers.ts" (TypeScript) with a comment on line 5.
- **Steps**:
  1. Call `buildPrompt` with the multi-file input.
  2. Parse the output structure.
- **Expected Result**: The output contains:
  1. `## Instructions` with "Refactor for consistency"
  2. `## File: utils.ts (TypeScript)` with `### Requested Changes` listing 2 comments with code snippets
  3. `## File: helpers.ts (TypeScript)` with `### Requested Changes` listing 1 comment with code snippet
  4. Files in load order, comments in line order within each file
- **Edge Cases**: Single file with comments among multiple loaded files should produce the same format as single-file mode.

---

#### `TC-crp-multi-file-prompt-order`: Files in prompt follow load order

- **Type**: Unit
- **Covers**: `FR-crp-multi-file-prompt-format`
- **Preconditions**: `buildPrompt` function available. Files loaded in order: C.ts, A.ts, B.ts. All three have comments.
- **Steps**:
  1. Call `buildPrompt`.
- **Expected Result**: The prompt sections appear in order: C.ts, A.ts, B.ts (load order, not alphabetical).

---

#### `TC-crp-multi-file-prompt-omits-uncommented`: Files without comments excluded from prompt

- **Type**: Unit
- **Covers**: `AC-crp-multi-file-prompt-omits-uncommented`
- **Preconditions**: Three files loaded: A.ts (2 comments), B.ts (0 comments), C.ts (1 comment).
- **Steps**:
  1. Call `buildPrompt`.
- **Expected Result**: The prompt includes `## File: A.ts` and `## File: C.ts` sections only. B.ts does not appear in the prompt.

---

#### `TC-crp-multi-file-comment-count-global`: Comment count spans all files

- **Type**: Integration
- **Covers**: `AC-crp-multi-file-comment-count`, `FR-crp-comment-count`
- **Preconditions**: Two files loaded. "utils.ts" has 3 comments, "helpers.ts" has 2 comments.
- **Steps**:
  1. Observe the toolbar comment count.
  2. Add a comment to "helpers.ts".
  3. Observe the toolbar comment count.
- **Expected Result**: Step 1: "5 comments". Step 3: "6 comments". The count is global across all files.

---

#### `TC-crp-multi-file-clear-all-confirm`: Clear session shows confirmation mentioning all files

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-clear-all`
- **Preconditions**: 3 files loaded with a total of 7 comments.
- **Steps**:
  1. Click "Clear" in the toolbar.
  2. Observe the confirmation dialog.
- **Expected Result**: Dialog body says something like "This will remove all 3 loaded files, all 7 comments, and the preamble. This action cannot be undone."

---

#### `TC-crp-multi-file-clear-all-resets`: Confirming clear removes everything

- **Type**: E2E
- **Covers**: `AC-crp-multi-file-clear-all`
- **Preconditions**: 3 files loaded with comments.
- **Steps**:
  1. Click "Clear" -> confirm.
- **Expected Result**: All files, comments, and preamble removed. Application returns to empty state. FileBrowser sidebar gone.

---

### Review Context Display

---

#### `TC-crp-context-overall-visible`: Overall changeset context is visible in the CRPG

- **Type**: E2E
- **Covers**: `AC-crp-context-overall-visible`, `FR-crp-review-context-receive`, `FR-crp-review-context-display`, `FR-crp-review-context-overall`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data provided. At least 2 files are loaded. The context data includes overall neutral context and overall review feedback.
- **Steps**:
  1. Open the CRPG via `/shepherd-review` (which passes context data).
  2. Look for an overall changeset context section in the CRPG UI.
  3. Verify the overall neutral context is displayed (factual description of the changeset).
  4. Verify the overall review feedback is displayed (agent's opinions and suggestions).
  5. Switch between files in the FileBrowser sidebar and verify the overall context remains visible regardless of which file is active.
- **Expected Result**: An overall changeset context section is visible in the CRPG. It contains two visually distinct parts: (1) neutral context with factual description (e.g., "This changeset adds a new route and refactors utility functions"), and (2) review feedback with the agent's assessment (e.g., "The route implementation follows good patterns. Consider adding error handling."). The overall context is not tied to a specific file and remains visible when switching files. Both sections have clear labels or headers identifying them as "neutral" / "what changed" versus "review" / "feedback."
- **Edge Cases**:
  - Overall context with only neutral content (no review feedback): the neutral section is shown; the review section is absent or empty.
  - Very long overall context text: the section should be scrollable or otherwise handle overflow gracefully.

---

#### `TC-crp-context-per-file-visible`: Per-file context is visible for each file

- **Type**: E2E
- **Covers**: `AC-crp-context-per-file-visible`, `FR-crp-review-context-per-file`, `FR-crp-review-context-display`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data. At least 2 files are loaded. Each file has per-file neutral context and per-file review feedback in the context data.
- **Steps**:
  1. Select the first file in the FileBrowser sidebar.
  2. Verify per-file neutral context is displayed alongside the diff (factual description of what changed in this file).
  3. Verify per-file review feedback is displayed alongside the diff (agent's opinions about this file).
  4. Verify the neutral and review sections have visually distinct styling.
- **Expected Result**: The per-file context appears alongside the file's diff content. The neutral context describes specific changes in the file (e.g., "Added `processData()` function; modified `handleSubmit()` to use async/await"). The review feedback provides the agent's observations (e.g., "The async refactor looks clean. The error handling could be more specific."). Both sections are clearly labeled and visually distinct.
- **Edge Cases**:
  - A file loaded via paste/upload/drag-drop (not from `/shepherd-review`): no per-file context is shown for that file (see `TC-crp-context-graceful-missing`).
  - Per-file context with only neutral content (no review feedback): the neutral section is shown; the review section is absent.

---

#### `TC-crp-context-per-file-switches`: Per-file context updates when switching files

- **Type**: E2E
- **Covers**: `AC-crp-context-per-file-switches`, `FR-crp-review-context-per-file`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data for files A.ts and B.ts. Both files have distinct per-file context (different neutral and review content).
- **Steps**:
  1. Select A.ts in the FileBrowser sidebar.
  2. Read the per-file neutral context and review feedback displayed.
  3. Note the specific content (e.g., neutral says "Modified `fetchData()` function").
  4. Switch to B.ts in the FileBrowser sidebar.
  5. Read the per-file neutral context and review feedback.
  6. Verify the content is different from A.ts's context (e.g., neutral says "Added new `Validator` class").
  7. Switch back to A.ts.
  8. Verify A.ts's per-file context is restored.
- **Expected Result**: When switching from A.ts to B.ts, the per-file context updates to show B.ts's context. The content is specific to B.ts and different from A.ts. Switching back to A.ts restores A.ts's context. The update happens immediately on file switch with no stale data or flicker.
- **Edge Cases**:
  - Rapidly switching between 3+ files: context updates correctly for each file without race conditions.
  - A file with no per-file context (e.g., a file added manually): switching to it shows no per-file context panel; switching back to a context-bearing file restores that file's context.

---

#### `TC-crp-context-neutral-vs-review`: Neutral and review sections have distinct visual styling

- **Type**: E2E
- **Covers**: `AC-crp-context-neutral-vs-review`, `FR-crp-review-context-display`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data that includes both neutral context and review feedback (overall and per-file).
- **Steps**:
  1. Observe the overall context section in the CRPG.
  2. Compare the visual styling of the neutral context area versus the review feedback area.
  3. Check for differences in: background color, border color, section header/label text, icons (if any).
  4. Repeat for per-file context on any file.
- **Expected Result**: The neutral context and review feedback are visually distinct in all of these ways:
  - **Different background/border colors**: Neutral uses informational styling (e.g., blue tones), review uses a distinct color (e.g., violet/purple tones).
  - **Different labels/headers**: Neutral is labeled something like "What changed" or "Changes"; review is labeled something like "Review feedback" or "Agent feedback."
  - **Different icons** (if used): Each section type has its own icon.

  A user who has never used the tool can tell at a glance which section is factual description and which is the agent's opinion. The distinction is consistent between overall context and per-file context.
- **Edge Cases**:
  - Color-blind users: the distinction should not rely solely on color (e.g., labels and/or icons provide redundant differentiation).

---

#### `TC-crp-context-graceful-missing`: No context panel when context data is absent

- **Type**: E2E
- **Covers**: `AC-crp-context-graceful-missing`, `FR-crp-review-context-receive`
- **Preconditions**: The CRPG is opened in standalone mode (no `/shepherd-review` invocation). Files are loaded via paste, upload, or drag-and-drop.
- **Steps**:
  1. Open the CRPG directly (e.g., navigate to the URL without context parameters).
  2. Load a file via paste or upload.
  3. Inspect the UI for any context panels.
  4. Add a second file via drag-and-drop.
  5. Inspect the UI again.
- **Expected Result**: No context panel is shown -- neither overall context nor per-file context. The CRPG works exactly as it did before context support was added. There is no empty context panel, no placeholder text like "No context available," and no collapsed/hidden context section. The UI behaves as if context support does not exist. All existing functionality (comments, prompt generation, copy, Done) works normally.
- **Edge Cases**:
  - Loading a file via `?file=` URL parameter (single-file `/shepherd` mode, no context data): no context panel is shown for this file either.
  - A mixed session where some files have context (from `/shepherd-review`) and some were added manually: only the files from `/shepherd-review` show per-file context; manually-added files do not.

---

#### `TC-crp-context-readonly`: Context text cannot be edited

- **Type**: E2E
- **Covers**: `AC-crp-context-readonly`, `FR-crp-review-context-display`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data. Both overall and per-file context are visible.
- **Steps**:
  1. Click on the overall neutral context text and attempt to type.
  2. Click on the overall review feedback text and attempt to type.
  3. Click on the per-file neutral context text and attempt to type.
  4. Click on the per-file review feedback text and attempt to type.
  5. Try selecting context text and pressing Delete or Backspace.
  6. Try right-clicking context text to check for an "Edit" option.
- **Expected Result**: None of the context text is editable. Clicking on it does not open an editor or place a cursor. Keyboard input does not modify the text. The text can be selected (for copy-paste) but not modified. There are no edit buttons, pencil icons, or other edit affordances on the context sections.
- **Edge Cases**:
  - Selecting context text and pressing Cmd+A / Ctrl+A followed by typing: no modification occurs.
  - The context text is separate from the inline comment system -- clicking on context should not open the InlineCommentEditor.

---

#### `TC-crp-context-collapse`: Context panel can be collapsed and expanded

- **Type**: E2E
- **Covers**: `FR-crp-review-context-display`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data. At least 2 files are loaded.
- **Steps**:
  1. Locate the context panel (overall or per-file).
  2. Click the collapse/toggle control to collapse the context panel.
  3. Verify the context content is hidden and the panel is minimized.
  4. Switch to another file in the FileBrowser sidebar.
  5. Verify the collapsed state persists (context panel remains collapsed on the new file).
  6. Click the expand/toggle control to expand the context panel.
  7. Verify the context content is visible again.
  8. Switch files again.
  9. Verify the expanded state persists.
- **Expected Result**: The context panel can be collapsed to save vertical space when the reviewer wants to focus on the code. The collapsed state persists across file switches (the collapse preference is global, not per-file). Expanding the panel restores the full context view. The toggle control is clearly visible (e.g., a chevron icon or "Show/Hide context" label).
- **Edge Cases**:
  - Collapsing the panel and then reloading the page: the collapsed state may or may not persist (per `NFR-crp-no-data-persistence`, session state is not persisted across reloads).
  - Collapsing when only overall context is visible (no per-file context): the overall context collapses.
  - Collapsing when both overall and per-file context are visible: both collapse together (or each has its own toggle, depending on design).

---

#### `TC-crp-context-dark-mode`: Context panel renders correctly in dark mode

- **Type**: E2E
- **Covers**: `FR-crp-review-context-display`
- **Preconditions**: The CRPG is opened via `/shepherd-review` with context data. Dark mode is enabled (either via system preference or manual toggle).
- **Steps**:
  1. Enable dark mode in the CRPG (or ensure the system is set to dark mode).
  2. Observe the overall context panel (neutral and review sections).
  3. Observe the per-file context panel on a file.
  4. Verify the neutral vs review visual distinction is maintained in dark mode.
  5. Verify text is readable against the dark background.
  6. Toggle between light and dark mode and verify the context panel adapts.
- **Expected Result**: In dark mode:
  - Context panel backgrounds use appropriate dark-mode colors (not the same light-mode blues/violets).
  - The neutral vs review distinction is still visually clear (different shades, different border colors adapted for dark backgrounds).
  - Text contrast is sufficient for readability (meets accessibility contrast ratio guidelines).
  - Section headers, labels, and icons adapt to dark mode.
  - Toggling between light and dark mode causes the context panel to re-render with the correct color scheme.
- **Edge Cases**:
  - System preference set to dark mode but CRPG manually set to light: the CRPG setting takes precedence and context renders in light mode.
  - Very long context text in dark mode: scrollbar styling should also adapt.

---

### File Review Tracking

---

#### `TC-crp-mark-reviewed-happy`: Mark a file as reviewed via ReviewStatusBar

- **Type**: E2E
- **Covers**: `AC-crp-file-mark-reviewed`, `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`
- **Preconditions**: Multiple files are loaded. The active file is unreviewed (default state).
- **Steps**:
  1. Locate the ReviewStatusBar in the code viewer area. It should show an unchecked checkbox with the label "Mark as reviewed".
  2. Click the checkbox or button to mark the file as reviewed.
  3. Observe the ReviewStatusBar.
  4. Observe the file's row in the FileBrowser sidebar.
  5. Observe the file grouping in the FileBrowser sidebar.
- **Expected Result**: After step 2: the ReviewStatusBar checkbox becomes filled with a green checkmark and the label changes to "Reviewed" (the checkmark is rendered inside the checkbox icon, not as label text). The file's row in the FileBrowser sidebar shows a green checkmark icon, and the file row text is muted (lower contrast/opacity). The file's row moves from the "TO REVIEW" group to the "REVIEWED" group in the FileBrowser sidebar.
- **Edge Cases**:
  - Marking a file with no comments as reviewed: should work identically (reviewed status is independent of comments).
  - Marking a file with comments as reviewed: the comments remain visible and editable.

---

#### `TC-crp-unmark-reviewed-happy`: Unmark a reviewed file

- **Type**: E2E
- **Covers**: `AC-crp-file-unmark-reviewed`, `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`
- **Preconditions**: Multiple files are loaded. The active file has been marked as reviewed.
- **Steps**:
  1. The ReviewStatusBar shows a checked checkbox (filled green checkmark) with label "Reviewed".
  2. Click the checkbox or button to unmark the file.
  3. Observe the ReviewStatusBar.
  4. Observe the file's row in the FileBrowser sidebar.
  5. Observe the file grouping.
- **Expected Result**: After step 2: the ReviewStatusBar reverts to an unchecked checkbox with label "Mark as reviewed". The file's row no longer shows a green checkmark, and the file row text returns to normal contrast. The file's row moves from the "REVIEWED" group back to the "TO REVIEW" group.
- **Edge Cases**:
  - Unmarking the only reviewed file: the "REVIEWED" group should become empty/hidden.

---

#### `TC-crp-mark-reviewed-via-tab`: Mark a file as reviewed via FileBrowser sidebar toggle icon

- **Type**: E2E
- **Covers**: `AC-crp-file-mark-reviewed`, `FR-crp-file-reviewed-toggle`
- **Preconditions**: Multiple files are loaded. File B is unreviewed. File A is the active/visible file.
- **Steps**:
  1. Hover over file B's row in the FileBrowser sidebar (without clicking to switch to it).
  2. A small toggle icon (e.g., a circle or checkmark outline) should appear on hover.
  3. Click the toggle icon on file B's row.
  4. Observe file B's row.
  5. Verify that the active file is still file A (the viewer did not switch).
- **Expected Result**: After step 3: file B's row shows a green checkmark and muted text. File B moves to the "REVIEWED" group. The code viewer still displays file A's content (the active file did not change). The progress indicator updates to reflect one more file reviewed.
- **Edge Cases**:
  - Clicking the file row text (not the toggle icon): this should switch to file B (standard file selection behavior), not toggle the reviewed status.

---

#### `TC-crp-mark-reviewed-keyboard`: Toggle review status via keyboard shortcut

- **Type**: E2E
- **Covers**: `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`, `FR-crp-file-reviewed-toggle`
- **Preconditions**: Multiple files are loaded. The active file is unreviewed.
- **Steps**:
  1. Press `Cmd+Shift+R` (macOS) or `Ctrl+Shift+R` (other platforms).
  2. Observe the ReviewStatusBar and the file's row in the FileBrowser sidebar.
  3. Press `Cmd+Shift+R` / `Ctrl+Shift+R` again.
  4. Observe the ReviewStatusBar and the file's row in the FileBrowser sidebar.
- **Expected Result**: After step 1: the file is marked as reviewed (checkbox filled with green checkmark, label "Reviewed", file row shows checkmark, file row moves to "REVIEWED" group). After step 3: the file is unmarked (checkbox unchecked, label "Mark as reviewed", file row returns to normal, file row moves back to "TO REVIEW" group). The shortcut toggles the reviewed state of the currently active file.
- **Edge Cases**:
  - Pressing the shortcut with only 1 file loaded: should still toggle the reviewed status (but the progress indicator may be hidden per `TC-crp-reviewed-progress-hidden-single`).
  - Pressing `r` when the FileBrowser sidebar is focused: should also toggle reviewed status for the focused file (per design spec keyboard shortcut `r` for file-list-focused context).

---

#### `TC-crp-reviewed-grouping-display`: Reviewed and unreviewed files grouped correctly

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-grouping`
- **Preconditions**: 5 files are loaded (A.ts, B.ts, C.ts, D.ts, E.ts). All are initially unreviewed.
- **Steps**:
  1. Mark A.ts and C.ts as reviewed.
  2. Observe the FileBrowser sidebar.
- **Expected Result**: The FileBrowser sidebar shows two groups separated by a divider. The first group is labeled "TO REVIEW" and contains B.ts, D.ts, E.ts (3 files). The second group is labeled "REVIEWED" and contains A.ts, C.ts (2 files). The "TO REVIEW" group appears first (above "REVIEWED"). Within each group, files maintain their original load order.
- **Edge Cases**:
  - Within each group, the file order should follow the original load order (not alphabetical or review-time order).

---

#### `TC-crp-reviewed-grouping-all-reviewed`: All files reviewed hides "To Review" group

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-grouping`
- **Preconditions**: 3 files loaded, all unreviewed.
- **Steps**:
  1. Mark all 3 files as reviewed.
  2. Observe the FileBrowser sidebar.
- **Expected Result**: The "TO REVIEW" group is empty and hidden (no empty group label shown). The "REVIEWED" group contains all 3 files. Only the "REVIEWED" group label is visible.
- **Edge Cases**:
  - Unmarking one file after all are reviewed: the "TO REVIEW" group reappears with that file.

---

#### `TC-crp-reviewed-grouping-none-reviewed`: Default state shows all files in "To Review"

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-grouping`
- **Preconditions**: 3 files loaded. No files have been marked as reviewed.
- **Steps**:
  1. Observe the FileBrowser sidebar.
- **Expected Result**: All 3 files appear in the "TO REVIEW" group. The "REVIEWED" group is empty and hidden. No divider or "REVIEWED" label is shown.
- **Edge Cases**:
  - With only 1 file loaded: the "TO REVIEW" group still shows, or the grouping labels are hidden entirely for single-file sessions (per design spec behavior).

---

#### `TC-crp-reviewed-progress-display`: Progress indicator shows correct reviewed count

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-progress-count`, `FR-crp-file-reviewed-progress`
- **Preconditions**: 4 files are loaded. All unreviewed.
- **Steps**:
  1. Observe the FileBrowser sidebar header for a progress indicator.
  2. Mark the first file as reviewed.
  3. Observe the progress indicator.
  4. Mark the second file as reviewed.
  5. Observe the progress indicator.
- **Expected Result**: Step 1: the progress indicator shows "0/4 reviewed". Step 3: "1/4 reviewed". Step 5: "2/4 reviewed". The format is "N/M reviewed" where N is the count of reviewed files and M is the total file count.
- **Edge Cases**:
  - The progress indicator should be a badge or inline text in the FileBrowser sidebar header (per design spec).

---

#### `TC-crp-reviewed-progress-updates`: Progress updates correctly through mark, unmark, add, and remove

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-progress-count`, `FR-crp-file-reviewed-progress`
- **Preconditions**: 3 files loaded (A.ts, B.ts, C.ts). All unreviewed.
- **Steps**:
  1. Mark A.ts as reviewed. Observe the progress indicator.
  2. Mark B.ts as reviewed. Observe.
  3. Unmark A.ts (toggle back to unreviewed). Observe.
  4. Remove B.ts from the session (close its file row). Observe.
  5. Add a new file D.ts. Observe.
- **Expected Result**: Step 1: "1/3 reviewed". Step 2: "2/3 reviewed". Step 3: "1/3 reviewed" (A.ts unmarked). Step 4: "0/2 reviewed" (B.ts was reviewed and removed; denominator decreases). Step 5: "0/3 reviewed" (D.ts is added as unreviewed; denominator increases).
- **Edge Cases**:
  - Removing an unreviewed file: the denominator decreases but the numerator stays the same.

---

#### `TC-crp-reviewed-progress-hidden-single`: Progress indicator hidden with single file

- **Type**: Integration
- **Covers**: `AC-crp-file-reviewed-progress-count`, `FR-crp-file-reviewed-progress`
- **Preconditions**: Only 1 file is loaded.
- **Steps**:
  1. Observe the FileBrowser sidebar header for a progress indicator.
- **Expected Result**: No progress indicator ("N/M reviewed" badge) is shown. The progress indicator only appears when 2 or more files are loaded.
- **Edge Cases**:
  - Adding a second file: the progress indicator should appear.
  - Removing files until only 1 remains: the progress indicator should disappear.

---

#### `TC-crp-reviewed-survives-tab-switch`: Reviewed status persists across file switches

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-survives-tab-switch`, `FR-crp-file-reviewed-persistence`
- **Preconditions**: 3 files loaded (A.ts, B.ts, C.ts). A.ts is marked as reviewed. B.ts and C.ts are unreviewed.
- **Steps**:
  1. Verify A.ts file row shows the reviewed checkmark.
  2. Click B.ts in the FileBrowser sidebar to switch to it.
  3. Observe A.ts's file row (it should still show the reviewed checkmark).
  4. Click C.ts in the FileBrowser sidebar.
  5. Click A.ts in the FileBrowser sidebar to switch back to it.
  6. Observe the ReviewStatusBar for A.ts.
- **Expected Result**: Throughout all file switches, A.ts remains marked as reviewed. The file row always shows the checkmark. The ReviewStatusBar on A.ts shows the checked state (filled green checkmark, label "Reviewed") when A.ts is the active file. B.ts and C.ts remain unreviewed throughout.
- **Edge Cases**:
  - Rapidly switching between files (A -> B -> C -> A in quick succession): reviewed states are always consistent and never lost.

---

#### `TC-crp-reviewed-independent-of-comments`: Reviewed status is orthogonal to comments

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-with-comments`
- **Preconditions**: 2 files loaded. File A has no comments. File B has 2 comments.
- **Steps**:
  1. Mark file A (no comments) as reviewed. Verify it works.
  2. Mark file B (2 comments) as reviewed. Verify it works.
  3. Add a comment to file A (now reviewed with 1 comment). Verify file A is still reviewed.
  4. Delete all comments from file B (now reviewed with 0 comments). Verify file B is still reviewed.
  5. Add a comment to file B. Verify file B is still reviewed.
- **Expected Result**: At every step, the reviewed status is independent of whether comments exist. Marking a file reviewed does not require comments. Adding or removing comments does not change the reviewed status. The reviewed checkmark and grouping remain stable through comment changes.
- **Edge Cases**:
  - A reviewed file with comments still generates its section in the prompt (reviewed status does not suppress prompt generation).

---

#### `TC-crp-reviewed-clear-session-resets`: Clearing session discards all reviewed statuses

- **Type**: E2E
- **Covers**: `AC-crp-file-reviewed-clear-session`, `FR-crp-file-reviewed-persistence`
- **Preconditions**: 4 files loaded. 3 of them are marked as reviewed. Progress shows "3/4 reviewed".
- **Steps**:
  1. Click "Clear" in the toolbar.
  2. Confirm the clear action (click "Clear session" in the dialog).
  3. Observe the application state.
  4. Load new files (e.g., upload 2 new files).
  5. Observe the new files' reviewed states and the progress indicator.
- **Expected Result**: After step 3: the application is in the empty state (no files, no comments, no preamble, no reviewed statuses). After step 5: the 2 new files are both unreviewed. The progress indicator shows "0/2 reviewed" (if 2+ files are loaded). No reviewed status from the previous session carries over.
- **Edge Cases**:
  - Cancelling the clear dialog: all reviewed statuses are preserved.

---

#### `TC-crp-reviewed-remove-file-discards`: Removing a reviewed file updates progress

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-progress`
- **Preconditions**: 3 files loaded. Files A and B are reviewed, file C is unreviewed. Progress shows "2/3 reviewed".
- **Steps**:
  1. Remove file A (close its file row, confirm if it has comments).
  2. Observe the progress indicator.
  3. Observe the FileBrowser sidebar grouping.
- **Expected Result**: After step 1: the progress indicator shows "1/2 reviewed" (B is still reviewed, C is unreviewed). The "REVIEWED" group shows only B. The "TO REVIEW" group shows only C. File A's reviewed status is fully discarded.
- **Edge Cases**:
  - Removing the only reviewed file: progress shows "0/N reviewed" and the "REVIEWED" group is hidden.

---

#### `TC-crp-reviewed-new-file-unreviewed`: Newly added files default to unreviewed

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-grouping`
- **Preconditions**: 2 files loaded. Both are marked as reviewed. Progress shows "2/2 reviewed".
- **Steps**:
  1. Add a new file (via "+" button, upload, paste, or drag-and-drop).
  2. Observe the new file's row in the FileBrowser sidebar.
  3. Observe the FileBrowser sidebar grouping.
  4. Observe the progress indicator.
- **Expected Result**: The new file's row appears in the "TO REVIEW" group with no checkmark and normal (non-muted) text. The progress indicator updates to "2/3 reviewed". The new file's ReviewStatusBar shows "Mark as reviewed" (unchecked).
- **Edge Cases**:
  - Adding multiple files at once (drag-and-drop multiple): all new files should be unreviewed.

---

#### `TC-crp-reviewed-visual-tab-states`: Visual distinction between reviewed and unreviewed file rows

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-visual`
- **Preconditions**: 3 files loaded. File A is reviewed. Files B and C are unreviewed. File B is the active file.
- **Steps**:
  1. Observe file A's row (reviewed, inactive).
  2. Observe file B's row (unreviewed, active).
  3. Observe file C's row (unreviewed, inactive).
  4. Click file A's row to make it active.
  5. Observe file A's row (reviewed, active).
  6. Observe file B's row (unreviewed, inactive).
- **Expected Result**: Reviewed file rows (A) have: a green checkmark icon, muted/lower-opacity text, and a subtly different background from unreviewed file rows. Unreviewed file rows (B, C) have: no checkmark icon, normal-contrast text. The active file row styling (e.g., highlighted background) applies on top of the reviewed/unreviewed styling. Specifically: file A active+reviewed is visually distinct from file B active+unreviewed. File A inactive+reviewed is visually distinct from file C inactive+unreviewed. All four combinations (active/inactive x reviewed/unreviewed) are distinguishable.
- **Edge Cases**:
  - In dark mode: the checkmark, muted text, and background differences should still be distinguishable.

---

### File Review Tracking -- Edge Cases

---

#### `TC-crp-reviewed-edge-rapid-toggle`: Rapid toggling does not lose state

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-toggle`
- **Preconditions**: A file is loaded and unreviewed.
- **Steps**:
  1. Rapidly click the ReviewStatusBar checkbox 10 times in quick succession.
  2. Observe the final state.
- **Expected Result**: The final state reflects the correct toggle parity (10 toggles from unreviewed = unreviewed). No intermediate states are visible as "stuck." The progress indicator matches the final state. No errors in the console.
- **Edge Cases**:
  - Rapidly using the keyboard shortcut (`Cmd+Shift+R` / `Ctrl+Shift+R`) multiple times: same behavior, final state is correct.

---

#### `TC-crp-reviewed-edge-single-file-reviewed`: Marking the only file as reviewed

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-grouping`
- **Preconditions**: Only 1 file is loaded. It is unreviewed.
- **Steps**:
  1. Mark the file as reviewed.
  2. Observe the ReviewStatusBar, file row, and grouping.
- **Expected Result**: The ReviewStatusBar shows the checked state (filled green checkmark, label "Reviewed"). The file row shows a checkmark. The progress indicator is hidden (single file). Group labels are not shown in single-file mode since the FileBrowser sidebar is not visible with only one file.
- **Edge Cases**:
  - Unmarking the only file: reverts to unreviewed state with no grouping labels visible.

---

#### `TC-crp-reviewed-edge-add-after-all-reviewed`: Adding a file when all are reviewed

- **Type**: E2E
- **Covers**: `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`
- **Preconditions**: 2 files loaded, both reviewed. Progress shows "2/2 reviewed".
- **Steps**:
  1. Add a new file.
  2. Observe the FileBrowser sidebar and progress indicator.
- **Expected Result**: The new file appears in the "TO REVIEW" group (which was previously hidden and now reappears). The progress indicator updates to "2/3 reviewed". The "TO REVIEW" group appears above the "REVIEWED" group.
- **Edge Cases**:
  - The new file is the active file: its ReviewStatusBar should show "Mark as reviewed" (unchecked).

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
  4. Observe the prompt preview (which auto-updates).
- **Expected Result**: Both comments are displayed below line 5 as separate CommentBubbles. The gutter shows one indicator for line 5. Comment count shows "2 comments". In the prompt preview, both comments appear under line 5 in creation order.
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
  3. Observe the prompt preview.
- **Expected Result**: The CommentBubble displays the full text (scrollable within the bubble if needed, or wrapping). The InlineCommentEditor text area should have scrolled when the text exceeded 200px height (per design spec). The prompt preview includes the full comment text. No truncation occurs.
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

### `TC-crp-edge-stale-prompt-indicator`: Prompt auto-updates after comment and preamble changes

- **Type**: Integration
- **Covers**: `AC-crp-generate-prompt-structure`, `AC-crp-edit-comment`, `AC-crp-delete-comment`
- **Preconditions**: A file is loaded. No comments exist yet.
- **Steps**:
  1. Add a comment on line 5 with text "First comment".
  2. Observe the prompt preview panel.
  3. Edit the comment text to "Updated comment".
  4. Observe the prompt preview panel.
  5. Add another comment on line 10 with text "Second comment".
  6. Observe the prompt preview panel.
  7. Delete the comment on line 5.
  8. Observe the prompt preview panel.
  9. Change the preamble text to "Review for readability".
  10. Observe the prompt preview panel.
- **Expected Result**: After each modification (steps 2, 4, 6, 8, 10), the prompt preview immediately updates to reflect the current state. There is no stale indicator. The prompt is always current. Step 2: prompt appears with "First comment" on line 5. Step 4: prompt shows "Updated comment" instead. Step 6: prompt includes both comments. Step 8: prompt shows only the line 10 comment. Step 10: prompt includes the preamble in the Instructions section.
- **Edge Cases**:
  - Rapidly editing a comment multiple times: the prompt preview should settle on the final state without visual glitches or race conditions.

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
  1. Load a file, add a comment (prompt auto-generates), and copy to clipboard in each browser.
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
  1. Load a file, add comments, copy to clipboard, clear the session.
  2. Inspect all network requests made during the entire workflow.
- **Expected Result**: No outbound network requests are made to external services. The only requests are for the application's own static assets (JS bundles, CSS, WASM grammars) served from the same origin.
- **Edge Cases**:
  - Shiki WASM grammar loading: these should be bundled and served from the same origin, not fetched from a CDN.

---

### `TC-crp-multi-file-edge-add-during-edit`: Adding file while editing a comment

- **Type**: Integration
- **Covers**: `FR-crp-multi-file-load`
- **Preconditions**: A file is loaded. The InlineCommentEditor is open.
- **Steps**: Drop a new file onto the application.
- **Expected Result**: The new file is added. The editor closes (the active file switches). The in-progress comment is discarded.

---

### `TC-crp-multi-file-edge-comment-nav-active-file-only`: Comment navigation stays within active file

- **Type**: Integration
- **Covers**: `FR-crp-comment-navigation`, `FR-crp-multi-file-nav`
- **Preconditions**: "utils.ts" has 2 comments, "helpers.ts" has 3 comments. "utils.ts" is active.
- **Steps**: Click Next comment until it wraps.
- **Expected Result**: Navigation cycles through only the 2 comments on "utils.ts". It does not jump to "helpers.ts".

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

7. **Done button and prompt handoff**: Changes to the prompt generation pipeline, clipboard logic, or toolbar layout could break the Done action flow. The Done button's visibility depends on slash command mode detection (`?file=` URL param), so changes to URL handling or the `useFileFromUrl` hook could hide/show the button incorrectly.

8. **Multi-file state isolation**: Changes to multi-file state management could cause comment bleeding between files (comments from file A appearing on file B). Each comment's `fileId` must match the file it was created on.

9. **Prompt builder refactor**: The prompt builder changes from single-file to multi-file. Existing single-file tests must still pass (the multi-file builder should produce identical output when only one file has comments).

10. **FileBrowser sidebar interaction with toolbar**: The FileBrowser sidebar introduces a new layer of navigation. Ensure toolbar actions (Copy, Clear, Done) still reference the correct aggregated state across all files, not just the active file.

11. **Review context display**: The context panel is a new UI element overlaid on the existing CRPG layout. Changes to the layout, sidebar, toolbar, or FileBrowser sidebar could cause the context panel to overlap or be hidden. The context panel must coexist with the existing code viewer, comment bubbles, and prompt preview without layout conflicts.

12. **Context data handoff mechanism**: The mechanism for receiving context data (URL parameters, file-based, API) must be backward-compatible. When no context data is provided (standalone mode, `/shepherd` single file), the CRPG must work exactly as before -- no empty context panels, no errors, no layout shifts.

13. **Dark mode and context**: The context panel introduces new color tokens (blue for neutral, violet for review). Dark mode must provide appropriate dark-mode variants of these colors. Changes to the dark mode implementation could cause the context panel to render with light-mode colors or insufficient contrast.

14. **File review tracking and FileBrowser sidebar grouping**: The file review tracking feature adds grouping ("TO REVIEW" / "REVIEWED") to the FileBrowser sidebar and a progress indicator to the FileBrowser sidebar header. Changes to FileBrowser sidebar rendering, file ordering, or file addition/removal logic could break the grouping display or cause reviewed status to be lost. The reviewed status must survive file switches but not page reloads. Changes to the clear session flow must also reset all reviewed statuses. The reviewed status is orthogonal to comments -- changes to comment add/edit/delete logic must not affect the reviewed flag.

### Recommended regression suite

Run the following test cases as a minimum regression suite before any release:

- `TC-crp-load-upload-happy` (file loading works)
- `TC-crp-add-comment-single-line-happy` (comment creation works)
- `TC-crp-edit-comment-happy` (comment editing works)
- `TC-crp-delete-comment-happy` (comment deletion works)
- `TC-crp-generate-prompt-structure-happy` (prompt structure is correct)
- `TC-crp-copy-clipboard-happy` (clipboard copy works)
- `TC-crp-preview-matches-copy-exact` (preview matches clipboard)
- `TC-crp-clear-confirmation-confirm-clears` (session clear works)
- `TC-crp-keyboard-add-comment-happy` (keyboard accessibility works)
- `TC-crp-large-file-scroll-no-jank` (performance holds)
- `TC-crp-binary-file-rejected-upload` (error handling works)
- `TC-crp-done-happy` (Done action sends prompt and confirms)
- `TC-crp-done-hidden-standalone` (Done hidden in standalone mode)
- `TC-crp-done-fallback-clipboard` (fallback works on server failure)
- `TC-crp-multi-file-load-second` (multi-file loading works)
- `TC-crp-multi-file-switch-preserves-comments` (state isolation works)
- `TC-crp-multi-file-prompt-structure-happy` (combined prompt is correct)
- `TC-crp-multi-file-remove-last-empty-state` (cleanup works)
- `TC-crp-context-graceful-missing` (no context panel in standalone mode)
- `TC-crp-context-overall-visible` (overall context displayed with context data)
- `TC-crp-context-per-file-switches` (per-file context updates on file switch)
- `TC-crp-context-neutral-vs-review` (neutral vs review visual distinction)
- `TC-crp-mark-reviewed-happy` (file reviewed toggle works)
- `TC-crp-reviewed-grouping-display` (reviewed/unreviewed grouping correct)
- `TC-crp-reviewed-progress-updates` (progress indicator tracks correctly)
- `TC-crp-reviewed-survives-tab-switch` (reviewed status persists across file switches)
- `TC-crp-reviewed-clear-session-resets` (clear session resets reviewed statuses)
