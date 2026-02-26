# Working Copy Diff View — Design Spec

> Based on requirements in `../../product/diff-view.md`

## Screen Inventory

This feature does not introduce new screens or routes. It modifies the existing single-page CRPG application by adding an alternative rendering mode within the code viewer panel. The application continues to have one primary view that transitions through states as described in `../design/code-review-prompt.md`.

The diff view feature adds or modifies the following view states:

| View State | Change Type | Description |
|---|---|---|
| **File Loaded State — File Mode** | Existing (renamed) | The existing file-loaded code viewer, now explicitly labeled "File" mode. No visual changes to this mode. |
| **File Loaded State — Diff Mode** | New | The code viewer panel renders a unified diff instead of the full file. Sidebar (preamble + prompt preview) remains unchanged. |
| **File Loaded State — Diff Mode — Empty Diff** | New | The code viewer panel shows an empty state when the working copy matches git HEAD. |
| **File Loaded State — Diff Mode — Loading Baseline** | New | A brief loading state while the git HEAD version is being fetched from the server. |

---

## Screen Definitions

### File Loaded Screen — Toolbar Modifications

The existing toolbar is extended with a view mode toggle and a refresh button. The toolbar layout changes from:

```
+---[Logo/Title]---[Comment Nav]---[Comment Count]------[Generate][Copy][Clear]---+
```

To:

```
+---[Logo/Title]---[File|Diff]---[Refresh]---[Comment Nav]---[Comment Count]------[Generate][Copy][Clear]---+
```

#### View Mode Toggle (`FR-diff-mode-toggle`, `FR-diff-mode-availability`, `AC-diff-toggle-to-diff`, `AC-diff-toggle-to-file`, `AC-diff-paste-upload-disabled`)

The toggle is a **segmented control** (two-segment button group) placed immediately after the application title, before the comment navigation controls. It contains two segments: "File" and "Diff".

- **Placement**: After the title, separated by a 16px gap. Before the refresh button (which is followed by a 16px gap, then comment nav).
- **Dimensions**: Each segment is 56px wide and 32px tall. Total control width: 112px.
- **Typography**: 13px, font-weight 500, system sans-serif.
- **Border**: 1px solid `#E2E8F0`, border-radius 6px on the outer corners of the group. The two segments share the inner edge (no double-border).

**Segment States**:

| State | Background | Text Color | Border |
|---|---|---|---|
| **Active (selected)** | `#2563EB` (primary blue) | `#FFFFFF` (white) | 1px solid `#2563EB` |
| **Inactive (not selected, enabled)** | `#FFFFFF` (white) | `#475569` (slate) | 1px solid `#E2E8F0` |
| **Inactive hover** | `#F8FAFC` (very light gray) | `#1E293B` (dark slate) | 1px solid `#E2E8F0` |
| **Disabled** | `#F1F5F9` (off-white) | `#94A3B8` (muted) | 1px solid `#E2E8F0` |
| **Focused** | Same as inactive/active + 2px blue focus ring (`#2563EB`, offset 2px) | Same | Same |

**Disabled State** (`AC-diff-paste-upload-disabled`): When the file was loaded via paste, upload, or drag-and-drop (not via the file-serving API), the "Diff" segment is disabled. The "File" segment remains active and selected. The disabled "Diff" segment has `cursor: not-allowed` and displays a tooltip on hover:

- Tooltip text: "Diff view requires a file loaded via the /shepherd command"
- Tooltip appears below the toggle, centered on the "Diff" segment
- Tooltip style: background `#1E293B`, text `#FFFFFF`, font 12px, padding 6px 10px, border-radius 4px, max-width 240px, box-shadow `0 2px 8px rgba(0,0,0,0.15)`
- Tooltip appears after a 300ms hover delay and disappears immediately on mouse-out

**Visibility**: The toggle is visible whenever a file is loaded (`hasFile === true`). In the empty state (no file loaded), the toggle is hidden (not rendered) to keep the empty-state toolbar clean.

**Default Selection**: When a file is loaded via the file-serving API, "File" is selected by default. The user must explicitly switch to "Diff". When a file is loaded via paste/upload/drag-and-drop, "File" is selected and "Diff" is disabled.

#### Refresh Button (`FR-diff-refresh`, `AC-diff-refresh-updates`)

A refresh button appears immediately after the view mode toggle, separated by an 8px gap.

- **Icon**: A circular arrow (refresh/reload icon), 16px, stroke style.
- **Dimensions**: 32px x 32px square button.
- **Visibility**: Only visible when diff mode is active. Hidden when file mode is active.
- **Tooltip**: "Refresh diff (re-fetch file and recompute)" on hover.

**States**:

| State | Appearance |
|---|---|
| **Default** | Icon color: `#475569`. Background: transparent. |
| **Hover** | Icon color: `#1E293B`. Background: `#F8FAFC`. Border-radius: 6px. |
| **Active (pressed)** | Icon color: `#1E293B`. Background: `#E2E8F0`. |
| **Disabled (during fetch)** | Icon color: `#94A3B8`. Cursor: `not-allowed`. The icon rotates with a spin animation (360deg, 1s linear infinite) while the baseline is being fetched. |
| **Focused** | Same as default + 2px blue focus ring. |

**Behavior**: Clicking refresh re-fetches the working copy and HEAD version from the server, then recomputes the diff. If comments exist, a confirmation dialog is shown first (see Flow 5: Refresh Diff).

#### Updated Toolbar States Table

Extends the existing toolbar states table from `../design/code-review-prompt.md`:

| Application State | View Toggle | Refresh | Generate | Copy | Clear | Navigation |
|---|---|---|---|---|---|---|
| Empty (no file) | Hidden | Hidden | Disabled | Disabled | Disabled | Disabled |
| File loaded (paste/upload), File mode | File active, Diff disabled | Hidden | Depends on comments | Depends on prompt | Enabled | Depends on comments |
| File loaded (server), File mode | File active, Diff enabled | Hidden | Depends on comments | Depends on prompt | Enabled | Depends on comments |
| File loaded (server), Diff mode, loading | File enabled, Diff active | Visible, disabled (spinning) | Disabled | Disabled | Enabled | Disabled |
| File loaded (server), Diff mode, populated | File enabled, Diff active | Visible, enabled | Depends on comments | Depends on prompt | Enabled | Depends on comments |
| File loaded (server), Diff mode, empty diff | File enabled, Diff active | Visible, enabled | Disabled | Disabled | Enabled | Disabled |

---

### File Loaded Screen — Diff Mode: Code Viewer Panel

When diff mode is active, the code viewer panel replaces its content with the diff viewer. The panel dimensions, position, and relationship to the sidebar remain identical to file mode. The FileHeader bar at the top of the code viewer panel also remains, continuing to show the file name and language.

#### Diff Mode Loading State (`FR-diff-baseline-fetch`)

When the user switches to diff mode or triggers a refresh, the application fetches the git HEAD version of the file. During this fetch:

- The code viewer panel area shows a centered spinner with the text "Loading baseline..." below it.
- Spinner: a 24px circular spinner using the primary blue color (`#2563EB`), with a 1s rotation animation.
- Text: 13px, color `#94A3B8`, 8px below the spinner.
- The toolbar refresh button shows its spinning state.
- This loading state should be brief (target: under 500ms per `NFR-diff-baseline-fetch-speed`).

If the HEAD fetch fails because the file has no git history (untracked file, HTTP 404 from the HEAD endpoint):

- The application treats the baseline as an empty file (zero lines).
- The diff is computed as all lines being additions.
- No error is shown to the user; this is a valid state per `AC-diff-no-git-history`.

If the HEAD fetch fails for a non-404 reason (network error, server error):

- An error banner appears at the top of the code viewer panel: "Failed to fetch the baseline version. Check that the file is in a git repository." with a "Retry" link.
- Error banner style: background `#FEF2F2`, text `#991B1B`, border 1px solid `#FECACA`, padding 12px 16px, border-radius 4px. "Retry" is a text link in `#991B1B`, underlined.
- The user can click "Retry" to re-attempt the fetch, or switch back to file mode.

#### Diff Viewer Layout (`FR-diff-display`, `AC-diff-line-numbers`, `AC-diff-syntax-highlight`)

The diff viewer replaces the standard CodeViewer content within the code viewer panel. It uses a similar structure but with an expanded gutter area to accommodate diff-specific columns.

```
+-----+------+------+---+---+-------------------------------------------------+
| CmG | OldLN| NewLN| T | G | Code Content                                     |
+-----+------+------+---+---+-------------------------------------------------+
|     |   1  |   1  |   | . | import React from 'react';                       |
|     |   2  |   2  |   | . | import { useState } from 'react';                |
|     |   3  |   3  |   | . | const App = () => {                              |
|     |   4  |      | - | . |   const [count, setCount] = useState(0);         |  <- red bg
|     |      |   4  | + | . |   const [count, setCount] = useState<number>(0); |  <- green bg
|     |   5  |   5  |   | . |   return <div>{count}</div>;                     |
|     |   6  |   6  |   | . | };                                               |
+-----+------+------+---+---+-------------------------------------------------+
```

**Column layout** (left to right):

1. **CmG (Comment Gutter)**: 28px wide. Identical to the existing comment gutter. Shows blue dot indicators for lines with comments. Shows faint "+" icon on hover for lines without comments. This is the clickable area to initiate comment creation.

2. **OldLN (Old Line Number)**: 44px wide. Right-aligned. Monospace font, 13px, color `#94A3B8`. Shows the line number in the old (HEAD) version. For added lines (`+`), this cell is empty. For removed lines (`-`) and context lines (` `), this shows the old line number. Right-padded with 4px before the next column.

3. **NewLN (New Line Number)**: 44px wide. Right-aligned. Monospace font, 13px, color `#94A3B8`. Shows the line number in the new (working copy) version. For removed lines (`-`), this cell is empty. For added lines (`+`) and context lines (` `), this shows the new line number. Right-padded with 4px before the next column.

4. **T (Type Indicator)**: 20px wide. Center-aligned. Monospace font, 13px, font-weight 600. Shows the line type character:
   - Added lines: `+` in color `#15803D` (green-700)
   - Removed lines: `-` in color `#B91C1C` (red-700)
   - Context lines: blank (space character)

5. **G (Gutter spacer)**: 4px wide. Empty. Provides visual separation between the type indicator and code.

6. **Code Content**: Remaining width. Same monospace font and rendering as the existing CodeViewer. Syntax highlighted per `FR-crp-syntax-highlight` and `AC-diff-syntax-highlight`. Horizontal scrolling if lines exceed panel width. The gutter columns (CmG through G) remain sticky during horizontal scroll, consistent with the existing design.

**Total gutter width**: 28 + 44 + 44 + 20 + 4 = 140px (compared to 76px in file mode: 28px comment gutter + 48px line number).

#### Line Background Colors

Each line in the diff viewer has a background color based on its type:

| Line Type | Background Color | Hex | Description |
|---|---|---|---|
| Added (`+`) | Light green | `#F0FDF4` | green-50 from Tailwind |
| Removed (`-`) | Light red | `#FEF2F2` | red-50 from Tailwind |
| Context (` `) | White | `#FFFFFF` | Same as file mode |
| Hovered (any type) | Overlay | Original color with `#F8FAFC` 50% blend | Subtle hover darkening on any line type |
| Selected range (any type) | Blue overlay | `#DBEAFE` at 60% opacity over the line-type color | Range selection for multi-line comments |
| Focused comment line | Yellow overlay | `#FEF9C3` at 50% opacity over the line-type color | When navigating to a comment |
| Keyboard-focused | Focus ring | 2px `#2563EB` outline on the line, plus original bg | Keyboard navigation indicator |

**Color composition for overlapping states**: When a line is both an added line and part of a selected range, the green background (`#F0FDF4`) shows through with the blue selection overlay at 60% opacity on top. The exact resulting color is computed by the browser via `background: linear-gradient(rgba(219,234,254,0.6), rgba(219,234,254,0.6)), #F0FDF4`.

#### Collapsed Sections (`FR-diff-collapse`, `AC-diff-collapse-default`)

Blocks of unchanged context lines that exceed the visible context window are collapsed into a single separator row. The default context size is 3 lines above and below each change hunk.

**Collapse rules**:
- Between two adjacent change hunks, if the gap of unchanged lines is greater than 6 (2 x 3 context lines), the middle portion is collapsed.
- If the gap between hunks is 7 or fewer unchanged lines (2 x 3 + 1), all lines are shown without collapsing.
- At the top of the file, unchanged lines before the first change hunk are collapsed after showing 0 lines above (no leading context before the first hunk, but 3 lines of trailing context from the file start if the first change is more than 3 lines in).
- At the bottom of the file, unchanged lines after the last change hunk are collapsed after showing 3 lines of trailing context.

**Collapsed section separator visual**:

```
+-----+------+------+---+---+-------------------------------------------------+
|                                                                               |
|     |      |      |   |   | ... 47 unchanged lines ...              [Expand] |
|                                                                               |
+-----+------+------+---+---+-------------------------------------------------+
```

- **Height**: 36px.
- **Background**: `#F8FAFC` (very light gray). Distinct from both the white context line background and the green/red change backgrounds.
- **Border**: 1px dashed `#CBD5E1` on top and bottom edges.
- **Text**: "... N unchanged lines ..." centered in the code content area. Font: 12px, system sans-serif, font-weight 500, color `#64748B` (slate-500). The ellipsis characters are literal `...` — three dots on each side.
- **Expand control**: A text link "Expand" right-aligned in the code content area, 16px from the right edge of the visible panel (not the scrollable area). Font: 12px, font-weight 500, color `#2563EB`. Underline on hover.
- **Gutter columns**: The CmG, OldLN, NewLN, T, and G columns are all empty/blank for the separator row. The separator spans the full width visually.
- **Cursor**: `pointer` on the entire separator row (clicking anywhere on it expands).
- **Hover state**: Background changes to `#EFF6FF` (blue-50). Border changes to 1px dashed `#93C5FD` (blue-300). The "Expand" text becomes underlined.
- **Focus state** (keyboard): 2px `#2563EB` focus ring around the separator row. The separator is focusable (`tabindex="0"`, `role="button"`).

**Screen reader**: `aria-label="Expand 47 unchanged lines"`. `role="button"`.

#### Expanded Sections (`FR-diff-expand`, `AC-diff-expand-section`, `AC-diff-expand-then-comment`)

When the user clicks a collapsed section separator (or presses `Enter` / `Space` on a focused separator):

1. The separator row is replaced by all the hidden context lines.
2. The newly revealed lines are rendered identically to other context lines (white background, both old and new line numbers, blank type indicator).
3. The expansion is animated: the separator fades out (100ms) and the lines appear with a height expansion animation (150ms ease-out) from 0 to their natural height.
4. Once expanded, the section cannot be re-collapsed. There is no collapse control. This matches GitHub's behavior.
5. The user can add comments on any newly revealed line (`AC-diff-expand-then-comment`). The comment gutter "+" icon appears on hover, identical to other context lines.
6. Focus moves to the first newly revealed line after expansion (for keyboard users).

#### Comments on Diff Lines (`FR-diff-comment-create`, `FR-diff-comment-on-range`, `AC-diff-comment-added-line`, `AC-diff-comment-removed-line`, `AC-diff-comment-context-line`, `AC-diff-comment-range`)

Comments in diff mode work identically to file mode in terms of interaction (click gutter to create, inline editor appears below the line, edit/delete on bubble hover). The following adaptations are made for the diff context:

**Comment gutter behavior**: The 28px comment gutter (CmG column) behaves identically to the existing file-mode gutter. Blue dot for lines with comments; faint "+" on hover for lines without.

**Inline comment editor placement**: The InlineCommentEditor appears below the target line (or below the last line of a range selection), spanning from the CmG column to the right edge of the code content area. It occupies the same width as in file mode. The expanded gutter (OldLN, NewLN, T, G columns) on the editor's row is empty/blank.

**Comment bubble placement**: CommentBubble components appear below their target line(s), spanning the same width as the InlineCommentEditor. The line label in the CommentBubble adapts to the diff context:

- For a single added line: "Line +N" (where N is the new line number)
- For a single removed line: "Line -N" (where N is the old line number)
- For a single context line: "Line N" (using the new line number)
- For a range: "Lines +4 to +7" (if all added), "Lines -10 to -12" (if all removed), or "Lines -10 to +7" (if the range spans different types, using the old/new number appropriate to each endpoint's type). For a range of context lines: "Lines 5-8" (using new line numbers).

**Range selection across line types** (`AC-diff-comment-range`): The user can select a range spanning different line types (e.g., a removed line, followed by two added lines). The selection highlight uses the blue overlay (`#DBEAFE` at 60% opacity) over each line's type-specific background color. The range cannot span across a collapsed section separator. If the user attempts to extend a selection past a separator (via Shift+click or Shift+Arrow), the selection stops at the last visible line before the separator.

**Comment data model**: Each comment in diff mode stores a diff-specific identifier rather than an absolute line number. The identifier encodes:
- `lineType`: `"added"` | `"removed"` | `"context"`
- `oldLineNumber`: number | null (null for added lines)
- `newLineNumber`: number | null (null for removed lines)

For range comments, both the start and end are encoded this way.

#### Empty Diff State (`FR-diff-empty-state`, `AC-diff-no-changes`)

When the working copy is identical to the git HEAD version, the code viewer panel displays an empty state instead of the diff viewer.

```
+----------------------------------------------+
|                                               |
|          [document icon with = sign]          |
|                                               |
|       No changes detected                     |
|                                               |
|  The working copy matches the git HEAD        |
|  version. Switch to File view to see and      |
|  comment on the full file.                    |
|                                               |
|       [Switch to File view]                   |
|                                               |
+----------------------------------------------+
```

- **Icon**: A document icon with an equals sign (indicating identical), 48px, color `#94A3B8`.
- **Title**: "No changes detected" in 16px, font-weight 600, color `#1E293B`. Centered. 12px below icon.
- **Description**: Two lines of text, 13px, color `#64748B`, centered. 8px below title. Line height: 20px.
- **Button**: "Switch to File view" as a secondary button (border `#E2E8F0`, text `#475569`, hover background `#F8FAFC`). 16px below description. Clicking this switches the view mode toggle to "File".
- **Centered**: The entire content block is vertically and horizontally centered within the code viewer panel.

#### Untracked File State (`AC-diff-no-git-history`)

When the HEAD endpoint returns 404 (file has no git history), the diff is computed with an empty baseline. The diff viewer renders normally with every line shown as an added line (`+` indicator, green background, only new line numbers shown). No special UI treatment is needed beyond the standard diff rendering. The collapsed section logic does not apply (there are no unchanged sections to collapse).

---

## Interaction Flows

### Flow 1: Switch to Diff View (`AC-diff-toggle-to-diff`)

1. User has a file loaded via the `/shepherd` slash command. The toolbar shows the view mode toggle with "File" active and "Diff" enabled.
2. User clicks the "Diff" segment (or presses `Tab` to focus it, then `Enter` / `Space`).
3. **If comments exist in file mode** (`AC-diff-switch-clears-comments`): A confirmation dialog appears (see Flow 3: Mode Switch Confirmation). If cancelled, the mode stays on "File" and flow ends. If confirmed, continue.
4. All file-mode comments are cleared. The comment count resets to 0.
5. The "Diff" segment becomes active (blue background). The "File" segment becomes inactive.
6. The refresh button appears in the toolbar (fade in, 150ms).
7. The code viewer panel shows the loading state ("Loading baseline...").
8. The application fetches the git HEAD version via `GET /api/file/head?path=<encoded-path>`.
9. On successful fetch, the application computes the diff client-side (`FR-diff-compute`, `NFR-diff-client-compute`).
10. The diff viewer renders in the code viewer panel with collapsed sections, line gutters, and syntax highlighting.
11. If the diff is empty (no changes), the empty diff state is shown instead (see `AC-diff-no-changes`).
12. If the file has no git history (HEAD 404), all lines are shown as additions (see `AC-diff-no-git-history`).

### Flow 2: Switch Back to File View (`AC-diff-toggle-to-file`)

1. User is in diff view.
2. User clicks the "File" segment in the toggle (or uses keyboard).
3. **If comments exist in diff mode** (`AC-diff-switch-clears-comments`): A confirmation dialog appears (see Flow 3). If cancelled, flow ends.
4. All diff-mode comments are cleared. The comment count resets to 0.
5. The "File" segment becomes active. The "Diff" segment becomes inactive.
6. The refresh button disappears from the toolbar (fade out, 150ms).
7. The code viewer panel reverts to showing the full file content with absolute line numbers, exactly as it was before diff view was activated (but without any comments, since those were cleared).
8. The preamble is preserved across mode switches.

### Flow 3: Mode Switch Confirmation (`AC-diff-switch-clears-comments`)

Triggered when the user attempts to switch view modes and comments exist in the current mode.

1. A ConfirmationDialog appears with:
   - **Title**: "Switch view mode?"
   - **Body**: "Switching to [File/Diff] view will clear all N comments. Comments cannot be transferred between view modes because they are anchored to different line models."
   - **Cancel button**: "Cancel" (secondary, left).
   - **Confirm button**: "Switch and clear comments" (destructive/red, right).
2. If the user clicks "Switch and clear comments" or presses `Enter` (focus is on Cancel by default, so the user must Tab to the confirm button), the mode switch proceeds and comments are cleared.
3. If the user clicks "Cancel" or presses `Escape`, the dialog closes and the mode toggle reverts to the previous selection. No comments are cleared.

The dialog uses the same ConfirmationDialog component from `../design/code-review-prompt.md`, with `confirmVariant: 'destructive'`.

### Flow 4: Add a Comment in Diff View (`AC-diff-comment-added-line`, `AC-diff-comment-removed-line`, `AC-diff-comment-context-line`)

1. User is in diff view with the diff rendered.
2. User hovers over a visible diff line (added, removed, or context). A faint "+" icon appears in the comment gutter (CmG column).
3. User clicks the "+" icon (or the old/new line number area).
4. The InlineCommentEditor opens below that line, identical to the file-mode editor.
5. User types a comment and clicks "Comment" or presses `Cmd+Enter` / `Ctrl+Enter`.
6. The editor closes. A CommentBubble appears below the line with a diff-aware line label (e.g., "Line +15" for an added line).
7. The comment gutter shows a blue dot indicator on that line.
8. The toolbar comment count increments by 1. Comment navigation becomes enabled (if this is the first comment).

### Flow 5: Refresh Diff (`AC-diff-refresh-updates`)

1. User is in diff view.
2. User clicks the refresh button (or presses `Tab` to focus it, then `Enter` / `Space`).
3. **If comments exist**: A confirmation dialog appears:
   - **Title**: "Refresh diff?"
   - **Body**: "Refreshing will re-fetch the file and recompute the diff. All N comments will be cleared because line positions may have changed."
   - **Cancel button**: "Cancel" (secondary).
   - **Confirm button**: "Refresh and clear comments" (destructive/red).
4. If confirmed (or if no comments existed):
   - All comments are cleared.
   - The refresh button enters its spinning/disabled state.
   - The code viewer shows the loading state.
   - The application re-fetches both the working copy (`GET /api/file?path=<path>`) and the HEAD version (`GET /api/file/head?path=<path>`).
   - The diff is recomputed and the diff viewer re-renders.
   - The refresh button returns to its default state.
5. If cancelled, nothing happens.

### Flow 6: Expand a Collapsed Section (`AC-diff-expand-section`)

1. User is in diff view and sees a collapsed section separator ("... 47 unchanged lines ...").
2. User clicks anywhere on the separator row (or focuses it via keyboard and presses `Enter` / `Space`).
3. The separator fades out (100ms).
4. The hidden lines appear with a height-expansion animation (150ms ease-out).
5. The lines are now interactive: the user can hover, click the gutter, and add comments on any of the newly revealed lines (`AC-diff-expand-then-comment`).
6. For keyboard users, focus moves to the first newly revealed line.

### Flow 7: Comment After Expanding a Section (`AC-diff-expand-then-comment`)

1. User expands a collapsed section (Flow 6).
2. User hovers over one of the newly revealed context lines. The "+" icon appears in the gutter.
3. User clicks the gutter to open the InlineCommentEditor.
4. User adds a comment. The flow follows Flow 4 from step 5 onward.

### Flow 8: Navigate Comments in Diff View

Comment navigation (`[` / `]` keys, or the previous/next buttons in the toolbar) works identically to file mode. Comments are ordered by their position in the diff view (top to bottom as rendered). When navigating to a comment:

1. The diff viewer scrolls to center the target comment's line(s) in the viewport.
2. The target CommentBubble receives the focused style (blue left border, `#DBEAFE` background).
3. The line(s) associated with the comment receive the focused-comment-line yellow overlay.
4. The toolbar shows "Comment N of M".
5. Wrapping behavior is identical: "Next" on the last comment wraps to the first; "Previous" on the first wraps to the last.

### Flow 9: Generate Prompt from Diff View (`FR-diff-prompt-format`, `AC-diff-prompt-includes-diff`)

1. User is in diff view with one or more comments.
2. The prompt is automatically generated and updated in the preview panel whenever comments are added, edited, or deleted.
3. The application generates a diff-aware prompt (see Prompt Output Format — Diff Mode below).
4. The sidebar prompt preview populates with the generated text. The preamble collapses to a summary line. The Copy button becomes enabled.
5. All existing behaviors (automatic prompt generation, copy) work identically to file mode.

### Flow 10: Keyboard Navigation in Diff View (`NFR-diff-accessibility`)

All keyboard interactions from file mode are supported in diff mode:

1. `Tab` into the diff viewer area focuses the first visible line.
2. `ArrowUp` / `ArrowDown` moves focus between visible lines (skipping collapsed section separators — separators are treated as focusable stops, but Arrow keys move through them to the next visible code line; `Tab` can also land on a separator).
3. `Enter` or `c` on a focused line opens the InlineCommentEditor.
4. `Shift+ArrowDown` / `Shift+ArrowUp` extends a range selection. The range stops at collapsed separators.
5. `Enter` or `Space` on a focused collapsed separator expands it.
6. `Escape` clears a range selection.
7. `[` / `]` navigates between comments.
8. All toolbar keyboard shortcuts remain unchanged.

---

## Component Specs

### ViewModeToggle

A segmented control for switching between File and Diff view modes. Implements `FR-diff-mode-toggle`, `FR-diff-mode-availability`.

- **Variants**: None (single component with internal state per segment).

- **Props/Inputs**:
  - `activeMode: 'file' | 'diff'` — The currently active view mode.
  - `isDiffEnabled: boolean` — Whether the Diff segment is enabled (true for server-loaded files).
  - `onModeChange: (mode: 'file' | 'diff') => void` — Callback when the user selects a mode.

- **Visual Structure**:
  ```
  +--------+--------+
  |  File  |  Diff  |
  +--------+--------+
  ```
  - Two segments in a horizontal group.
  - Outer border-radius: 6px. Inner edges are flat (shared border).
  - Each segment: 56px wide, 32px tall.
  - 1px border around the entire group.

- **Behavior**:
  - Clicking an inactive, enabled segment fires `onModeChange`.
  - Clicking the active segment does nothing.
  - Clicking a disabled segment does nothing (tooltip appears on hover).
  - The parent component handles confirmation dialogs before actually changing the mode.

- **Keyboard Accessibility** (`NFR-diff-accessibility`):
  - The toggle is focusable as a group (`role="tablist"`, each segment is `role="tab"`).
  - `ArrowLeft` / `ArrowRight` moves focus between segments.
  - `Enter` or `Space` activates the focused segment (if enabled).
  - `aria-selected="true"` on the active segment.
  - `aria-disabled="true"` on the Diff segment when disabled.
  - Disabled tooltip is also announced via `aria-describedby` referencing a visually-hidden tooltip element.

---

### DiffViewer

The core diff display component. Replaces the CodeViewer in the code viewer panel when diff mode is active. Implements `FR-diff-display`, `FR-diff-collapse`, `FR-diff-expand`, `FR-diff-comment-create`, `FR-diff-comment-on-range`.

- **Variants**: None (single variant with dynamic rendering based on diff content and comments).

- **Props/Inputs**:
  - `diffLines: DiffLine[]` — Array of diff line objects, each with `{ type: 'added' | 'removed' | 'context', oldLineNumber: number | null, newLineNumber: number | null, content: string }`.
  - `collapsedSections: CollapsedSection[]` — Array of `{ startIndex: number, endIndex: number, lineCount: number }` describing which ranges of `diffLines` are collapsed.
  - `expandedSections: Set<number>` — Indices of collapsed sections that have been expanded.
  - `language: string` — For syntax highlighting.
  - `comments: DiffComment[]` — Array of comment objects with diff-specific identifiers.
  - `focusedCommentId: string | null`
  - `selectedRange: { startIndex: number, endIndex: number } | null`
  - `onLineClick: (index: number) => void`
  - `onRangeSelect: (startIndex: number, endIndex: number) => void`
  - `onExpandSection: (sectionIndex: number) => void`
  - `onCommentEdit: (commentId: string) => void`
  - `onCommentDelete: (commentId: string) => void`

- **Visual Structure**: See the Diff Viewer Layout section above for the column layout.

- **Performance** (`NFR-diff-render-perf`):
  - The diff viewer must use **virtualized rendering**, identical in approach to the file-mode CodeViewer. Only lines in and near the viewport (plus a buffer of ~20 lines above and below) are rendered to the DOM.
  - Collapsed section separators count as a single row in the virtual list (36px height) regardless of how many lines they hide.
  - Expanded sections are treated as normal rows in the virtual list after expansion.

- **Keyboard Accessibility** (`NFR-diff-accessibility`):
  - Same `role="grid"` / `role="row"` / `role="rowheader"` / `role="gridcell"` structure as the file-mode CodeViewer.
  - Each row has three `role="rowheader"` cells: old line number, new line number, and type indicator.
  - Collapsed separators are `role="button"` with `aria-label="Expand N unchanged lines"`.
  - Screen reader announcements for lines include the type: "Added line, new line 15: [code]", "Removed line, old line 42: [code]", "Context line, old 30 new 30: [code]".

---

### CollapsedSectionSeparator

A single row representing a collapsed block of unchanged lines. Implements `FR-diff-collapse`, `FR-diff-expand`.

- **Variants**: None.

- **Props/Inputs**:
  - `lineCount: number` — Number of hidden lines.
  - `onExpand: () => void` — Callback when clicked/activated.

- **Visual Structure**:
  ```
  +----------------------------------------------------------------------+
  |                  ... 47 unchanged lines ...              [Expand]     |
  +----------------------------------------------------------------------+
  ```
  - Full width of the diff viewer.
  - Height: 36px.
  - Background: `#F8FAFC`. Border: 1px dashed `#CBD5E1` top and bottom.
  - Text: centered, 12px, font-weight 500, color `#64748B`.
  - "Expand" link: right-aligned, 12px, font-weight 500, color `#2563EB`.

- **States**:

  | State | Appearance |
  |---|---|
  | Default | As described above |
  | Hover | Background: `#EFF6FF`. Border: 1px dashed `#93C5FD`. "Expand" underlined. Cursor: pointer. |
  | Focused | 2px `#2563EB` focus ring around the row. |
  | Expanding (animated) | Fade out 100ms, then hidden lines expand in 150ms. |

- **Behavior**:
  - Clicking anywhere on the separator triggers expansion.
  - `Enter` or `Space` when focused triggers expansion.
  - After expansion, the component is unmounted and replaced by the revealed lines.

- **Keyboard Accessibility**:
  - `tabindex="0"`, `role="button"`, `aria-label="Expand N unchanged lines"`.
  - Participates in the grid navigation: `ArrowUp` / `ArrowDown` can move focus to/from the separator, and it can also receive focus from sequential Tab navigation.

---

### DiffEmptyState

The empty state shown when there are no changes between the working copy and HEAD. Implements `FR-diff-empty-state`, `AC-diff-no-changes`.

- **Variants**: None.

- **Props/Inputs**:
  - `onSwitchToFile: () => void` — Callback to switch back to file view.

- **Visual Structure**:
  ```
  +----------------------------------------------+
  |                                               |
  |          [document-equals icon, 48px]         |
  |                                               |
  |          No changes detected                  |
  |                                               |
  |  The working copy matches the git HEAD        |
  |  version. Switch to File view to see and      |
  |  comment on the full file.                    |
  |                                               |
  |       [Switch to File view]                   |
  |                                               |
  +----------------------------------------------+
  ```
  - Centered vertically and horizontally in the code viewer panel.
  - Icon: 48px, color `#94A3B8`.
  - Title: 16px, font-weight 600, color `#1E293B`. 12px below icon.
  - Description: 13px, color `#64748B`. 8px below title. Max-width: 320px. Text-align: center.
  - Button: secondary style. Border: 1px solid `#E2E8F0`. Background: `#FFFFFF`. Text: `#475569`, 13px, font-weight 500. Padding: 8px 16px. Border-radius: 6px. Hover background: `#F8FAFC`. 16px below description.

- **Keyboard Accessibility**:
  - The button is focusable. `Tab` lands on it. `Enter` or `Space` activates it.
  - `aria-label` on the component container: "No changes detected in diff view".

---

## Prompt Output Format — Diff Mode

When generating a prompt from diff view, the format adapts to include diff context instead of the full file. Implements `FR-diff-prompt-format`, `AC-diff-prompt-includes-diff`.

```
## Instructions

[Preamble text, if provided. Omitted if no preamble.]

## File: [filename] ([language]) — Diff View

The following shows changes between the git HEAD version and the current working copy.
Lines prefixed with `+` are additions. Lines prefixed with `-` are removals. Unmarked lines are unchanged context.

```diff
@@ ... @@
   30 |  const result = processData(input);
   31 |  if (result.error) {
-  32 |    console.log(result.error);
+  32 |    console.error(result.error);
+  33 |    throw new Error(result.error.message);
   33 |  }
   34 |  return result.data;
```

## Requested Changes

- **Line +32** (added): Use console.warn instead of console.error for non-fatal issues
- **Line -32** (removed): This logging was insufficient, good that it was replaced
- **Lines +32 to +33** (added): Add error recovery instead of throwing
```

**Rules**:
- The file heading includes "-- Diff View" to distinguish from file-mode prompts.
- A preamble explaining the diff notation is always included (the two-line explanation above the diff block). This is a fixed string, not user-editable.
- The code block uses the `diff` language identifier for syntax highlighting in AI agents that support it.
- Line numbers in the diff block use the format: `  32 |` (right-aligned, pipe separator). Added lines use the new line number. Removed lines use the old line number. Context lines use the new line number.
- Lines are prefixed with `+`, `-`, or ` ` (space) matching the diff type indicator.
- The diff block includes the full rendered diff (including context lines and expanded sections), not just the lines around comments. This gives the AI agent the complete picture of what changed. Collapsed sections are included as-is (i.e., hidden lines are NOT included; only visible lines plus a `@@ ... N unchanged lines ... @@` marker for collapsed sections).
- Comments are listed in the "Requested Changes" section in top-to-bottom order as they appear in the diff.
- Each comment label includes the line number with a type prefix: "Line +N" (added), "Line -N" (removed), "Line N" (context). Range comments use "Lines +N to +M", "Lines -N to -M", or "Lines -N to +M" as appropriate.
- Each comment label includes a parenthetical type descriptor: "(added)", "(removed)", "(context)", or "(mixed)" for ranges spanning types.
- If no preamble is provided, the "Instructions" section is omitted (same as file mode).
- If the file name is unknown, use "Untitled". If the language is unknown, use "Plain Text". Same rules as file mode.

---

## Responsive Behavior

The diff view follows the same responsive rules as the existing CRPG design (see `../design/code-review-prompt.md`, Responsive Behavior section).

### Breakpoints

| Breakpoint | Diff-Specific Behavior |
|---|---|
| **>= 1280px** | Full diff viewer layout as described. All gutter columns visible (140px total gutter width). Sidebar: 360px. |
| **1024px - 1279px** | Sidebar narrows to 300px. The diff viewer gutter remains at full width (140px). The code content area is narrower, which means longer lines trigger horizontal scrolling sooner. The view mode toggle and refresh button remain visible. |
| **< 1024px** | Same overlay message as file mode. The diff view is not usable below 1024px. |

### Horizontal Overflow in Diff View

Long lines in the diff viewer trigger horizontal scrolling within the code content column only. The gutter columns (CmG, OldLN, NewLN, T, G) remain **sticky** (fixed in place) while the code content scrolls horizontally. This uses `position: sticky; left: 0` on the gutter columns, with a combined width of 140px.

---

## Accessibility

### Keyboard Navigation (`NFR-diff-accessibility`)

All diff view interactions are achievable via keyboard:

| Workflow | Keyboard Path |
|---|---|
| **Switch to diff view** | `Tab` to view mode toggle, `ArrowRight` to "Diff" segment, `Enter` |
| **Switch to file view** | `Tab` to view mode toggle, `ArrowLeft` to "File" segment, `Enter` |
| **Navigate diff lines** | `Tab` to diff viewer, `ArrowUp`/`ArrowDown` to move between lines |
| **Expand collapsed section** | `ArrowDown` to land on separator, `Enter` or `Space` |
| **Add comment on diff line** | Focus line, `Enter` or `c`, type comment, `Cmd+Enter` |
| **Add range comment** | Focus start line, `Shift+ArrowDown` to select range, `Enter` |
| **Navigate comments** | `[` for previous, `]` for next (same as file mode) |
| **Refresh diff** | `Tab` to refresh button, `Enter` |
| **Copy prompt** | `Cmd+Shift+C` / `Ctrl+Shift+C` (same as file mode) |

### Focus Management

- When switching to diff mode, focus moves to the first visible line in the diff viewer after loading completes.
- When switching to file mode, focus moves to the first line in the code viewer.
- When expanding a collapsed section, focus moves to the first newly revealed line.
- When the empty diff state is shown, focus moves to the "Switch to File view" button.
- All InlineCommentEditor and ConfirmationDialog focus management rules from file mode apply identically.

### ARIA Attributes

Extends the ARIA table from `../design/code-review-prompt.md`:

| Element | ARIA |
|---|---|
| View mode toggle group | `role="tablist"`, `aria-label="View mode"` |
| "File" segment | `role="tab"`, `aria-selected="true/false"`, `aria-controls="code-viewer-panel"` |
| "Diff" segment | `role="tab"`, `aria-selected="true/false"`, `aria-disabled="true/false"`, `aria-controls="code-viewer-panel"`, `aria-describedby="diff-disabled-tooltip"` (when disabled) |
| Diff viewer | `role="grid"`, `aria-label="Diff viewer"` |
| Diff line row | `role="row"` |
| Old line number cell | `role="rowheader"`, `aria-label="Old line N"` (or empty if added line) |
| New line number cell | `role="rowheader"`, `aria-label="New line N"` (or empty if removed line) |
| Type indicator cell | `role="rowheader"`, `aria-label="Added"` / `"Removed"` / `"Unchanged"` |
| Code content cell | `role="gridcell"` |
| Collapsed section separator | `role="button"`, `aria-label="Expand N unchanged lines"` |
| Refresh button | `aria-label="Refresh diff"`, `aria-disabled` when fetching |
| Empty diff state | `role="region"`, `aria-label="No changes detected"` |
| Comment bubble (diff) | `role="note"`, `aria-label="Comment on [type] line N: [text]"` |

### Color and Contrast

- **Added line background** (`#F0FDF4`) with dark code text meets WCAG AA contrast ratio (the lightest text color used on code is `#94A3B8` for line numbers, which achieves 3.4:1 against `#F0FDF4` — sufficient for the 13px monospace text which qualifies as large text at this weight). The primary code text colors from syntax highlighting all exceed 4.5:1 against `#F0FDF4`.
- **Removed line background** (`#FEF2F2`) with dark code text meets WCAG AA. Same contrast analysis as added lines — `#94A3B8` line numbers achieve 3.3:1 against `#FEF2F2`.
- **Type indicator colors**: `+` in `#15803D` (green-700) against `#F0FDF4` = 4.8:1 (passes AA). `-` in `#B91C1C` (red-700) against `#FEF2F2` = 5.6:1 (passes AA).
- **Collapsed separator text**: `#64748B` against `#F8FAFC` = 4.9:1 (passes AA).
- The diff view does not rely solely on color to convey information. The `+`/`-` type indicator provides a textual signal alongside the green/red backgrounds. Screen readers announce "Added"/"Removed"/"Unchanged" for each line.

---

## Color Palette — Diff Additions

These colors extend the palette from `../design/code-review-prompt.md`:

| Usage | Color | Hex |
|---|---|---|
| Added line background | Light green | `#F0FDF4` |
| Removed line background | Light red | `#FEF2F2` |
| Added line type indicator | Green | `#15803D` |
| Removed line type indicator | Red | `#B91C1C` |
| Collapsed separator background | Very light gray | `#F8FAFC` |
| Collapsed separator border | Dashed gray | `#CBD5E1` |
| Collapsed separator text | Slate | `#64748B` |
| Collapsed separator hover bg | Blue-tinted | `#EFF6FF` |
| Collapsed separator hover border | Light blue | `#93C5FD` |
| Toggle active segment bg | Primary blue | `#2563EB` |
| Toggle active segment text | White | `#FFFFFF` |
| Toggle inactive segment bg | White | `#FFFFFF` |
| Toggle disabled segment bg | Off-white | `#F1F5F9` |
| Toggle disabled segment text | Muted | `#94A3B8` |
| Error banner background | Pale red | `#FEF2F2` |
| Error banner text | Dark red | `#991B1B` |
| Error banner border | Light red | `#FECACA` |

---

## Requirement Traceability

This section maps every diff-view requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-diff-mode-toggle` | ViewModeToggle component; Toolbar Modifications section; Flow 1 (switch to diff); Flow 2 (switch to file) |
| `FR-diff-mode-availability` | ViewModeToggle disabled state; Toolbar states table; disabled tooltip specification |
| `FR-diff-baseline-fetch` | Diff Mode Loading State section; Flow 1 step 8; error banner spec |
| `FR-diff-compute` | Flow 1 step 9; implicit in DiffViewer props (diffLines computed upstream) |
| `FR-diff-display` | Diff Viewer Layout section; DiffViewer component; column layout; line background colors |
| `FR-diff-collapse` | Collapsed Sections section; CollapsedSectionSeparator component; collapse rules |
| `FR-diff-expand` | Expanded Sections section; CollapsedSectionSeparator component; Flow 6 |
| `FR-diff-comment-create` | Comments on Diff Lines section; Flow 4; DiffViewer component |
| `FR-diff-comment-on-range` | Comments on Diff Lines section (range selection); Flow 4; `AC-diff-comment-range` |
| `FR-diff-prompt-format` | Prompt Output Format -- Diff Mode section; Flow 9 |
| `FR-diff-empty-state` | DiffEmptyState component; Empty Diff State section |
| `FR-diff-refresh` | Refresh Button spec; Flow 5 |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-diff-compute-perf` | Implicit (design constraint for engineering); Flow 1 loading state note |
| `NFR-diff-render-perf` | DiffViewer Performance note (virtualized rendering) |
| `NFR-diff-client-compute` | Implicit (no server diff endpoint in any flow; server provides raw text only) |
| `NFR-diff-baseline-fetch-speed` | Diff Mode Loading State section (target: under 500ms note) |
| `NFR-diff-accessibility` | Accessibility section; keyboard navigation table; ARIA attributes; Flow 10 |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-diff-toggle-to-diff` | Flow 1; ViewModeToggle states |
| `AC-diff-toggle-to-file` | Flow 2; ViewModeToggle states |
| `AC-diff-collapse-default` | Collapsed Sections section (collapse rules); CollapsedSectionSeparator |
| `AC-diff-expand-section` | Flow 6; Expanded Sections section; CollapsedSectionSeparator |
| `AC-diff-comment-added-line` | Flow 4; Comments on Diff Lines (line label: "Line +N"); color table (green background) |
| `AC-diff-comment-removed-line` | Flow 4; Comments on Diff Lines (line label: "Line -N"); color table (red background) |
| `AC-diff-comment-context-line` | Flow 4; Comments on Diff Lines (line label: "Line N") |
| `AC-diff-prompt-includes-diff` | Prompt Output Format -- Diff Mode section; Flow 9 |
| `AC-diff-no-git-history` | Untracked File State section; Flow 1 step 12 |
| `AC-diff-no-changes` | DiffEmptyState component; Empty Diff State section; Flow 1 step 11 |
| `AC-diff-paste-upload-disabled` | ViewModeToggle disabled state; disabled tooltip text and styling |
| `AC-diff-line-numbers` | Diff Viewer Layout section (OldLN and NewLN column specs) |
| `AC-diff-syntax-highlight` | Diff Viewer Layout (code content column, syntax highlighting note); DiffViewer props (language) |
| `AC-diff-refresh-updates` | Flow 5; Refresh Button spec |
| `AC-diff-switch-clears-comments` | Flow 3 (Mode Switch Confirmation); Flow 1 step 3; Flow 2 step 3 |
| `AC-diff-comment-range` | Comments on Diff Lines (range selection across line types); range label format |
| `AC-diff-expand-then-comment` | Flow 7; Expanded Sections section (step 5) |
