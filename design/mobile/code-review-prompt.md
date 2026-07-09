---
product-hash: 323b3b866d3f9c84f30fca9b3c045f8e898d2504e3bc4a91e659530e8f11be78
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout]
---

# Code Review Prompt Generator — Mobile Design Spec

> Based on requirements in `../../product/code-review-prompt.md`  
> See also `../../product/mobile/code-review-prompt.md` for mobile-specific requirements.

## What We're Designing

A touch-first, mobile-native code review application for iOS and Android that lets developers annotate source files with inline comments and generate structured prompts for AI coding assistants. The design optimizes for small screens with collapsible panels, gesture navigation, and voice input support while preserving all core CRPG functionality from the shared product spec. The app is launched via deep links from Buzz Mobile, which provides file content and review context.

## Screen Inventory

1. **Code Review Screen** — Primary workspace where users view code, add comments, and navigate between files
2. **Review Context Drawer** — Collapsible panel showing overall changeset context and per-file context
3. **Prompt Preview Screen** — Full-screen view of the generated prompt with copy/done actions
4. **All Comments Screen** — Summary view listing all comments across all files
5. **File Selector Overlay** — Full-screen file list for quick navigation (alternative to tab strip)

## Design Principles for Mobile

### Touch-First Interaction

All interactive elements meet minimum tap target size of 44pt (iOS) / 48dp (Android) per platform guidelines. No hover states. All actions are triggered by tap, long-press, or gestures.

### Progressive Disclosure

Limited screen real estate demands collapsible UI. Context panels, file lists, and auxiliary views collapse to headers or icons when not actively needed. The code content is always the primary surface.

### Gesture Primacy

Standard mobile gestures (swipe, pinch, long-press) are leveraged before introducing custom controls. Users should feel at home using patterns they know from other mobile apps.

### Readable by Default

Line wrapping is on by default. Syntax highlighting uses high-contrast themes optimized for outdoor readability. Pinch zoom is available without hiding it behind a menu.

---

## Screen Definitions

### Code Review Screen

The primary workspace where users spend most of their time. Shows one file at a time with line numbers, syntax highlighting, inline comments, and a file tab strip.

**Entry points:**
- Launched via deep link from Buzz Mobile (`FR-crpm-deeplink-launch`)
- Restored from background with persisted session state (`FR-crpm-offline-persist`)

**Layout:**

```
┌────────────────────────────────────┐
│ [Tab: utils.ts (3)] [helpers.ts…]  │ ← Horizontal scrollable file tabs
├────────────────────────────────────┤
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  │
│ ┃  1  import { validate } from  ┃  │ ← Code content with line numbers
│ ┃  2  './validators';           ┃  │   (scrollable, zoomable)
│ ┃  3● export function process…  ┃  │   ● = comment indicator
│ ┃  4                             ┃  │
│ ┃     [Comment: Rename this…]   ┃  │ ← Inline comment attached to line 3
│ ┃                                ┃  │
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  │
├────────────────────────────────────┤
│ ⌃ Context    [3 comments]  Done   │ ← Bottom toolbar
└────────────────────────────────────┘
```

**Components:**

- **File Tab Strip** (`FR-crpm-mobile-tabs`): Horizontal scrollable row at top showing all loaded files. Each tab displays:
  - File name (truncated with ellipsis if longer than ~15 characters)
  - Comment count badge (e.g., "(3)") if file has comments
  - Active tab highlighted with solid background color (primary brand color)
  - Inactive tabs have transparent background with border or subtle tint
  - Tabs scroll horizontally when more files than fit on screen
  - Tapping a tab switches to that file immediately

- **Code Content Area** (`FR-crp-file-display`):
  - Scrollable vertically and horizontally (when line wrap is off)
  - Line numbers in left gutter (minimum 44pt wide for tap targets)
  - Code text in monospace font, syntax highlighted per detected language (`FR-crp-syntax-highlight`)
  - Comment indicators (colored dots or icons) in gutter for lines with comments (`FR-crp-comment-indicator`)
  - Inline comment boxes appear directly below commented lines, anchored to the gutter
  - Supports pinch-to-zoom (`FR-crpm-pinch-zoom`): 50% to 200% of default text size
  - Supports horizontal swipe gestures for file navigation (`FR-crpm-gesture-nav`)

- **Inline Comment Box**:
  - Appears below the commented line when user taps a line number or an existing comment
  - Contains comment text in editable text view (when creating/editing) or read-only text (when viewing)
  - Shows microphone icon button for voice input (`FR-crpm-voice-input`) when keyboard is active
  - Tap outside or swipe down to dismiss keyboard and collapse input box
  - Edit and delete actions accessible via long-press on existing comment or via icon buttons

- **Bottom Toolbar**:
  - **Context button** (left): Chevron icon indicating drawer state (⌃ when collapsed, ⌄ when expanded). Tap to toggle Review Context Drawer (`FR-crpm-mobile-context`)
  - **Comment count** (center): Displays total number of comments across all files (e.g., "3 comments") (`FR-crp-comment-count`). Tap to open All Comments screen
  - **Done button** (right): Primary action button. Sends prompt to Buzz Mobile via deep link callback (`FR-crpm-deeplink-handoff`). Disabled when no comments exist. Only visible when launched via deep link

**States:**

- **Empty** (`AC-crp-empty-state`): No files loaded. Shows centered message: "Open from Buzz Mobile to start reviewing code."
- **Single file loaded**: File tab strip shows one tab (no scrolling). Code content fills screen. Bottom toolbar visible.
- **Multi-file loaded**: Tab strip scrolls horizontally. Active file displayed. Swipe gestures enabled.
- **Comment input active**: Keyboard slides up from bottom, pushing code content and toolbar up. Comment input box is anchored below tapped line. Microphone button visible in input box.
- **Offline** (`FR-crpm-offline-sync`): No visual change to Code Review Screen itself. Offline indicator appears in status bar or top banner if prompt send fails.
- **Fullscreen** (`FR-crpm-fullscreen`): All chrome (tabs, toolbar) hidden. Only code content and line numbers visible. Tap top of screen to reveal minimal exit toolbar.

**Actions:**

- **Tap line number** (`FR-crpm-touch-select`): Opens comment input box anchored below that line. Keyboard appears. Focus moves to input field.
- **Tap existing comment**: Opens comment in edit mode. Keyboard appears with comment text pre-filled.
- **Long-press comment**: Shows action menu: Edit / Delete / Cancel
- **Swipe left on code area** (`FR-crpm-gesture-nav`): Navigate to next file (if available). Smooth animated transition.
- **Swipe right on code area**: Navigate to previous file. Wrap-around at first/last file.
- **Pinch on code area** (`FR-crpm-pinch-zoom`): Zoom in/out on code content. Zoom level persists per-file within session.
- **Tap Context button**: Toggles Review Context Drawer from collapsed to expanded or vice versa
- **Tap comment count**: Opens All Comments screen
- **Tap Done button**: Sends generated prompt to Buzz Mobile. Shows loading indicator briefly, then closes app (if platform allows) or shows confirmation message

**Requirements satisfied:**  
`FR-crp-file-display`, `FR-crp-line-comment-create`, `FR-crp-comment-indicator`, `FR-crp-comment-count`, `FR-crp-syntax-highlight`, `FR-crpm-mobile-tabs`, `FR-crpm-touch-select`, `FR-crpm-gesture-nav`, `FR-crpm-pinch-zoom`, `FR-crpm-voice-input`, `FR-crpm-fullscreen`, `FR-crpm-deeplink-handoff`, `AC-crp-add-comment-single-line`, `AC-crp-edit-comment`, `AC-crp-delete-comment`

---

### Review Context Drawer

Collapsible bottom drawer that displays overall changeset context and per-file context. Only shown when context data is present (launched via `/shepherd-review`).

**Entry points:**
- Tap Context button in bottom toolbar of Code Review Screen
- Swipe up from bottom edge of screen (when drawer is collapsed)

**Layout (expanded):**

```
┌────────────────────────────────────┐
│ Code content (pushed up, partially │
│ visible above)                     │
├────────────────────────────────────┤
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ ← Drag handle
│                                    │
│ ▼ Overall Context                  │ ← Collapsible section header
│   What changed: Added validation   │
│   logic to process() function.     │ ← Neutral context (informational style)
│                                    │
│ ▼ Review Feedback                  │ ← Collapsible section header
│   ⚠️ Consider edge case handling   │ ← Review feedback (distinct style)
│   for empty input arrays.          │
│                                    │
│ ▼ File Context: utils.ts           │ ← Per-file context section
│   This file: Modified process()    │
│   to validate inputs before…       │
│                                    │
└────────────────────────────────────┘
```

**Layout (collapsed):**

```
┌────────────────────────────────────┐
│ Code content (full screen)         │
│                                    │
│                                    │
├────────────────────────────────────┤
│ ⌄ Context: Overall + utils.ts     │ ← Collapsed header showing summary
└────────────────────────────────────┘
```

**Components:**

- **Drag Handle** (`FR-crpm-mobile-context`): Horizontal bar at top of drawer. User can drag up to expand, drag down to collapse. Standard iOS/Android bottom sheet pattern.

- **Overall Changeset Context Section** (`FR-crp-review-context-overall`):
  - Header: "Overall Context" with collapse/expand chevron icon
  - Content: Two subsections with distinct visual styling:
    - **Neutral context**: Plain text, informational icon (ℹ️), neutral background color
    - **Review feedback**: Warning/info icon (⚠️ or 💡), subtle colored background (yellow tint for warnings, blue tint for info), clearly labeled as "AI Review"
  - Tappable to collapse/expand independently

- **Per-File Context Section** (`FR-crp-review-context-per-file`):
  - Header: "File Context: [filename]"
  - Content: Same two-subsection structure as overall context (neutral + review feedback)
  - Updates automatically when user switches files in tab strip
  - Hidden entirely if current file has no context data (`AC-crp-context-graceful-missing`)

**States:**

- **Collapsed**: Only header bar visible at bottom of screen. Shows summary text like "Context: Overall + utils.ts"
- **Expanded**: Drawer slides up to cover bottom ~40% of screen. Code content pushed up but still partially visible. User can scroll within drawer content if it's longer than drawer height.
- **Not present**: Drawer not shown at all when no context data provided (standalone mode or files loaded without shepherd-review)

**Actions:**

- **Swipe up on handle**: Expands drawer
- **Swipe down on handle**: Collapses drawer
- **Tap context section header**: Toggles that section between collapsed and expanded (accordion pattern)
- **Scroll within drawer**: When expanded, drawer content scrolls vertically if longer than drawer height

**Requirements satisfied:**  
`FR-crpm-mobile-context`, `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`, `FR-crp-review-context-collapsible`, `AC-crp-context-overall-visible`, `AC-crp-context-per-file-visible`, `AC-crp-context-per-file-switches`, `AC-crp-context-neutral-vs-review`

---

### Prompt Preview Screen

Full-screen view of the generated prompt with actions to copy or send back to Buzz Mobile.

**Entry points:**
- Tap "Preview Prompt" button in bottom toolbar (optional additional button, not shown in initial layout — may be accessible via long-press on Done or menu)
- Automatically shown after Done action completes (if app doesn't auto-close)

**Layout:**

```
┌────────────────────────────────────┐
│ ← Back          Prompt          ⋯  │ ← Navigation bar
├────────────────────────────────────┤
│ # Instructions                     │
│ Refactor for readability.          │ ← Generated prompt content (scrollable)
│                                    │
│ ## File: utils.ts (typescript)     │
│                                    │
│ ### Requested Changes              │
│                                    │
│ ```typescript                      │
│ export function process(data) {    │
│ ```                                │
│ Rename this function to be more…   │
│                                    │
│ [more content...]                  │
├────────────────────────────────────┤
│ [Copy to Clipboard]     [Done]     │ ← Action buttons
└────────────────────────────────────┘
```

**Components:**

- **Navigation Bar**:
  - Back button (left): Returns to Code Review Screen
  - Title: "Prompt"
  - More menu button (right): Opens menu with actions like "Share" or "Clear Session"

- **Prompt Content Area** (`FR-crp-prompt-preview`):
  - Read-only text view showing full generated prompt
  - Formatted with markdown-style visual hierarchy (headings, code blocks, indentation)
  - Scrollable vertically
  - Syntax highlighting within code blocks (same highlighting as main code viewer)
  - No editing allowed

- **Action Buttons**:
  - **Copy to Clipboard** (`FR-crp-prompt-copy`): Copies entire prompt text to system clipboard. Shows toast notification "Copied to clipboard" on success.
  - **Done** (`FR-crp-done-action`, `FR-crpm-deeplink-handoff`): Sends prompt to Buzz Mobile via deep link callback. Shows loading indicator. On success, closes app or shows confirmation message. Only visible when launched via deep link.

**States:**

- **Empty** (`AC-crp-generate-prompt-no-comments`): No comments exist. Prompt content area shows placeholder message: "Add comments to generate a prompt."
- **Populated**: Generated prompt displayed with full formatting
- **Sending**: Done button shows loading spinner. Buttons disabled.
- **Send failed**: Error banner appears: "Could not send to Buzz. Prompt copied to clipboard." Copy button remains available.

**Actions:**

- **Tap Copy button**: Copies prompt to clipboard. Shows confirmation toast.
- **Tap Done button**: Sends prompt to Buzz Mobile. Shows loading state. On success, attempts to close app. On failure, shows error banner and falls back to clipboard copy.
- **Tap Back**: Returns to Code Review Screen

**Requirements satisfied:**  
`FR-crp-prompt-preview`, `FR-crp-prompt-copy`, `FR-crp-done-action`, `FR-crpm-deeplink-handoff`, `AC-crp-copy-clipboard`, `AC-crp-done-sends-prompt`, `AC-crp-done-fallback-clipboard`

---

### All Comments Screen

Summary view listing all comments across all files, organized by file. Read-only view for review purposes.

**Entry points:**
- Tap comment count in bottom toolbar of Code Review Screen
- Menu option "View All Comments" (if menu exists)

**Layout:**

```
┌────────────────────────────────────┐
│ ← Back       All Comments          │ ← Navigation bar
├────────────────────────────────────┤
│ utils.ts (3 comments)              │ ← File section header
│                                    │
│ Line 3                             │ ← Comment entry
│ Rename this function to be more    │
│ descriptive.                       │
│                                    │
│ Lines 10-15                        │
│ Extract this to a helper function. │
│                                    │
│ Line 25                            │
│ Fix null check here.               │
│                                    │
├────────────────────────────────────┤
│ helpers.ts (2 comments)            │
│                                    │
│ Line 5                             │
│ Remove unused parameter.           │
│                                    │
│ Line 42                            │
│ Add error handling.                │
│                                    │
└────────────────────────────────────┘
```

**Components:**

- **Navigation Bar**:
  - Back button: Returns to Code Review Screen
  - Title: "All Comments"

- **File Section** (`FR-crp-comment-summary`):
  - Header showing file name and comment count for that file
  - List of comments below header
  - Files with zero comments are not shown (`AC-crp-comment-summary-shows-all`)
  - Files ordered by position in file tab strip

- **Comment Entry**:
  - Line number or line range (e.g., "Line 3" or "Lines 10-15")
  - Comment text below line reference
  - Tappable: tap navigates to that line in the Code Review Screen (switches file if needed, scrolls to line, highlights comment)

**States:**

- **Empty** (`AC-crp-comment-summary-empty`): No comments exist. Shows centered message: "No comments yet. Tap a line number to add one."
- **Populated**: Shows all files with comments, organized as described above
- **Real-time updates** (`AC-crp-comment-summary-realtime`): If user navigates back to Code Review Screen, adds/edits/deletes comments, then returns to All Comments, the list reflects those changes immediately (no refresh needed)

**Actions:**

- **Tap comment entry**: Navigates to Code Review Screen, switches to that file (if needed), scrolls to the commented line, highlights the comment
- **Tap Back**: Returns to Code Review Screen

**Requirements satisfied:**  
`FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-realtime`, `AC-crp-comment-summary-empty`

---

### File Selector Overlay (Optional Alternative)

Full-screen overlay showing all loaded files in a directory tree or flat list for quick navigation. This is an alternative or supplement to the tab strip for sessions with many files.

**Entry points:**
- Long-press on file tab strip
- Button in toolbar menu
- Swipe down on tab strip with 2 fingers (discoverable gesture)

**Layout:**

```
┌────────────────────────────────────┐
│              Files                 │ ← Header with close button (X)
├────────────────────────────────────┤
│ 3 / 7 reviewed             [Clear] │ ← Progress indicator and actions
├────────────────────────────────────┤
│                                    │
│ src/                               │ ← Directory tree
│   ├─ components/                   │
│   │  └─ FileBrowser.tsx (3) ✓      │ ← File with comment count + reviewed
│   └─ utils/                        │
│      ├─ helpers.ts (2)             │ ← File with comments, not reviewed
│      └─ validators.ts ●            │ ← Active file indicator
│                                    │
│ lib/                               │
│   └─ helpers.ts                    │ ← No comments
│                                    │
└────────────────────────────────────┘
```

**Components:**

- **Header**: Title "Files" and close button (X) to dismiss overlay

- **Progress Bar** (`FR-crp-file-reviewed-progress`): Shows "3 / 7 reviewed" or progress bar visualization

- **Clear Button**: Triggers clear/reset session action (`FR-crp-clear-session`)

- **Directory Tree** (`FR-crp-multi-file-nav`):
  - Files organized under parent directories (same structure as desktop file navigator)
  - Each file row shows:
    - File name
    - Comment count badge if file has comments (e.g., "(3)")
    - Reviewed indicator (checkmark ✓) if file marked as reviewed (`FR-crp-file-reviewed-visual`)
    - Active file indicator (colored dot ●) for currently displayed file
  - Directories can be collapsed/expanded (chevron icon)
  - Unreviewed files appear before reviewed files within each directory (`FR-crp-file-reviewed-grouping`)

- **File Row Actions**:
  - Tap file: Switches to that file and closes overlay
  - Swipe left on file: Reveals action buttons (Mark Reviewed / Remove File)
  - Long-press file: Shows detail overlay with full path, language, review status (`FR-crp-file-tooltip`)

**States:**

- **Single file**: Overlay still available but less useful. Shows single file entry.
- **Multi-file**: Directory tree with all files, scrollable if tree is tall
- **Empty**: Not shown when no files loaded

**Actions:**

- **Tap file row**: Switches to that file in Code Review Screen and dismisses overlay
- **Swipe left on file**: Reveals "Mark Reviewed" toggle button and "Remove" button
- **Tap Mark Reviewed button** (`FR-crp-file-reviewed-toggle`): Toggles reviewed status. Checkmark appears/disappears. Progress indicator updates.
- **Tap Remove button** (`FR-crp-multi-file-remove`): Shows confirmation dialog if file has comments. Removes file from session.
- **Long-press file**: Shows detail popover with full path and metadata (`FR-crp-file-tooltip`, `AC-crp-file-tooltip-full-path`)
- **Tap Close button**: Dismisses overlay, returns to Code Review Screen

**Requirements satisfied:**  
`FR-crp-multi-file-nav`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `FR-crp-file-reviewed-toggle`, `FR-crp-multi-file-remove`, `FR-crp-file-tooltip`

---

## Interaction Flows

### Add a Comment to a Line

User wants to annotate a specific line of code with a review comment.

1. User views code in Code Review Screen
2. User taps line number in left gutter (`FR-crpm-touch-select`) → line highlights, comment input box appears anchored below that line
3. Keyboard slides up from bottom, focus moves to input field
4. User types comment text OR taps microphone icon to use voice input (`FR-crpm-voice-input`)
5. If voice: user speaks, platform speech-to-text converts to text and fills input field
6. User taps "Done" on keyboard or taps outside input area → comment is saved and attached to line
7. Comment indicator (colored dot) appears in gutter for that line (`FR-crp-comment-indicator`)
8. Comment text is displayed in read-only box below the line
9. Comment count in bottom toolbar increments by 1 (`FR-crp-comment-count`)
10. Generated prompt updates automatically in background (`FR-crp-prompt-generate`)

**Requirements satisfied:** `FR-crp-line-comment-create`, `FR-crpm-touch-select`, `FR-crpm-voice-input`, `FR-crp-comment-indicator`, `FR-crp-comment-count`, `FR-crp-prompt-generate`

---

### Navigate Between Files Using Gestures

User is reviewing multiple files and wants to move quickly between them without tapping small tabs.

1. User views file A in Code Review Screen (e.g., utils.ts)
2. User swipes left on code content area (`FR-crpm-gesture-nav`) → screen slides left with animation
3. File B (helpers.ts) slides in from right and becomes active file
4. File tab strip updates to show file B as active (highlighted tab)
5. Code content, line numbers, and inline comments update to show file B's content
6. Per-file context updates in Review Context Drawer (if drawer is open)
7. User swipes left again → navigates to file C
8. User swipes right → navigates back to file B
9. At first file, swiping right wraps around to last file (and vice versa)

**Requirements satisfied:** `FR-crpm-gesture-nav`, `AC-crpm-swipe-nav`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-context-per-file-switches`

---

### Review Context in Collapsible Drawer

User is reviewing code that was loaded from `/shepherd-review` and wants to see the AI agent's feedback without losing focus on the code.

1. User views code in Code Review Screen
2. Review Context Drawer is collapsed at bottom, showing only header "Context: Overall + utils.ts" (`FR-crpm-mobile-context`)
3. User taps Context button in toolbar OR swipes up on drawer handle → drawer expands upward
4. Code content is pushed up (still partially visible above drawer)
5. Drawer shows:
   - Overall Context section (neutral facts about changeset)
   - Review Feedback section (AI agent's opinions and suggestions)
   - File Context section for current file (neutral + feedback)
6. User reads review feedback while scrolling within drawer
7. User taps Overall Context header → that section collapses (accordion pattern)
8. User switches to different file using tab strip → File Context section updates automatically to show new file's context (`AC-crp-context-per-file-switches`)
9. User swipes down on drawer handle OR taps Context button again → drawer collapses back to header-only state
10. Code content slides down to fill screen again

**Requirements satisfied:** `FR-crpm-mobile-context`, `FR-crp-review-context-display`, `FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse`, `AC-crp-context-per-file-switches`

---

### Send Prompt Back to Buzz Mobile

User has finished adding comments and wants to send the generated prompt back to the AI agent.

1. User has added at least one comment to any file
2. Done button in bottom toolbar is enabled (blue/primary color)
3. User taps Done button (`FR-crp-done-action`)
4. App copies generated prompt to system clipboard (fallback, happens immediately)
5. App attempts deep link callback to Buzz Mobile with session ID and prompt text (`FR-crpm-deeplink-handoff`)
6. **Success path:**
   - Deep link succeeds → Buzz Mobile receives prompt
   - App shows brief confirmation message: "Sent to Buzz!" (toast or banner)
   - App attempts to close/dismiss its window (`AC-crp-done-auto-close`)
   - If auto-close not possible, shows "Done! Switch back to Buzz." message
7. **Failure path:**
   - Deep link fails (Buzz not responding, network offline)
   - App shows error banner: "Could not send to Buzz. Prompt copied to clipboard." (`AC-crp-done-fallback-clipboard`)
   - Prompt is queued locally for retry when network returns (`FR-crpm-offline-sync`)
   - User can manually paste prompt into Buzz

**Requirements satisfied:** `FR-crp-done-action`, `FR-crpm-deeplink-handoff`, `AC-crp-done-sends-prompt`, `AC-crp-done-auto-close`, `AC-crp-done-fallback-clipboard`

---

### Zoom Code for Readability

User is outdoors on a phone and the default text size is too small to read comfortably.

1. User views code in Code Review Screen
2. User performs pinch-out gesture on code content area (`FR-crpm-pinch-zoom`)
3. Code text size increases smoothly following pinch gesture
4. Line numbers scale proportionally to remain aligned
5. User continues pinching until text is readable (up to 200% of default size)
6. User scrolls code vertically and horizontally (if needed) — zoom level persists
7. User switches to different file → new file displays at default zoom (zoom is per-file)
8. User switches back to first file → zoom level is restored (150% or whatever user set)
9. User performs pinch-in gesture to zoom out
10. Zoom level is remembered for that file until session ends

**Requirements satisfied:** `FR-crpm-pinch-zoom`, `AC-crpm-pinch-zoom`

---

## Component Specs

### File Tab

Displays a file's name and comment count in the horizontal tab strip. Tappable to switch files.

**Variants:**
- Active tab (currently displayed file)
- Inactive tab (other loaded files)

**Props/Inputs:**
- File name (string)
- Comment count (integer, 0 or higher)
- Active state (boolean)

**States:**
- Active: Solid background in primary brand color, white text, elevated appearance (shadow or border)
- Inactive: Transparent or subtle tinted background, default text color, no elevation

**Behavior:**
- Tap switches to that file in Code Review Screen
- Long-press shows file actions menu or opens File Selector Overlay
- Tab width is variable (shrinks to fit more tabs on screen, but has minimum width ~60pt)
- File name truncates with ellipsis if too long for tab width
- Comment count badge appears as "(3)" after file name if count > 0

**Accessibility:**
- Label: "[filename] tab, [N] comments" (or "no comments")
- Hint: "Double-tap to switch to this file"

---

### Comment Indicator (Gutter Marker)

Visual indicator in the line number gutter showing that a line has one or more comments attached.

**Variants:**
- Single comment (one dot or icon)
- Multiple comments on same line (number badge or stacked dots)

**Props/Inputs:**
- Comment count for that line (integer, 1 or higher)

**States:**
- Default: Colored dot (primary accent color, e.g., blue or orange) in gutter next to line number
- Multiple: Number badge showing count (e.g., "3") instead of dot

**Behavior:**
- Tap on indicator OR tap on line number opens comment input/viewer for that line
- Indicator positioned to right of line number, within gutter column
- Vertically aligned to first visual row of line (if line is wrapped, indicator appears only once)

**Accessibility:**
- Label: "Line [N], [M] comment(s)"

---

### Comment Input Box

Text input field for creating or editing a comment on a line.

**Variants:**
- Create mode (empty input)
- Edit mode (pre-filled with existing comment text)

**Props/Inputs:**
- Line number (integer)
- Existing comment text (string, empty for create mode)
- Voice input available (boolean, based on platform permissions)

**States:**
- Active: Input field has focus, keyboard visible, cursor blinking
- Voice recording: Microphone button highlighted, recording indicator visible, platform speech-to-text active
- Saving: Brief loading state after user taps Done (spinner or disabled state)

**Behavior:**
- Appears anchored below the commented line, aligned with gutter
- Text input expands vertically as user types (up to 5 lines, then scrolls internally)
- Microphone button (if available) positioned in bottom-right corner of input field
- Tap microphone → starts voice recording, platform speech recognition converts to text, fills input field
- Tap outside input OR swipe down on input dismisses keyboard and saves comment (if text is non-empty)
- Tap "x" or cancel button discards changes and closes input
- Empty comment (whitespace only) is not saved

**Accessibility:**
- Label: "Comment for line [N]"
- Hint: "Enter your review comment. Use the microphone button for voice input."
- Voice input respects system speech recognition settings

---

### Context Section Header

Collapsible section header for Overall Context, Review Feedback, and File Context sections within the Review Context Drawer.

**Variants:**
- Collapsed (chevron pointing right ▶)
- Expanded (chevron pointing down ▼)

**Props/Inputs:**
- Section title (string, e.g., "Overall Context")
- Expanded state (boolean)

**States:**
- Collapsed: Header bar with chevron pointing right, content hidden
- Expanded: Header bar with chevron pointing down, content visible below

**Behavior:**
- Tap anywhere on header bar toggles expanded state
- Smooth animation when expanding/collapsing (slide down/up with fade)
- Collapse state persists within session (survives file switches, drawer collapse/expand)

**Accessibility:**
- Label: "[Section title], [expanded/collapsed]"
- Hint: "Double-tap to expand" or "Double-tap to collapse"
- Implements expandable section pattern

---

## Responsive Behavior

### Phone (Portrait, ~375pt width)

- File tab strip shows ~2-3 tabs at a time, scrolls horizontally
- Code content uses full width minus small margins (8pt per side)
- Line numbers gutter is minimum width (44pt) for tap targets
- Review Context Drawer covers ~50% of screen when expanded (overlays code, does not push it off-screen entirely)
- Toolbar buttons are full-width or split evenly (Done button gets more weight)
- Fullscreen mode hides all chrome, maximizing code readability

### Phone (Landscape, ~667pt width)

- More tabs visible in tab strip (~4-5 tabs)
- Code content has more horizontal space, reducing need for horizontal scrolling
- Review Context Drawer is shorter in vertical space, shows less content before scrolling is needed
- Toolbar remains at bottom but may use compact button layout

### Tablet (Portrait/Landscape, ~768pt+ width)

- Tab strip shows many more tabs (~6-8 or more)
- Code content has generous margins, easier to read without pinch zoom
- Review Context Drawer can be larger (up to 60% of screen height) without obscuring code
- Consider split-view layout option: code on left, context drawer on right (permanent sidebar instead of bottom drawer)
- Fullscreen mode still available but less critical given larger screen

---

## Accessibility

### VoiceOver / TalkBack Support

- All interactive elements have clear labels and hints
- Line numbers are labeled "Line [N], tap to add comment" (or "Line [N], [M] comment(s), tap to view")
- Comment text is read aloud when user focuses on comment box
- File tabs announce file name, comment count, and active/inactive state
- Context drawer sections announce expanded/collapsed state
- Keyboard navigation is supported via external keyboard (tab through interactive elements)

### Dynamic Type / Font Scaling

- UI respects platform font scaling settings
- Code text size scales with system font size (in addition to pinch zoom)
- Minimum tap target size (44pt / 48dp) maintained regardless of font size
- Layout reflows gracefully when text size increases

### Color Contrast

- Syntax highlighting themes use high contrast ratios (4.5:1 minimum for normal text, 3:1 for large text)
- Comment indicators use colors distinguishable from both light and dark backgrounds
- Active tab background and inactive tab background have sufficient contrast
- Context drawer section headers have clear visual distinction from content (not relying solely on color)

### Reduced Motion

- Respect platform reduced motion preference
- Swipe navigation still works but uses instant transition instead of slide animation
- Drawer expand/collapse uses instant appearance instead of slide-up animation
- Focus changes are immediate rather than animated

---

## Platform-Specific Adaptations

### iOS

- Use standard iOS bottom sheet pattern for Review Context Drawer (drag handle, rounded corners, shadow)
- File tabs use iOS-style segmented control or custom tabs with iOS visual style
- Comment input uses iOS keyboard with voice input via Siri dictation
- Done button styled as iOS primary button (filled with tint color)
- Swipe gestures match iOS momentum and physics
- Supports iOS 15+ (or as determined by engineering)

### Android

- Use Material Design bottom sheet for Review Context Drawer
- File tabs use Material tabs component or custom tabs with Material visual style
- Comment input uses Android keyboard with voice input via Google Voice Typing
- Done button styled as Material elevated button or filled button
- Swipe gestures match Android momentum and physics
- Supports Android 8.0+ (or as determined by engineering)

---

## Open Questions

1. **Split-view layout for tablets**: Should tablets use a side-by-side layout (code on left, context on right) instead of bottom drawer? This would match desktop behavior more closely.

2. **File Selector vs. Tab Strip**: Should we offer both file navigation patterns, or choose one? Tab strip is faster for 2-5 files, but File Selector Overlay scales better for 10+ files.

3. **Swipe gesture conflicts**: Swipe left/right on code area navigates files. What if user wants to scroll horizontally within code (when line wrap is off)? Should we require two-finger horizontal swipe for file navigation when line wrap is off?

4. **Fullscreen mode discoverability**: How does user discover fullscreen mode? Long-press on code area? Button in toolbar menu? Pinch-out gesture past max zoom?

5. **Offline indicator visibility**: Where should we show the offline state indicator when prompt send fails? Status bar banner? Persistent toolbar indicator? Only when user taps Done?
