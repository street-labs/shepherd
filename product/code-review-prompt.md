# Code Review Prompt Generator

## Overview

A web application that lets developers view a source file with line numbers, add inline comments on specific lines (similar to a GitHub pull request review), and then generate a single structured prompt that aggregates the file content and all comments. The generated prompt is designed to be copied and fed to an AI coding assistant, giving the AI full context about what changes are needed and where.

The core workflow is: **load file --> annotate lines --> copy prompt --> paste into AI agent**. The prompt is automatically generated and kept current as comments are added, so there is no explicit "generate" step.

This bridges the gap between a developer's code review observations and an actionable AI prompt, eliminating the need to manually describe file context, line numbers, and desired changes.

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

## Requirements

### Functional Requirements

#### `FR-crp-file-load` -- Load a file for review
The user can load a file into the viewer by either pasting file content into a text area, uploading a file from their local filesystem via a file picker, or dragging and dropping a file onto the application. The application must accept any plain-text file regardless of extension. When multiple files are dropped simultaneously, only the first file is loaded and a brief notification informs the user that only one file can be loaded at a time. Binary files are detected by scanning the first 8,192 bytes (or the entire file if shorter) for null bytes (`0x00`); files containing null bytes are rejected with an error message. This is a deliberate trade-off that may reject rare text files containing legitimate null bytes, but it prevents garbled display of binary content.

#### `FR-crp-file-display` -- Display file with line numbers
The loaded file is displayed in a read-only viewer with sequential line numbers starting at 1. Each line is individually addressable (clickable). The viewer must use a monospace font and preserve the original indentation, whitespace, and line breaks of the source file.

#### `FR-crp-syntax-highlight` -- Syntax highlighting
The file viewer applies syntax highlighting based on the detected or specified language. The application must support at minimum these 13 languages: JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, HTML, CSS, JSON, YAML, and Markdown. Multiple file extensions (e.g., `.js`, `.jsx`, `.mjs`, `.cjs`) may map to the same language. If the language cannot be detected, the file is displayed as plain text (the fallback) without highlighting.

#### `FR-crp-line-comment-create` -- Create an inline comment
The user can click on any line number (or a gutter icon) to open a comment input box anchored to that line. The comment input accepts free-form text. After submitting, the comment is visually attached to that line in the viewer. Multiple comments can be attached to the same line.

#### `FR-crp-line-comment-edit` -- Edit an existing comment
The user can click on an existing comment to edit its text. The edit is applied in place without changing the comment's line association.

#### `FR-crp-line-comment-delete` -- Delete a comment
The user can delete any existing comment. After deletion, the comment is removed from the viewer and will not appear in the generated prompt. If a line has no remaining comments, the line returns to its uncommented visual state.

#### `FR-crp-comment-indicator` -- Visual indicators for commented lines
Lines that have one or more comments attached display a distinct visual indicator in the gutter (such as a colored marker or icon) so the user can see at a glance which lines are annotated.

#### `FR-crp-comment-count` -- Display total comment count
The application displays the current total number of comments somewhere persistently visible (such as a toolbar or sidebar header), so the user knows how many annotations they have placed.

#### `FR-crp-prompt-preamble` -- Prompt preamble / high-level instructions
Before generating the prompt, the user can write an optional preamble that provides high-level context or instructions (e.g., "Refactor this function to use async/await" or "Fix the security vulnerability in the authentication logic"). This preamble appears at the top of the generated prompt. A preamble consisting only of whitespace is treated as empty and will not appear in the generated prompt.

#### `FR-crp-prompt-generate` -- Automatically generated aggregated prompt
The prompt is automatically regenerated whenever the user adds, edits, or deletes a comment, or modifies the preamble. There is no manual "Generate" button. The prompt updates reactively and is always current as long as at least one comment exists. When all comments are removed, the prompt preview clears. The automatically generated prompt is a single structured text containing:
1. The preamble (if provided)
2. The file path and language
3. Each comment paired with the actual code snippet it references, listed in source order

The prompt is formatted so an AI agent can understand the file context and the specific changes requested. Comments are paired with code snippets rather than line numbers, because line numbers change as the file is edited and would be stale by the time the AI processes the prompt. Generation must complete within 300ms (`NFR-crp-prompt-gen-time`) so the UI feels instant.

#### `FR-crp-prompt-preview` -- Live prompt preview
The full automatically generated prompt is always visible in a read-only preview panel that updates in real-time as comments are added, edited, or deleted. The preview displays the exact text that will be copied, including all formatting. Because the prompt is automatically generated, the preview is always current and requires no user action to refresh.

#### `FR-crp-prompt-copy` -- Copy prompt to clipboard
The user can copy the generated prompt to the system clipboard with a single button click. The application displays a confirmation message (e.g., "Copied to clipboard") after a successful copy.

#### `FR-crp-prompt-format` -- Structured prompt format
The generated prompt must follow a consistent, machine-readable structure. The format must include:
- An "Instructions" section containing the preamble text (if provided)
- A "File" heading with the file name (if known) and language (e.g., `## File: utils.ts (typescript)`)
- A "Requested Changes" section listing each comment paired with the code snippet it references
- Each comment formatted as a fenced code block containing the relevant source code, followed by the comment text on the next line
- Comments listed in the order they appear in the source file

The prompt does not include the full file content or line numbers. Instead, each comment is paired directly with the code snippet it references. This ensures the prompt remains accurate even if line numbers shift during editing.

#### `FR-crp-done-action` -- Done action that signals annotation is complete
When the user clicks "Done", the generated prompt is sent to the local server for handoff back to the AI agent. The prompt is also copied to the system clipboard as a fallback. The Done button is only enabled when at least one inline comment exists (same condition as the Copy button per `FR-crp-prompt-copy`). After a successful send, the CRPG automatically closes its browser window (`window.close()`). If the window cannot be closed (browser security restrictions in non-app-mode windows), the CRPG shows a confirmation state indicating the prompt has been sent and instructs the user to switch back to the terminal. The Done button is only visible when the CRPG is running in slash command mode (served by the local server); when loaded standalone (paste/upload/drag-and-drop), the Done button is not shown and the Copy button remains the primary action.

#### `FR-crp-prompt-handoff` -- Prompt handoff to agent via server
When the Done action is triggered, the CRPG sends the generated prompt text to the local server via `POST /api/prompt-output`. The request body is the prompt text (the same text that would be copied to the clipboard). The server writes this to a known file location (`~/.shepherd/prompt-output.md`). This endpoint is only available when the CRPG is served by the local server (slash command mode), not when loaded standalone. If the POST fails, the prompt is still copied to the clipboard and the user is informed to paste manually.

#### `FR-crp-clear-session` -- Clear / reset session
The user can clear the current session (file + all comments + preamble) and return to the initial empty state. The application must ask for confirmation before clearing if any comments exist.

#### `FR-crp-filename-display` -- Display file name
When a file is loaded via upload or drag-and-drop, the application displays the file name above or near the viewer. When content is pasted, the user can optionally provide a file name.

#### `FR-crp-line-range-comment` -- Comment on a range of lines
The user can select a contiguous range of lines and attach a single comment to that range, rather than only a single line. The generated prompt must indicate the full line range for such comments.

#### `FR-crp-comment-navigation` -- Navigate between comments
The user can step through comments sequentially (next/previous) to review them in line order. Navigating to a comment scrolls the viewer to the relevant line and highlights it. Navigation wraps around: pressing "next" on the last comment navigates to the first comment, and pressing "previous" on the first comment navigates to the last comment.

### Non-Functional Requirements

#### `NFR-crp-large-file-perf` -- Large file performance
The application must remain responsive (no visible jank or freeze longer than 200ms) when loading and scrolling files up to 10,000 lines. Files over 10,000 lines may display a warning but must still be loadable.

#### `NFR-crp-render-time` -- Initial render time
A file under 1,000 lines must render in the viewer within 500ms of being loaded. Syntax highlighting may load progressively but the text with line numbers must be visible within that window.

#### `NFR-crp-prompt-gen-time` -- Prompt generation time
Prompt generation must complete within 300ms for files up to 10,000 lines with up to 200 comments.

#### `NFR-crp-client-only` -- Client-side only architecture
The entire application must run client-side in the browser with no server-side component required. No file content or comments are sent to any external service. This ensures user code remains private. In slash command mode, the CRPG makes same-origin requests to the local dev server for file loading (`FR-sc-file-api`) and prompt handoff (`FR-crp-prompt-handoff`). No data leaves the local machine.

#### `NFR-crp-browser-support` -- Browser compatibility
The application must work in the latest stable versions of Chrome, Firefox, Safari, and Edge.

#### `NFR-crp-responsive-layout` -- Responsive layout
The application must be usable on viewports from 1024px wide and above. Below 1024px, the application may show a message recommending a wider viewport. It is not required to support mobile.

#### `NFR-crp-accessibility-keyboard` -- Keyboard accessibility
Core workflows (load file, add comment, generate prompt, copy prompt) must be achievable via keyboard alone without requiring mouse interaction.

#### `NFR-crp-no-data-persistence` -- No data persistence requirement
The application is not required to persist sessions across page reloads in this initial version. Session data is held in memory only. This is an explicit scoping decision.

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
**Given** inline comments exist and the CRPG is running in slash command mode (served by the local server), **when** the user clicks Done, **then** the generated prompt is sent to the server via `POST /api/prompt-output` and written to `~/.shepherd/prompt-output.md`, and the prompt is also copied to the system clipboard.

#### `AC-crp-done-auto-close` -- Window closes automatically after Done succeeds
**Given** the CRPG is running in an app-mode browser window and the user clicks Done and the handoff succeeds, **then** the browser window closes automatically via `window.close()`, returning focus to the terminal (which was the previously active window). If the window cannot be closed (e.g., opened as a regular browser tab instead of app mode), the CRPG falls back to showing the confirmation state.

#### `AC-crp-done-confirmation` -- Done action shows confirmation state (fallback)
**Given** the user clicks Done, the prompt handoff succeeds, but the window cannot be auto-closed (not in app-mode), **then** the CRPG shows a confirmation message (e.g., "Prompt sent to agent! Switch back to your terminal.") and the Done button changes to a "Sent" state.

#### `AC-crp-done-fallback-clipboard` -- Done action falls back to clipboard on server failure
**Given** the user clicks Done but the `POST /api/prompt-output` request fails, **then** the prompt is still copied to the system clipboard and the user sees a message indicating they should paste manually.

#### `AC-crp-done-disabled-no-comments` -- Done button disabled when no comments exist
**Given** no inline comments exist, **then** the Done button is disabled (same condition as the Copy button).

#### `AC-crp-done-standalone-hidden` -- Done button hidden in standalone mode
**Given** the CRPG is not running in slash command mode (e.g., loaded via paste/upload/drag-and-drop, no local server), **then** the Done button is not shown. The Copy button remains the primary action.

## Open Questions

1. **Prompt format customization**: Should the user be able to choose between different prompt formats (e.g., one optimized for ChatGPT, one for Claude, one for Copilot)? For v1, a single well-structured format is assumed sufficient.

2. **Multi-file support**: Should the tool support loading and commenting on multiple files in a single session? This PRD scopes to single-file only. Multi-file could be a follow-up feature.

3. **Session persistence**: Should sessions survive a page reload (e.g., via localStorage)? This PRD explicitly defers persistence (`NFR-crp-no-data-persistence`), but it is a natural v2 candidate.

4. **Diff view mode**: Should the tool support viewing a diff (two versions of a file) rather than a single file? This is deferred for now but could align well with the "code review" metaphor.

5. **Prompt template customization**: Should advanced users be able to edit the prompt template itself (e.g., change section headers, reorder sections, add custom instructions)? Deferred to a future iteration.

6. **File loading from URL or GitHub**: Should the tool support loading a file directly from a URL or GitHub repo? This PRD scopes to local-only loading (paste, upload, drag-and-drop).

7. **Maximum file size**: `NFR-crp-large-file-perf` sets a 10,000-line target. Should we enforce a hard upper limit (e.g., 50,000 lines) beyond which the file is rejected?

## Dependencies

- **Syntax highlighting library**: Requires a client-side syntax highlighting library (e.g., Prism.js, Shiki, or CodeMirror for the viewer). Selection is an engineering decision.
- **Clipboard API**: Requires the browser Clipboard API (`navigator.clipboard.writeText`). Falls back gracefully if unavailable.
- **React/TypeScript**: The application is built as a React + TypeScript single-page application.
- **No external services**: Per `NFR-crp-client-only`, there are no backend or third-party API dependencies.
