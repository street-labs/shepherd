# Code Review Prompt Generator

## Overview

An application that lets developers load one or more source files with line numbers, add inline comments on specific lines (similar to a GitHub pull request review), and then generate a single structured prompt that aggregates all files and their comments. The generated prompt is designed to be copied and fed to an AI coding assistant, giving the AI full context about what changes are needed and where across the entire changeset.

The core workflow is: **load file(s) --> annotate lines --> copy prompt --> paste into AI agent**. Multiple files can be loaded into a single session, each maintaining its own comments independently. The prompt is automatically generated and kept current as comments are added to any file, so there is no explicit "generate" step.

This bridges the gap between a developer's code review observations and an actionable AI prompt, eliminating the need to manually describe file context, line numbers, and desired changes — even when the review spans multiple files.

## User Stories

### US-1: View a file with line numbers
**As a** developer, **I want to** load and view a source file with numbered lines in a readable format, **so that** I can reference specific lines when making comments.

### US-2: Add inline comments on specific lines
**As a** developer, **I want to** click on a line number and add a comment attached to that line, **so that** I can annotate exactly which parts of the code need changes.

### US-3: Prompt is automatically assembled as I annotate
**As a** developer, **I want** the structured prompt to be automatically assembled and updated as I add, edit, or delete comments, **so that** I can copy it at any time and feed it to an AI coding assistant with full context.

### US-4: Copy the prompt to clipboard
**As a** developer, **I want to** copy the generated prompt to my clipboard with one click, **so that** I can quickly paste it into my AI agent without manual selection.

### US-5: Edit and delete placed comments
**As a** developer, **I want to** edit or remove comments I've already placed, **so that** I can refine my review before generating the final prompt.

### US-6: Customize the generated prompt
**As a** developer, **I want to** add a high-level instruction or context preamble to the generated prompt, **so that** I can guide the AI's overall approach in addition to the line-specific comments.

### US-7: Send the prompt back to the AI agent automatically
**As a** developer, **I want to** click "Done" when I've finished annotating, **so that** the generated prompt is automatically sent back to my AI agent without manual copy-paste.

### US-8: Load multiple files for review
**As a** developer, **I want to** load multiple files into the CRPG at the same time, **so that** I can annotate changes across several files and generate a single combined prompt.

### US-9: Navigate between loaded files
**As a** developer, **I want to** see which files are loaded and switch between them, **so that** I can review and comment on each file without losing my work on others.

### US-10: Generate a combined multi-file prompt
**As a** developer, **I want** the generated prompt to include all files and their comments in a single structured output, **so that** the AI agent has full context across the entire changeset.

### US-11: See review context alongside files
**As a** developer reviewing files in the CRPG, **I want to** see what changed in each file and the agent's review feedback without switching back to the terminal, **so that** I have all the context I need right where I'm doing my review.

### US-12: Track review progress across files
**As a** developer reviewing a multi-file changeset, **I want to** mark files as "reviewed" and see my progress through the file list, **so that** I can keep track of which files I've finished looking at and how much of the review remains.

### US-13: See all comments in one place
**As a** developer reviewing multiple files, **I want to** see a summary of all my comments across all files in one place, **so that** I can verify the complete set of feedback before sending it to the AI agent.

## Requirements

### Functional Requirements

#### `FR-crp-file-load` -- Load a file for review
The user can load a file into the viewer by either pasting file content into a text area, uploading a file from their local filesystem via a file picker, or dragging and dropping a file onto the application. The application must accept any plain-text file regardless of extension. When the session already has one or more files loaded, loading a new file adds it to the session rather than replacing the existing file(s). When multiple files are dropped simultaneously, all files are loaded into the session. Binary files are detected by scanning the first 8,192 bytes (or the entire file if shorter) for null bytes (`0x00`); files containing null bytes are rejected with an error message. This is a deliberate trade-off that may reject rare text files containing legitimate null bytes, but it prevents garbled display of binary content.

#### `FR-crp-file-display` -- Display file with line numbers
The loaded file is displayed in a read-only viewer with sequential line numbers starting at 1. Each line is individually addressable (clickable). The viewer must preserve the original indentation, whitespace, and line breaks of the source file in a readable format suitable for code. By default, long lines wrap visually within the code content area (`FR-crp-line-wrap`). The user can toggle wrapping off to enable horizontal scrolling instead.

#### `FR-crp-line-wrap` -- Toggle line wrapping in the code viewer
The user can toggle line wrapping on or off in the code viewer. When line wrapping is enabled, long lines wrap visually within the code content area so that no horizontal scrollbar is needed for the code. Wrapped lines do not create new line numbers — each line number corresponds to a single logical line in the source file and appears only once, aligned to the first visual row of the wrapped content. The gutter (comment indicators) also aligns with the first visual row. Line wrapping does not affect commenting behavior — clicking on any visual row of a wrapped line targets the same logical line number. The toggle preference persists within the session (consistent with `NFR-crp-no-data-persistence`) — switching files and switching back does not reset the setting. The default state is wrapping ON (line wrapping enabled), so users can always read long lines without horizontal scrolling out of the box. When wrapping is disabled, the code content area uses horizontal scrolling for long lines. The gutter and line-number columns remain unaffected by the toggle.

#### `FR-crp-syntax-highlight` -- Syntax highlighting
The file viewer applies syntax highlighting based on the detected or specified language. The application must support at minimum these 13 languages: JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, HTML, CSS, JSON, YAML, and Markdown. Multiple file extensions (e.g., `.js`, `.jsx`, `.mjs`, `.cjs`) may map to the same language. If the language cannot be detected, the file is displayed as plain text (the fallback) without highlighting.

#### `FR-crp-line-comment-create` -- Create an inline comment
The user can select any line number to open a comment input box anchored to that line. The comment input accepts free-form text. After submitting, the comment is visually attached to that line in the viewer. Multiple comments can be attached to the same line.

#### `FR-crp-line-comment-edit` -- Edit an existing comment
The user can click on an existing comment to edit its text. The edit is applied in place without changing the comment's line association.

#### `FR-crp-line-comment-delete` -- Delete a comment
The user can delete any existing comment. After deletion, the comment is removed from the viewer and will not appear in the generated prompt. If a line has no remaining comments, the line returns to its uncommented visual state.

#### `FR-crp-comment-indicator` -- Visual indicators for commented lines
Lines that have one or more comments attached display a distinct visual indicator in the gutter (such as a colored marker or icon) so the user can see at a glance which lines are annotated.

#### `FR-crp-comment-count` -- Display total comment count
The application displays the current total number of comments across all loaded files somewhere persistently visible, so the user knows how many annotations they have placed. This is a global count spanning every file in the session, not a per-file count (though per-file counts may also be shown via `FR-crp-multi-file-nav`).

#### `FR-crp-prompt-preamble` -- Overall Comment (formerly "Preamble")
The user can write an optional "Overall Comment" that provides high-level context or instructions applying to the entire batch of files (e.g., "Refactor this function to use async/await" or "Fix the security vulnerability in the authentication logic"). The UI label for this field is **"Overall Comment"** (not "Preamble"). The field must make it clear that this text applies to all files in the session and will be included at the top of the generated prompt. Internally this field is still the preamble and appears in the generated prompt's "Instructions" section, unchanged in behavior. The key improvement is labeling clarity — "Preamble" was confusing because users did not understand that it applied globally or that it was included in the prompt. A value consisting only of whitespace is treated as empty and will not appear in the generated prompt.

#### `FR-crp-prompt-generate` -- Automatically generated aggregated prompt
The prompt is automatically regenerated whenever the user adds, edits, or deletes a comment on any loaded file, or modifies the preamble. There is no manual "Generate" button. The prompt updates reactively and is always current as long as at least one comment exists on any file. When all comments across all files are removed, the prompt preview clears. The automatically generated prompt is a single structured text that aggregates comments across all loaded files:
1. The preamble (if provided) — shared across all files
2. For each file that has comments: the file path and language, followed by each comment paired with the actual code snippet it references, listed in source order
3. Files without comments are omitted from the prompt

The prompt is formatted so an AI agent can understand the file context and the specific changes requested. Comments are paired with code snippets rather than line numbers, because line numbers change as the file is edited and would be stale by the time the AI processes the prompt. Generation must complete within 300ms (`NFR-crp-prompt-gen-time`) so the UI feels instant. See `FR-crp-multi-file-prompt` and `FR-crp-multi-file-prompt-format` for multi-file prompt details.

#### `FR-crp-prompt-preview` -- Live prompt preview
The full automatically generated prompt is always visible in a read-only preview panel that updates in real-time as comments are added, edited, or deleted. The preview displays the exact text that will be copied, including all formatting. Because the prompt is automatically generated, the preview is always current and requires no user action to refresh.

#### `FR-crp-prompt-copy` -- Copy prompt to clipboard
The user can copy the generated prompt to the system clipboard with a single button click. The application displays a confirmation message (e.g., "Copied to clipboard") after a successful copy.

#### `FR-crp-prompt-format` -- Structured prompt format
The generated prompt must follow a consistent, machine-readable structure. For a single file with comments, the format must include:
- An "Instructions" section containing the preamble text (if provided)
- A "File" heading with the file name (if known) and language (e.g., `## File: utils.ts (typescript)`)
- A "Requested Changes" section listing each comment paired with the code snippet it references
- Each comment formatted as a fenced code block containing the relevant source code, followed by the comment text on the next line
- Comments listed in the order they appear in the source file

The prompt does not include the full file content or line numbers. Instead, each comment is paired directly with the code snippet it references. This ensures the prompt remains accurate even if line numbers shift during editing.

When multiple files have comments, the format extends to include multiple file sections. See `FR-crp-multi-file-prompt-format` for the multi-file structure.

#### `FR-crp-done-action` -- Done action that signals annotation is complete
When the user clicks "Done", the combined multi-file prompt (same content as what Copy would produce) is sent to the local server for handoff back to the AI agent. The prompt is also copied to the system clipboard as a fallback. The Done button is only enabled when at least one inline comment exists on any file (same condition as the Copy button per `FR-crp-prompt-copy`). After a successful send, the application attempts to close its window. If the window cannot be closed (platform restrictions), the application shows a confirmation state indicating the prompt has been sent and instructs the user to switch back to the terminal. The Done button is only visible when the CRPG is running in slash command mode (served by the local server); when loaded standalone (paste/upload/drag-and-drop), the Done button is not shown and the Copy button remains the primary action.

#### `FR-crp-prompt-handoff` -- Prompt handoff to agent via server
When the Done action is triggered, the CRPG sends the generated prompt text to the local server for handoff back to the AI agent, including the session ID. The server writes this to the session-scoped output location (`~/.shepherd/sessions/<session-id>/prompt-output.md`). The transport mechanism is an engineering decision. This is only available in slash command mode, not when loaded standalone. If the handoff fails, the prompt is still copied to the clipboard and the user is informed to paste manually.

#### `FR-crp-session-identity` -- Display session context in window title
When the CRPG is launched via the slash command with a session ID, it displays the session context (working directory or project name) in the application window title. This allows users to distinguish between multiple concurrent CRPG sessions at a glance (e.g., "Shepherd — myproject" vs. "Shepherd — other-repo"). When the CRPG is used in standalone mode (no session ID), the window title uses a generic label (e.g., "Shepherd").

#### `FR-crp-clear-session` -- Clear / reset session
The user can clear the current session — removing ALL loaded files, all comments across all files, and the preamble — and return to the initial empty state. This is the "nuclear option" that resets everything. The application must ask for confirmation before clearing if any comments exist on any file. For removing an individual file without clearing the entire session, see `FR-crp-multi-file-remove`. Clearing a session affects only the current window's in-memory state. Other concurrent sessions (in other windows with different session IDs) are not affected.

#### `FR-crp-filename-display` -- Display file name
When a file is loaded via upload or drag-and-drop, the application displays the file name above or near the viewer. When content is pasted, the user can optionally provide a file name.

#### `FR-crp-line-range-comment` -- Comment on a range of lines
The user can select a contiguous range of lines and attach a single comment to that range, rather than only a single line. The generated prompt must indicate the full line range for such comments.

#### `FR-crp-comment-navigation` -- Navigate between comments
The user can step through comments sequentially (next/previous) to review them in line order. Navigating to a comment scrolls the viewer to the relevant line and highlights it. Navigation wraps around: pressing "next" on the last comment navigates to the first comment, and pressing "previous" on the first comment navigates to the last comment.

#### `FR-crp-multi-file-load` -- Load multiple files for review
The user can load additional files into an existing session. Each file is loaded independently (paste, upload, drag-and-drop, or via the slash command API). Files accumulate in the session — loading a new file does not replace the current one. Each loaded file maintains its own set of comments, line numbers, and syntax highlighting independently. There is no hard limit on the number of files, but performance may degrade past 20 files (consistent with `NFR-crp-large-file-perf`).

#### `FR-crp-multi-file-nav` -- Navigate between loaded files
The application provides a file browser sidebar panel that presents all loaded files in a **nested directory tree** and lets the user switch between them. Files are organized under their parent directories, showing the full directory hierarchy. Directories are displayed as collapsible tree nodes; files are leaf nodes under their parent directory. The tree structure makes it immediately clear where each file is located — files with the same name in different directories (e.g., `src/utils/helpers.ts` and `lib/helpers.ts`) are naturally distinguished by their position in the tree. The currently active file is displayed in the main viewer. Switching files preserves all comments and state for the previously viewed file. Each file node in the tree must show: (a) the file name, (b) the number of comments on that file, and (c) which file is currently active (highlighted). Files loaded via paste (with no directory path) appear at the root level of the tree or under a "(pasted)" group. Directories can be collapsed and expanded to manage visual space; the collapse state persists during the session. The sidebar layout scales naturally to sessions with many files (10+) because nested directories keep the tree compact.

#### `FR-crp-multi-file-remove` -- Remove a file from the session
The user can remove an individual file from the session without clearing the entire session. Removing a file also removes all comments associated with it. If the removed file was the active file, the application switches to another loaded file (or returns to the empty state if no files remain). If the file has comments, a confirmation is shown before removal.

#### `FR-crp-multi-file-prompt` -- Combined multi-file prompt generation
When multiple files are loaded with comments, the generated prompt includes all files and their comments in a single structured output. The format extends `FR-crp-prompt-format` with multiple file sections — one per file that has comments. Files without comments are omitted from the prompt. Files appear in the prompt in the order they were loaded. The prompt is automatically regenerated whenever any comment is added, edited, or deleted on any file.

#### `FR-crp-multi-file-prompt-format` -- Multi-file prompt format
The combined prompt follows this structure: (1) An "Instructions" section with the preamble (if provided) — shared across all files, not per-file; (2) For each file that has comments: a "File" heading with the file name and language, followed by a "Requested Changes" subsection listing each comment paired with its code snippet in source order; (3) Comments within each file are ordered by line number; files are ordered by their position in the file list. The preamble applies globally to the entire review, not per-file.

#### `FR-crp-review-context-receive` -- Receive context data from the agent
The CRPG must accept structured review context data passed from the shepherd-review command. The data includes overall changeset context and per-file context, each split into two parts: neutral context and review feedback. Per-file context is keyed by file path. The mechanism for receiving this data (URL params, file-based, API endpoint) is an engineering decision. The CRPG gracefully handles missing context — if no context data is provided (standalone mode, `/shepherd` single file), the context UI is simply not shown and the CRPG works exactly as before.

#### `FR-crp-review-context-display` -- Display review context in the CRPG
When the CRPG receives review context data (from the shepherd-review command), it displays the context in the UI for each file and for the overall changeset. The context has two distinct parts:
- **Neutral context**: Factual description of what changed (what was added/modified/removed, which functions were touched, structural changes). Displayed with neutral/informational styling. Contains no opinions.
- **Review feedback**: The AI agent's assessment and opinions (code quality observations, potential concerns, suggestions, things done well). Displayed with distinct styling that makes it clear this is the agent's subjective take, not objective fact.

Both parts are read-only — the user cannot edit them. They serve as reference material while the user adds their own inline comments.

#### `FR-crp-review-context-overall` -- Display overall changeset context
The CRPG displays an overall changeset summary (neutral context + review feedback) that applies to the entire review session, not tied to a specific file. This orients the user on the scope and purpose of the changes before they dive into individual files. The overall context is visible regardless of which file is active in the file browser.

#### `FR-crp-review-context-per-file` -- Display per-file context
Each file displays context specific to that file (neutral context + review feedback). When the user switches files, the context updates to show the relevant file's context. Files without context data (e.g., files loaded via paste/upload/drag-drop that were not part of the shepherd-review invocation) simply don't show the context panel — no empty or placeholder state is needed.

#### `FR-crp-review-context-collapsible` -- Collapsible review context in the sidebar
The review context sections in the right sidebar (overall changeset context) must be collapsible and expandable, similar to the per-file context panel in the code viewer area. This allows users to reclaim vertical space in the sidebar when they don't need to reference the context. The collapse state must persist during the session — it should not reset when the user switches between file tabs. Each section (neutral context and review feedback) may collapse independently, or the entire sidebar context area may collapse as a unit — this is a design decision. The collapse/expand controls must be clearly visible and discoverable.

#### `FR-crp-comment-summary` -- All Comments summary view
The CRPG provides an "All Comments" summary view that shows every comment across all loaded files, organized by file. For each comment, the summary shows: the file name, the line number(s) or element reference, and the comment text. The summary is read-only — viewing only; editing happens in the file's code viewer. The summary updates in real-time as comments are added, edited, or deleted on any file. When no comments exist, the summary shows an appropriate empty state message (e.g., "No comments yet"). The summary is accessible from the sidebar area and can be toggled or accessed alongside the prompt preview. Files with zero comments are not listed in the summary.

#### `FR-crp-panel-resize` -- Resizable file browser sidebar
The file browser sidebar panel (which presents loaded files in a directory tree) must be user-resizable by dragging its right edge. This allows the user to widen the panel to see longer file paths and directory names, or narrow it to give more space to the code viewer. The resize handle is positioned at the boundary between the file browser and the code viewer panel. The panel has a minimum width (to remain usable) and a maximum width (to ensure the code viewer retains enough space). The resize preference persists within the current session (consistent with `NFR-crp-no-data-persistence`). A quick-reset mechanism restores the panel to its default width. The resize interaction must be smooth with no visible layout jank.

#### `FR-crp-active-file-path` -- Display active file path at top of code viewer
When multiple files are loaded (multi-file mode), the full path of the currently active file is displayed at the top of the code viewer panel. This provides persistent context about which file the user is viewing and commenting on, without requiring them to look at the file browser sidebar. The path updates immediately when the user switches files. In single-file mode, the existing FileHeader already provides this context. The path display is read-only and non-interactive (not editable). When a file was loaded via paste with no file name, the path display shows "Untitled" (or the user-given name if one was provided).

#### `FR-crp-file-tooltip` -- File row tooltip with full path and metadata
When the user hovers over a file row in the file browser sidebar, a tooltip displays the full untruncated file path, the detected language, and the review status. This ensures the user can always read the complete path even when file names are truncated due to the sidebar width. For pasted files, the tooltip shows "Untitled" or the user-given name. This tooltip is essential because the sidebar has limited width and file names are commonly truncated.

#### `FR-crp-file-reviewed-toggle` -- Mark/unmark a file as reviewed
The user can toggle an individual file's review status between "unreviewed" (default) and "reviewed". This is a manual action — the application never automatically marks a file as reviewed. The toggle is available for every loaded file regardless of whether the file has comments, context data, or was loaded via any particular method (paste, upload, drag-drop, slash command, shepherd-review). In a single-file session, the toggle is still available but the grouping and progress features (`FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`) may have limited utility. The toggle mechanism is a design decision (could be a checkbox in the file browser, a button in the toolbar, a keyboard shortcut, or some combination), but it must be reachable without switching away from the current file.

#### `FR-crp-file-reviewed-visual` -- Visual distinction for reviewed files
Files that are marked as reviewed must have a visually distinct treatment in the file browser sidebar. The visual treatment must be obvious at a glance — a user scanning the file browser should be able to instantly tell which files are reviewed and which are not without hovering or clicking. Possible treatments include (but are not limited to): a checkmark icon, muted/dimmed text, a different background color, or a strikethrough on the file name. The specific visual treatment is a design decision. The currently active file's entry still shows its reviewed/unreviewed state even while active.

#### `FR-crp-file-reviewed-grouping` -- Review status within the directory tree
Within each directory in the tree, unreviewed files should be prominently positioned. Reviewed files are visually distinguished from unreviewed files at their tree position — they are NOT moved to a separate "Reviewed" group. The directory tree structure is the primary organizational axis; review status is a secondary visual layer on top of it. The user can still click on a reviewed file to view it, add comments to it, or unmark it. When all files in a directory are reviewed, the directory node itself must show a reviewed indicator (e.g., a checkmark) so that a collapsed, fully-reviewed directory clearly communicates its status at a glance. The "To Review" / "Reviewed" section headers from the previous flat-list design are removed — they are replaced by the directory tree structure with per-file reviewed indicators.

#### `FR-crp-file-reviewed-progress` -- Review progress indicator
The application displays a progress indicator showing the number of reviewed files versus total loaded files (e.g., "3/7 reviewed" or a progress bar or percentage). The indicator is visible at all times when two or more files are loaded. The indicator updates immediately when a file is marked or unmarked as reviewed, when a file is added to the session, or when a file is removed from the session. In a single-file session, the progress indicator is optional (a design decision) since "0/1" or "1/1" has limited value. When the session is cleared, the progress indicator resets (or disappears if no files are loaded).

#### `FR-crp-file-reviewed-persistence` -- Review status session persistence
A file's reviewed/unreviewed status persists within the current session. Switching between files, scrolling, adding/editing/deleting comments, toggling view modes (file/diff/rendered), and interacting with the preamble or context panels do not affect a file's reviewed status. Consistent with `NFR-crp-no-data-persistence`, reviewed status does NOT persist across page reloads — all files return to "unreviewed" on reload. When a file is removed from the session via `FR-crp-multi-file-remove`, its reviewed status is discarded. When the session is cleared via `FR-crp-clear-session`, all reviewed statuses are reset.

### Non-Functional Requirements

#### `NFR-crp-large-file-perf` -- Large file performance
The application must remain responsive (no visible jank or freeze longer than 200ms) when loading and scrolling files up to 10,000 lines. Files over 10,000 lines may display a warning but must still be loadable.

#### `NFR-crp-render-time` -- Initial render time
A file under 1,000 lines must render in the viewer within 500ms of being loaded. Syntax highlighting may load progressively but the text with line numbers must be visible within that window.

#### `NFR-crp-prompt-gen-time` -- Prompt generation time
Prompt generation must complete within 300ms for files up to 10,000 lines with up to 200 comments.

#### `NFR-crp-client-only` -- Client-side only architecture
All processing happens locally — no file content or comments leave the user's machine. In slash command mode, the CRPG communicates with the local server for file loading (`FR-sc-file-api`) and prompt handoff (`FR-crp-prompt-handoff`). No data leaves the local machine.

#### `NFR-crp-browser-support` -- Browser compatibility (web-specific; see `web/code-review-prompt.md`)
The application must work in the latest stable versions of Chrome, Firefox, Safari, and Edge.

#### `NFR-crp-responsive-layout` -- Responsive layout (web-specific; see `web/code-review-prompt.md`)
The application must be usable on viewports from 1024px wide and above. Below 1024px, the application may show a message recommending a wider viewport. It is not required to support mobile.

#### `NFR-crp-accessibility-keyboard` -- Keyboard accessibility
Core workflows (load file, add comment, generate prompt, copy prompt) must be achievable via keyboard alone without requiring mouse interaction.

#### `NFR-crp-no-data-persistence` -- No data persistence requirement
The application is not required to persist sessions across page reloads in this initial version. Session data is held in memory only. This is an explicit scoping decision. Sessions are now identifiable via a session ID (see `FR-sc-session-id`), but the session ID is used only for routing (URL-based window targeting) and prompt handoff (writing to the session-scoped output path). The session ID does not enable persistence — all in-browser state (loaded files, comments, preamble) is still lost on page reload.

## Acceptance Criteria

#### `AC-crp-load-paste` -- File loads via paste
**Given** the application is in the initial empty state, **when** the user pastes text content into the file input area, **then** the viewer displays the pasted content with line numbers starting at 1.

#### `AC-crp-load-upload` -- File loads via upload
**Given** the application is in the initial empty state, **when** the user selects a file using the file picker, **then** the viewer displays the file content with line numbers and the file name is shown.

#### `AC-crp-load-drag-drop` -- File loads via drag and drop
**Given** the application is in the initial empty state, **when** the user drags a text file onto the drop zone, **then** the viewer displays the file content with line numbers and the file name is shown.

#### `AC-crp-syntax-highlight-detected` -- Syntax highlighting applies automatically
**Given** a TypeScript file is loaded, **when** the viewer renders, **then** the code is displayed with syntax-appropriate coloring for keywords, strings, and comments.

#### `AC-crp-add-comment-single-line` -- Comment added to a single line
**Given** a file is displayed in the viewer, **when** the user clicks on line 5 and types "Rename this variable" and submits, **then** a comment reading "Rename this variable" is visually attached below line 5, and the gutter for line 5 shows a comment indicator.

#### `AC-crp-add-comment-line-range` -- Comment added to a line range
**Given** a file is displayed in the viewer, **when** the user selects lines 10 through 15 and adds the comment "Extract this to a helper function", **then** the comment is attached to the range 10-15, the gutter shows indicators for lines 10 through 15, and the generated prompt references lines 10-15.

#### `AC-crp-edit-comment` -- Existing comment is edited
**Given** a comment "Fix this" exists on line 3, **when** the user clicks to edit it and changes the text to "Fix this null check", **then** the displayed comment updates to "Fix this null check" and it remains attached to line 3.

#### `AC-crp-delete-comment` -- Comment is deleted
**Given** a comment exists on line 7, **when** the user deletes it, **then** the comment is removed from the viewer, the gutter indicator for line 7 disappears (if no other comments remain on that line), and the comment count decreases by 1.

#### `AC-crp-generate-prompt-structure` -- Generated prompt has correct structure
**Given** a file named "utils.ts" is loaded with comments on lines 3, 10-12, and 25, and a preamble "Refactor for readability", **when** the user has added comments, **then** the automatically generated prompt contains: (1) an "Instructions" section with the preamble text, (2) a "File" heading with the file name and language, (3) a "Requested Changes" section where each comment is preceded by a fenced code block containing the actual source code the comment references, and (4) all three comments listed in the order they appear in the source file.

#### `AC-crp-generate-prompt-no-comments` -- No prompt when no comments exist
**Given** a file is loaded but no comments have been added, **then** the prompt preview area shows a placeholder message indicating that comments are needed to produce a prompt, and the prompt value is empty. **When** the user adds a comment, **then** the prompt is automatically generated and appears in the preview. **When** the user deletes the last remaining comment, **then** the prompt clears and the placeholder message returns.

#### `AC-crp-copy-clipboard` -- Prompt copied to clipboard
**Given** a prompt has been generated and is displayed in the preview, **when** the user clicks the copy button, **then** the prompt text is placed on the system clipboard and a "Copied to clipboard" confirmation is displayed.

#### `AC-crp-preview-matches-copy` -- Preview matches clipboard content
**Given** a prompt has been generated, **when** the user views the preview and then copies, **then** the text on the clipboard is byte-for-byte identical to the text shown in the preview.

#### `AC-crp-clear-confirmation` -- Clear session asks for confirmation
**Given** the user has added at least one comment, **when** the user clicks the clear/reset button, **then** a confirmation dialog appears. If confirmed, the file, all comments, and the preamble are cleared. If cancelled, everything is preserved.

#### `AC-crp-clear-no-confirm-empty` -- Clear session skips confirmation when empty
**Given** a file is loaded but no comments exist, **when** the user clicks the clear/reset button, **then** the session clears immediately without a confirmation dialog.

#### `AC-crp-empty-state` -- Empty state displays load instructions
**Given** no file is loaded, **when** the user first opens the application, **then** the viewer area displays instructions for how to load a file (paste, upload, or drag-and-drop), and the copy button is disabled.

#### `AC-crp-large-file-scroll` -- Large file scrolls without jank
**Given** a file with 10,000 lines is loaded, **when** the user scrolls through the viewer, **then** scrolling is smooth with no visible stutter or frame drops exceeding 200ms.

#### `AC-crp-comment-navigation-next` -- Next/previous comment navigation works
**Given** comments exist on lines 5, 20, and 100, **when** the user is viewing line 5's comment and clicks "next comment", **then** the viewer scrolls to line 20 and that comment is highlighted.

#### `AC-crp-keyboard-add-comment` -- Comment can be added via keyboard
**Given** the viewer has focus, **when** the user uses keyboard navigation to reach a line and presses the designated key to add a comment, **then** the comment input opens for that line without any mouse interaction.

#### `AC-crp-binary-file-rejected` -- Binary files are rejected gracefully
**Given** the application is in the initial empty state, **when** the user attempts to upload a binary file (e.g., an image or compiled executable), **then** the application displays an error message indicating that only text files are supported and does not crash or display garbled content.

#### `AC-crp-done-sends-prompt` -- Done action sends prompt to server and clipboard
**Given** inline comments exist and the CRPG is running in slash command mode (served by the local server), **when** the user clicks Done, **then** the generated prompt is sent to the local server with the session ID and written to `~/.shepherd/sessions/<session-id>/prompt-output.md`, and the prompt is also copied to the system clipboard.

#### `AC-crp-done-auto-close` -- Window closes automatically after Done succeeds
**Given** the CRPG is running in a standalone application window and the user clicks Done and the handoff succeeds, **then** the application window closes automatically, returning focus to the terminal (which was the previously active window). If the window cannot be closed (platform restrictions), the CRPG falls back to showing the confirmation state.

#### `AC-crp-done-confirmation` -- Done action shows confirmation state (fallback)
**Given** the user clicks Done, the prompt handoff succeeds, but the window cannot be auto-closed, **then** the CRPG shows a confirmation message (e.g., "Prompt sent to agent! Switch back to your terminal.") and the Done button changes to a "Sent" state.

#### `AC-crp-done-fallback-clipboard` -- Done action falls back to clipboard on server failure
**Given** the user clicks Done but the prompt handoff to the local server fails, **then** the prompt is still copied to the system clipboard and the user sees a message indicating they should paste manually.

#### `AC-crp-done-disabled-no-comments` -- Done button disabled when no comments exist
**Given** no inline comments exist, **then** the Done button is disabled (same condition as the Copy button).

#### `AC-crp-done-standalone-hidden` -- Done button hidden in standalone mode
**Given** the CRPG is not running in slash command mode (e.g., loaded via paste/upload/drag-and-drop, no local server), **then** the Done button is not shown. The Copy button remains the primary action.

#### `AC-crp-multi-file-load-adds` -- Loading a second file adds it to the session
**Given** a file "utils.ts" is loaded, **when** the user uploads "helpers.ts", **then** both files are available in the session, and the user can switch between them.

#### `AC-crp-multi-file-drop-multiple` -- Multiple files can be dropped at once
**Given** the application is open, **when** the user drags and drops 3 files simultaneously, **then** all 3 files are loaded into the session.

#### `AC-crp-multi-file-nav-preserves-state` -- Switching files preserves comments
**Given** "utils.ts" has 3 comments and "helpers.ts" has 2 comments, **when** the user switches from "utils.ts" to "helpers.ts" and back, **then** all 3 comments on "utils.ts" are still present.

#### `AC-crp-multi-file-remove-with-comments` -- Removing a file with comments asks confirmation
**Given** "utils.ts" has 2 comments, **when** the user attempts to remove it, **then** a confirmation dialog appears. If confirmed, the file and its comments are removed.

#### `AC-crp-multi-file-remove-no-comments` -- Removing a file without comments requires no confirmation
**Given** "helpers.ts" has no comments, **when** the user removes it, **then** it is removed immediately without confirmation.

#### `AC-crp-multi-file-prompt-structure` -- Combined prompt includes all files
**Given** "utils.ts" has comments on lines 3 and 10, and "helpers.ts" has a comment on line 5, and preamble is "Refactor for consistency", **then** the generated prompt contains: an Instructions section with the preamble, then a File section for "utils.ts" with its 2 comments, then a File section for "helpers.ts" with its 1 comment.

#### `AC-crp-multi-file-prompt-omits-uncommented` -- Files without comments are excluded from prompt
**Given** 3 files are loaded but only 2 have comments, **then** the generated prompt only includes sections for the 2 files with comments.

#### `AC-crp-multi-file-comment-count` -- Comment count spans all files
**Given** "utils.ts" has 3 comments and "helpers.ts" has 2 comments, **then** the displayed total comment count is 5.

#### `AC-crp-multi-file-clear-all` -- Clear session removes all files
**Given** 3 files are loaded with various comments, **when** the user clicks clear, **then** a confirmation appears, and if confirmed, all files, comments, and preamble are removed.

#### `AC-crp-multi-file-empty-after-remove-last` -- Removing the last file returns to empty state
**Given** only one file is loaded, **when** the user removes it, **then** the application returns to the initial empty state.

#### `AC-crp-file-path-display` -- Directory tree distinguishes same-named files
**Given** two files with the same name but different directories are loaded (e.g., `src/utils/helpers.ts` and `lib/helpers.ts`), **when** the user views the file browser sidebar, **then** the files appear under their respective directory nodes in the tree, making them immediately distinguishable by their position in the hierarchy.

#### `AC-crp-file-path-single-dir` -- Directory tree shown for files in a single directory
**Given** all loaded files reside in the same directory, **when** the user views the file browser sidebar, **then** the files appear under that directory node in the tree. The directory structure is always shown regardless of whether multiple directories are present.

#### `AC-crp-context-overall-visible` -- Overall changeset context is visible
**Given** the CRPG is opened via shepherd-review with context data, **when** the user views any file, **then** an overall changeset context section is visible showing both neutral context and review feedback with visually distinct styling.

#### `AC-crp-context-per-file-visible` -- Per-file context is visible
**Given** a file loaded via shepherd-review has per-file context, **when** the user views that file, **then** the file's neutral context and review feedback are visible with distinct styling.

#### `AC-crp-context-per-file-switches` -- Per-file context switches with files
**Given** files A and B both have per-file context, **when** the user switches from file A to file B, **then** the displayed per-file context updates to show file B's context (not file A's).

#### `AC-crp-context-neutral-vs-review` -- Neutral context and review feedback are visually distinct
**Given** context is displayed (either overall or per-file), **then** the neutral context section and review feedback section are visually distinct (different styling, headers, or containers) so a user can immediately tell which is factual description and which is the agent's opinion.

#### `AC-crp-context-graceful-missing` -- No context panel when context data is absent
**Given** a file is loaded via paste/upload/drag-drop (no context data provided), **then** no context panel is shown for that file. The CRPG works exactly as before when no context data is provided — there is no empty or placeholder context state.

#### `AC-crp-context-readonly` -- Context is read-only
**Given** context is displayed (neutral or review feedback), **then** the user cannot edit the neutral context or review feedback text. They are read-only reference material.

#### `AC-crp-context-sidebar-collapse` -- Sidebar review context can be collapsed and expanded
**Given** the CRPG is opened via shepherd-review with context data, **when** the user clicks the collapse control on the sidebar review context, **then** the context content collapses to just a header bar. Clicking again expands it back. The collapse state survives tab switches — switching to another file and back does not reset the collapse state.

#### `AC-crp-overall-comment-label` -- Overall Comment field labeling
**Given** the sidebar is visible, **then** the field formerly labeled "Preamble" is now labeled "Overall Comment" with a description or placeholder text indicating that it applies to all files in the session and will be included at the top of the generated prompt.

#### `AC-crp-overall-comment-in-prompt` -- Overall Comment appears once in multi-file prompt
**Given** the user has typed text in the Overall Comment field and added inline comments on two files, **when** the prompt is generated, **then** the overall comment text appears once at the top of the prompt in the "Instructions" section, not duplicated per file.

#### `AC-crp-comment-summary-shows-all` -- All Comments summary shows comments organized by file
**Given** files A, B, and C are loaded with 2, 3, and 0 comments respectively, **when** the user views the All Comments summary, **then** all 5 comments are shown organized under file A (2 comments) and file B (3 comments). File C with no comments is not listed.

#### `AC-crp-comment-summary-realtime` -- All Comments summary updates in real-time
**Given** the All Comments summary is visible, **when** the user switches to a file tab and adds a new comment, **then** the summary immediately reflects the new comment without requiring a manual refresh.

#### `AC-crp-comment-summary-empty` -- All Comments summary shows empty state when no comments exist
**Given** no comments exist on any file, **when** the user views the All Comments summary area, **then** a message like "No comments yet" is shown instead of an empty list.

#### `AC-crp-file-mark-reviewed` -- Marking a file changes its visual state
**Given** a file is loaded and currently unreviewed, **when** the user marks it as reviewed, **then** the file's entry in the file browser sidebar immediately displays the reviewed visual treatment (e.g., checkmark, muted styling) at its current position in the directory tree. The file remains in its directory position and does not move to a separate group.

#### `AC-crp-file-unmark-reviewed` -- User can unmark a reviewed file
**Given** a file is marked as reviewed, **when** the user toggles its reviewed status again, **then** the file returns to the unreviewed visual state at its current position in the directory tree. This confirms the reviewed status is a toggle, not a one-way action.

#### `AC-crp-file-reviewed-grouping` -- Reviewed files shown with indicators in the directory tree
**Given** 5 files are loaded across multiple directories and 2 are marked as reviewed, **then** the file browser sidebar shows all files in their directory tree positions. Within each directory, unreviewed files appear before reviewed files. Reviewed files have visual indicators (checkmark, muted text) distinguishing them from unreviewed files. There are no separate "To Review" / "Reviewed" section headers.

#### `AC-crp-file-reviewed-progress-count` -- Progress indicator shows correct count
**Given** 7 files are loaded and 3 have been marked as reviewed, **then** the progress indicator shows "3/7" (or equivalent). **When** the user marks a 4th file as reviewed, **then** the indicator updates to "4/7". **When** the user unmarks one file, **then** it updates to "3/7". **When** the user removes a reviewed file from the session, **then** it updates to "2/6". **When** the user adds a new file, **then** it updates to "2/7" (new files default to unreviewed).

#### `AC-crp-file-reviewed-survives-tab-switch` -- Reviewed status persists across tab switches
**Given** "utils.ts" is marked as reviewed and "helpers.ts" is not, **when** the user switches from "utils.ts" to "helpers.ts" and back to "utils.ts", **then** "utils.ts" still shows as reviewed and "helpers.ts" still shows as unreviewed.

#### `AC-crp-file-reviewed-with-comments` -- Reviewed status is independent of comments
**Given** a file has no comments, **when** the user marks it as reviewed, **then** the file is successfully marked as reviewed. Conversely, **given** a file has 5 comments and is marked as reviewed, **when** the user deletes all comments, **then** the file remains marked as reviewed. The reviewed status is orthogonal to whether the file has comments.

#### `AC-crp-file-reviewed-clear-session` -- Clear session resets reviewed statuses
**Given** 3 files are marked as reviewed, **when** the user clears the session (per `FR-crp-clear-session`), **then** all files are removed and all reviewed statuses are discarded. If the user then loads new files, they all start as unreviewed.

#### `AC-crp-panel-resize-drag` -- File browser sidebar can be resized by dragging
**Given** two or more files are loaded and the file browser sidebar is visible, **when** the user clicks and drags the right edge of the file browser, **then** the sidebar width changes smoothly following the mouse, and the code viewer panel adjusts to fill the remaining space.

#### `AC-crp-panel-resize-bounds` -- Resize respects minimum and maximum width
**Given** the user is dragging the file browser resize handle, **when** they drag below the minimum width, **then** the sidebar stops shrinking and stays at the minimum. **When** they drag beyond the maximum width, **then** the sidebar stops growing and stays at the maximum. The code viewer always retains enough width to be usable.

#### `AC-crp-panel-resize-double-click` -- Double-click resets to default width
**Given** the file browser sidebar has been resized to a non-default width, **when** the user triggers the quick-reset mechanism, **then** the sidebar returns to its default width.

#### `AC-crp-panel-resize-persists` -- Resize preference persists within the session
**Given** the user resizes the file browser to 350px, **when** they switch between files, **then** the file browser remains at 350px. Consistent with `NFR-crp-no-data-persistence`, the width resets to default on page reload.

#### `AC-crp-active-file-path-visible` -- Active file path is displayed at top of code viewer in multi-file mode
**Given** two or more files are loaded and the user is viewing `src/components/FileBrowser.tsx`, **then** the full path `src/components/FileBrowser.tsx` is displayed at the top of the code viewer panel, above the code content.

#### `AC-crp-active-file-path-switches` -- File path updates when switching files
**Given** the active file path shows `src/utils/helpers.ts`, **when** the user clicks on a different file in the file browser, **then** the path immediately updates to show the new file's path.

#### `AC-crp-active-file-path-single-file` -- File path header not shown in single-file mode
**Given** only one file is loaded, **then** the existing FileHeader is shown (not the new path header). The active file path header only appears in multi-file mode (when two or more files are loaded).

#### `AC-crp-file-tooltip-full-path` -- Hovering over a file row shows full path in tooltip
**Given** a file `src/components/deeply/nested/VeryLongComponentName.tsx` is loaded, **when** the user hovers over its row in the file browser sidebar, **then** a tooltip appears showing the full path, detected language, and review status (e.g., "src/components/deeply/nested/VeryLongComponentName.tsx — TypeScript").

#### `AC-crp-file-tooltip-reviewed` -- Tooltip reflects review status
**Given** a file is marked as reviewed, **when** the user hovers over its file row, **then** the tooltip includes the review status (e.g., "src/utils.ts — TypeScript — Reviewed").

#### `AC-crp-line-wrap-toggle` -- Enabling line wrapping removes horizontal scrollbar
**Given** a file with long lines is loaded, **when** the user enables line wrapping, **then** long lines wrap within the code content area and no horizontal scrollbar appears for the code.

#### `AC-crp-line-wrap-preserves-line-numbers` -- Wrapped lines retain a single line number
**Given** line wrapping is enabled and a long line wraps to 3 visual rows, **then** only one line number is displayed (aligned to the first visual row) and the next logical line's number follows correctly (no gaps, no duplicated numbers).

#### `AC-crp-line-wrap-comment-target` -- Clicking any visual row of a wrapped line targets the correct logical line
**Given** line wrapping is enabled, **when** the user clicks on any visual row of a wrapped line, **then** the comment is attached to the correct logical line number.

#### `AC-crp-line-wrap-default-on` -- Line wrapping is on by default
**Given** a new session is started, **then** line wrapping is on by default and long lines wrap visually within the code content area.

#### `AC-crp-line-wrap-persists-session` -- Line wrapping preference persists within the session
**Given** the user enables line wrapping, **when** they switch between files and switch back, **then** the line wrapping setting is still enabled.

## Open Questions

1. **Prompt format customization**: Should the user be able to choose between different prompt formats (e.g., one optimized for ChatGPT, one for Claude, one for Copilot)? For v1, a single well-structured format is assumed sufficient.

2. **~~Multi-file support~~** (Resolved): Multi-file support is now included in this spec. See `FR-crp-multi-file-load`, `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `FR-crp-multi-file-prompt`, and `FR-crp-multi-file-prompt-format`.

3. **Session persistence**: Should sessions survive a page reload (e.g., via localStorage)? This PRD explicitly defers persistence (`NFR-crp-no-data-persistence`), but it is a natural v2 candidate.

4. **Diff view mode**: Should the tool support viewing a diff (two versions of a file) rather than a single file? This is deferred for now but could align well with the "code review" metaphor.

5. **Prompt template customization**: Should advanced users be able to edit the prompt template itself (e.g., change section headers, reorder sections, add custom instructions)? Deferred to a future iteration.

6. **File loading from URL or GitHub**: Should the tool support loading a file directly from a URL or GitHub repo? This PRD scopes to local-only loading (paste, upload, drag-and-drop).

7. **Maximum file size**: `NFR-crp-large-file-perf` sets a 10,000-line target. Should we enforce a hard upper limit (e.g., 50,000 lines) beyond which the file is rejected?

8. **File ordering in prompt**: Should files in the generated prompt be ordered by load order, alphabetically, or user-reorderable? V1 assumes load order.

9. **Per-file preamble**: Should users be able to add per-file instructions in addition to the global preamble? V1 assumes a single global preamble only.

10. **Maximum file count**: Should there be a hard limit on the number of files that can be loaded? V1 has no hard limit but acknowledges performance may degrade past 20 files. The file browser sidebar handles larger file counts much better than the previous tab bar approach, since it uses vertical scrolling rather than horizontal compression, but very large sessions (50+ files) may still warrant a limit or lazy-rendering strategy.

11. **~~Review context layout placement~~** (Resolved): The file browser sidebar provides a natural home for overall changeset context (e.g., in a collapsible section above the file list). Per-file context is displayed alongside the code viewer when a file is selected. The sidebar + code viewer + prompt panel form a three-column layout. This three-column layout has implications for screen real estate on smaller viewports (see `NFR-crp-responsive-layout`, which already sets a 1024px minimum). Design should determine whether the sidebar collapses, overlays, or uses a different treatment at narrower widths within the supported range.

## Dependencies

- **Syntax highlighting library**: Selection is an engineering decision.
- **Clipboard API**: Requires platform clipboard access. Falls back gracefully if unavailable.
- **No external services**: Per `NFR-crp-client-only`, there are no backend or third-party API dependencies.
