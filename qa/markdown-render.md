# Markdown Rendered View -- Test Plan

> Based on requirements in `../product/markdown-render.md`
> Based on design in `../design/markdown-render.md`
> Based on technical spec in `../engineering/markdown-render.md`

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-mdr-detect-markdown` | `TC-mdr-detect-md-ext`, `TC-mdr-detect-mdx-ext`, `TC-mdr-detect-markdown-ext`, `TC-mdr-detect-mdown-ext`, `TC-mdr-detect-mkdn-ext`, `TC-mdr-detect-mkd-ext`, `TC-mdr-detect-uppercase-ext`, `TC-mdr-detect-non-md-hidden`, `TC-mdr-detect-no-extension`, `TC-mdr-detect-md-in-directory`, `TC-mdr-edge-paste-md-filename` | Not started |
| `FR-mdr-render-toggle` | `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-click-raw`, `TC-mdr-toggle-keyboard`, `TC-mdr-toggle-default-raw`, `TC-mdr-toggle-persists-session`, `TC-mdr-toggle-resets-new-file`, `TC-mdr-toggle-independent-file-diff` | Not started |
| `FR-mdr-render-commonmark` | `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists`, `TC-mdr-render-ordered-lists`, `TC-mdr-render-nested-lists`, `TC-mdr-render-blockquotes`, `TC-mdr-render-horizontal-rules`, `TC-mdr-render-images`, `TC-mdr-render-images-broken`, `TC-mdr-render-inline-code`, `TC-mdr-render-html-blocks-safe`, `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`, `TC-mdr-render-gfm-autolinks`, `TC-mdr-render-code-blocks-highlighted`, `TC-mdr-render-code-blocks-no-lang` | Not started |
| `FR-mdr-render-styling` | `TC-mdr-style-body-typography`, `TC-mdr-style-heading-hierarchy`, `TC-mdr-style-code-block-theme`, `TC-mdr-style-table-styling`, `TC-mdr-style-max-width`, `TC-mdr-style-blockquote`, `TC-mdr-style-links` | Not started |
| `FR-mdr-element-id` | `TC-mdr-element-id-deterministic`, `TC-mdr-element-id-positional`, `TC-mdr-element-id-all-block-types` | Not started |
| `FR-mdr-rendered-comment-create` | `TC-mdr-comment-paragraph`, `TC-mdr-comment-heading`, `TC-mdr-comment-list-item`, `TC-mdr-comment-code-block`, `TC-mdr-comment-table`, `TC-mdr-comment-blockquote`, `TC-mdr-comment-multiple-same-element`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-cmd-click`, `TC-mdr-comment-bubble-label`, `TC-mdr-comment-count-increments` | Not started |
| `FR-mdr-rendered-comment-prompt` | `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-element-type`, `TC-mdr-prompt-format-structure`, `TC-mdr-prompt-multiple-comments-order`, `TC-mdr-prompt-no-preamble`, `TC-mdr-prompt-with-preamble` | Not started |
| `FR-mdr-switch-comments` | `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel`, `TC-mdr-switch-no-comments-immediate`, `TC-mdr-switch-preamble-preserved`, `TC-mdr-switch-raw-to-rendered`, `TC-mdr-switch-rendered-to-raw`, `TC-mdr-switch-rendered-file-to-rendered-diff`, `TC-mdr-switch-rendered-diff-to-rendered-file` | Not started |
| `FR-mdr-raw-diff-unchanged` | `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical` | Not started |
| `FR-mdr-rendered-diff-display` | `TC-mdr-rdiff-added-block`, `TC-mdr-rdiff-removed-block`, `TC-mdr-rdiff-modified-block-word-diff`, `TC-mdr-rdiff-unchanged-block`, `TC-mdr-rdiff-no-changes`, `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-fallback-dismiss`, `TC-mdr-rdiff-loading-spinner`, `TC-mdr-rdiff-timeout-fallback` | Not started |
| `FR-mdr-rendered-diff-comment` | `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-removed`, `TC-mdr-rdiff-comment-modified`, `TC-mdr-rdiff-comment-unchanged`, `TC-mdr-rdiff-comment-anchor-qualifier` | Not started |
| `FR-mdr-rendered-diff-prompt` | `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only`, `TC-mdr-rdiff-prompt-heading-format`, `TC-mdr-rdiff-prompt-document-order` | Not started |
| `NFR-mdr-render-perf` | `TC-mdr-perf-render-5k`, `TC-mdr-perf-render-10k`, `TC-mdr-perf-render-ui-block` | Not started |
| `NFR-mdr-render-scroll-perf` | `TC-mdr-perf-scroll-smooth`, `TC-mdr-perf-scroll-content-visibility` | Not started |
| `NFR-mdr-rendered-diff-perf` | `TC-mdr-perf-rdiff-5k`, `TC-mdr-perf-rdiff-10k`, `TC-mdr-perf-rdiff-timeout` | Not started |
| `NFR-mdr-xss-safety` | `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`, `TC-mdr-xss-data-url`, `TC-mdr-xss-safe-html-preserved` | Not started |
| `NFR-mdr-client-only` | `TC-mdr-client-only-no-requests` | Not started |
| `NFR-mdr-accessibility` | `TC-mdr-a11y-keyboard-nav`, `TC-mdr-a11y-keyboard-comment`, `TC-mdr-a11y-screen-reader-elements`, `TC-mdr-a11y-screen-reader-diff`, `TC-mdr-a11y-focus-on-mode-switch`, `TC-mdr-a11y-aria-toggle`, `TC-mdr-a11y-aria-rendered-content`, `TC-mdr-a11y-aria-diff-annotations` | Not started |
| `AC-mdr-toggle-appears` | `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-default-raw`, `TC-mdr-detect-md-ext` | Not started |
| `AC-mdr-toggle-hidden-non-md` | `TC-mdr-detect-non-md-hidden` | Not started |
| `AC-mdr-render-basic` | `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists` | Not started |
| `AC-mdr-render-gfm` | `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough` | Not started |
| `AC-mdr-render-code-blocks` | `TC-mdr-render-code-blocks-highlighted` | Not started |
| `AC-mdr-raw-unchanged` | `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical` | Not started |
| `AC-mdr-comment-rendered-element` | `TC-mdr-comment-paragraph`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-bubble-label` | Not started |
| `AC-mdr-comment-heading` | `TC-mdr-comment-heading`, `TC-mdr-prompt-raw-source-lines` | Not started |
| `AC-mdr-comment-prompt-format` | `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-format-structure` | Not started |
| `AC-mdr-switch-clears-comments` | `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel` | Not started |
| `AC-mdr-switch-no-comments` | `TC-mdr-switch-no-comments-immediate` | Not started |
| `AC-mdr-rendered-diff-additions` | `TC-mdr-rdiff-added-block` | Not started |
| `AC-mdr-rendered-diff-removals` | `TC-mdr-rdiff-removed-block` | Not started |
| `AC-mdr-rendered-diff-modifications` | `TC-mdr-rdiff-modified-block-word-diff` | Not started |
| `AC-mdr-rendered-diff-comment` | `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-modified` | Not started |
| `AC-mdr-rendered-diff-prompt` | `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only` | Not started |
| `AC-mdr-html-sanitized` | `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script` | Not started |
| `AC-mdr-large-file-renders` | `TC-mdr-perf-render-5k`, `TC-mdr-perf-scroll-smooth` | Not started |
| `AC-mdr-keyboard-comment` | `TC-mdr-a11y-keyboard-comment` | Not started |
| `AC-mdr-diff-fallback` | `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-timeout-fallback` | Not started |

---

## Test Cases

---

### Markdown Detection

---

#### `TC-mdr-detect-md-ext`: `.md` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`, `AC-mdr-toggle-appears`
- **Preconditions**: Application is running. A file named `README.md` with valid markdown content is available.
- **Steps**:
  1. Load `README.md` via the `/shepherd` slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle (Raw | Rendered) is visible in the toolbar, positioned after the File/Diff toggle. The "Raw" segment is active by default.
- **Edge Cases**:
  - File named `.md` (no basename, just the extension): toggle should still appear.

---

#### `TC-mdr-detect-mdx-ext`: `.mdx` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `page.mdx` is available.
- **Steps**:
  1. Load `page.mdx` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible. "Raw" is active by default.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-markdown-ext`: `.markdown` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `docs.markdown` is available.
- **Steps**:
  1. Load `docs.markdown` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-mdown-ext`: `.mdown` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `notes.mdown` is available.
- **Steps**:
  1. Load `notes.mdown` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-mkdn-ext`: `.mkdn` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `spec.mkdn` is available.
- **Steps**:
  1. Load `spec.mkdn` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-mkd-ext`: `.mkd` file triggers render toggle visibility

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `readme.mkd` is available.
- **Steps**:
  1. Load `readme.mkd` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-uppercase-ext`: File with uppercase `.MD` extension triggers toggle

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `CHANGELOG.MD` is available.
- **Steps**:
  1. Load `CHANGELOG.MD` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: The render mode toggle is visible. Extension detection is case-insensitive.
- **Edge Cases**:
  - Mixed case: `README.Md`, `notes.mD` -- all should trigger the toggle.

---

#### `TC-mdr-detect-non-md-hidden`: Non-markdown file hides render toggle

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`, `AC-mdr-toggle-hidden-non-md`
- **Preconditions**: A file named `utils.ts` is available.
- **Steps**:
  1. Load `utils.ts` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: No render mode toggle is visible in the toolbar. The toolbar looks identical to the pre-feature state for non-markdown files. The toggle is not rendered in the DOM (hidden, not disabled).
- **Edge Cases**:
  - File with `.txt` extension: no toggle.
  - File with `.json` extension: no toggle.
  - File with `.yml` extension: no toggle.
  - File loaded via paste with no filename: no toggle.
  - File loaded via paste with filename "notes.md": toggle appears (detection is based on filename, not load method).

---

#### `TC-mdr-detect-no-extension`: File with no extension hides render toggle

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A file named `Makefile` (no extension) is available.
- **Steps**:
  1. Load `Makefile` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: No render mode toggle is visible. Files without recognized markdown extensions are treated as non-markdown.
- **Edge Cases**: None.

---

#### `TC-mdr-detect-md-in-directory`: File in a directory with `.md` in the name does not falsely trigger toggle

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: A TypeScript file at path `docs.md/utils.ts` is available.
- **Steps**:
  1. Load `docs.md/utils.ts` via the slash command.
  2. Observe the toolbar.
- **Expected Result**: No render mode toggle is visible. The `.md` in the directory name does not cause false detection -- only the file's own extension is checked.
- **Edge Cases**: None.

---

### Toggle Behavior

---

#### `TC-mdr-toggle-click-rendered`: Click to switch to rendered view

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`, `AC-mdr-toggle-appears`
- **Preconditions**: A markdown file is loaded. The render toggle shows "Raw" active.
- **Steps**:
  1. Click the "Rendered" segment of the render toggle.
  2. Observe the toggle state and the code viewer panel.
- **Expected Result**: The "Rendered" segment becomes active (blue background `#2563EB`, white text). The "Raw" segment becomes inactive (white background, slate text). The code viewer panel transitions from raw syntax-highlighted markdown to formatted HTML output. The raw content fades out (100ms) and rendered content fades in (150ms).
- **Edge Cases**:
  - Clicking "Rendered" when it is already active: nothing happens.

---

#### `TC-mdr-toggle-click-raw`: Click to switch back to raw view

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`
- **Preconditions**: A markdown file is loaded in rendered view. No comments exist.
- **Steps**:
  1. Click the "Raw" segment of the render toggle.
  2. Observe the toggle state and the code viewer panel.
- **Expected Result**: The "Raw" segment becomes active. The code viewer returns to the raw syntax-highlighted markdown source with line numbers. The rendered content fades out (100ms) and raw content fades in (150ms).
- **Edge Cases**: None.

---

#### `TC-mdr-toggle-keyboard`: Switch render mode via keyboard

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`, `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded with "Raw" active.
- **Steps**:
  1. Press `Tab` until focus reaches the render mode toggle.
  2. Press `ArrowRight` to move focus to the "Rendered" segment.
  3. Press `Enter` to activate.
  4. Observe the view change.
  5. Press `ArrowLeft` to move focus to "Raw".
  6. Press `Space` to activate.
  7. Observe the view change.
- **Expected Result**: Both `Enter` and `Space` activate the focused segment. The toggle uses `role="tablist"` and `role="tab"` with `aria-selected` on each segment. Focus rings (2px `#2563EB`, offset 2px) are visible during keyboard interaction.
- **Edge Cases**:
  - `ArrowRight` when already on "Rendered": focus stays (no wrap).
  - `ArrowLeft` when already on "Raw": focus stays (no wrap).

---

#### `TC-mdr-toggle-default-raw`: Render toggle defaults to Raw for markdown files

- **Type**: Integration
- **Covers**: `FR-mdr-render-toggle`, `AC-mdr-toggle-appears`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Load a markdown file.
  2. Observe the toggle state.
- **Expected Result**: The "Raw" segment is active. The code viewer shows the raw markdown source, identical to the pre-feature behavior for markdown files. Rendered mode is opt-in, not a surprise default.
- **Edge Cases**: None.

---

#### `TC-mdr-toggle-persists-session`: Toggle state persists within session

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`
- **Preconditions**: A markdown file is loaded. The user has switched to "Rendered" mode.
- **Steps**:
  1. Switch to "Rendered" mode.
  2. Interact with the file (scroll, hover over elements).
  3. Observe that the toggle remains on "Rendered".
- **Expected Result**: The toggle state stays on "Rendered" throughout the session for the current file. It does not revert to "Raw" on scroll or other interactions.
- **Edge Cases**: None.

---

#### `TC-mdr-toggle-resets-new-file`: Toggle resets to Raw when a new file is loaded

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`
- **Preconditions**: A markdown file is loaded in "Rendered" mode.
- **Steps**:
  1. Load a different markdown file (e.g., via the slash command with a different path).
  2. Observe the toggle state.
- **Expected Result**: The toggle resets to "Raw". The new file displays in raw view by default.
- **Edge Cases**:
  - Loading a non-markdown file after being in rendered mode: the toggle disappears entirely (non-markdown files do not show the toggle).

---

#### `TC-mdr-toggle-independent-file-diff`: Render toggle is independent of File/Diff toggle

- **Type**: E2E
- **Covers**: `FR-mdr-render-toggle`
- **Preconditions**: A markdown file is loaded via the slash command (both toggles visible). "Raw" and "File" are active.
- **Steps**:
  1. Switch to "Rendered" mode. Observe: Rendered + File.
  2. Switch to "Diff" mode. Observe: Rendered + Diff.
  3. Switch to "Raw" mode. Observe: Raw + Diff.
  4. Switch to "File" mode. Observe: Raw + File.
- **Expected Result**: Each combination produces a distinct view state. The two toggles operate independently. Rendered + File shows the RenderedViewer. Rendered + Diff shows the RenderedDiffViewer. Raw + File shows the standard CodeViewer. Raw + Diff shows the standard DiffViewer.
- **Edge Cases**:
  - Rapid toggling between all 4 states: all transitions should be smooth with no rendering artifacts.

---

### Markdown Rendering

---

#### `TC-mdr-render-headings`: Headings H1-H6 render with correct hierarchy

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-basic`, `FR-mdr-render-styling`
- **Preconditions**: A markdown file containing all heading levels (H1 through H6) is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect each heading level.
- **Expected Result**: H1 renders at 24px, font-weight 700, with a 3px `#2563EB` left border. H2 renders at 20px, weight 600, 3px `#3B82F6` left border. H3 renders at 16px, weight 600, 3px `#60A5FA` left border. H4-H6 render at 14px, weight 600, 2px `#93C5FD` left border. Each heading level is visually distinct from the others.
- **Edge Cases**:
  - Heading with inline formatting (e.g., `## API **Reference**`): bold within heading renders correctly.
  - Heading with inline code (e.g., `` ## The `config` module ``): inline code renders with monospace font within the heading.

---

#### `TC-mdr-render-paragraphs-bold-italic`: Paragraphs with bold and italic render correctly

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-basic`
- **Preconditions**: A markdown file containing paragraphs with `**bold**`, `*italic*`, `***bold italic***`, and plain text is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the paragraph content.
- **Expected Result**: Body text is 14px system sans-serif. Bold text is font-weight 700. Italic text is font-style italic. Bold italic text is both. Line height is 22px. Text color is `#1E293B`.
- **Edge Cases**:
  - Nested emphasis (e.g., `**bold *and italic* inside**`): renders correctly with nested formatting.

---

#### `TC-mdr-render-links`: Links render as clickable elements

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-basic`
- **Preconditions**: A markdown file containing inline links (`[text](url)`) and reference-style links is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered links.
  3. Hover over a link.
- **Expected Result**: Links render in `#2563EB` (primary blue). They show an underline on hover. Cursor changes to pointer. Links have `target="_blank"` and `rel="noopener noreferrer"`.
- **Edge Cases**:
  - Link with no title: no tooltip on hover.
  - Link with a title: tooltip appears on hover.
  - Link wrapping to multiple lines: underline and color apply to the full link text.

---

#### `TC-mdr-render-unordered-lists`: Unordered lists render with correct bullets

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-basic`
- **Preconditions**: A markdown file containing unordered lists with nesting up to 4 levels.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the list bullets and indentation.
- **Expected Result**: Level 1 uses disc bullets, level 2 uses circle, level 3 uses square, level 4 uses disc again. Each level has 24px left padding. Items are 14px, line-height 22px.
- **Edge Cases**:
  - List with inline formatting in items.
  - Single-item list.

---

#### `TC-mdr-render-ordered-lists`: Ordered lists render with correct numbering

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with ordered lists, including nested ordered lists.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect numbering and nesting.
- **Expected Result**: Level 1 uses decimal numbering. Level 2 uses lower-alpha. Level 3 uses lower-roman. Level 4 returns to decimal. 24px padding per level.
- **Edge Cases**:
  - Ordered list starting at a number other than 1 (e.g., `3. Item`): numbering should reflect the specified start value per CommonMark.

---

#### `TC-mdr-render-nested-lists`: Deeply nested lists render correctly

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with mixed ordered/unordered lists nested 4 levels deep.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the nested structure.
- **Expected Result**: Each nesting level is properly indented. Bullet styles and numbering styles alternate correctly per the design spec. All items are readable and properly formatted.
- **Edge Cases**:
  - Lists nested beyond 4 levels: should render (even if bullet style repeats).

---

#### `TC-mdr-render-blockquotes`: Blockquotes render with styled border

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing blockquotes, including nested blockquotes and blockquotes containing code blocks.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect blockquote styling.
- **Expected Result**: Blockquotes have a 3px left border in `#CBD5E1`, 16px left padding, italic text in `#475569`, background `#F8FAFC`. Nested blockquotes are indented further with their own left border.
- **Edge Cases**:
  - Blockquote containing a code block: code block renders with its own styling inside the blockquote.
  - Blockquote containing a list: list renders properly inside the blockquote.

---

#### `TC-mdr-render-horizontal-rules`: Horizontal rules render as dividers

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing `---`, `***`, or `___` horizontal rule syntax.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the horizontal rules.
- **Expected Result**: Horizontal rules render as 1px solid `#E2E8F0` lines with 24px vertical margin above and below.
- **Edge Cases**: None.

---

#### `TC-mdr-render-images`: Images render with correct constraints

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing image references (`![alt](url)`) with at least one working URL.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered image.
- **Expected Result**: Images render as `<img>` tags with `max-width: 100%` and `border-radius: 4px`. The image does not overflow the content area.
- **Edge Cases**: None.

---

#### `TC-mdr-render-images-broken`: Broken images show alt text fallback

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing an image reference with a broken/nonexistent URL.
- **Steps**:
  1. Switch to rendered view.
  2. Observe the broken image placeholder.
- **Expected Result**: The broken image shows the alt text in italic muted text on a `#F8FAFC` background with a broken-image icon. No broken image icon from the browser is shown.
- **Edge Cases**:
  - Image with empty alt text: placeholder area still appears but with no text content.

---

#### `TC-mdr-render-inline-code`: Inline code spans render with distinct styling

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing inline code (e.g., `` `const x = 1` ``).
- **Steps**:
  1. Switch to rendered view.
  2. Inspect inline code styling.
- **Expected Result**: Inline code uses the monospace font stack at 13px. Background is `#F1F5F9`. Padding: 2px 6px. Border-radius: 3px. Text color: `#BE185D`.
- **Edge Cases**:
  - Inline code containing backticks (e.g., ``` `` `code` `` ```): renders correctly.

---

#### `TC-mdr-render-html-blocks-safe`: Safe embedded HTML renders correctly

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing safe HTML blocks like `<details>`, `<summary>`, `<sup>`, `<sub>`.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered HTML elements.
- **Expected Result**: `<details>` and `<summary>` render as a collapsible section. `<sup>` and `<sub>` render as superscript and subscript. The safe HTML is preserved through sanitization.
- **Edge Cases**: None.

---

#### `TC-mdr-render-gfm-tables`: GFM tables render with proper styling

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-gfm`
- **Preconditions**: A markdown file containing a pipe table with alignment (left, center, right) and multiple rows.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered table.
- **Expected Result**: Table has 1px `#E2E8F0` borders. Header row has `#F1F5F9` background and font-weight 600. Body rows alternate between `#FFFFFF` and `#F8FAFC`. Cell padding is 8px 12px. Column alignment is respected. Table font is 13px.
- **Edge Cases**:
  - Table with very wide content: horizontal scrolling within the table.
  - Table with a single column: renders as a table, not just a paragraph.
  - Table with inline formatting in cells (bold, links, code): formats correctly.

---

#### `TC-mdr-render-gfm-task-lists`: GFM task lists render with checkboxes

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-gfm`
- **Preconditions**: A markdown file containing a task list (`- [ ] unchecked`, `- [x] checked`).
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered task list.
  3. Attempt to click a checkbox.
- **Expected Result**: Checked items show a filled blue checkbox. Unchecked items show an empty bordered checkbox. Checkboxes are read-only -- clicking them does not change their state. The rendered view is read-only.
- **Edge Cases**: None.

---

#### `TC-mdr-render-gfm-strikethrough`: GFM strikethrough renders with line-through

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-gfm`
- **Preconditions**: A markdown file containing `~~strikethrough text~~`.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the strikethrough text.
- **Expected Result**: Strikethrough text has `text-decoration: line-through` and color `#94A3B8`.
- **Edge Cases**: None.

---

#### `TC-mdr-render-gfm-autolinks`: GFM autolinks render bare URLs as links

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing a bare URL (e.g., `https://example.com`) not wrapped in link syntax.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the bare URL.
- **Expected Result**: The bare URL renders as a clickable link with the same styling as explicit markdown links (color `#2563EB`, underline on hover).
- **Edge Cases**: None.

---

#### `TC-mdr-render-code-blocks-highlighted`: Fenced code blocks have syntax highlighting

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `AC-mdr-render-code-blocks`
- **Preconditions**: A markdown file containing a fenced TypeScript code block (` ```typescript ... ``` `).
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the rendered code block.
- **Expected Result**: The code block has background `#1E293B` and text `#E2E8F0`. Padding: 16px. Border-radius: 6px. Syntax highlighting is applied using the same Shiki theme as the raw code viewer: keywords, strings, comments are colored distinctly. The code block has `overflow-x: auto` for horizontal scrolling if lines are long.
- **Edge Cases**:
  - Code block with an unrecognized language identifier: renders as plain text with no syntax coloring but retains the code block styling.
  - Code block with no language identifier: renders as plain monospace text in the code block container.

---

#### `TC-mdr-render-code-blocks-no-lang`: Fenced code blocks without language render as plain text

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing a fenced code block with no language specifier (` ``` ... ``` `).
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the code block.
- **Expected Result**: The code block renders with the dark background and monospace font but without syntax highlighting. Text appears in `#E2E8F0`.
- **Edge Cases**: None.

---

### Rendered View Styling

---

#### `TC-mdr-style-body-typography`: Body text uses correct typography

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Inspect the computed styles of a paragraph element.
- **Expected Result**: Font family is system sans-serif. Font size is 14px. Font weight is 400. Line height is 22px. Color is `#1E293B`.
- **Edge Cases**: None.

---

#### `TC-mdr-style-heading-hierarchy`: Heading styles are visually distinct at each level

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file with H1-H6 headings is loaded in rendered view.
- **Steps**:
  1. Inspect each heading level's computed styles.
- **Expected Result**: Each heading level has a progressively smaller font size (H1: 24px, H2: 20px, H3: 16px, H4-H6: 14px). Left border colors progress from darker blue (H1: `#2563EB`) to lighter blue (H4-H6: `#93C5FD`). Font weights: H1 is 700; H2-H6 are 600.
- **Edge Cases**: None.

---

#### `TC-mdr-style-code-block-theme`: Code blocks in rendered view use same theme as raw view

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`, `AC-mdr-render-code-blocks`
- **Preconditions**: A markdown file with a TypeScript fenced code block is loaded. The same TypeScript content exists in a `.ts` file that can be loaded for comparison.
- **Steps**:
  1. Load the `.ts` file in raw view. Note the syntax highlighting colors for a `const` keyword.
  2. Load the markdown file in rendered view. Note the syntax highlighting colors for the same `const` keyword inside a fenced code block.
- **Expected Result**: The syntax highlighting colors are identical between the raw view and the fenced code block in the rendered view. Both use the same Shiki theme.
- **Edge Cases**: None.

---

#### `TC-mdr-style-table-styling`: Tables match design spec styling

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file with a multi-row table is loaded in rendered view.
- **Steps**:
  1. Inspect table computed styles.
- **Expected Result**: Border: 1px solid `#E2E8F0`. Header row: background `#F1F5F9`, font-weight 600. Body rows alternate `#FFFFFF` and `#F8FAFC`. Cell padding: 8px 12px. Font size: 13px.
- **Edge Cases**: None.

---

#### `TC-mdr-style-max-width`: Rendered content has max-width cap

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file is loaded in rendered view on a wide viewport (> 1280px).
- **Steps**:
  1. Inspect the content area width.
- **Expected Result**: The rendered content has a max-width of approximately 80ch (~640px at 13px). Content is centered with equal padding on both sides via `margin: 0 auto`.
- **Edge Cases**:
  - Viewport narrower than 80ch: content takes full available width minus the comment affordance column.

---

#### `TC-mdr-style-blockquote`: Blockquotes match design spec

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file with a blockquote is loaded in rendered view.
- **Steps**:
  1. Inspect blockquote computed styles.
- **Expected Result**: Left border: 3px solid `#CBD5E1`. Padding-left: 16px. Color: `#475569`. Font-style: italic. Background: `#F8FAFC`.
- **Edge Cases**: None.

---

#### `TC-mdr-style-links`: Links match design spec

- **Type**: Integration
- **Covers**: `FR-mdr-render-styling`
- **Preconditions**: A markdown file with links is loaded in rendered view.
- **Steps**:
  1. Inspect link computed styles.
  2. Hover over a link.
- **Expected Result**: Color: `#2563EB`. Underline appears on hover. Cursor: pointer.
- **Edge Cases**: None.

---

### Element Identifiers

---

#### `TC-mdr-element-id-deterministic`: Same markdown source produces same element identifiers

- **Type**: Unit
- **Covers**: `FR-mdr-element-id`
- **Preconditions**: The element identifier assignment function is available for direct testing.
- **Steps**:
  1. Parse a markdown string into an AST and assign element identifiers.
  2. Repeat the process with the identical markdown string.
  3. Compare the identifiers.
- **Expected Result**: Identifiers are byte-for-byte identical between the two runs. For example, `heading-0`, `paragraph-1`, `list-2-item-0` are produced in both runs.
- **Edge Cases**:
  - Markdown with duplicate content (two identical paragraphs): each gets a distinct positional identifier (e.g., `paragraph-1`, `paragraph-3`).

---

#### `TC-mdr-element-id-positional`: Identifiers are based on position, not content

- **Type**: Unit
- **Covers**: `FR-mdr-element-id`
- **Preconditions**: The element identifier assignment function is available.
- **Steps**:
  1. Parse markdown with two identical paragraphs at different positions.
  2. Inspect their identifiers.
- **Expected Result**: Each paragraph gets a unique identifier based on its AST position (e.g., `paragraph-0` and `paragraph-2`), not based on content hash. Position-based identifiers prevent collisions when content is duplicated.
- **Edge Cases**: None.

---

#### `TC-mdr-element-id-all-block-types`: All block-level element types receive identifiers

- **Type**: Unit
- **Covers**: `FR-mdr-element-id`
- **Preconditions**: The element identifier assignment function is available.
- **Steps**:
  1. Parse markdown containing a heading, paragraph, list item, code block, table, blockquote, and horizontal rule.
  2. Inspect identifiers for each element.
- **Expected Result**: Each block-level element has an identifier following the pattern: `heading-N`, `paragraph-N`, `list-N-item-M`, `code-block-N`, `table-N`, `blockquote-N`, `thematic-break-N`, `image-N`. No block-level element is left without an identifier.
- **Edge Cases**: None.

---

### Comments on Rendered Elements

---

#### `TC-mdr-comment-paragraph`: Add a comment on a rendered paragraph

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`, `AC-mdr-comment-rendered-element`
- **Preconditions**: A markdown file is loaded in rendered view showing at least one paragraph.
- **Steps**:
  1. Hover over a paragraph element. Observe the hover affordance.
  2. Click the comment icon in the C (comment affordance) column.
  3. Type "Rewrite this for clarity" in the InlineCommentEditor.
  4. Click "Comment" (or press `Cmd+Enter`).
- **Expected Result**: On hover, the paragraph background changes to `#F8FAFC` (150ms transition). A comment icon (speech bubble, 16px, `#94A3B8`) appears in the C column. After clicking the icon, the InlineCommentEditor opens below the paragraph. After submitting, a CommentBubble appears below the paragraph with the label "Paragraph: [first 60 chars of content]..." and the comment text. The C column shows a blue dot (8px, `#3B82F6`) for the element. The toolbar comment count increments to 1.
- **Edge Cases**:
  - Clicking "Cancel": no comment created, editor closes.
  - Pressing `Escape`: same as Cancel.
  - Submitting with empty text area: "Comment" button should be disabled.

---

#### `TC-mdr-comment-heading`: Add a comment on a rendered heading

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`, `AC-mdr-comment-heading`
- **Preconditions**: A markdown file containing `## API Reference` is loaded in rendered view.
- **Steps**:
  1. Hover over the "API Reference" heading.
  2. Click the comment icon.
  3. Type "This heading should be level 3, not level 2."
  4. Submit the comment.
  5. Observe the prompt preview.
- **Expected Result**: The CommentBubble appears below the heading with label "Heading: ## API Reference". The prompt preview includes the raw markdown line `## API Reference` (not rendered HTML) paired with the comment text.
- **Edge Cases**: None.

---

#### `TC-mdr-comment-list-item`: Add a comment on a rendered list item

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file with a list is loaded in rendered view.
- **Steps**:
  1. Hover over a specific list item.
  2. Click the comment icon.
  3. Type "This item is redundant" and submit.
- **Expected Result**: The CommentBubble appears below the list item with label "List item: [item text preview]". The comment is anchored to the specific list item element, not the entire list.
- **Edge Cases**:
  - Nested list item: the comment is anchored to the specific nested item.

---

#### `TC-mdr-comment-code-block`: Add a comment on a rendered code block

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file with a fenced code block is loaded in rendered view.
- **Steps**:
  1. Hover over the rendered code block.
  2. Click the comment icon.
  3. Type "Add a 'rememberMe' boolean field" and submit.
- **Expected Result**: The CommentBubble appears below the code block with label "Code block: [first line or language tag preview]". The prompt includes the full raw markdown source of the fenced code block (including the opening and closing ``` fences).
- **Edge Cases**: None.

---

#### `TC-mdr-comment-table`: Add a comment on a rendered table

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file with a table is loaded in rendered view.
- **Steps**:
  1. Hover over the table.
  2. Click the comment icon.
  3. Type "Add a column for status codes" and submit.
- **Expected Result**: The CommentBubble appears below the table with label "Table: [header row preview]". The prompt includes the full raw markdown source of the table.
- **Edge Cases**: None.

---

#### `TC-mdr-comment-blockquote`: Add a comment on a rendered blockquote

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file with a blockquote is loaded in rendered view.
- **Steps**:
  1. Hover over the blockquote.
  2. Click the comment icon.
  3. Type "Attribute this quote" and submit.
- **Expected Result**: The CommentBubble appears below the blockquote with label "Block quote: [text preview]".
- **Edge Cases**: None.

---

#### `TC-mdr-comment-multiple-same-element`: Multiple comments on the same element

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file is loaded in rendered view with one comment on a paragraph.
- **Steps**:
  1. Hover over the same paragraph that already has a comment.
  2. Click the comment icon (which appears overlapping the existing blue dot).
  3. Type a second comment and submit.
- **Expected Result**: Both comments are displayed as separate CommentBubbles below the paragraph, stacked vertically with 8px spacing. The blue dot in the C column remains a single dot. The comment count shows the total count of all comments.
- **Edge Cases**:
  - Deleting one of two comments on the same element: the remaining comment stays, the blue dot remains.

---

#### `TC-mdr-comment-hover-affordance`: Hover affordance appears and disappears correctly

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`, `AC-mdr-comment-rendered-element`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Hover over a paragraph. Note the hover affordance appearance timing.
  2. Move the mouse away from the paragraph. Note the disappearance timing.
  3. Hover over a heading. Observe the same behavior.
- **Expected Result**: On hover: element background changes to `#F8FAFC` (150ms transition). Comment icon appears in the C column at the element's vertical center. On icon hover: color changes from `#94A3B8` to `#2563EB`, tooltip "Add comment" appears after 300ms. On mouse leave: the highlight and icon fade out in 100ms.
- **Edge Cases**:
  - Rapidly moving between adjacent elements: the highlight transitions smoothly without flickering.

---

#### `TC-mdr-comment-cmd-click`: Cmd/Ctrl+click on element opens comment editor

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Hold `Cmd` (macOS) or `Ctrl` (Windows/Linux) and click on a paragraph element.
- **Expected Result**: The InlineCommentEditor opens below the paragraph, identical to clicking the comment icon.
- **Edge Cases**:
  - Cmd+click on a link within a paragraph: should open the comment editor, not navigate the link. (Note: this is a potential conflict -- flag if behavior is ambiguous.)

---

#### `TC-mdr-comment-bubble-label`: Comment bubble shows element type and content preview

- **Type**: Integration
- **Covers**: `FR-mdr-rendered-comment-create`, `AC-mdr-comment-rendered-element`
- **Preconditions**: Comments exist on a heading, paragraph, list item, and code block.
- **Steps**:
  1. Inspect each CommentBubble's label text.
- **Expected Result**: Labels follow the pattern "[Element type]: [content preview]". Content preview is max 60 characters with ellipsis truncation. Examples: "Heading: ## API Reference", "Paragraph: This module provides the core authen...", "List item: POST /login -- Authenticate a user", "Code block: ```typescript interface LoginRequ...".
- **Edge Cases**:
  - Element with very short content (< 60 chars): no ellipsis, full content shown.
  - Element with no text content (e.g., horizontal rule): label shows just "Horizontal rule".

---

#### `TC-mdr-comment-count-increments`: Comment count updates in rendered view

- **Type**: Integration
- **Covers**: `FR-mdr-rendered-comment-create`
- **Preconditions**: A markdown file is loaded in rendered view. Comment count shows "0 comments".
- **Steps**:
  1. Add a comment on a heading. Observe the toolbar.
  2. Add a comment on a paragraph. Observe the toolbar.
  3. Delete the first comment. Observe the toolbar.
- **Expected Result**: After step 1: "1 comment". After step 2: "2 comments". After step 3: "1 comment".
- **Edge Cases**: None.

---

### Prompt Generation from Rendered View

---

#### `TC-mdr-prompt-raw-source-lines`: Prompt references raw markdown source, not HTML

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`, `AC-mdr-comment-heading`
- **Preconditions**: A markdown file is loaded in rendered view with a comment on a heading at raw line 15.
- **Steps**:
  1. Observe the prompt preview.
- **Expected Result**: The prompt contains the raw markdown source `## API Reference` (not `<h2>API Reference</h2>`) paired with the comment. The entry reads: `- **Heading (lines 15-15)**:` followed by a markdown code fence with the raw source, followed by `Comment: "..."`.
- **Edge Cases**:
  - Comment on a paragraph spanning raw lines 10-14: the prompt includes all 5 raw lines in the code fence.

---

#### `TC-mdr-prompt-element-type`: Prompt includes element type annotation

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`
- **Preconditions**: Comments exist on a heading, paragraph, and code block.
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: Each comment entry in the "Requested Changes" section labels the element type: "Heading", "Paragraph", "Code block". The labels match the element types from the design spec.
- **Edge Cases**: None.

---

#### `TC-mdr-prompt-format-structure`: Prompt follows the rendered view format spec

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`
- **Preconditions**: A markdown file named "README.md" is loaded in rendered view with a preamble and two comments.
- **Steps**:
  1. Inspect the full prompt output.
- **Expected Result**: The prompt contains, in order:
  1. `## Instructions` with the preamble text.
  2. `## File: README.md (Markdown) -- Rendered View`.
  3. A markdown code fence with the full raw source and line numbers.
  4. `## Requested Changes` with each comment entry.
  The heading includes "-- Rendered View" to distinguish from raw-mode prompts.
- **Edge Cases**: None.

---

#### `TC-mdr-prompt-multiple-comments-order`: Comments listed in document order

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`
- **Preconditions**: Comments are added in this order: on a paragraph at AST position 5 (created first), on a heading at AST position 0 (created second), on a code block at AST position 3 (created third).
- **Steps**:
  1. Inspect the prompt output's "Requested Changes" section.
- **Expected Result**: Comments appear in document order (by AST position): heading (position 0), code block (position 3), paragraph (position 5). Creation order does not affect output order.
- **Edge Cases**: None.

---

#### `TC-mdr-prompt-no-preamble`: Prompt omits Instructions section when no preamble

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`
- **Preconditions**: A markdown file is loaded in rendered view with a comment but no preamble.
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: The prompt does NOT contain a `## Instructions` section. It starts with `## File:`.
- **Edge Cases**:
  - Whitespace-only preamble: treated as empty, no Instructions section.

---

#### `TC-mdr-prompt-with-preamble`: Prompt includes Instructions section when preamble exists

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-comment-prompt`
- **Preconditions**: A markdown file is loaded in rendered view with a comment and preamble "Review for readability".
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: The prompt starts with `## Instructions` followed by "Review for readability", then the file section.
- **Edge Cases**: None.

---

### View Switch Behavior

---

#### `TC-mdr-switch-with-comments-confirm`: Switch with comments shows confirmation and clears on confirm

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`
- **Preconditions**: A markdown file is loaded in rendered view. Two comments exist.
- **Steps**:
  1. Click the "Raw" segment.
  2. Observe the confirmation dialog.
  3. Click "Switch and clear comments".
- **Expected Result**: A ConfirmationDialog appears with title "Switch view mode?", body mentioning that switching to Raw view will clear all 2 comments and explaining that comments cannot be transferred between view modes. After confirming: all rendered-mode comments are cleared, comment count resets to 0, the view switches to raw. The preamble is preserved.
- **Edge Cases**:
  - Dialog body includes the exact comment count (e.g., "all 2 comments").

---

#### `TC-mdr-switch-with-comments-cancel`: Cancel preserves comments and view

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`
- **Preconditions**: A markdown file is loaded in rendered view. Comments exist. The confirmation dialog is open.
- **Steps**:
  1. Click "Cancel" (or press `Escape`).
- **Expected Result**: The dialog closes. The view stays on "Rendered". All comments are preserved. Comment count is unchanged. The toggle remains on "Rendered".
- **Edge Cases**:
  - Pressing `Escape`: same as clicking Cancel.
  - Clicking the backdrop/overlay: closes without switching (same as Cancel).

---

#### `TC-mdr-switch-no-comments-immediate`: Switch with no comments is immediate

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`, `AC-mdr-switch-no-comments`
- **Preconditions**: A markdown file is loaded in rendered view. Zero comments exist.
- **Steps**:
  1. Click the "Raw" segment.
- **Expected Result**: The view switches immediately to raw mode. No confirmation dialog appears. The transition happens with the standard fade animation (100ms out, 150ms in).
- **Edge Cases**: None.

---

#### `TC-mdr-switch-preamble-preserved`: Preamble is preserved across render mode switches

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`
- **Preconditions**: A markdown file is loaded. The user has entered a preamble in the sidebar.
- **Steps**:
  1. In raw view, type preamble "Review for documentation quality".
  2. Switch to rendered view (no comments, so immediate switch).
  3. Observe the preamble in the sidebar.
  4. Switch back to raw view.
  5. Observe the preamble.
- **Expected Result**: The preamble text "Review for documentation quality" is preserved across both switches. Render mode changes never clear the preamble.
- **Edge Cases**: None.

---

#### `TC-mdr-switch-raw-to-rendered`: All four toggle transitions work (Raw + File -> Rendered + File)

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded, Raw + File active, no comments.
- **Steps**:
  1. Click "Rendered". Observe: Rendered + File view.
- **Expected Result**: The view shows formatted HTML output. The File/Diff toggle remains on "File". The render toggle shows "Rendered" active.
- **Edge Cases**: None.

---

#### `TC-mdr-switch-rendered-to-raw`: Rendered + File -> Raw + File

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded, Rendered + File active, no comments.
- **Steps**:
  1. Click "Raw". Observe: Raw + File view.
- **Expected Result**: The view returns to syntax-highlighted raw markdown source with line numbers.
- **Edge Cases**: None.

---

#### `TC-mdr-switch-rendered-file-to-rendered-diff`: Rendered + File -> Rendered + Diff

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded via slash command, Rendered + File active, no comments.
- **Steps**:
  1. Click "Diff". Observe: the rendered diff view loads.
- **Expected Result**: The view transitions to the RenderedDiffViewer. A loading spinner shows "Computing rendered diff..." if computation takes noticeable time. After loading, the rendered diff displays with addition/removal/modification annotations.
- **Edge Cases**:
  - If comments existed in Rendered + File mode: confirmation dialog appears before switching.

---

#### `TC-mdr-switch-rendered-diff-to-rendered-file`: Rendered + Diff -> Rendered + File

- **Type**: E2E
- **Covers**: `FR-mdr-switch-comments`
- **Preconditions**: Markdown file loaded, Rendered + Diff active, no comments.
- **Steps**:
  1. Click "File". Observe: the rendered file view loads.
- **Expected Result**: The view transitions to the RenderedViewer showing the full rendered file without diff annotations. Comments are cleared (with confirmation if any existed).
- **Edge Cases**: None.

---

### Raw View Unchanged

---

#### `TC-mdr-raw-file-identical`: Raw + File view is identical to pre-feature behavior

- **Type**: E2E
- **Covers**: `FR-mdr-raw-diff-unchanged`, `AC-mdr-raw-unchanged`
- **Preconditions**: A markdown file is loaded with the render toggle on "Raw".
- **Steps**:
  1. Observe the code viewer panel.
  2. Verify: syntax-highlighted markdown source, line numbers, gutter with comment affordances, line-based comment clicking.
- **Expected Result**: The display is identical to the existing behavior before the markdown rendered view feature was added. Line numbers are present. Gutter shows the "+" comment affordance on hover. Clicking a line opens the line-based InlineCommentEditor. Syntax highlighting shows markdown tokens (headings, bold, code spans, etc.) with appropriate Shiki colors.
- **Edge Cases**: None.

---

#### `TC-mdr-raw-diff-identical`: Raw + Diff view is identical to pre-feature behavior

- **Type**: E2E
- **Covers**: `FR-mdr-raw-diff-unchanged`, `AC-mdr-raw-unchanged`
- **Preconditions**: A markdown file with changes is loaded via the slash command. Render toggle is on "Raw". File/Diff toggle is on "Diff".
- **Steps**:
  1. Observe the diff viewer panel.
  2. Verify: unified diff with added/removed/context lines, line numbers, collapsed sections, gutter with comment affordances.
- **Expected Result**: The raw diff view behaves identically to the existing diff view feature (`design/diff-view.md`). Added lines have green background, removed lines have red background, context lines have white background. Collapsed sections show the "... N unchanged lines ..." separator. No diff annotations from the rendered diff feature are present.
- **Edge Cases**: None.

---

### Rendered Diff Display

---

#### `TC-mdr-rdiff-added-block`: Added block renders with green highlight and ADDED badge

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-additions`
- **Preconditions**: A markdown file where the working copy has a new paragraph not present in HEAD is loaded. Rendered + Diff view is active.
- **Steps**:
  1. Locate the new paragraph in the rendered diff.
  2. Inspect its visual styling.
- **Expected Result**: The new paragraph has background `#F0FDF4` (green-50). Left border: 3px solid `#22C55E` (green-500). An "ADDED" label badge appears in the upper-left of the block (background `#DCFCE7`, text `#15803D`, 10px font, uppercase). The paragraph content renders as formatted HTML within the green-highlighted block.
- **Edge Cases**:
  - Multiple consecutive added blocks: each gets its own ADDED badge and green background.

---

#### `TC-mdr-rdiff-removed-block`: Removed block renders with red highlight, strikethrough, and REMOVED badge

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-removals`
- **Preconditions**: A markdown file where the working copy has a paragraph removed that existed in HEAD. Rendered + Diff view is active.
- **Steps**:
  1. Locate the removed paragraph in the rendered diff.
  2. Inspect its visual styling.
- **Expected Result**: The removed paragraph has background `#FEF2F2` (red-50). Left border: 3px solid `#EF4444` (red-500). Text has `text-decoration: line-through` and color `#6B7280`. A "REMOVED" label badge appears in the upper-left (background `#FEE2E2`, text `#B91C1C`). The content is rendered from the baseline (HEAD) version's markdown.
- **Edge Cases**:
  - Removed heading: strikethrough and red styling apply to the heading text; the heading's own left-border accent is overridden by the red diff border.

---

#### `TC-mdr-rdiff-modified-block-word-diff`: Modified block shows word-level inline diff

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-modifications`
- **Preconditions**: A markdown file where a paragraph changed from "The API returns JSON data" to "The API returns XML data" in the working copy. Rendered + Diff view is active.
- **Steps**:
  1. Locate the modified paragraph in the rendered diff.
  2. Inspect the inline diff annotations.
- **Expected Result**: The paragraph renders the new version ("The API returns XML data") with inline annotations. "JSON" appears with strikethrough, red background `#FECACA`, and gray text `#6B7280`. "XML" appears with green background `#BBF7D0` and normal text color. Surrounding unchanged words ("The API returns", "data") render normally. No block-level background change is applied to the whole paragraph.
- **Edge Cases**:
  - Modification that changes most of the paragraph: word-level diff is still applied, showing many red/green annotations.
  - Modification that only adds words (e.g., "returns data" -> "returns JSON data"): only the added word "JSON" gets the green highlight.

---

#### `TC-mdr-rdiff-unchanged-block`: Unchanged blocks render normally

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`
- **Preconditions**: A markdown file with some changes and some unchanged sections. Rendered + Diff view is active.
- **Steps**:
  1. Locate a paragraph that exists identically in both HEAD and working copy.
  2. Inspect its styling.
- **Expected Result**: The paragraph renders with no diff annotations -- no background color, no badge, no strikethrough. It appears exactly as it would in the rendered file view.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-fallback-banner`: Fallback banner appears for heavily restructured files

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`, `AC-mdr-diff-fallback`
- **Preconditions**: A markdown file where > 80% of blocks have been modified or replaced. Rendered + Diff view is active.
- **Steps**:
  1. Observe the top of the rendered diff content.
- **Expected Result**: A fallback banner appears with background `#FEF3C7`, border 1px solid `#F59E0B`. It contains an info icon (`#D97706`), title "This file has extensive structural changes." (13px, weight 600, `#92400E`), description "The rendered diff may be hard to follow." (13px, weight 400, `#92400E`), and a "Switch to Raw Diff" text link (`#2563EB`). The banner has a dismiss button (X, top-right).
- **Edge Cases**:
  - File with exactly 80% blocks changed: no fallback banner (threshold is > 80%).
  - File with 81% blocks changed: fallback banner appears.

---

#### `TC-mdr-rdiff-fallback-switch-link`: Fallback banner "Switch to Raw Diff" link works

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`, `AC-mdr-diff-fallback`
- **Preconditions**: The fallback banner is displayed in the rendered diff view.
- **Steps**:
  1. Click the "Switch to Raw Diff" link in the banner.
  2. Observe the view state.
- **Expected Result**: The render toggle switches to "Raw" (keeping File/Diff on "Diff"). The view shows the standard raw diff viewer. If comments existed, the mode-switch confirmation flow applies.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-fallback-dismiss`: Fallback banner can be dismissed

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`
- **Preconditions**: The fallback banner is displayed.
- **Steps**:
  1. Click the dismiss (X) button on the banner.
- **Expected Result**: The banner disappears. The rendered diff content is still shown below. The banner does not reappear during the session (for this file/diff state).
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-loading-spinner`: Loading spinner shows during diff computation

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`
- **Preconditions**: A markdown file with changes is loaded via the slash command.
- **Steps**:
  1. Switch to Rendered + Diff mode.
  2. Observe the code viewer panel during computation.
- **Expected Result**: A centered spinner (24px, `#2563EB`, 1s rotation) with "Computing rendered diff..." text (13px, `#94A3B8`, 8px below) is shown while the AST diff is computed. After computation completes, the spinner is replaced by the rendered diff content.
- **Edge Cases**:
  - Very small file (< 100 lines): spinner may flash briefly or not appear at all if computation is instant.

---

#### `TC-mdr-rdiff-timeout-fallback`: Timeout falls back to raw diff with toast

- **Type**: E2E / Performance
- **Covers**: `FR-mdr-rendered-diff-display`, `NFR-mdr-rendered-diff-perf`, `AC-mdr-diff-fallback`
- **Preconditions**: A markdown file large enough (or computationally complex enough) to cause the AST diff to exceed 5 seconds. (May need to be simulated by throttling or using an extremely large file.)
- **Steps**:
  1. Switch to Rendered + Diff mode.
  2. Wait for the computation to exceed 5 seconds.
- **Expected Result**: The computation is cancelled. The view automatically switches to Raw + Diff. An info toast appears: "File too large for rendered diff. Showing raw diff instead." The toast auto-dismisses after a few seconds.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-no-changes`: Rendered diff with no changes shows empty state

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-display`
- **Preconditions**: A markdown file loaded via `/shepherd` that is identical to its git HEAD version (no changes).
- **Steps**:
  1. Switch to Rendered + Diff mode (set both toggles).
  2. Observe the rendered diff view.
- **Expected Result**: The AST diff result has zero non-unchanged entries. The rendered diff view shows only unchanged blocks with no annotations (no green/red highlights, no badges). Alternatively, the existing "No changes detected" empty state from the raw diff view is shown. The user can switch to File mode or Raw mode.
- **Edge Cases**:
  - File has only whitespace differences that normalize away during parsing: should still show as no changes in rendered diff.

---

### Comments on Rendered Diff Elements

---

#### `TC-mdr-rdiff-comment-added`: Comment on an added element in rendered diff

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-comment`
- **Preconditions**: Rendered + Diff view is active showing an added heading.
- **Steps**:
  1. Hover over the added heading. Observe the hover affordance.
  2. Click the comment icon.
  3. Type "Good addition. Add a note about the reset window." and submit.
- **Expected Result**: The CommentBubble appears below the added heading with label "Added Heading: ## Rate Limiting". The comment is anchored with identifier `added:heading-N`.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-comment-removed`: Comment on a removed element in rendered diff

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-comment`
- **Preconditions**: Rendered + Diff view is active showing a removed paragraph.
- **Steps**:
  1. Click the comment icon on the removed paragraph.
  2. Type "We should keep a deprecation notice" and submit.
- **Expected Result**: The CommentBubble appears below the removed paragraph with label "Removed Paragraph: [text preview]". Despite the strikethrough styling on the element, the comment affordance works normally.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-comment-modified`: Comment on a modified element in rendered diff

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-comment`
- **Preconditions**: Rendered + Diff view is active showing a modified paragraph with word-level diff.
- **Steps**:
  1. Click the comment icon on the modified paragraph.
  2. Type "I prefer the full word 'authentication'" and submit.
- **Expected Result**: The CommentBubble appears below the modified paragraph with label "Modified Paragraph: [text preview]". The comment anchor identifier includes `modified:` qualifier.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-comment-unchanged`: Comment on an unchanged element in rendered diff

- **Type**: E2E
- **Covers**: `FR-mdr-rendered-diff-comment`
- **Preconditions**: Rendered + Diff view is active. An unchanged paragraph is visible.
- **Steps**:
  1. Click the comment icon on the unchanged paragraph.
  2. Type "Consider updating this section" and submit.
- **Expected Result**: The CommentBubble appears with label "Paragraph: [text preview]" (no change-type prefix for unchanged). The comment anchor identifier includes `unchanged:` qualifier.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-comment-anchor-qualifier`: Comment anchors include change-type qualifier

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-comment`
- **Preconditions**: Comments exist on added, removed, modified, and unchanged elements.
- **Steps**:
  1. Inspect the internal comment objects' element identifiers.
- **Expected Result**: Added element: `added:heading-3`. Removed element: `removed:paragraph-5`. Modified element: `modified:list-1-item-2`. Unchanged element: `unchanged:paragraph-0`. The qualifier is prepended to the standard element identifier.
- **Edge Cases**: None.

---

### Prompt Generation from Rendered Diff View

---

#### `TC-mdr-rdiff-prompt-modified-old-new`: Modified element prompt shows old and new source

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`
- **Preconditions**: Rendered diff view is active with a comment on a modified paragraph.
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: The prompt entry shows:
  ```
  ### Modified Paragraph (lines 3-4 -> lines 3-4):
  Old:
  ```markdown
  [old raw source]
  ```
  New:
  ```markdown
  [new raw source]
  ```
  Comment: "[comment text]"
  ```
  Both old and new raw markdown source are included in separate code fences.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-prompt-added-new-only`: Added element prompt shows only new source

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`
- **Preconditions**: Rendered diff view is active with a comment on an added heading.
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: The prompt entry shows:
  ```
  ### Added Heading (new lines 8-8):
  ```markdown
  ## Rate Limiting
  ```
  Comment: "[comment text]"
  ```
  Only the new source is shown. No "Old:" section.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-prompt-removed-old-only`: Removed element prompt shows only old source

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`
- **Preconditions**: Rendered diff view is active with a comment on a removed paragraph.
- **Steps**:
  1. Inspect the prompt output.
- **Expected Result**: The prompt entry shows:
  ```
  ### Removed Paragraph (old lines 15-16):
  ```markdown
  [old raw source]
  ```
  Comment: "[comment text]"
  ```
  Only the old source is shown. No "New:" section.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-prompt-heading-format`: Rendered diff prompt uses correct heading format

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-prompt`
- **Preconditions**: A markdown file named "README.md" is loaded in rendered diff view with a preamble and comments.
- **Steps**:
  1. Inspect the full prompt output.
- **Expected Result**: The prompt contains:
  1. `## Instructions` with preamble text.
  2. `## File: README.md (Markdown) -- Rendered Diff View`.
  3. A preamble paragraph: "The following shows changes between the git HEAD version and the current working copy, annotated at the document element level."
  4. `## Changed Elements` (not "Requested Changes") with comment entries.
- **Edge Cases**: None.

---

#### `TC-mdr-rdiff-prompt-document-order`: Rendered diff comments listed in document order

- **Type**: Unit
- **Covers**: `FR-mdr-rendered-diff-prompt`
- **Preconditions**: Comments on multiple elements in the rendered diff view, added in non-sequential order.
- **Steps**:
  1. Inspect the "Changed Elements" section of the prompt.
- **Expected Result**: Comments appear in document order (by element position in the merged diff AST), regardless of creation order.
- **Edge Cases**: None.

---

### Security (XSS Safety)

---

#### `TC-mdr-xss-script-tag`: Script tags are stripped from rendered output

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`
- **Preconditions**: A markdown file containing `<script>alert('xss')</script>` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Observe the rendered output.
  3. Check the browser console for script execution.
- **Expected Result**: The `<script>` tag is stripped. No alert dialog appears. No JavaScript executes. The rest of the markdown renders normally. The console shows no errors from stripped scripts.
- **Edge Cases**:
  - Script tag with attributes: `<script type="text/javascript">code</script>` -- also stripped.
  - Script tag split across lines: still stripped.

---

#### `TC-mdr-xss-event-handler`: Event handler attributes are stripped

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`
- **Preconditions**: A markdown file containing `<img src="x" onerror="alert('xss')">` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Observe: the image renders (or shows alt text for broken src), but no alert fires.
- **Expected Result**: The `onerror` attribute is stripped from the `<img>` tag before DOM insertion. No JavaScript executes.
- **Edge Cases**:
  - Other event handlers: `onclick`, `onload`, `onmouseover` -- all stripped.
  - Case variations: `onClick`, `ONCLICK` -- all stripped.

---

#### `TC-mdr-xss-javascript-url`: `javascript:` URLs are stripped

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`
- **Preconditions**: A markdown file containing `[click me](javascript:alert('xss'))` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Click the link.
- **Expected Result**: The link renders but clicking it does not execute JavaScript. The `javascript:` URL is sanitized -- either the `href` is removed or replaced with `#`.
- **Edge Cases**:
  - URL with encoding: `javascript&#58;alert(1)` -- also sanitized.
  - Mixed case: `jAvAsCrIpT:alert(1)` -- also sanitized.

---

#### `TC-mdr-xss-iframe`: Iframe injection is prevented

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`
- **Preconditions**: A markdown file containing `<iframe src="https://evil.com"></iframe>` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the DOM.
- **Expected Result**: The `<iframe>` tag is stripped from the output. No iframe appears in the DOM. No external content is loaded.
- **Edge Cases**:
  - `<object>` and `<embed>` tags: also stripped.

---

#### `TC-mdr-xss-svg-script`: SVG with embedded script is neutralized

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`
- **Preconditions**: A markdown file containing:
  ```html
  <svg onload="alert('xss')"><circle r="40"></circle></svg>
  ```
- **Steps**:
  1. Switch to rendered view.
  2. Observe: no alert fires.
- **Expected Result**: The `onload` attribute is stripped from the SVG element. The SVG may render visually or be stripped entirely (either is acceptable). No JavaScript executes.
- **Edge Cases**:
  - SVG with `<script>` child element: the script child is stripped.

---

#### `TC-mdr-xss-data-url`: Data URLs are blocked (except for images)

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`
- **Preconditions**: A markdown file containing `<a href="data:text/html,<script>alert(1)</script>">click</a>` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Click the link.
- **Expected Result**: The `data:` URL is stripped or neutralized. No new page opens with the injected content.
- **Edge Cases**:
  - `data:image/png;base64,...` in an `<img>` tag: should be preserved (images are the exception per the design spec).

---

#### `TC-mdr-xss-safe-html-preserved`: Safe HTML tags are preserved through sanitization

- **Type**: E2E
- **Covers**: `NFR-mdr-xss-safety`
- **Preconditions**: A markdown file containing `<details><summary>Click to expand</summary><p>Hidden content</p></details>` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Click the disclosure triangle.
- **Expected Result**: The `<details>` element renders as a collapsible section. Clicking the summary expands/collapses the content. The safe HTML is preserved through sanitization.
- **Edge Cases**:
  - Other safe tags: `<sup>`, `<sub>`, `<mark>`, `<abbr>` -- all preserved.

---

### Performance

---

#### `TC-mdr-perf-render-5k`: Markdown rendering within 200ms for 5,000-line file

- **Type**: Performance
- **Covers**: `NFR-mdr-render-perf`, `AC-mdr-large-file-renders`
- **Preconditions**: A markdown file with exactly 5,000 lines is prepared (mix of headings, paragraphs, lists, code blocks).
- **Steps**:
  1. Load the file.
  2. Record `performance.now()` before switching to rendered view.
  3. Switch to rendered view.
  4. Record `performance.now()` when rendering completes (content visible).
- **Expected Result**: The rendering (parse + HTML generation + syntax highlighting of code blocks + sanitization + DOM insertion) completes within 200ms.
- **Edge Cases**:
  - File with many fenced code blocks (computationally expensive syntax highlighting): may approach the 200ms limit. Still must complete within budget.

---

#### `TC-mdr-perf-render-10k`: Markdown rendering within 500ms for 10,000-line file

- **Type**: Performance
- **Covers**: `NFR-mdr-render-perf`
- **Preconditions**: A markdown file with exactly 10,000 lines is prepared.
- **Steps**:
  1. Load the file.
  2. Switch to rendered view and measure rendering time.
- **Expected Result**: Rendering completes within 500ms. If the rendering would block the UI for > 100ms, it should be deferred to a Web Worker or use incremental rendering.
- **Edge Cases**: None.

---

#### `TC-mdr-perf-render-ui-block`: Rendering does not block UI for > 100ms

- **Type**: Performance
- **Covers**: `NFR-mdr-render-perf`
- **Preconditions**: A markdown file with 5,000+ lines is loaded.
- **Steps**:
  1. Open browser DevTools Performance panel.
  2. Switch to rendered view.
  3. Observe the main thread timeline.
- **Expected Result**: No single task on the main thread exceeds 100ms. If the rendering is expensive, it should be chunked or offloaded to a Web Worker.
- **Edge Cases**: None.

---

#### `TC-mdr-perf-scroll-smooth`: Rendered view scrolls smoothly for large files

- **Type**: Performance
- **Covers**: `NFR-mdr-render-scroll-perf`, `AC-mdr-large-file-renders`
- **Preconditions**: A markdown file with 5,000 lines is loaded in rendered view.
- **Steps**:
  1. Scroll from top to bottom using continuous scrolling.
  2. Scroll back to the top.
  3. Measure frame timing via DevTools Performance panel.
- **Expected Result**: Scrolling is smooth with no visible jank. No frame drops exceed 200ms. The majority of frames render under 16ms.
- **Edge Cases**:
  - File with many images (even broken ones): scroll performance is not degraded.

---

#### `TC-mdr-perf-scroll-content-visibility`: Content-visibility optimization for large files

- **Type**: Integration
- **Covers**: `NFR-mdr-render-scroll-perf`
- **Preconditions**: A markdown file with > 5,000 lines is loaded in rendered view.
- **Steps**:
  1. Inspect the computed CSS of top-level block elements.
- **Expected Result**: Top-level block elements have `content-visibility: auto` applied. This optimizes rendering by skipping layout and paint for off-screen elements.
- **Edge Cases**:
  - File with < 5,000 lines: `content-visibility: auto` may or may not be applied (optimization is optional for smaller files).

---

#### `TC-mdr-perf-rdiff-5k`: Rendered diff computation within 1s for 5,000-line file

- **Type**: Performance
- **Covers**: `NFR-mdr-rendered-diff-perf`
- **Preconditions**: Two versions of a 5,000-line markdown file with ~20% of blocks changed are available.
- **Steps**:
  1. Load the file and switch to Rendered + Diff mode.
  2. Measure the time from diff computation start to rendered diff display.
- **Expected Result**: The AST diff computation (parse both versions, diff ASTs, compute word-level diffs) completes within 1 second.
- **Edge Cases**: None.

---

#### `TC-mdr-perf-rdiff-10k`: Rendered diff computation within 3s for 10,000-line file

- **Type**: Performance
- **Covers**: `NFR-mdr-rendered-diff-perf`
- **Preconditions**: Two versions of a 10,000-line markdown file are available.
- **Steps**:
  1. Switch to Rendered + Diff mode and measure computation time.
- **Expected Result**: Computation completes within 3 seconds. A loading spinner is shown during computation.
- **Edge Cases**: None.

---

#### `TC-mdr-perf-rdiff-timeout`: Rendered diff computation cancelled after 5s

- **Type**: Performance
- **Covers**: `NFR-mdr-rendered-diff-perf`, `AC-mdr-diff-fallback`
- **Preconditions**: A file large enough or complex enough to exceed the 5-second computation budget.
- **Steps**:
  1. Switch to Rendered + Diff mode.
  2. Wait for the 5-second timeout.
- **Expected Result**: After 5 seconds, computation is cancelled. The view auto-switches to Raw + Diff. An info toast appears: "File too large for rendered diff. Showing raw diff instead."
- **Edge Cases**: None.

---

### Accessibility

---

#### `TC-mdr-a11y-keyboard-nav`: Navigate rendered elements via keyboard

- **Type**: E2E
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Press `Tab` to enter the rendered content area.
  2. Press `Tab` to cycle through commentable block elements.
  3. Observe the focus ring on each element.
  4. Press `Shift+Tab` to move backwards.
- **Expected Result**: Each commentable element (heading, paragraph, list item, code block, table, blockquote) receives a visible focus ring (2px `#2563EB` outline, 2px offset) when focused. The comment icon appears in the C column for the focused element. Elements are traversed in document order.
- **Edge Cases**:
  - `Tab` past the last element: focus leaves the rendered content area and moves to the next toolbar/sidebar element.

---

#### `TC-mdr-a11y-keyboard-comment`: Add comment via keyboard without mouse

- **Type**: E2E
- **Covers**: `NFR-mdr-accessibility`, `AC-mdr-keyboard-comment`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Press `Tab` to enter the rendered content area.
  2. Press `Tab` to focus a paragraph element.
  3. Press `Enter` (or `c`) to open the InlineCommentEditor.
  4. Type "Fix this paragraph".
  5. Press `Cmd+Enter` / `Ctrl+Enter` to submit.
- **Expected Result**: The InlineCommentEditor opens for the focused paragraph without mouse interaction. After submission, the CommentBubble appears and focus returns to the paragraph element. The entire workflow is achievable without a mouse.
- **Edge Cases**:
  - Pressing `Escape` after opening the editor: editor closes, focus returns to the element.
  - Pressing `Tab` within the editor: cycles through the text area, Comment button, Cancel button.

---

#### `TC-mdr-a11y-screen-reader-elements`: Screen reader announces rendered elements

- **Type**: Manual / Accessibility
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded in rendered view. A screen reader (e.g., VoiceOver, NVDA) is active.
- **Steps**:
  1. Navigate through rendered elements using the screen reader's navigation commands.
  2. Listen to the announcements.
- **Expected Result**: Each element is announced by type and content. Examples: "Heading level 2: API Reference", "Paragraph: This module provides the core authentication...", "List item: POST /login". Elements with comments append "has N comments" to the announcement.
- **Edge Cases**: None.

---

#### `TC-mdr-a11y-screen-reader-diff`: Screen reader announces diff annotations

- **Type**: Manual / Accessibility
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: Rendered diff view is active. A screen reader is active.
- **Steps**:
  1. Navigate through elements.
  2. Listen to announcements for added, removed, and modified elements.
- **Expected Result**: Added elements are announced as "Added heading level 2: Rate Limiting". Removed elements: "Removed paragraph: The old authentication system...". Modified elements: "Modified paragraph: This module provides the core [changed: authentication to auth] API...". Inline `<ins>` elements are announced as "Added text: [word]". Inline `<del>` elements: "Removed text: [word]".
- **Edge Cases**: None.

---

#### `TC-mdr-a11y-focus-on-mode-switch`: Focus management on render mode switch

- **Type**: E2E
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded.
- **Steps**:
  1. Switch to rendered view. Observe where focus goes after rendering.
  2. Switch back to raw view. Observe where focus goes.
  3. Switch to rendered diff view. Observe focus during loading spinner and after content appears.
- **Expected Result**: After switching to rendered view: focus moves to the first commentable element. After switching to raw view: focus moves to the first line in the code viewer. During rendered diff loading: focus remains on the render toggle. After rendered diff loads: focus moves to the first rendered element. When fallback banner appears: focus moves to the "Switch to Raw Diff" link.
- **Edge Cases**: None.

---

#### `TC-mdr-a11y-aria-toggle`: Render toggle has correct ARIA attributes

- **Type**: Integration
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded.
- **Steps**:
  1. Inspect the render toggle's DOM.
- **Expected Result**: The toggle group has `role="tablist"` and `aria-label="Render mode"`. The "Raw" segment has `role="tab"`, `aria-controls="code-viewer-panel"`. The "Rendered" segment has `role="tab"`, `aria-controls="code-viewer-panel"`. The active segment has `aria-selected="true"`. The inactive segment has `aria-selected="false"`.
- **Edge Cases**: None.

---

#### `TC-mdr-a11y-aria-rendered-content`: Rendered content area has correct ARIA attributes

- **Type**: Integration
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: A markdown file is loaded in rendered view.
- **Steps**:
  1. Inspect the rendered content area's DOM.
- **Expected Result**: The content area has `role="document"` and `aria-label="Rendered markdown content"`. Each commentable block element has `tabindex="0"`, `role="article"`, and an `aria-label` describing its content (e.g., `aria-label="Heading level 2: API Reference"`). Comment affordance icons have `role="button"` and `aria-label="Add comment on [element type]: [content preview]"`.
- **Edge Cases**: None.

---

#### `TC-mdr-a11y-aria-diff-annotations`: Rendered diff has correct ARIA for change types

- **Type**: Integration
- **Covers**: `NFR-mdr-accessibility`
- **Preconditions**: Rendered diff view is active with added, removed, and modified blocks.
- **Steps**:
  1. Inspect the DOM.
- **Expected Result**: Added blocks have `aria-label="Added [element type]: [content preview]"`. Removed blocks: `aria-label="Removed [element type]: [content preview]"`. Modified blocks: `aria-label="Modified [element type]: [content preview]"`. Inline added words use `<ins>` with `aria-label="Added text: [word]"`. Inline removed words use `<del>` with `aria-label="Removed text: [word]"`. The fallback banner has `role="alert"`. The loading spinner has `role="status"` and `aria-label="Computing rendered diff"`.
- **Edge Cases**: None.

---

### Edge Cases

---

#### `TC-mdr-edge-empty-file`: Empty markdown file renders empty view

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with zero content (empty file) is loaded.
- **Steps**:
  1. Switch to rendered view.
- **Expected Result**: The rendered view shows an empty content area. No errors occur. The comment affordance column is present but has no elements to anchor to. Switching back to raw view shows the empty file with no line numbers.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-only-frontmatter`: Markdown file with only YAML frontmatter

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing only YAML frontmatter (`---` delimiters with YAML between them) is loaded.
- **Steps**:
  1. Switch to rendered view.
- **Expected Result**: The frontmatter is rendered as a code block or horizontal rule (depending on the parser's handling), or the content is empty if the parser strips frontmatter. No crash occurs. The view is functional.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-many-headings`: Markdown file with 100+ headings

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`, `FR-mdr-element-id`
- **Preconditions**: A markdown file with 100 H2 headings (each with a short paragraph below) is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Scroll through the content.
  3. Add a comment on the 50th heading.
- **Expected Result**: All 100 headings render with correct styling. Scrolling is smooth. Each heading has a unique element identifier. The comment on the 50th heading anchors correctly and the prompt references the correct raw source lines.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-large-table`: Markdown file with a very large table (50+ rows, 10+ columns)

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with a table of 50 rows and 10 columns.
- **Steps**:
  1. Switch to rendered view.
  2. Scroll the table horizontally if it overflows.
- **Expected Result**: The table renders with all rows and columns. If the table exceeds the content max-width, horizontal scrolling is available within the content area. Alternating row backgrounds apply to all 50 rows. Column alignment is respected.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-deeply-nested-lists`: Deeply nested lists (> 4 levels)

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with lists nested 6 levels deep.
- **Steps**:
  1. Switch to rendered view.
  2. Inspect the nesting.
- **Expected Result**: All 6 levels render with proper indentation. Bullet styles repeat after 4 levels (disc, circle, square, disc, circle, square). Items are readable. No layout breakage.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-mdx-opaque-components`: MDX file renders JSX as opaque blocks

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: An `.mdx` file containing JSX component tags (e.g., `<CustomButton label="Click" />`) is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Locate the JSX component tag in the output.
- **Expected Result**: The JSX/component tag is displayed as an opaque code block or unrendered text. It is NOT rendered as an interactive component (v1 does not support component rendering for MDX). The surrounding markdown content renders normally.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-mermaid-code-block`: Mermaid code blocks render as highlighted code

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing a fenced code block with language `mermaid` is loaded.
- **Steps**:
  1. Switch to rendered view.
  2. Locate the mermaid code block.
- **Expected Result**: The mermaid code block renders as a syntax-highlighted code block (not as a rendered diagram). Diagram rendering is deferred to v2. The code block uses the same dark background and monospace styling as other code blocks.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-very-long-paragraph`: Extremely long paragraph (10,000+ characters)

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file with a single paragraph of 10,000 characters (no line breaks within it).
- **Steps**:
  1. Switch to rendered view.
  2. Observe the paragraph rendering.
- **Expected Result**: The paragraph renders with word wrapping within the 80ch max-width. Scrolling is smooth. Adding a comment on the paragraph works correctly. The prompt includes the full raw source text.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-only-headings`: Markdown file with only headings (no body text)

- **Type**: E2E
- **Covers**: `FR-mdr-render-commonmark`
- **Preconditions**: A markdown file containing only H1-H3 headings with no paragraph text between them.
- **Steps**:
  1. Switch to rendered view.
- **Expected Result**: All headings render with correct hierarchy. No errors from missing paragraph elements. Comments can be added on individual headings.
- **Edge Cases**: None.

---

#### `TC-mdr-edge-paste-md-filename`: Pasted content with `.md` filename triggers toggle

- **Type**: E2E
- **Covers**: `FR-mdr-detect-markdown`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Click "Paste content".
  2. Enter "notes.md" as the file name.
  3. Paste valid markdown content.
  4. Click "Load".
  5. Observe the toolbar.
- **Expected Result**: The render toggle appears because the filename has a `.md` extension. Note: the File/Diff toggle will be disabled (paste/upload files do not support diff), but the render toggle is still visible and functional.
- **Edge Cases**:
  - Paste with a non-markdown filename (e.g., "notes.txt"): no render toggle.

---

### Client-Side Only

---

#### `TC-mdr-client-only-no-requests`: No external requests during rendering

- **Type**: E2E
- **Covers**: `NFR-mdr-client-only`
- **Preconditions**: A markdown file is loaded. Network monitoring is enabled.
- **Steps**:
  1. Switch to rendered view.
  2. Switch to rendered diff view.
  3. Add comments. Generate prompts.
  4. Inspect all network requests during the workflow.
- **Expected Result**: No outbound network requests are made for rendering, diffing, or comment processing. All markdown parsing, HTML generation, syntax highlighting, sanitization, and AST diffing happen client-side. The only requests are for static assets from the same origin.
- **Edge Cases**: None.

---

## Edge Cases & Error Scenarios

---

### Switching between all four view combinations with comments

- **Trigger**: User has comments in one mode and rapidly switches through all four view combinations (Raw+File, Raw+Diff, Rendered+File, Rendered+Diff).
- **Expected behavior**: Each switch that changes the comment anchoring model triggers a confirmation dialog (if comments exist). Comments from one mode never leak into another mode. The preamble is preserved throughout.
- **Test cases**: `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-no-comments-immediate`, `TC-mdr-switch-preamble-preserved`

---

### Markdown with embedded dangerous content

- **Trigger**: A reviewer loads a markdown file containing XSS payloads (script tags, event handlers, javascript: URLs, iframes, SVG with scripts).
- **Expected behavior**: All dangerous content is sanitized before DOM insertion. The application never executes injected JavaScript. Safe HTML elements are preserved.
- **Test cases**: `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`

---

### Very large file rendering timeout

- **Trigger**: A markdown file exceeding 10,000 lines is loaded and the user switches to rendered view.
- **Expected behavior**: Rendering completes within the 500ms budget (or uses Web Worker / incremental rendering). Scroll performance is maintained via `content-visibility: auto`.
- **Test cases**: `TC-mdr-perf-render-10k`, `TC-mdr-perf-scroll-smooth`, `TC-mdr-perf-scroll-content-visibility`

---

### Rendered diff for file with no changes

- **Trigger**: User switches to Rendered + Diff for a markdown file identical to HEAD.
- **Expected behavior**: The empty diff state appears (same as raw diff empty state per `AC-diff-no-changes`). No rendered diff annotations are shown.
- **Test cases**: Covered by the existing `TC-diff-no-changes-empty-state` from `qa/diff-view.md` -- the empty state logic is shared.

---

### Loading a non-markdown file after being in rendered mode

- **Trigger**: User is in rendered view for a markdown file, then loads a `.ts` file.
- **Expected behavior**: The render toggle disappears. The view reverts to raw file view. The toggle state is reset.
- **Test cases**: `TC-mdr-toggle-resets-new-file`, `TC-mdr-detect-non-md-hidden`

---

### Comment on element near bottom of rendered content

- **Trigger**: User adds a comment on the very last element in the rendered markdown.
- **Expected behavior**: The InlineCommentEditor opens below the last element. The viewport scrolls to show the editor. After submitting, the CommentBubble appears and the viewport accommodates it.
- **Test cases**: `TC-mdr-comment-paragraph` (edge case variant)

---

### Rapid toggle switching

- **Trigger**: User rapidly clicks between "Raw" and "Rendered" multiple times in quick succession.
- **Expected behavior**: The final state matches the last click. No rendering artifacts, no partially rendered content, no crashes. Transition animations may be interrupted but the final state is correct.
- **Test cases**: `TC-mdr-toggle-independent-file-diff` (edge case variant)

---

## Regression Considerations

### Existing File View Functionality

The markdown rendered view feature modifies the toolbar (adding the RenderToggle component) and the code viewer panel (adding RenderedViewer and RenderedDiffViewer as alternative components). Regression tests should verify:

- **Raw file view unchanged**: Loading a markdown file with the toggle on "Raw" must produce identical behavior to the pre-feature state. Syntax highlighting, line numbers, line-based comments, prompt generation -- all unchanged.
- **Raw diff view unchanged**: Markdown files in Raw + Diff mode must behave identically to the existing diff view feature. No diff annotation styles from the rendered diff leak into the raw diff.
- **Non-markdown files unaffected**: TypeScript, Python, JSON, and all other file types must show no render toggle and function identically to the pre-feature state. The toolbar layout is unchanged for non-markdown files.
- **Comment stores are isolated**: Comments in raw mode, rendered mode, and diff mode are separate stores. Adding a comment in rendered mode does not affect raw mode comments. Mode switches clear comments (with confirmation) and do not cross-contaminate.

### Toolbar Layout

- **Toggle positioning**: The RenderToggle must be positioned correctly relative to the File/Diff toggle (12px gap) and not overlap with other toolbar elements (refresh button, comment navigation, etc.).
- **Toolbar states table**: All toolbar states from the design spec (empty state, non-markdown file, markdown paste/upload, markdown server) must be verified.

### Prompt Generation

- **File-mode prompts unchanged**: The `buildPrompt` function for raw file mode must produce identical output to before the feature. The rendered view prompt format is separate.
- **Diff-mode prompts unchanged**: The `buildDiffPrompt` function for raw diff mode must produce identical output. The rendered diff prompt format is separate.
- **Prompt auto-generation**: Prompts auto-update on comment/preamble changes in all modes (raw file, raw diff, rendered file, rendered diff).

### Performance

- **No regression in raw view performance**: Adding the rendered view code path (markdown parser, sanitizer, etc.) must not affect the performance of raw view rendering. These dependencies should be lazy-loaded.
- **Store re-renders**: Adding rendered-mode state to the Zustand store should not cause unnecessary re-renders in raw mode components.

### Recommended Regression Suite

Run the following test cases as a minimum regression suite before any release that includes the markdown rendered view feature:

- `TC-mdr-detect-md-ext` (toggle appears for markdown files)
- `TC-mdr-detect-non-md-hidden` (toggle hidden for non-markdown files)
- `TC-mdr-toggle-click-rendered` (toggle switches to rendered view)
- `TC-mdr-render-headings` (basic rendering works)
- `TC-mdr-render-code-blocks-highlighted` (code block highlighting works)
- `TC-mdr-comment-paragraph` (commenting works in rendered view)
- `TC-mdr-prompt-raw-source-lines` (prompt references raw source)
- `TC-mdr-switch-with-comments-confirm` (mode switch confirmation works)
- `TC-mdr-switch-no-comments-immediate` (immediate switch without comments)
- `TC-mdr-rdiff-added-block` (rendered diff shows additions)
- `TC-mdr-rdiff-modified-block-word-diff` (word-level diff works)
- `TC-mdr-xss-script-tag` (XSS protection works)
- `TC-mdr-perf-render-5k` (rendering performance within budget)
- `TC-mdr-a11y-keyboard-comment` (keyboard accessibility works)
- `TC-mdr-raw-file-identical` (raw view regression -- unchanged)
- `TC-mdr-raw-diff-identical` (raw diff regression -- unchanged)
