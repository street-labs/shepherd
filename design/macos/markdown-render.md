---
product-hash: 69829a16ab804671ab7c7469445cb1a699d3b2681aaf502ea3fececb4cf858bd
product-slugs: [AC-mdr-comment-heading, AC-mdr-comment-prompt-format, AC-mdr-comment-rendered-element, AC-mdr-diff-fallback, AC-mdr-html-sanitized, AC-mdr-keyboard-comment, AC-mdr-large-file-renders, AC-mdr-raw-unchanged, AC-mdr-render-basic, AC-mdr-render-code-blocks, AC-mdr-render-gfm, AC-mdr-rendered-diff-additions, AC-mdr-rendered-diff-comment, AC-mdr-rendered-diff-modifications, AC-mdr-rendered-diff-prompt, AC-mdr-rendered-diff-removals, AC-mdr-switch-clears-comments, AC-mdr-switch-no-comments, AC-mdr-toggle-appears, AC-mdr-toggle-hidden-non-md, FR-mdr-detect-markdown, FR-mdr-element-id, FR-mdr-raw-diff-unchanged, FR-mdr-render-commonmark, FR-mdr-render-styling, FR-mdr-render-toggle, FR-mdr-rendered-comment-create, FR-mdr-rendered-comment-prompt, FR-mdr-rendered-diff-comment, FR-mdr-rendered-diff-display, FR-mdr-rendered-diff-prompt, FR-mdr-switch-comments, NFR-mdr-accessibility, NFR-mdr-client-only, NFR-mdr-render-perf, NFR-mdr-render-scroll-perf, NFR-mdr-rendered-diff-perf, NFR-mdr-xss-safety]
---
# Markdown Rendered View — macOS Design Spec

> Based on requirements in `../../product/markdown-render.md`

## What We're Designing

A rendered markdown view mode for the macOS CRPG that displays markdown files as formatted HTML instead of raw syntax-highlighted source. Users can toggle between raw and rendered views, add comments on rendered elements (paragraphs, headings, lists), and see diffs with visual change annotations in the rendered output. This extends the existing code viewer to support semantic-level review of markdown documents.

## View Mode States

With this feature, markdown files have four view combinations. Each state builds on the existing Code Viewer Panel layout:

| Raw/Rendered | File/Diff | Code Viewer Panel Content |
|---|---|---|
| **Raw + File** | Existing | Syntax-highlighted markdown source with line numbers and gutter |
| **Raw + Diff** | Existing | Unified diff view of raw markdown source (added/removed lines) |
| **Rendered + File** | **New** | Formatted HTML rendering of the markdown with semantic element highlighting |
| **Rendered + Diff** | **New** | Formatted HTML rendering with visual diff annotations (additions, removals, modifications) |

Non-markdown files continue to show only raw views (the rendered/raw toggle is hidden per `FR-mdr-detect-markdown`).

---

## Toolbar: Rendered/Raw Toggle

### Toggle Control (`FR-mdr-render-toggle`, `AC-mdr-toggle-appears`)

**Location:** Toolbar, adjacent to the existing File/Diff segmented control.

**Visual Treatment:** A second segmented control with two segments: `Raw` and `Rendered`.

```
Toolbar Layout:
[Open] [File | Diff] [Raw | Rendered] [Wrap] [Copy] [Done]
       ^existing      ^new toggle
```

**Behavior:**
- **Default state:** `Raw` is selected when a markdown file is loaded.
- **File/Diff independence:** The rendered/raw toggle is independent of the File/Diff toggle. Both can be set simultaneously.
- **Session persistence:** The selected segment persists within the session but resets when a new file is loaded.
- **Visibility:** The toggle is **only visible** when a markdown file (`.md`, `.mdx`, `.markdown`, `.mdown`, `.mkdn`, `.mkd`) is loaded. For non-markdown files, the toggle is absent (hidden, not disabled) per `FR-mdr-detect-markdown` and `AC-mdr-toggle-hidden-non-md`.

**Interaction:**
- Clicking `Rendered` switches the Code Viewer Panel to rendered view.
- Clicking `Raw` switches back to raw view.
- If comments exist when switching, a confirmation dialog appears per `FR-mdr-switch-comments` (see Confirmation Dialog section below).

---

## Code Viewer Panel: Rendered File View

### Layout (`FR-mdr-render-commonmark`, `FR-mdr-render-styling`)

When `Rendered + File` mode is active, the Code Viewer Panel displays formatted HTML instead of syntax-highlighted source:

```
+------------------------------------------------------+
| FileHeader                                            |
| Review Context (collapsible, if available)            |
+------------------------------------------------------+
| +--------------------------------------------------+ |
| | Rendered Markdown Content                         | |
| | (scrollable, formatted HTML)                      | |
| |                                                   | |
| | # Heading Level 1                                 | |
| |                                                   | |
| | This is a **paragraph** with bold text.          | |
| |   [+ Comment bubble if comment exists]           | |
| |                                                   | |
| | - Bullet item 1                                   | |
| | - Bullet item 2                                   | |
| |   [+ Comment bubble if comment exists]           | |
| |                                                   | |
| | ```typescript                                     | |
| | const x = 42;  // syntax highlighted             | |
| | ```                                               | |
| |                                                   | |
| +--------------------------------------------------+ |
+------------------------------------------------------+
```

**Rendering:**
- **Prose content:** Rendered with system fonts, respecting macOS text rendering conventions.
- **Headings:** Styled with progressively larger font sizes (H1 largest → H6 smallest), bold weight, vertical spacing.
- **Lists:** Rendered with proper bullets (unordered) or numbers (ordered), indentation for nesting (up to 4 levels per `FR-mdr-render-commonmark`).
- **Tables:** Bordered cells with alignment per GFM pipe table syntax (`FR-mdr-render-commonmark`).
- **Code blocks:** Fenced code blocks use the same TreeSitter syntax highlighting as the raw view, maintaining visual consistency per `FR-mdr-render-styling`.
- **Inline code:** Monospace font, subtle background fill to distinguish from prose.
- **Links:** Clickable, styled with underline and/or color. Clicking opens in the default browser.
- **Images:** Rendered as `<img>` tags. If the image fails to load, alt text is displayed.
- **Task lists:** Checkboxes rendered but read-only (GFM extension per `FR-mdr-render-commonmark`).
- **Strikethrough:** Text with line-through decoration (GFM extension).

**Content Width:**
- Maximum content width of 800pt to maintain readability (prevents extremely long lines).
- Content is horizontally centered within the available panel width.
- On narrow windows, content reflows to fit.

**Scrolling:**
- Vertical scroll only. The rendered content is a single continuous HTML document.
- Scroll performance per `NFR-mdr-render-scroll-perf` (smooth for files up to 10,000 lines).

### Comment Interaction (`FR-mdr-rendered-comment-create`, `AC-mdr-comment-rendered-element`)

**Hover Affordance:**
When the user hovers over a commentable rendered element (paragraph, heading, list item, code block, table, blockquote, image), the element receives a subtle hover state:

- **Visual treatment:** Light background tint (slightly lighter in light mode, slightly darker in dark mode), 4pt border radius.
- **Comment icon:** A small circular `+` icon appears in the left margin aligned with the element's first line, similar to the gutter icon in raw view.
- **Interactive area:** The entire element and the `+` icon are clickable.

**Click to Comment:**
- **Mouse:** Click the `+` icon or Cmd+click anywhere on the element.
- **Keyboard:** Tab-navigate to the element, press Enter or a designated shortcut (e.g., Cmd+/) to open the comment editor per `NFR-mdr-accessibility` and `AC-mdr-keyboard-comment`.

**Comment Editor:**
An inline comment text field appears **below** the rendered element, similar to the existing line comment editor:

```
| This is a **paragraph** with bold text.          |
|   [+ Comment bubble if comment exists]           |
|   +---------------------------------------------+ |
|   | [Comment text editor]                       | |
|   | [Cancel] [Submit]                            | |
|   +---------------------------------------------+ |
```

After submission, the comment appears as a comment bubble below the element.

**Multiple Comments:**
Multiple comments can be attached to the same element. They stack vertically below the element.

**Element Identification (`FR-mdr-element-id`):**
Each rendered element is assigned a stable identifier (e.g., `heading-0`, `paragraph-3`, `list-1-item-2`) based on its AST position. This identifier is used for comment anchoring and remains deterministic across re-renders.

---

## Code Viewer Panel: Rendered Diff View

### Layout (`FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications`)

When `Rendered + Diff` mode is active, the Code Viewer Panel displays the new (working copy) version of the markdown rendered as HTML, with visual annotations showing what changed relative to the baseline (HEAD):

```
+------------------------------------------------------+
| FileHeader                                            |
| Review Context (collapsible, if available)            |
+------------------------------------------------------+
| +--------------------------------------------------+ |
| | Rendered Markdown Diff                            | |
| |                                                   | |
| | # Heading Level 1                                 |
| |   (unchanged — rendered normally)                |
| |                                                   | |
| | This paragraph was added in the working copy.    | |
| |   ┃ Green left border + light green background   | |
| |   ┃ [+ Added] indicator                          | |
| |                                                   | |
| | This paragraph was removed from the baseline.    | |
| |   ┃ Red left border + strikethrough              | |
| |   ┃ [- Removed] indicator                        | |
| |                                                   | |
| | This paragraph changed from JSON to XML.         | |
| |   The API returns ~~JSON~~ XML data.             | |
| |   ┃ Strikethrough (red bg) + green highlight     | |
| |                                                   | |
| +--------------------------------------------------+ |
+------------------------------------------------------+
```

**Visual Annotations:**

**Added Blocks:**
- Entire element (paragraph, heading, list item, etc.) rendered with:
  - Light green background tint
  - 4pt green left border accent
  - `[+ Added]` badge in the left margin or top-left corner

**Removed Blocks:**
- Entire element rendered with:
  - Light red/muted background tint
  - Strikethrough text decoration
  - 4pt red left border accent
  - `[- Removed]` badge in the left margin or top-left corner

**Modified Blocks:**
- Element rendered with inline word-level diff:
  - **Removed words/phrases:** Strikethrough text with light red background highlight
  - **Added words/phrases:** Light green background highlight
  - Unchanged surrounding text rendered normally
- The net effect resembles Google Docs "suggestion mode" or Microsoft Word "track changes"

**Unchanged Blocks:**
- Rendered normally with no annotations.

**Diff Computation:**
The diff is computed at the AST block level: both HEAD and working copy are parsed into ASTs, the ASTs are diffed to identify added/removed/modified/unchanged blocks, then rendered. Modified blocks receive a word-level diff per `FR-mdr-rendered-diff-display`.

**Fallback for Heavily Restructured Files (`AC-mdr-diff-fallback`):**
If the AST diff produces an unreadable result (e.g., > 80% of blocks changed), a banner appears at the top of the rendered view:

```
+------------------------------------------------------+
| [⚠] Too many structural changes for rendered diff.   |
|     [Switch to Raw Diff] to see line-level changes.  |
+------------------------------------------------------+
```

Clicking the button switches to `Raw + Diff` mode immediately.

### Comment Interaction (`FR-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-comment`)

**Hover Affordance:**
Same as rendered file view — hovering over any rendered element (added, removed, modified, or unchanged) shows a hover state and `+` icon.

**Element Identification:**
Elements in rendered diff view are identified with a change-type qualifier: `added:heading-3`, `removed:paragraph-5`, `modified:list-1-item-2`, `unchanged:paragraph-10`.

**Comment Editor:**
Same inline editor as rendered file view. Comments are anchored to the change-qualified element identifier.

---

## Confirmation Dialog: Switching Views with Comments

### Trigger (`FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`)

When the user switches between `Raw` and `Rendered` views (or vice versa) and comments exist in the current view, a confirmation dialog appears:

### Dialog Layout

```
+------------------------------------------------------+
| ⚠  Clear Comments?                                    |
|                                                      |
| Switching to [Raw/Rendered] view will clear your     |
| current comments. This cannot be undone.             |
|                                                      |
| [Cancel]                      [Clear and Switch]     |
+------------------------------------------------------+
```

**Behavior:**
- **Cancel:** Dismisses the dialog, stays in the current view.
- **Clear and Switch:** Clears all comments, switches to the selected view.

**No Comments Case (`AC-mdr-switch-no-comments`):**
If no comments exist, the view switches immediately with no dialog.

---

## Inspector Sidebar: Prompt Generation from Rendered Views

### Generated Prompt Format (`FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`)

When comments exist in rendered view, the prompt preview shows each comment paired with the **raw markdown source** that produces the rendered element (not HTML):

```
## File: README.md

**Heading (lines 15-15)**:
```markdown
## API Reference
```
Comment: "This heading should be level 3, not level 2."

**Paragraph (lines 20-23)**:
```markdown
The application provides a REST API for managing
user accounts. The API is authenticated via bearer
tokens and returns JSON responses.
```
Comment: "Clarify that tokens expire after 24 hours."
```

**Element Type Labels:**
- Heading, Paragraph, List Item, Code Block, Table, Blockquote, Image

**Line Number Range:**
Each element references the raw source lines it came from (derived from the AST node's source position per `FR-mdr-element-id`).

### Rendered Diff Prompt Format (`FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`)

When comments exist in rendered diff view, the prompt shows both old and new raw markdown source for modified elements, plus change type for added/removed elements:

```
## File: README.md (diff)

**Heading (added, lines 15-15)**:
```markdown
## New Section
```
Comment: "Good addition, but use title case."

**Paragraph (modified, lines 20-23 → 20-24)**:

Old:
```markdown
The API returns JSON data.
```

New:
```markdown
The API returns XML data with schema validation.
```
Comment: "Why switch from JSON to XML? This is a breaking change."

**Paragraph (removed, lines 30-32)**:
```markdown
This feature is deprecated and will be removed
in version 2.0.
```
Comment: "Update the migration guide before removing this."
```

**Change Type Labels:**
- `added` — element exists in working copy but not in HEAD
- `removed` — element exists in HEAD but not in working copy
- `modified` — element exists in both but content differs
- `unchanged` — element is identical (only shown if commented)

---

## Component Specs

### RenderedMarkdownView

A SwiftUI view that renders parsed markdown AST as formatted native views.

**Props:**
- `ast: MarkdownAST` — The parsed markdown document
- `elementIdentifiers: [String: MarkdownElement]` — Map of stable IDs to AST nodes
- `comments: [String: [Comment]]` — Comments keyed by element ID
- `diffAnnotations: [String: DiffChangeType]?` — Optional diff annotations (nil for file view, populated for diff view)
- `onCommentCreate: (String) -> Void` — Callback when user clicks to comment on an element

**States:**
- Hover state: Element under pointer receives visual hover treatment
- Keyboard focus: Element navigable via Tab, receives focus ring
- Comment editing: Inline editor appears below focused element

**Behavior:**
- Renders each AST node as native SwiftUI views (Text, VStack for paragraphs, HStack for lists, etc.)
- Syntax-highlighted code blocks use TreeSitter via SyntaxHighlightClient
- Click/keyboard interaction opens comment editor
- Comments displayed as comment bubbles below elements

### DiffAnnotationView

A wrapper view that applies diff visual annotations to rendered elements.

**Props:**
- `changeType: DiffChangeType` — `.added`, `.removed`, `.modified`, `.unchanged`
- `wordLevelChanges: [WordLevelDiff]?` — For modified blocks, word-level add/remove highlights
- `content: () -> some View` — The rendered element content

**Visual Treatment:**
- Added: Green left border, light green background, `[+ Added]` badge
- Removed: Red left border, strikethrough, light red background, `[- Removed]` badge
- Modified: Word-level highlights (red strikethrough for removed words, green background for added words)
- Unchanged: No annotations

---

## Accessibility

### Keyboard Navigation (`NFR-mdr-accessibility`, `AC-mdr-keyboard-comment`)

- **Tab traversal:** Each commentable element is focusable. Tab moves forward, Shift+Tab moves backward.
- **Focus indicator:** Focused element receives a visible focus ring.
- **Comment trigger:** Enter or Cmd+/ opens the comment editor for the focused element.
- **Comment editor navigation:** Tab moves through text field and buttons (Cancel/Submit). Enter submits. Escape cancels.

### Screen Reader Support

- **Element announcements:** Screen reader reads element type and content (e.g., "Heading level 2: API Reference").
- **Diff annotations:** Added/removed/modified state announced (e.g., "Paragraph, added: This paragraph was added in the working copy.").
- **Comment presence:** Elements with comments are announced as "Has comments" or similar.
- **ARIA labels:** Diff change badges (`[+ Added]`, `[- Removed]`) have ARIA labels for non-visual users.

---

## Interaction Flows

### Flow 1: View a markdown file in rendered mode

User has loaded a markdown file (`README.md`) and wants to see it rendered.

1. User clicks the `Rendered` segment in the toolbar.
2. The Code Viewer Panel transitions from syntax-highlighted source to formatted HTML rendering.
3. User scrolls through the rendered content, seeing headings, paragraphs, lists, tables, and syntax-highlighted code blocks.

### Flow 2: Add a comment on a rendered paragraph

User is reviewing a rendered markdown file and wants to comment on a specific paragraph.

1. User hovers over a paragraph → paragraph receives hover tint, `+` icon appears in left margin.
2. User clicks the `+` icon (or Cmd+clicks the paragraph).
3. Inline comment editor opens below the paragraph.
4. User types comment text, clicks Submit.
5. Comment bubble appears below the paragraph.
6. Inspector sidebar prompt preview updates to show the comment paired with the raw markdown source for that paragraph.

### Flow 3: Review a markdown diff in rendered mode

User has made changes to a markdown file and wants to see what changed in the rendered output.

1. User clicks the `Diff` segment in the toolbar → diff view loads (currently in raw mode).
2. User clicks the `Rendered` segment → rendered diff view appears.
3. Added paragraphs show with green background and `[+ Added]` badge.
4. Removed paragraphs show with strikethrough and `[- Removed]` badge.
5. Modified paragraphs show word-level highlights (strikethrough for removed words, green background for added words).
6. User hovers over a modified paragraph, clicks to comment on it.
7. Comment is anchored to the modified element. Prompt preview shows both old and new raw markdown source plus the comment.

### Flow 4: Switch from rendered to raw view with comments

User has added comments in rendered view and wants to switch back to raw view.

1. User clicks the `Raw` segment in the toolbar.
2. Confirmation dialog appears: "Switching to Raw view will clear your current comments. This cannot be undone."
3. User clicks `Cancel` → dialog dismisses, stays in rendered view.
4. User clicks `Raw` again, then clicks `Clear and Switch`.
5. Comments are cleared. View switches to raw syntax-highlighted source.

---

## Requirements Satisfied

This design addresses all requirements in `../../product/markdown-render.md`:

**Core Rendering:**
- `FR-mdr-detect-markdown` — Toggle only appears for markdown files
- `FR-mdr-render-toggle` — Segmented control in toolbar
- `FR-mdr-render-commonmark` — Full CommonMark + GFM rendering
- `FR-mdr-render-styling` — Consistent visual theme, syntax-highlighted code blocks
- `FR-mdr-element-id` — Stable identifiers for each rendered element

**Comments:**
- `FR-mdr-rendered-comment-create` — Hover affordance + click/keyboard interaction
- `FR-mdr-rendered-comment-prompt` — Prompt pairs comments with raw source
- `FR-mdr-switch-comments` — Confirmation dialog when switching views with comments

**Diff:**
- `FR-mdr-raw-diff-unchanged` — Raw diff view unaffected
- `FR-mdr-rendered-diff-display` — Visual diff annotations (added/removed/modified)
- `FR-mdr-rendered-diff-comment` — Comments on any diff element
- `FR-mdr-rendered-diff-prompt` — Prompt shows old/new source plus comments

**Non-Functional:**
- `NFR-mdr-render-perf` — Rendering completes within 200ms for 5k lines (engineering enforces)
- `NFR-mdr-render-scroll-perf` — Smooth scrolling (engineering enforces)
- `NFR-mdr-rendered-diff-perf` — Diff computation within 1s for 5k lines (engineering enforces)
- `NFR-mdr-xss-safety` — HTML sanitization (engineering enforces)
- `NFR-mdr-client-only` — All rendering is local (no external services)
- `NFR-mdr-accessibility` — Keyboard navigation + screen reader support

**Acceptance Criteria:**
All 20 acceptance criteria (`AC-mdr-*`) are addressed through the design patterns described above.
