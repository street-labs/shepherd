---
product-hash: 69829a16ab804671ab7c7469445cb1a699d3b2681aaf502ea3fececb4cf858bd
product-slugs: [AC-mdr-comment-heading, AC-mdr-comment-prompt-format, AC-mdr-comment-rendered-element, AC-mdr-diff-fallback, AC-mdr-html-sanitized, AC-mdr-keyboard-comment, AC-mdr-large-file-renders, AC-mdr-raw-unchanged, AC-mdr-render-basic, AC-mdr-render-code-blocks, AC-mdr-render-gfm, AC-mdr-rendered-diff-additions, AC-mdr-rendered-diff-comment, AC-mdr-rendered-diff-modifications, AC-mdr-rendered-diff-prompt, AC-mdr-rendered-diff-removals, AC-mdr-switch-clears-comments, AC-mdr-switch-no-comments, AC-mdr-toggle-appears, AC-mdr-toggle-hidden-non-md, FR-mdr-detect-markdown, FR-mdr-element-id, FR-mdr-raw-diff-unchanged, FR-mdr-render-commonmark, FR-mdr-render-styling, FR-mdr-render-toggle, FR-mdr-rendered-comment-create, FR-mdr-rendered-comment-prompt, FR-mdr-rendered-diff-comment, FR-mdr-rendered-diff-display, FR-mdr-rendered-diff-prompt, FR-mdr-switch-comments, NFR-mdr-accessibility, NFR-mdr-client-only, NFR-mdr-render-perf, NFR-mdr-render-scroll-perf, NFR-mdr-rendered-diff-perf, NFR-mdr-xss-safety]
---
# Markdown Rendered View — macOS Test Plan

> Based on requirements in `../../product/markdown-render.md`
> Based on design in `../../design/macos/markdown-render.md`
> Based on technical spec in `../../engineering/macos/markdown-render.md`

## What We're Testing

The markdown rendered view feature for the macOS CRPG: detecting markdown files, toggling between raw and rendered views, rendering CommonMark + GFM content, element-level comment anchoring, rendered diff display with visual change annotations, prompt generation from rendered comments, view-switching confirmation dialogs, XSS safety, and performance budgets. Risk areas include AST-level diff computation complexity, word-level diff accuracy, comment mapping between element IDs and raw source lines, and rendering performance for large files.

## Test Strategy

Tests are organized into five layers matching the project's test strategy:

| Layer | Framework | Scope |
|---|---|---|
| **Unit** | Swift Testing + TCA `TestStore` | MarkdownParser, GFMVisitor, MarkdownDiffer, ElementIdentifier, MarkdownSanitizer, PromptBuilder |
| **Snapshot** | Point-Free SnapshotTesting | Rendered view appearance (file + diff modes), diff annotations, comment bubbles, fallback banner |
| **Integration** | Swift Testing + TCA `TestStore` | Multi-step flows: toggle -> render -> comment -> prompt, diff computation -> render -> comment |
| **UI** | XCUITest | End-to-end flows: load markdown -> toggle to rendered -> add comment -> verify prompt |
| **Manual** | Human verification | Rendering fidelity vs GitHub/other renderers, scroll performance on large files, VoiceOver navigation |

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-mdr-toggle-appears` | `TC-mdr-toggle-appears-markdown` | Not started |
| `AC-mdr-toggle-hidden-non-md` | `TC-mdr-toggle-hidden-typescript` | Not started |
| `AC-mdr-render-basic` | `TC-mdr-render-basic-commonmark` | Not started |
| `AC-mdr-render-gfm` | `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough` | Not started |
| `AC-mdr-render-code-blocks` | `TC-mdr-render-code-blocks-syntax` | Not started |
| `AC-mdr-raw-unchanged` | `TC-mdr-raw-unchanged-syntax-highlight` | Not started |
| `AC-mdr-comment-rendered-element` | `TC-mdr-comment-paragraph-hover`, `TC-mdr-comment-paragraph-submit` | Not started |
| `AC-mdr-comment-heading` | `TC-mdr-comment-heading-anchors-line` | Not started |
| `AC-mdr-comment-prompt-format` | `TC-mdr-comment-prompt-raw-source` | Not started |
| `AC-mdr-switch-clears-comments` | `TC-mdr-switch-raw-to-rendered-confirm`, `TC-mdr-switch-rendered-to-raw-confirm` | Not started |
| `AC-mdr-switch-no-comments` | `TC-mdr-switch-no-comments-immediate` | Not started |
| `AC-mdr-rendered-diff-additions` | `TC-mdr-diff-added-paragraph-green` | Not started |
| `AC-mdr-rendered-diff-removals` | `TC-mdr-diff-removed-paragraph-strikethrough` | Not started |
| `AC-mdr-rendered-diff-modifications` | `TC-mdr-diff-modified-word-level` | Not started |
| `AC-mdr-rendered-diff-comment` | `TC-mdr-diff-comment-modified-element` | Not started |
| `AC-mdr-rendered-diff-prompt` | `TC-mdr-diff-prompt-old-new-source` | Not started |
| `AC-mdr-html-sanitized` | `TC-mdr-xss-script-stripped`, `TC-mdr-xss-onerror-stripped` | Not started |
| `AC-mdr-large-file-renders` | `TC-mdr-perf-5k-lines-render`, `TC-mdr-perf-scroll-smooth` | Not started |
| `AC-mdr-keyboard-comment` | `TC-mdr-keyboard-tab-focus`, `TC-mdr-keyboard-enter-comment` | Not started |
| `AC-mdr-diff-fallback` | `TC-mdr-diff-fallback-80-percent-changed` | Not started |

---

## Test Cases

### Toggle Visibility and Mode Switching

These tests verify that the rendered/raw toggle appears only for markdown files and that mode switching works correctly.

#### Toggle appears for markdown file `TC-mdr-toggle-appears-markdown`
- **Type**: UI
- **Covers**: `AC-mdr-toggle-appears`, `FR-mdr-detect-markdown`, `FR-mdr-render-toggle`
- **Preconditions**: Application is running
- **Steps**:
  1. Load a markdown file (`README.md` with `.md` extension)
  2. Observe the toolbar
- **Expected Result**: A `Raw | Rendered` segmented control is visible in the toolbar, adjacent to the `File | Diff` toggle. The `Raw` segment is selected by default.

#### Toggle is hidden for non-markdown file `TC-mdr-toggle-hidden-typescript`
- **Type**: UI
- **Covers**: `AC-mdr-toggle-hidden-non-md`, `FR-mdr-detect-markdown`
- **Preconditions**: Application is running
- **Steps**:
  1. Load a TypeScript file (`utils.ts`)
  2. Observe the toolbar
- **Expected Result**: No `Raw | Rendered` toggle is visible. The toolbar shows only the `File | Diff` toggle and other standard controls.

#### Switch from raw to rendered with no comments `TC-mdr-switch-no-comments-immediate`
- **Type**: Integration
- **Covers**: `AC-mdr-switch-no-comments`, `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded, raw view active, no comments exist
- **Steps**:
  1. Click the `Rendered` segment in the toolbar
- **Expected Result**: View switches immediately to rendered view with no confirmation dialog. Markdown content displays as formatted HTML.

#### Switch from rendered to raw with comments shows confirmation `TC-mdr-switch-rendered-to-raw-confirm`
- **Type**: Integration
- **Covers**: `AC-mdr-switch-clears-comments`, `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded in rendered view, at least one comment exists on a rendered element
- **Steps**:
  1. Click the `Raw` segment in the toolbar
  2. Observe the confirmation dialog
  3. Click `Cancel`
  4. Click `Raw` again
  5. Click `Clear and Switch`
- **Expected Result**: 
   - Step 2: Dialog appears with message "Switching to Raw view will clear your current comments. This cannot be undone."
   - Step 3: Dialog dismisses, stays in rendered view, comments still present
   - Step 5: Comments are cleared, view switches to raw syntax-highlighted source

---

### Basic Rendering (CommonMark + GFM)

These tests verify that markdown renders correctly with all required formatting.

#### Render basic CommonMark elements `TC-mdr-render-basic-commonmark`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-render-basic`, `FR-mdr-render-commonmark`, `FR-mdr-render-styling`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/basic.md` containing headings (H1-H6), paragraphs, **bold**, *italic*, [links](http://example.com), bullet lists, numbered lists, inline `code`, blockquotes, horizontal rules
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Capture snapshot (light mode)
- **Expected Result**:
   - Headings render with progressively larger font sizes, bold weight
   - Bold and italic text styled correctly
   - Links are underlined/colored, clickable
   - Lists rendered with bullets/numbers, proper indentation
   - Inline code monospaced with subtle background
   - Blockquotes visually distinct (border, indentation)
   - Horizontal rule displays as visual separator
   - Snapshot matches approved baseline

#### Render GFM tables `TC-mdr-render-gfm-tables`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-render-gfm`, `FR-mdr-render-commonmark`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/gfm-table.md` containing a pipe table with left/center/right alignment
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
- **Expected Result**: Table renders with bordered cells, column headers, alignment applied (left-aligned, centered, right-aligned columns visible)

#### Render GFM task lists `TC-mdr-render-gfm-task-lists`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-render-gfm`, `FR-mdr-render-commonmark`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/task-list.md` containing `- [ ] Unchecked` and `- [x] Checked` items
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Attempt to click checkbox
- **Expected Result**: Task list renders with checkboxes. Checked items show checked state. Clicking checkboxes does nothing (read-only per `FR-mdr-render-commonmark`).

#### Render GFM strikethrough `TC-mdr-render-gfm-strikethrough`
- **Type**: Integration
- **Covers**: `AC-mdr-render-gfm`, `FR-mdr-render-commonmark`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/strikethrough.md` containing `~~strikethrough text~~`
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
- **Expected Result**: Text displays with line-through decoration

#### Render fenced code blocks with syntax highlighting `TC-mdr-render-code-blocks-syntax`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-render-code-blocks`, `FR-mdr-render-commonmark`, `FR-mdr-render-styling`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/code-blocks.md` containing:
  ````markdown
  ```typescript
  const x: number = 42;
  function foo() { return x; }
  ```
  ````
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
- **Expected Result**: Code block renders with syntax highlighting identical to the raw code viewer theme (keywords colored, strings colored, etc.)

---

### Comment Interaction in Rendered View

These tests verify element-level comment anchoring and prompt generation.

#### Comment on paragraph with hover affordance `TC-mdr-comment-paragraph-hover`
- **Type**: UI
- **Covers**: `AC-mdr-comment-rendered-element`, `FR-mdr-rendered-comment-create`
- **Preconditions**: Markdown file loaded in rendered view showing at least one paragraph
- **Steps**:
  1. Hover mouse over a paragraph
  2. Observe visual feedback
  3. Click the `+` icon in the left margin (or Cmd+click the paragraph)
  4. Type "Fix typo in this paragraph"
  5. Click Submit
- **Expected Result**:
   - Step 2: Paragraph receives light background tint, `+` icon appears in left margin
   - Step 3: Inline comment editor opens below the paragraph
   - Step 5: Comment bubble appears below the paragraph, prompt preview updates

#### Comment on heading anchors to correct line `TC-mdr-comment-heading-anchors-line`
- **Type**: Integration
- **Covers**: `AC-mdr-comment-heading`, `FR-mdr-element-id`, `FR-mdr-rendered-comment-prompt`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/heading.md` where `## API Reference` is on line 15
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Add comment on the `## API Reference` heading: "This should be level 3"
  4. View prompt preview
- **Expected Result**: Prompt preview shows:
  ```
  **Heading (lines 15-15)**:
  ```markdown
  ## API Reference
  ```
  Comment: "This should be level 3"
  ```

#### Prompt from rendered view includes raw markdown source `TC-mdr-comment-prompt-raw-source`
- **Type**: Integration
- **Covers**: `AC-mdr-comment-prompt-format`, `FR-mdr-rendered-comment-prompt`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/paragraph-span.md` where a paragraph spans lines 20-23
- **Steps**:
  1. Load fixture file in rendered view
  2. Add comment on the paragraph: "Clarify this"
  3. View prompt preview
- **Expected Result**: Prompt shows:
  ```
  **Paragraph (lines 20-23)**:
  ```markdown
  The application provides a REST API for managing
  user accounts. The API is authenticated via bearer
  tokens and returns JSON responses.
  ```
  Comment: "Clarify this"
  ```
  (Raw markdown source is shown, not HTML)

---

### Rendered Diff View

These tests verify AST-level diff computation and visual annotations.

#### Added paragraph shows green highlight `TC-mdr-diff-added-paragraph-green`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-rendered-diff-additions`, `FR-mdr-rendered-diff-display`
- **Preconditions**: None
- **Fixtures**: 
  - Baseline: `fixtures/diff/baseline.md` (missing a paragraph at line 10)
  - Working: `fixtures/diff/working-added.md` (has new paragraph at line 10)
- **Steps**:
  1. Load working file in diff mode
  2. Switch to rendered view
  3. Observe the added paragraph
- **Expected Result**: New paragraph renders with light green background, 4pt green left border, `[+ Added]` badge. Snapshot matches approved baseline.

#### Removed paragraph shows strikethrough `TC-mdr-diff-removed-paragraph-strikethrough`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-rendered-diff-removals`, `FR-mdr-rendered-diff-display`
- **Preconditions**: None
- **Fixtures**:
  - Baseline: `fixtures/diff/baseline.md` (has a paragraph at line 15)
  - Working: `fixtures/diff/working-removed.md` (paragraph at line 15 removed)
- **Steps**:
  1. Load working file in diff mode
  2. Switch to rendered view
  3. Observe the removed paragraph
- **Expected Result**: Paragraph renders with strikethrough text, light red background, 4pt red left border, `[- Removed]` badge.

#### Modified paragraph shows word-level changes `TC-mdr-diff-modified-word-level`
- **Type**: Integration + Snapshot
- **Covers**: `AC-mdr-rendered-diff-modifications`, `FR-mdr-rendered-diff-display`
- **Preconditions**: None
- **Fixtures**:
  - Baseline: `fixtures/diff/baseline.md` — paragraph reads "The API returns JSON data"
  - Working: `fixtures/diff/working-modified.md` — paragraph reads "The API returns XML data"
- **Steps**:
  1. Load working file in diff mode
  2. Switch to rendered view
  3. Observe the modified paragraph
- **Expected Result**: Paragraph displays "The API returns ~~JSON~~ XML data" where "JSON" has strikethrough + red background and "XML" has green background.

#### Comment on modified element in diff view `TC-mdr-diff-comment-modified-element`
- **Type**: Integration
- **Covers**: `AC-mdr-rendered-diff-comment`, `FR-mdr-rendered-diff-comment`
- **Preconditions**: Markdown file in rendered diff mode showing a modified paragraph
- **Steps**:
  1. Hover over the modified paragraph
  2. Click `+` icon
  3. Add comment: "Why change from JSON to XML?"
  4. Submit
- **Expected Result**: Comment anchors to the modified element (element ID includes `modified:` qualifier), comment bubble appears below the paragraph.

#### Prompt from rendered diff includes old and new source `TC-mdr-diff-prompt-old-new-source`
- **Type**: Integration
- **Covers**: `AC-mdr-rendered-diff-prompt`, `FR-mdr-rendered-diff-prompt`
- **Preconditions**: Modified paragraph in rendered diff view with comment
- **Steps**:
  1. (From previous test) View prompt preview
- **Expected Result**: Prompt shows:
  ```
  **Paragraph (modified, lines 20-20 → 20-20)**:

  Old:
  ```markdown
  The API returns JSON data.
  ```

  New:
  ```markdown
  The API returns XML data.
  ```
  Comment: "Why change from JSON to XML?"
  ```

#### Fallback banner for heavily restructured file `TC-mdr-diff-fallback-80-percent-changed`
- **Type**: Integration
- **Covers**: `AC-mdr-diff-fallback`, `FR-mdr-rendered-diff-display`
- **Preconditions**: None
- **Fixtures**:
  - Baseline: `fixtures/diff/baseline-long.md` (50 paragraphs)
  - Working: `fixtures/diff/working-restructured.md` (45+ paragraphs rewritten/reordered)
- **Steps**:
  1. Load working file in diff mode
  2. Switch to rendered view
  3. Observe banner
  4. Click "Switch to Raw Diff" button
- **Expected Result**:
   - Step 3: Banner appears: "Too many structural changes for rendered diff. [Switch to Raw Diff]"
   - Step 4: View switches to raw diff mode (unified diff of markdown source)

---

### Security (XSS Safety)

These tests verify that embedded HTML is sanitized.

#### Script tags are stripped from rendered output `TC-mdr-xss-script-stripped`
- **Type**: Integration
- **Covers**: `AC-mdr-html-sanitized`, `NFR-mdr-xss-safety`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/xss-script.md` containing:
  ```markdown
  # Normal Content

  <script>alert('xss')</script>

  More content.
  ```
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Observe rendered output
  4. Check browser console for script execution
- **Expected Result**: 
   - Heading and paragraph render normally
   - `<script>` tag does not appear in rendered output
   - No alert fires (script was stripped, not executed)

#### Event handlers are stripped `TC-mdr-xss-onerror-stripped`
- **Type**: Integration
- **Covers**: `AC-mdr-html-sanitized`, `NFR-mdr-xss-safety`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/xss-onerror.md` containing:
  ```markdown
  <img src="invalid.png" onerror="alert('xss')">
  ```
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Observe rendered output
- **Expected Result**: 
   - Image renders (or shows alt text if src invalid)
   - `onerror` attribute is stripped
   - No alert fires

---

### Performance

These tests verify rendering and diff computation performance.

#### 5,000-line file renders within 200ms `TC-mdr-perf-5k-lines-render`
- **Type**: Integration
- **Covers**: `AC-mdr-large-file-renders`, `NFR-mdr-render-perf`
- **Preconditions**: None
- **Fixture**: `fixtures/markdown/large-5k.md` (5,000 lines of markdown)
- **Steps**:
  1. Load fixture file
  2. Switch to rendered view
  3. Measure time from toggle click to render complete
- **Expected Result**: Rendering completes within 200ms. Scroll is smooth (no jank).

#### Scroll performance on large rendered file `TC-mdr-perf-scroll-smooth`
- **Type**: Manual
- **Covers**: `AC-mdr-large-file-renders`, `NFR-mdr-render-scroll-perf`
- **Preconditions**: 5,000-line file loaded in rendered view
- **Steps**:
  1. Scroll rapidly through the rendered content using mouse wheel, trackpad gestures, and scroll bar
  2. Observe frame rate and responsiveness
- **Expected Result**: Scrolling is smooth with no visible jank or lag. Frame rate stays above 30fps.

#### Diff computation for 5k-line file within 1 second `TC-mdr-perf-diff-5k`
- **Type**: Integration
- **Covers**: `NFR-mdr-rendered-diff-perf`
- **Preconditions**: None
- **Fixtures**: 
  - Baseline: `fixtures/diff/baseline-5k.md` (5,000 lines)
  - Working: `fixtures/diff/working-5k-modified.md` (500 lines modified)
- **Steps**:
  1. Load working file in diff mode
  2. Switch to rendered view
  3. Measure time from toggle click to diff render complete
- **Expected Result**: Diff computation + rendering completes within 1 second.

---

### Accessibility

These tests verify keyboard navigation and screen reader support.

#### Tab navigation focuses rendered elements `TC-mdr-keyboard-tab-focus`
- **Type**: UI
- **Covers**: `AC-mdr-keyboard-comment`, `NFR-mdr-accessibility`
- **Preconditions**: Markdown file loaded in rendered view
- **Steps**:
  1. Press Tab repeatedly
  2. Observe focus indicator
- **Expected Result**: Each commentable element (paragraphs, headings, lists, code blocks) receives focus in sequence. Focus ring is visible.

#### Enter key opens comment editor on focused element `TC-mdr-keyboard-enter-comment`
- **Type**: UI
- **Covers**: `AC-mdr-keyboard-comment`, `NFR-mdr-accessibility`
- **Preconditions**: Markdown file loaded in rendered view
- **Steps**:
  1. Tab to a paragraph (receives focus)
  2. Press Enter (or Cmd+/)
  3. Type comment text
  4. Press Tab to Submit button
  5. Press Space to submit
- **Expected Result**: 
   - Step 2: Inline comment editor opens below the paragraph
   - Step 5: Comment is submitted, bubble appears

#### VoiceOver announces diff annotations `TC-mdr-voiceover-diff-annotations`
- **Type**: Manual
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: Rendered diff view active with added/removed/modified elements, VoiceOver enabled
- **Steps**:
  1. Use VoiceOver to navigate through rendered diff
  2. Listen to announcements for added, removed, modified elements
- **Expected Result**:
   - Added element announced as "Paragraph, added: [content]"
   - Removed element announced as "Paragraph, removed: [content]"
   - Modified element announced with indication of modification

---

### Raw View Unchanged

These tests verify that raw view behavior is not affected.

#### Raw view still shows syntax-highlighted markdown `TC-mdr-raw-unchanged-syntax-highlight`
- **Type**: Integration
- **Covers**: `AC-mdr-raw-unchanged`, `FR-mdr-raw-diff-unchanged`
- **Preconditions**: Markdown file loaded, toggle on `Raw`
- **Steps**:
  1. Observe code viewer content
- **Expected Result**: Syntax-highlighted markdown source with line numbers and gutter, identical to pre-feature behavior.

---

## Edge Cases & Error Scenarios

### Rendering Errors

- **Empty markdown file**: Renders as blank content area, no errors
- **Malformed markdown**: Renders whatever can be parsed, degrades gracefully
- **Broken image links**: Shows alt text, no render failure
- **Extremely nested lists (> 10 levels)**: Renders up to supported depth (4 levels per `FR-mdr-render-commonmark`), flattens or caps deeper nesting

### Diff Edge Cases

- **Entire file rewritten**: Falls back to banner (> 80% changed)
- **Only whitespace changes**: Shown as unchanged (no diff annotations)
- **Reordered paragraphs**: Shown as removed (old position) + added (new position)

### Comment Edge Cases

- **Multiple comments on same element**: Stack vertically below element
- **Comment on removed element in diff view**: Anchors to `removed:` element ID, prompt shows old source
- **Switch mode with unsaved comment in editor**: Confirmation dialog still appears (comments includes in-progress editors)

## Regression Considerations

- **Existing raw view**: Verify line-based commenting still works for markdown files in raw mode
- **Existing diff view**: Verify raw diff view for markdown files shows unified diff correctly
- **File/Diff toggle**: Verify rendered/raw toggle does not interfere with File/Diff toggle state
- **Multi-file sessions**: Verify rendered/raw mode is per-file (switching files preserves each file's mode)
- **Syntax highlighting**: Verify TreeSitter highlighting still works in code blocks within rendered view
