# Code Review Prompt Generator — Design Spec

> Based on requirements in `../product/code-review-prompt.md`

## Screen Inventory

This is a single-page application with one primary view that transitions through several states. There are no separate routes or pages.

| View State | Description |
|---|---|
| **Empty State** | No file loaded. Shows drop zone and file loading instructions. |
| **File Loaded State** | File is displayed in the code viewer. User can add, edit, delete comments and generate prompts. |
| **Prompt Preview State** | The generated prompt is displayed in a preview panel alongside the code viewer. |

Within the File Loaded State, the application has several sub-states depending on user activity (editing a comment, selecting a line range, etc.). These are described in detail below.

---

## Application Layout

The application uses a single-page layout with a fixed toolbar at the top and a main content area below it. The main content area is divided into panels depending on the current state.

### Top-Level Layout (1024px+ viewports)

```
+------------------------------------------------------------------+
|  Toolbar                                                          |
+------------------------------------------------------------------+
|                                                                    |
|  Main Content Area                                                 |
|  (contents vary by state — see below)                              |
|                                                                    |
+------------------------------------------------------------------+
```

- **Toolbar**: Fixed to the top of the viewport. Always visible. Height: 56px.
- **Main Content Area**: Fills the remaining viewport height below the toolbar. Uses `calc(100vh - 56px)` with `overflow: hidden` — individual panels scroll independently.

### Main Content Area — Empty State (`AC-crp-empty-state`)

When no file is loaded, the entire main content area is a single drop zone / file loading area.

```
+------------------------------------------------------------------+
|                                                                    |
|                     [Drop Zone / File Loader]                      |
|                                                                    |
+------------------------------------------------------------------+
```

### Main Content Area — File Loaded State

When a file is loaded, the main content area splits into a two-column layout:

```
+----------------------------------------------+-------------------+
|                                               |                   |
|  Code Viewer Panel (flexible width)           |  Sidebar Panel    |
|                                               |  (360px fixed)    |
|                                               |                   |
+----------------------------------------------+-------------------+
```

- **Code Viewer Panel**: Takes remaining width after the sidebar. Contains the code viewer with line numbers, gutter, and inline comments. Scrolls vertically independently.
- **Sidebar Panel**: Fixed width of 360px on the right side. Contains the preamble input and, when generated, the prompt preview. Scrolls vertically independently.

### Main Content Area — Prompt Preview Active

The layout remains the same two-column structure. The sidebar panel switches from showing only the preamble input to showing both the preamble input (collapsed to a summary line) and the prompt preview below it.

```
+----------------------------------------------+-------------------+
|                                               | Preamble (summary)|
|  Code Viewer Panel                            |-------------------|
|                                               |                   |
|                                               | Prompt Preview    |
|                                               | (scrollable)      |
|                                               |                   |
+----------------------------------------------+-------------------+
```

---

## Screen Definitions

### Empty State Screen

- **Purpose**: Guide the user to load a file so they can begin annotating. Implements `AC-crp-empty-state`.
- **Entry points**: Initial page load; after clearing a session (`FR-crp-clear-session`).

#### Layout

The entire main content area is a single centered drop zone.

#### Components

- **FileDropZone** (see Component Specs below): Dominates the content area. Provides three loading methods per `FR-crp-file-load`.
- **Toolbar**: Visible but with most actions disabled.
  - Generate button: disabled (grayed out, `aria-disabled="true"`). Tooltip: "Load a file to get started."
  - Copy button: disabled. Tooltip: "Generate a prompt first."
  - Clear button: disabled. Tooltip: "No session to clear."
  - Comment navigation (previous/next): disabled.
  - Comment count: displays "0 comments".

#### States

| State | Trigger | Appearance |
|---|---|---|
| **Default** | Page load / session cleared | Drop zone with dashed border, icon, and instructions |
| **Drag hover** | User drags a file over the zone | Border becomes solid and highlighted (blue, `#2563EB`). Background gets a subtle tint (`#EFF6FF`). Text changes to "Drop file to load". |
| **Loading** | File is being read | Brief spinner centered in the zone. Text: "Reading file..." |
| **Error — binary file** | Binary file detected (`AC-crp-binary-file-rejected`) | Error banner appears inside the drop zone. Red border. Message: "This file doesn't appear to be a text file. Only plain-text files are supported." A "Dismiss" link returns to the default state. |
| **Error — read failure** | File read fails for another reason | Error banner with message: "Failed to read file. Please try again." |

---

### File Loaded Screen

- **Purpose**: Display the loaded file with line numbers, allow the user to add/edit/delete inline comments, write a preamble, and generate the prompt.
- **Entry points**: Successfully loading a file from the Empty State.

#### Layout

Two-column layout as described above: Code Viewer Panel (left, flexible) and Sidebar Panel (right, 360px fixed).

#### Code Viewer Panel

Contains the following from top to bottom:

1. **FileHeader**: A horizontal bar at the top of the code viewer showing the file name (`FR-crp-filename-display`) and detected language. Height: 40px. Background: `#F8FAFC`. Border-bottom: 1px solid `#E2E8F0`.
   - File name displayed in a monospace font, truncated with ellipsis if too long.
   - Language badge: a small pill-shaped label (e.g., "TypeScript", "Python"). If language is unknown, shows "Plain Text".
   - If the file was pasted and no name was provided, shows an inline editable text field with placeholder "Untitled — click to name". File names from upload/drag-and-drop are displayed as read-only text and cannot be renamed.

2. **CodeViewer**: The main scrollable code display area. See Component Specs for full details. Implements `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`.

3. **InlineCommentEditor**: Appears inline within the CodeViewer when the user is creating or editing a comment. See Component Specs.

#### Sidebar Panel

Contains the following from top to bottom:

1. **PreambleInput**: A text area for the prompt preamble (`FR-crp-prompt-preamble`). See Component Specs.
2. **PromptPreview**: Appears below the preamble input after the user generates a prompt (`FR-crp-prompt-preview`). See Component Specs. Before generation, this area shows a placeholder message: "Add comments to the code, then generate a prompt."

#### Toolbar (File Loaded state)

All toolbar items update to their active states:

| Item | State | Behavior |
|---|---|---|
| **Comment count** | Active | Displays "N comments" (e.g., "3 comments"). Updates live as comments are added/deleted. `FR-crp-comment-count` |
| **Previous comment** | Enabled when >= 1 comment exists | Navigates to the previous comment in line order. Wraps from first to last. `FR-crp-comment-navigation` |
| **Next comment** | Enabled when >= 1 comment exists | Navigates to the next comment in line order. Wraps from last to first. `FR-crp-comment-navigation` |
| **Generate** | Enabled when >= 1 comment exists; disabled otherwise (`AC-crp-generate-prompt-no-comments`) | Triggers prompt generation. `FR-crp-prompt-generate` |
| **Copy** | Enabled only after a prompt has been generated | Copies prompt to clipboard. `FR-crp-prompt-copy` |
| **Clear** | Always enabled when a file is loaded | Clears the session. `FR-crp-clear-session` |

#### States

| State | Trigger | Appearance |
|---|---|---|
| **Populated, no comments** | File loaded, zero comments | Code viewer shows file. Sidebar shows empty preamble input and placeholder in preview area. Generate button disabled. |
| **Populated, with comments** | One or more comments exist | Code viewer shows file with comment indicators in the gutter. Generate button enabled. Comment navigation enabled. |
| **Comment editing** | User opens the inline comment editor | InlineCommentEditor is inserted below the target line(s) in the code viewer. Rest of the code is pushed down. |
| **Line range selection** | User is selecting a range of lines (`FR-crp-line-range-comment`) | Selected lines are highlighted with a blue background (`#DBEAFE`). Selection indicator shows "Lines N-M selected". |
| **Prompt generated** | User clicks Generate | Sidebar shows the prompt preview below the preamble. Copy button becomes enabled. |
| **Prompt copied** | User clicks Copy | A toast notification appears: "Copied to clipboard" for 3 seconds. The Copy button briefly changes label to "Copied!" with a checkmark icon, then reverts after 2 seconds. `AC-crp-copy-clipboard` |
| **Large file warning** | File exceeds 10,000 lines (`NFR-crp-large-file-perf`) | A dismissible yellow banner appears at the top of the code viewer: "This file has N lines. Performance may be affected for very large files." Dismissing sets a session-only flag (`largeFileWarningDismissed`). If the user clears and loads another large file, the banner appears again. |

---

## Interaction Flows

### Flow 1: Load File via Paste (`AC-crp-load-paste`)

1. User opens the application and sees the Empty State with the drop zone.
2. User clicks the "Paste content" tab/area within the drop zone.
3. A multi-line text area appears within the drop zone.
4. User pastes or types file content into the text area.
5. An optional text input labeled "File name (optional)" appears below the text area.
6. User clicks "Load" button.
7. Application transitions to File Loaded state: code viewer appears with the pasted content, line numbers starting at 1. If a file name was provided, it appears in the FileHeader. If not, "Untitled" is shown with option to click and name it.
8. Sidebar appears with empty preamble input.

### Flow 2: Load File via Upload (`AC-crp-load-upload`)

1. User opens the application and sees the Empty State.
2. User clicks the "Choose file" button in the drop zone. A native file picker opens.
3. User selects a text file.
4. Application reads the file. Brief loading spinner is shown.
5. If the file is binary, the error state is shown (`AC-crp-binary-file-rejected`). Flow ends.
6. If the file is text, application transitions to File Loaded state. The file name from the filesystem is displayed in the FileHeader.

### Flow 3: Load File via Drag and Drop (`AC-crp-load-drag-drop`)

1. User drags a file from their filesystem over the application window.
2. The drop zone highlights (drag hover state): border turns solid blue, background tints.
3. User drops the file.
4. Application reads the file. Brief loading spinner.
5. Binary check: if binary, show error. If text, transition to File Loaded state with file name from the filesystem.

### Flow 4: Add a Single-Line Comment (`AC-crp-add-comment-single-line`, `FR-crp-line-comment-create`)

1. User hovers over a line in the code viewer. A faint "+" icon appears in the gutter on that line.
2. User clicks the gutter "+" icon (or the line number itself).
3. The InlineCommentEditor opens directly below that line, pushing subsequent lines down.
4. The editor contains a text area (auto-focused) and two buttons: "Comment" (primary) and "Cancel" (secondary).
5. User types their comment text.
6. User clicks "Comment" (or presses `Cmd+Enter` / `Ctrl+Enter` — this shortcut is context-specific and only active when the InlineCommentEditor has focus).
7. The editor closes. A CommentBubble appears below the line showing the comment text. The gutter for that line now shows a comment indicator (blue dot). The toolbar comment count increments by 1.
8. If the user clicks "Cancel" (or presses `Escape`), the editor closes with no comment created.

> **Note on keyboard shortcuts**: `Cmd+Enter` / `Ctrl+Enter` is a **context-specific** shortcut that only operates when the InlineCommentEditor text area has focus. It is not a global shortcut and does not conflict with toolbar shortcuts.

### Flow 5: Add a Line-Range Comment (`AC-crp-add-comment-line-range`, `FR-crp-line-range-comment`)

1. User clicks on a line number in the gutter and holds, then drags to another line number. Alternatively, user clicks a line number, then Shift+clicks another line number.
2. The selected range of lines is highlighted with a blue background. A small floating label appears: "Lines N-M selected".
3. The InlineCommentEditor opens below the last line of the range.
4. User types their comment and clicks "Comment" or presses `Cmd+Enter` / `Ctrl+Enter`.
5. The editor closes. A CommentBubble appears below the range showing the comment text with a label "Lines N-M". The gutter shows comment indicators for every line in the range.
6. To cancel the selection without commenting, the user presses `Escape` or clicks elsewhere in the code viewer.

### Flow 6: Edit a Comment (`AC-crp-edit-comment`, `FR-crp-line-comment-edit`)

1. User sees an existing CommentBubble below a line.
2. User clicks the "Edit" button on the CommentBubble (visible on hover), or double-clicks the comment text.
3. The CommentBubble transforms into the InlineCommentEditor, pre-populated with the existing comment text. The text area is auto-focused with the cursor at the end.
4. User modifies the text.
5. User clicks "Save" (or presses `Cmd+Enter` / `Ctrl+Enter`).
6. The editor reverts to a CommentBubble showing the updated text. The comment remains on the same line(s).
7. If the user clicks "Cancel" or presses `Escape`, the edit is discarded and the original CommentBubble is restored.

### Flow 7: Delete a Comment (`AC-crp-delete-comment`, `FR-crp-line-comment-delete`)

1. User hovers over a CommentBubble. A "Delete" button (trash icon) appears.
2. User clicks "Delete".
3. The CommentBubble is immediately removed (no confirmation dialog for individual comment deletion). The gutter indicator is removed if no other comments remain on that line. The toolbar comment count decrements by 1.
4. If a prompt was previously generated, it is now stale. The prompt preview area shows a subtle "Prompt is outdated. Regenerate to include latest changes." message with a "Regenerate" link.

### Flow 8: Write a Preamble (`FR-crp-prompt-preamble`)

1. In the sidebar, the user sees the PreambleInput text area with placeholder text: "Add high-level instructions for the AI (optional). Example: Refactor this function to use async/await."
2. User clicks the text area and types their preamble.
3. The preamble is stored in application state. No explicit save action is needed.
4. When the prompt is generated, the preamble appears at the top of the output.

### Flow 9: Generate Prompt (`FR-crp-prompt-generate`, `AC-crp-generate-prompt-structure`)

1. User has loaded a file and added at least one comment.
2. User clicks the "Generate" button in the toolbar.
3. The application assembles the prompt per `FR-crp-prompt-format`:
   - Preamble (if provided)
   - File name and detected language
   - Full file content with line numbers
   - "Requested Changes" section with all comments in ascending line order
4. The prompt preview panel in the sidebar populates with the generated prompt text. The preamble input collapses automatically to a single summary line (showing the first ~80 characters of the preamble with "..." if truncated, or "No preamble" in muted text if empty). The user can click the summary to expand and re-edit. The Generate button label changes to "Regenerate".
5. The Copy button in the toolbar becomes enabled.

   **Preamble collapse/expand behavior**: The preamble collapses automatically when the prompt is generated. After expanding to edit, the preamble remains in the user's chosen state (expanded or collapsed) until the user toggles it or regenerates the prompt. Editing the preamble at any time immediately sets `isPromptStale = true`.
6. Prompt generation must complete within 300ms (`NFR-crp-prompt-gen-time`). No loading spinner is shown for this operation since it is expected to be near-instant.

### Flow 10: Copy Prompt to Clipboard (`AC-crp-copy-clipboard`, `AC-crp-preview-matches-copy`)

1. User clicks the "Copy" button in the toolbar (or clicks a "Copy" button at the top of the prompt preview panel).
2. The prompt text is written to the system clipboard via `navigator.clipboard.writeText()`.
3. A toast notification appears at the bottom-center of the viewport: "Copied to clipboard". The toast auto-dismisses after 3 seconds.
4. The Copy button in the toolbar temporarily shows "Copied!" with a checkmark icon for 2 seconds, then reverts to its default label.
5. The text copied to the clipboard is byte-for-byte identical to what is displayed in the prompt preview (`AC-crp-preview-matches-copy`).

### Flow 11: Navigate Between Comments (`FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`)

1. User clicks the "Next" arrow button in the toolbar (or presses the keyboard shortcut `]`).
2. The code viewer scrolls to center the next comment (in ascending line order) in the viewport. The target CommentBubble is highlighted with a brief pulse animation (blue border flash, 300ms).
3. If the user is on the last comment, "Next" wraps to the first comment.
4. "Previous" (`[` key) works identically in reverse order.
5. The currently focused comment is tracked in application state. When a comment is focused, the toolbar shows "Comment N of M" between the previous/next buttons. When no comment has been navigated to yet (`focusedCommentId` is null), the center section shows only the comment count (e.g., "3 comments"). The "Comment N of M" format only appears after the user navigates at least once.

### Flow 12: Clear Session (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`, `FR-crp-clear-session`)

1. User clicks the "Clear" button in the toolbar.
2. **If comments exist** (`AC-crp-clear-confirmation`): A confirmation dialog (modal) appears with:
   - Title: "Clear session?"
   - Body: "This will remove the loaded file, all N comments, and the preamble. This action cannot be undone."
   - Buttons: "Cancel" (secondary, left) and "Clear session" (destructive/red, right).
   - If user clicks "Clear session", the application resets to the Empty State.
   - If user clicks "Cancel" or presses `Escape`, the dialog closes and nothing changes.
3. **If no comments exist** (`AC-crp-clear-no-confirm-empty`): The session clears immediately without a dialog. The application returns to the Empty State.

### Flow 13: Keyboard-Only Comment Creation (`AC-crp-keyboard-add-comment`, `NFR-crp-accessibility-keyboard`)

1. User presses `Tab` to move focus into the code viewer area.
2. User presses `ArrowUp` / `ArrowDown` to navigate between lines. The currently focused line is indicated by a visible focus ring around the line number and a subtle background highlight on the line.
3. User presses `Enter` or `c` on the focused line to open the InlineCommentEditor for that line.
4. User types their comment in the auto-focused text area.
5. User presses `Cmd+Enter` / `Ctrl+Enter` to submit, or `Escape` to cancel.
6. Focus returns to the line in the code viewer after submission or cancellation.

### Flow 14: Keyboard-Only Line Range Selection

1. User navigates to the start line using `ArrowUp` / `ArrowDown`.
2. User holds `Shift` and presses `ArrowDown` to extend the selection downward (or `Shift+ArrowUp` to extend upward).
3. Selected lines are highlighted identically to the mouse-based range selection.
4. User presses `Enter` or `c` to open the InlineCommentEditor for the selected range.
5. Remainder of the flow follows Flow 5.

---

## Component Specs

### FileDropZone

Handles all three file loading methods: paste, upload, and drag-and-drop. Implements `FR-crp-file-load`.

- **Variants**:
  - `default` — Resting state with instructions.
  - `drag-hover` — File is being dragged over the zone.
  - `paste-mode` — User has selected the paste tab and a text area is visible.
  - `loading` — File is being read.
  - `error` — A file loading error occurred.

- **Props/Inputs**:
  - `onFileLoaded: (content: string, fileName?: string, language?: string) => void` — Callback when a file is successfully loaded.
  - `onError: (message: string) => void` — Callback for loading errors.

- **Visual Structure (default variant)**:
  ```
  +-------------------------------------------------------+
  |                                                         |
  |            [Upload icon — 48x48, muted gray]            |
  |                                                         |
  |         Drop a file here, or choose an option:          |
  |                                                         |
  |     [Choose file]   [Paste content]                     |
  |                                                         |
  |       Accepts any plain-text file                       |
  +-------------------------------------------------------+
  ```
  - Outer container: dashed border (`2px dashed #CBD5E1`), rounded corners (`8px`), centered in the content area, max-width 600px, padding 48px.
  - "Choose file" is a secondary button that opens the native file picker.
  - "Paste content" is a secondary button that switches the drop zone interior to paste-mode.

- **Visual Structure (paste-mode variant)**:
  ```
  +-------------------------------------------------------+
  |  File name (optional): [________________]               |
  |  +---------------------------------------------------+ |
  |  |                                                     | |
  |  |  [Paste or type file content here...]               | |
  |  |                                                     | |
  |  +---------------------------------------------------+ |
  |  [Load]  [Back]                                         |
  +-------------------------------------------------------+
  ```
  - Text area: minimum height 200px, monospace font, resizable vertically.
  - File name input: standard text input, placeholder "e.g., utils.ts".
  - "Load" is a primary button (enabled only when text area is non-empty). "Back" returns to the default variant.

- **Behavior**:
  - Drag-and-drop uses the HTML5 Drag and Drop API. The entire component is the drop target.
  - Binary file detection: After reading the file, check for null bytes (`\x00`) in the first 8,192 bytes (or the entire file if shorter than 8,192 bytes). If found, trigger the error state with the message "This file doesn't appear to contain text content. Only plain-text files are supported." (`AC-crp-binary-file-rejected`).
  - Multiple files dropped: When multiple files are dropped simultaneously, load only the first file and show an info toast: "Loaded [filename]. Only one file can be loaded at a time."
  - Language detection: Infer from file extension (`.ts` = TypeScript, `.py` = Python, etc.). If pasted content has no file name or an unrecognized extension, default to "Plain Text" (`FR-crp-syntax-highlight`).
  - Shiki grammar load failure: If the syntax highlighting grammar fails to load for the detected language, the file renders as plain text and an info toast appears: "Syntax highlighting unavailable for this file. Displaying as plain text."

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - `Tab` navigates between "Choose file" and "Paste content" buttons.
  - `Enter` or `Space` activates the focused button.
  - In paste-mode, `Tab` moves between the file name input, text area, "Load" button, and "Back" button.
  - The drop zone itself is not keyboard-operable (drag-and-drop is inherently a pointer interaction), but the "Choose file" button provides the same functionality via keyboard.

---

### Toolbar

The persistent toolbar at the top of the application. Always visible.

- **Variants**: None (single variant; individual items have enabled/disabled states).

- **Props/Inputs**:
  - `commentCount: number` — Total number of comments.
  - `currentCommentIndex: number | null` — Index of the currently focused comment (for navigation display).
  - `hasFile: boolean` — Whether a file is loaded.
  - `hasPrompt: boolean` — Whether a prompt has been generated.
  - `onGenerate: () => void`
  - `onCopy: () => void`
  - `onClear: () => void`
  - `onPrevComment: () => void`
  - `onNextComment: () => void`

- **Visual Structure**:
  ```
  +---[Logo/Title]---[Comment Nav]---[Comment Count]------[Generate][Copy][Clear]---+
  ```
  - Left section: Application title "Code Review Prompt Generator" (or abbreviated to "CRPG" on narrower viewports approaching 1024px).
  - Center section: Comment navigation group — `[< Prev]` `Comment 2 of 5` `[Next >]`. The label shows "No comments" when count is 0.
  - Right section: Action buttons — "Generate" (primary style, blue), "Copy" (secondary style), "Clear" (ghost/text style, red on hover for destructive affordance).

- **States**:

  | Application State | Generate | Copy | Clear | Navigation |
  |---|---|---|---|---|
  | Empty (no file) | Disabled | Disabled | Disabled | Disabled |
  | File loaded, 0 comments | Disabled | Disabled | Enabled | Disabled |
  | File loaded, >= 1 comment, no prompt | Enabled | Disabled | Enabled | Enabled |
  | File loaded, >= 1 comment, prompt generated | Enabled (label: "Regenerate") | Enabled | Enabled | Enabled |

  **Generate/Regenerate label logic**: The button reads "Generate" when `generatedPrompt` is null. After the first prompt generation, the label changes to "Regenerate" (when `generatedPrompt` is not null). If the user clears the session and starts over, the label resets to "Generate".

  **Disabled button tooltips (all states)**:
  - Generate disabled (empty state): "Load a file to get started"
  - Generate disabled (file loaded, 0 comments): "Add at least one comment to generate a prompt"
  - Copy disabled (no prompt generated): "Generate a prompt first"
  - Clear disabled (empty state): "No session to clear"
  - Navigation disabled (0 comments): "No comments to navigate"

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - All buttons are focusable with `Tab`.
  - `Enter` or `Space` activates the focused button.
  - Keyboard shortcuts (displayed in button tooltips):
    - Generate: `Cmd+Shift+G` / `Ctrl+Shift+G`
    - Copy: `Cmd+Shift+C` / `Ctrl+Shift+C`
    - Previous comment: `[`
    - Next comment: `]`
    - Clear: No shortcut (destructive action).

---

### CodeViewer

The core code display component. Implements `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`, `FR-crp-line-range-comment`.

- **Variants**: None (single variant with dynamic rendering based on content and comments).

- **Props/Inputs**:
  - `content: string` — The full file content.
  - `language: string` — The detected language for syntax highlighting.
  - `comments: Comment[]` — Array of comment objects with `{ id, startLine, endLine, text }`.
  - `focusedCommentId: string | null` — The comment currently focused via navigation.
  - `selectedLineRange: { start: number; end: number } | null` — Currently selected range for range commenting.
  - `onLineClick: (lineNumber: number) => void`
  - `onRangeSelect: (start: number, end: number) => void`
  - `onCommentEdit: (commentId: string) => void`
  - `onCommentDelete: (commentId: string) => void`

- **Visual Structure**:
  ```
  +---+----+---------------------------------------------------------+
  | G | LN | Code Content                                             |
  +---+----+---------------------------------------------------------+
  | . |  1 | import React from 'react';                               |
  | . |  2 | import { useState } from 'react';                        |
  | o |  3 | const App = () => {                                      |
  |   |    | +-----------------------------------------------------+  |
  |   |    | | [Comment bubble] Rename this variable          [E][D]|  |
  |   |    | +-----------------------------------------------------+  |
  | . |  4 |   const [count, setCount] = useState(0);                 |
  | . |  5 |   return <div>{count}</div>;                             |
  | . |  6 | };                                                       |
  +---+----+---------------------------------------------------------+
  ```
  - **G (Gutter)**: 28px wide. Shows comment indicators. On lines with comments: a filled blue circle (8px diameter). On the specific line the user is currently hovering over (if that line has no comments): a faint "+" icon (16px, gray `#94A3B8`, centered in the gutter) that invites the user to click and add a comment. The icon disappears when the mouse moves away.
  - **LN (Line Numbers)**: 48px wide (supports up to 5 digits). Right-aligned. Monospace font. Color: `#94A3B8` (muted). Clickable — clicking a line number initiates comment creation.
  - **Code Content**: Remaining width. Monospace font (system monospace stack: `ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace`). Font size: 13px. Line height: 20px. Horizontal scrolling enabled if lines exceed panel width. Syntax highlighted per `FR-crp-syntax-highlight`.
  - **Comment Bubbles**: Rendered inline between code lines, spanning the full width of the code content area. See CommentBubble component. When multiple comments are attached to the same line, they are stacked vertically with 8px vertical margin between each bubble, all rendered below the target line.

- **Overlapping Range Comments**: Overlapping ranges are allowed and each comment is treated independently. When navigating to a comment, only that comment's range is highlighted (yellow background). When clicking on a line covered by multiple range comments, all comment bubbles for that line are visible and stacked vertically.

- **Line Highlighting**:
  - Hovered line: subtle background (`#F8FAFC`).
  - Selected range (`FR-crp-line-range-comment`): blue background (`#DBEAFE`) on all lines in the range.
  - Line associated with focused comment (via navigation): yellow background (`#FEF9C3`) with a brief pulse animation.
  - Keyboard-focused line: visible focus ring (2px blue outline) around the line number.

- **Performance** (`NFR-crp-large-file-perf`, `NFR-crp-render-time`, `AC-crp-large-file-scroll`):
  - The code viewer must use **virtualized rendering** for files over 500 lines. Only lines in and near the viewport are rendered to the DOM. This is a design constraint that engineering must implement.
  - The initial text with line numbers must be visible within 500ms for files under 1,000 lines. Syntax highlighting may apply progressively — for large files (>500 lines), text appears immediately in monochrome and syntax colors "paint in" shortly after. No loading indicator is shown for this progressive highlighting as it is expected to be near-instant after the first paint.

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`, `AC-crp-keyboard-add-comment`):
  - The code viewer is a focusable region (`tabindex="0"`, `role="grid"` or `role="listbox"`).
  - `ArrowUp` / `ArrowDown` moves focus between lines.
  - `Enter` or `c` on a focused line opens the comment editor for that line (creates a new comment, even if the line already has comments — to edit an existing comment, focus the CommentBubble and use its Edit button).
  - `focusedLine` (keyboard navigation within code lines) is independent of `focusedCommentId` (comment navigation via toolbar). They track different concepts.
  - `Shift+ArrowDown` / `Shift+ArrowUp` extends a line range selection.
  - `Escape` clears a range selection.
  - Screen reader: Each line is announced as "Line N: [code content]". Lines with comments append "has N comments".

---

### CommentBubble

Displays an existing comment attached to a line or range of lines. Implements `FR-crp-line-comment-create` (display after creation), `FR-crp-line-comment-edit`, `FR-crp-line-comment-delete`, `FR-crp-comment-indicator`.

- **Variants**:
  - `default` — Displays comment text with action buttons on hover.
  - `focused` — Highlighted via comment navigation. Shows a blue left border and subtle background.

- **Props/Inputs**:
  - `comment: { id: string; startLine: number; endLine: number; text: string }`
  - `isFocused: boolean`
  - `onEdit: (commentId: string) => void`
  - `onDelete: (commentId: string) => void`

- **Visual Structure**:
  ```
  +--------------------------------------------------------------+
  | Lines 10-15                              [Edit] [Delete]      |
  | Extract this to a helper function                             |
  +--------------------------------------------------------------+
  ```
  - Container: full width of the code content column. Background: `#F0F9FF` (light blue). Left border: 3px solid `#3B82F6` (blue). Padding: 8px 12px. Margin: 4px 0. Rounded corners: 4px.
  - Line label: "Line N" for single-line comments, "Lines N-M" for ranges. Font size: 11px. Color: `#64748B`. Font weight: semi-bold.
  - Comment text: Font size: 13px. Color: `#1E293B`. Preserves line breaks via `white-space: pre-wrap`. Multiline comments display with visible line breaks between paragraphs.
  - Edit and Delete buttons: Icon buttons (pencil and trash icons, 16px). Visible only on hover (or when focused via keyboard). On mobile-width (if applicable in future), always visible.
  - Focused variant: Background changes to `#DBEAFE`. Left border widens to 4px.

- **Keyboard Accessibility**:
  - The comment bubble is focusable (`tabindex="0"`).
  - `Tab` within a focused bubble cycles through Edit and Delete buttons.
  - `Enter` on Edit opens the inline editor. `Enter` on Delete removes the comment.
  - `Escape` returns focus to the code viewer on the associated line.

---

### InlineCommentEditor

The input form for creating or editing a comment. Appears inline within the code viewer below the target line(s). Implements `FR-crp-line-comment-create`, `FR-crp-line-comment-edit`.

- **Variants**:
  - `create` — Creating a new comment. Submit button reads "Comment".
  - `edit` — Editing an existing comment. Submit button reads "Save". Text area pre-populated.

- **Props/Inputs**:
  - `variant: 'create' | 'edit'`
  - `initialText: string` — Empty string for create, existing comment text for edit.
  - `lineLabel: string` — "Line N" or "Lines N-M".
  - `onSubmit: (text: string) => void`
  - `onCancel: () => void`

- **Visual Structure**:
  ```
  +--------------------------------------------------------------+
  | Line 5                                                        |
  | +----------------------------------------------------------+ |
  | |                                                            | |
  | | [Add your comment here...]                                 | |
  | |                                                            | |
  | +----------------------------------------------------------+ |
  | [Comment]  [Cancel]              Cmd+Enter to submit          |
  +--------------------------------------------------------------+
  ```
  - Container: full width of the code content column. Background: `#FFFFFF`. Border: 1px solid `#3B82F6` (blue). Padding: 12px. Margin: 4px 0. Rounded corners: 4px. Box shadow: `0 2px 8px rgba(0,0,0,0.1)`.
  - Line label: same styling as CommentBubble line label.
  - Text area: minimum height 60px, auto-grows with content up to 200px, then scrolls. Monospace font. Placeholder: "Add your comment here..." (create) or empty (edit).
  - "Comment"/"Save" button: primary style (blue background, white text). Disabled when text area is empty.
  - "Cancel" button: secondary style (gray text, no background).
  - Shortcut hint: "Cmd+Enter to submit" (or "Ctrl+Enter") in 11px muted text, right-aligned on the button row.

- **Behavior**:
  - Auto-focuses the text area on mount.
  - `Cmd+Enter` / `Ctrl+Enter` submits if text is non-empty.
  - `Escape` cancels and closes the editor.
  - On submit, fires `onSubmit` callback. On cancel, fires `onCancel`.

- **Keyboard Accessibility**:
  - Text area receives focus automatically.
  - `Cmd+Enter` / `Ctrl+Enter` submits the comment (context-specific shortcut, only active when the editor has focus — not a global shortcut).
  - `Tab` moves from text area to "Comment"/"Save" button to "Cancel" button.
  - `Shift+Tab` moves in reverse.
  - `Escape` from anywhere in the editor cancels.

---

### PreambleInput

Text area for the optional prompt preamble. Implements `FR-crp-prompt-preamble`.

- **Variants**:
  - `expanded` — Full text area visible and editable (default when no prompt has been generated).
  - `collapsed` — Shows a single-line summary of the preamble. Used after prompt generation to save space for the preview.

- **Props/Inputs**:
  - `value: string`
  - `onChange: (value: string) => void`
  - `isCollapsed: boolean`
  - `onToggleCollapse: () => void`

- **Visual Structure (expanded)**:
  ```
  Preamble (optional)
  +----------------------------------------------------------+
  |                                                            |
  |  [Add high-level instructions for the AI (optional)...]    |
  |                                                            |
  +----------------------------------------------------------+
  ```
  - Label: "Preamble (optional)" in 13px semi-bold, color `#475569`.
  - Text area: min-height 80px, max-height 200px (then scrolls). Standard font (not monospace). Placeholder as shown.
  - Bottom margin: 16px separating it from the preview area below.

- **Visual Structure (collapsed)**:
  ```
  +----------------------------------------------------------+
  | [v] Preamble: "Refactor this function to use asy..."      |
  +----------------------------------------------------------+
  ```
  - Single line. Clickable to expand. Chevron icon indicates collapse state. Shows truncated preamble text (or "No preamble" in muted text if empty). Background: `#F8FAFC`. Padding: 8px 12px.

---

### PromptPreview

Read-only display of the generated prompt. Implements `FR-crp-prompt-preview`, `FR-crp-prompt-format`.

- **Variants**:
  - `empty` — No prompt generated yet. Shows placeholder message.
  - `populated` — Displays the generated prompt.
  - `stale` — A prompt was generated but comments have changed since. Shows a stale indicator.

- **Props/Inputs**:
  - `promptText: string | null` — The generated prompt text. Null if not yet generated.
  - `isStale: boolean` — True if comments or preamble have changed since last generation.
  - `onRegenerate: () => void`
  - `onCopy: () => void`

- **Visual Structure (empty variant)**:
  ```
  Prompt Preview
  +----------------------------------------------------------+
  |                                                            |
  |  Add comments to the code, then click Generate             |
  |  to create your AI prompt.                                 |
  |                                                            |
  +----------------------------------------------------------+
  ```
  - Centered muted text. Border: 1px dashed `#CBD5E1`.

- **Visual Structure (populated variant)**:
  ```
  Prompt Preview                                [Copy]
  +----------------------------------------------------------+
  |  ## Instructions                                          |
  |  Refactor this function to use async/await                |
  |                                                           |
  |  ## File: utils.ts (TypeScript)                           |
  |                                                           |
  |  ```                                                      |
  |  1 | import React from 'react';                           |
  |  2 | import { useState } from 'react';                    |
  |  ...                                                      |
  |  ```                                                      |
  |                                                           |
  |  ## Requested Changes                                     |
  |  - **Line 3**: Rename this variable                       |
  |  - **Lines 10-15**: Extract this to a helper function     |
  |  - **Line 25**: Add error handling here                   |
  +----------------------------------------------------------+
  ```
  - Header row: "Prompt Preview" label (13px semi-bold) with a "Copy" button (small, secondary style) right-aligned.
  - Content area: monospace font, 12px. Background: `#1E293B` (dark). Text: `#E2E8F0` (light). Padding: 16px. Scrollable vertically. This uses a "dark terminal" theme to visually distinguish the output from the editing areas.
  - The content is rendered inside a `<pre>` element as a text node — no markdown processing is applied. The user sees the literal markdown syntax markers (e.g., `## Instructions`, `**Line 3**`) as plain text. This is intentional: these markers are part of the prompt structure and will be interpreted by the AI agent, not by the application's preview.

- **Visual Structure (stale variant)**:
  - Same as populated, but with a yellow banner at the top of the preview:
    ```
    [!] Prompt is outdated. [Regenerate]
    ```
    Background: `#FEF3C7`. Text: `#92400E`. "Regenerate" is a text link.

---

### ConfirmationDialog

Modal dialog used for the clear session confirmation. Implements `AC-crp-clear-confirmation`.

- **Props/Inputs**:
  - `title: string`
  - `body: string`
  - `confirmLabel: string`
  - `confirmVariant: 'destructive' | 'primary'`
  - `onConfirm: () => void`
  - `onCancel: () => void`

- **Visual Structure**:
  ```
  +-----------------------------------------------+
  |  Clear session?                          [X]   |
  |                                                 |
  |  This will remove the loaded file, all 5        |
  |  comments, and the preamble. This action        |
  |  cannot be undone.                              |
  |                                                 |
  |                        [Cancel] [Clear session] |
  +-----------------------------------------------+
  ```
  - Overlay: semi-transparent black (`rgba(0,0,0,0.5)`).
  - Dialog: white background, rounded corners (8px), max-width 440px, centered vertically and horizontally. Box shadow: `0 4px 24px rgba(0,0,0,0.2)`. Padding: 24px.
  - Title: 18px semi-bold.
  - Body: 14px, color `#475569`.
  - "Cancel": secondary button.
  - "Clear session": destructive button (red background `#DC2626`, white text).
  - Close button [X]: top-right, same as Cancel behavior.

- **Keyboard Accessibility**:
  - Focus is trapped inside the dialog while open.
  - `Escape` triggers cancel.
  - `Tab` cycles between Cancel and the confirm button. Auto-focus on Cancel (the safe option).

---

### ToastNotification

Ephemeral notification for the clipboard copy confirmation. Implements `AC-crp-copy-clipboard`.

- **Props/Inputs**:
  - `message: string`
  - `duration: number` — Auto-dismiss time in milliseconds (default: 3000).

- **Visual Structure**:
  ```
  +-------------------------------------------+
  |  [checkmark icon]  Copied to clipboard     |
  +-------------------------------------------+
  ```
  - Positioned at the bottom-center of the viewport, 24px from the bottom edge.
  - Background: `#1E293B` (dark). Text: `#FFFFFF`. Rounded corners: 8px. Padding: 12px 20px. Box shadow.
  - Entry animation: slide up and fade in (200ms). Exit animation: fade out (200ms).
  - `role="status"` and `aria-live="polite"` for screen reader announcement.

- **Variants**:
  - `success` — Green checkmark icon. Background: `#1E293B` (dark). Used for "Copied to clipboard".
  - `error` — Warning triangle icon. Background: `#991B1B` (dark red). Text: `#FFFFFF`. Used for error messages such as "Failed to copy. Try selecting the text manually." or "Syntax highlighting unavailable for this file. Displaying as plain text."
  - `info` — Info icon. Background: `#1E293B`. Used for informational messages such as "Loaded [filename]. Only one file can be loaded at a time." (when multiple files are dropped).

---

## Prompt Output Format

The generated prompt follows this exact structure (`FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`):

```
## Instructions

[Preamble text, if provided. This entire section is omitted if no preamble was entered.]

## File: [filename] ([language])

```
  1 | [first line of code]
  2 | [second line of code]
  ...
  N | [last line of code]
```

## Requested Changes

- **Line 3**: [comment text]
- **Lines 10-15**: [comment text]
- **Line 25**: [comment text]
```

Rules:
- Line numbers in the code block are left-padded (right-aligned) to align (e.g., `  1 |`, ` 10 |`, `100 |`).
- Comments are listed in ascending line order.
- For line-range comments, the format is "Lines N-M" (not "Line N to M" or other variations). When a range comment has `startLine == endLine` (single-line range), the format is "Line N" (singular), not "Lines N-N".
- If no preamble is provided, the "Instructions" section is omitted entirely (not left empty). A preamble consisting only of whitespace is treated as empty.
- If the file name is unknown, use "Untitled" as the filename.
- If the language is unknown, use "Plain Text".

---

## Responsive Behavior

Implements `NFR-crp-responsive-layout`.

### Breakpoints

| Breakpoint | Behavior |
|---|---|
| **>= 1280px** | Full layout as described. Sidebar: 360px. |
| **1024px - 1279px** | Sidebar narrows to 300px. Toolbar title abbreviates. Font sizes remain the same. |
| **< 1024px** | A full-screen overlay message appears: "This application is designed for viewports 1024px and wider. Please resize your browser window or use a device with a larger screen." The application content is hidden behind the overlay. |

### Panel Resizing

The boundary between the code viewer panel and the sidebar panel is **not** user-resizable in v1. The sidebar has a fixed width and the code viewer takes the remaining space.

### Horizontal Overflow

The code viewer handles long lines by enabling horizontal scrolling within the code content area. The gutter and line numbers remain fixed (sticky) while the code content scrolls horizontally.

---

## Accessibility

### Keyboard Navigation (`NFR-crp-accessibility-keyboard`)

All core workflows are achievable via keyboard:

| Workflow | Keyboard Path |
|---|---|
| **Load file (upload)** | `Tab` to "Choose file" button, `Enter` to open picker |
| **Load file (paste)** | `Tab` to "Paste content" button, `Enter`, then `Tab` to text area, type/paste, `Tab` to "Load", `Enter` |
| **Navigate to a line** | `Tab` to code viewer, `ArrowUp`/`ArrowDown` |
| **Add comment on a line** | Focus line, press `Enter` or `c`, type comment, `Cmd+Enter` to submit |
| **Add comment on a range** | Focus start line, `Shift+ArrowDown` to select range, `Enter` to open editor |
| **Edit a comment** | `Tab` to comment bubble, `Enter` to focus Edit button, `Enter` |
| **Delete a comment** | `Tab` to comment bubble, `Tab` to Delete button, `Enter` |
| **Navigate comments** | `[` for previous, `]` for next |
| **Generate prompt** | `Cmd+Shift+G` / `Ctrl+Shift+G` |
| **Copy prompt** | `Cmd+Shift+C` / `Ctrl+Shift+C` |
| **Clear session** | `Tab` to Clear button, `Enter` |

### Focus Management

- When the InlineCommentEditor opens, focus moves to the text area.
- When the InlineCommentEditor closes (submit or cancel), focus returns to the line in the code viewer.
- When a modal dialog opens, focus is trapped inside it. On close, focus returns to the triggering button.
- Comment navigation (`[` and `]`) moves focus to the navigated CommentBubble.

### ARIA Attributes

| Element | ARIA |
|---|---|
| Code viewer | `role="grid"`, `aria-label="Code viewer"` |
| Each line row | `role="row"` |
| Line number cell | `role="rowheader"` |
| Code content cell | `role="gridcell"` |
| Comment bubble | `role="note"`, `aria-label="Comment on line N: [text]"` |
| Gutter indicator | `aria-hidden="true"` (decorative; the comment bubble provides the accessible label) |
| Toolbar buttons | `aria-label` describing the action, `aria-disabled` when disabled |
| Confirmation dialog | `role="alertdialog"`, `aria-labelledby` pointing to the title, `aria-describedby` pointing to the body |
| Toast | `role="status"`, `aria-live="polite"` |
| Prompt preview | `role="region"`, `aria-label="Generated prompt preview"` |
| Drop zone | `role="region"`, `aria-label="File loading area"` |

### Color and Contrast

- All text meets WCAG 2.1 AA contrast ratios (minimum 4.5:1 for normal text, 3:1 for large text).
- Comment indicators in the gutter use both color (blue dot) and shape (filled circle) to avoid reliance on color alone.
- The focused line uses both a background color change and a visible focus ring.
- Error states use both red coloring and an icon (warning triangle) plus descriptive text.
- The prompt preview's dark theme provides strong contrast for readability.

---

## Color Palette

| Usage | Color | Hex |
|---|---|---|
| Primary / interactive | Blue | `#2563EB` |
| Primary hover | Darker blue | `#1D4ED8` |
| Comment bubble background | Light blue | `#F0F9FF` |
| Comment bubble border | Blue | `#3B82F6` |
| Selected line range | Pale blue | `#DBEAFE` |
| Focused comment highlight | Pale yellow | `#FEF9C3` |
| Destructive action | Red | `#DC2626` |
| Destructive hover | Darker red | `#B91C1C` |
| Stale warning background | Pale yellow | `#FEF3C7` |
| Stale warning text | Dark amber | `#92400E` |
| Error background | Pale red | `#FEF2F2` |
| Error text | Dark red | `#991B1B` |
| Toolbar background | White | `#FFFFFF` |
| Toolbar border | Light gray | `#E2E8F0` |
| Code viewer background | White | `#FFFFFF` |
| Line number text | Muted | `#94A3B8` |
| Prompt preview background | Dark | `#1E293B` |
| Prompt preview text | Light | `#E2E8F0` |
| Body text | Dark slate | `#1E293B` |
| Secondary text | Slate | `#475569` |
| Muted text | Light slate | `#94A3B8` |
| Borders | Light gray | `#E2E8F0` |
| Drop zone border | Dashed gray | `#CBD5E1` |
| Hover background | Very light | `#F8FAFC` |
| Page background | Off-white | `#F1F5F9` |

---

## Typography

| Element | Font | Size | Weight | Line Height |
|---|---|---|---|---|
| Application title | System sans-serif | 16px | 600 (semi-bold) | 24px |
| Toolbar button labels | System sans-serif | 13px | 500 (medium) | 20px |
| Code content | Monospace stack | 13px | 400 (regular) | 20px |
| Line numbers | Monospace stack | 13px | 400 | 20px |
| Comment text | System sans-serif | 13px | 400 | 20px |
| Comment line label | System sans-serif | 11px | 600 | 16px |
| Section labels | System sans-serif | 13px | 600 | 20px |
| Placeholder text | Same as field | Same | 400 | Same |
| Toast message | System sans-serif | 14px | 500 | 20px |
| Dialog title | System sans-serif | 18px | 600 | 28px |
| Dialog body | System sans-serif | 14px | 400 | 22px |
| Prompt preview text | Monospace stack | 12px | 400 | 18px |

System sans-serif stack: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif`

Monospace stack: `ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace`

---

## Requirement Traceability

This section maps every product requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-crp-file-load` | FileDropZone component; Flows 1, 2, 3 |
| `FR-crp-file-display` | CodeViewer component; File Loaded Screen layout |
| `FR-crp-syntax-highlight` | CodeViewer component (language prop, progressive highlighting); FileDropZone (language detection) |
| `FR-crp-line-comment-create` | InlineCommentEditor component (create variant); Flow 4; CommentBubble |
| `FR-crp-line-comment-edit` | InlineCommentEditor component (edit variant); Flow 6; CommentBubble (Edit action) |
| `FR-crp-line-comment-delete` | CommentBubble component (Delete action); Flow 7 |
| `FR-crp-comment-indicator` | CodeViewer gutter (blue dot indicator); CommentBubble |
| `FR-crp-comment-count` | Toolbar component (comment count display) |
| `FR-crp-prompt-preamble` | PreambleInput component; Flow 8 |
| `FR-crp-prompt-generate` | Toolbar Generate button; Flow 9; Prompt Output Format section |
| `FR-crp-prompt-preview` | PromptPreview component (populated variant) |
| `FR-crp-prompt-copy` | Toolbar Copy button; PromptPreview Copy button; Flow 10; ToastNotification |
| `FR-crp-prompt-format` | Prompt Output Format section; PromptPreview component |
| `FR-crp-clear-session` | Toolbar Clear button; ConfirmationDialog component; Flow 12 |
| `FR-crp-filename-display` | FileHeader within Code Viewer Panel; FileDropZone (paste-mode file name input) |
| `FR-crp-line-range-comment` | CodeViewer (range selection); Flow 5; Flow 14 |
| `FR-crp-comment-navigation` | Toolbar (previous/next buttons); Flow 11 |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-crp-large-file-perf` | CodeViewer performance note (virtualized rendering); File Loaded Screen (large file warning) |
| `NFR-crp-render-time` | CodeViewer performance note (progressive highlighting) |
| `NFR-crp-prompt-gen-time` | Flow 9 (no loading spinner; sub-300ms expectation) |
| `NFR-crp-client-only` | Implicit in all designs — no server calls, no external dependencies in any flow |
| `NFR-crp-browser-support` | Implicit — no browser-specific features are relied upon beyond Clipboard API with fallback |
| `NFR-crp-responsive-layout` | Responsive Behavior section (breakpoints, 1024px minimum, sub-1024 overlay) |
| `NFR-crp-accessibility-keyboard` | Accessibility section; keyboard details in every component spec; Flows 13, 14 |
| `NFR-crp-no-data-persistence` | Implicit — no localStorage, no IndexedDB, no persistence in any flow |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-crp-load-paste` | Flow 1; FileDropZone paste-mode variant |
| `AC-crp-load-upload` | Flow 2; FileDropZone (Choose file button) |
| `AC-crp-load-drag-drop` | Flow 3; FileDropZone drag-hover variant |
| `AC-crp-syntax-highlight-detected` | CodeViewer component (language prop, syntax highlighting) |
| `AC-crp-add-comment-single-line` | Flow 4; InlineCommentEditor create variant; CommentBubble; gutter indicator |
| `AC-crp-add-comment-line-range` | Flow 5; CodeViewer range selection; InlineCommentEditor; CommentBubble line range label |
| `AC-crp-edit-comment` | Flow 6; InlineCommentEditor edit variant |
| `AC-crp-delete-comment` | Flow 7; CommentBubble Delete action |
| `AC-crp-generate-prompt-structure` | Flow 9; Prompt Output Format section |
| `AC-crp-generate-prompt-no-comments` | Toolbar states table (Generate disabled when 0 comments) |
| `AC-crp-copy-clipboard` | Flow 10; ToastNotification component |
| `AC-crp-preview-matches-copy` | Flow 10 (byte-for-byte match note); PromptPreview renders exact text |
| `AC-crp-clear-confirmation` | Flow 12; ConfirmationDialog component |
| `AC-crp-clear-no-confirm-empty` | Flow 12 (immediate clear when no comments) |
| `AC-crp-empty-state` | Empty State Screen definition; FileDropZone; Toolbar disabled states |
| `AC-crp-large-file-scroll` | CodeViewer performance note (virtualized rendering) |
| `AC-crp-comment-navigation-next` | Flow 11; Toolbar navigation buttons |
| `AC-crp-keyboard-add-comment` | Flow 13; CodeViewer keyboard accessibility |
| `AC-crp-binary-file-rejected` | FileDropZone error state; Flows 2, 3 (binary check) |
