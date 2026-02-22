# Glossary

Shared vocabulary for this project. All agents should use these terms consistently across product, design, engineering, and QA specs.

**Every agent must check this glossary before introducing a new term.** If a concept already has a name here, use it. If you need a new term, add it here first.

## Code Review Prompt Generator (CRPG)
**Definition**: The core application of the Shepherd project. A client-side web app that lets developers load a source file, annotate it with inline comments, and generate a structured prompt for AI coding assistants. Available as a local web app and (planned) as a standalone CLI.
**Also known as**: CRPG, the app
**Not to be confused with**: The slash command (which is a launcher for the CRPG, not the CRPG itself)

## Code Viewer
**Definition**: The main panel of the application that displays a loaded source file with line numbers, syntax highlighting, and a comment gutter. Read-only — users cannot edit file content.
**Also known as**: File viewer
**Not to be confused with**: Code editor (implies editing capability)

## Inline Comment
**Definition**: A user-authored annotation attached to a specific line or contiguous range of lines in the code viewer. Contains free-form text describing a requested change or observation.
**Also known as**: Line comment, annotation
**Not to be confused with**: Code comments (comments in the source code itself)

## Comment Gutter
**Definition**: The narrow column to the left of line numbers in the code viewer. Displays visual indicators (colored markers) for lines that have inline comments attached.
**Also known as**: Gutter, annotation gutter
**Not to be confused with**: Line number column

## Preamble
**Definition**: An optional block of high-level instructions or context that the user writes before generating a prompt. Appears at the top of the generated prompt, before the file content and inline comments.
**Also known as**: High-level instructions, prompt context
**Not to be confused with**: Inline comments (which are line-specific)

## Generated Prompt
**Definition**: The structured text output automatically produced by the application whenever comments or the preamble change. Aggregates the preamble, full file content with line numbers, and all inline comments in line order. Designed to be copied and pasted into an AI coding assistant. There is no manual generation step — the prompt is always current when comments exist.
**Also known as**: Aggregated prompt, output prompt
**Not to be confused with**: Preamble (which is only one section of the generated prompt)

## Session
**Definition**: The current working state of the application: the loaded file, all inline comments, and the preamble. A session exists only in browser memory and is lost on page reload (v1).
**Also known as**: Review session
**Not to be confused with**: Browser session or authentication session

## Line Range
**Definition**: A contiguous selection of two or more lines to which a single inline comment can be attached. Displayed as lines N-M in the generated prompt.
**Also known as**: Multi-line selection, range selection
**Not to be confused with**: Multiple separate single-line comments

## Comment Navigation
**Definition**: The ability to step through inline comments sequentially (next/previous) in line-number order, scrolling the code viewer to each comment's location.
**Also known as**: Comment stepping
**Not to be confused with**: Scrolling through the code viewer manually

## Drop Zone
**Definition**: The interactive area displayed in the empty state where users can drag-and-drop a file, paste content, or click to open the file picker. Provides visual feedback during drag hover.
**Also known as**: File input area
**Not to be confused with**: The code viewer (which replaces the drop zone after a file is loaded)

## Syntax Highlighting
**Definition**: The application of color-coded formatting to source code tokens (keywords, strings, comments, types) based on the detected programming language. Powered by Shiki using TextMate grammars.
**Also known as**: Code coloring, code highlighting
**Not to be confused with**: Line highlighting (the background color applied to hovered, selected, or focused lines)

## Virtualized Scrolling
**Definition**: A rendering optimization where only the visible rows (plus a small overscan buffer) are present in the DOM, rather than all rows of the file. Used by the code viewer to maintain smooth scrolling for files up to 10,000+ lines.
**Also known as**: Virtualization, windowed rendering
**Not to be confused with**: Lazy loading (which loads data on demand; virtualized scrolling has all data in memory but only renders what's visible)

## Prompt Preview
**Definition**: The read-only panel in the sidebar that displays the generated prompt as plain text inside a `<pre>` element with a dark terminal theme. Shows exactly what will be copied to the clipboard.
**Also known as**: Preview panel
**Not to be confused with**: The preamble input (which is editable and only part of the generated prompt)

## Comment Bubble
**Definition**: The visual component that displays an existing inline comment below its target line(s) in the code viewer. Shows the comment text, line label, and edit/delete action buttons on hover.
**Also known as**: CommentBubble (component name)
**Not to be confused with**: The inline comment editor (which is the input form for creating or editing comments)

## Inline Comment Editor
**Definition**: The input form that appears inline in the code viewer when a user is creating a new inline comment or editing an existing one. Contains a text area, submit button, and cancel button.
**Also known as**: InlineCommentEditor (component name), comment editor
**Not to be confused with**: The comment bubble (which is the read-only display of a submitted comment)

## Toolbar
**Definition**: The persistent horizontal bar fixed at the top of the application viewport (56px height). Contains the application title, comment navigation controls, comment count, and action buttons (Copy, Clear).
**Also known as**: Action bar, top bar
**Not to be confused with**: The sidebar panel (which is the right-side panel containing the preamble and prompt preview)

## Slash Command
**Definition**: A shortcut invoked by typing `/shepherd <filepath>` in a supported AI coding agent (e.g., Claude Code). Launches the CRPG web app with the specified file auto-loaded. Implemented as a Claude Code custom command (`.claude/commands/shepherd.md`) for in-repo use, and as a standalone CLI binary for global use.
**Also known as**: Custom command, agent command
**Not to be confused with**: Shell commands (executed in a terminal, not an agent conversation)

## File-Serving API
**Definition**: A localhost-only HTTP endpoint (`GET /api/file?path=<encoded-path>`) exposed by the local server that reads a file from the filesystem and returns its content as plain text. Used by the CRPG web app to load files specified via URL parameters from the slash command.
**Also known as**: File API, local file endpoint
**Not to be confused with**: The CRPG's in-browser file loading (drag-drop, upload, paste), which does not involve a server

## Lockfile
**Definition**: A file at `~/.shepherd/server.lock` that records the PID and port of a running CRPG server instance. Used to detect and reuse existing server instances across multiple slash command invocations, and to enable explicit shutdown via `--stop`.
**Also known as**: Server lockfile, PID file
**Not to be confused with**: `pnpm-lock.yaml` (dependency lockfile)

## Auto-Load
**Definition**: The behavior where the CRPG web app automatically loads a file on startup when a `?file=<path>` URL query parameter is present. Bypasses the normal drop zone interaction. Clears any existing session without confirmation.
**Also known as**: URL-based file loading, query parameter loading
**Not to be confused with**: Manual file loading (drag-drop, upload, paste via the drop zone)

## Working Copy
**Definition**: The current on-disk version of a file, including any uncommitted modifications. In the context of the diff view, the working copy is compared against the baseline (git HEAD) to produce the diff.
**Also known as**: Modified version, current version
**Not to be confused with**: Baseline (the git HEAD version), staged changes (git index — not used in v1)

## Diff View
**Definition**: An alternative viewing mode in the CRPG that displays a unified diff between a file's git HEAD version (baseline) and its current working copy on disk. Shows added lines (green), removed lines (red), and context lines, with collapsible unchanged sections. Only available for files loaded via the slash command (server-loaded files).
**Also known as**: Diff mode, working copy diff
**Not to be confused with**: File view (the default full-file viewing mode), side-by-side diff (not supported in v1)

## Baseline
**Definition**: The reference version of a file used for diff computation. In v1, this is always the git HEAD version of the file, fetched via the `/api/file/head` endpoint.
**Also known as**: HEAD version, original version
**Not to be confused with**: Working copy (the current on-disk version of the file)

## Hunk
**Definition**: A contiguous block of changes in a diff, consisting of added, removed, and surrounding context lines. Multiple hunks may exist in a single file diff, separated by unchanged regions.
**Also known as**: Diff hunk, change block
**Not to be confused with**: Collapsed section (which is a block of unchanged lines between hunks)

## Collapsed Section
**Definition**: A block of unchanged lines in the diff view that is hidden by default, replaced by a clickable separator showing the count of hidden lines (e.g., "... 47 unchanged lines ..."). Users can expand collapsed sections to reveal the hidden lines. Only the configured number of context lines (default: 3) are shown around each hunk.
**Also known as**: Collapsed region, hidden lines
**Not to be confused with**: Hunk (which contains actual changes)

## Context Lines
**Definition**: Unchanged lines shown in the diff view surrounding each hunk to provide context. The default context size is 3 lines above and below each change, matching GitHub's convention. Context lines display both old and new line numbers.
**Also known as**: Surrounding context, unchanged context
**Not to be confused with**: Changed lines (added or removed lines within a hunk)

## View Mode Toggle
**Definition**: A segmented control in the toolbar that switches between "File" (full-file view) and "Diff" (unified diff view) modes. Disabled when the file was not loaded via the server (paste/upload files have no baseline to diff against). Switching modes clears comments with a confirmation dialog.
**Also known as**: Mode toggle, File/Diff toggle
**Not to be confused with**: The toolbar action buttons (Copy, Clear)

## Diff Line Identifier
**Definition**: A unique identifier for a line in the diff view, encoding the line type (added, removed, or context) and the corresponding old and/or new line numbers. Used to anchor comments in diff mode, replacing the simple line number used in file mode.
**Also known as**: DiffLineId
**Not to be confused with**: Line number (used in file view for comment anchoring)

## Shepherd Review
**Definition**: A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Discovers the changeset of the current branch vs main, filters out uninteresting files, and iterates through the remaining files one by one, invoking the `/shepherd` command for each.
**Also known as**: Review command, review loop
**Not to be confused with**: The `/shepherd` command (which opens a single file), or the CRPG itself (the web app used to annotate files)

## Changeset
**Definition**: The set of files that have been modified, added, renamed, or deleted on the current branch relative to the base branch (typically `main`). Determined using `git diff --name-status` against the merge base.
**Also known as**: Changed files, diff set
**Not to be confused with**: A git commit (a changeset may span multiple commits)

## File Filtering
**Definition**: The heuristic process of excluding uninteresting files from the review changeset. Filters out lockfiles, generated/build output, binary files, IDE config, and snapshot files based on path patterns. Does not read file contents.
**Also known as**: Noise filtering, file exclusion
**Not to be confused with**: Git's `--diff-filter` flag (which filters by change type like added/deleted)

## Merge Base
**Definition**: The most recent common ancestor commit between the current branch and a base branch (typically `main`). Used by `/shepherd-review` to determine the exact point where the feature branch diverged, ensuring only branch-specific changes are included in the changeset. Computed via `git merge-base HEAD main`.
**Also known as**: Branch point, divergence point
**Not to be confused with**: The tip of the base branch (which may have moved forward since the branch was created)

## Review Iteration Loop
**Definition**: The interactive cycle in `/shepherd-review` where the agent announces a file, opens it in the CRPG via `/shepherd`, waits for the user to finish, and then moves to the next file. The user controls pace with commands: next, skip, list, quit.
**Also known as**: Review loop, iteration loop
**Not to be confused with**: The engineering-QA iteration loop (which is a development process, not a user-facing feature)

## Slash Command Mode
**Definition**: The operational state of the CRPG when it was launched via the `/shepherd` slash command (i.e., the file was loaded from a `?file=` URL parameter via the local server API). In this mode, the Done button is visible in the toolbar, enabling the prompt feedback loop. The CRPG typically opens in an app-mode browser window (no address bar or tabs). The mode is tracked in the app's state and resets when the session is cleared.
**Also known as**: Server mode, agent-connected mode
**Not to be confused with**: Standalone mode (when the CRPG is used via paste/upload/drag-drop without the slash command)

## App-Mode Window
**Definition**: A browser window opened with Chrome/Chromium's `--app` flag that removes all browser chrome (address bar, tab strip, navigation buttons). The CRPG appears as a standalone application rather than a website. App-mode windows allow `window.close()` to work, enabling auto-close after the Done action. If Chrome is not available, the CRPG falls back to a regular browser tab.
**Also known as**: Chromeless window, standalone window, app window
**Not to be confused with**: A regular browser tab (which has address bar, tabs, and does not allow `window.close()`)

## Prompt Handoff
**Definition**: The mechanism by which the generated prompt is sent from the CRPG web app back to the AI coding agent. The CRPG POSTs the prompt to the local server's `/api/prompt-output` endpoint, which writes it to `~/.shepherd/prompt-output.md`. A file watcher running in the agent's terminal detects the file and feeds its contents back to the agent.
**Also known as**: Feedback loop, prompt return path
**Not to be confused with**: Prompt copy (which puts the prompt on the clipboard for manual pasting)

## Prompt Output File
**Definition**: A temporary file at `~/.shepherd/prompt-output.md` used as the handoff mechanism between the CRPG and the AI agent. Written by the server when the user clicks Done, read by the agent's file watcher, and deleted immediately after reading. Stale files from previous sessions are cleaned up on each new slash command invocation.
**Also known as**: Output file, handoff file
**Not to be confused with**: The generated prompt (which is the content written to the file, not the file itself)
<!--
Entry template:

## Term Name
**Definition**: What it means in the context of this project.
**Also known as**: [Any synonyms that should redirect here]
**Not to be confused with**: [Similar terms that mean something different]
-->
