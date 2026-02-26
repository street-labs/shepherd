# Code Review Prompt Generator — macOS Design Spec

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/macos/code-review-prompt.md` for macOS-specific requirements.

## Screen Inventory

The application is a native macOS window that transitions through several states. Each concurrent session opens in its own window (`FR-crp-macos-window-management`). There are no separate routes — all states are presented within the same window.

| View State | Description |
|---|---|
| **Empty State** | No file loaded. A centered drop zone fills the window content area with instructions for loading files. |
| **Single-File State** | One file is loaded. Two-column layout: code viewer (center) and inspector sidebar (right). The file browser sidebar is not shown. |
| **Multi-File State** | Two or more files are loaded. Three-column layout using a split view: file browser sidebar (left), code viewer (center), inspector sidebar (right). Implements `FR-crp-multi-file-nav`, `FR-crp-panel-resize`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`. |
| **Prompt Active State** | At least one comment exists on any loaded file. The inspector sidebar shows the live prompt preview. Active within both single-file and multi-file states. Implements `FR-crp-prompt-preview`, `FR-crp-multi-file-prompt`. |

Within the file-loaded states (single-file and multi-file), the application has sub-states depending on user activity (editing a comment, selecting a line range, etc.). These are described in detail below.

---

## Application Layout

The application uses a standard macOS window with a toolbar at the top and a main content area below it. The content area is divided into panels using native split views.

### Window Structure

```
+====================================================================+
| [close] [minimize] [zoom]    Toolbar    [global actions]           |
+====================================================================+
|                                                                      |
|  Main Content Area                                                   |
|  (contents vary by state -- see below)                               |
|                                                                      |
+----------------------------------------------------------------------+
```

- **Toolbar**: Native toolbar integrated with the title bar. Contains the window title (session context per `FR-crp-session-identity`) and action items. The toolbar can be customized by the user via the standard macOS toolbar customization mechanism (right-click toolbar > Customize Toolbar).
- **Main Content Area**: Fills the window below the toolbar. Uses native split views for column layouts.

### Main Content Area -- Empty State (`AC-crp-empty-state`)

When no file is loaded, the entire content area is a single centered drop zone.

```
+----------------------------------------------------------------------+
|                                                                      |
|                                                                      |
|                   [  Drop files here or press                        |
|                      Cmd+O to open  ]                                |
|                                                                      |
|                                                                      |
+----------------------------------------------------------------------+
```

### Main Content Area -- Single-File State

When one file is loaded, the content area splits into two columns:

```
+----------------------------------------------+-----------------------+
|                                              |                       |
|  Code Viewer Panel                           |  Inspector Sidebar    |
|  (flexible width)                            |  (default 340pt)      |
|                                              |                       |
|  +----------------------------------------+ |  +------------------+ |
|  | FileHeader                              | |  | Review Context   | |
|  | Review Context (collapsible, if avail.) | |  | (collapsible)    | |
|  | Code with line numbers + gutter         | |  | Overall Comment  | |
|  | Inline comments                         | |  | [Preview][All]   | |
|  |                                         | |  | Prompt / Summary | |
|  +----------------------------------------+ |  +------------------+ |
|                                              |                       |
+----------------------------------------------+-----------------------+
```

- **Code Viewer Panel**: Takes remaining width after the inspector. Contains the FileHeader, the per-file ReviewContextPanel (when context data is available, `FR-crp-review-context-display`), and the scrollable code viewer with line numbers, gutter, and inline comments. Scrolls vertically independently.
- **Inspector Sidebar**: Default width of 340pt on the right side. Contains the ReviewContextSection (overall changeset context, when available), the Overall Comment text editor, and a segmented control switching between Preview and All Comments. Scrolls vertically independently.

### Main Content Area -- Multi-File State

When two or more files are loaded, a file browser sidebar appears on the left, creating a three-column layout. Implements `FR-crp-multi-file-nav`, `FR-crp-panel-resize`.

```
+----------------------------------------------------------------------+
|  Toolbar: [Open] [title: session/Shepherd] [Wrap] [Copy] [Done]      |
+-----------+--+-----------------------------------+-----------------------+
|           |  |                                   |                       |
| File      |  |  Code Viewer Panel                |  Inspector Sidebar    |
| Browser   |  |  (flexible width)                 |  (default 340pt)      |
| Sidebar   |  |                                   |                       |
| (220pt    |  |  +-------------------------------+|  +------------------+ |
|  default) |  |  | ActiveFilePath                ||  | Review Context   | |
|           |  |  | Review Context (if available) ||  | (collapsible)    | |
|           |  |  | Code + line numbers + gutter  ||  | Overall Comment  | |
|           |  |  | Inline comments               ||  | [Preview][All]   | |
|           |  |  |                               ||  | Prompt / Summary | |
|           |  |  +-------------------------------+|  +------------------+ |
|           |  |                                   |                       |
+-----------+--+-----------------------------------+-----------------------+
             ^
             | divider (drag to resize)
```

- **File Browser Sidebar**: Default width of 220pt on the left side, user-resizable via the native split view divider (`FR-crp-panel-resize`). Source list style background. Lists all loaded files in a directory tree with review status indicators, per-file comment counts, and a review progress indicator. See FileBrowser component spec.
- **ActiveFilePath**: A breadcrumb-style bar at the top of the Code Viewer Panel showing the full relative file path of the active file (`FR-crp-active-file-path`). Only rendered in multi-file mode (2+ files loaded). Updates when the active file changes (`AC-crp-active-file-path-switches`). Not rendered in single-file mode (`AC-crp-active-file-path-single-file`).
- **Code Viewer Panel**: Same as single-file layout, except the FileHeader is replaced by the ActiveFilePath bar. In multi-file mode, the ReviewContextPanel (if present) appears below the ActiveFilePath, followed by the code viewer.
- **Inspector Sidebar**: Same as single-file layout. The prompt preview aggregates comments across all files.

> **Note**: The file browser sidebar appears as soon as the second file is loaded and remains visible until only one file remains, at which point it collapses back to the single-file two-column layout with the FileHeader restored.

---

## Screen Definitions

### Empty State Screen

- **Purpose**: Guide the user to load a file so they can begin annotating. Implements `AC-crp-empty-state`.
- **Entry points**: Application launch in standalone mode (`FR-crp-macos-standalone-mode`); after clearing a session (`FR-crp-clear-session`).

#### Layout

The entire content area is a single centered drop zone.

#### Components

- **FileDropZone** (see Component Specs): Fills the content area. Provides file loading via open panel, drag-and-drop from Finder, and paste. Implements `FR-crp-file-load`, `FR-crp-macos-file-open-panel`, `FR-crp-macos-drag-drop-finder`.
- **Toolbar**: Visible but with most actions disabled.
  - Open button: enabled. Opens the native file open panel.
  - Copy Prompt: disabled (`AC-crp-macos-menu-copy-disabled`). Tooltip: "Load a file to get started."
  - Line Wrap toggle: disabled.
  - Comment navigation (Cmd+] / Cmd+[): disabled.
  - Done button (if in slash command mode): disabled.

#### States

| State | Trigger | Appearance |
|---|---|---|
| **Default** | App launch / session cleared | Centered message with SF Symbol (doc.badge.plus, large, secondary color). Text: "Drop files here or press Cmd+O to open". Subtext: "Accepts any plain-text file." |
| **Drag hover** | Files dragged over the window | The entire content area highlights with a system accent color border. A translucent overlay appears with "Drop to load files" centered. |
| **Loading** | File is being read | A brief indeterminate progress indicator centered in the content area. |
| **Error -- binary file** | Binary file detected (`AC-crp-binary-file-rejected`) | A native alert appears: "Cannot Open File" / "This file does not appear to contain text. Only plain-text files are supported." with a Dismiss button. |
| **Error -- permission denied** | File cannot be read (`AC-crp-macos-file-permission-error`) | A native alert appears: "Cannot Read File" / "The file could not be read. Check that the application has permission to access this file." with a Dismiss button. |
| **Error -- read failure** | File read fails | A native alert appears: "Failed to Read File" / "An error occurred while reading the file. Please try again." with a Dismiss button. |

---

### File Loaded Screen

- **Purpose**: Display the loaded file(s) with line numbers, allow the user to add/edit/delete inline comments, write an Overall Comment, and view the auto-generated prompt. When multiple files are loaded, provide file browser navigation between them (`FR-crp-multi-file-nav`).
- **Entry points**: Successfully loading a file from the Empty State; loading additional files via Open (Cmd+O) or drag-and-drop; launching via slash command with session data (`FR-crp-macos-slash-command-launch`).

#### Layout

**Single file**: Two-column layout: Code Viewer Panel (left, flexible) and Inspector Sidebar (right, default 340pt).

**Multiple files**: File Browser sidebar on the left, creating a three-column layout. See "Main Content Area -- Multi-File State" in the Application Layout section.

#### Code Viewer Panel

Contains the following from top to bottom:

1. **FileHeader** (single-file mode only): A horizontal bar at the top of the code viewer showing the file name (`FR-crp-filename-display`) and detected language. Uses system font. Displays: file name (truncated with ellipsis if too long) and a language label (e.g., "TypeScript", "Python"). If the language cannot be detected, shows "Plain Text".
   - If the file was pasted with no name, shows "Untitled".
   - **In multi-file mode**, the FileHeader is replaced by the ActiveFilePath bar.

2. **ActiveFilePath** (multi-file mode only): A compact breadcrumb-style bar displaying the full relative file path of the active file (`FR-crp-active-file-path`). Positioned at the top of the Code Viewer Panel, replacing the FileHeader in multi-file mode. Only rendered when 2+ files are loaded. Updates when the active file changes (`AC-crp-active-file-path-switches`). Not rendered in single-file mode (`AC-crp-active-file-path-single-file`). See ActiveFilePath component spec.

3. **ReviewContextPanel** (conditional): Visible only when review context data is available (`FR-crp-review-context-receive`) and the active file has per-file context. Positioned below the ActiveFilePath (multi-file) or below the FileHeader (single-file). Shows per-file context only for the active file (overall changeset context is in the Inspector Sidebar). Collapsible to maximize code viewing space. When no context data is available (standalone mode), or the active file has no per-file context, this component is not rendered at all (`AC-crp-context-graceful-missing`). See ReviewContextPanel component spec.

4. **CodeViewer**: The main scrollable code display area. Implements `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`. In multi-file mode, displays the content of the currently active file only. When the user switches files via the file browser, the code viewer swaps to the new file's content, restoring that file's scroll position and rendering its comments.

5. **InlineCommentEditor**: Appears inline within the CodeViewer when the user is creating or editing a comment. See Component Specs.

#### Inspector Sidebar

Contains the following from top to bottom:

1. **ReviewContextSection** (conditional): Visible only when review context data is available (`FR-crp-review-context-receive`). A collapsible section showing the overall changeset context (neutral context + review feedback). Implements `FR-crp-review-context-collapsible`, `FR-crp-review-context-overall`. See ReviewContextSection component spec.
2. **Overall Comment editor**: A text editor for the Overall Comment (`FR-crp-prompt-preamble`). See Component Specs.
3. **Content tabs**: A native segmented control below the Overall Comment, with two segments: **"Preview"** and **"All Comments"**.
   - **Preview** segment (default): Shows the PromptPreview component. Appears below the Overall Comment once comments exist (`FR-crp-prompt-preview`). Before any comments are added, this area shows a placeholder message: "Add comments to the code to generate your AI prompt."
   - **All Comments** segment: Shows the CommentSummary component. Displays all comments across all loaded files, organized by file (`FR-crp-comment-summary`). See CommentSummary component spec.

#### Toolbar (File Loaded State)

All toolbar items update to their active states:

| Item | Position | State | Behavior |
|---|---|---|---|
| **Open** (doc.badge.plus) | Leading | Always enabled | Opens the native file open panel. `FR-crp-macos-file-open-panel` |
| **Window Title** | Center | Reflects session context | Session name or "Shepherd". `FR-crp-session-identity` |
| **Line Wrap** (text.word.spacing) | Trailing | Toggle, default ON | Toggles line wrapping in the code viewer. `FR-crp-line-wrap` |
| **Copy Prompt** (doc.on.doc) | Trailing | Enabled when >= 1 comment | Copies prompt to system clipboard. `FR-crp-prompt-copy`, `FR-crp-macos-clipboard` |
| **Done** (checkmark.circle.fill) | Trailing | Only in slash command mode; enabled when >= 1 comment | Sends prompt to agent and closes window. `FR-crp-done-action`, `FR-crp-macos-auto-close` |

Comment count and navigation are accessible via the Review menu (Cmd+] / Cmd+[) rather than occupying toolbar space.

#### States

| State | Trigger | Appearance |
|---|---|---|
| **Populated, no comments** | File(s) loaded, zero comments on any file | Code viewer shows the active file. Inspector shows ReviewContextSection (if available), empty Overall Comment, and placeholder in Preview tab. Copy Prompt disabled. |
| **Populated, with comments** | One or more comments exist on any loaded file | Code viewer shows the active file with comment indicators in the gutter. Prompt preview updates automatically. Copy Prompt enabled. In multi-file mode, the file browser shows per-file comment count badges. |
| **Comment editing** | User opens the inline comment editor | InlineCommentEditor is inserted below the target line(s) in the code viewer. Subsequent content shifts down. |
| **Line range selection** | User is selecting a range of lines (`FR-crp-line-range-comment`) | Selected lines are highlighted with the system selection color. A floating label shows "Lines N-M". |
| **Prompt copied** | User clicks Copy Prompt or presses Cmd+Shift+C | The Copy Prompt toolbar icon briefly animates (checkmark replaces the copy icon for 2 seconds). No toast -- the toolbar animation is the confirmation. `AC-crp-copy-clipboard` |
| **Prompt sent (auto-close)** | User clicks Done, handoff succeeds (`AC-crp-macos-auto-close-reliable`) | Done toolbar icon shows a brief spinner, then the window closes. Focus returns to the previously active application (typically the terminal). `FR-crp-macos-auto-close` |
| **Prompt send failed** | Handoff to server fails (`AC-crp-done-fallback-clipboard`) | A native alert appears: "Could Not Send to Agent" / "The prompt was copied to your clipboard instead. Switch to your terminal and paste manually." The prompt is on the clipboard. |
| **Large file warning** | File exceeds 10,000 lines (`NFR-crp-large-file-perf`) | An inline banner appears at the top of the code viewer: "This file has N lines. Large files may affect performance." Dismissible with an X button. |
| **Multi-file: file switching** | User clicks a different file in the file browser (`FR-crp-multi-file-nav`) | The code viewer transitions to the newly active file. Previous file's state is preserved in memory. `AC-crp-multi-file-nav-preserves-state`, `AC-crp-file-reviewed-survives-tab-switch` |
| **Multi-file: file removal** | User removes a file via context menu (`FR-crp-multi-file-remove`) | The file row disappears from the file browser. If it was the active file, the adjacent file becomes active. If no files remain, the app returns to the Empty State. `AC-crp-multi-file-empty-after-remove-last` |
| **Multi-file: drag-over add** | Files dragged over the window while files are loaded | A drop overlay appears over the code viewer: "Drop to add file(s)" with a highlighted border. On drop, files are added to the session. |

---

## Interaction Flows

### Flow 1: Load File via Open Panel (`AC-crp-load-upload`, `FR-crp-macos-file-open-panel`, `AC-crp-macos-open-panel-multi`)

1. User clicks the Open toolbar button or presses Cmd+O.
2. The native macOS file open panel appears. It supports selecting multiple files simultaneously (`AC-crp-macos-open-panel-multi`). The panel remembers the last-used directory within the session.
3. User selects one or more files and clicks Open.
4. Each file undergoes binary detection (null-byte scan of the first 8,192 bytes).
5. Binary files are rejected with a native alert per file (`AC-crp-binary-file-rejected`).
6. Valid text files are loaded into the session:
   - **Single file selected, empty state**: Transitions to single-file state. File name from the filesystem is shown in the FileHeader.
   - **Multiple files selected, or files already loaded**: Transitions to multi-file state. The last loaded file becomes the active file. If this is the first time going from one file to two, the file browser sidebar appears.
7. File paths from the open panel are used for display and prompt generation (`AC-crp-macos-drag-drop-finder-path`).

### Flow 2: Load File via Drag and Drop (`AC-crp-load-drag-drop`, `FR-crp-macos-drag-drop-finder`, `AC-crp-multi-file-drop-multiple`)

1. User drags one or more files from Finder over the application window.
2. The window highlights with a drag indicator (translucent overlay with system accent border). Text: "Drop to load files."
3. User drops the file(s).
4. Each dropped file undergoes binary detection independently.
5. Binary files are rejected individually with a native alert per file.
6. **Single file dropped, empty state**: Transition to single-file state. File name from Finder is shown.
7. **Multiple files dropped** (`AC-crp-multi-file-drop-multiple`): All valid text files are loaded into the session. The last loaded file becomes the active file.
8. **Files dropped while files are already loaded**: New files are added to the session. If transitioning from one to two files, the file browser sidebar appears.

### Flow 3: Load File via Paste (`AC-crp-load-paste`)

1. User presses Cmd+V while the application is in the empty state (or while the code viewer has focus and no text input is active).
2. If the system clipboard contains plain text, the text is loaded as a new file with the name "Untitled".
3. Application transitions to the file loaded state. The file is shown with line numbers starting at 1.
4. If the clipboard does not contain text (e.g., contains an image), nothing happens.

### Flow 4: Load File via Slash Command (`FR-crp-macos-slash-command-launch`, `AC-crp-macos-slash-command-launch-session`)

1. The CLI invokes the application with a session ID.
2. If the application is already running with a window for that session ID, the existing window is brought to the front (`AC-crp-macos-window-deduplicate`).
3. If no window exists for the session, a new window opens.
4. The application reads session data from `~/.shepherd/sessions/<session-id>/` and loads the files and context specified.
5. The window title is set to the session context (e.g., "Shepherd -- myproject"). `FR-crp-session-identity`
6. Files with review context data display the ReviewContextPanel and ReviewContextSection. `FR-crp-review-context-receive`, `FR-crp-review-context-display`
7. The Done button is shown in the toolbar (slash command mode). `AC-crp-done-standalone-hidden`

### Flow 5: Add a Single-Line Comment (`AC-crp-add-comment-single-line`, `FR-crp-line-comment-create`)

1. User hovers over a line in the code viewer. A faint "+" icon (SF Symbol: plus.bubble) appears in the gutter on that line.
2. User clicks the gutter "+" icon or the line number itself.
3. The InlineCommentEditor opens directly below that line, pushing subsequent lines down.
4. The editor contains a text view (auto-focused) and two buttons: "Comment" (default/accent) and "Cancel" (secondary).
5. User types their comment text.
6. User clicks "Comment" or presses Cmd+Return (context-specific, only active when the editor has focus).
7. The editor closes. A CommentBubble appears below the line showing the comment text. The gutter for that line shows a comment indicator. The comment count (visible in the Review menu and the All Comments tab) increments.
8. If the user clicks "Cancel" or presses Escape, the editor closes with no comment created.

### Flow 6: Add a Line-Range Comment (`AC-crp-add-comment-line-range`, `FR-crp-line-range-comment`)

1. User clicks on a line number in the gutter and drags to another line number. Alternatively, user clicks a line number, then Shift+clicks another line number.
2. The selected range is highlighted with the system selection color. A small floating label shows "Lines N-M".
3. The InlineCommentEditor opens below the last line of the range.
4. User types their comment and clicks "Comment" or presses Cmd+Return.
5. The editor closes. A CommentBubble appears below the range with a label "Lines N-M". The gutter shows comment indicators for every line in the range.
6. To cancel the selection without commenting, the user presses Escape or clicks elsewhere.

### Flow 7: Edit a Comment (`AC-crp-edit-comment`, `FR-crp-line-comment-edit`)

1. User sees an existing CommentBubble below a line.
2. User double-clicks the comment text, or clicks an "Edit" button that appears on hover.
3. The CommentBubble transforms into the InlineCommentEditor, pre-populated with the existing comment text. The text view is auto-focused with the cursor at the end.
4. User modifies the text.
5. User clicks "Save" or presses Cmd+Return.
6. The editor reverts to a CommentBubble showing the updated text. The comment remains on the same line(s).
7. If the user clicks "Cancel" or presses Escape, the edit is discarded and the original CommentBubble is restored.

### Flow 8: Delete a Comment (`AC-crp-delete-comment`, `FR-crp-line-comment-delete`)

1. User hovers over a CommentBubble. A "Delete" button (SF Symbol: trash) appears.
2. User clicks "Delete".
3. The CommentBubble is removed (no confirmation for individual comment deletion). The gutter indicator is removed if no other comments remain on that line. The comment count decrements.
4. The prompt preview automatically updates. If no comments remain, the prompt preview reverts to the placeholder and the Copy Prompt toolbar item becomes disabled.

### Flow 9: Write an Overall Comment (`FR-crp-prompt-preamble`)

1. In the Inspector Sidebar, the user sees a text editor labeled "Overall Comment" with placeholder text: "Add an overall comment for all files in this review..."
2. User clicks the text editor and types their overall comment.
3. The overall comment is stored in application state. No explicit save action is needed.
4. If comments exist, the prompt automatically regenerates to include the updated overall comment. The overall comment appears once at the top of the prompt in the "Instructions" section (`AC-crp-overall-comment-in-prompt`).

### Flow 10: Copy Prompt to Clipboard (`AC-crp-copy-clipboard`, `AC-crp-preview-matches-copy`, `FR-crp-macos-clipboard`)

1. User clicks the Copy Prompt toolbar button or presses Cmd+Shift+C (via the Review menu).
2. The prompt text is placed on the system clipboard via native clipboard integration (`FR-crp-macos-clipboard`).
3. The Copy Prompt toolbar icon briefly changes to a checkmark for 2 seconds, then reverts.
4. The text on the clipboard is identical to the text shown in the prompt preview (`AC-crp-preview-matches-copy`).

### Flow 11: Navigate Between Comments (`FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`)

1. User presses Cmd+] (Next Comment) or Cmd+[ (Previous Comment) via the Review menu.
2. The code viewer scrolls to center the target comment in the viewport. The CommentBubble briefly highlights.
3. If the user is on the last comment, "Next" wraps to the first comment.
4. "Previous" works identically in reverse order.
5. In multi-file mode, if the next comment is in a different file, navigating to it automatically switches to that file in the file browser.

### Flow 12: Clear Session (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`, `FR-crp-clear-session`, `AC-crp-multi-file-clear-all`)

1. User selects Review > Clear Session from the menu bar.
2. **If comments exist on any file** (`AC-crp-clear-confirmation`): A native alert sheet drops from the title bar:
   - Title: "Clear Session?"
   - Body (single file): "This will remove the loaded file, all N comments, and the overall comment. This cannot be undone."
   - Body (multi-file): "This will remove all M loaded files, all N comments, and the overall comment. This cannot be undone." (`AC-crp-multi-file-clear-all`)
   - Buttons: "Cancel" (default) and "Clear Session" (destructive).
   - If user clicks "Clear Session", everything is removed (`AC-crp-file-reviewed-clear-session`). The app returns to the Empty State.
   - If user clicks "Cancel", nothing changes.
3. **If no comments exist on any file** (`AC-crp-clear-no-confirm-empty`): The session clears immediately without a dialog.

### Flow 13: Done -- Send Prompt to Agent (`FR-crp-done-action`, `FR-crp-prompt-handoff`, `AC-crp-done-sends-prompt`, `AC-crp-macos-auto-close-reliable`)

> This flow applies only in slash command mode.

1. User finishes annotating. At least one inline comment exists.
2. User clicks the Done toolbar button or presses Cmd+Return (via the Review menu).
3. The Done toolbar icon shows a brief spinner.
4. Two operations execute:
   a. The prompt text is written to `~/.shepherd/sessions/<session-id>/prompt-output.md` (`FR-crp-prompt-handoff`).
   b. The prompt is copied to the system clipboard (`FR-crp-macos-clipboard`).
5. On success: The window closes reliably (`FR-crp-macos-auto-close`, `AC-crp-macos-auto-close-reliable`). Focus returns to the previously active application (the terminal). There is no fallback confirmation state needed because the native window close always succeeds.
6. If only one window was open, the application remains running with no windows (standard macOS behavior, `AC-crp-macos-close-last-window`). The user can reactivate from the Dock.

### Flow 14: Done -- Error Fallback (`AC-crp-done-fallback-clipboard`)

1. User clicks Done.
2. The prompt handoff fails (e.g., session directory not writable).
3. The prompt is still copied to the system clipboard.
4. A native alert appears: "Could Not Send to Agent" / "The prompt was copied to your clipboard. Switch to your terminal and paste it manually." Dismiss button.
5. The Done button reverts to its normal state. The user can retry.

### Flow 15: Switch Between Files (`FR-crp-multi-file-nav`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-context-per-file-switches`)

1. User sees multiple files in the file browser sidebar. One is highlighted as active.
2. User clicks on an inactive file row (or navigates with arrow keys and presses Return).
3. The code viewer transitions instantly to the selected file. The ActiveFilePath bar updates (`AC-crp-active-file-path-switches`).
4. All comments for the selected file are rendered. The scroll position is restored.
5. The previously active file retains its full state. If the user had an InlineCommentEditor open, it is closed without saving.
6. If the ReviewContextPanel is visible, the per-file context updates (`AC-crp-context-per-file-switches`). If the new file has no per-file context, the panel is not rendered. The overall changeset context in the Inspector is unaffected. The collapse state of both context areas is preserved.
7. The prompt preview in the Inspector continues to reflect all comments across all files.
8. Comment navigation (Cmd+] / Cmd+[) operates across all files. If the next comment is in a different file, switching to it automatically activates that file.

### Flow 16: Remove a File (`FR-crp-multi-file-remove`, `AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments`, `AC-crp-multi-file-empty-after-remove-last`)

1. User right-clicks (or Control-clicks) a file row in the file browser, revealing the context menu.
2. User selects "Remove File" from the context menu.
3. **If the file has comments** (`AC-crp-multi-file-remove-with-comments`): A native alert sheet appears:
   - Title: "Remove File?"
   - Body: "Remove \"[filename]\"? This will remove the file and its N comments. This cannot be undone."
   - Buttons: "Cancel" (default) / "Remove" (destructive).
4. **If the file has no comments** (`AC-crp-multi-file-remove-no-comments`): The file is removed immediately.
5. The file row disappears from the file browser. The review progress indicator updates.
6. If the removed file was active: the adjacent file becomes active. If no files remain: the app returns to the Empty State.
7. If only one file remains, the file browser sidebar collapses, the ActiveFilePath disappears, and the layout reverts to single-file with the FileHeader restored.
8. The prompt regenerates, omitting the removed file.

### Flow 17: Mark a File as Reviewed (`FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-reviewed-with-comments`)

There are three ways to mark a file as reviewed:

**Via the file browser context menu:**

1. User right-clicks a file row in the file browser.
2. User selects "Mark as Reviewed" (or "Mark as Unreviewed" if already reviewed).
3. The file row immediately updates with the reviewed visual treatment (checkmark overlay on the file icon, muted text if inactive).
4. Within its parent directory, the file reorders so unreviewed files appear before reviewed files. The animation follows standard macOS list behavior.
5. The review progress indicator in the file browser header updates (`AC-crp-file-reviewed-progress-count`).
6. This mechanism works without switching to the file.

**Via keyboard shortcut:**

1. User presses Cmd+Shift+R (global, targets the active file) or presses R when a file row is focused in the file browser.
2. The active file's (or focused file's) reviewed state toggles. All visual updates are identical.
3. VoiceOver announces: "[filename] marked as reviewed" or "[filename] marked as unreviewed".

**Via the Review menu:**

1. User selects Review > Mark Current File as Reviewed from the menu bar.
2. The active file's reviewed state toggles.

### Flow 18: Unmark a Reviewed File (`AC-crp-file-unmark-reviewed`)

1. User sees a file in the reviewed state.
2. User toggles the reviewed state via the context menu ("Mark as Unreviewed"), keyboard shortcut (Cmd+Shift+R or R), or the Review menu.
3. The checkmark disappears, text color returns to normal.
4. The file reorders within its directory (unreviewed files first). If the directory was fully reviewed, the directory checkmark disappears.
5. The progress indicator decrements.

### Flow 19: Keyboard-Only Comment Creation (`AC-crp-keyboard-add-comment`, `NFR-crp-accessibility-keyboard`)

1. User presses Tab to move focus into the code viewer area.
2. User presses Up Arrow / Down Arrow to navigate between lines. The focused line has a visible focus ring.
3. User presses Return or C on the focused line to open the InlineCommentEditor.
4. User types their comment.
5. User presses Cmd+Return to submit, or Escape to cancel.
6. Focus returns to the line in the code viewer.

### Flow 20: Keyboard-Only Line Range Selection

1. User navigates to the start line using arrow keys.
2. User holds Shift and presses Down Arrow to extend the selection (or Shift+Up Arrow to extend upward).
3. Selected lines are highlighted.
4. User presses Return or C to open the InlineCommentEditor for the range.
5. Remainder follows Flow 6.

---

## Component Specs

### Toolbar

Native toolbar integrated with the title bar. Implements `FR-crp-macos-menu-bar`, `FR-crp-macos-keyboard-shortcuts`.

- **Leading items**:
  - **Open** button: SF Symbol `doc.badge.plus`. Label: "Open". Opens the native file open panel (`FR-crp-macos-file-open-panel`). Keyboard shortcut: Cmd+O (via File menu).

- **Center**:
  - **Window Title**: Displays session context per `FR-crp-session-identity`. In slash command mode: "Shepherd -- <project-name>". In standalone mode: "Shepherd".

- **Trailing items**:
  - **Line Wrap** toggle: SF Symbol `text.word.spacing`. Label: "Line Wrap". Toggles line wrapping (`FR-crp-line-wrap`). Displays pressed/active state when wrapping is ON (default). No keyboard shortcut in the toolbar; accessible via View > Toggle Line Wrapping.
  - **Copy Prompt** button: SF Symbol `doc.on.doc`. Label: "Copy Prompt". Copies the prompt to clipboard (`FR-crp-prompt-copy`, `FR-crp-macos-clipboard`). Disabled when no comments exist. Keyboard shortcut: Cmd+Shift+C (via Review menu). When not in slash command mode, this is the primary trailing action.
  - **Done** button (conditional): SF Symbol `checkmark.circle.fill`. Label: "Done". Only rendered in slash command mode (`AC-crp-done-standalone-hidden`, `AC-crp-macos-standalone-no-done`). Disabled when no comments exist (`AC-crp-done-disabled-no-comments`). Sends prompt and closes window (`FR-crp-done-action`, `FR-crp-macos-auto-close`). Keyboard shortcut: Cmd+Return (via Review menu).

- **Customization**: The toolbar supports standard macOS toolbar customization (right-click > Customize Toolbar). Users can add, remove, or rearrange items. The default set is as described above.

- **States**:

  | Toolbar Item | Empty State | File Loaded, No Comments | File Loaded, With Comments |
  |---|---|---|---|
  | Open | Enabled | Enabled | Enabled |
  | Line Wrap | Disabled | Enabled, active (ON) | Enabled, active (ON) |
  | Copy Prompt | Disabled | Disabled | Enabled |
  | Done | Disabled (if visible) | Disabled (if visible) | Enabled (if visible) |

---

### FileDropZone

Handles file loading in the empty state. Implements `FR-crp-file-load`, `FR-crp-macos-file-open-panel`, `FR-crp-macos-drag-drop-finder`.

- **Variants**:
  - `empty-state` -- Resting state with instructions. Fills the entire content area.
  - `drag-hover` -- Files are being dragged over the window.
  - `overlay` -- Used when adding files to an existing session (drop overlay over the code viewer).

- **Visual Structure (empty-state)**:
  ```
  +----------------------------------------------------------------------+
  |                                                                      |
  |                                                                      |
  |                    [doc.badge.plus SF Symbol, 48pt]                  |
  |                                                                      |
  |               Drop files here or press Cmd+O to open                 |
  |                                                                      |
  |                    Accepts any plain-text file                        |
  |              Also accepts pasted text content (Cmd+V)                 |
  |                                                                      |
  |                                                                      |
  +----------------------------------------------------------------------+
  ```
  - Centered vertically and horizontally in the content area.
  - SF Symbol: `doc.badge.plus`, 48pt, secondary label color.
  - Primary text: system font, 17pt, primary label color.
  - Secondary text: system font, 13pt, secondary label color.
  - No explicit "Choose file" or "Paste content" buttons -- macOS users use Cmd+O for file picker and Cmd+V for paste. The drop zone accepts Finder drag-and-drop natively.

- **Visual Structure (drag-hover)**:
  - The entire content area gets a translucent overlay with the system accent color border (3pt, rounded corners matching the window's corner radius).
  - Center text changes to "Drop to load files" with an animated SF Symbol `arrow.down.doc`.
  - The overlay appears and disappears with a brief fade (150ms).

- **Visual Structure (overlay -- adding files to existing session)**:
  ```
  +----------------------------------------------------------------------+
  |                                                                      |
  |    [translucent overlay covering the code viewer area]               |
  |                                                                      |
  |                     Drop to add file(s)                              |
  |                                                                      |
  +----------------------------------------------------------------------+
  ```
  - Semi-transparent overlay (system material) covers the code viewer panel.
  - The file browser sidebar and inspector sidebar remain visible but dimmed.
  - Text: "Drop to add file(s)" centered on the overlay.

- **Behavior**:
  - Drag-and-drop uses the native file promise / pasteboard mechanism. The entire window is the drop target.
  - Binary file detection: Check for null bytes (`0x00`) in the first 8,192 bytes. If found, show a native alert (`AC-crp-binary-file-rejected`).
  - Multiple files dropped: All valid text files are loaded. Binary files rejected individually.
  - Language detection: Infer from file extension. If unknown, default to "Plain Text" (`FR-crp-syntax-highlight`).
  - Paste: Cmd+V in the empty state loads clipboard text as a new "Untitled" file. In the file loaded state, Cmd+V adds clipboard text as a new file if no text input is focused.

- **Accessibility** (`NFR-crp-accessibility-keyboard`):
  - The drop zone instructions mention Cmd+O and Cmd+V as keyboard alternatives.
  - VoiceOver reads: "Drop zone. Press Command O to open files, or Command V to paste text."
  - The drop zone is not itself keyboard-interactive (drag-and-drop is a pointer interaction), but the Open and Paste commands provide full keyboard equivalence.

---

### FileBrowser

Source list style sidebar presenting all loaded files in a nested directory tree. Implements `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `FR-crp-panel-resize`. Only rendered when two or more files are loaded.

- **Position**: Left column of the split view. Default width: 220pt. User-resizable via the native split view divider (`FR-crp-panel-resize`). Full height of the content area. Uses the standard macOS source list background (vibrant under the sidebar material).

- **Resize Behavior** (`FR-crp-panel-resize`, `AC-crp-panel-resize-drag`, `AC-crp-panel-resize-bounds`, `AC-crp-panel-resize-double-click`, `AC-crp-panel-resize-persists`):
  - The split view divider between the file browser and the code viewer is draggable.
  - **Minimum width**: 180pt. Below this, the sidebar stops shrinking.
  - **Maximum width**: 50% of the window width or 500pt, whichever is smaller. This ensures the code viewer always retains adequate space.
  - **Double-click to reset**: Double-clicking the divider resets the file browser to the 220pt default with a smooth animation (`AC-crp-panel-resize-double-click`).
  - **Session persistence**: The width persists within the session. Switching files, adding/removing files, and other interactions do not reset the width. On app relaunch, the width resets to 220pt (`NFR-crp-no-data-persistence`). `AC-crp-panel-resize-persists`

- **Visual Structure (directory tree, `FR-crp-file-reviewed-grouping`)**:

  Mixed reviewed/unreviewed files -- within each directory, unreviewed files appear before reviewed:
  ```
  +-------------------------------+
  | FILES           3/7 reviewed  |
  +-------------------------------+
  | > src/                        |
  |     app.tsx                   |
  |   + utils.ts            [3]  |
  | > lib/                        |
  |     helpers.ts           [1] |
  | + config.json            [1] |
  | + README.md                   |
  +-------------------------------+
  ```
  Note: `+` indicates a checkmark (reviewed indicator), `>` indicates a disclosure triangle (expanded), `[N]` indicates comment count badge.

  Within `src/`, unreviewed `app.tsx` appears before reviewed `utils.ts`.

  When all files are reviewed:
  ```
  +-------------------------------+
  | FILES           5/5 reviewed  |
  +-------------------------------+
  | + > src/                      |
  |   + utils.ts            [3]  |
  |   + app.tsx                   |
  | + > lib/                      |
  |   + helpers.ts           [1] |
  | + config.json            [1] |
  | + README.md                   |
  +-------------------------------+
  ```

  Collapsed directory:
  ```
  +-------------------------------+
  | + > src/          (2 files)   |
  | > lib/                        |
  |     helpers.ts           [1] |
  | + config.json            [1] |
  +-------------------------------+
  ```
  When collapsed, children are hidden and the directory shows "(N files)". When all files in a collapsed directory are reviewed, the directory shows a checkmark.

- **Header Section**: Fixed at the top of the sidebar.
  - **Title row**: "FILES" label (small caps, secondary label color) on the left. Review progress indicator ("3/7 reviewed") on the right, same line. When all files are reviewed, the progress text uses the system green color. `FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-progress-count`.
  - VoiceOver: Progress indicator has live region semantics, announcing "N of M files reviewed" on change.

- **Directory nodes**: Represent directories in the file tree. System font, 12pt, secondary label color. Indented by nesting level (16pt per level). Non-selectable (directories are not files). Click or Return toggles collapse/expand.
  - **Disclosure triangle**: Standard macOS disclosure triangle. Points right when collapsed, down when expanded.
  - **Directory name**: Includes trailing slash (e.g., `src/`). When collapsed, shows "(N files)" summary.
  - **Fully-reviewed indicator** (`FR-crp-file-reviewed-grouping`): When all files within a directory are reviewed, the directory shows a checkmark icon (system green) before the name, and the directory name text is muted. This is important for collapsed directories -- the checkmark communicates that all contents have been reviewed.

- **File nodes (leaves)**: Each loaded file is a clickable row in the tree. Height: 24pt. Indented by nesting level (16pt per level). The row shows:
  - **File icon**: Language-appropriate SF Symbol (e.g., `swift` for Swift, `doc.text` for generic text). When the file is reviewed, a small checkmark badge overlays the icon.
  - **File name**: The bare filename (e.g., `helpers.ts`). System font, 13pt. Truncated with ellipsis if too long.
  - **Comment count badge**: Small rounded badge shown only when commentCount > 0. System accent color background, white text, 10pt. Positioned inline after the file name.
  - **Active indicator**: The active file row is highlighted using the standard macOS source list selection style (system accent color highlight when the sidebar is the focused view, or gray highlight when focus is elsewhere).
  - **Reviewed visual treatment** (`FR-crp-file-reviewed-visual`): When a file is reviewed: checkmark badge on the file icon, muted text for inactive rows. The visual treatment is always visible (not hover-gated).

- **Context Menu** (right-click / Control-click on a file row):
  - "Mark as Reviewed" / "Mark as Unreviewed" (toggle) -- `FR-crp-file-reviewed-toggle`
  - Separator
  - "Remove File" -- `FR-crp-multi-file-remove`

- **Tooltip on hover** (`FR-crp-file-tooltip`, `AC-crp-file-tooltip-full-path`, `AC-crp-file-tooltip-reviewed`): Shows the full untruncated file path, detected language, and review status. Format: `<full-path> -- <language>` or `<full-path> -- <language> -- Reviewed`. For pasted files: "Untitled -- Plain Text". The tooltip uses the native macOS tooltip mechanism (NSView toolTip).

- **File Row States**:

  | State | Background | Text Color | Icon Treatment |
  |---|---|---|---|
  | **Active, unreviewed** | Source list selection highlight (accent) | Primary label color | Normal file icon |
  | **Active, reviewed** | Source list selection highlight (accent) | Primary label color | File icon with checkmark badge |
  | **Inactive, unreviewed** | Transparent | Primary label color | Normal file icon |
  | **Inactive, reviewed** | Transparent | Secondary label color (muted) | File icon with checkmark badge |
  | **Inactive, unreviewed (hover)** | Subtle hover highlight | Primary label color | Normal file icon |
  | **Inactive, reviewed (hover)** | Subtle hover highlight | Secondary label color | File icon with checkmark badge |

  The reviewed visual treatment follows system appearance (light/dark) automatically (`FR-crp-macos-system-appearance`).

- **Keyboard Accessibility** (`NFR-crp-accessibility-keyboard`):
  - The file browser is focusable. Tab moves focus into the sidebar from the toolbar.
  - Up Arrow / Down Arrow moves focus between visible nodes (both directories and files), skipping children of collapsed directories.
  - Right Arrow on a collapsed directory expands it. On an expanded directory, moves focus to first child. On a file node, no effect.
  - Left Arrow on an expanded directory collapses it. On a child node, moves focus to parent directory.
  - Return or Space on a file node selects (activates) it. On a directory node, toggles collapse/expand.
  - Delete or Backspace on a focused file node removes that file (with confirmation if it has comments).
  - R on a focused file node toggles reviewed state (`FR-crp-file-reviewed-toggle`).

- **VoiceOver**:
  - Container: tree role with "File browser" label.
  - Directory nodes: tree item role with expanded/collapsed state.
  - File nodes: tree item role with selected state. When reviewed, includes "Reviewed" in the description.
  - Progress indicator: live region, announces changes.

---

### ActiveFilePath

A compact breadcrumb-style bar at the top of the Code Viewer Panel showing the full path of the active file. Implements `FR-crp-active-file-path`, `AC-crp-active-file-path-visible`, `AC-crp-active-file-path-switches`.

- **Visibility**: Only rendered in multi-file mode (2+ files loaded). Not rendered in single-file mode (`AC-crp-active-file-path-single-file`).

- **Visual Structure**:
  ```
  +------------------------------------------------------+
  | src / components / FileBrowser.tsx                     |
  +------------------------------------------------------+
  ```
  - Height: 28pt. System font, 12pt.
  - Path segments are separated by " / " with secondary label color separators.
  - The final segment (file name) uses primary label color. Parent segments use secondary label color.
  - Separator between the path bar and the code viewer below: 1pt hairline, separator color.

- **Behavior**:
  - Updates immediately when the active file changes.
  - Read-only, non-interactive. The path is for display only.
  - For pasted files with no path: shows "Untitled" or the user-given name.
  - Truncation: if the path is too long, the leading segments are truncated with an ellipsis: "... / nested / VeryLongComponentName.tsx".

---

### CodeViewer

Read-only code display with line numbers and a comment gutter. Implements `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`, `FR-crp-line-wrap`.

- **Visual Structure**:
  ```
  +----+---+--------------------------------------------------+
  | Ln | G |  Code Content                                     |
  +----+---+--------------------------------------------------+
  |  1 |   |  import { useState } from 'react';               |
  |  2 | * |  function App() {                                 |
  |  3 |   |    const [count, setCount] = useState(0);         |
  |  4 |   |    return <div>{count}</div>;                     |
  |  5 |   |  }                                                |
  +----+---+--------------------------------------------------+
  ```
  - **Line numbers column** (Ln): Fixed width, right-aligned. Monospace font, secondary label color. Clickable to create comments. `FR-crp-file-display`
  - **Gutter column** (G): Narrow column between line numbers and code. Shows comment indicators for annotated lines. `FR-crp-comment-indicator`
  - **Code content area**: Monospace font. Syntax highlighting applied based on detected language (`FR-crp-syntax-highlight`).

- **Line Wrapping** (`FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`, `AC-crp-line-wrap-preserves-line-numbers`, `AC-crp-line-wrap-comment-target`, `AC-crp-line-wrap-default-on`, `AC-crp-line-wrap-persists-session`):
  - Default: ON (wrapping enabled).
  - When ON: Long lines wrap within the code content area. No horizontal scrollbar. Each line number appears once, aligned to the first visual row. The gutter also aligns to the first visual row.
  - When OFF: Long lines extend beyond the visible area. The code content area scrolls horizontally. Line numbers and gutter remain fixed.
  - Toggle via the toolbar Line Wrap button or View > Toggle Line Wrapping.
  - Clicking any visual row of a wrapped line targets the correct logical line (`AC-crp-line-wrap-comment-target`).
  - The wrapping preference persists within the session (`AC-crp-line-wrap-persists-session`).

- **Comment Indicators** (`FR-crp-comment-indicator`):
  - Lines with one or more comments show a filled circle (system accent color) in the gutter.
  - When hovering over an uncommented line, a faint "+" icon appears in the gutter.

- **Line Selection for Range Comments**:
  - Click-drag in the gutter or line number column selects a contiguous range.
  - Shift+click extends the selection.
  - Selected lines are highlighted with the system selection color.

- **Syntax Highlighting** (`FR-crp-syntax-highlight`):
  - Supports the required 13 languages (JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, HTML, CSS, JSON, YAML, Markdown).
  - Colors follow the system appearance (light/dark mode) automatically (`FR-crp-macos-system-appearance`, `AC-crp-macos-appearance-follows-system`).
  - If the language cannot be detected, the file is displayed as plain text.

- **Scroll Behavior**:
  - The code viewer scrolls vertically independently of the file browser and inspector.
  - Scroll position is preserved per file when switching between files in multi-file mode.

---

### InlineCommentEditor

Appears inline within the CodeViewer when creating or editing a comment. Implements `FR-crp-line-comment-create`, `FR-crp-line-comment-edit`.

- **Visual Structure**:
  ```
  +--------------------------------------------------------------+
  |                                                              |
  |  [Text editor area, auto-focused]                            |
  |                                                              |
  +--------------------------------------------------------------+
  |  [Cancel]                                   [Comment / Save] |
  +--------------------------------------------------------------+
  ```
  - Positioned directly below the target line (or the last line of a range).
  - The text editor area: native text view with system font. Minimum height: 60pt. Grows with content. Placeholder text: "Add your comment..."
  - Buttons: "Cancel" (secondary) on the left, "Comment" or "Save" (accent/default) on the right.
  - For range comments, a label "Lines N-M" appears above the text editor.
  - The editor has a distinct background (slightly tinted, matching the system accent at very low opacity) and a thin border to distinguish it from the code.

- **Behavior**:
  - Auto-focuses the text editor when opened.
  - Cmd+Return submits the comment (context-specific, only active when the editor has focus).
  - Escape cancels and closes the editor.
  - When editing an existing comment, the text editor is pre-populated. The button reads "Save" instead of "Comment".
  - If the user clicks outside the editor while it has content, the editor remains open (no accidental dismissal). The user must explicitly Cancel or Save.
  - Undo (Cmd+Z) and Redo (Cmd+Shift+Z) work within the text editor (`FR-crp-macos-keyboard-shortcuts`).

---

### CommentBubble

Displays a submitted comment attached to a line or line range.

- **Visual Structure**:
  ```
  +--------------------------------------------------------------+
  | Lines 10-15 (range label, if applicable)         [Edit][Del] |
  | Extract this to a helper function                             |
  +--------------------------------------------------------------+
  ```
  - Positioned directly below the target line (or range).
  - Background: secondary system background. Border: hairline, separator color. Rounded corners.
  - Comment text: system font, 13pt, primary label color.
  - Range label (if applicable): "Lines N-M" in secondary label color, 11pt.
  - **Edit** button: appears on hover or when the bubble has keyboard focus. SF Symbol `pencil`. Tooltip: "Edit comment".
  - **Delete** button: appears on hover or when the bubble has keyboard focus. SF Symbol `trash`. Tooltip: "Delete comment". Destructive color (system red) on hover.
  - Double-clicking the comment text also enters edit mode.

- **Accessibility**:
  - VoiceOver reads: "Comment on line N: [comment text]. Actions available: Edit, Delete."
  - For range comments: "Comment on lines N through M: [comment text]."
  - Edit and Delete buttons are keyboard-accessible when the bubble is focused.

---

### ReviewContextPanel (Per-File Context)

Displays per-file review context within the Code Viewer Panel. Implements `FR-crp-review-context-display`, `FR-crp-review-context-per-file`, `AC-crp-context-per-file-visible`, `AC-crp-context-per-file-switches`.

- **Visibility**: Only rendered when review context data is available for the active file. Not rendered when context is absent (`AC-crp-context-graceful-missing`).

- **Visual Structure**:
  ```
  +--------------------------------------------------------------+
  | [v] File Context                                              |
  +--------------------------------------------------------------+
  | What Changed                                                  |
  | Modified the authentication middleware to add rate limiting.  |
  | Added a new `rateLimiter` function.                           |
  +--------------------------------------------------------------+
  | Review Feedback                                               |
  | The rate limiting implementation looks correct but consider   |
  | using a sliding window algorithm for more accurate tracking.  |
  +--------------------------------------------------------------+
  ```
  - Collapsible: clicking the disclosure button or header row toggles visibility. When collapsed, only the header "File Context" is shown with a right-pointing disclosure indicator.
  - **Neutral context** ("What Changed"): Standard text styling. System font, 13pt. Informational appearance -- no special color treatment.
  - **Review feedback**: Distinct styling to indicate it is the agent's opinion (`AC-crp-context-neutral-vs-review`). Uses a tinted background (subtle system yellow or orange tint) and an icon (SF Symbol `lightbulb`) before the section header. This visually separates factual changes from subjective feedback.
  - Both sections are read-only (`AC-crp-context-readonly`).
  - The collapse state persists across file switches (`AC-crp-context-sidebar-collapse`).

---

### ReviewContextSection (Overall Changeset Context -- Inspector Sidebar)

Displays the overall changeset context in the Inspector Sidebar. Implements `FR-crp-review-context-overall`, `FR-crp-review-context-collapsible`, `AC-crp-context-overall-visible`, `AC-crp-context-sidebar-collapse`.

- **Visibility**: Only rendered when overall review context data is available. Not rendered in standalone mode.

- **Visual Structure**:
  ```
  +----------------------------------------------------+
  | [v] Review Context                                  |
  +----------------------------------------------------+
  | Changeset Summary                                   |
  | This changeset adds rate limiting to the auth       |
  | middleware and updates the configuration system.     |
  +----------------------------------------------------+
  | Agent Feedback                                      |
  | [lightbulb icon]                                    |
  | Overall the changes look good. The rate limiting    |
  | approach is sound. Consider adding metrics.         |
  +----------------------------------------------------+
  ```
  - Collapsible: clicking the disclosure button or header toggles between expanded and collapsed. When collapsed, shows only "Review Context" with a right-pointing disclosure indicator.
  - **Neutral context** ("Changeset Summary"): Standard text styling. System font, 13pt.
  - **Review feedback** ("Agent Feedback"): Distinct styling with a tinted background and lightbulb icon, matching the per-file review feedback treatment (`AC-crp-context-neutral-vs-review`).
  - Both sections are read-only.
  - The collapse state persists during the session -- switching files does not reset it (`AC-crp-context-sidebar-collapse`).
  - This section is visible regardless of which file is active (`FR-crp-review-context-overall`).

---

### Overall Comment Editor

Text editor for the Overall Comment. Implements `FR-crp-prompt-preamble`, `AC-crp-overall-comment-label`.

- **Visual Structure**:
  ```
  +----------------------------------------------------+
  | Overall Comment                                     |
  | +------------------------------------------------+ |
  | | Add an overall comment for all files in this   | |
  | | review...                                       | |
  | |                                                 | |
  | +------------------------------------------------+ |
  | This comment applies to all files and appears at   |
  | the top of the generated prompt.                   |
  +----------------------------------------------------+
  ```
  - **Label**: "Overall Comment" (system font, 13pt, bold). `AC-crp-overall-comment-label`
  - **Text editor**: Native text view. Placeholder text: "Add an overall comment for all files in this review..." Minimum height: 60pt. Grows with content up to a maximum of 200pt, then scrolls internally.
  - **Help text**: Below the editor, secondary label color, 11pt: "This comment applies to all files and appears at the top of the generated prompt."
  - **Behavior**: Changes are stored in application state immediately (no explicit save). When the text changes and comments exist, the prompt regenerates automatically to include the updated overall comment (`AC-crp-overall-comment-in-prompt`). A value of only whitespace is treated as empty.

---

### PromptPreview

Read-only display of the auto-generated prompt. Implements `FR-crp-prompt-preview`, `FR-crp-prompt-format`, `FR-crp-multi-file-prompt-format`.

- **Visual Structure**:
  ```
  +----------------------------------------------------+
  | Preview              All Comments                   |
  +----------------------------------------------------+
  |                                                     |
  | ## Instructions                                     |
  |                                                     |
  | Refactor for readability                            |
  |                                                     |
  | ## File: utils.ts (typescript)                      |
  |                                                     |
  | ### Requested Changes                               |
  |                                                     |
  | ```typescript                                       |
  | const x = foo();                                    |
  | ```                                                 |
  | Rename this variable to something descriptive       |
  |                                                     |
  +----------------------------------------------------+
  ```
  - Scrollable text view. Monospace font for the prompt content to reflect the exact text that will be copied.
  - Read-only. The user cannot edit the preview.
  - Updates in real-time as comments are added, edited, or deleted (`FR-crp-prompt-generate`).
  - When no comments exist, shows a placeholder: "Add comments to the code to generate your AI prompt."
  - The prompt preview content is identical to what is copied to the clipboard (`AC-crp-preview-matches-copy`).

---

### CommentSummary

Summary view of all comments across all files. Implements `FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-realtime`, `AC-crp-comment-summary-empty`.

- **Visual Structure** (with comments):
  ```
  +----------------------------------------------------+
  | Preview              All Comments                   |
  +----------------------------------------------------+
  |                                                     |
  | utils.ts                                            |
  |   Line 3: Rename this variable                      |
  |   Lines 10-12: Extract to helper function           |
  |   Line 25: Add error handling                       |
  |                                                     |
  | helpers.ts                                          |
  |   Line 5: Use async/await here                      |
  |                                                     |
  +----------------------------------------------------+
  ```
  - Groups comments by file. File name as a header (bold, 13pt). Each comment shows: line number(s) and comment text.
  - Files with zero comments are not listed.
  - Read-only. Clicking a comment could optionally scroll to it in the code viewer (nice-to-have, not required).
  - Updates in real-time as comments change (`AC-crp-comment-summary-realtime`).

- **Empty state** (`AC-crp-comment-summary-empty`):
  ```
  +----------------------------------------------------+
  | Preview              All Comments                   |
  +----------------------------------------------------+
  |                                                     |
  |              No comments yet                        |
  |     Add comments in the code viewer to see          |
  |     them listed here.                               |
  |                                                     |
  +----------------------------------------------------+
  ```
  - Centered message. Secondary label color. SF Symbol `text.bubble` above the text.

---

### Confirmation Dialogs

Native macOS alert sheets for destructive actions. Drop from the window title bar.

- **Clear Session** (`AC-crp-clear-confirmation`):
  - Title: "Clear Session?"
  - Body (single file): "This will remove the loaded file, all N comments, and the overall comment. This cannot be undone."
  - Body (multi-file): "This will remove all M loaded files, all N comments, and the overall comment. This cannot be undone."
  - Buttons: "Cancel" (default), "Clear Session" (destructive).

- **Remove File** (`AC-crp-multi-file-remove-with-comments`):
  - Title: "Remove File?"
  - Body: "Remove \"[filename]\"? This will also remove its N comments. This cannot be undone."
  - Buttons: "Cancel" (default), "Remove" (destructive).

- **Done -- Handoff Failed** (`AC-crp-done-fallback-clipboard`):
  - Title: "Could Not Send to Agent"
  - Body: "The prompt was copied to your clipboard. Switch to your terminal and paste it manually."
  - Buttons: "OK" (default).

---

## Menu Bar Design

Implements `FR-crp-macos-menu-bar`, `FR-crp-macos-keyboard-shortcuts`, `AC-crp-macos-menu-shortcuts`.

### Shepherd (App Menu)

| Menu Item | Shortcut | Behavior |
|---|---|---|
| About Shepherd | -- | Shows the About panel |
| Preferences... | Cmd+, | Opens the Preferences window (future) |
| -- (separator) | -- | -- |
| Hide Shepherd | Cmd+H | Standard hide |
| Hide Others | Cmd+Option+H | Standard hide others |
| Show All | -- | Standard show all |
| -- (separator) | -- | -- |
| Quit Shepherd | Cmd+Q | Quits the application |

### File

| Menu Item | Shortcut | Behavior | State |
|---|---|---|---|
| Open... | Cmd+O | Opens the native file open panel | Always enabled |
| -- (separator) | -- | -- | -- |
| Close Window | Cmd+W | Closes the current window | Always enabled |

### Edit

| Menu Item | Shortcut | Behavior | State |
|---|---|---|---|
| Undo | Cmd+Z | Undo last comment edit | Enabled when undo is available |
| Redo | Cmd+Shift+Z | Redo last undone edit | Enabled when redo is available |
| -- (separator) | -- | -- | -- |
| Cut | Cmd+X | Standard cut (text fields) | Enabled when text is selected in an editable field |
| Copy | Cmd+C | Standard copy (text fields) | Enabled when text is selected |
| Paste | Cmd+V | Pastes file content from clipboard into the session | Context-dependent (see below) |
| Select All | Cmd+A | Standard select all | Enabled in text fields |

**Paste behavior**: When no text input is focused, Cmd+V loads clipboard text as a new file into the session (implements the paste loading mechanism from `FR-crp-file-load`). When a text input is focused (Overall Comment editor or InlineCommentEditor), Cmd+V performs standard text paste into that field.

### View

| Menu Item | Shortcut | Behavior | State |
|---|---|---|---|
| Toggle Line Wrapping | -- | Toggles line wrap on/off | Checkmark when ON (`FR-crp-line-wrap`) |
| -- (separator) | -- | -- | -- |
| Toggle Sidebar | Cmd+Option+S | Shows/hides the file browser sidebar | Enabled in multi-file mode |
| Toggle Inspector | Cmd+Option+I | Shows/hides the inspector sidebar | Always enabled when files are loaded |
| -- (separator) | -- | -- | -- |
| Enter Full Screen | Cmd+Control+F | Standard full-screen toggle | Always enabled |

### Review

| Menu Item | Shortcut | Behavior | State |
|---|---|---|---|
| Copy Prompt | Cmd+Shift+C | Copies the prompt to clipboard | Enabled when >= 1 comment (`AC-crp-macos-menu-copy-disabled`) |
| Done | Cmd+Return | Sends prompt and closes window | Only in slash command mode, enabled when >= 1 comment |
| -- (separator) | -- | -- | -- |
| Next Comment | Cmd+] | Navigates to the next comment | Enabled when >= 1 comment (`FR-crp-comment-navigation`) |
| Previous Comment | Cmd+[ | Navigates to the previous comment | Enabled when >= 1 comment |
| -- (separator) | -- | -- | -- |
| Mark Current File as Reviewed | Cmd+Shift+R | Toggles review status of active file | Enabled when a file is loaded (`FR-crp-file-reviewed-toggle`) |
| -- (separator) | -- | -- | -- |
| Clear Session | -- | Clears all files and comments | Enabled when files are loaded |

### Window

Standard macOS Window menu (Minimize, Zoom, Bring All to Front, window list).

### Help

| Menu Item | Shortcut | Behavior |
|---|---|---|
| Shepherd Help | -- | Opens help documentation (if available) |

---

## Accessibility

Implements `NFR-crp-accessibility-keyboard` and macOS accessibility conventions.

### VoiceOver Support

- All controls have appropriate accessibility labels and roles.
- The file browser uses tree semantics (tree, treeitem) with proper expanded/collapsed state.
- Comment indicators in the gutter announce the presence and count of comments on each line.
- The prompt preview announces updates via a live region.
- The review progress indicator announces changes (e.g., "3 of 7 files reviewed").
- Context sections announce their collapsed/expanded state.
- Destructive actions (Clear Session, Remove File) are announced with their full consequences before the user confirms.

### Full Keyboard Navigation

All core workflows are achievable via keyboard alone:

| Workflow | Keyboard Path |
|---|---|
| Load a file | Cmd+O (open panel) or Cmd+V (paste from clipboard) |
| Navigate between files | Tab into file browser, Up/Down arrows, Return to select |
| Add a comment | Tab into code viewer, Up/Down to navigate lines, Return to open editor, Cmd+Return to submit |
| Edit a comment | Tab to CommentBubble, Return to edit, Cmd+Return to save |
| Delete a comment | Tab to CommentBubble, Delete key |
| Select a line range | Shift+Up/Down in the code viewer |
| Copy the prompt | Cmd+Shift+C |
| Navigate between comments | Cmd+] (next), Cmd+[ (previous) |
| Mark file as reviewed | Cmd+Shift+R |
| Done (send to agent) | Cmd+Return (via Review menu) |
| Clear session | Review > Clear Session (menu bar) |
| Toggle line wrapping | View > Toggle Line Wrapping (menu bar) |

### Reduced Motion

- When the "Reduce motion" preference is enabled in macOS Accessibility settings, all animations (file row transitions, highlight pulses, toolbar icon changes) are replaced with instant state changes.

### High Contrast

- When "Increase contrast" is enabled in macOS Accessibility settings, borders, separators, and focus rings become more prominent. The application uses system colors that automatically adapt to high contrast mode.

---

## Responsive Behavior

Implements `FR-crp-macos-window-management`.

### Minimum Window Size

800 x 600 points. The window cannot be resized below this (`FR-crp-macos-window-management`). This ensures all three panels (file browser, code viewer, inspector) remain usable.

### Panel Adaptation

- **File browser sidebar**: Can be collapsed via View > Toggle Sidebar (Cmd+Option+S) to give the code viewer more width. When collapsed, the sidebar is completely hidden. The split view divider handles the animation natively.
- **Inspector sidebar**: Can be collapsed via View > Toggle Inspector (Cmd+Option+I). When collapsed, the code viewer takes the full remaining width.
- **Both collapsed**: The code viewer occupies the full window width (minus the toolbar).
- When the window is narrowed:
  - The code viewer has highest priority for width.
  - The inspector sidebar maintains its minimum usable width (240pt) or collapses.
  - The file browser sidebar maintains its minimum width (180pt) or collapses.

### Full-Screen Support

The application supports macOS full-screen mode (Cmd+Control+F). All panels scale appropriately within the full-screen space. The toolbar remains visible.

### Window Restoration (`AC-crp-macos-window-restore`)

The application remembers window position and size between launches, restoring the last-used dimensions when a new window opens. This is standard macOS window behavior. Session data (files, comments) is NOT persisted, consistent with `NFR-crp-no-data-persistence`.

### Multiple Windows (`AC-crp-macos-window-open`, `AC-crp-macos-multi-window-independent`)

Each session opens in its own independent window. Multiple windows can be open simultaneously. Each window operates independently -- actions in one window do not affect another. The Window menu lists all open windows.
