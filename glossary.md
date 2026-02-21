# Glossary

Shared vocabulary for this project. All agents should use these terms consistently across product, design, engineering, and QA specs.

**Every agent must check this glossary before introducing a new term.** If a concept already has a name here, use it. If you need a new term, add it here first.

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
**Definition**: The structured text output produced by the application that aggregates the preamble, full file content with line numbers, and all inline comments in line order. Designed to be copied and pasted into an AI coding assistant.
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
**Definition**: The persistent horizontal bar fixed at the top of the application viewport (56px height). Contains the application title, comment navigation controls, comment count, and action buttons (Generate, Copy, Clear).
**Also known as**: Action bar, top bar
**Not to be confused with**: The sidebar panel (which is the right-side panel containing the preamble and prompt preview)

## Stale Prompt
**Definition**: A state indicating that the generated prompt is out of date because the user has modified comments or the preamble since the last generation. Visually indicated by a yellow banner in the prompt preview with a "Regenerate" link.
**Also known as**: Outdated prompt
**Not to be confused with**: An empty prompt (no prompt has been generated at all)

<!--
Entry template:

## Term Name
**Definition**: What it means in the context of this project.
**Also known as**: [Any synonyms that should redirect here]
**Not to be confused with**: [Similar terms that mean something different]
-->
