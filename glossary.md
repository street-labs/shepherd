# Glossary

Shared vocabulary for this project. All agents should use these terms consistently across product, design, engineering, and QA specs.

**Every agent must check this glossary before introducing a new term.** If a concept already has a name here, use it. If you need a new term, add it here first.

## Code Review Prompt Generator (CRPG)
**Definition**: The core application of the Shepherd project. A native macOS application (SwiftUI + TCA) that lets developers load one or more source files, annotate them with inline comments, and generate a single structured prompt for AI coding assistants. Supports multiple files simultaneously in a file browser sidebar.
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
**Definition**: The current working state of the application: all loaded files, all inline comments across those files, and the preamble. A session exists only in the app's in-memory state for the lifetime of the window and is not persisted across relaunch (v1). A session can contain multiple files simultaneously. Each session is identified by a unique Session ID when launched via the `/shepherd` or `/shepherd-review` slash commands.
**Also known as**: Review session
**Not to be confused with**: Session ID (which is the unique identifier for a session, not the session state itself)

## Reviewer Identity
**Definition**: The Nostr identity under which the reviewer signs and publishes replies to a NIP-34 patch thread from within the Shepherd review tool. It takes one of two forms: a **local secret key** (`nsec`, see Local Secret Key) the reviewer holds, or a **bunker connection** (see Bunker) to a remote signer that holds the secret key on the reviewer's behalf. In both cases the app attributes published replies to the reviewer's public key; other participants resolve it to a display name via the roster. Both forms can be configured two ways: in-app via the Identity screen (log in with an existing `nsec` or `bunker://` URI, or generate a new local key), or out of band via environment variables and config files. For an in-app-created local identity the app generates and persists the key (in secure storage); for all other in-app or out-of-band forms the reviewer brings their own key or bunker URI.
**Also known as**: Reviewer Nostr identity, reviewer npub (when referring to the public-key half)
**Not to be confused with**: Patch author (the Nostr identity that published the patch being reviewed, not the reviewer's)

## Local Secret Key
**Definition**: The reviewer's Nostr secret key in bech32 form (`nsec1...`), or its 32-byte hex equivalent — the half of a Nostr keypair that signs events. Its corresponding public key is the `npub1...` / x-only pubkey that published events are attributed to. Shepherd loads a local secret key either from the in-app Identity screen (stored in secure storage) or from out-of-band sources (env var / config file), derives the public key in-process via secp256k1, and signs published replies with it. The secret key is held in memory for the app's lifetime and (for the in-app path) persisted in secure storage — never written to disk in plaintext.
**Also known as**: nsec, secret key, private key
**Not to be confused with**: Bunker (a remote signer that holds the secret key off-host, so the local machine never has it); npub (the public-key half, which is safe to share)

## Bunker
**Definition**: A NIP-46 remote signer — a service that holds a Nostr secret key and signs events on the reviewer's behalf over a Nostr relay, so the secret key never has to be present on the review host. Shepherd connects to a bunker via a `bunker://<remote-signer-pubkey>?relay=<wss-url>[&secret=<token>]` URI, runs the NIP-46 `connect` handshake, and delegates each `sign_event` to the bunker. The reviewer's public key is obtained from the bunker; the app holds no reviewer secret key in this mode.
**Also known as**: NIP-46 remote signer, remote signer
**Not to be confused with**: Local secret key / `nsec` (the in-process signing form, where the reviewer's key is loaded directly); Relay (the Nostr server the bunker communicates over, not the bunker itself)

## NIP-46
**Definition**: The Nostr remote-signing protocol (Nostr Connect) that lets a client delegate event signing to a remote bunker over a Nostr relay using NIP-44-encrypted kind `24133` request/response events. Shepherd uses NIP-46 only for the bunker identity form; the local-key form signs in-process and does not use NIP-46. The reviewer's (user) pubkey is obtained from the bunker via the `get_public_key` method after `connect`.
**Also known as**: Nostr Connect
**Not to be confused with**: NIP-44 (the authenticated-encryption scheme NIP-46 uses to encrypt its kind `24133` payloads); NIP-04 (the older direct-message encryption scheme, not used by Shepherd's bunker path); NIP-34 (the git-patch protocol, unrelated to signing)

## NIP-44
**Definition**: The Nostr authenticated-encryption scheme (ChaCha20-Poly1305 + HKDF, with an ECDH shared secret) used to encrypt NIP-46 kind `24133` control-channel payloads. Shepherd implements it via `P256K` (ECDH) + `CryptoKit` (`ChaChaPoly`, `HKDF`) — no AES-CBC, no new package dependency.
**Also known as**: nip44
**Not to be confused with**: NIP-04 (the older AES-CBC direct-message scheme, which NIP-46 no longer uses); NIP-46 (the remote-signing protocol that uses NIP-44 for payload encryption, not an encryption scheme itself)

## NIP-34 Patch
**Definition**: A Nostr event representing a git patch, per NIP-34 (the Nostr git protocol). Shepherd reviews kind `1617` (proposal) and `1621` (patch) events whose content is a unified diff and whose tags carry the repository coordinate (`a` tag, `30617:<owner>:<repo>`), commit hash, parent commit, author, and patch status (`open`/`merged`/`closed`/`draft`). A patch can be opened for review two ways: via the CLI (`/shepherd-review --patch <event-id>`, which applies it to a temporary git review branch) or in-app by entering its event reference in the Open Patch dialog (which loads the diff directly, no git repo required). Reviewers publish kind:1 Patch-Thread Replies against it.
**Also known as**: ngit patch, Nostr patch, patch event
**Not to be confused with**: Patch-Thread Reply (a kind:1 comment *on* a patch, not the patch itself); a git patch/commit in a local repo (a NIP-34 patch is a Nostr event that *contains* a unified diff)

## Patch-Thread Reply
**Definition**: A kind:1 Nostr text note published as a comment on a NIP-34 patch event, tagged with the patch event as the thread root (an `e` tag with the `root` marker) plus the repository `a` tag, and optionally a line-range anchor pinning it to a file and line span in the applied patch. Both other participants' replies (read by the review tool) and the reviewer's own published replies use this format.
**Also known as**: Patch reply, thread reply
**Not to be confused with**: Inline comment (a local annotation in the review tool; in a patch review, submitting an inline comment also publishes a patch-thread reply when a reviewer identity is loaded)

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
**Definition**: The application of color-coded formatting to source code tokens (keywords, strings, comments, types) based on the detected programming language. Powered by a native TreeSitter-based highlighter (swift-tree-sitter).
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
**Definition**: A shortcut invoked by typing `/shepherd <filepath>` in a supported AI coding agent (e.g., Claude Code or opencode). Launches the macOS CRPG app with the specified file auto-loaded. Implemented as a Claude Code or opencode custom command (`.claude/commands/shepherd.md`).
**Also known as**: Custom command, agent command
**Not to be confused with**: Shell commands (executed in a terminal, not an agent conversation)

## Launcher Script
**Definition**: A shell script (`scripts/shepherd-launch.sh`) that encapsulates all slash command logic — file validation, writing the session's `session.json` payload, and launching the prebuilt `ShepherdApp` binary with `--session <id>` — in a single invocation. The slash command delegates to this script to minimize AI agent overhead and achieve fast launch times.
**Also known as**: shepherd-launch.sh, launch script
**Not to be confused with**: The slash command itself (which is the `.claude/commands/shepherd.md` prompt file that invokes the launcher script)

## Working Copy
**Definition**: The current on-disk version of a file, including any uncommitted modifications. In the context of the diff view, the working copy is compared against the baseline (git HEAD) to produce the diff.
**Also known as**: Modified version, current version
**Not to be confused with**: Baseline (the git HEAD version), staged changes (git index — not used in v1)

## Diff View
**Definition**: An alternative viewing mode in the CRPG that displays a unified diff between a file's git HEAD version (baseline) and its current working copy on disk. Shows added lines (green), removed lines (red), and context lines, with collapsible unchanged sections. Only available for files loaded via the slash command.
**Also known as**: Diff mode, working copy diff
**Not to be confused with**: File view (the default full-file viewing mode), side-by-side diff (not supported in v1)

## Baseline
**Definition**: The reference version of a file used for diff computation. In v1, this is always the git HEAD version of the file.
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
**Definition**: A segmented control in the toolbar that switches between "File" (full-file view) and "Diff" (unified diff view) modes. Disabled when the file was not loaded via the slash command (paste/open files have no baseline to diff against). Switching modes clears comments with a confirmation dialog.
**Also known as**: Mode toggle, File/Diff toggle, ViewModeToggle (component name)
**Not to be confused with**: Rendered/Raw Toggle (which controls how content is displayed, not what content is shown), the toolbar action buttons (Copy, Clear)

## Diff Line Identifier
**Definition**: A unique identifier for a line in the diff view, encoding the line type (added, removed, or context) and the corresponding old and/or new line numbers. Used to anchor comments in diff mode, replacing the simple line number used in file mode.
**Also known as**: DiffLineId
**Not to be confused with**: Line number (used in file view for comment anchoring)

## Shepherd Review
**Definition**: A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Discovers the changeset of the current branch vs main, filters out uninteresting files, and batch-opens all reviewable files in a single CRPG session via the launcher script's multi-file support.
**Also known as**: Review command, batch review
**Not to be confused with**: The `/shepherd` command (which opens a single file), or the CRPG itself (the macOS app used to annotate files)

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
**Definition**: The workflow in `/shepherd-review` where the agent discovers the changeset, filters files, prints a changeset overview with per-file context, and batch-opens all reviewable files in the CRPG. The user reviews files at their own pace using the CRPG's file browser, then clicks Done to return a unified prompt. The agent processes the feedback and presents a completion summary.
**Also known as**: Review loop, batch-open loop
**Not to be confused with**: The engineering-QA iteration loop (which is a development process, not a user-facing feature)

## Slash Command Mode
**Definition**: The operational state of the CRPG when it was launched via the `/shepherd` slash command (i.e., the files were loaded from the launcher-written `session.json` payload). In this mode, the Done button is visible in the toolbar, enabling the prompt feedback loop. The mode is tracked in the app's state and resets when the session is cleared.
**Also known as**: Agent-connected mode
**Not to be confused with**: Standalone mode (when the CRPG is used via paste/open/drag-drop without the slash command)

## Prompt Handoff
**Definition**: The mechanism by which the generated prompt is sent from the macOS app back to the AI coding agent. When the user clicks Done, the app writes the prompt directly to the session's `prompt-output.md` file, which the agent reads after the interactive prompt.
**Also known as**: Feedback loop, prompt return path
**Not to be confused with**: Prompt copy (which puts the prompt on the clipboard for manual pasting)

## Prompt Output File
**Definition**: A session-scoped temporary file at `~/.shepherd/sessions/<session-id>/prompt-output.md` used as the handoff mechanism between the CRPG and the AI agent. Written by the macOS app when the user clicks Done, read by the agent after the interactive prompt, and deleted immediately after reading. Stale session directories from previous sessions (older than 24 hours) are cleaned up on each new slash command invocation.
**Also known as**: Output file, handoff file
**Not to be confused with**: The generated prompt (which is the content written to the file, not the file itself), Session Directory (which is the parent directory containing this file)

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
**Definition**: A viewing mode for markdown files that shows changes between HEAD and working copy as formatted HTML with visual annotations — green highlights for additions, strikethrough with red background for removals, and inline word-level change markers for modifications. Combines the rendered view with the diff view. Only available for markdown files loaded via the slash command.
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
**Definition**: A target runtime environment for the CRPG application. Each platform has its own tech stack, build system, and may have platform-specific UI/UX. The only platform is macOS (a native SwiftUI app). A web platform existed previously but has been removed.
**Also known as**: Target platform
**Not to be confused with**: Operating system (a platform is more specific — "macOS" is one OS with a native app)

## Shared Product Spec
**Definition**: A product spec file at the top level of `product/` (e.g., `product/code-review-prompt.md`). Contains platform-neutral requirements describing what a feature does. Design, engineering, and QA specs do not have shared base specs — they are always platform-specific.
**Also known as**: Base spec, product spec
**Not to be confused with**: Platform-specific specs (which live in platform subfolders like `design/macos/` or `engineering/macos/`)

## Platform-Specific Spec
**Definition**: A spec file in a platform subfolder (e.g., `design/macos/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`). For product, this supplements the shared spec with platform-specific requirements. For design, engineering, and QA, this is the primary spec (there is no shared base).
**Also known as**: Platform spec, platform variant
**Not to be confused with**: Shared product spec (which lives at the top level of `product/`)

## Session Directory
**Definition**: A directory at `~/.shepherd/sessions/<session-id>/` that holds session-scoped files. The directory holds `session.json` (the launcher-written payload that `ShepherdApp` reads at startup, with `reviewContext` embedded inline) and `prompt-output.md` (written when the user clicks Done). Created on demand. Cleaned up after the agent reads the output, or after 24 hours if stale. Each `/shepherd` or `/shepherd-review` invocation gets its own session directory, identified by its unique Session ID.
**Also known as**: Session folder, session-scoped directory
**Not to be confused with**: Session (which is the in-memory working state, not a filesystem directory)

## Session ID
**Definition**: A human-readable identifier derived from the working directory path, used to scope session state for each `/shepherd` or `/shepherd-review` invocation. The session ID is the slugified basename of the project/worktree directory (e.g., `my-project`, `shepherd-1`). The same worktree always produces the same session ID, providing deterministic session isolation. Used to scope the session directory and prompt output file path. Passed to the app via the `--session <id>` launch argument and included in the agent's output.
**Also known as**: Session identifier, project slug
**Not to be confused with**: Session (which is the working state identified by the session ID)

## FileBrowser
**Definition**: A vertical sidebar panel (default 240px, user-resizable via `FR-crp-panel-resize`) on the left side of the CRPG layout in multi-file mode. Presents all loaded files in a nested directory tree (similar to GitHub's pull request file browser). Within each directory, unreviewed files appear before reviewed files. Each file row shows the file name, comment count badge, review toggle, and remove button. Hovering a file row shows a tooltip with the full path, language, and review status (`FR-crp-file-tooltip`). The header contains a review progress indicator and an "Add file" button. Appears when two or more files are loaded; collapses to single-file layout when only one file remains.
**Also known as**: FileBrowser (component name), file sidebar, file browser panel
**Not to be confused with**: Browser file dialogs (which are OS-native file pickers)

## Active File
**Definition**: The currently visible file in the code viewer. In a multi-file session, only one file is active at a time. Switching the active file preserves all comments and scroll position for the previously active file. Comments can only be added to the active file.
**Also known as**: Current file, selected file
**Not to be confused with**: Loaded files (all files in the session, most of which may be inactive)

## Review Context
**Definition**: Structured data generated by the `/shepherd-review` command and displayed in the CRPG UI. Contains two distinct parts for the overall changeset and for each file: neutral context (factual description of what changed) and review feedback (the AI agent's subjective assessment). Files map keys are the same absolute path strings used in the file list, so the application can match per-file context to its tab. The launcher inlines the data into the session's `session.json` payload (the `reviewContext` field on `SessionData`) so the native binary loads it in a single read.
**Also known as**: Context data, review context data
**Not to be confused with**: Inline comments (which are user-authored annotations, not agent-generated context)

## Neutral Context
**Definition**: The factual, objective portion of review context. Describes what changed in the code without opinions — functions added/modified/removed, structural changes, file-level summary. Displayed with informational styling (blue tones) in the CRPG.
**Also known as**: "What Changed" section
**Not to be confused with**: Review feedback (which contains the agent's opinions)

## Review Feedback
**Definition**: The AI agent's subjective assessment portion of review context. Contains quality observations, potential concerns, suggestions, and things done well. Displayed with distinct styling (violet tones) in the CRPG to clearly indicate it is the agent's opinion, not objective fact.
**Also known as**: "Agent Review" section, agent feedback
**Not to be confused with**: Neutral context (which is purely factual), inline comments (which are user-authored)

## Review Context Panel
**Definition**: A collapsible UI component in the CRPG that displays review context data. Positioned inside the Code Viewer Panel. Contains two sections: overall changeset context (visible for all tabs) and per-file context (switches when the user changes tabs). Each section shows neutral context and review feedback as visually distinct sub-sections. Only visible when context data is available (slash command mode with shepherd-review).
**Also known as**: ReviewContextPanel (component name), context panel
**Not to be confused with**: Prompt Preview (which shows the generated prompt, not review context)

## Reviewed Status
**Definition**: A per-file boolean flag indicating whether the user considers a file "reviewed." Defaults to unreviewed for all files. Toggled manually by the user — the application never auto-marks a file. Persists within the session but not across relaunch. Independent of whether the file has comments. Used to drive file grouping in the FileBrowser sidebar, visual indicators, and the progress indicator.
**Also known as**: Review status, reviewed flag
**Not to be confused with**: Review feedback (the AI agent's assessment), inline comments (user annotations on specific lines)

## Review Status Bar
**Definition**: A compact horizontal bar inside the code viewer panel that provides the primary mechanism for toggling a file's reviewed status. Displays a checkbox and label ("Mark as reviewed" / "Reviewed") and a keyboard shortcut hint. Always visible when at least one file is loaded. The entire bar is clickable.
**Also known as**: ReviewStatusBar (component name)
**Not to be confused with**: FileBrowser (which lists all files in a sidebar), Toolbar (the top-level action bar)

## Review Progress Indicator
**Definition**: A compact text badge in the FileBrowser sidebar header showing the count of reviewed files versus total loaded files (e.g., "3/7 reviewed"). Only visible when two or more files are loaded (since the FileBrowser is only rendered in multi-file mode). Updates immediately on mark/unmark, file add, or file remove. Turns green when all files are reviewed.
**Also known as**: Progress indicator, reviewed count
**Not to be confused with**: Comment count (which tracks inline comments, not reviewed status)

## File Grouping
**Definition**: The organization of file rows within each directory in the FileBrowser's nested directory tree. Within each directory, unreviewed files are listed before reviewed files (so unreviewed files remain prominent). Reviewed files display visual indicators (green checkmark, muted text) at their tree position. The directory tree structure is the primary organizational axis; review status is a secondary visual layer. There are no separate "To Review" / "Reviewed" section headers — the directory tree with per-file reviewed indicators replaces the previous flat-list grouping model. When all files in a directory are reviewed, the directory node itself shows a reviewed indicator.
**Also known as**: File grouping, reviewed/unreviewed ordering
**Not to be confused with**: File ordering (which is load order within each review-status group within a directory)

## Resize Handle
**Definition**: A thin interactive drag handle (6px hit target) rendered on the right edge of the FileBrowser sidebar. Allows the user to resize the FileBrowser width by clicking and dragging horizontally. Shows a `col-resize` cursor on hover and a 3px blue visual indicator during hover/drag. Supports keyboard accessibility via `role="separator"` with `ArrowLeft`/`ArrowRight` (±10px) and `Home`/`End` (min/max). Double-clicking resets the FileBrowser to its default 240px width. Implements `FR-crp-panel-resize`.
**Also known as**: ResizeHandle (component name), drag handle, panel resizer
**Not to be confused with**: Browser window resize handles, CSS `resize` property

## Active File Path
**Definition**: A compact bar displayed at the top of the Code Viewer Panel in multi-file mode (when 2+ files are loaded). Shows the full relative file path (e.g., `src/components/FileBrowser.tsx`) of the currently active file, providing persistent context about which file is being viewed. Updates immediately when the user switches files. Uses CSS `direction: rtl` truncation so the filename (rightmost part) remains visible when the path is truncated. Only rendered in multi-file mode; in single-file mode, the FileHeader serves this purpose. Implements `FR-crp-active-file-path`.
**Also known as**: ActiveFilePath (component name), file path header, path bar
**Not to be confused with**: FileHeader (which is the single-file mode header), file breadcrumb (a different UI pattern with clickable path segments)

## File Tooltip
**Definition**: A tooltip that appears when the user hovers over a file row in the FileBrowser sidebar. Shows the full untruncated file path, detected language, and review status (e.g., "src/utils/helpers.ts -- TypeScript" or "config.json -- JSON -- Reviewed"). Uses a native tooltip. Essential because the sidebar has limited width and file names are commonly truncated. Implements `FR-crp-file-tooltip`.
**Also known as**: File row tooltip
**Not to be confused with**: Comment tooltips (which show comment text), button tooltips (which show keyboard shortcuts)

## All Comments
**Definition**: A summary view in the sidebar that displays every inline comment across all loaded files, organized by file. Implemented as a tab in the sidebar that can be toggled between the Prompt Preview and All Comments views. The summary is read-only and updates in real-time as comments are added, edited, or deleted. Implements `FR-crp-comment-summary`.
**Also known as**: All Comments tab, All Comments summary
**Not to be confused with**: Comment count (which is just a number), individual inline comments (which are line-specific annotations)

## Comment Summary
**Definition**: The React component that renders the All Comments summary view in the sidebar. Reads all comments across all files and displays them grouped by file name, with line references and comment text. Clicking a comment in the summary navigates to that file and focuses the comment.
**Also known as**: CommentSummary (component name)
**Not to be confused with**: All Comments (the feature), prompt preview (which shows the generated prompt)

## Overall Comment
**Definition**: A user-authored optional block of high-level instructions or context that applies to the entire review session (all loaded files). Appears at the top of the generated prompt in the "Instructions" section. Also known internally as the preamble, but labeled "Overall Comment" in the UI for clarity. The field's placeholder text indicates that it applies globally to all files.
**Also known as**: Preamble (internal name), high-level context, global comment
**Not to be confused with**: Inline comments (which are line-specific), per-file instructions (not supported in v1)

## ReviewContextSidebar
**Definition**: A collapsible component in the right sidebar that displays the overall changeset context (neutral description of what changed and the AI agent's review feedback) provided by the shepherd-review command. Positioned at the top of the sidebar, above the Overall Comment input. Only visible when review context data is available. Per-file context is shown separately in the ReviewContextPanel within the code viewer.
**Also known as**: ReviewContextSidebar (component name), sidebar context section
**Not to be confused with**: ReviewContextPanel (which displays per-file context in the code viewer), Sidebar Panel (the entire right-side panel)

## SidebarContentTabs
**Definition**: A segmented tab control in the sidebar that switches between two content areas: the "Preview" tab (showing the PromptPreview component) and the "All Comments" tab (showing the CommentSummary component). Positioned below the Overall Comment input. The All Comments tab displays a count badge showing the total number of comments when comments exist.
**Also known as**: SidebarContentTabs (component name), Preview/All Comments tabs, sidebar tabs
**Not to be confused with**: File Tab Bar (which switches between loaded files), view mode toggle (which switches between file/diff/rendered views)

## Lane Discipline
**Definition**: The principle that each functional area (product, design, engineering, QA) stays within its scope. Product describes what; design describes how it looks; engineering describes how it's built; QA describes how to verify. Specifically, product specs must not prescribe design solutions (pixel values, font choices, layout specifics) or engineering solutions (library names, API endpoints, algorithms, CSS properties).
**Also known as**: Separation of concerns (in the spec context)
**Not to be confused with**: Code separation of concerns (which is an engineering pattern within a single codebase)

## TCA
**Definition**: The Composable Architecture — a SwiftUI state management framework used in the macOS app. Provides unidirectional data flow, exhaustive testability via TestStore, controlled side effects via @Dependency, and a composable reducer tree. Every state transition is explicit and testable. Used exclusively in the macOS platform engineering implementation.
**Also known as**: The Composable Architecture
**Not to be confused with**: MVC or other architecture patterns (TCA is specifically a Swift/SwiftUI pattern)

## Reducer (TCA)
**Definition**: In TCA, a pure function that takes the current state and an action, and returns an updated state along with any effects to execute. Reducers compose into a tree structure mirroring the application's feature hierarchy. The root AppFeature reducer composes child feature reducers (FileBrowserFeature, CodeViewerFeature, etc.) using Scope. All state mutations happen within reducers.
**Also known as**: TCA reducer
**Not to be confused with**: JavaScript reducers (similar concept, different ecosystem)

## TreeSitter
**Definition**: A native syntax highlighting engine used in the macOS app. Parses source code using language-specific grammars to produce syntax tokens. Runs on a background thread to avoid blocking UI rendering. Supports all 13 required programming languages. The macOS platform uses swift-tree-sitter (native TreeSitter bindings).
**Also known as**: swift-tree-sitter (Swift bindings), TreeSitterHighlighter (the app's singleton)

## Inspector (macOS)
**Definition**: The right sidebar panel in the macOS app. Contains the ReviewContextSection (overall changeset context), Overall Comment editor, and Preview/All Comments tabs. Default width 340pt. Uses native macOS sidebar material and styling. The term "inspector" follows macOS conventions for detail/configuration sidebars.
**Also known as**: Inspector sidebar, right sidebar (macOS)
**Not to be confused with**: Sidebar (the generic term), file browser sidebar (the left panel in multi-file mode)

## Source List
**Definition**: A macOS sidebar style using vibrant background material under the sidebar appearance. The macOS file browser sidebar uses source list styling — standard for file/navigation trees in macOS apps. Provides selection highlighting, hover states, and tree disclosure indicators following macOS conventions.
**Also known as**: NSTableView source list (AppKit term)
**Not to be confused with**: Generic sidebar or tree view (source list is specifically a macOS UI pattern)

## SF Symbols
**Definition**: Apple's system icon library used throughout the macOS app. Provides vector icons that automatically adapt to system appearance (light/dark) and accessibility settings (high contrast, large text). Examples in the app: doc.badge.plus (Open button), checkmark.circle.fill (Done button), trash (delete), pencil (edit). All toolbar and menu icons use SF Symbols.
**Also known as**: San Francisco Symbols
**Not to be confused with**: Custom icons or icon fonts (SF Symbols are system-provided and platform-native)

## NavigationSplitView
**Definition**: A SwiftUI component that creates a three-column layout with resizable dividers. Used in the macOS app for multi-file mode (file browser, code viewer, inspector). Provides native split view behavior: user-resizable columns, keyboard accessibility, and state restoration. The split view divider between file browser and code viewer implements FR-crp-panel-resize.
**Also known as**: Three-column split view
**Not to be confused with**: HSplitView (two-column split view used in single-file mode)

## Feature Module (TCA)
**Definition**: A self-contained Swift package target representing a single functional area in the TCA architecture. Each feature module has its own reducer, state, actions, and views. Examples: FileBrowserFeature, CodeViewerFeature, InspectorFeature. Feature modules compose into the root AppFeature using Scope. Enables independent testing and clear boundaries between features.
**Also known as**: TCA feature, reducer module
**Not to be confused with**: React components or web modules (feature modules are TCA-specific)

## TestStore (TCA)
**Definition**: A TCA testing utility that provides exhaustive verification of state changes and effects. Used to test every reducer in the macOS app. TestStore assertions fail if any state mutation is unaccounted for or if effects don't match expectations. Supports dependency injection for deterministic testing with no mocks. The test pattern is: send action → assert state change → receive effect result action → assert state change.
**Also known as**: TCA TestStore
**Not to be confused with**: XCTest (the underlying testing framework — TestStore is a TCA-specific layer on top of it)

## Native Menu Bar
**Definition**: The macOS menu bar integration in the Shepherd app. Provides standard menus (Shepherd, File, Edit, View, Review, Window, Help) with keyboard shortcuts. Menu items reflect application state — for example, Copy Prompt is disabled when no comments exist. All keyboard shortcuts are discoverable through the menu bar. Defined using SwiftUI's @CommandsBuilder.
**Also known as**: macOS menu bar
**Not to be confused with**: Toolbar (the visual bar at the top of the window — the menu bar is the system-level menu at the top of the screen)

## App Bundle
**Definition**: The macOS application distribution format. A directory structure (Shepherd.app) containing the executable, resources, and metadata (Info.plist). Users install by dragging the .app bundle to /Applications. The bundle is signed with a Developer ID certificate and notarized for Gatekeeper compatibility. Distributed as a .dmg or .zip file.
**Also known as**: .app bundle, application bundle
**Not to be confused with**: Executable binary (the app bundle contains the binary plus all resources)

## Developer ID
**Definition**: An Apple-issued code signing certificate used to sign macOS applications distributed outside the App Store. The Shepherd app is signed with a Developer ID certificate, enabling Gatekeeper to verify the app's authenticity. Without Developer ID signing, users would see "unidentified developer" warnings on first launch.
**Also known as**: Developer ID certificate
**Not to be confused with**: App Store distribution (Developer ID is for direct distribution, not the App Store)

## Notarization
**Definition**: An Apple security process that scans macOS applications for malicious content and issues a notarization ticket. The Shepherd app is notarized via notarytool after code signing. Notarization is required for Gatekeeper to allow the app to run without warnings on macOS 10.15+. The notarization ticket is stapled to the .app bundle before distribution.
**Also known as**: Apple notarization, notarytool process
**Not to be confused with**: Code signing (notarization happens after signing and is a separate verification step)

## Gatekeeper
**Definition**: The macOS security system that verifies downloaded applications before allowing them to run. Checks for code signing and notarization. The Shepherd app must be signed with a Developer ID and notarized to pass Gatekeeper verification. When properly signed/notarized, users can open the app without encountering "unidentified developer" warnings (AC-crp-macos-signed-notarized).
**Also known as**: macOS Gatekeeper
**Not to be confused with**: macOS sandboxing (a separate security mechanism for App Store apps)

<!--
Entry template:

## Term Name
**Definition**: What it means in the context of this project.
**Also known as**: [Any synonyms that should redirect here]
**Not to be confused with**: [Similar terms that mean something different]
-->
