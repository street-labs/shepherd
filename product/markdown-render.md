# Markdown Rendered View

## Overview

An alternative rendering mode for the Code Review Prompt Generator (CRPG) that displays markdown files as formatted HTML rather than raw syntax-highlighted source. When a markdown file (`.md`, `.mdx`, `.markdown`) is loaded, the user can toggle between a **rendered view** (headings, bold, lists, tables, code blocks, etc. displayed as formatted HTML) and the existing **raw view** (syntax-highlighted markdown source with line numbers).

This feature addresses a key limitation of the current CRPG: when reviewing markdown files (READMEs, documentation, specs), the raw markdown source is harder to scan than rendered output. A developer reviewing AI-generated changes to a README wants to see what the document *looks like*, not just the markup that produces it. The rendered view shows the document as end users will see it, while still supporting the core CRPG workflow of adding inline comments and generating structured prompts.

The rendered view integrates with the existing diff view feature (`product/diff-view.md`). When diff mode is active for a markdown file, the user can see a **rendered diff** that highlights what changed in the rendered output — additions, removals, and modifications shown inline in the formatted HTML, similar to track-changes in a word processor. This is the most complex aspect of the feature and is partially deferred to v2 (see Open Questions).

### View Mode Matrix

With this feature, markdown files have four possible view combinations:

| Raw/Rendered | File/Diff | Description |
|---|---|---|
| Raw + File | Existing behavior | Full file with syntax-highlighted markdown source and line numbers |
| Raw + Diff | Existing behavior | Unified diff of raw markdown source (added/removed lines) |
| Rendered + File | **New** | Markdown rendered as formatted HTML |
| Rendered + Diff | **New (v1 limited)** | Rendered markdown with visual diff annotations showing what changed |

Non-markdown files continue to show only raw views (the rendered/raw toggle is hidden).

## User Stories

### US-MDR-1: View rendered markdown
**As a** developer reviewing a markdown file, **I want to** see the file rendered as formatted HTML (headings, lists, tables, code blocks), **so that** I can read the document as end users will see it rather than parsing raw markup in my head.

### US-MDR-2: Toggle between rendered and raw views
**As a** developer reviewing a markdown file, **I want to** switch between the rendered HTML view and the raw syntax-highlighted source, **so that** I can choose whichever perspective is most useful — rendered for reading comprehension, raw for editing precision.

### US-MDR-3: Comment on rendered markdown
**As a** developer reviewing rendered markdown, **I want to** add comments anchored to specific rendered elements (paragraphs, headings, list items, code blocks), **so that** I can annotate the document at the semantic level rather than needing to know which raw lines produce a given paragraph.

### US-MDR-4: See what changed in rendered markdown
**As a** developer reviewing AI-generated markdown changes, **I want to** see the diff rendered as formatted HTML with additions and removals visually highlighted, **so that** I can understand how the changes affect the document's final appearance without mentally parsing unified diff notation.

### US-MDR-5: Comment on rendered diffs
**As a** developer reviewing a rendered markdown diff, **I want to** add comments on specific changed elements in the rendered output, **so that** I can provide feedback on the visual result of the changes, not just the raw markup changes.

### US-MDR-6: Toggle is only for markdown
**As a** developer working with non-markdown files, **I want** the rendered/raw toggle to be absent (not just disabled), **so that** the UI stays clean and I am not confused by an irrelevant control.

## Requirements

### Functional Requirements

#### `FR-mdr-detect-markdown` -- Detect markdown files for rendered view availability
When a file is loaded, the application detects whether it is a markdown file by checking the file extension (case-insensitive). Recognized extensions are: `.md`, `.mdx`, `.markdown`, `.mdown`, `.mkdn`, `.mkd`. This detection uses the same mechanism as the existing language detection in `FR-crp-syntax-highlight`, which already identifies Markdown as a supported language. When a markdown file is detected, the rendered/raw toggle becomes available. For non-markdown files, the toggle is not present at all (hidden, not disabled — unlike the diff toggle which shows as disabled for paste/upload files per `FR-diff-mode-availability`).

#### `FR-mdr-render-toggle` -- Toggle between rendered and raw views
The application provides a toggle control (e.g., a segmented button or icon toggle) that switches between "Raw" view (the existing syntax-highlighted code viewer) and "Rendered" view (the formatted HTML output). The toggle is located in the toolbar, adjacent to the existing File/Diff toggle. The default view for markdown files is **Raw** (consistent with the existing behavior — rendering is opt-in, not a surprise). The toggle state persists within the session but resets when a new file is loaded.

This toggle is **independent** of the File/Diff toggle. Both can be set simultaneously, producing four combinations (see View Mode Matrix in Overview). The rendered/raw toggle controls *how* the content is displayed; the File/Diff toggle controls *what* content is displayed.

#### `FR-mdr-render-commonmark` -- Render markdown as formatted HTML
The rendered view converts the markdown source into formatted HTML and displays it in the code viewer area. The renderer must support **CommonMark** as the baseline spec, plus the following **GitHub Flavored Markdown (GFM)** extensions:
- Tables (pipe tables with alignment)
- Task lists (checkboxes in list items)
- Strikethrough (`~~text~~`)
- Autolinks (bare URLs converted to links)

The rendered output must also handle:
- Fenced code blocks with syntax highlighting (using the same syntax highlighting engine as `FR-crp-syntax-highlight`)
- Inline code spans
- Block quotes
- Nested lists (ordered and unordered, up to 4 levels)
- Images (rendered as `<img>` tags; images that fail to load show alt text)
- Horizontal rules
- HTML blocks embedded in markdown (rendered as-is when safe; script tags and event handlers are stripped for security)

The rendered output is **read-only** — the user cannot edit the markdown through the rendered view.

#### `FR-mdr-render-styling` -- Rendered view styling matches code review context
The rendered markdown view uses a styling theme that is consistent with the code review tool aesthetic. Styled consistently with the application's visual theme. Code blocks within the rendered view use the same syntax highlighting engine and theme as the raw code viewer. Specific visual treatments (typography, spacing, heading styles, table presentation, maximum content width) are design decisions.

#### `FR-mdr-element-id` -- Assign stable identifiers to rendered elements
Each rendered block-level element (heading, paragraph, list item, code block, table, blockquote, horizontal rule, image) is assigned a stable identifier based on its position in the document structure. The identifier encodes the element's structural path (e.g., `heading-0`, `paragraph-3`, `list-1-item-2`). These identifiers are used for comment anchoring in the rendered view.

The identifiers must be **deterministic** — rendering the same markdown source always produces the same identifiers. They are positional (based on AST node index), not content-based, because content may be duplicated (e.g., multiple paragraphs could have the same text).

#### `FR-mdr-rendered-comment-create` -- Create comments on rendered elements
In the rendered view, the user can add inline comments anchored to specific rendered elements. The interaction model differs from the raw view's line-number-based clicking:
- When the user directs attention to a rendered block element (paragraph, heading, list item, code block, table, blockquote, image), a subtle highlight and a comment affordance appear, indicating the element is commentable. Tables are commentable as a whole unit (not per-row); the comment anchors to the entire table element.
- Clicking the comment icon (or the element itself, with a modifier key like Cmd/Ctrl+click) opens the inline comment editor anchored to that element.
- The comment is associated with the element's stable identifier (`FR-mdr-element-id`).
- Multiple comments can be attached to the same element.
- Comments are displayed as comment bubbles below the rendered element they are anchored to, visually similar to the existing comment bubbles in the raw view.

This creates a **separate comment store** for rendered-mode comments (analogous to the separate stores for file-mode and diff-mode comments per the decision in `decisions.md`). Rendered-mode comments anchor to AST element identifiers; raw-mode comments anchor to line numbers; diff-mode comments anchor to diff line identifiers.

#### `FR-mdr-rendered-comment-prompt` -- Generate prompts from rendered-view comments
When generating a prompt from the rendered view, comments are paired with the **raw markdown source lines** that produce the rendered element the comment is anchored to. The prompt includes the original markdown source (not the rendered HTML), because the AI agent needs to modify the source, not the rendered output.

Each comment in the prompt references the element type and the source lines. For example:
```
- **Heading (lines 15-15)**:
  ```markdown
  ## API Reference
  ```
  Comment: "This heading should be level 3, not level 2."
```

The prompt format follows the same overall structure as `FR-crp-prompt-format` (instructions section, file heading, requested changes section).

#### `FR-mdr-switch-comments` -- Comment behavior when switching between rendered and raw views
Switching between rendered and raw views **clears comments with confirmation**, consistent with the mode-switching behavior established in `FR-diff-mode-toggle`. The confirmation dialog warns the user that comments will be lost. If no comments exist, switching is immediate with no dialog.

This is a deliberate v1 scoping decision. Mapping rendered-element comments to raw-line comments (and vice versa) is technically possible via the AST-to-line mapping but introduces edge cases (e.g., a comment on a rendered paragraph that spans 5 raw lines — which line does it map to?). Deferring this to v2 keeps the feature simpler and avoids surprising behavior.

#### `FR-mdr-raw-diff-unchanged` -- Raw diff view is unchanged for markdown
When viewing a markdown file in Raw + Diff mode, the existing diff view behavior (`FR-diff-display`, `FR-diff-collapse`, etc.) applies without modification. The rendered/raw toggle does not affect diff functionality in raw mode.

#### `FR-mdr-rendered-diff-display` -- Display rendered diff with change annotations
When the rendered/raw toggle is set to "Rendered" and the File/Diff toggle is set to "Diff", the application shows a **rendered diff view**. This view renders the new (working copy) version of the markdown as HTML, with visual annotations indicating what changed relative to the baseline (HEAD) version:

- **Added text**: Highlighted with a green background and a left-border accent. Entire added blocks (new paragraphs, new headings, new list items) are wrapped in an addition indicator.
- **Removed text**: Displayed as strikethrough with a red/muted background. Removed blocks are shown in their original position with a deletion indicator. Removed content is rendered from the baseline version's markdown.
- **Modified text**: When a block exists in both versions but its content differs, the rendered diff shows the new version with inline annotations: removed words/phrases use strikethrough with a red background, added words/phrases use a green background. This is similar to word-level diff highlighting in Google Docs' suggestion mode.
- **Unchanged blocks**: Displayed normally with no annotations.

The diff is computed at the **AST block level**: the application parses both the HEAD and working copy versions into ASTs, diffs the ASTs to identify added, removed, modified, and unchanged blocks, and renders the result. For modified blocks, a word-level diff is applied to the text content to produce inline change annotations.

If the AST-level diff produces an unreadable result (e.g., the structure changed so dramatically that every block is "modified"), the rendered diff view falls back to showing the new version with a banner indicating that too many structural changes occurred for rendered diff to be useful, and recommends switching to raw diff view.

#### `FR-mdr-rendered-diff-comment` -- Comment on rendered diff elements
In the rendered diff view, the user can add comments on any rendered element — added, removed, modified, or unchanged. The comment anchoring uses the same element identifier system as `FR-mdr-element-id`, extended with a change-type qualifier (e.g., `added:heading-3`, `removed:paragraph-5`, `modified:list-1-item-2`). Comments on removed elements reference the baseline version's element identifiers.

#### `FR-mdr-rendered-diff-prompt` -- Generate prompts from rendered diff comments
When generating a prompt from the rendered diff view, comments are paired with both the old and new raw markdown source for the referenced element (when applicable). Modified elements show a mini unified diff of just that element's source. Added elements show only the new source. Removed elements show only the old source. The format makes clear to the AI agent what the original text was, what it was changed to, and what feedback the reviewer has.

### Non-Functional Requirements

#### `NFR-mdr-render-perf` -- Markdown rendering performance
Markdown rendering (parsing + HTML generation) must complete within 200ms for files up to 5,000 lines. For files between 5,000 and 10,000 lines, rendering should complete within 500ms. The rendering runs on the main thread; if files are large enough to block UI for more than 100ms, rendering should not block UI interaction. This budget includes both the markdown parsing and the syntax highlighting of fenced code blocks within the rendered output.

#### `NFR-mdr-render-scroll-perf` -- Rendered view scroll performance
The rendered view must scroll smoothly for markdown files up to 10,000 lines. Unlike the raw view which uses virtualized scrolling (`NFR-crp-large-file-perf`), the rendered view produces a single HTML document. For very large markdown files (> 5,000 lines), the rendered view may use platform-appropriate optimizations for rendering performance, since rendered markdown elements are heterogeneous and harder to virtualize than uniform code lines.

#### `NFR-mdr-rendered-diff-perf` -- Rendered diff computation performance
The AST-level diff computation (parse both versions, diff the ASTs, compute word-level diffs for modified blocks) must complete within 1 second for files up to 5,000 lines. For files between 5,000 and 10,000 lines, the computation should complete within 3 seconds. A visual indication of computation in progress is shown. If the computation exceeds 5 seconds, the application cancels it and falls back to raw diff view with a message explaining that the file is too large for rendered diff.

#### `NFR-mdr-xss-safety` -- Rendered markdown must be XSS-safe
The markdown renderer must sanitize the HTML output to prevent cross-site scripting (XSS) attacks. This is especially important because markdown can contain embedded HTML blocks. The sanitization must strip: `<script>` tags, event handler attributes (e.g., `onclick`, `onerror`), `javascript:` URLs, and any other active content vectors. The sanitization must be applied *after* rendering but *before* the output is inserted into the live view. This is a security requirement, not a feature — it is not optional.

#### `NFR-mdr-client-only` -- Rendered view is client-side only
Consistent with `NFR-crp-client-only`, all markdown rendering, AST diffing, and comment anchoring happen locally. No markdown content is sent to any external service.

#### `NFR-mdr-accessibility` -- Rendered view accessibility
The rendered view must be navigable via keyboard. Commentable elements must be reachable through keyboard navigation. The commenting affordance must be reachable via keyboard, not solely by pointer. Screen readers must be able to read the rendered content. Diff annotations (added, removed) must be announced to screen readers using appropriate ARIA labels, not just communicated via color.

## Acceptance Criteria

#### `AC-mdr-toggle-appears` -- Rendered/raw toggle appears for markdown files
**Given** a markdown file (e.g., `README.md`) is loaded, **when** the code viewer renders, **then** a rendered/raw toggle control is visible in the toolbar alongside the existing File/Diff toggle, and it defaults to "Raw".

#### `AC-mdr-toggle-hidden-non-md` -- Toggle is hidden for non-markdown files
**Given** a TypeScript file (e.g., `utils.ts`) is loaded, **when** the code viewer renders, **then** no rendered/raw toggle is visible in the toolbar. The toolbar looks identical to its pre-feature state for non-markdown files.

#### `AC-mdr-render-basic` -- Basic markdown renders correctly
**Given** a markdown file containing headings, paragraphs, bold text, italic text, links, and a bullet list is loaded, **when** the user switches to rendered view, **then** the content displays as formatted HTML with appropriately styled headings, bold/italic text, clickable links, and a bulleted list.

#### `AC-mdr-render-gfm` -- GFM extensions render correctly
**Given** a markdown file containing a pipe table, a task list with checkboxes, and strikethrough text is loaded, **when** the user switches to rendered view, **then** the table renders with aligned columns and bordered cells, the task list shows checkboxes (read-only), and strikethrough text appears with a line through it.

#### `AC-mdr-render-code-blocks` -- Fenced code blocks are syntax highlighted in rendered view
**Given** a markdown file containing a fenced TypeScript code block is loaded, **when** the user switches to rendered view, **then** the code block displays with the same syntax highlighting theme used in the raw code viewer, including colored keywords, strings, and comments.

#### `AC-mdr-raw-unchanged` -- Raw view is unchanged
**Given** a markdown file is loaded and the rendered/raw toggle is on "Raw", **when** the user views the file, **then** the display is identical to the existing behavior — syntax-highlighted markdown source with line numbers, gutter, and line-based comment clicking.

#### `AC-mdr-comment-rendered-element` -- Comment can be added on a rendered element
**Given** a markdown file is loaded in rendered view showing a paragraph, **when** the user hovers over the paragraph and clicks the comment icon, **then** an inline comment editor opens anchored below that paragraph. After submitting the comment, it appears as a comment bubble below the paragraph.

#### `AC-mdr-comment-heading` -- Comment can be added on a heading
**Given** a markdown file is loaded in rendered view showing an `## API Reference` heading, **when** the user adds a comment on that heading, **then** the comment is anchored to the heading element and the generated prompt references the raw markdown line `## API Reference`.

#### `AC-mdr-comment-prompt-format` -- Generated prompt from rendered view references raw source
**Given** a markdown file is loaded in rendered view with a comment on a paragraph that spans raw lines 10-14, **when** the user views the prompt preview, **then** the prompt contains the raw markdown source for lines 10-14 (not HTML), paired with the user's comment text.

#### `AC-mdr-switch-clears-comments` -- Switching views clears comments with confirmation
**Given** the user has added comments in rendered view, **when** the user switches to raw view, **then** a confirmation dialog warns that comments will be cleared. If confirmed, comments are cleared and the view switches. If cancelled, the view stays on rendered.

#### `AC-mdr-switch-no-comments` -- Switching views with no comments is immediate
**Given** no comments exist in the current view, **when** the user switches between rendered and raw views, **then** the switch happens immediately with no confirmation dialog.

#### `AC-mdr-rendered-diff-additions` -- Added content is highlighted in rendered diff
**Given** a markdown file has a new paragraph added in the working copy that does not exist in the HEAD version, **when** the user views the rendered diff, **then** the new paragraph is rendered as formatted HTML with a green background highlight and an addition indicator.

#### `AC-mdr-rendered-diff-removals` -- Removed content is shown in rendered diff
**Given** a markdown file has a paragraph that was removed in the working copy but exists in the HEAD version, **when** the user views the rendered diff, **then** the removed paragraph is rendered with strikethrough text, a red/muted background, and a deletion indicator.

#### `AC-mdr-rendered-diff-modifications` -- Modified content shows word-level changes
**Given** a paragraph in a markdown file was changed from "The API returns JSON data" to "The API returns XML data" in the working copy, **when** the user views the rendered diff, **then** the paragraph shows "JSON" with strikethrough and red background, and "XML" with a green background, with the surrounding unchanged text rendered normally.

#### `AC-mdr-rendered-diff-comment` -- Comment can be placed on a rendered diff element
**Given** the rendered diff view is active and shows a modified paragraph, **when** the user clicks the comment icon on that paragraph and submits a comment, **then** the comment is anchored to that modified element and appears as a comment bubble below it.

#### `AC-mdr-rendered-diff-prompt` -- Prompt from rendered diff includes old and new source
**Given** the rendered diff view is active with a comment on a modified paragraph, **when** the user views the prompt preview, **then** the prompt shows the old raw markdown source, the new raw markdown source, and the user's comment, so the AI agent can see what changed and what feedback was given.

#### `AC-mdr-html-sanitized` -- Embedded HTML in markdown is sanitized
**Given** a markdown file contains an embedded `<script>alert('xss')</script>` block, **when** the user switches to rendered view, **then** the script tag is stripped from the output and does not execute. The rest of the markdown renders normally.

#### `AC-mdr-large-file-renders` -- Large markdown file renders within performance budget
**Given** a markdown file with 5,000 lines is loaded, **when** the user switches to rendered view, **then** the rendered output appears within 200ms (per `NFR-mdr-render-perf`) and scrolling is smooth.

#### `AC-mdr-keyboard-comment` -- Comment can be added via keyboard in rendered view
**Given** the rendered view is active and the user navigates to a paragraph using Tab, **when** the user presses the designated key to add a comment (e.g., Enter or a shortcut), **then** the inline comment editor opens for that element without requiring mouse interaction.

#### `AC-mdr-diff-fallback` -- Rendered diff falls back for heavily restructured files
**Given** a markdown file where nearly every block has been restructured or rewritten, **when** the user views the rendered diff, **then** either the diff renders readably with inline annotations, or a fallback banner appears recommending the raw diff view, and the user can switch to raw diff with one click.

## Open Questions

1. **Comment mapping between rendered and raw views (v2)**: Should switching between rendered and raw views attempt to map comments via the AST-to-line-number relationship instead of clearing them? This is technically feasible (each AST node knows its source line range) but introduces edge cases: a comment on a rendered paragraph that spans 5 raw lines could map to the first line, the full range, or be ambiguous. Deferred to v2 to keep v1 behavior simple and predictable.

2. **Rendered diff complexity threshold**: What heuristic should trigger the "too many structural changes" fallback in `FR-mdr-rendered-diff-display`? Options: percentage of blocks changed (e.g., > 80%), absolute count of changed blocks, or Levenshtein distance of the AST. Needs engineering input on what produces the best user experience.

3. **Inline element commenting granularity**: Should the user be able to comment on inline elements within a paragraph (e.g., a specific bold phrase or link), or only on block-level elements (paragraphs, headings, list items)? v1 scopes to block-level only. Inline selection-based commenting (like Google Docs) could be a v2 enhancement.

4. **Image rendering and diffing**: How should images in markdown be handled in the rendered diff? If an image URL changed, the diff could show both the old and new images side-by-side, or just note that the URL changed. Needs design input.

5. **MDX component rendering**: `.mdx` files can contain JSX components. Should the rendered view attempt to render custom components, or treat them as opaque blocks with a placeholder? v1 treats JSX/component tags as opaque code blocks — they are displayed but not rendered as interactive components.

6. **Mermaid and diagram rendering**: Should fenced code blocks with `mermaid`, `plantuml`, or other diagram languages be rendered as diagrams in the rendered view? Deferred to v2 — they display as syntax-highlighted code blocks in v1.

7. **Table of contents / document outline**: Should the rendered view provide a mini table of contents or document outline derived from headings? This would be useful for navigating long documents. Deferred — not part of the core feature.

8. **Rendered diff for non-server files**: The rendered diff requires both HEAD and working copy versions (via `FR-diff-baseline-fetch`). Should rendered diff be available for paste/upload files that have no baseline? No — consistent with `FR-diff-mode-availability`, diff view (in any rendering mode) requires server-loaded files.

9. **Performance of AST-level diff**: The AST diffing approach (parse both versions, diff the trees) is more expensive than line-level diff. Should there be a lower file-size threshold for rendered diff compared to raw diff? Engineering should evaluate whether the 10,000-line limit from `NFR-diff-compute-perf` needs to be lowered for rendered diff.

## Dependencies

- **`FR-crp-syntax-highlight`**: The rendered view's fenced code blocks reuse the same syntax highlighting engine.
- **`FR-crp-file-display`**: The rendered view occupies the same code viewer area and shares the surrounding application layout.
- **`FR-crp-line-comment-create`**: The rendered view's comment creation interaction is modeled after the existing line-comment interaction, adapted for element-based anchoring.
- **`FR-crp-prompt-format`**: The rendered view's prompt generation follows the same structural format, with element-type annotations instead of line numbers.
- **`FR-diff-mode-toggle`**: The rendered/raw toggle is independent of but adjacent to the File/Diff toggle. Both toggles coexist in the toolbar.
- **`FR-diff-baseline-fetch`**: The rendered diff view requires the HEAD version, fetched through the same baseline-retrieval mechanism as the raw diff.
- **`FR-diff-compute`**: The raw diff computation is unchanged. The rendered diff uses a higher-level AST diff but still relies on the baseline/working-copy data model.
- **`NFR-crp-client-only`**: All rendering and diffing is client-side.
- **`NFR-crp-large-file-perf`**: The rendered view must meet comparable scrolling performance targets.
- **Markdown parsing**: A client-side CommonMark + GFM parser is required. The specific parser is an engineering decision.
- **HTML sanitization**: Rendered markdown must be sanitized client-side before display. The specific sanitizer is an engineering decision.
- **AST diff library or algorithm**: For rendered diff, an algorithm to diff markdown ASTs is required. This may be a custom implementation based on tree edit distance or a simpler block-matching heuristic. Selection and approach are engineering decisions.
