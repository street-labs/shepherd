# Glossary

Shared vocabulary for this project. All agents should use these terms consistently across product, design, engineering, and QA specs.

**Every agent must check this glossary before introducing a new term.** If a concept already has a name here, use it. If you need a new term, add it here first.

## Code Review Prompt Generator (CRPG)
**Definition**: The core application of the Shepherd project. A client-side web app that lets developers load one or more source files, annotate them with inline comments, and generate a single structured prompt for AI coding assistants. Supports multiple files simultaneously in a tabbed interface. Available as a local web app and (planned) as a standalone CLI.
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
**Definition**: The structured text output automatically produced by the application whenever comments or the preamble change. Aggregates the preamble and, for each file that has comments, the file content with code snippets paired with their inline comments. When multiple files have comments, the prompt includes a section per file. Designed to be copied and pasted into an AI coding assistant. There is no manual generation step — the prompt is always current when comments exist.
**Also known as**: Aggregated prompt, output prompt, combined prompt
**Not to be confused with**: Preamble (which is only one section of the generated prompt)

## Session
**Definition**: The current working state of the application: all loaded files, all inline comments across those files, and the preamble. A session exists only in browser memory and is lost on page reload (v1). A session can contain multiple files simultaneously.
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
**Definition**: The persistent horizontal bar fixed at the top of the application viewport (56px height). Contains the application title, comment navigation controls, comment count, theme toggle, and action buttons (Copy, Clear).
**Also known as**: Action bar, top bar
**Not to be confused with**: The sidebar panel (which is the right-side panel containing the preamble and prompt preview)

## Slash Command
**Definition**: A shortcut invoked by typing `/shepherd <filepath>` in a supported AI coding agent (e.g., Claude Code). Launches the CRPG web app with the specified file auto-loaded. Implemented as a Claude Code custom command (`.claude/commands/shepherd.md`) for in-repo use, and as a standalone CLI binary for global use.
**Also known as**: Custom command, agent command
**Not to be confused with**: Shell commands (executed in a terminal, not an agent conversation)

## Launcher Script
**Definition**: A shell script (`scripts/shepherd-launch.sh`) that encapsulates all slash command logic — file validation, server lifecycle management, URL encoding, and browser opening — in a single invocation. The slash command delegates to this script to minimize AI agent overhead and achieve sub-2-second warm launch times.
**Also known as**: shepherd-launch.sh, launch script
**Not to be confused with**: The slash command itself (which is the `.claude/commands/shepherd.md` prompt file that invokes the launcher script)

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
**Also known as**: Mode toggle, File/Diff toggle, ViewModeToggle (component name)
**Not to be confused with**: Rendered/Raw Toggle (which controls how content is displayed, not what content is shown), the toolbar action buttons (Copy, Clear)

## Diff Line Identifier
**Definition**: A unique identifier for a line in the diff view, encoding the line type (added, removed, or context) and the corresponding old and/or new line numbers. Used to anchor comments in diff mode, replacing the simple line number used in file mode.
**Also known as**: DiffLineId
**Not to be confused with**: Line number (used in file view for comment anchoring)

## Shepherd Review
**Definition**: A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Discovers the changeset of the current branch vs main, filters out uninteresting files, and batch-opens all reviewable files in a single CRPG session via the launcher script's multi-file support.
**Also known as**: Review command, batch review
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
**Definition**: The workflow in `/shepherd-review` where the agent discovers the changeset, filters files, prints a changeset overview with per-file context, and batch-opens all reviewable files in the CRPG. The user reviews files at their own pace using the CRPG's tab interface, then clicks Done to return a unified prompt. The agent processes the feedback and presents a completion summary.
**Also known as**: Review loop, batch-open loop
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

## Rendered View
**Definition**: An alternative display mode for markdown files in the CRPG that converts raw markdown source into formatted HTML output (headings, bold, lists, tables, code blocks, etc.). Available only for markdown files. The user can toggle between rendered view and raw view.
**Also known as**: Rendered mode, markdown preview, formatted view
**Not to be confused with**: Raw view (which shows syntax-highlighted markdown source with line numbers)

## Raw View
**Definition**: The default display mode for all files in the CRPG, showing syntax-highlighted source code with line numbers. For markdown files, this shows the markdown markup itself rather than its rendered output. For non-markdown files, this is the only available view.
**Also known as**: Source view, code view
**Not to be confused with**: Rendered view (which shows markdown formatted as HTML)

## Rendered/Raw Toggle
**Definition**: A toolbar control that switches between rendered view (formatted HTML) and raw view (syntax-highlighted source) for markdown files. Independent of the File/Diff toggle. Only visible when a markdown file is loaded; hidden for non-markdown files.
**Also known as**: Render toggle, markdown view toggle
**Not to be confused with**: View Mode Toggle (the File/Diff toggle), which controls what content is shown, not how it is rendered

## Element Identifier
**Definition**: A stable, deterministic identifier assigned to each block-level element in rendered markdown (e.g., `heading-0`, `paragraph-3`, `list-1-item-2`). Based on the element's position in the markdown abstract syntax tree (AST). Used to anchor comments in rendered view, analogous to how line numbers anchor comments in raw view and diff line identifiers anchor comments in diff view.
**Also known as**: Element ID, AST node ID, rendered anchor
**Not to be confused with**: Diff Line Identifier (used in diff view), line number (used in raw/file view)

## Rendered Diff
**Definition**: A viewing mode for markdown files that shows changes between HEAD and working copy as formatted HTML with visual annotations — green highlights for additions, strikethrough with red background for removals, and inline word-level change markers for modifications. Combines the rendered view with the diff view. Only available for markdown files loaded via the server.
**Also known as**: Rendered diff view, visual diff, formatted diff
**Not to be confused with**: Raw diff (which shows unified diff of markdown source with +/- line prefixes)

## AST Diff
**Definition**: A diff algorithm that operates on the abstract syntax tree (AST) representation of two markdown documents rather than on raw text lines. Identifies added, removed, modified, and unchanged blocks at the structural level (headings, paragraphs, list items, etc.). Used to produce the rendered diff view.
**Also known as**: Tree diff, structural diff
**Not to be confused with**: Line-level diff (used in raw diff view, computed by jsdiff)

## Horizontal Rule
**Definition**: A block-level markdown element that produces a horizontal dividing line (`---`, `***`, or `___` in markdown source). In the AST, this is represented as a `thematicBreak` node (the mdast/CommonMark name). The element identifier format is `thematic-break-{index}`.
**Also known as**: Thematic break (mdast/CommonMark term), `<hr>` (HTML element)
**Not to be confused with**: Block quote border (which is a left border on quoted content, not a horizontal line)

## Comment Affordance Column
**Definition**: A 32px-wide column on the left side of the rendered markdown view that shows comment interaction indicators. Displays a faint speech bubble icon on hover for commentable elements, and a filled blue dot for elements with existing comments. Functionally analogous to the Comment Gutter in the raw view, but adapted for element-level (rather than line-level) comment anchoring.
**Also known as**: C column (shorthand used in layout diagrams)
**Not to be confused with**: Comment Gutter (the equivalent column in the raw code viewer, which uses line-based indicators)

## Theme Preference
**Definition**: The user's chosen theme setting, stored as one of three values: `light`, `dark`, or `system`. When set to `system`, the app follows the OS color scheme. Stored in `localStorage` under the key `shepherd-theme`.
**Also known as**: Theme selection, theme mode
**Not to be confused with**: Resolved theme (the actual light/dark value applied after resolving `system` against the OS preference)

## Resolved Theme
**Definition**: The actual theme applied to the UI after resolving the user's theme preference. Always either `light` or `dark` — never `system`. If the preference is `system`, the resolved theme is determined by the OS `prefers-color-scheme` media query.
**Also known as**: Applied theme, effective theme
**Not to be confused with**: Theme preference (which can be `system`)

## Theme Toggle
**Definition**: A segmented control in the toolbar with three icon-only segments (sun for Light, moon for Dark, monitor for System) that lets users switch between theme preferences. Uses WAI-ARIA radio group pattern for keyboard accessibility.
**Also known as**: ThemeToggle (component name), theme switcher
**Not to be confused with**: View Mode Toggle (the File/Diff mode switcher, which is a separate toolbar control)

## FOUC
**Definition**: Flash of Unstyled Content (or in this context, Flash of Wrong Theme). The brief visual flicker that occurs when the page initially renders with one theme and then switches to another. Prevented in this app by a blocking `<script>` in `<head>` that sets the `data-theme` attribute on `<html>` before any CSS or React renders.
**Also known as**: Flash of unstyled content, theme flash
**Not to be confused with**: Smooth theme transitions (which are intentional animated changes during runtime theme switches)

## CSS Custom Properties
**Definition**: CSS variables (e.g., `var(--color-bg)`) used as the foundation of the theming system. All color values in the app reference these variables rather than hardcoded hex values. Two sets of values are defined — one for `[data-theme="light"]` and one for `[data-theme="dark"]` — allowing the entire UI to switch themes by changing a single attribute on the root element.
**Also known as**: CSS variables, theme tokens
**Not to be confused with**: Tailwind CSS utility classes (which are used for layout and spacing, not theming colors)

## Platform
**Definition**: A target runtime environment for the CRPG application. Each platform has its own tech stack, build system, and may have platform-specific UI/UX. The current platforms are: web (React/Vite in the browser) and macOS (native SwiftUI app, planned).
**Also known as**: Target platform
**Not to be confused with**: Operating system (a platform is more specific — "web" runs on multiple OSes, "macOS" is one OS with a native app)

## Base Spec
**Definition**: A spec file without a platform suffix (e.g., `code-review-prompt.md`). Represents either shared behavior across platforms or the web platform's spec (since web was the first platform). All existing unsuffixed spec files are base specs.
**Also known as**: Unsuffixed spec, web spec
**Not to be confused with**: Platform-specific variant (which has a `.<platform>.md` suffix)

## Platform-Specific Variant
**Definition**: A spec file with a platform suffix (e.g., `code-review-prompt.macos.md`) that documents how a feature diverges from its base spec on a particular platform. Only covers differences — shared behavior stays in the base spec.
**Also known as**: Platform variant, suffixed spec
**Not to be confused with**: Base spec (which covers shared or web-specific behavior)
## File Tab Bar
**Definition**: A horizontal tab bar displayed between the toolbar and the main content area when multiple files are loaded. Each tab shows a file name, an optional comment count badge, and a close (X) button. The "+" button at the end opens the file loading modal to add more files. Tabs are ordered by load order.
**Also known as**: FileTabBar (component name), tab strip
**Not to be confused with**: Browser tabs (which navigate between pages)

## Active File
**Definition**: The currently visible file in the code viewer. In a multi-file session, only one file is active at a time. Switching the active file preserves all comments and scroll position for the previously active file. Comments can only be added to the active file.
**Also known as**: Current file, selected file
**Not to be confused with**: Loaded files (all files in the session, most of which may be inactive)

<!--
Entry template:

## Term Name
**Definition**: What it means in the context of this project.
**Also known as**: [Any synonyms that should redirect here]
**Not to be confused with**: [Similar terms that mean something different]
-->
