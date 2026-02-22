# Markdown Rendered View -- Design Spec

> Based on requirements in `../product/markdown-render.md`

## Screen Inventory

This feature does not introduce new screens or routes. It adds new view states within the existing single-page CRPG application by providing an alternative rendering mode for markdown files. The application continues to have one primary view that transitions through states as described in `../design/code-review-prompt.md`.

The markdown rendered view feature adds or modifies the following view states:

| View State | Change Type | Description |
|---|---|---|
| **File Loaded State -- Rendered + File** | New | The code viewer panel renders markdown as formatted HTML instead of syntax-highlighted source. |
| **File Loaded State -- Rendered + Diff** | New | The code viewer panel renders markdown as formatted HTML with diff annotations (additions, removals, modifications). |
| **File Loaded State -- Raw + File** | Existing (unchanged) | The existing file-loaded code viewer with syntax-highlighted markdown source and line numbers. |
| **File Loaded State -- Raw + Diff** | Existing (unchanged) | The existing diff view with raw markdown source. No changes from `../design/diff-view.md`. |

The rendered/raw toggle is only visible for markdown files. Non-markdown files continue to show only raw views with no toggle present in the DOM.

---

## Screen Definitions

### File Loaded Screen -- Toolbar Modifications

The existing toolbar is extended with a render mode toggle when a markdown file is loaded. The toolbar layout for a markdown file loaded via the server (both toggles visible and enabled) changes from:

```
+---[Logo/Title]---[File|Diff]---[Refresh]---[Comment Nav]---[Comment Count]------[Copy][Clear]---+
```

To:

```
+---[Logo/Title]---[File|Diff]---[Raw|Rendered]---[Refresh]---[Comment Nav]---[Comment Count]------[Copy][Clear]---+
```

#### Render Mode Toggle (`FR-mdr-render-toggle`, `FR-mdr-detect-markdown`, `AC-mdr-toggle-appears`, `AC-mdr-toggle-hidden-non-md`)

The toggle is a **segmented control** (two-segment button group) placed immediately after the File/Diff toggle, separated by a 12px gap. It contains two segments: "Raw" and "Rendered".

- **Placement**: After the File/Diff toggle (or after the application title if the File/Diff toggle is not visible), separated by a 12px gap. Before the refresh button (if visible) or comment navigation controls.
- **Dimensions**: "Raw" segment is 48px wide; "Rendered" segment is 80px wide. Both segments are 32px tall. Total control width: 128px.
- **Typography**: 13px, font-weight 500, system sans-serif.
- **Border**: 1px solid `#E2E8F0`, border-radius 6px on the outer corners of the group. The two segments share the inner edge (no double-border).

**Segment States** (identical styling pattern to the ViewModeToggle from `../design/diff-view.md`):

| State | Background | Text Color | Border |
|---|---|---|---|
| **Active (selected)** | `#2563EB` (primary blue) | `#FFFFFF` (white) | 1px solid `#2563EB` |
| **Inactive (not selected, enabled)** | `#FFFFFF` (white) | `#475569` (slate) | 1px solid `#E2E8F0` |
| **Inactive hover** | `#F8FAFC` (very light gray) | `#1E293B` (dark slate) | 1px solid `#E2E8F0` |
| **Focused** | Same as inactive/active + 2px blue focus ring (`#2563EB`, offset 2px) | Same | Same |

**Visibility** (`FR-mdr-detect-markdown`, `AC-mdr-toggle-hidden-non-md`): The toggle is visible only when the loaded file is a markdown file (detected by extension: `.md`, `.mdx`, `.markdown`, `.mdown`, `.mkdn`, `.mkd`). For non-markdown files, the toggle is **not rendered in the DOM** (hidden, not disabled). This differs from the File/Diff toggle, which shows as disabled for paste/upload files -- the render toggle is simply absent for non-markdown files.

**Default Selection** (`AC-mdr-toggle-appears`): When a markdown file is loaded, "Raw" is selected by default. Rendered mode is opt-in. The toggle state persists within the session but resets when a new file is loaded.

**Independence from File/Diff toggle**: The two toggles are independent. Both are visible simultaneously for markdown files loaded via the server. The render toggle controls *how* content is displayed (raw source vs. formatted HTML). The File/Diff toggle controls *what* content is displayed (full file vs. diff). This produces four combinations:

| Raw/Rendered | File/Diff | Result |
|---|---|---|
| Raw + File | Standard code viewer (existing behavior) |
| Raw + Diff | Standard diff viewer (existing behavior per `../design/diff-view.md`) |
| Rendered + File | RenderedViewer (new) |
| Rendered + Diff | RenderedDiffViewer (new) |

#### Updated Toolbar States Table

Extends the toolbar states table from `../design/diff-view.md`:

| Application State | File/Diff Toggle | Render Toggle | Refresh | Copy | Clear | Navigation |
|---|---|---|---|---|---|---|
| Empty (no file) | Hidden | Hidden | Hidden | Disabled | Disabled | Disabled |
| Non-markdown file loaded (paste/upload) | File active, Diff disabled | Hidden | Hidden | Depends on comments | Enabled | Depends on comments |
| Non-markdown file loaded (server) | File active, Diff enabled | Hidden | Hidden (visible in diff mode) | Depends on comments | Enabled | Depends on comments |
| Markdown file loaded (paste/upload) | File active, Diff disabled | Raw active, Rendered enabled | Hidden | Depends on comments | Enabled | Depends on comments |
| Markdown file loaded (server), Raw + File | File active, Diff enabled | Raw active, Rendered enabled | Hidden | Depends on comments | Enabled | Depends on comments |
| Markdown file loaded (server), Raw + Diff | File enabled, Diff active | Raw active, Rendered enabled | Visible, enabled | Depends on comments | Enabled | Depends on comments |
| Markdown file loaded (server), Rendered + File | File active, Diff enabled | Raw enabled, Rendered active | Hidden | Depends on comments | Enabled | Depends on comments |
| Markdown file loaded (server), Rendered + Diff, loading | File enabled, Diff active | Raw enabled, Rendered active | Visible, disabled (spinning) | Disabled | Enabled | Disabled |
| Markdown file loaded (server), Rendered + Diff, populated | File enabled, Diff active | Raw enabled, Rendered active | Visible, enabled | Depends on comments | Enabled | Depends on comments |

---

### File Loaded Screen -- Rendered View (Rendered + File)

When the render toggle is set to "Rendered" and the File/Diff toggle is set to "File", the code viewer panel replaces the raw CodeViewer with the RenderedViewer. The panel dimensions, position, and relationship to the sidebar remain identical. The FileHeader bar remains at the top, continuing to show the file name and the language badge (which reads "Markdown").

#### Rendered View Layout (`FR-mdr-render-styling`, `FR-mdr-render-commonmark`, `AC-mdr-render-basic`, `AC-mdr-render-gfm`, `AC-mdr-render-code-blocks`)

The rendered markdown occupies the code viewer panel area below the FileHeader. Instead of the gutter + line number + code content column layout of the raw view, the rendered view uses a single content area with a comment affordance column.

```
+---+--------------------------------------------------------------+
| C |  Rendered Content                                             |
+---+--------------------------------------------------------------+
| . |                                                               |
|   |  # API Reference                                              |
|   |                                                               |
| . |  This module provides the core authentication API for         |
|   |  managing user sessions and credentials.                      |
|   |                                                               |
|   |  +------------------------------------------------------+     |
|   |  | [Comment bubble] "This heading should be level 3" [E][D] | |
|   |  +------------------------------------------------------+     |
|   |                                                               |
| . |  ## Endpoints                                                 |
|   |                                                               |
| . |  - `POST /login` -- Authenticate a user                      |
| . |  - `POST /logout` -- End a user session                      |
| . |  - `GET /me` -- Get current user info                        |
|   |                                                               |
| . |  ```typescript                                                |
|   |  interface LoginRequest {                                     |
|   |    email: string;                                             |
|   |    password: string;                                          |
|   |  }                                                            |
|   |  ```                                                          |
|   |                                                               |
+---+--------------------------------------------------------------+
```

**Column layout** (left to right):

1. **C (Comment Affordance Column)**: 32px wide. Shows a faint comment icon on hover for the block element at the pointer's vertical position. When a block element has comments, shows a filled blue circle (8px diameter) -- identical to the raw view's gutter indicator. This column is sticky during horizontal scroll (though horizontal scroll is unlikely in rendered view due to the max-width cap).

2. **Rendered Content**: Remaining width, with a maximum content width of **80ch** (approximately 560-640px depending on the typeface at 14px body font size), centered horizontally within the available space. If the panel is wider than the max-width, equal padding appears on both sides. The content uses `margin: 0 auto` centering.

**Content Styling** (`FR-mdr-render-styling`):

| Element | Font | Size | Weight | Line Height | Additional |
|---|---|---|---|---|---|
| Body text (paragraphs) | System sans-serif | 14px | 400 | 22px | Color: `#1E293B` |
| H1 | System sans-serif | 24px | 700 | 32px | Left border: 3px solid `#2563EB`. Padding-left: 12px. Margin-top: 32px. Margin-bottom: 16px. Color: `#0F172A` |
| H2 | System sans-serif | 20px | 600 | 28px | Left border: 3px solid `#3B82F6`. Padding-left: 12px. Margin-top: 28px. Margin-bottom: 12px. Color: `#0F172A` |
| H3 | System sans-serif | 16px | 600 | 24px | Left border: 3px solid `#60A5FA`. Padding-left: 12px. Margin-top: 24px. Margin-bottom: 8px. Color: `#1E293B` |
| H4-H6 | System sans-serif | 14px | 600 | 22px | Left border: 2px solid `#93C5FD`. Padding-left: 12px. Margin-top: 20px. Margin-bottom: 8px. Color: `#1E293B` |
| Inline code | Monospace stack | 13px | 400 | 20px | Background: `#F1F5F9`. Padding: 2px 6px. Border-radius: 3px. Color: `#BE185D` (pink-700, matches typical code highlight) |
| Code blocks | Monospace stack | 13px | 400 | 20px | Background: `#1E293B`. Text: `#E2E8F0`. Padding: 16px. Border-radius: 6px. Overflow-x: auto. Syntax highlighted per `FR-crp-syntax-highlight` |
| Block quotes | System sans-serif | 14px | 400 (italic) | 22px | Left border: 3px solid `#CBD5E1`. Padding-left: 16px. Color: `#475569`. Background: `#F8FAFC` |
| Unordered lists | System sans-serif | 14px | 400 | 22px | Disc bullets. Nested: circle, square, disc (up to 4 levels). Padding-left: 24px per level |
| Ordered lists | System sans-serif | 14px | 400 | 22px | Decimal numbering. Nested: lower-alpha, lower-roman, decimal. Padding-left: 24px per level |
| Tables | System sans-serif | 13px | 400 | 20px | Border: 1px solid `#E2E8F0`. Header row: background `#F1F5F9`, font-weight 600. Alternating body rows: `#FFFFFF` / `#F8FAFC`. Cell padding: 8px 12px |
| Links | System sans-serif | 14px | 400 | 22px | Color: `#2563EB`. Underline on hover. Cursor: pointer. `target="_blank"` with `rel="noopener noreferrer"` |
| Images | N/A | N/A | N/A | N/A | Max-width: 100%. Border-radius: 4px. Failed images show alt text in italic muted text on a `#F8FAFC` background with a broken-image icon |
| Horizontal rules | N/A | N/A | N/A | N/A | 1px solid `#E2E8F0`. Margin: 24px 0 |
| Task lists | System sans-serif | 14px | 400 | 22px | Checkboxes are read-only. Checked: filled blue checkbox. Unchecked: empty bordered checkbox. Uses `appearance: none` + custom styling |
| Strikethrough | System sans-serif | 14px | 400 | 22px | `text-decoration: line-through`. Color: `#94A3B8` |

**HTML Sanitization** (`NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`): All rendered HTML is sanitized before DOM insertion. The sanitizer strips `<script>` tags, event handler attributes (`onclick`, `onerror`, etc.), `javascript:` URLs, `data:` URLs (except for images), `<iframe>`, `<object>`, `<embed>`, and any other active content vectors. Safe HTML tags embedded in markdown (e.g., `<details>`, `<summary>`, `<sup>`, `<sub>`, `<mark>`, `<abbr>`, `<ins>`, `<del>`) are preserved.

**Performance** (`NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`, `AC-mdr-large-file-renders`):
- Rendered view does not use virtualized scrolling (unlike the raw view). It renders a single HTML document.
- For files > 5,000 lines, `content-visibility: auto` is applied to top-level block elements for scroll performance optimization.
- Markdown rendering must complete within 200ms for files up to 5,000 lines and 500ms for files up to 10,000 lines.
- If rendering blocks the UI for > 100ms, it should be deferred to a Web Worker.

---

### File Loaded Screen -- Rendered Diff View (Rendered + Diff)

When the render toggle is set to "Rendered" and the File/Diff toggle is set to "Diff", the code viewer panel shows the RenderedDiffViewer. This view renders the new (working copy) version of the markdown as formatted HTML, with visual annotations showing what changed relative to the HEAD version.

#### Rendered Diff Layout (`FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications`)

The layout is identical to the rendered file view (comment affordance column + rendered content), but with diff annotations overlaid on the rendered elements.

```
+---+--------------------------------------------------------------+
| C |  Rendered Diff Content                                        |
+---+--------------------------------------------------------------+
|   |                                                               |
| . |  # API Reference                                              |
|   |                                                               |
| . |  This module provides the core [authentication]{+auth+} API   |   <- word-level diff
|   |  for managing user sessions [-and credentials-]{+and tokens+}.|
|   |                                                               |
| . | +--[ADDED]---------------------------------------------------+|
|   | | ## Rate Limiting                                            ||   <- new section
|   | |                                                             ||
|   | | All endpoints are rate-limited to 100 requests per minute.  ||
|   | +------------------------------------------------------------+|
|   |                                                               |
| . | +--[REMOVED]-------------------------------------------------+|
|   | | ~~## Legacy Auth~~                                          ||   <- removed section
|   | | ~~The old authentication system is deprecated.~~            ||
|   | +------------------------------------------------------------+|
|   |                                                               |
+---+--------------------------------------------------------------+
```

**Diff Annotation Styles**:

| Annotation Type | Visual Treatment |
|---|---|
| **Added block** (entire new element) | Background: `#F0FDF4` (green-50). Left border: 3px solid `#22C55E` (green-500). Label badge: "ADDED" in upper-left corner of the block. Label style: background `#DCFCE7` (green-100), text `#15803D` (green-700), font 10px, font-weight 600, uppercase, padding 2px 6px, border-radius 3px. The block content renders normally with the green background. |
| **Removed block** (entire deleted element) | Background: `#FEF2F2` (red-50). Left border: 3px solid `#EF4444` (red-500). Text has `text-decoration: line-through` and color shifts to `#6B7280` (gray-500). Label badge: "REMOVED" in upper-left. Label style: background `#FEE2E2` (red-100), text `#B91C1C` (red-700), font 10px, font-weight 600, uppercase, padding 2px 6px, border-radius 3px. |
| **Modified block** (content changed within element) | No block-level background change. Word-level inline diffs within the rendered text (see below). |
| **Unchanged block** | No annotations. Rendered normally. |

**Word-Level Inline Diff (Modified Blocks)**:

When a block element exists in both versions but its text content differs, the rendered diff shows the new version with inline annotations at the word/phrase level:

| Inline Annotation | Visual Treatment |
|---|---|
| **Added words** | Background: `#BBF7D0` (green-200). Padding: 1px 2px. Border-radius: 2px. Color: `#1E293B` (normal text). |
| **Removed words** | Background: `#FECACA` (red-200). Padding: 1px 2px. Border-radius: 2px. `text-decoration: line-through`. Color: `#6B7280` (gray-500). |

The inline diff is computed at the word level: words present in the old version but not the new are shown as removed (strikethrough, red background), and words present in the new version but not the old are shown as added (green background). Unchanged words render normally. The removed words appear inline at their original position relative to the surrounding text.

**Fallback Banner** (`AC-mdr-diff-fallback`): When the AST-level diff produces an unreadable result (heuristic: > 80% of blocks are modified or removed/added), a fallback banner appears at the top of the rendered diff content:

```
+--------------------------------------------------------------+
|  [info icon]  This file has extensive structural changes.     |
|               The rendered diff may be hard to follow.        |
|               [Switch to Raw Diff]                            |
+--------------------------------------------------------------+
```

- Background: `#FEF3C7` (amber-100). Border: 1px solid `#F59E0B` (amber-500). Border-radius: 6px. Padding: 12px 16px.
- Icon: info circle, 16px, color `#D97706` (amber-600).
- Title text: "This file has extensive structural changes." 13px, font-weight 600, color `#92400E` (amber-800).
- Description text: "The rendered diff may be hard to follow." 13px, font-weight 400, color `#92400E`.
- Link: "Switch to Raw Diff" as a text link, color `#2563EB`, underline on hover. Clicking switches the render toggle to "Raw" (keeping the File/Diff toggle on "Diff").
- The fallback banner is dismissible (small X button, top-right). After dismissal, the rendered diff content is still shown below.

**Performance** (`NFR-mdr-rendered-diff-perf`):
- AST diff computation must complete within 1s for files up to 5,000 lines, 3s for files up to 10,000 lines.
- A loading spinner is shown during computation: same centered spinner as the diff mode loading state (24px, primary blue, "Computing rendered diff..." text below).
- If computation exceeds 5 seconds, it is cancelled and the view automatically falls back to Raw + Diff with a toast: "File too large for rendered diff. Showing raw diff instead." (info toast variant).

---

### Comment Interaction in Rendered View

#### Element Comment Affordance (`FR-mdr-rendered-comment-create`, `FR-mdr-element-id`, `AC-mdr-comment-rendered-element`, `AC-mdr-comment-heading`)

In the rendered view (both File and Diff modes), commenting works at the block-element level rather than the line level.

**Commentable elements**: Every block-level rendered element is commentable: headings (H1-H6), paragraphs, list items, code blocks, tables (whole table, not individual rows), block quotes, horizontal rules, images. Each is assigned a stable AST-based identifier (`FR-mdr-element-id`).

**Hover affordance**:
1. When the user hovers over a commentable block element, the element receives a subtle highlight: background changes to `#F8FAFC` with a 150ms transition. The comment affordance column (C column) shows a comment icon at the vertical center of the hovered element.
2. The comment icon: a speech bubble outline icon, 16px, color `#94A3B8` (muted). On hover of the icon itself, color changes to `#2563EB` (primary blue) and a tooltip appears: "Add comment" (same tooltip style as toolbar tooltips).
3. The hover highlight and icon disappear when the pointer leaves the element (with a 100ms fade-out).
4. Elements that already have comments show the blue dot indicator in the C column (same as the raw view's gutter indicator). The comment icon still appears on hover, overlapping the dot.

**Click to comment**:
1. Clicking the comment icon opens the InlineCommentEditor (same component as the raw view) positioned **below the rendered element** it is anchored to.
2. Alternative: `Cmd/Ctrl + click` on the element itself also opens the comment editor.
3. The editor spans the full width of the rendered content area (within the max-width cap). It uses the same styling as the existing InlineCommentEditor (white background, blue border, text area, Comment/Cancel buttons).
4. The line label in the editor shows the element type instead of a line number: "Heading", "Paragraph", "List item", "Code block", "Table", "Block quote", "Image".

**Comment bubbles**:
- Comments appear as CommentBubble components below the rendered element they are anchored to.
- The bubble styling is identical to the existing CommentBubble (background `#F0F9FF`, left border 3px solid `#3B82F6`, Edit/Delete on hover).
- The line label is replaced with an element label: "Heading: ## API Reference" (showing the element type and a truncated preview of its content, max 60 characters).
- Multiple comments on the same element are stacked vertically with 8px spacing.

#### Comment Interaction in Rendered Diff View (`FR-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-comment`)

Commenting in the rendered diff view follows the same hover-affordance pattern as the rendered file view. All rendered elements are commentable -- added, removed, modified, and unchanged.

The comment anchor identifier includes a change-type qualifier:
- Added elements: `added:heading-3`
- Removed elements: `removed:paragraph-5`
- Modified elements: `modified:list-1-item-2`
- Unchanged elements: `unchanged:paragraph-0`

The CommentBubble label includes the change type: "Added Heading: ## Rate Limiting", "Removed Paragraph: The old authentication...", "Modified Paragraph: This module provides...".

---

## Interaction Flows

### Flow 1: Switch to Rendered View (`AC-mdr-toggle-appears`, `FR-mdr-render-toggle`)

1. User has a markdown file loaded. The toolbar shows the render toggle with "Raw" active.
2. User clicks the "Rendered" segment (or presses `Tab` to focus it, then `Enter` / `Space`).
3. **If comments exist in raw mode** (`FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`): A confirmation dialog appears (see Flow 6: Mode Switch Confirmation). If cancelled, the toggle stays on "Raw" and flow ends. If confirmed, continue.
4. All raw-mode comments are cleared. The comment count resets to 0.
5. The "Rendered" segment becomes active (blue background). The "Raw" segment becomes inactive.
6. The code viewer panel transitions from the raw code display to the rendered markdown display. Transition: the raw content fades out (100ms), then the rendered content fades in (150ms).
7. The rendered markdown is parsed and displayed. For files under 5,000 lines, this is near-instant (< 200ms). For larger files, a brief spinner is shown during rendering.
8. The rendered content is scrollable. The comment affordance column appears on the left.
9. The preamble and sidebar remain unchanged.

### Flow 2: Switch Back to Raw View (`FR-mdr-render-toggle`)

1. User is in rendered view (Rendered + File or Rendered + Diff).
2. User clicks the "Raw" segment in the render toggle (or uses keyboard).
3. **If comments exist in rendered mode** (`FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`): A confirmation dialog appears (see Flow 6). If cancelled, flow ends.
4. All rendered-mode comments are cleared. The comment count resets to 0.
5. The "Raw" segment becomes active. The "Rendered" segment becomes inactive.
6. The code viewer panel transitions back to the raw code display (or raw diff, depending on File/Diff toggle state). Transition: rendered content fades out (100ms), raw content fades in (150ms).
7. The raw view displays as if it were freshly loaded -- same file content, but no comments.
8. The preamble is preserved across render mode switches.

### Flow 3: Add Comment in Rendered View (`AC-mdr-comment-rendered-element`, `AC-mdr-comment-heading`)

1. User is in rendered view (Rendered + File).
2. User hovers over a rendered block element (e.g., a paragraph). The element's background subtly changes to `#F8FAFC`. A comment icon appears in the C column at the element's vertical center.
3. User clicks the comment icon (or `Cmd/Ctrl + click` on the element).
4. The InlineCommentEditor opens below the rendered element, pushing subsequent elements down.
5. The editor label shows the element type: "Paragraph" (instead of "Line N").
6. User types their comment and clicks "Comment" or presses `Cmd+Enter` / `Ctrl+Enter`.
7. The editor closes. A CommentBubble appears below the element with the element label (e.g., "Paragraph: This module provides the core auth..."). A blue dot appears in the C column for that element.
8. The toolbar comment count increments by 1. The prompt preview updates automatically.

### Flow 4: View Rendered Diff (`FR-mdr-rendered-diff-display`)

1. User has a markdown file loaded via the server with both toggles visible.
2. User switches to Diff mode (File/Diff toggle). The raw diff loads per `../design/diff-view.md` Flow 1.
3. User then switches to Rendered mode (render toggle). Or alternatively, user switches to Rendered mode first, then to Diff mode -- the order does not matter.
4. **If comments exist**: Confirmation dialog per Flow 6.
5. Comments are cleared. The view transitions to the rendered diff:
   a. If the AST diff has not been computed yet, a loading spinner is shown ("Computing rendered diff...").
   b. The application parses both the HEAD and working copy markdown into ASTs, diffs the ASTs, and computes word-level diffs for modified blocks.
   c. The rendered diff appears with added/removed/modified/unchanged block annotations.
6. If the diff computation triggers the fallback heuristic (> 80% blocks changed), the fallback banner appears.
7. The user can hover over any rendered element and add comments.

### Flow 5: Add Comment on Rendered Diff Element (`AC-mdr-rendered-diff-comment`)

1. User is in rendered diff view (Rendered + Diff).
2. User hovers over a rendered element (added, removed, modified, or unchanged). The hover affordance appears.
3. User clicks the comment icon.
4. The InlineCommentEditor opens below the element. The label includes the change type: "Added Heading" or "Modified Paragraph".
5. User types a comment and submits.
6. The CommentBubble appears below the element with a change-type-aware label (e.g., "Modified Paragraph: This module provides...").
7. The prompt preview updates with the rendered diff prompt format (see Prompt Output Format section).

### Flow 6: Mode Switch Confirmation (`FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`, `AC-mdr-switch-no-comments`)

Triggered when the user attempts to switch the render toggle (Raw <-> Rendered) and comments exist in the current render mode.

1. A ConfirmationDialog appears with:
   - **Title**: "Switch view mode?"
   - **Body**: The body text adapts to the specific switch being performed:
     - Render toggle switch (Raw <-> Rendered): "Switching to [Raw/Rendered] view will clear all N comments. Comments cannot be transferred between view modes because they use different anchoring systems (line numbers vs. document elements)."
     - File/Diff toggle switch while in Rendered mode: "Switching to [File/Diff] mode will clear all N comments. Comments cannot be transferred because file and diff modes use different element identifiers."
   - **Cancel button**: "Cancel" (secondary, left).
   - **Confirm button**: "Switch and clear comments" (destructive/red, right).
2. If the user clicks "Switch and clear comments" or tabs to the confirm button and presses `Enter`, the mode switch proceeds and comments are cleared.
3. If the user clicks "Cancel" or presses `Escape`, the dialog closes and the render toggle reverts. No comments are cleared.

**No-comment case** (`AC-mdr-switch-no-comments`): If no comments exist in the current mode, switching is immediate with no confirmation dialog.

The dialog uses the same ConfirmationDialog component from `../design/code-review-prompt.md` with `confirmVariant: 'destructive'`.

### Flow 7: Toggle Combinations

The two toggles (File/Diff and Raw/Rendered) can be switched in any order. Each switch independently may trigger a confirmation dialog if comments exist. The resulting view is always the intersection of the two toggle states.

| Starting State | User Action | Transition |
|---|---|---|
| Raw + File | Clicks "Rendered" | Flow 1 (switch to rendered file view) |
| Raw + File | Clicks "Diff" | Diff view Flow 1 from `../design/diff-view.md` |
| Raw + Diff | Clicks "Rendered" | Confirmation if comments -> rendered diff (Flow 4) |
| Raw + Diff | Clicks "File" | Diff view Flow 2 from `../design/diff-view.md` |
| Rendered + File | Clicks "Raw" | Flow 2 (switch to raw file view) |
| Rendered + File | Clicks "Diff" | Confirmation if comments -> rendered diff (Flow 4) |
| Rendered + Diff | Clicks "Raw" | Confirmation if comments -> raw diff |
| Rendered + Diff | Clicks "File" | Confirmation if comments -> rendered file view |

**Key rule**: Any toggle switch that changes the commenting anchor model (line-based vs. element-based, or file-element vs. diff-element) clears comments with confirmation. Switching File/Diff while in Rendered mode clears because element identifiers differ between file and diff modes (diff mode adds change-type qualifiers). Switching Raw/Rendered always clears because the anchoring model changes.

### Flow 8: Navigate Comments in Rendered View

Comment navigation (`[` / `]` keys, or the previous/next buttons in the toolbar) works in rendered view. Comments are ordered by their element's position in the AST (document order). When navigating to a comment:

1. The rendered view scrolls to center the target comment's element in the viewport.
2. The target CommentBubble receives the focused style (blue left border, `#DBEAFE` background).
3. The element associated with the comment receives a subtle highlight (background `#DBEAFE` with 150ms transition).
4. The toolbar shows "Comment N of M".
5. Wrapping behavior is identical to file mode: "Next" on the last comment wraps to the first; "Previous" on the first wraps to the last.

This flow applies identically to both rendered file view and rendered diff view. In rendered diff view, comments are ordered by their position in the diff result (document order of the merged diff output).

### Flow 9: Keyboard Comment in Rendered View (`AC-mdr-keyboard-comment`, `NFR-mdr-accessibility`)

1. User presses `Tab` to move focus into the rendered content area.
2. User presses `Tab` to cycle through commentable block elements. Each element receives a visible focus ring (2px `#2563EB` outline, 2px offset) when focused.
3. The focused element's comment icon appears in the C column (same as hover, but persistent while focused).
4. User presses `Enter` or `c` on the focused element to open the InlineCommentEditor.
5. User types their comment in the auto-focused text area.
6. User presses `Cmd+Enter` / `Ctrl+Enter` to submit, or `Escape` to cancel.
7. Focus returns to the rendered element after submission or cancellation.

---

## Component Specs

### RenderToggle

A segmented control for switching between Raw and Rendered view modes for markdown files. Implements `FR-mdr-render-toggle`, `FR-mdr-detect-markdown`.

- **Variants**: None (single component with internal state per segment).

- **Props/Inputs**:
  - `activeMode: 'raw' | 'rendered'` -- The currently active render mode.
  - `isVisible: boolean` -- Whether the toggle should render (true only for markdown files).
  - `onModeChange: (mode: 'raw' | 'rendered') => void` -- Callback when the user selects a mode.

- **Visual Structure**:
  ```
  +-------+-----------+
  |  Raw  | Rendered  |
  +-------+-----------+
  ```
  - Two segments in a horizontal group.
  - Outer border-radius: 6px. Inner edges are flat (shared border).
  - "Raw" segment: 48px wide, 32px tall.
  - "Rendered" segment: 80px wide, 32px tall.
  - 1px border around the entire group.

- **Behavior**:
  - Clicking an inactive segment fires `onModeChange`.
  - Clicking the active segment does nothing.
  - The parent component handles confirmation dialogs before actually changing the mode.
  - When `isVisible` is false, the component renders nothing (returns null). It does not render a hidden or disabled element.

- **Keyboard Accessibility** (`NFR-mdr-accessibility`):
  - The toggle is focusable as a group (`role="tablist"`, each segment is `role="tab"`).
  - `ArrowLeft` / `ArrowRight` moves focus between segments.
  - `Enter` or `Space` activates the focused segment.
  - `aria-selected="true"` on the active segment.
  - `aria-label="Render mode"` on the tablist.
  - Each tab has `aria-controls="code-viewer-panel"`.

---

### RenderedViewer

The rendered markdown display component. Replaces the CodeViewer in the code viewer panel when rendered + file mode is active. Implements `FR-mdr-render-commonmark`, `FR-mdr-render-styling`, `FR-mdr-element-id`, `FR-mdr-rendered-comment-create`.

- **Variants**: None (single variant with dynamic rendering based on content and comments).

- **Props/Inputs**:
  - `markdownSource: string` -- The raw markdown source text.
  - `language: string` -- Always "Markdown" but passed for consistency.
  - `comments: RenderedComment[]` -- Array of comment objects with `{ id, elementId, text }`.
  - `focusedCommentId: string | null` -- The comment currently focused via navigation.
  - `onElementClick: (elementId: string) => void` -- Callback when the user clicks a comment affordance.
  - `onCommentEdit: (commentId: string) => void`
  - `onCommentDelete: (commentId: string) => void`

- **Visual Structure**: See the Rendered View Layout section above.

- **Internal Processing**:
  1. Parse markdown source into AST (CommonMark + GFM).
  2. Assign stable element identifiers to each block-level node (`FR-mdr-element-id`). Identifiers encode the AST path: `heading-0`, `paragraph-1`, `list-2-item-0`, `code-block-5`, `table-3`, `blockquote-4`, etc.
  3. Render AST to sanitized HTML.
  4. Apply syntax highlighting to fenced code blocks.
  5. Insert into DOM with comment affordance hooks on each block element.

- **Performance** (`NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`):
  - Rendering is a single-pass operation (parse + render + sanitize + highlight).
  - No virtualized scrolling. For files > 5,000 lines, uses `content-visibility: auto` on top-level elements.
  - Must complete within 200ms for files <= 5,000 lines, 500ms for files <= 10,000 lines.

- **Keyboard Accessibility** (`NFR-mdr-accessibility`, `AC-mdr-keyboard-comment`):
  - The rendered content area is a focusable region (`tabindex="0"`, `role="document"`, `aria-label="Rendered markdown content"`).
  - Each commentable block element has `tabindex="0"` and `role="article"` with `aria-label` describing its content (e.g., `aria-label="Heading level 2: API Reference"`).
  - `Tab` cycles through commentable elements in document order.
  - `Enter` or `c` on a focused element opens the comment editor.
  - `Escape` within the rendered content (not in an editor) returns focus to the rendered content region.
  - Screen reader: Each element is announced by type and content. Elements with comments append "has N comments".

---

### RenderedDiffViewer

The rendered markdown diff display component. Replaces the CodeViewer in the code viewer panel when rendered + diff mode is active. Implements `FR-mdr-rendered-diff-display`, `FR-mdr-rendered-diff-comment`.

- **Variants**: None.

- **Props/Inputs**:
  - `oldMarkdownSource: string` -- The HEAD version markdown source.
  - `newMarkdownSource: string` -- The working copy markdown source.
  - `language: string` -- Always "Markdown".
  - `comments: RenderedDiffComment[]` -- Array of comment objects with `{ id, elementId, changeType, text }`.
  - `focusedCommentId: string | null`
  - `onElementClick: (elementId: string) => void`
  - `onCommentEdit: (commentId: string) => void`
  - `onCommentDelete: (commentId: string) => void`
  - `onFallbackToRawDiff: () => void` -- Callback when user clicks "Switch to Raw Diff" in the fallback banner.

- **Visual Structure**: See the Rendered Diff Layout section above.

- **Internal Processing**:
  1. Parse both old and new markdown into ASTs.
  2. Diff the ASTs at the block level: identify added, removed, modified, and unchanged blocks.
  3. For modified blocks, compute word-level text diffs.
  4. Render the merged result as HTML with diff annotations.
  5. Sanitize the output.
  6. Assign element identifiers with change-type qualifiers.
  7. If > 80% of blocks are changed, show the fallback banner.

- **Loading State**: While computing the AST diff, display a centered spinner with "Computing rendered diff..." text. Spinner: 24px circular, color `#2563EB`, 1s rotation. Text: 13px, color `#94A3B8`, 8px below spinner.

- **Performance** (`NFR-mdr-rendered-diff-perf`):
  - Diff computation must complete within 1s (< 5,000 lines) or 3s (5,000-10,000 lines).
  - 5-second hard timeout: if exceeded, auto-switch to Raw + Diff with info toast.

- **Keyboard Accessibility** (`NFR-mdr-accessibility`):
  - Same as RenderedViewer: `role="document"`, block elements focusable, `Tab` to cycle, `Enter` or `c` to comment.
  - Diff annotations are announced to screen readers via `aria-label`: "Added heading level 2: Rate Limiting", "Removed paragraph: The old authentication system...", "Modified paragraph: This module provides the core [changed: authentication to auth] API...".

---

### ElementCommentAnchor

The hover affordance for commenting on a rendered element. Appears in the comment affordance column (C column) of the RenderedViewer and RenderedDiffViewer.

- **Variants**:
  - `hidden` -- Default state. Nothing visible.
  - `hover` -- Element is hovered or focused. Comment icon visible.
  - `has-comments` -- Element has existing comments. Blue dot visible; comment icon on hover.

- **Props/Inputs**:
  - `elementId: string` -- The stable element identifier.
  - `hasComments: boolean` -- Whether the element has attached comments.
  - `commentCount: number` -- Number of comments on this element.
  - `isHovered: boolean` -- Whether the parent element is hovered.
  - `isFocused: boolean` -- Whether the parent element has keyboard focus.
  - `onClick: () => void` -- Callback to initiate comment creation.

- **Visual Structure**:
  ```
  Hidden:        [   ] (32px wide, empty)
  Hover:         [ 💬 ] (comment icon, 16px, centered)
  Has-comments:  [ ● ] (blue dot, 8px, centered)
  Hover+has:     [ 💬 ] (comment icon overlays the dot)
  ```
  - Column width: 32px. Background: transparent.
  - Comment icon: speech bubble outline, 16px. Color: `#94A3B8` (muted). Hover color: `#2563EB` (primary blue). Cursor: pointer.
  - Blue dot (has-comments): 8px diameter filled circle, color `#3B82F6`. Centered vertically at the top of the associated element.
  - The icon/dot are vertically centered relative to the first line of the associated block element.

- **Behavior**:
  - Clicking the icon fires `onClick`, which initiates comment creation for the associated element.
  - The icon appears on hover (or focus) of the associated rendered element, not just the C column itself.
  - Fade in: 100ms. Fade out: 100ms (after pointer leaves both the element and the C column row).
  - Tooltip on icon hover: "Add comment" (background `#1E293B`, text `#FFFFFF`, font 12px, padding 6px 10px, border-radius 4px, 300ms delay).

- **Keyboard Accessibility**:
  - The icon is focusable (`tabindex="0"`) when the parent element is focused.
  - When the parent element receives keyboard focus, the icon becomes visible and focusable.
  - `Enter` or `Space` on the focused icon fires `onClick`.
  - `aria-label="Add comment on [element type]: [element text preview]"`.

---

### Reused Components

The following existing components are reused with adaptations:

**InlineCommentEditor** (from `../design/code-review-prompt.md`):
- Reused as-is for creating and editing comments in rendered views.
- Positioning: placed below the rendered element (instead of below a code line).
- The `lineLabel` prop is repurposed: instead of "Line N" or "Lines N-M", it shows the element type label (e.g., "Heading", "Paragraph", "Modified Paragraph").
- All other behavior (auto-focus, Cmd+Enter submit, Escape cancel, create/edit variants) is identical.

**CommentBubble** (from `../design/code-review-prompt.md`):
- Reused for displaying comments below rendered elements.
- The line label is replaced: instead of "Line N" or "Lines N-M", shows "Heading: ## API Reference" (element type + content preview, max 60 characters with ellipsis).
- In rendered diff view, the label includes the change type: "Added Heading: ## Rate Limiting".
- Focused variant works identically (blue left border, `#DBEAFE` background).
- Edit/Delete buttons work identically.

**ConfirmationDialog** (from `../design/code-review-prompt.md`):
- Reused for mode switch confirmation (Flow 6).
- Same destructive variant styling. Same keyboard behavior (focus trapped, Escape cancels, auto-focus on Cancel).

---

## Prompt Output Format -- Rendered View

When generating a prompt from the rendered file view, comments reference the raw markdown source lines rather than the HTML. Implements `FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`.

```
## Instructions

[Preamble text, if provided. Omitted if no preamble.]

## File: [filename] ([language]) -- Rendered View

```markdown
  1 | # API Reference
  2 |
  3 | This module provides the core authentication API for
  4 | managing user sessions and credentials.
  5 |
  ...
```

## Requested Changes

- **Heading (lines 1-1)**:
  ```markdown
  # API Reference
  ```
  Comment: "This heading should be level 3, not level 1."

- **Paragraph (lines 3-4)**:
  ```markdown
  This module provides the core authentication API for
  managing user sessions and credentials.
  ```
  Comment: "Rewrite this to mention the new OAuth2 support."

- **Code block (lines 12-18)**:
  ```markdown
  ```typescript
  interface LoginRequest {
    email: string;
    password: string;
  }
  ```
  ```
  Comment: "Add a 'rememberMe' boolean field."
```

**Rules**:
- The file heading includes "-- Rendered View" to distinguish from raw-mode and diff-mode prompts.
- The full raw markdown source is included with line numbers (identical to file-mode prompts), because the AI agent needs the source to make changes.
- Each comment references the element type and the raw source line range that produces the rendered element.
- The raw source for the commented element is included in a markdown code fence below the element type/line reference.
- The comment text follows the source excerpt.
- Comments are listed in document order (ascending by element position in the AST).
- If no preamble is provided, the "Instructions" section is omitted.
- If the file name is unknown, use "Untitled". If the language is unknown, use "Plain Text". Same rules as file mode.

---

## Prompt Output Format -- Rendered Diff View

When generating a prompt from the rendered diff view, comments include both old and new source. Implements `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`.

```
## Instructions

[Preamble text, if provided. Omitted if no preamble.]

## File: [filename] ([language]) -- Rendered Diff View

The following shows changes between the git HEAD version and the current working copy,
annotated at the document element level.

## Annotated Elements

### Modified Paragraph (lines 3-4 -> lines 3-4):
Old:
```markdown
This module provides the core authentication API for
managing user sessions and credentials.
```
New:
```markdown
This module provides the core auth API for
managing user sessions and tokens.
```
Comment: "I prefer the full word 'authentication' over the abbreviation 'auth'."

### Added Heading (new lines 8-8):
```markdown
## Rate Limiting
```
Comment: "Good addition. Add a note about the rate limit reset window."

### Removed Paragraph (old lines 15-16):
```markdown
The old authentication system is deprecated.
Please migrate to the new OAuth2 endpoints.
```
Comment: "We should keep a deprecation notice somewhere even if this section is removed."
```

**Rules**:
- The file heading includes "-- Rendered Diff View".
- The preamble about change notation is included (fixed string).
- Comments are grouped under "Annotated Elements" (instead of "Requested Changes") to reflect the element-level anchoring. This section includes comments on any element — changed or unchanged.
- Each entry labels the change type and element type: "Modified Paragraph", "Added Heading", "Removed Paragraph", "Unchanged Code block".
- Modified elements show both "Old:" and "New:" source in separate code fences.
- Added elements show only the new source. Removed elements show only the old source.
- Line references show old and/or new line numbers as appropriate: "lines 3-4 -> lines 3-4" for modified, "new lines 8-8" for added, "old lines 15-16" for removed.
- Comments are listed in document order.
- Same fallback rules for missing preamble, unknown file name, unknown language.

---

## Responsive Behavior

The rendered view follows the same responsive rules as the existing CRPG design (see `../design/code-review-prompt.md`, Responsive Behavior section).

### Breakpoints

| Breakpoint | Rendered-View-Specific Behavior |
|---|---|
| **>= 1280px** | Full rendered view layout as described. Content max-width: 80ch, centered. C column: 32px. Sidebar: 360px. Both toggles visible. |
| **1024px - 1279px** | Sidebar narrows to 300px. The rendered content max-width remains 80ch but may be constrained by the narrower panel. The render toggle remains visible. Font sizes unchanged. |
| **< 1024px** | Same overlay message as existing design. The rendered view is not usable below 1024px. |

### Horizontal Overflow

The rendered view has a max-width cap of 80ch, so horizontal overflow is rare. When it occurs (e.g., a wide table or long code block), horizontal scrolling is enabled within the rendered content area. The C (comment affordance) column remains sticky (`position: sticky; left: 0`).

---

## Accessibility

### Keyboard Navigation (`NFR-mdr-accessibility`, `AC-mdr-keyboard-comment`)

All rendered view interactions are achievable via keyboard:

| Workflow | Keyboard Path |
|---|---|
| **Switch to rendered view** | `Tab` to render toggle, `ArrowRight` to "Rendered" segment, `Enter` |
| **Switch to raw view** | `Tab` to render toggle, `ArrowLeft` to "Raw" segment, `Enter` |
| **Navigate rendered elements** | `Tab` into rendered content, then `Tab` to cycle through commentable elements |
| **Add comment on element** | Focus element, `Enter` or `c`, type comment, `Cmd+Enter` |
| **Navigate comments** | `[` for previous, `]` for next (same as file mode) |
| **View rendered diff** | Switch File/Diff toggle to "Diff" and render toggle to "Rendered" (either order) |
| **Add comment on diff element** | Same as rendered file view: focus element, `Enter` or `c` |
| **Copy prompt** | `Cmd+Shift+C` / `Ctrl+Shift+C` (same as all modes) |
| **Dismiss fallback banner** | `Tab` to banner close button, `Enter` |

### Focus Management

- When switching to rendered mode, focus moves to the first commentable element in the rendered content after rendering completes.
- When switching to raw mode, focus moves to the first line in the code viewer.
- When the InlineCommentEditor opens in rendered view, focus moves to the text area.
- When the InlineCommentEditor closes, focus returns to the rendered element that was commented on.
- When the rendered diff loading spinner is shown, focus remains on the render toggle. After loading completes, focus moves to the first rendered element.
- When the fallback banner is shown, focus moves to the banner (specifically the "Switch to Raw Diff" link).
- All ConfirmationDialog focus management rules from existing design apply.

### ARIA Attributes

| Element | ARIA |
|---|---|
| Render toggle group | `role="tablist"`, `aria-label="Render mode"` |
| "Raw" segment | `role="tab"`, `aria-selected="true/false"`, `aria-controls="code-viewer-panel"` |
| "Rendered" segment | `role="tab"`, `aria-selected="true/false"`, `aria-controls="code-viewer-panel"` |
| Rendered content area | `role="document"`, `aria-label="Rendered markdown content"` |
| Rendered diff content area | `role="document"`, `aria-label="Rendered markdown diff"` |
| Commentable block element | `role="article"`, `aria-label="[Element type]: [content preview]"`, `tabindex="0"` |
| Added block (in diff) | `role="article"`, `aria-label="Added [element type]: [content preview]"` |
| Removed block (in diff) | `role="article"`, `aria-label="Removed [element type]: [content preview]"` |
| Modified block (in diff) | `role="article"`, `aria-label="Modified [element type]: [content preview]"` |
| Inline added words (in diff) | `<ins>` element with `aria-label="Added text: [word]"` |
| Inline removed words (in diff) | `<del>` element with `aria-label="Removed text: [word]"` |
| Comment affordance icon | `role="button"`, `aria-label="Add comment on [element type]: [content preview]"`, `tabindex="0"` |
| Comment bubble (rendered) | `role="note"`, `aria-label="Comment on [element type]: [comment text]"` |
| Comment bubble (rendered diff) | `role="note"`, `aria-label="Comment on [change type] [element type]: [comment text]"` |
| Fallback banner | `role="alert"`, `aria-label="Rendered diff fallback notice"` |
| Loading spinner | `role="status"`, `aria-label="Computing rendered diff"` |

### Color and Contrast

- **Added block background** (`#F0FDF4`) with body text `#1E293B` = 14.5:1 contrast (passes AAA).
- **Removed block background** (`#FEF2F2`) with strikethrough text `#6B7280` = 5.0:1 (passes AA).
- **Inline added word background** (`#BBF7D0`) with text `#1E293B` = 11.4:1 (passes AAA).
- **Inline removed word background** (`#FECACA`) with strikethrough text `#6B7280` = 4.0:1 (passes AA for normal text at 14px).
- **Fallback banner background** (`#FEF3C7`) with text `#92400E` = 5.8:1 (passes AA).
- **Comment affordance icon** (`#94A3B8`) on white background = 3.1:1 (passes for graphical objects, which require 3:1). Hover state (`#2563EB` on white) = 4.6:1 (passes AA).
- The rendered diff does not rely solely on color: added blocks have the "ADDED" label badge, removed blocks have the "REMOVED" label badge and strikethrough text, and inline diffs use `<ins>` / `<del>` elements announced by screen readers.
- Heading left-border accents use color + position (left border is a structural indicator, not just a color change).

---

## Color Palette -- Rendered View Additions

These colors extend the palettes from `../design/code-review-prompt.md` and `../design/diff-view.md`:

| Usage | Color | Hex |
|---|---|---|
| Rendered heading H1 left border | Primary blue | `#2563EB` |
| Rendered heading H2 left border | Blue | `#3B82F6` |
| Rendered heading H3 left border | Light blue | `#60A5FA` |
| Rendered heading H4-H6 left border | Lighter blue | `#93C5FD` |
| Rendered inline code background | Light slate | `#F1F5F9` |
| Rendered inline code text | Pink | `#BE185D` |
| Rendered code block background | Dark (same as prompt preview) | `#1E293B` |
| Rendered code block text | Light | `#E2E8F0` |
| Rendered blockquote border | Gray | `#CBD5E1` |
| Rendered blockquote background | Very light | `#F8FAFC` |
| Rendered table header background | Light slate | `#F1F5F9` |
| Rendered table alternating row | Very light | `#F8FAFC` |
| Rendered table border | Light gray | `#E2E8F0` |
| Rendered link color | Primary blue | `#2563EB` |
| Rendered diff added block background | Light green | `#F0FDF4` |
| Rendered diff added block border | Green | `#22C55E` |
| Rendered diff added block label bg | Green-100 | `#DCFCE7` |
| Rendered diff added block label text | Green-700 | `#15803D` |
| Rendered diff removed block background | Light red | `#FEF2F2` |
| Rendered diff removed block border | Red | `#EF4444` |
| Rendered diff removed block label bg | Red-100 | `#FEE2E2` |
| Rendered diff removed block label text | Red-700 | `#B91C1C` |
| Rendered diff removed text color | Gray | `#6B7280` |
| Rendered diff inline added word bg | Green-200 | `#BBF7D0` |
| Rendered diff inline removed word bg | Red-200 | `#FECACA` |
| Element hover background | Very light | `#F8FAFC` |
| Comment affordance icon (default) | Muted | `#94A3B8` |
| Comment affordance icon (hover) | Primary blue | `#2563EB` |
| Fallback banner background | Amber-100 | `#FEF3C7` |
| Fallback banner border | Amber-500 | `#F59E0B` |
| Fallback banner icon | Amber-600 | `#D97706` |
| Fallback banner text | Amber-800 | `#92400E` |

---

## Requirement Traceability

This section maps every markdown-render requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-mdr-detect-markdown` | RenderToggle component (visibility logic); Toolbar Modifications section (toggle hidden for non-markdown); Updated Toolbar States Table |
| `FR-mdr-render-toggle` | RenderToggle component; Toolbar Modifications section; Flow 1 (switch to rendered); Flow 2 (switch to raw); Flow 7 (toggle combinations) |
| `FR-mdr-render-commonmark` | RenderedViewer component (internal processing step 1); Content Styling table (all rendered element styles) |
| `FR-mdr-render-styling` | Content Styling table (typography, colors, spacing for all rendered elements); Rendered View Layout section |
| `FR-mdr-element-id` | RenderedViewer component (internal processing step 2); Comment Interaction section (element identifiers); ElementCommentAnchor component |
| `FR-mdr-rendered-comment-create` | Comment Interaction section; Flow 3 (add comment in rendered view); ElementCommentAnchor component; RenderedViewer component |
| `FR-mdr-rendered-comment-prompt` | Prompt Output Format -- Rendered View section; Flow 3 step 8 |
| `FR-mdr-switch-comments` | Flow 6 (mode switch confirmation); Flow 7 (toggle combinations); ConfirmationDialog reuse |
| `FR-mdr-raw-diff-unchanged` | Screen Inventory table (Raw + Diff: existing/unchanged); Updated Toolbar States Table |
| `FR-mdr-rendered-diff-display` | Rendered Diff Layout section; RenderedDiffViewer component; Flow 4 (view rendered diff); Diff annotation styles table; Word-level inline diff specification |
| `FR-mdr-rendered-diff-comment` | Comment Interaction in Rendered Diff View section; Flow 5 (add comment on rendered diff element); RenderedDiffViewer component |
| `FR-mdr-rendered-diff-prompt` | Prompt Output Format -- Rendered Diff View section |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-mdr-render-perf` | RenderedViewer Performance note (200ms/500ms targets, Web Worker fallback); Flow 1 step 7 |
| `NFR-mdr-render-scroll-perf` | RenderedViewer Performance note (content-visibility: auto for > 5,000 lines; no virtualization) |
| `NFR-mdr-rendered-diff-perf` | RenderedDiffViewer Performance note (1s/3s targets, 5s hard timeout); Loading state specification |
| `NFR-mdr-xss-safety` | HTML Sanitization paragraph in Rendered View Layout section; RenderedDiffViewer processing step 5 |
| `NFR-mdr-client-only` | Implicit -- no server calls in any rendered-view flow; all rendering and diffing is client-side |
| `NFR-mdr-accessibility` | Accessibility section (keyboard navigation table, focus management, ARIA attributes); RenderedViewer keyboard spec; RenderedDiffViewer keyboard spec; ElementCommentAnchor keyboard spec; Flow 8 |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-mdr-toggle-appears` | RenderToggle component; Toolbar Modifications section (default "Raw" selection); Flow 1 |
| `AC-mdr-toggle-hidden-non-md` | RenderToggle visibility logic (hidden for non-markdown, not rendered in DOM); Updated Toolbar States Table |
| `AC-mdr-render-basic` | Content Styling table (headings, paragraphs, bold, italic, links, lists); RenderedViewer component |
| `AC-mdr-render-gfm` | Content Styling table (tables, task lists, strikethrough); RenderedViewer internal processing (GFM parsing) |
| `AC-mdr-render-code-blocks` | Content Styling table (code blocks with syntax highlighting); RenderedViewer processing step 4 |
| `AC-mdr-raw-unchanged` | Screen Inventory table (Raw + File: existing unchanged); FR-mdr-raw-diff-unchanged coverage |
| `AC-mdr-comment-rendered-element` | Comment Interaction section (hover affordance, click to comment); Flow 3; ElementCommentAnchor component |
| `AC-mdr-comment-heading` | Comment Interaction section (headings are commentable elements); Flow 3 (element type label); Prompt Output Format -- Rendered View (heading line reference example) |
| `AC-mdr-comment-prompt-format` | Prompt Output Format -- Rendered View section (raw source lines included, not HTML) |
| `AC-mdr-switch-clears-comments` | Flow 6 (mode switch confirmation dialog); Flow 7 (toggle combinations table showing when confirmation triggers) |
| `AC-mdr-switch-no-comments` | Flow 6 (no-comment case: immediate switch, no dialog) |
| `AC-mdr-rendered-diff-additions` | Rendered Diff Layout section (added block style: green background, left border, ADDED badge) |
| `AC-mdr-rendered-diff-removals` | Rendered Diff Layout section (removed block style: red background, strikethrough, REMOVED badge) |
| `AC-mdr-rendered-diff-modifications` | Rendered Diff Layout section (word-level inline diff: green for added words, red+strikethrough for removed words) |
| `AC-mdr-rendered-diff-comment` | Comment Interaction in Rendered Diff View section; Flow 5; RenderedDiffViewer component |
| `AC-mdr-rendered-diff-prompt` | Prompt Output Format -- Rendered Diff View section (old/new source for modified elements) |
| `AC-mdr-html-sanitized` | HTML Sanitization paragraph (script tags stripped, event handlers stripped); RenderedViewer/RenderedDiffViewer processing |
| `AC-mdr-large-file-renders` | RenderedViewer Performance note (200ms for ≤5,000 lines per `NFR-mdr-render-perf`); content-visibility optimization |
| `AC-mdr-keyboard-comment` | Flow 8 (keyboard comment creation); Accessibility section (keyboard navigation table); ElementCommentAnchor keyboard spec |
| `AC-mdr-diff-fallback` | Fallback Banner specification (> 80% blocks changed threshold); RenderedDiffViewer fallback logic; Flow 4 step 6 |
