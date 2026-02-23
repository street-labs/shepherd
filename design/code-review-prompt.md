# Code Review Prompt Generator — Design Spec

> Based on requirements in `../product/code-review-prompt.md`

## Screen Inventory

This is a single-page application with one primary view that transitions through several states. There are no separate routes or pages.

| View State | Description |
|---|---|
| **Empty State** | No file loaded. Shows drop zone and file loading instructions. |
| **File Loaded State (Single File)** | One file is loaded and displayed in the code viewer. User can add, edit, delete comments. The prompt auto-generates when comments exist. When review context data is available (shepherd-review mode), a collapsible Review Context Panel appears between the FileHeader and the code viewer (`FR-crp-review-context-display`). |
| **File Loaded State (Multi-File)** | Two or more files are loaded. A File Tab Bar appears between the toolbar and the content area, showing all loaded files with comment counts, grouped by review status ("To Review" and "Reviewed" sections with `FR-crp-file-reviewed-grouping`). The active file is displayed in the code viewer. User can switch between files, add/remove files, mark files as reviewed, and annotate each independently. A review progress indicator in the toolbar shows "N/M reviewed" (`FR-crp-file-reviewed-progress`). When review context data is available (shepherd-review mode), a collapsible Review Context Panel appears between the File Tab Bar and the code viewer, showing overall changeset context and per-file context for the active tab (`FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`). Implements `FR-crp-multi-file-load`, `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`. |
| **Prompt Preview State** | The auto-generated prompt is displayed in a preview panel alongside the code viewer. Active whenever >= 1 comment exists on any loaded file. When multiple files have comments, the prompt aggregates all files (`FR-crp-multi-file-prompt`). |

Within the File Loaded State (both single and multi-file), the application has several sub-states depending on user activity (editing a comment, selecting a line range, etc.). These are described in detail below.

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

### Main Content Area — File Loaded State (Single File)

When a single file is loaded, the main content area splits into a two-column layout:

```
+----------------------------------------------+-------------------+
|                                               |                   |
|  Code Viewer Panel (flexible width)           |  Sidebar Panel    |
|                                               |  (360px fixed)    |
|                                               |                   |
+----------------------------------------------+-------------------+
```

When review context data is available (shepherd-review mode), a Review Context Panel appears inside the Code Viewer Panel between the FileHeader and the code viewer:

```
+----------------------------------------------+-------------------+
|  FileHeader                                   |                   |
|  Review Context Panel (collapsible)           |  Sidebar Panel    |
|  Code Viewer (scrollable)                     |  (360px fixed)    |
|                                               |                   |
+----------------------------------------------+-------------------+
```

- **Code Viewer Panel**: Takes remaining width after the sidebar. Contains the FileHeader, the Review Context Panel (when context data is available, `FR-crp-review-context-display`), the code viewer with line numbers, gutter, and inline comments. Scrolls vertically independently.
- **Sidebar Panel**: Fixed width of 360px on the right side. Contains the preamble input and the prompt preview (auto-populated when comments exist). Scrolls vertically independently.
- **Review Context Panel**: Conditionally visible only when review context data is available (`AC-crp-context-graceful-missing`). See ReviewContextPanel component spec for details.

### Main Content Area — File Loaded State (Multi-File)

When two or more files are loaded, a **File Tab Bar** appears between the toolbar and the two-column content area. Implements `FR-crp-multi-file-nav`.

```
+------------------------------------------------------------------+
|  Toolbar                                                          |
+------------------------------------------------------------------+
|  File Tab Bar                                                     |
+----------------------------------------------+-------------------+
|                                               |                   |
|  Code Viewer Panel (flexible width)           |  Sidebar Panel    |
|                                               |  (360px fixed)    |
|                                               |                   |
+----------------------------------------------+-------------------+
```

When review context data is available (shepherd-review mode), a Review Context Panel appears inside the Code Viewer Panel between the File Tab Bar and the code viewer:

```
+------------------------------------------------------------------+
|  Toolbar                                                          |
+------------------------------------------------------------------+
|  File Tab Bar                                                     |
+----------------------------------------------+-------------------+
|  Review Context Panel (collapsible)           |                   |
|  Code Viewer (scrollable)                     |  Sidebar Panel    |
|                                               |  (360px fixed)    |
|                                               |                   |
+----------------------------------------------+-------------------+
```

- **File Tab Bar**: Full width, 40px height. Shows a tab for each loaded file plus an "Add file" button. See FileTabBar component spec for details. The tab bar replaces the FileHeader — file name and language info are shown in the active tab (with full details in a tooltip on hover).
- **Review Context Panel**: Conditionally visible only when review context data is available (`AC-crp-context-graceful-missing`). Displays overall changeset context and per-file context for the active tab. The per-file context updates when tabs are switched (`AC-crp-context-per-file-switches`). See ReviewContextPanel component spec for details.
- **Code Viewer Panel**: Same as single-file layout, but the FileHeader is no longer rendered (its information is in the tab bar). The code viewer displays the content of the currently active file.
- **Sidebar Panel**: Same as single-file layout. The prompt preview aggregates comments across all files.

> **Note**: The File Tab Bar also appears when a single file is loaded if additional files were previously loaded and then removed — i.e., the tab bar appears as soon as the second file is loaded and remains visible until only one file remains, at which point it collapses back to the single-file layout with the FileHeader.

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
  - Copy button: disabled. Tooltip: "Load a file to get started."
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

- **Purpose**: Display the loaded file(s) with line numbers, allow the user to add/edit/delete inline comments, write a preamble, and view the auto-generated prompt. When multiple files are loaded, provide tab-based navigation between them (`FR-crp-multi-file-nav`).
- **Entry points**: Successfully loading a file from the Empty State; loading an additional file via the "+" button in the File Tab Bar.

#### Layout

**Single file**: Two-column layout as described above: Code Viewer Panel (left, flexible) and Sidebar Panel (right, 360px fixed).

**Multiple files**: File Tab Bar above the two-column layout. See "Main Content Area -- File Loaded State (Multi-File)" in the Application Layout section.

#### Code Viewer Panel

Contains the following from top to bottom:

1. **FileHeader** (single-file mode only): A horizontal bar at the top of the code viewer showing the file name (`FR-crp-filename-display`) and detected language. Height: 40px. Background: `#F8FAFC`. Border-bottom: 1px solid `#E2E8F0`.
   - File name displayed in a monospace font, truncated with ellipsis if too long.
   - Language badge: a small pill-shaped label (e.g., "TypeScript", "Python"). If language is unknown, shows "Plain Text".
   - If the file was pasted and no name was provided, shows an inline editable text field with placeholder "Untitled -- click to name". File names from upload/drag-and-drop are displayed as read-only text and cannot be renamed.
   - **In multi-file mode**, the FileHeader is not rendered. File name, language badge, and rename affordance (for pasted files) move into the File Tab Bar. Hovering over a tab shows a tooltip with the full file name and language. Right-clicking a tab for a pasted file opens the rename input inline.

2. **ReviewContextPanel** (conditional): Visible only when review context data is available (`FR-crp-review-context-receive`). Positioned between the FileHeader (or the top of the Code Viewer Panel in multi-file mode) and the CodeViewer. Shows overall changeset context and per-file context for the active file. Collapsible to maximize code viewing space. See ReviewContextPanel component spec for full details. When no context data is available (standalone mode, single `/shepherd`), this component is not rendered at all (`AC-crp-context-graceful-missing`).

3. **ReviewStatusBar** (file-reviewed feature): A compact horizontal bar at the top of the code viewer area (below the ReviewContextPanel if present, or below the FileHeader / tab bar). Shows the reviewed state of the active file with a toggle button. Implements `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`. See ReviewStatusBar component spec for full details.

4. **CodeViewer**: The main scrollable code display area. See Component Specs for full details. Implements `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`. In multi-file mode, the CodeViewer displays the content of the currently active file only. When the user switches tabs, the CodeViewer swaps to the new file's content, restoring that file's scroll position and rendering its comments.

5. **InlineCommentEditor**: Appears inline within the CodeViewer when the user is creating or editing a comment. See Component Specs.

#### Sidebar Panel

Contains the following from top to bottom:

1. **PreambleInput**: A text area for the prompt preamble (`FR-crp-prompt-preamble`). See Component Specs.
2. **PromptPreview**: Appears below the preamble input once comments exist (`FR-crp-prompt-preview`). See Component Specs. Before any comments are added, this area shows a placeholder message: "Add comments to the code to generate your AI prompt."

#### Toolbar (File Loaded state)

All toolbar items update to their active states:

| Item | State | Behavior |
|---|---|---|
| **Comment count** | Active | Displays "N comments" (e.g., "3 comments"). Updates live as comments are added/deleted. `FR-crp-comment-count` |
| **Previous comment** | Enabled when >= 1 comment exists | Navigates to the previous comment in line order. Wraps from first to last. `FR-crp-comment-navigation` |
| **Next comment** | Enabled when >= 1 comment exists | Navigates to the next comment in line order. Wraps from last to first. `FR-crp-comment-navigation` |
| **Done** | Only rendered in slash command mode. Enabled when >= 1 comment exists | Sends generated prompt to the agent via POST and copies to clipboard. `FR-crp-done-action`, `FR-crp-prompt-handoff` |
| **Copy** | Enabled when >= 1 comment exists. Primary style when not in slash command mode; secondary/outlined style when Done is visible | Copies prompt to clipboard. `FR-crp-prompt-copy` |
| **Clear** | Always enabled when a file is loaded | Clears the session. `FR-crp-clear-session` |

#### States

| State | Trigger | Appearance |
|---|---|---|
| **Populated, no comments** | File(s) loaded, zero comments on any file | Code viewer shows the active file. Sidebar shows empty preamble input and placeholder message in preview area. |
| **Populated, with comments** | One or more comments exist on any loaded file | Code viewer shows the active file with comment indicators in the gutter. Prompt preview updates automatically (aggregating all files with comments). Comment navigation enabled. Copy button enabled. In multi-file mode, the File Tab Bar shows per-file comment count badges. |
| **Comment editing** | User opens the inline comment editor | InlineCommentEditor is inserted below the target line(s) in the code viewer. Rest of the code is pushed down. |
| **Line range selection** | User is selecting a range of lines (`FR-crp-line-range-comment`) | Selected lines are highlighted with a blue background (`#DBEAFE`). Selection indicator shows "Lines N-M selected". |
| **Prompt copied** | User clicks Copy | A toast notification appears: "Copied to clipboard" for 3 seconds. The Copy button briefly changes label to "Copied!" with a checkmark icon, then reverts after 2 seconds. `AC-crp-copy-clipboard` |
| **Prompt sent (auto-close)** | User clicks Done in app-mode window (`AC-crp-done-auto-close`) | Done button transitions: "Done" -> "Sending..." (with spinner). On success, `window.close()` is called and the window closes. The user never sees the "Sent" state because the window is gone. |
| **Prompt sent (fallback)** | User clicks Done but `window.close()` fails (not app-mode) (`AC-crp-done-confirmation`) | Done button transitions: "Done" -> "Sending..." (with spinner) -> "Sent" (green checkmark, disabled). A toast notification appears: "Prompt sent to agent! Switch back to your terminal." The "Sent" state persists until the user modifies comments or preamble, at which point the button resets to "Done". |
| **Prompt send failed** | Done POST request fails (`AC-crp-done-fallback-clipboard`) | Done button reverts from "Sending..." to "Done". A toast notification appears: "Could not send to agent. Prompt copied to clipboard -- paste it manually." The prompt is still available on the clipboard. |
| **Large file warning** | File exceeds 10,000 lines (`NFR-crp-large-file-perf`) | A dismissible yellow banner appears at the top of the code viewer: "This file has N lines. Performance may be affected for very large files." Dismissing sets a per-file session flag. If a different large file is activated, its warning is independent. |
| **Multi-file: file switching** | User clicks a different tab in the File Tab Bar (`FR-crp-multi-file-nav`) | The code viewer transitions to the newly active file. The previous file's state (comments, scroll position, reviewed status) is preserved in memory. The new file's scroll position is restored. The active tab indicator updates. The ReviewStatusBar updates to reflect the new file's reviewed state. `AC-crp-multi-file-nav-preserves-state`, `AC-crp-file-reviewed-survives-tab-switch` |
| **Multi-file: file removal** | User closes a tab (`FR-crp-multi-file-remove`) | The tab disappears. If the removed file was active, the adjacent tab becomes active (see Flow 19). If no files remain, the application returns to the Empty State. `AC-crp-multi-file-empty-after-remove-last` |
| **Multi-file: add file overlay** | User clicks "+" in the File Tab Bar | The FileDropZone appears as a centered modal overlay over the code viewer area. The existing file remains visible behind the backdrop. On successful load, the overlay closes and the new file's tab appears. See Flow 17. |
| **Multi-file: drag-over add** | User drags file(s) over the application while files are loaded | A drop overlay appears over the code viewer: "Drop to add file(s)" with a highlighted dashed border (`#2563EB`). On drop, files are added to the session. See Flow 20. |

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

### Flow 3: Load File via Drag and Drop (`AC-crp-load-drag-drop`, `AC-crp-multi-file-drop-multiple`)

1. User drags one or more files from their filesystem over the application window.
2. The drop zone highlights (drag hover state): border turns solid blue, background tints.
3. User drops the file(s).
4. Application reads each file. Brief loading spinner.
5. Binary check per file: binary files are rejected with an error toast per file. Valid text files are loaded.
6. **Single file dropped**: Transition to File Loaded state with file name from the filesystem.
7. **Multiple files dropped** (`AC-crp-multi-file-drop-multiple`): All valid text files are loaded into the session. An info toast confirms: "Loaded N files." The last loaded file becomes the active file. If this is the first load (empty state), the File Tab Bar appears as soon as the second file is added.

> **Note**: When files are already loaded and the user drags additional files over the application, see Flow 20 instead.

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
4. The prompt preview automatically updates to reflect the removal. If no comments remain, the prompt preview reverts to the placeholder message and the Copy button becomes disabled.

### Flow 8: Write a Preamble (`FR-crp-prompt-preamble`)

1. In the sidebar, the user sees the PreambleInput text area with placeholder text: "Add high-level instructions for the AI (optional). Example: Refactor this function to use async/await."
2. User clicks the text area and types their preamble.
3. The preamble is stored in application state. No explicit save action is needed.
4. If comments exist, the prompt automatically regenerates to include the updated preamble. The preamble appears at the top of the output.

### Flow 9: Automatic Prompt Generation (`FR-crp-prompt-generate`, `AC-crp-generate-prompt-structure`)

1. The prompt is automatically generated (and regenerated) whenever any of the following occur: a comment is added, a comment is edited, a comment is deleted, or the preamble text changes. There is no manual Generate button.
2. As soon as the first comment is added, the application assembles the prompt per `FR-crp-prompt-format`:
   - Preamble (if provided)
   - File name and detected language
   - Full file content with line numbers
   - "Requested Changes" section with all comments in ascending line order
3. The prompt preview panel in the sidebar populates with the generated prompt text. The prompt preview always reflects the current state of comments and preamble — there is no stale prompt concept.
4. The preamble input collapses automatically to a single summary line when the first comment is added (showing the first ~80 characters of the preamble with "..." if truncated, or "No preamble" in muted text if empty). The user can click the summary to expand and re-edit.
5. The Copy button in the toolbar becomes enabled as soon as any comment exists.

   **Preamble collapse/expand behavior**: The preamble collapses automatically when the first comment is added. After expanding to edit, the preamble remains in the user's chosen state (expanded or collapsed) until the user toggles it. Editing the preamble triggers an automatic prompt regeneration.
6. If all comments are deleted, the prompt preview reverts to the placeholder message and the Copy button becomes disabled.
7. Prompt generation must complete within 300ms (`NFR-crp-prompt-gen-time`). No loading spinner is shown for this operation since it is expected to be near-instant.

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

### Flow 12: Clear Session (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`, `FR-crp-clear-session`, `AC-crp-multi-file-clear-all`)

1. User clicks the "Clear" button in the toolbar.
2. **If comments exist on any file** (`AC-crp-clear-confirmation`): A confirmation dialog (modal) appears with:
   - Title: "Clear session?"
   - Body (single file): "This will remove the loaded file, all N comments, and the preamble. This action cannot be undone."
   - Body (multi-file): "This will remove all M loaded files, all N comments, and the preamble. This action cannot be undone." (`AC-crp-multi-file-clear-all`)
   - Buttons: "Cancel" (secondary, left) and "Clear session" (destructive/red, right).
   - If user clicks "Clear session", ALL loaded files, ALL comments across all files, the preamble, and all reviewed statuses are removed (`AC-crp-file-reviewed-clear-session`). The application resets to the Empty State. The File Tab Bar disappears. The review progress indicator disappears.
   - If user clicks "Cancel" or presses `Escape`, the dialog closes and nothing changes.
3. **If no comments exist on any file** (`AC-crp-clear-no-confirm-empty`): The session clears immediately without a dialog. All loaded files are removed. The application returns to the Empty State.

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

### Flow 15: Done -- Send Prompt to Agent (`FR-crp-done-action`, `FR-crp-prompt-handoff`, `AC-crp-done-sends-prompt`, `AC-crp-done-auto-close`, `AC-crp-done-confirmation`)

> This flow applies only in slash command mode (see "Slash Command Mode Detection" below).

1. User finishes annotating lines in the code viewer. At least one inline comment exists.
2. User clicks the "Done" button in the toolbar (positioned to the left of Copy).
3. The Done button transitions to its "Sending..." state: the label changes to "Sending..." and a spinner icon replaces the checkmark icon.
4. Two operations execute in parallel:
   a. A POST request is sent to `/api/prompt-output` with the generated prompt text as the request body (Content-Type: `text/plain; charset=utf-8`).
   b. The generated prompt is copied to the system clipboard via `navigator.clipboard.writeText()`.
5. On POST success (200 response):
   a. The prompt is on the clipboard (from step 4b).
   b. The CRPG calls `window.close()` (`AC-crp-done-auto-close`). This is the **primary success path**.
   c. **If the window closes** (app-mode): Done. The user is back at the terminal -- the last active window before the CRPG opened. The agent has received the prompt via the file watcher (see `design/slash-command.md`, Flow 10).
   d. **If the window does NOT close** (not in app-mode, or browser security restrictions prevent it): Fall back to the confirmation UI. The Done button transitions to its "Sent" state: label changes to "Sent" with a green checkmark icon. The button becomes disabled (no further clicks). A toast notification appears (success variant): "Prompt sent to agent! Switch back to your terminal." Auto-dismisses after 5 seconds (longer than the standard 3 seconds, since the user needs to read the instruction).
6. If the fallback confirmation UI is shown (step 5d), the user manually switches back to their terminal.
7. If the user returns to the CRPG and modifies any comment (add, edit, delete) or changes the preamble, the Done button resets from "Sent" to its normal "Done" state, ready to send again.

### Flow 16: Done -- Error Fallback (`AC-crp-done-fallback-clipboard`)

1. User clicks the "Done" button in the toolbar.
2. The Done button transitions to its "Sending..." state.
3. The POST request to `/api/prompt-output` fails (network error, server not running, non-200 response).
4. The clipboard write may have succeeded or failed independently. If it succeeded, the prompt is on the clipboard.
5. The Done button reverts to its normal "Done" state (not "Sent", since the handoff failed).
6. A toast notification appears (warning variant): "Could not send to agent. Prompt copied to clipboard -- paste it manually." Auto-dismisses after 5 seconds.
7. The user can retry by clicking "Done" again, or manually paste the prompt into their terminal.

#### Slash Command Mode Detection

The CRPG determines whether it is in slash command mode based on how the file was loaded:

- **Slash command mode = true**: The file was loaded via a `?file=` URL parameter (i.e., the `useFileFromUrl` hook successfully fetched a file from the server API). This means the local server is running and the agent is waiting for the prompt.
- **Slash command mode = false**: The file was loaded via paste, upload, or drag-and-drop (normal standalone usage). No local server is assumed.

When not in slash command mode, the Done button is not rendered at all (`AC-crp-done-standalone-hidden`). The Copy button retains its primary styling and remains the sole action for getting the prompt out of the app.

The mode is tracked as a boolean flag in application state (e.g., `isSlashCommandMode`), set to `true` when `useFileFromUrl` successfully loads a file, and `false` otherwise. Clearing the session (via the Clear button) resets this flag to `false`, returning the app to standalone mode.

### Flow 17: Load Additional Files — Multi-File (`FR-crp-multi-file-load`, `AC-crp-multi-file-load-adds`)

1. User has one or more files loaded and visible in the code viewer. The File Tab Bar is visible (if two or more files) or appears as the second file is added.
2. User clicks the "+" button in the File Tab Bar.
3. The FileDropZone appears as a centered modal overlay with a semi-transparent backdrop, overlaying the code viewer and sidebar. The existing file content is dimmed behind the overlay.
4. User loads a file via paste, upload, or drag-and-drop (same mechanisms as Flows 1-3).
5. On success, the modal closes. A new tab appears in the File Tab Bar (appended to the end, before the "+" button). The new file becomes the active tab and its content is displayed in the code viewer.
6. The previous file's full state (comments, scroll position, line selections) is preserved in memory and will be restored when the user switches back to that tab.
7. If this is the second file being loaded (first time going from one file to two), the File Tab Bar appears for the first time, and the FileHeader in the code viewer is replaced by the tab bar. The first file's tab is also present in the bar.

### Flow 18: Switch Between Files (`FR-crp-multi-file-nav`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-context-per-file-switches`)

1. User sees multiple tabs in the File Tab Bar. One tab is active (highlighted with the bottom border).
2. User clicks on an inactive tab (or focuses the tab bar with keyboard, uses `ArrowLeft`/`ArrowRight` to reach it, and presses `Enter` or `Space`).
3. The code viewer transitions to display the selected file's content. The transition is instant (no loading spinner) since all file content is held in memory.
4. All comments for the selected file are rendered in the code viewer. The scroll position is restored to where the user last was in that file.
5. The previously active tab retains its full state (comments, scroll position, any in-progress line range selection is discarded). If the user had an InlineCommentEditor open on the previous file, it is closed without saving (same as pressing Escape).
6. If the Review Context Panel is visible (`FR-crp-review-context-display`), the per-file context section updates to show the newly active file's context (`AC-crp-context-per-file-switches`). If the newly active file has no per-file context (e.g., it was added via paste/upload and was not part of the shepherd-review invocation), the per-file section is hidden; only the overall context remains visible. The overall changeset context is unaffected by tab switches (`FR-crp-review-context-overall`). The Review Context Panel's collapse/expand state is preserved across tab switches — it does not reset.
7. The prompt preview in the sidebar continues to reflect all comments across all files — it does not change when switching tabs (unless comments were modified).
8. Comment navigation (`[` and `]` keys, toolbar next/prev) operates across all files. If the next comment is in a different file, switching to that comment automatically activates the corresponding file's tab.

### Flow 19: Remove a File (`FR-crp-multi-file-remove`, `AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments`, `AC-crp-multi-file-empty-after-remove-last`)

1. User hovers over a tab in the File Tab Bar, revealing the close (X) button on that tab.
2. User clicks the X button.
3. **If the file has comments** (`AC-crp-multi-file-remove-with-comments`): A confirmation dialog appears:
   - Title: "Remove file?"
   - Body: "Remove \"[filename]\"? This will remove the file and its N comments. This cannot be undone."
   - Buttons: "Cancel" (secondary) / "Remove" (destructive/red).
   - If user clicks "Remove", proceed to step 5. If "Cancel", the dialog closes and nothing changes.
4. **If the file has no comments** (`AC-crp-multi-file-remove-no-comments`): The file is removed immediately without a confirmation dialog. Proceed to step 5.
5. The tab disappears from the File Tab Bar. The file, all its comments, and its reviewed status are removed from the session (`FR-crp-file-reviewed-persistence`). The review progress indicator updates immediately (e.g., if the removed file was reviewed, the reviewed count decrements; the total count also decrements).
6. If the removed file was the active tab:
   - If other files remain: The tab to the right becomes active (or the tab to the left if the rightmost tab was removed). The code viewer switches to the newly active file.
   - If no files remain (`AC-crp-multi-file-empty-after-remove-last`): The application returns to the Empty State. The File Tab Bar disappears.
7. If the removed file was not the active tab: The active tab remains unchanged. The tab bar adjusts to fill the gap.
8. The toolbar comment count updates to reflect the new total across all remaining files. The prompt preview regenerates, omitting the removed file's section. If no comments remain on any file, the prompt preview reverts to the placeholder.
9. If only one file remains after removal, the File Tab Bar collapses and the layout reverts to the single-file layout with the FileHeader restored.

### Flow 20: Drag-and-Drop Additional Files (`FR-crp-multi-file-load`, `AC-crp-multi-file-drop-multiple`)

1. While one or more files are already loaded, user drags one or more files from the filesystem over the application window.
2. A drop overlay appears over the code viewer area: semi-transparent backdrop with a centered message "Drop to add file(s)" and a highlighted dashed border (`2px dashed #2563EB`, background tint `#EFF6FF`). The File Tab Bar and sidebar remain visible but are behind the overlay.
3. User drops the files.
4. Each dropped file undergoes binary detection independently:
   - Valid text files are added as new tabs, appended in the order they appear in the drop event's file list.
   - Binary files are rejected individually. An error toast appears per rejected file (e.g., "image.png is not a text file and was skipped.").
5. An info toast confirms the result: "Loaded N files." (or "Loaded N files. M files were skipped." if some were binary).
6. The last successfully loaded file becomes the active tab. Its content is displayed in the code viewer.
7. If the user was previously in single-file mode, the File Tab Bar appears for the first time.

### Flow 21: Mark a File as Reviewed (`FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-reviewed-with-comments`)

There are three ways to mark a file as reviewed:

**Via the ReviewStatusBar (primary mechanism):**

1. User is viewing a file in the code viewer. The ReviewStatusBar is visible below the ReviewContextPanel (or at the top of the code viewer area if no context panel). The bar shows a checkbox and the text "Mark as reviewed".
2. User clicks the "Mark as reviewed" button (or the checkbox).
3. The ReviewStatusBar transitions: the checkbox fills with a green checkmark, the text changes to "Reviewed", and the bar's background subtly shifts to a pale green tint (`#F0FDF4`; dark mode: `#052E16`) for 300ms, then settles to a neutral reviewed appearance.
4. The file's tab in the File Tab Bar immediately updates: a green checkmark icon appears before the file name, and if the tab is inactive, its text color mutes.
5. The file's tab smoothly animates (150ms ease-out CSS transition on `transform` and `opacity`) from the "To Review" group to the "Reviewed" group. If this is the first reviewed file, the "REVIEWED" group label and divider appear simultaneously.
6. The review progress indicator in the toolbar updates immediately (e.g., "2/7 reviewed" becomes "3/7 reviewed"). `AC-crp-file-reviewed-progress-count`
7. The file remains active in the code viewer — the user does not lose their place. The user can continue reading, adding comments, or navigating. `AC-crp-file-reviewed-with-comments`

**Via the tab bar review toggle button:**

1. User hovers over a tab (or the tab is active), revealing the review toggle button (circle icon) after the comment badge.
2. User clicks the review toggle button.
3. The tab immediately updates with the reviewed visual treatment (green checkmark, muted text if inactive).
4. The tab moves to the "Reviewed" group with the same animation as above.
5. The ReviewStatusBar (if visible for this file) updates to show the "Reviewed" state.
6. The progress indicator updates.
7. This mechanism works without switching to the file — the user can mark other files as reviewed while remaining on the current file. `FR-crp-file-reviewed-toggle`

**Via keyboard shortcut:**

1. User presses `Cmd+Shift+R` / `Ctrl+Shift+R` (global shortcut) or `r` (when a tab is focused in the tab bar).
2. The active file's reviewed state toggles. All visual updates are identical to the ReviewStatusBar mechanism.
3. A brief toast-style screen reader announcement: "[filename] marked as reviewed" or "[filename] unmarked".

### Flow 22: Unmark a Reviewed File (`AC-crp-file-unmark-reviewed`)

1. User sees a file in the "Reviewed" state (either viewing it or seeing it in the tab bar).
2. User clicks the ReviewStatusBar "Reviewed" checkbox/button, clicks the tab's review toggle button, or presses the keyboard shortcut.
3. The ReviewStatusBar transitions: the checkbox empties, the text changes back to "Mark as reviewed", the pale green tint fades out.
4. The file's tab updates: the green checkmark disappears, text color returns to normal.
5. The tab animates from the "Reviewed" group back to the "To Review" group, maintaining its original load-order position within the group. If the "Reviewed" group is now empty, the group label and divider disappear.
6. The progress indicator decrements (e.g., "3/7 reviewed" becomes "2/7 reviewed").

### Flow 23: Tab Grouping Transition on Review Status Change (`FR-crp-file-reviewed-grouping`)

When a file's reviewed status changes, the tab must visually move between groups:

1. **Mark as reviewed**: The tab fades slightly (opacity 0.5, 100ms), slides horizontally toward the "Reviewed" group (150ms ease-out), and fades back in (opacity 1.0, 100ms) in its new position. The surrounding tabs in both groups adjust their positions smoothly (150ms CSS transition on `transform`).
2. **Unmark as reviewed**: The reverse animation. The tab fades, slides back to its load-order position in the "To Review" group, and fades in.
3. **Group label appearance**: When the first file enters a group (either "To Review" or "Reviewed"), the group label fades in (opacity 0 to 1, 150ms). When the last file leaves a group, the label fades out. The divider follows the same pattern.
4. **Edge case — all reviewed**: When the last unreviewed file is marked as reviewed, the "TO REVIEW" label and divider disappear. Only the "REVIEWED" label remains with all tabs. The progress indicator text turns green.
5. **Edge case — all unreviewed**: When the last reviewed file is unmarked, the "REVIEWED" label disappears. Group labels are hidden entirely (the default state with no labels is cleaner).

---

## Component Specs

### FileDropZone

Handles all three file loading methods: paste, upload, and drag-and-drop. Implements `FR-crp-file-load`, `FR-crp-multi-file-load`.

- **Variants**:
  - `default` — Resting state with instructions. Used in the empty state (full content area).
  - `drag-hover` — File is being dragged over the zone.
  - `paste-mode` — User has selected the paste tab and a text area is visible.
  - `loading` — File is being read.
  - `error` — A file loading error occurred.
  - `modal` — Used when adding a file to an existing session (triggered by the "+" button in the File Tab Bar). Same content as `default` but rendered as a centered modal overlay.

- **Props/Inputs**:
  - `onFileLoaded: (content: string, fileName?: string, language?: string) => void` — Callback when a file is successfully loaded. In multi-file mode, called once per file loaded.
  - `onFilesLoaded: (files: Array<{ content: string; fileName: string; language?: string }>) => void` — Callback when multiple files are loaded simultaneously (multi-drop). Each file triggers independent binary detection and language inference.
  - `onError: (message: string) => void` — Callback for loading errors.
  - `onClose: () => void` — Callback to close the modal variant. Only relevant in `modal` variant.
  - `variant: 'full' | 'modal'` — Whether the drop zone fills the content area (empty state) or appears as a modal (add file to session).

- **Visual Structure (default variant — full)**:
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
  - "Choose file" is a secondary button that opens the native file picker. In multi-file mode, the file picker allows multiple file selection (`multiple` attribute).
  - "Paste content" is a secondary button that switches the drop zone interior to paste-mode.

- **Visual Structure (modal variant)**:
  ```
  +===========================================================+
  |  [backdrop — semi-transparent black rgba(0,0,0,0.5)]       |
  |                                                             |
  |     +-----------------------------------------------+      |
  |     |  Add File                                [X]  |      |
  |     |                                                |      |
  |     |       [Upload icon — 48x48, muted gray]        |      |
  |     |                                                |      |
  |     |    Drop a file here, or choose an option:      |      |
  |     |                                                |      |
  |     |    [Choose file]   [Paste content]              |      |
  |     |                                                |      |
  |     |      Accepts any plain-text file               |      |
  |     +-----------------------------------------------+      |
  |                                                             |
  +===========================================================+
  ```
  - Overlay: semi-transparent black backdrop (`rgba(0,0,0,0.5)`).
  - Dialog: white background, rounded corners (`8px`), max-width 600px, centered vertically and horizontally. Box shadow: `0 4px 24px rgba(0,0,0,0.2)`. Padding: 24px.
  - Title: "Add File" in 18px semi-bold.
  - Close button [X]: top-right, closes the modal without loading a file.
  - Interior content is identical to the `default` variant (same paste-mode, same drag-hover behavior).
  - `Escape` closes the modal.

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
  - **Multiple files dropped** (`AC-crp-multi-file-drop-multiple`): When multiple files are dropped simultaneously, ALL files are loaded into the session. Each file undergoes independent binary detection. Binary files are rejected individually with an error toast per file (e.g., "image.png is not a text file and was skipped."). Valid text files are all loaded. An info toast confirms: "Loaded N files." (or "Loaded N files. M files were skipped." if some were binary).
  - **Dropping files while files are already loaded**: The entire application window acts as a drop target when files are loaded. Dropping files anywhere on the window (not just the FileDropZone) adds them to the session. See Flow 20.
  - Language detection: Infer from file extension (`.ts` = TypeScript, `.py` = Python, etc.). If pasted content has no file name or an unrecognized extension, default to "Plain Text" (`FR-crp-syntax-highlight`).
  - Shiki grammar load failure: If the syntax highlighting grammar fails to load for the detected language, the file renders as plain text and an info toast appears: "Syntax highlighting unavailable for this file. Displaying as plain text."

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - `Tab` navigates between "Choose file" and "Paste content" buttons.
  - `Enter` or `Space` activates the focused button.
  - In paste-mode, `Tab` moves between the file name input, text area, "Load" button, and "Back" button.
  - The drop zone itself is not keyboard-operable (drag-and-drop is inherently a pointer interaction), but the "Choose file" button provides the same functionality via keyboard.
  - In modal variant, focus is trapped inside the modal. `Escape` closes the modal.

---

### FileTabBar

Horizontal tab bar showing all loaded files in the session, grouped by review status. Implements `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`. Only rendered when two or more files are loaded (see layout section for transition rules).

- **Position**: Below the toolbar, above the code viewer and sidebar. Full width of the viewport. Min-height: 40px (may expand if group labels are present). Background: `#F8FAFC`. Border-bottom: 1px solid `#E2E8F0`.

- **Props/Inputs**:
  - `files: FileTab[]` where `FileTab = { id: string; name: string; language: string; commentCount: number; isReviewed: boolean }`
  - `activeFileId: string`
  - `onSelectFile: (fileId: string) => void`
  - `onRemoveFile: (fileId: string) => void`
  - `onAddFile: () => void`
  - `onToggleReviewed: (fileId: string) => void`

- **Visual Structure (with grouping, `FR-crp-file-reviewed-grouping`)**:

  When at least one file is in each group (both "To Review" and "Reviewed" are non-empty):
  ```
  +---TO REVIEW---[utils.ts (3)]---[helpers.ts]---|---REVIEWED---[✓ config.json (1)]---[✓ app.ts]---[+]---+
  ```

  When all files are unreviewed (no "Reviewed" group label needed):
  ```
  +---[utils.ts (3)]---[helpers.ts]---[config.json (1)]---[+]-------------+
  ```

  When all files are reviewed (no "To Review" group needed):
  ```
  +---REVIEWED---[✓ utils.ts (3)]---[✓ helpers.ts]---[✓ config.json (1)]---[+]---+
  ```

  - **Group labels**: Inline labels "TO REVIEW" and "REVIEWED" appear before each group's tabs. Style: 10px semi-bold (600), uppercase, letter-spacing `0.05em`, color `#94A3B8`, padding 0 8px, vertically centered in the tab bar. Group labels are only shown when both groups are non-empty, or when all files are in the "Reviewed" group (to make the reviewed state obvious). When all files are unreviewed, group labels are omitted since this is the default state and the labels would add visual noise without informational value.
  - **Group divider**: A thin vertical separator (1px solid `#CBD5E1`, height 20px, vertically centered) appears between the last "To Review" tab and the "REVIEWED" label. Only rendered when both groups have at least one file.
  - **Dark mode group labels**: Color `#64748B`. Divider: 1px solid `#3F4451`.

  Within each group, files maintain their original load order (`FR-crp-file-reviewed-grouping`).

  - Each loaded file gets a tab showing:
    - **Reviewed indicator** (`FR-crp-file-reviewed-visual`): When `isReviewed` is true, a green checkmark icon (12px, color `#16A34A`) appears before the file name with 4px right margin. The icon is always visible (not hover-gated) so the reviewed state is obvious at a glance.
      - Dark mode: Checkmark color `#4ADE80` (green-400).
    - **File name**: Truncated with ellipsis if > 20 characters. Monospace font, 13px. When the file is reviewed and the tab is inactive, the text color is muted to `#94A3B8` (light slate) to further distinguish reviewed files visually.
    - **Comment count badge**: Small pill shown only when `commentCount > 0`. Style: background `#3B82F6`, text white, font-size 10px, border-radius 8px, min-width 16px, height 16px, padding 0 4px. Positioned inline after the file name with 6px left margin.
    - **Review toggle button**: A small circle icon button (16px hit target, 12px icon) to the right of the comment count badge (or after the file name if no badge). Visible on hover or when the tab is active. When unreviewed: empty circle outline (color `#94A3B8`); when reviewed: filled green checkmark circle (color `#16A34A`). Clicking this toggles the reviewed state directly from the tab without switching to the file (`FR-crp-file-reviewed-toggle`). `aria-label="Mark [filename] as reviewed"` or `aria-label="Unmark [filename] as reviewed"` depending on state.
    - **Close button (X icon)**: 14px icon. Visible on hover or when the tab is active. Clicking removes the file (`FR-crp-multi-file-remove`). Hidden for the last remaining file (use Clear session instead).
  - **Tooltip on hover**: Shows the full file name, detected language, and review status (e.g., "helpers.ts -- TypeScript" or "config.json -- JSON -- Reviewed"). For pasted files, shows "Untitled -- Plain Text" or the user-given name.

- **Tab States**:

  | State | Background | Text Color | Border | Font Weight | Checkmark |
  |---|---|---|---|---|---|
  | **Active, unreviewed** | `#FFFFFF` (white) | `#1E293B` (dark slate) | border-bottom: 2px solid `#2563EB` | 600 (semi-bold) | None |
  | **Active, reviewed** | `#FFFFFF` (white) | `#1E293B` (dark slate) | border-bottom: 2px solid `#2563EB` | 600 (semi-bold) | Green checkmark (`#16A34A`) before name |
  | **Inactive, unreviewed** | transparent | `#64748B` (slate) | none | 400 (regular) | None |
  | **Inactive, reviewed** | transparent | `#94A3B8` (light slate, muted) | none | 400 (regular) | Green checkmark (`#16A34A`) before name |
  | **Inactive, unreviewed (hover)** | `#E2E8F0` | `#475569` | none | 400 | None |
  | **Inactive, reviewed (hover)** | `#E2E8F0` | `#475569` | none | 400 | Green checkmark |

  The reviewed visual treatment is always visible on the tab regardless of hover or focus state (`FR-crp-file-reviewed-visual`). The muted text color for inactive reviewed tabs provides an additional visual cue that the file has been "completed" without requiring hover.

- **Tab Sizing**: Each tab has min-width 120px, max-width 200px, padding 0 12px. Height: 40px (matching the bar). Tabs are left-aligned, laid out horizontally.

- **Overflow / Scrolling**: When total tab widths exceed the available bar width, the bar scrolls horizontally. Subtle fade indicators (8px wide, gradient from `#F8FAFC` to transparent) appear on the left/right edges when content is scrolled. The scroll position persists as tabs are added/removed. Scrolling can be done via horizontal mouse scroll, trackpad gesture, or grabbing and dragging the tab bar.

- **Add File Button**: Always the last element in the tab bar (after all file tabs). Rendered as a "+" icon button: 28x28px, border-radius 6px, background transparent, hover background `#E2E8F0`, icon color `#64748B`, icon size 16px. Clicking opens the FileDropZone as a modal overlay (see Flow 17).

- **Drag-and-Drop Reordering**: Not in v1. Tabs are ordered by load order (the order in which files were added to the session).

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - The tab bar is focusable as a group. `Tab` key moves focus into the tab bar from the toolbar.
  - `ArrowLeft` / `ArrowRight` moves focus between tabs within the bar (traverses across both groups seamlessly — the group labels are not focusable).
  - `Enter` or `Space` activates (selects) the focused tab.
  - `Delete` or `Backspace` on a focused tab removes that file (with confirmation if it has comments, per `FR-crp-multi-file-remove`).
  - `r` on a focused tab toggles the reviewed state for that file (`FR-crp-file-reviewed-toggle`). This key only fires when focus is on a tab element, not when focus is in a text input or comment editor.
  - `Tab` from the last tab moves focus to the "+" button. `Enter` or `Space` on the "+" button opens the add-file modal.
  - `Shift+Tab` from the tab bar moves focus back to the toolbar.

- **ARIA Attributes**:
  - Container: `role="tablist"`, `aria-label="Loaded files"`
  - Each tab: `role="tab"`, `aria-selected="true|false"`, `aria-controls` pointing to the code viewer panel ID. When the file is reviewed, the tab also includes `aria-description="Reviewed"`.
  - Active tab's associated code viewer panel: `role="tabpanel"`, `aria-labelledby` pointing to the active tab's ID
  - Close button within each tab: `aria-label="Remove [filename]"`
  - Review toggle button within each tab: `aria-label="Mark [filename] as reviewed"` (unreviewed) or `aria-label="Unmark [filename] as reviewed"` (reviewed), `aria-pressed="true|false"`
  - Add file button: `aria-label="Add another file"`
  - Group labels: `role="presentation"` (decorative, not interactive)

---

### ReviewStatusBar

A compact horizontal bar that displays the reviewed/unreviewed status of the currently active file and provides the primary mechanism for toggling it. Implements `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`, `FR-crp-file-reviewed-persistence`.

- **Position**: Inside the Code Viewer Panel, below the ReviewContextPanel (if present) or below the FileHeader (single-file mode) / the top of the panel (multi-file mode). Spans the full width of the Code Viewer Panel. Height: 36px. The bar is always visible when at least one file is loaded, regardless of whether context data is available.

- **Props/Inputs**:
  - `isReviewed: boolean` — Whether the currently active file is marked as reviewed.
  - `fileName: string` — Name of the currently active file (used in screen reader announcements).
  - `onToggleReviewed: () => void` — Callback to toggle the active file's reviewed state.

- **Visual Structure (unreviewed)**:
  ```
  +--------------------------------------------------------------+
  | [ ] Mark as reviewed                     Cmd+Shift+R          |
  +--------------------------------------------------------------+
  ```

- **Visual Structure (reviewed)**:
  ```
  +--------------------------------------------------------------+
  | [✓] Reviewed                             Cmd+Shift+R          |
  +--------------------------------------------------------------+
  ```

- **Styling (unreviewed — light mode)**:
  - **Container**: Full width. Height: 36px. Background: `#F8FAFC`. Border-bottom: 1px solid `#E2E8F0`. Padding: 0 16px. Display: flex, align-items center, justify-content space-between.
  - **Checkbox**: 16px square, border: 2px solid `#CBD5E1`, border-radius: 3px, background: white. Cursor: pointer. On hover: border color `#94A3B8`.
  - **Label**: "Mark as reviewed" in 13px regular (400), color `#475569`. Margin-left: 8px from checkbox. Cursor: pointer (clicking the label also toggles).
  - **Shortcut hint**: "Cmd+Shift+R" (or "Ctrl+Shift+R" on non-Mac) in 11px regular, color `#94A3B8`. Right-aligned.
  - **Dark mode**: Background: `#1A1D23`. Border-bottom: 1px solid `#2D3139`. Checkbox border: `#3F4451`. Label: `#A0AABB`. Shortcut hint: `#64748B`.

- **Styling (reviewed — light mode)**:
  - **Container**: Same dimensions. Background: `#F0FDF4` (green-50, subtle). Border-bottom: 1px solid `#BBF7D0` (green-200).
  - **Checkbox**: 16px square, background: `#16A34A` (green), border: none, border-radius: 3px. White checkmark icon (10px) centered inside.
  - **Label**: "Reviewed" in 13px semi-bold (600), color `#15803D` (green-700). Margin-left: 8px.
  - **Shortcut hint**: Same as unreviewed.
  - **Dark mode**: Background: `#052E16` (dark green tint). Border-bottom: 1px solid `#166534`. Checkbox background: `#4ADE80`. Label: `#4ADE80`.

- **Behavior**:
  - Clicking anywhere on the bar (checkbox, label, or background) toggles the reviewed state.
  - The toggle fires `onToggleReviewed`. The parent component handles the state update.
  - The transition between states uses a 150ms CSS transition on background-color and color for a smooth visual shift.
  - In single-file mode, the bar still appears (the toggle is still useful as a personal workflow marker, even though grouping and progress are not shown).

- **Keyboard Accessibility**:
  - The checkbox is focusable (`tabindex="0"`).
  - `Enter` or `Space` toggles the reviewed state.
  - `Tab` from the ReviewContextPanel header (or FileHeader) moves focus to the checkbox. `Tab` from the checkbox moves focus to the code viewer.
  - Screen reader: `role="checkbox"`, `aria-checked="true|false"`, `aria-label="Mark [filename] as reviewed"` or `aria-label="[filename] is reviewed"`.

---

### Toolbar

The persistent toolbar at the top of the application. Always visible.

- **Variants**: None (single variant; individual items have enabled/disabled states).

- **Props/Inputs**:
  - `commentCount: number` — Total number of comments **across all loaded files** (`FR-crp-comment-count`, `AC-crp-multi-file-comment-count`). This is a global aggregate, not per-file.
  - `currentCommentIndex: number | null` — Index of the currently focused comment (for navigation display). When navigating comments across multiple files, the index spans all files in tab order.
  - `hasFile: boolean` — Whether **at least one** file is loaded. True when one or more files exist in the session.
  - `fileCount: number` — Number of loaded files. Used to adjust the clear confirmation message (e.g., "This will remove all 3 loaded files, all 5 comments, and the preamble.").
  - `reviewedCount: number` — Number of files marked as reviewed (`FR-crp-file-reviewed-progress`). Used for the progress indicator.
  - `isSlashCommandMode: boolean` — Whether the CRPG was launched via the slash command. Controls Done button visibility.
  - `doneState: 'idle' | 'sending' | 'sent'` — Current state of the Done button.
  - `onDone: () => void` — Callback when Done is clicked.
  - `onCopy: () => void`
  - `onClear: () => void`
  - `onPrevComment: () => void`
  - `onNextComment: () => void`

- **Visual Structure**:

  When **not** in slash command mode (standalone):
  ```
  +---[Logo/Title]---[Comment Nav]---[Comment Count]---[3/7 reviewed]---[Copy][Clear]---+
  ```

  When in **slash command mode**:
  ```
  +---[Logo/Title]---[Comment Nav]---[Comment Count]---[3/7 reviewed]---[Done][Copy][Clear]---+
  ```

  - Left section: Application title "Code Review Prompt Generator" (or abbreviated to "CRPG" on narrower viewports approaching 1024px).
  - Center section: Comment navigation group — `[< Prev]` `Comment 2 of 5` `[Next >]`. The label shows "No comments" when count is 0.
  - Right section (before action buttons): **Review progress indicator** (`FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-progress-count`). Displays as a compact text badge: "[N]/[M] reviewed" where N = number of reviewed files and M = total loaded files. Only visible when `fileCount >= 2`. Hidden when 0 or 1 files are loaded (single-file sessions have limited utility for a progress indicator). Updates immediately when a file is marked/unmarked, added, or removed. When all files are reviewed, the text turns green (`#16A34A`; dark mode: `#4ADE80`) to signal completion.
    - **Style**: Font-size 12px, font-weight 500 (medium), color `#64748B` (slate; dark mode: `#8B95A5`). Background: `#F1F5F9` (light; dark mode: `#21252B`). Border-radius: 4px. Padding: 2px 8px. Positioned between the comment count and the action buttons with 12px left margin.
    - **Completion style**: When `reviewedCount === fileCount` and `fileCount >= 2`: Text color changes to `#16A34A` (green; dark mode: `#4ADE80`). Background changes to `#F0FDF4` (green-50; dark mode: `#052E16`).
    - **Screen reader**: `aria-label="N of M files reviewed"`, `role="status"`, `aria-live="polite"` so changes are announced.
  - Right section (action buttons): In slash command mode, "Done" (primary/filled style, blue background) appears to the left of "Copy" (secondary/outlined style). In standalone mode, "Done" is not rendered and "Copy" uses primary style. "Clear" always uses ghost/text style, red on hover for destructive affordance.

- **Done Button States** (`FR-crp-done-action`):

  | State | Label | Icon | Style | Clickable |
  |---|---|---|---|---|
  | **idle** | "Done" | Checkmark (`check`) | Primary (filled blue `#2563EB`, white text) | Yes (when >= 1 comment) |
  | **sending** | "Sending..." | Spinner (animated) | Primary (filled blue, white text) | No |
  | **sent** | "Sent" | Green checkmark | Success (filled green `#16A34A`, white text) | No | _(Fallback only -- in app-mode, the window closes via `window.close()` before this state is shown. This state is only visible when auto-close fails.)_ |
  | **disabled** | "Done" | Checkmark (muted) | Primary (reduced opacity 0.5) | No |

  The Done button resets from `sent` to `idle` whenever the user adds, edits, or deletes a comment, or modifies the preamble.

- **States**:

  | Application State | Done (slash command mode) | Copy | Clear | Navigation |
  |---|---|---|---|---|
  | Empty (no file) | Not rendered | Disabled | Disabled | Disabled |
  | File loaded, 0 comments | Disabled | Disabled | Enabled | Disabled |
  | File loaded, >= 1 comment | Enabled (idle) | Enabled | Enabled | Enabled |
  | File loaded, >= 1 comment, NOT slash command mode | Not rendered | Enabled (primary style) | Enabled | Enabled |

  **Disabled button tooltips (all states)**:
  - Done disabled (0 comments): "Add at least one comment"
  - Copy disabled (empty state): "Load a file to get started"
  - Copy disabled (file loaded, 0 comments): "Add at least one comment"
  - Clear disabled (empty state): "No session to clear"
  - Navigation disabled (0 comments): "No comments to navigate"

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - All buttons are focusable with `Tab`.
  - `Enter` or `Space` activates the focused button.
  - Keyboard shortcuts (displayed in button tooltips):
    - Done: `Cmd+Shift+D` / `Ctrl+Shift+D` (only active in slash command mode)
    - Copy: `Cmd+Shift+C` / `Ctrl+Shift+C`
    - Previous comment: `[`
    - Next comment: `]`
    - Mark as reviewed: `Cmd+Shift+R` / `Ctrl+Shift+R` — toggles the reviewed state for the currently active file (`FR-crp-file-reviewed-toggle`). This is a global shortcut that works from anywhere in the application as long as a file is loaded, so the user does not need to switch away from their current context.
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

### ReviewContextPanel

Collapsible panel that displays review context data provided by the shepherd-review command. Implements `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`, `AC-crp-context-neutral-vs-review`, `AC-crp-context-readonly`.

This component is **conditionally rendered** — it only appears when the CRPG receives review context data from the agent (`FR-crp-review-context-receive`). When no context data is available (standalone mode, single `/shepherd`), this component is not rendered at all. There is no empty or placeholder state (`AC-crp-context-graceful-missing`).

- **Position**: Inside the Code Viewer Panel, between the FileHeader (single-file mode) or the top of the panel (multi-file mode, since the FileHeader is replaced by the File Tab Bar) and the CodeViewer. The panel spans the full width of the Code Viewer Panel (does not extend into the Sidebar Panel).

- **Props/Inputs**:
  - `overallContext: { neutral: string; review: string } | null` — Overall changeset context. Both fields may be empty strings.
  - `perFileContext: { neutral: string; review: string } | null` — Per-file context for the currently active file. Null when the active file has no per-file context (e.g., file added via paste/upload, not part of the shepherd-review invocation).
  - `isCollapsed: boolean` — Whether the panel is in its collapsed state.
  - `onToggleCollapse: () => void` — Callback to toggle collapse/expand.
  - `activeFileName: string` — Name of the currently active file (used in the per-file section header).

- **States**:

  | State | Trigger | Appearance |
  |---|---|---|
  | **Expanded (overall + per-file)** | Default when context data is available and the active file has per-file context | Full panel showing both the overall changeset section and per-file section, each with neutral and review sub-sections. |
  | **Expanded (overall only)** | Context data is available but the active file has no per-file context | Panel shows only the overall changeset section. The per-file section is not rendered (no empty placeholder). |
  | **Collapsed** | User has collapsed the panel | Single-line indicator bar showing a collapsed state. |
  | **Absent / Hidden** | No context data available at all (`AC-crp-context-graceful-missing`) | Component is not rendered. No DOM element, no empty space. |

- **Visual Structure (expanded, both sections)**:
  ```
  +--------------------------------------------------------------+
  | [v] Review Context                                            |
  |--------------------------------------------------------------|
  | CHANGESET OVERVIEW                                            |
  |                                                               |
  | [ContextSection: "What Changed" — neutral styling]            |
  | [ContextSection: "Agent Review" — review styling]             |
  |                                                               |
  |--------------------------------------------------------------|
  | FILE: utils.ts                                                |
  |                                                               |
  | [ContextSection: "What Changed" — neutral styling]            |
  | [ContextSection: "Agent Review" — review styling]             |
  +--------------------------------------------------------------+
  ```

- **Visual Structure (collapsed)**:
  ```
  +--------------------------------------------------------------+
  | [>] Review Context                                            |
  +--------------------------------------------------------------+
  ```

- **Styling (expanded)**:
  - **Container**: Full width of the Code Viewer Panel. Background: `#FAFBFC`. Border-bottom: 1px solid `#E2E8F0`. Padding: 0 (internal sections provide their own padding). Max-height: 40% of the Code Viewer Panel height (to prevent the context from consuming too much space). Overflows vertically with scrolling when content exceeds the max-height.
  - **Dark mode**: Background: `#1A1D23`. Border-bottom: 1px solid `#2D3139`.
  - **Header bar**: Height: 36px. Padding: 0 16px. Background: `#F1F5F9`. Border-bottom: 1px solid `#E2E8F0`. Display: flex, align-items center. Cursor: pointer (entire header is the collapse/expand toggle).
    - Chevron icon: 14px, color `#64748B`. Points down when expanded (`v`), right when collapsed (`>`). Rotates with a 150ms CSS transition.
    - Label: "Review Context" in 12px semi-bold (600), color `#475569`, uppercase tracking (`letter-spacing: 0.05em`).
    - Dark mode header: Background: `#21252B`. Border-bottom: 1px solid `#2D3139`. Chevron: `#8B95A5`. Label: `#A0AABB`.
  - **Overall section**: Padding: 12px 16px. Border-bottom: 1px solid `#E2E8F0` (only if per-file section follows).
    - Section label: "CHANGESET OVERVIEW" in 11px semi-bold, color `#64748B`, uppercase, letter-spacing `0.05em`, margin-bottom 8px.
    - Dark mode section label: color `#8B95A5`.
    - Dark mode border-bottom: 1px solid `#2D3139`.
  - **Per-file section**: Padding: 12px 16px. No border-bottom (last section).
    - Section label: "FILE: [filename]" in 11px semi-bold, color `#64748B`, uppercase, letter-spacing `0.05em`, margin-bottom 8px. The filename portion is not uppercased — it uses its original casing.
    - Dark mode section label: color `#8B95A5`.

- **Styling (collapsed)**:
  - **Container**: Full width. Height: 36px. Background: `#F1F5F9`. Border-bottom: 1px solid `#E2E8F0`. Cursor: pointer.
  - Dark mode collapsed: Background: `#21252B`. Border-bottom: 1px solid `#2D3139`.
  - The collapsed state matches the header bar styling from the expanded state. Clicking anywhere on the collapsed bar expands the panel.

- **Collapse/Expand Behavior**:
  - Default state on first load: **expanded**. The user should see the context when the CRPG first opens with review data.
  - Toggle: Clicking the header bar toggles between collapsed and expanded. The expand/collapse is animated with a 200ms CSS transition on `max-height` and `opacity`.
  - **Persistence across tab switches**: The collapse/expand state is maintained when the user switches between file tabs. If the panel is collapsed, it stays collapsed when switching to another file. This is a session-level preference, not per-file.
  - **Reset**: The collapse state resets to expanded if the session is cleared and re-populated with context data.

- **Content Rendering**: Each section (overall and per-file) contains two ContextSection sub-components: one for neutral context ("What Changed") and one for review feedback ("Agent Review"). See the ContextSection component spec below.

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - The header bar is focusable (`tabindex="0"`).
  - `Enter` or `Space` toggles collapse/expand.
  - `Tab` from the header bar moves focus into the panel content (when expanded) or to the next focusable element (when collapsed).
  - Screen reader: The header bar has `aria-expanded="true|false"` and `aria-controls` pointing to the panel content ID.

- **ARIA Attributes**:
  - Header bar: `role="button"`, `aria-expanded="true|false"`, `aria-controls="review-context-content"`.
  - Panel content: `id="review-context-content"`, `role="region"`, `aria-label="Review context"`.
  - Overall section: `role="group"`, `aria-label="Changeset overview"`.
  - Per-file section: `role="group"`, `aria-label="File context for [filename]"`.
  - All text content within the panel: read-only, not editable (`AC-crp-context-readonly`). No `contenteditable`, no input elements for the context text.

---

### ContextSection

A single section within the ReviewContextPanel that displays either neutral context ("What Changed") or review feedback ("Agent Review"). Used twice within each group (overall and per-file) — once for the neutral variant and once for the review variant. Implements `AC-crp-context-neutral-vs-review`, `AC-crp-context-readonly`.

- **Variants**:
  - `neutral` — Displays factual/neutral context ("What Changed"). Uses informational styling.
  - `review` — Displays the agent's review feedback ("Agent Review"). Uses a distinct styling that signals subjective AI content.

- **Props/Inputs**:
  - `variant: 'neutral' | 'review'`
  - `content: string` — The context text to display. May contain multiple paragraphs.
  - `label: string` — The section header ("What Changed" for neutral, "Agent Review" for review).

- **States**:

  | State | Trigger | Appearance |
  |---|---|---|
  | **Visible** | Content string is non-empty | Section is rendered with label and content. |
  | **Hidden** | Content string is empty or undefined | Section is not rendered. No empty placeholder. |

- **Visual Structure (neutral variant — "What Changed")**:
  ```
  +--------------------------------------------------------------+
  |  [info-icon] What Changed                                     |
  |  +---------------------------------------------------------+  |
  |  | Added a new validateInput() function in the utils        |  |
  |  | module. Modified the processData() handler to call       |  |
  |  | validateInput() before processing. Removed the inline    |  |
  |  | validation logic from the handler.                       |  |
  |  +---------------------------------------------------------+  |
  +--------------------------------------------------------------+
  ```

- **Visual Structure (review variant — "Agent Review")**:
  ```
  +--------------------------------------------------------------+
  |  [sparkle-icon] Agent Review                                  |
  |  +---------------------------------------------------------+  |
  |  | The new validation function is a good separation of      |  |
  |  | concerns. However, the error messages are generic —      |  |
  |  | consider adding specific validation failure reasons.     |  |
  |  | The removal of inline validation is clean.               |  |
  |  +---------------------------------------------------------+  |
  +--------------------------------------------------------------+
  ```

- **Styling (neutral variant — light mode)**:
  - **Container**: Margin-bottom: 8px (gap between neutral and review within the same group). Padding: 0.
  - **Header row**: Display flex, align-items center, margin-bottom: 6px.
    - Icon: Info circle icon (`i` in a circle), 14px, color `#3B82F6` (blue-500). Margin-right: 6px.
    - Label: "What Changed" in 12px semi-bold (600), color `#475569`.
  - **Content area**: Background: `#FFFFFF`. Border: 1px solid `#E2E8F0`. Border-left: 3px solid `#3B82F6` (blue-500). Border-radius: 4px. Padding: 10px 12px.
  - **Content text**: Font-size: 13px. Line-height: 20px. Color: `#374151`. Font-family: system sans-serif. White-space: `pre-wrap` (preserves line breaks in the content). The text is read-only — no cursor change, no selection affordance beyond normal text selection for copy.

- **Styling (review variant — light mode)**:
  - **Container**: Margin-bottom: 0 (last within its group, or 8px if followed by more content).
  - **Header row**: Same layout as neutral.
    - Icon: Sparkle/AI icon (a small sparkle or robot head), 14px, color `#7C3AED` (violet-600). Margin-right: 6px.
    - Label: "Agent Review" in 12px semi-bold (600), color `#475569`.
  - **Content area**: Background: `#F5F3FF` (violet-50). Border: 1px solid `#DDD6FE` (violet-200). Border-left: 3px solid `#7C3AED` (violet-600). Border-radius: 4px. Padding: 10px 12px.
  - **Content text**: Same font properties as neutral. Color: `#374151`.

- **Styling (neutral variant — dark mode)**:
  - **Header row**: Icon color: `#60A5FA` (blue-400). Label color: `#A0AABB`.
  - **Content area**: Background: `#1E2028`. Border: 1px solid `#2D3139`. Border-left: 3px solid `#60A5FA` (blue-400).
  - **Content text**: Color: `#D1D5DB`.

- **Styling (review variant — dark mode)**:
  - **Header row**: Icon color: `#A78BFA` (violet-400). Label color: `#A0AABB`.
  - **Content area**: Background: `#1E1B2E` (dark violet tint). Border: 1px solid `#312E4A`. Border-left: 3px solid `#A78BFA` (violet-400).
  - **Content text**: Color: `#D1D5DB`.

- **Content Rendering**:
  - The content is rendered as plain text with `white-space: pre-wrap`. Line breaks in the content string are preserved.
  - No markdown rendering is applied. The content is displayed as-is.
  - The content is read-only. It is rendered in a `<div>` (not an `<input>` or `<textarea>`). Users can select and copy the text via normal browser text selection, but cannot edit it.

- **Visual Distinction Rationale** (`AC-crp-context-neutral-vs-review`):
  The neutral and review variants are distinguishable at a glance through multiple visual cues:
  1. **Left border color**: Blue (neutral) vs violet (review).
  2. **Background color**: White/transparent (neutral) vs faint violet tint (review).
  3. **Icon**: Info circle (neutral) vs sparkle/AI (review).
  4. **Label text**: "What Changed" (neutral) vs "Agent Review" (review).
  These four signals work together so that even users who are color-blind can distinguish the two sections via icon shape and label text.

- **Keyboard Accessibility**:
  - No interactive elements within a ContextSection — content is read-only.
  - Text is selectable via standard browser text selection (for copy-paste).
  - Screen reader: Content area has `role="note"`, `aria-label` set to the label text (e.g., "What Changed" or "Agent Review").

---

### PreambleInput

Text area for the optional prompt preamble. Implements `FR-crp-prompt-preamble`.

- **Variants**:
  - `expanded` — Full text area visible and editable (default when no comments exist).
  - `collapsed` — Shows a single-line summary of the preamble. Used after the first comment is added to save space for the prompt preview.

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

Read-only display of the generated prompt. Implements `FR-crp-prompt-preview`, `FR-crp-prompt-format`, `FR-crp-multi-file-prompt`.

- **Variants**:
  - `empty` — No comments exist on any loaded file. Shows placeholder message.
  - `populated` — Displays the auto-generated prompt. Appears automatically as soon as comments exist on any file. When multiple files have comments, the prompt aggregates all files per `FR-crp-multi-file-prompt-format`.

- **Props/Inputs**:
  - `promptText: string | null` — The generated prompt text. Null when no comments exist on any file. When multiple files have comments, this contains the full multi-file prompt.
  - `onCopy: () => void`

- **Visual Structure (empty variant)**:
  ```
  Prompt Preview
  +----------------------------------------------------------+
  |                                                            |
  |  Add comments to the code to generate your AI prompt.      |
  |                                                            |
  |                                                            |
  +----------------------------------------------------------+
  ```
  - Centered muted text. Border: 1px dashed `#CBD5E1`.

- **Visual Structure (populated variant — single file)**:
  ```
  Prompt Preview                                [Copy]
  +----------------------------------------------------------+
  |  ## Instructions                                          |
  |  Refactor this function to use async/await                |
  |                                                           |
  |  ## File: utils.ts (TypeScript)                           |
  |                                                           |
  |  ### Requested Changes                                    |
  |                                                           |
  |  ```                                                      |
  |  const App = () => {                                      |
  |  ```                                                      |
  |  Rename this variable                                     |
  |                                                           |
  |  ```                                                      |
  |  function processData(input: any) {                       |
  |    // ...complex logic...                                 |
  |  }                                                        |
  |  ```                                                      |
  |  Extract this to a helper function                        |
  +----------------------------------------------------------+
  ```

- **Visual Structure (populated variant — multi-file)**:
  ```
  Prompt Preview                                [Copy]
  +----------------------------------------------------------+
  |  ## Instructions                                          |
  |  Refactor for consistency                                 |
  |                                                           |
  |  ## File: utils.ts (TypeScript)                           |
  |                                                           |
  |  ### Requested Changes                                    |
  |                                                           |
  |  ```                                                      |
  |  const App = () => {                                      |
  |  ```                                                      |
  |  Rename this variable                                     |
  |                                                           |
  |  ## File: helpers.ts (TypeScript)                         |
  |                                                           |
  |  ### Requested Changes                                    |
  |                                                           |
  |  ```                                                      |
  |  export function formatDate(d: Date) {                    |
  |  ```                                                      |
  |  Add error handling here                                  |
  +----------------------------------------------------------+
  ```

  - Header row: "Prompt Preview" label (13px semi-bold) with a "Copy" button (small, secondary style) right-aligned.
  - Content area: monospace font, 12px. Background: `#1E293B` (dark). Text: `#E2E8F0` (light). Padding: 16px. Scrollable vertically. This uses a "dark terminal" theme to visually distinguish the output from the editing areas.
  - The content is rendered inside a `<pre>` element as a text node — no markdown processing is applied. The user sees the literal markdown syntax markers (e.g., `## Instructions`, `## File:`) as plain text. This is intentional: these markers are part of the prompt structure and will be interpreted by the AI agent, not by the application's preview.
  - The preview always shows the full aggregated prompt across all files — it does not filter to the currently active file. This ensures what the user sees is exactly what will be copied.

---

### ConfirmationDialog

Modal dialog used for destructive confirmations. Implements `AC-crp-clear-confirmation`, `AC-crp-multi-file-remove-with-comments`.

The dialog now handles two use cases:

1. **Clear session** (`FR-crp-clear-session`): Removes all loaded files, all comments, and the preamble.
2. **Remove single file** (`FR-crp-multi-file-remove`): Removes one file and its comments from the session.

- **Props/Inputs**:
  - `title: string`
  - `body: string`
  - `confirmLabel: string`
  - `confirmVariant: 'destructive' | 'primary'`
  - `onConfirm: () => void`
  - `onCancel: () => void`

- **Visual Structure (Clear Session)**:
  ```
  +-----------------------------------------------+
  |  Clear session?                          [X]   |
  |                                                 |
  |  This will remove all 3 loaded files, all 5    |
  |  comments, and the preamble. This action        |
  |  cannot be undone.                              |
  |                                                 |
  |                        [Cancel] [Clear session] |
  +-----------------------------------------------+
  ```

- **Visual Structure (Remove Single File)**:
  ```
  +-----------------------------------------------+
  |  Remove file?                            [X]   |
  |                                                 |
  |  Remove "utils.ts"? This will remove the file  |
  |  and its 3 comments. This cannot be undone.     |
  |                                                 |
  |                            [Cancel]  [Remove]   |
  +-----------------------------------------------+
  ```

- **Content by use case**:

  | Use Case | Title | Body | Confirm Label |
  |---|---|---|---|
  | Clear session (1 file) | "Clear session?" | "This will remove the loaded file, all N comments, and the preamble. This action cannot be undone." | "Clear session" |
  | Clear session (multi-file) | "Clear session?" | "This will remove all N loaded files, all M comments, and the preamble. This action cannot be undone." | "Clear session" |
  | Remove file (with comments) | "Remove file?" | "Remove \"[filename]\"? This will remove the file and its N comments. This cannot be undone." | "Remove" |

  Note: Remove file without comments does not trigger a dialog (`AC-crp-multi-file-remove-no-comments`).

- **Styling**:
  - Overlay: semi-transparent black (`rgba(0,0,0,0.5)`).
  - Dialog: white background, rounded corners (8px), max-width 440px, centered vertically and horizontally. Box shadow: `0 4px 24px rgba(0,0,0,0.2)`. Padding: 24px.
  - Title: 18px semi-bold.
  - Body: 14px, color `#475569`.
  - "Cancel": secondary button.
  - Confirm button: destructive style (red background `#DC2626`, white text).
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
  - `success` — Green checkmark icon. Background: `#1E293B` (dark). Used for "Copied to clipboard" and "Prompt sent to agent! Switch back to your terminal." (`AC-crp-done-confirmation`).
  - `error` — Warning triangle icon. Background: `#991B1B` (dark red). Text: `#FFFFFF`. Used for error messages such as "Failed to copy. Try selecting the text manually.", "[filename] is not a text file and was skipped." (per-file binary rejection in multi-drop), or general file loading failures.
  - `warning` — Warning triangle icon. Background: `#92400E` (dark amber). Text: `#FFFFFF`. Used for fallback messages such as "Could not send to agent. Prompt copied to clipboard -- paste it manually." (`AC-crp-done-fallback-clipboard`).
  - `info` — Info icon. Background: `#1E293B`. Used for informational messages such as "Loaded N files." (multi-file drop confirmation), "Loaded N files. M files were skipped." (when some dropped files were binary), and "Syntax highlighting unavailable for this file. Displaying as plain text." (grammar load failure).

---

## Prompt Output Format

### Single-File Format

The generated prompt follows this exact structure when a single file has comments (`FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`):

```
## Instructions

[Preamble text, if provided. This entire section is omitted if no preamble was entered.]

## File: [filename] ([language])

### Requested Changes

```
const App = () => {
```
Rename this variable

```
function processData(input: any) {
  // ...complex logic...
}
```
Extract this to a helper function
```

### Multi-File Format

When multiple files have comments, the format extends to include multiple file sections (`FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`, `AC-crp-multi-file-prompt-structure`):

```
## Instructions

[Preamble text, if provided. This entire section is omitted if no preamble was entered.]

## File: utils.ts (TypeScript)

### Requested Changes

```
const App = () => {
```
Rename this variable

```
function processData(input: any) {
  // ...complex logic...
}
```
Extract this to a helper function

## File: helpers.ts (TypeScript)

### Requested Changes

```
export function formatDate(d: Date) {
```
Add error handling here
```

### Format Rules

- Comments are paired with code snippets (the actual source code the comment references), not line numbers. This ensures the prompt remains accurate even if line numbers shift during editing.
- Each comment is formatted as a fenced code block containing the relevant source lines, followed by the comment text on the next line.
- Comments within each file are listed in ascending source order.
- If no preamble is provided, the "Instructions" section is omitted entirely (not left empty). A preamble consisting only of whitespace is treated as empty.
- If the file name is unknown, use "Untitled" as the filename.
- If the language is unknown, use "Plain Text".
- For multi-file prompts:
  - The "Instructions" section appears once at the top (global preamble), not per-file.
  - Each file with comments gets its own `## File` heading with a `### Requested Changes` subsection.
  - Files appear in the order they are listed in the File Tab Bar (load order).
  - Files without comments are omitted entirely (`AC-crp-multi-file-prompt-omits-uncommented`).
  - When only one file has comments (even if multiple are loaded), the format is identical to the single-file format.

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
| **Switch between files** | `Tab` to File Tab Bar, `ArrowLeft`/`ArrowRight` to navigate tabs, `Enter` or `Space` to activate |
| **Add another file** | `Tab` to File Tab Bar, `Tab` to "+" button, `Enter` to open add-file modal |
| **Remove a file** | Focus a tab in the File Tab Bar, press `Delete` or `Backspace` |
| **Toggle review context panel** | `Tab` to context panel header, `Enter` or `Space` to collapse/expand |
| **Navigate to a line** | `Tab` to code viewer, `ArrowUp`/`ArrowDown` |
| **Add comment on a line** | Focus line, press `Enter` or `c`, type comment, `Cmd+Enter` to submit |
| **Add comment on a range** | Focus start line, `Shift+ArrowDown` to select range, `Enter` to open editor |
| **Edit a comment** | `Tab` to comment bubble, `Enter` to focus Edit button, `Enter` |
| **Delete a comment** | `Tab` to comment bubble, `Tab` to Delete button, `Enter` |
| **Navigate comments** | `[` for previous, `]` for next (navigates across all files) |
| **Mark/unmark file as reviewed** | `Cmd+Shift+R` / `Ctrl+Shift+R` (global shortcut, toggles active file); or `r` when a tab is focused in the File Tab Bar |
| **Copy prompt** | `Cmd+Shift+C` / `Ctrl+Shift+C` |
| **Send prompt (Done)** | `Cmd+Shift+D` / `Ctrl+Shift+D` (slash command mode only) |
| **Clear session** | `Tab` to Clear button, `Enter` |

### Focus Management

- When the InlineCommentEditor opens, focus moves to the text area.
- When the InlineCommentEditor closes (submit or cancel), focus returns to the line in the code viewer.
- When a modal dialog opens (including the add-file modal), focus is trapped inside it. On close, focus returns to the triggering button.
- Comment navigation (`[` and `]`) moves focus to the navigated CommentBubble. If the next/previous comment is in a different file, the corresponding tab is activated first, then the comment is focused.
- When a tab is removed from the File Tab Bar, focus moves to the adjacent tab (right, or left if rightmost was removed). If no tabs remain, focus moves to the drop zone.

### ARIA Attributes

| Element | ARIA |
|---|---|
| File Tab Bar container | `role="tablist"`, `aria-label="Loaded files"` |
| File tab | `role="tab"`, `aria-selected="true\|false"`, `aria-controls="[panel-id]"` |
| File tab close button | `aria-label="Remove [filename]"` |
| Add file button (in tab bar) | `aria-label="Add another file"` |
| Code viewer | `role="grid"`, `aria-label="Code viewer"` (also serves as `role="tabpanel"` with `aria-labelledby` pointing to the active tab) |
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
| Add file modal | `role="dialog"`, `aria-label="Add file"`, `aria-modal="true"` |
| Review status bar checkbox | `role="checkbox"`, `aria-checked="true\|false"`, `aria-label="Mark [filename] as reviewed"` |
| Review progress indicator | `role="status"`, `aria-live="polite"`, `aria-label="N of M files reviewed"` |
| File tab review toggle button | `aria-label="Mark [filename] as reviewed"` / `aria-label="Unmark [filename] as reviewed"`, `aria-pressed="true\|false"` |
| File tab group labels | `role="presentation"` |
| Review context panel header | `role="button"`, `aria-expanded="true\|false"`, `aria-controls="review-context-content"` |
| Review context panel content | `role="region"`, `aria-label="Review context"` |
| Context section (neutral) | `role="note"`, `aria-label="What Changed"` |
| Context section (review) | `role="note"`, `aria-label="Agent Review"` |

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
| Error background | Pale red | `#FEF2F2` |
| Error text | Dark red | `#991B1B` |
| Warning toast background | Dark amber | `#92400E` |
| Done button sent state | Green | `#16A34A` |
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
| Context panel background | Near-white | `#FAFBFC` |
| Context panel header | Light slate | `#F1F5F9` |
| Neutral context border (left) | Blue | `#3B82F6` |
| Neutral context icon | Blue | `#3B82F6` |
| Review context border (left) | Violet | `#7C3AED` |
| Review context background | Violet-50 | `#F5F3FF` |
| Review context border | Violet-200 | `#DDD6FE` |
| Review context icon | Violet | `#7C3AED` |
| Reviewed checkmark (light) | Green | `#16A34A` |
| Reviewed checkmark (dark) | Green-400 | `#4ADE80` |
| Reviewed bar background (light) | Green-50 | `#F0FDF4` |
| Reviewed bar background (dark) | Dark green | `#052E16` |
| Reviewed bar border (light) | Green-200 | `#BBF7D0` |
| Reviewed bar border (dark) | Green-800 | `#166534` |
| Reviewed text (light) | Green-700 | `#15803D` |
| Reviewed tab muted text | Light slate | `#94A3B8` |
| Progress complete text (light) | Green | `#16A34A` |
| Progress complete background (light) | Green-50 | `#F0FDF4` |
| Tab group label text | Muted | `#94A3B8` |
| Tab group divider | Dashed gray | `#CBD5E1` |

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
| Context panel header | System sans-serif | 12px | 600 | 16px |
| Context section label | System sans-serif | 11px | 600 | 16px |
| Context section header | System sans-serif | 12px | 600 | 16px |
| Context content text | System sans-serif | 13px | 400 | 20px |
| Tab group label | System sans-serif | 10px | 600 | 16px |
| Review status bar label | System sans-serif | 13px | 400 (unreviewed) / 600 (reviewed) | 20px |
| Review progress indicator | System sans-serif | 12px | 500 | 16px |

System sans-serif stack: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif`

Monospace stack: `ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace`

---

## Requirement Traceability

This section maps every product requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-crp-file-load` | FileDropZone component; Flows 1, 2, 3; Flow 17 (add file to session); Flow 20 (drag-drop additional files) |
| `FR-crp-file-display` | CodeViewer component; File Loaded Screen layout |
| `FR-crp-syntax-highlight` | CodeViewer component (language prop, progressive highlighting); FileDropZone (language detection) |
| `FR-crp-line-comment-create` | InlineCommentEditor component (create variant); Flow 4; CommentBubble |
| `FR-crp-line-comment-edit` | InlineCommentEditor component (edit variant); Flow 6; CommentBubble (Edit action) |
| `FR-crp-line-comment-delete` | CommentBubble component (Delete action); Flow 7 |
| `FR-crp-comment-indicator` | CodeViewer gutter (blue dot indicator); CommentBubble |
| `FR-crp-comment-count` | Toolbar component (global comment count across all files); FileTabBar (per-file comment count badges) |
| `FR-crp-prompt-preamble` | PreambleInput component; Flow 8 |
| `FR-crp-prompt-generate` | Automatic prompt generation on comment/preamble change; Flow 9; Prompt Output Format section |
| `FR-crp-prompt-preview` | PromptPreview component (populated variant — single and multi-file) |
| `FR-crp-prompt-copy` | Toolbar Copy button; PromptPreview Copy button; Flow 10; ToastNotification |
| `FR-crp-prompt-format` | Prompt Output Format section (single-file format); PromptPreview component |
| `FR-crp-clear-session` | Toolbar Clear button; ConfirmationDialog component (clear session variant); Flow 12 |
| `FR-crp-filename-display` | FileHeader (single-file mode); FileTabBar tabs and tooltips (multi-file mode); FileDropZone (paste-mode file name input) |
| `FR-crp-line-range-comment` | CodeViewer (range selection); Flow 5; Flow 14 |
| `FR-crp-comment-navigation` | Toolbar (previous/next buttons); Flow 11; Flow 18 (cross-file comment navigation) |
| `FR-crp-done-action` | Toolbar Done button; Done Button States table; Flow 15; Slash Command Mode Detection |
| `FR-crp-prompt-handoff` | Flow 15 (POST to `/api/prompt-output`); Flow 16 (error fallback) |
| `FR-crp-multi-file-load` | FileDropZone component (modal variant, multi-drop); FileTabBar (add file button); Flow 17; Flow 20 |
| `FR-crp-multi-file-nav` | FileTabBar component; File Loaded State (Multi-File) layout; Flow 18; Screen Inventory table |
| `FR-crp-multi-file-remove` | FileTabBar (close button on tabs); ConfirmationDialog (remove file variant); Flow 19 |
| `FR-crp-multi-file-prompt` | PromptPreview component (multi-file populated variant); Prompt Output Format section (multi-file format); Flow 9 |
| `FR-crp-multi-file-prompt-format` | Prompt Output Format section (multi-file format rules) |
| `FR-crp-review-context-receive` | ReviewContextPanel component (conditional rendering based on data availability); Code Viewer Panel layout (item 2) |
| `FR-crp-review-context-display` | ReviewContextPanel component; ContextSection component; Application Layout (single-file and multi-file with context panel); Code Viewer Panel layout; Flow 18 step 6 |
| `FR-crp-review-context-overall` | ReviewContextPanel component (overall section); Application Layout diagrams; Flow 18 step 6 |
| `FR-crp-review-context-per-file` | ReviewContextPanel component (per-file section); Flow 18 step 6 (per-file context updates on tab switch) |
| `FR-crp-file-reviewed-toggle` | ReviewStatusBar component (primary toggle); FileTabBar review toggle button; Toolbar keyboard shortcut `Cmd+Shift+R`; Flow 21; Flow 22 |
| `FR-crp-file-reviewed-visual` | FileTabBar tab states (green checkmark, muted text for reviewed tabs); ReviewStatusBar styling (reviewed variant) |
| `FR-crp-file-reviewed-grouping` | FileTabBar visual structure (group labels "TO REVIEW" / "REVIEWED", divider, grouping logic); Flow 23 |
| `FR-crp-file-reviewed-progress` | Toolbar review progress indicator ("N/M reviewed" badge); Toolbar props (`reviewedCount`) |
| `FR-crp-file-reviewed-persistence` | ReviewStatusBar behavior (session-level state); Flow 19 step 5 (discarded on removal); Flow 12 (cleared on session clear); File Loaded Screen "multi-file: file switching" state |

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
| `AC-crp-generate-prompt-structure` | Flow 9; Prompt Output Format section (single-file and multi-file formats) |
| `AC-crp-generate-prompt-no-comments` | Toolbar states table (Copy disabled when 0 comments across all files; prompt only auto-generates when comments exist) |
| `AC-crp-copy-clipboard` | Flow 10; ToastNotification component |
| `AC-crp-preview-matches-copy` | Flow 10 (byte-for-byte match note); PromptPreview renders exact text |
| `AC-crp-clear-confirmation` | Flow 12; ConfirmationDialog component (clear session variant with multi-file message) |
| `AC-crp-clear-no-confirm-empty` | Flow 12 (immediate clear when no comments) |
| `AC-crp-empty-state` | Empty State Screen definition; FileDropZone; Toolbar disabled states |
| `AC-crp-large-file-scroll` | CodeViewer performance note (virtualized rendering) |
| `AC-crp-comment-navigation-next` | Flow 11; Toolbar navigation buttons; Flow 18 (cross-file navigation) |
| `AC-crp-keyboard-add-comment` | Flow 13; CodeViewer keyboard accessibility |
| `AC-crp-binary-file-rejected` | FileDropZone error state; Flows 2, 3 (binary check); Flow 20 (per-file rejection for multi-drop) |
| `AC-crp-done-sends-prompt` | Flow 15 (POST + clipboard copy in parallel) |
| `AC-crp-done-auto-close` | Flow 15 step 5b-c (`window.close()` as primary success path); File Loaded Screen "Prompt sent (auto-close)" state |
| `AC-crp-done-confirmation` | Flow 15 step 5d (fallback when auto-close fails); File Loaded Screen "Prompt sent (fallback)" state |
| `AC-crp-done-fallback-clipboard` | Flow 16 (error fallback, prompt on clipboard); File Loaded Screen "Prompt send failed" state; ToastNotification warning variant |
| `AC-crp-done-disabled-no-comments` | Toolbar States table (Done disabled when 0 comments); Done Button States table (disabled state) |
| `AC-crp-done-standalone-hidden` | Toolbar States table (Done not rendered outside slash command mode); Slash Command Mode Detection |
| `AC-crp-multi-file-load-adds` | Flow 17 (loading a second file adds to session); FileTabBar component |
| `AC-crp-multi-file-drop-multiple` | Flow 20 (multiple files dropped simultaneously); FileDropZone multi-drop behavior |
| `AC-crp-multi-file-nav-preserves-state` | Flow 18 (switching files preserves comments and scroll position); File Loaded Screen multi-file states |
| `AC-crp-multi-file-remove-with-comments` | Flow 19 step 3 (confirmation dialog for files with comments); ConfirmationDialog (remove file variant) |
| `AC-crp-multi-file-remove-no-comments` | Flow 19 step 4 (immediate removal without confirmation) |
| `AC-crp-multi-file-prompt-structure` | Prompt Output Format section (multi-file format); PromptPreview (multi-file populated variant) |
| `AC-crp-multi-file-prompt-omits-uncommented` | Prompt Output Format format rules (files without comments omitted) |
| `AC-crp-multi-file-comment-count` | Toolbar component (`commentCount` prop — global across all files); FileTabBar (per-file badge) |
| `AC-crp-multi-file-clear-all` | Flow 12; ConfirmationDialog (clear session variant with multi-file count); File Loaded Screen states |
| `AC-crp-multi-file-empty-after-remove-last` | Flow 19 step 6 (returns to Empty State when last file removed) |
| `AC-crp-context-overall-visible` | ReviewContextPanel component (expanded state with overall section); Application Layout diagrams |
| `AC-crp-context-per-file-visible` | ReviewContextPanel component (expanded state with per-file section); Application Layout diagrams |
| `AC-crp-context-per-file-switches` | Flow 18 step 6 (per-file context updates on tab switch); ReviewContextPanel component |
| `AC-crp-context-neutral-vs-review` | ContextSection component (neutral vs review variants with distinct visual treatment); ReviewContextPanel component |
| `AC-crp-context-graceful-missing` | ReviewContextPanel component (absent/hidden state — not rendered when no context data); Code Viewer Panel layout |
| `AC-crp-context-readonly` | ReviewContextPanel component (read-only content); ContextSection component (read-only div, no editable elements) |
| `AC-crp-file-mark-reviewed` | ReviewStatusBar component (unreviewed -> reviewed transition); FileTabBar (review toggle button, visual update); Flow 21 |
| `AC-crp-file-unmark-reviewed` | ReviewStatusBar component (reviewed -> unreviewed transition); FileTabBar (review toggle button, visual update); Flow 22 |
| `AC-crp-file-reviewed-grouping` | FileTabBar (group labels, divider, tab ordering by group); Flow 23 (transition animations) |
| `AC-crp-file-reviewed-progress-count` | Toolbar review progress indicator (updates on mark/unmark/add/remove); Flow 21 step 6 |
| `AC-crp-file-reviewed-survives-tab-switch` | File Loaded Screen "multi-file: file switching" state; Flow 18 (reviewed status preserved) |
| `AC-crp-file-reviewed-with-comments` | Flow 21 step 7 (reviewed status is orthogonal to comments); ReviewStatusBar (available regardless of comment state) |
| `AC-crp-file-reviewed-clear-session` | Flow 12 (all reviewed statuses cleared with session) |
