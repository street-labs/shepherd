# Dark Mode -- Test Plan

> Based on requirements in `../product/dark-mode.md`
> Based on design in `../design/dark-mode.md`
> Based on technical spec in `../engineering/dark-mode.md`

## Coverage Matrix

### Acceptance Criteria Coverage

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-dm-default-respects-system` | `TC-dm-system-dark-default`, `TC-dm-no-fouc-dark` | Not started |
| `AC-dm-default-light-system` | `TC-dm-system-light-default`, `TC-dm-system-no-preference` | Not started |
| `AC-dm-toggle-to-dark` | `TC-dm-toggle-to-dark`, `TC-dm-transition-smooth` | Not started |
| `AC-dm-toggle-to-light` | `TC-dm-toggle-to-light`, `TC-dm-transition-smooth` | Not started |
| `AC-dm-toggle-to-system` | `TC-dm-toggle-to-system` | Not started |
| `AC-dm-persistence-survives-reload` | `TC-dm-persist-dark-reload` | Not started |
| `AC-dm-persistence-system-survives-reload` | `TC-dm-persist-system-reload` | Not started |
| `AC-dm-realtime-os-change` | `TC-dm-realtime-os-dark-to-light` | Not started |
| `AC-dm-manual-ignores-os` | `TC-dm-realtime-manual-ignores-os` | Not started |
| `AC-dm-syntax-highlight-dark` | `TC-dm-syntax-dark-readable` | Not started |
| `AC-dm-syntax-highlight-light` | `TC-dm-syntax-light-readable` | Not started |
| `AC-dm-all-surfaces-themed` | `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar` | Not started |
| `AC-dm-diff-view-themed` | `TC-dm-surface-diff-view` | Not started |
| `AC-dm-drop-zone-themed` | `TC-dm-surface-drop-zone` | Not started |
| `AC-dm-dialog-themed` | `TC-dm-surface-dialogs` | Not started |
| `AC-dm-no-fouc` | `TC-dm-no-fouc-dark`, `TC-dm-no-fouc-system` | Not started |
| `AC-dm-localstorage-unavailable` | `TC-dm-persist-no-localstorage` | Not started |
| `AC-dm-keyboard-toggle` | `TC-dm-toggle-keyboard`, `TC-dm-a11y-toggle-aria` | Not started |

### Functional Requirement Coverage

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-dm-system-preference` | `TC-dm-system-dark-default`, `TC-dm-system-light-default`, `TC-dm-system-no-preference` | Not started |
| `FR-dm-manual-toggle` | `TC-dm-toggle-to-dark`, `TC-dm-toggle-to-light`, `TC-dm-toggle-to-system`, `TC-dm-toggle-keyboard` | Not started |
| `FR-dm-persistence` | `TC-dm-persist-dark-reload`, `TC-dm-persist-system-reload`, `TC-dm-persist-no-localstorage`, `TC-dm-persist-corrupt-value` | Not started |
| `FR-dm-realtime-tracking` | `TC-dm-realtime-os-dark-to-light`, `TC-dm-realtime-manual-ignores-os` | Not started |
| `FR-dm-full-surface-coverage` | `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar`, `TC-dm-surface-drop-zone`, `TC-dm-surface-diff-view`, `TC-dm-surface-dialogs`, `TC-dm-surface-toasts` | Not started |
| `FR-dm-css-custom-properties` | `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar` | Not started |

### Non-Functional Requirement Coverage

| Requirement | Test Cases | Status |
|---|---|---|
| `NFR-dm-no-fouc` | `TC-dm-no-fouc-dark`, `TC-dm-no-fouc-system` | Not started |
| `NFR-dm-smooth-transition` | `TC-dm-transition-smooth`, `TC-dm-transition-no-initial` | Not started |
| `NFR-dm-syntax-highlight-both-themes` | `TC-dm-syntax-dark-readable`, `TC-dm-syntax-light-readable`, `TC-dm-syntax-no-reparse` | Not started |
| `NFR-dm-contrast-ratios` | `TC-dm-a11y-contrast-light`, `TC-dm-a11y-contrast-dark` | Not started |
| `NFR-dm-no-performance-impact` | `TC-dm-perf-no-regression` | Not started |

---

## Test Cases

---

### System Detection Tests

---

#### `TC-dm-system-dark-default`: First visit with dark OS loads dark theme

- **Type**: E2E
- **Covers**: `AC-dm-default-respects-system`, `FR-dm-system-preference`
- **Preconditions**: No `localStorage` entry for `shepherd-theme` exists. OS appearance is set to dark mode. Browser `prefers-color-scheme: dark` reports `true`.
- **Steps**:
  1. Clear `localStorage` of any `shepherd-theme` key.
  2. Set the emulated `prefers-color-scheme` to `dark` (via browser DevTools or test harness).
  3. Navigate to the application URL.
  4. Observe the rendered page on first paint.
  5. Inspect the `<html>` element for the `data-theme` attribute.
  6. Inspect the ThemeToggle component.
- **Expected Result**:
  - The `<html>` element has `data-theme="dark"`.
  - All visible surfaces render in dark mode colors (dark backgrounds, light text).
  - The ThemeToggle shows "System" as the active selection (since no explicit override was stored).
  - No intermediate flash of light theme is visible.
- **Edge Cases**:
  - If `prefers-color-scheme: dark` is set after initial load but before React hydration: the blocking script should still have applied dark theme before paint.

---

#### `TC-dm-system-light-default`: First visit with light OS loads light theme

- **Type**: E2E
- **Covers**: `AC-dm-default-light-system`, `FR-dm-system-preference`
- **Preconditions**: No `localStorage` entry for `shepherd-theme` exists. OS appearance is set to light mode. Browser `prefers-color-scheme: dark` reports `false`.
- **Steps**:
  1. Clear `localStorage` of any `shepherd-theme` key.
  2. Set the emulated `prefers-color-scheme` to `light`.
  3. Navigate to the application URL.
  4. Observe the rendered page on first paint.
  5. Inspect the `<html>` element for the `data-theme` attribute.
  6. Inspect the ThemeToggle component.
- **Expected Result**:
  - The `<html>` element has `data-theme="light"`.
  - All visible surfaces render in light mode colors (white/light backgrounds, dark text).
  - The ThemeToggle shows "System" as the active selection.
  - No intermediate flash of dark theme is visible.

---

#### `TC-dm-system-no-preference`: OS reports no preference falls back to light

- **Type**: E2E
- **Covers**: `AC-dm-default-light-system`, `FR-dm-system-preference`
- **Preconditions**: No `localStorage` entry for `shepherd-theme` exists. OS does not express a color scheme preference (`prefers-color-scheme: no-preference` or media query returns `false` for both `dark` and `light`).
- **Steps**:
  1. Clear `localStorage` of any `shepherd-theme` key.
  2. Set the emulated `prefers-color-scheme` to `no-preference` (or ensure the `dark` media query returns `false`).
  3. Navigate to the application URL.
  4. Observe the rendered page on first paint.
  5. Inspect the `<html>` element for the `data-theme` attribute.
- **Expected Result**:
  - The `<html>` element has `data-theme="light"`.
  - All surfaces render in light mode (light is the default fallback when no preference is detected).
  - The ThemeToggle shows "System" as the active selection.

---

### Manual Toggle Tests

---

#### `TC-dm-toggle-to-dark`: Switch to dark from light

- **Type**: E2E
- **Covers**: `AC-dm-toggle-to-dark`, `FR-dm-manual-toggle`
- **Preconditions**: Application is loaded in light mode (either via system detection or manual selection). A file is loaded in the code viewer.
- **Steps**:
  1. Verify the app is in light mode (`data-theme="light"` on `<html>`).
  2. Locate the ThemeToggle in the toolbar.
  3. Click the "Dark" segment (moon icon).
  4. Observe the theme change across all surfaces.
  5. Inspect the `<html>` element for the `data-theme` attribute.
  6. Inspect `localStorage` for the `shepherd-theme` key.
- **Expected Result**:
  - The `<html>` element changes to `data-theme="dark"`.
  - All UI surfaces transition smoothly to dark mode colors (dark backgrounds, light text).
  - The ThemeToggle indicates "Dark" as the active selection (blue background on the moon segment, `aria-checked="true"`).
  - `localStorage` key `shepherd-theme` is set to `"dark"`.
  - The transition is smooth (no abrupt color snap).

---

#### `TC-dm-toggle-to-light`: Switch to light from dark

- **Type**: E2E
- **Covers**: `AC-dm-toggle-to-light`, `FR-dm-manual-toggle`
- **Preconditions**: Application is loaded in dark mode. A file is loaded in the code viewer.
- **Steps**:
  1. Verify the app is in dark mode (`data-theme="dark"` on `<html>`).
  2. Locate the ThemeToggle in the toolbar.
  3. Click the "Light" segment (sun icon).
  4. Observe the theme change across all surfaces.
  5. Inspect the `<html>` element for the `data-theme` attribute.
  6. Inspect `localStorage` for the `shepherd-theme` key.
- **Expected Result**:
  - The `<html>` element changes to `data-theme="light"`.
  - All UI surfaces transition smoothly to light mode colors.
  - The ThemeToggle indicates "Light" as the active selection.
  - `localStorage` key `shepherd-theme` is set to `"light"`.

---

#### `TC-dm-toggle-to-system`: Switch to system follows OS preference

- **Type**: E2E
- **Covers**: `AC-dm-toggle-to-system`, `FR-dm-manual-toggle`
- **Preconditions**: User has previously selected "Dark" from the ThemeToggle. OS is set to light mode.
- **Steps**:
  1. Verify `localStorage` key `shepherd-theme` is `"dark"` and the app is in dark mode.
  2. Click the "System" segment (monitor icon) in the ThemeToggle.
  3. Observe the theme change.
  4. Inspect the `<html>` element for the `data-theme` attribute.
  5. Inspect `localStorage` for the `shepherd-theme` key.
- **Expected Result**:
  - The app switches to light mode (matching the OS light preference).
  - The `<html>` element has `data-theme="light"`.
  - The ThemeToggle indicates "System" as the active selection.
  - `localStorage` key `shepherd-theme` is set to `"system"`.
  - Real-time OS tracking is re-enabled (verified in `TC-dm-realtime-os-dark-to-light`).

---

#### `TC-dm-toggle-keyboard`: Keyboard navigation of theme toggle

- **Type**: E2E
- **Covers**: `AC-dm-keyboard-toggle`, `FR-dm-manual-toggle`
- **Preconditions**: Application is loaded. Current theme is "Light" (active selection is the sun segment).
- **Steps**:
  1. Press `Tab` repeatedly to move focus through toolbar controls until the ThemeToggle group receives focus.
  2. Verify focus lands on the currently active segment (Light / sun).
  3. Press `ArrowRight` to move focus to the "Dark" segment.
  4. Verify the theme changes to dark mode immediately on arrow key press (radio group activation pattern).
  5. Press `ArrowRight` again to move focus to the "System" segment.
  6. Verify the theme changes to match the OS preference.
  7. Press `ArrowLeft` twice to cycle back to "Light".
  8. Press `Tab` to move focus out of the ThemeToggle to the next toolbar control.
- **Expected Result**:
  - The ThemeToggle is reachable via `Tab` key.
  - `ArrowLeft` and `ArrowRight` navigate between segments and activate them immediately.
  - Each segment shows a visible focus ring (2px solid `var(--color-primary)`, offset 2px) when focused.
  - `Tab` from within the group moves focus to the next toolbar control (not the next segment).
  - The theme actually changes with each arrow key activation.

---

### Persistence Tests

---

#### `TC-dm-persist-dark-reload`: Dark preference survives page reload

- **Type**: E2E
- **Covers**: `AC-dm-persistence-survives-reload`, `FR-dm-persistence`
- **Preconditions**: Application is loaded.
- **Steps**:
  1. Click the "Dark" segment in the ThemeToggle.
  2. Verify `localStorage` key `shepherd-theme` is `"dark"`.
  3. Reload the page (full browser refresh).
  4. Observe the page immediately on load (before React hydrates).
  5. After full load, inspect the ThemeToggle.
- **Expected Result**:
  - The page loads directly in dark mode from the very first paint. No flash of light mode.
  - The `<html>` element has `data-theme="dark"` before React mounts.
  - After hydration, the ThemeToggle shows "Dark" as the active selection.

---

#### `TC-dm-persist-system-reload`: System preference survives page reload

- **Type**: E2E
- **Covers**: `AC-dm-persistence-system-survives-reload`, `FR-dm-persistence`
- **Preconditions**: OS is set to dark mode. Application is loaded.
- **Steps**:
  1. Click the "System" segment in the ThemeToggle (or ensure it is already selected).
  2. Verify `localStorage` key `shepherd-theme` is `"system"`.
  3. Reload the page.
  4. Observe the page immediately on load.
  5. After full load, inspect the ThemeToggle.
- **Expected Result**:
  - The page loads in dark mode (from OS detection) from the first paint. No flash of light mode.
  - The `<html>` element has `data-theme="dark"` (resolved from OS) before React mounts.
  - After hydration, the ThemeToggle shows "System" as the active selection (not "Dark").

---

#### `TC-dm-persist-no-localstorage`: Graceful fallback without localStorage

- **Type**: E2E
- **Covers**: `AC-dm-localstorage-unavailable`, `FR-dm-persistence`
- **Preconditions**: OS is set to dark mode. `localStorage` is unavailable (simulated via browser override, private browsing restriction, or test mock that throws on `localStorage.getItem`).
- **Steps**:
  1. Disable or mock `localStorage` so that reads throw an exception or return `null`.
  2. Navigate to the application URL.
  3. Observe the initial render.
  4. Click the "Light" segment in the ThemeToggle.
  5. Verify the theme switches to light for the current session.
  6. Reload the page.
  7. Observe the initial render after reload.
- **Expected Result**:
  - On initial load, the app falls back to OS preference detection (dark mode, since OS is dark).
  - The ThemeToggle shows "System" as the active selection.
  - No error messages or console warnings are displayed to the user.
  - The toggle still works for the current session -- clicking "Light" switches to light mode in memory.
  - After reload, the app falls back to OS detection again (dark mode). The "Light" selection was not persisted.

---

#### `TC-dm-persist-corrupt-value`: Invalid localStorage value falls back to system

- **Type**: Integration
- **Covers**: `FR-dm-persistence`
- **Preconditions**: OS is set to light mode.
- **Steps**:
  1. Manually set `localStorage` key `shepherd-theme` to an invalid value (e.g., `"banana"`, `""`, `"null"`, or `"DARK"`).
  2. Navigate to the application URL.
  3. Observe the initial render.
  4. Inspect the `<html>` element.
  5. Inspect the ThemeToggle after full load.
- **Expected Result**:
  - The blocking script treats the invalid value as if no preference was stored.
  - The app falls back to OS preference detection (light mode, since OS is light).
  - `data-theme="light"` is set on `<html>`.
  - The ThemeToggle shows "System" as the active selection.
  - No JavaScript errors are thrown.

---

### Real-time Tracking Tests

---

#### `TC-dm-realtime-os-dark-to-light`: OS switches while on system mode

- **Type**: E2E
- **Covers**: `AC-dm-realtime-os-change`, `FR-dm-realtime-tracking`
- **Preconditions**: ThemeToggle is set to "System". OS is currently set to light mode. App is rendering in light mode.
- **Steps**:
  1. Verify the app is in light mode with "System" selected.
  2. Switch the OS appearance to dark mode (emulated via `matchMedia` change event or browser DevTools).
  3. Observe the app without reloading.
  4. Inspect the `<html>` element.
  5. Inspect the ThemeToggle.
  6. Switch OS back to light mode.
  7. Observe the app again.
- **Expected Result**:
  - When OS switches to dark: the app transitions smoothly to dark mode in real time, without a page reload.
  - `data-theme` on `<html>` changes from `"light"` to `"dark"`.
  - The ThemeToggle still shows "System" as the active selection (the preference did not change, only the resolved theme).
  - No `localStorage` write occurs (stored value remains `"system"`).
  - When OS switches back to light: the app transitions smoothly back to light mode.

---

#### `TC-dm-realtime-manual-ignores-os`: Manual override ignores OS changes

- **Type**: E2E
- **Covers**: `AC-dm-manual-ignores-os`, `FR-dm-realtime-tracking`
- **Preconditions**: User has explicitly selected "Light" from the ThemeToggle. OS is set to light mode.
- **Steps**:
  1. Verify the app is in light mode with "Light" selected and `localStorage` `shepherd-theme` is `"light"`.
  2. Switch the OS appearance to dark mode (emulated via `matchMedia` change event).
  3. Wait 1 second and observe the app.
  4. Inspect the `<html>` element.
- **Expected Result**:
  - The app remains in light mode. No visual change occurs.
  - `data-theme` remains `"light"` on `<html>`.
  - The ThemeToggle still shows "Light" as active.
  - The `matchMedia` change event is received but ignored because the stored preference is an explicit override (`"light"`), not `"system"`.

---

### FOUC Tests

---

#### `TC-dm-no-fouc-dark`: No flash of light theme when loading in dark mode

- **Type**: E2E
- **Covers**: `AC-dm-no-fouc`, `NFR-dm-no-fouc`
- **Preconditions**: `localStorage` key `shepherd-theme` is set to `"dark"`.
- **Steps**:
  1. Set `localStorage` key `shepherd-theme` to `"dark"`.
  2. Use a performance recording tool (e.g., Playwright `page.screenshot` on `'domcontentloaded'` event, or Chrome DevTools Performance trace with screenshots enabled).
  3. Navigate to the application URL.
  4. Capture a screenshot at the earliest visible paint.
  5. Capture another screenshot after full React hydration.
- **Expected Result**:
  - The earliest visible paint shows a dark background. There is no frame showing a white/light background.
  - The blocking `<script>` in `<head>` has set `data-theme="dark"` on `<html>` before any CSS or content paints.
  - No CSS transition animation is visible on the initial load (the `data-theme-transition` attribute is not set).
  - Both screenshots (early paint and post-hydration) show consistent dark mode styling.

---

#### `TC-dm-no-fouc-system`: No flash when system preference is dark

- **Type**: E2E
- **Covers**: `AC-dm-no-fouc`, `NFR-dm-no-fouc`
- **Preconditions**: `localStorage` key `shepherd-theme` is set to `"system"` (or absent entirely). OS is set to dark mode.
- **Steps**:
  1. Set `localStorage` key `shepherd-theme` to `"system"` (or clear it).
  2. Set emulated `prefers-color-scheme` to `dark`.
  3. Use a performance recording tool to capture the earliest visible paint.
  4. Navigate to the application URL.
  5. Capture screenshots at earliest paint and after full hydration.
- **Expected Result**:
  - The earliest visible paint shows a dark background. No intermediate flash of light theme.
  - The blocking script detects OS dark preference and sets `data-theme="dark"` before paint.
  - Both screenshots show consistent dark mode.

---

### Surface Coverage Tests

---

#### `TC-dm-surface-toolbar`: Toolbar themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-all-surfaces-themed`, `FR-dm-full-surface-coverage`, `FR-dm-css-custom-properties`
- **Preconditions**: Application is in dark mode. A file is loaded.
- **Steps**:
  1. Switch to dark mode via the ThemeToggle.
  2. Inspect the toolbar visually: background, text color, button labels, icon colors, bottom border.
  3. Hover over toolbar buttons and observe hover states.
  4. Inspect the view mode toggle (File/Diff) active and inactive segment colors.
  5. Verify the ThemeToggle itself renders with dark mode segment styling.
  6. Switch to light mode and repeat the visual inspection.
- **Expected Result**:
  - **Dark mode**: Toolbar background is `#0F172A` (slate-950). Text and icons are light (`#E2E8F0`). Bottom border is `#334155`. Button hover backgrounds are `#1E293B`. View mode toggle inactive segments have dark background.
  - **Light mode**: Toolbar background is `#FFFFFF`. Text is `#1E293B`. Bottom border is `#E2E8F0`.
  - All colors are applied via CSS custom properties (inspect computed styles to verify `var(--color-toolbar-bg)` etc.).
  - No hardcoded color values remain on toolbar elements.

---

#### `TC-dm-surface-code-viewer`: Code viewer themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-all-surfaces-themed`, `FR-dm-full-surface-coverage`, `FR-dm-css-custom-properties`
- **Preconditions**: Application is in dark mode. A TypeScript file is loaded with comments placed on specific lines.
- **Steps**:
  1. Switch to dark mode.
  2. Inspect the code viewer: background color, line number color, file header background and border.
  3. Hover over a line and observe the hover background color.
  4. Select a range of lines and observe the selection highlight color.
  5. Click on a comment gutter indicator and observe the focused line highlight.
  6. Inspect the gutter comment dots (blue circles).
  7. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Code background is `#0F172A`. Line numbers are `#475569`. File header is `#1E293B` with `#334155` border. Line hover is `#1E293B`. Selection highlight is `#1E3A5F`. Focused line is `#422006`. Gutter dots are `#60A5FA`.
  - **Light mode**: Code background is `#FFFFFF`. Line numbers are `#94A3B8`. File header is `#F8FAFC` with `#E2E8F0` border. Gutter dots are `#3B82F6`.

---

#### `TC-dm-surface-comments`: Comment bubbles themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-all-surfaces-themed`, `FR-dm-full-surface-coverage`, `FR-dm-css-custom-properties`
- **Preconditions**: Application is in dark mode. A file is loaded with at least two comments placed.
- **Steps**:
  1. Switch to dark mode.
  2. Inspect a comment bubble: background, left border, body text, line label text.
  3. Hover over a comment to reveal edit/delete action icons. Inspect their color.
  4. Click on a comment to focus it. Inspect the focused background color.
  5. Open the inline comment editor (click a line's gutter "+" icon). Inspect the editor: background, border, textarea background, placeholder text, button styles, box shadow.
  6. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Comment background is `#0C2D48`. Left border is `#2563EB`. Body text is `#E2E8F0`. Label text is `#94A3B8`. Focused background is `#1E3A5F`. Editor background is `#1E293B`, border `#2563EB`, textarea background `#0F172A`, shadow with higher opacity.
  - **Light mode**: Comment background is `#F0F9FF`. Left border is `#3B82F6`. Body text is `#1E293B`.

---

#### `TC-dm-surface-sidebar`: Sidebar themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-all-surfaces-themed`, `FR-dm-full-surface-coverage`, `FR-dm-css-custom-properties`
- **Preconditions**: Application is in dark mode. A file is loaded. Sidebar is visible with preamble and prompt preview sections.
- **Steps**:
  1. Switch to dark mode.
  2. Inspect the sidebar panel background.
  3. Inspect the preamble text area: background, text color, border.
  4. Inspect the collapsed preamble bar (if applicable).
  5. Inspect the prompt preview panel: background, text color, border.
  6. Inspect section labels/headers.
  7. When no comments exist, inspect the empty state prompt preview (dashed border, muted text).
  8. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Sidebar background is `#0F172A`. Preamble textarea background is `#1E293B`. Prompt preview background is `#020617` (deeper than surrounding). Preview text is `#CBD5E1`. Empty preview border is dashed `#334155`.
  - **Light mode**: Sidebar background is `#FFFFFF`. Preamble textarea is white. Prompt preview is `#1E293B` (dark terminal look).

---

#### `TC-dm-surface-drop-zone`: Drop zone themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-drop-zone-themed`, `FR-dm-full-surface-coverage`
- **Preconditions**: Application is in dark mode. No file is loaded (empty state shows drop zone).
- **Steps**:
  1. Switch to dark mode.
  2. Observe the drop zone: container background, dashed border color, upload icon color, instructional text color.
  3. Inspect the "Choose file" and "Paste content" button styles.
  4. Drag a file over the drop zone and observe the drag-hover state: background color change, border becoming solid.
  5. Release the file outside the zone (or press Escape) to dismiss the drag-hover state.
  6. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Background is `#0F172A`. Dashed border is `#334155`. Icon is `#475569`. Text is `#94A3B8`. Drag-hover background is `#172554` with solid blue border `#3B82F6`.
  - **Light mode**: Background is `#FFFFFF`. Dashed border is `#CBD5E1`. Icon is `#94A3B8`. Drag-hover background is `#EFF6FF` with border `#2563EB`.

---

#### `TC-dm-surface-diff-view`: Diff view themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-diff-view-themed`, `FR-dm-full-surface-coverage`
- **Preconditions**: Application is in dark mode. Diff view is active (user has loaded both original and modified files, or a diff is available). The diff contains added lines, removed lines, unchanged context lines, and at least one collapsed section.
- **Steps**:
  1. Switch to dark mode.
  2. Switch to Diff view via the File/Diff toggle.
  3. Inspect added lines: background color and `+` indicator color.
  4. Inspect removed lines: background color and `-` indicator color.
  5. Inspect unchanged context lines: background color.
  6. Inspect a collapsed section separator: background, dashed border, text, "Expand" link.
  7. Hover over a collapsed section and inspect the hover state.
  8. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Added line background is `#052E16`, `+` indicator is `#4ADE80`. Removed line background is `#450A0A`, `-` indicator is `#FCA5A5`. Context background is `#0F172A`. Collapsed separator background is `#1E293B` with dashed border `#334155`, text `#94A3B8`, hover background `#172554`.
  - **Light mode**: Added is `#F0FDF4` / `#15803D`. Removed is `#FEF2F2` / `#B91C1C`. Context is `#FFFFFF`. Collapsed is `#F8FAFC` / `#CBD5E1`.

---

#### `TC-dm-surface-dialogs`: Dialogs themed correctly in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-dialog-themed`, `FR-dm-full-surface-coverage`
- **Preconditions**: Application is in dark mode. A file is loaded with at least one comment placed.
- **Steps**:
  1. Switch to dark mode.
  2. Click the "Clear" button in the toolbar to trigger the confirmation dialog.
  3. Inspect the dialog: backdrop overlay, dialog background, box shadow, title text, body text, cancel button, destructive (confirm) button.
  4. Click "Cancel" to dismiss.
  5. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Backdrop is `rgba(0,0,0,0.7)`. Dialog background is `#1E293B`. Title is `#F1F5F9`. Body text is `#94A3B8`. Destructive button is `#EF4444` with white text. Shadow uses higher opacity (`rgba(0,0,0,0.5)`).
  - **Light mode**: Backdrop is `rgba(0,0,0,0.5)`. Dialog background is `#FFFFFF`. Title is `#1E293B`. Body text is `#475569`. Destructive button is `#DC2626`.

---

#### `TC-dm-surface-toasts`: Toast notifications themed correctly in dark mode

- **Type**: Manual
- **Covers**: `FR-dm-full-surface-coverage`
- **Preconditions**: Application is in dark mode. A file is loaded with comments.
- **Steps**:
  1. Switch to dark mode.
  2. Click the "Copy" button to copy the generated prompt.
  3. Observe the "Copied to clipboard" toast notification.
  4. Inspect the toast: background color, text color.
  5. Trigger an error toast if possible (e.g., attempt to load an invalid file for an error notification).
  6. Switch to light mode and repeat.
- **Expected Result**:
  - **Dark mode**: Success toast background is `#F1F5F9` (light), text is `#0F172A` (dark) -- inverted to maintain contrast against the dark page.
  - **Light mode**: Success toast background is `#1E293B` (dark), text is `#FFFFFF` (white).
  - Toast colors correctly invert between themes to float visually above the page background.

---

### Syntax Highlighting Tests

---

#### `TC-dm-syntax-dark-readable`: Syntax tokens are readable in dark mode

- **Type**: Manual
- **Covers**: `AC-dm-syntax-highlight-dark`, `NFR-dm-syntax-highlight-both-themes`
- **Preconditions**: A TypeScript file is loaded with representative syntax: keywords, strings, comments, types, function names, variables, numbers, operators.
- **Steps**:
  1. Switch to dark mode.
  2. Inspect the code viewer for syntax highlighting tokens.
  3. Verify keywords (e.g., `function`, `const`, `if`) are visually distinct from variable names.
  4. Verify strings are visually distinct from code.
  5. Verify comments are visually distinct but less prominent.
  6. Verify all tokens are clearly visible against the dark background (`#0F172A`).
  7. Check for any tokens that blend into the background or become invisible.
- **Expected Result**:
  - Shiki `github-dark` theme is active. Token colors are appropriate for a dark background.
  - All token types are distinguishable from each other and from the background.
  - No tokens are invisible, near-invisible, or have insufficient contrast against the dark background.
  - Code is comfortable to read in dark mode.

---

#### `TC-dm-syntax-light-readable`: Syntax tokens are readable in light mode

- **Type**: Manual
- **Covers**: `AC-dm-syntax-highlight-light`, `NFR-dm-syntax-highlight-both-themes`
- **Preconditions**: Same TypeScript file as `TC-dm-syntax-dark-readable`.
- **Steps**:
  1. Switch to light mode.
  2. Inspect the code viewer for syntax highlighting tokens.
  3. Verify the same token categories as in the dark mode test.
  4. Check for any tokens that blend into the white background.
- **Expected Result**:
  - Shiki `github-light` theme is active. Token colors are appropriate for a white background.
  - All token types are distinguishable from each other and from the background.
  - No tokens are invisible or have insufficient contrast against the white background.

---

#### `TC-dm-syntax-no-reparse`: Theme switch does not re-parse file

- **Type**: Integration
- **Covers**: `NFR-dm-syntax-highlight-both-themes`
- **Preconditions**: A large TypeScript file (1000+ lines) is loaded. Browser DevTools Performance panel is open.
- **Steps**:
  1. Load the file and wait for syntax highlighting to complete.
  2. Start a Performance recording in DevTools.
  3. Toggle from light to dark mode via the ThemeToggle.
  4. Stop the Performance recording.
  5. Examine the trace for Shiki-related JavaScript execution (calls to `codeToHtml`, `codeToTokens`, or similar Shiki parsing functions).
- **Expected Result**:
  - The theme switch does not trigger any re-parsing of the file by Shiki.
  - The Shiki dual-theme CSS variables mode is used: both light and dark token colors are present in the DOM, and a CSS attribute swap (`data-theme`) determines which set is visible.
  - The toggle's JavaScript execution should be minimal (attribute change + localStorage write only).
  - No significant frame drops or scripting spikes during the toggle.

---

### Transition Tests

---

#### `TC-dm-transition-smooth`: Toggle produces smooth CSS transition

- **Type**: E2E
- **Covers**: `AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `NFR-dm-smooth-transition`
- **Preconditions**: Application is loaded in light mode with a file and comments visible.
- **Steps**:
  1. Open DevTools and observe the `<html>` element attributes.
  2. Click the "Dark" segment in the ThemeToggle.
  3. Observe whether the `data-theme-transition` attribute is momentarily added to `<html>`.
  4. Observe the visual transition: background colors, text colors, border colors should animate over approximately 150ms.
  5. Verify no layout shifts occur during the transition (element positions and sizes remain stable).
  6. Click "Light" to toggle back and observe the same transition behavior.
- **Expected Result**:
  - The `data-theme-transition` attribute is added to `<html>` immediately before the `data-theme` attribute changes.
  - Colors animate smoothly over ~150ms with an ease timing function.
  - The `data-theme-transition` attribute is removed after ~200ms.
  - No layout shifts, jumps, or flickering occur during the transition.
  - Transitions affect `background-color`, `color`, `border-color`, and `box-shadow` only.

---

#### `TC-dm-transition-no-initial`: No transition animation on initial page load

- **Type**: E2E
- **Covers**: `NFR-dm-smooth-transition`
- **Preconditions**: `localStorage` key `shepherd-theme` is set to `"dark"`.
- **Steps**:
  1. Set `localStorage` key `shepherd-theme` to `"dark"`.
  2. Navigate to the application URL.
  3. Use a performance recording tool with screenshots to capture the initial load sequence.
  4. Inspect the `<html>` element during load for the `data-theme-transition` attribute.
- **Expected Result**:
  - The initial page load applies dark mode instantly with no CSS transition animation.
  - The `data-theme-transition` attribute is NOT present on `<html>` during initial load.
  - The user sees a fully dark page from the first paint with no fade-in or color animation.

---

### Performance Tests

---

#### `TC-dm-perf-no-regression`: Existing performance benchmarks are unchanged

- **Type**: Integration
- **Covers**: `NFR-dm-no-performance-impact`
- **Preconditions**: Existing performance benchmarks are baselined (initial render time, prompt generation time, large file scrolling performance as defined in `NFR-crp-render-time`, `NFR-crp-prompt-gen-time`, `NFR-crp-large-file-perf`).
- **Steps**:
  1. Run the existing performance benchmark suite in light mode.
  2. Record the results: initial render time, prompt generation time, large file scroll FPS.
  3. Switch to dark mode.
  4. Run the same benchmark suite.
  5. Compare results between light and dark mode and against pre-dark-mode baselines.
- **Expected Result**:
  - Initial render time remains within the threshold defined by `NFR-crp-render-time` in both themes.
  - Prompt generation time remains within the threshold defined by `NFR-crp-prompt-gen-time`.
  - Large file scrolling performance remains within the threshold defined by `NFR-crp-large-file-perf`.
  - No measurable degradation introduced by the CSS custom property theming system.
  - Dark mode and light mode benchmarks are within acceptable variance of each other.

---

### Accessibility Tests

---

#### `TC-dm-a11y-contrast-light`: Light theme meets WCAG AA contrast ratios

- **Type**: Manual
- **Covers**: `NFR-dm-contrast-ratios`
- **Preconditions**: Application is in light mode. A file is loaded with comments, sidebar visible, and full UI populated.
- **Steps**:
  1. Switch to light mode.
  2. Use an accessibility auditing tool (e.g., Axe DevTools, Lighthouse accessibility audit, or manual contrast checker).
  3. Check primary text (`#1E293B`) against backgrounds (`#FFFFFF`): expect >= 4.5:1.
  4. Check secondary text (`#475569`) against backgrounds (`#FFFFFF`): expect >= 4.5:1.
  5. Check muted text (`#94A3B8`) against backgrounds (`#FFFFFF`): expect >= 3:1 (used for UI components and large text only).
  6. Check diff indicators: `+` (`#15803D`) against added line bg (`#F0FDF4`): expect >= 4.5:1. `-` (`#B91C1C`) against removed line bg (`#FEF2F2`): expect >= 4.5:1.
  7. Check interactive elements: primary button text (`#FFFFFF`) against primary bg (`#2563EB`): expect >= 4.5:1.
  8. Check comment text (`#1E293B`) against comment bg (`#F0F9FF`): expect >= 4.5:1.
- **Expected Result**:
  - All normal text meets WCAG 2.1 AA minimum of 4.5:1 contrast ratio.
  - Large text and UI components meet the 3:1 minimum.
  - No accessibility violations are flagged by the auditing tool related to color contrast.

---

#### `TC-dm-a11y-contrast-dark`: Dark theme meets WCAG AA contrast ratios

- **Type**: Manual
- **Covers**: `NFR-dm-contrast-ratios`
- **Preconditions**: Application is in dark mode. A file is loaded with comments, sidebar visible, and full UI populated.
- **Steps**:
  1. Switch to dark mode.
  2. Use an accessibility auditing tool.
  3. Check primary text (`#E2E8F0`) against dark bg (`#0F172A`): expect >= 4.5:1 (actual ~13.1:1).
  4. Check secondary text (`#94A3B8`) against dark bg (`#0F172A`): expect >= 4.5:1 (actual ~5.6:1).
  5. Check muted text (`#64748B`) against dark bg (`#0F172A`): expect >= 3:1 (actual ~3.4:1, UI component threshold).
  6. Check line numbers (`#475569`) against dark bg (`#0F172A`): expect >= 3:1 (actual ~3.1:1, UI component).
  7. Check diff indicators: `+` (`#4ADE80`) against added bg (`#052E16`): expect >= 4.5:1 (actual ~6.3:1). `-` (`#FCA5A5`) against removed bg (`#450A0A`): expect >= 4.5:1 (actual ~5.1:1).
  8. Check comment text (`#E2E8F0`) against comment bg (`#0C2D48`): expect >= 4.5:1 (actual ~10.2:1).
  9. Check dialog body text (`#94A3B8`) against dialog bg (`#1E293B`): expect >= 4.5:1 (actual ~4.6:1).
  10. Check primary blue (`#3B82F6`) against dark bg (`#0F172A`): expect >= 3:1 for interactive components (actual ~4.7:1).
- **Expected Result**:
  - All dark mode color pairings meet WCAG 2.1 AA requirements.
  - Muted text tokens are only used for elements qualifying as UI components or large text (3:1 threshold).
  - No contrast violations reported by the auditing tool.

---

#### `TC-dm-a11y-toggle-aria`: ThemeToggle has correct ARIA attributes

- **Type**: Integration
- **Covers**: `AC-dm-keyboard-toggle`
- **Preconditions**: Application is loaded. ThemeToggle is visible.
- **Steps**:
  1. Inspect the ThemeToggle in the DOM.
  2. Verify the outer container has `role="radiogroup"` and `aria-label="Theme"`.
  3. Verify each segment has `role="radio"`.
  4. Verify the active segment has `aria-checked="true"` and the other two have `aria-checked="false"`.
  5. Verify each segment has an appropriate `aria-label`:
     - Light segment: `"Light mode"`
     - Dark segment: `"Dark mode"`
     - System segment: `"System theme"`
  6. Click the "Dark" segment.
  7. Verify `aria-checked` values update: "Dark" becomes `true`, "Light" becomes `false`.
  8. Verify the focus ring is visible when using keyboard navigation (2px solid focus ring with 2px offset).
- **Expected Result**:
  - The ThemeToggle implements the WAI-ARIA radio group pattern correctly.
  - All `role`, `aria-label`, and `aria-checked` attributes are present and correct.
  - `aria-checked` updates dynamically when the selection changes.
  - Screen readers can identify the toggle as "Theme" with three options and the current selection.

---

## Edge Cases & Error Scenarios

---

### localStorage is unavailable

- **Trigger**: The user is in a browser where `localStorage` throws (e.g., certain private browsing modes in older Safari, or `localStorage` is disabled in browser settings).
- **Expected behavior**: The blocking script catches the exception during `localStorage.getItem()`, falls back to `prefers-color-scheme` detection, and renders the correct theme. The toggle works for the current session in memory only. No errors shown to the user.
- **Test case**: `TC-dm-persist-no-localstorage`

### Corrupt localStorage value

- **Trigger**: The `shepherd-theme` key in `localStorage` contains an invalid value (e.g., `"banana"`, `""`, `"DARK"`, `"undefined"`, a JSON object, or a very long string).
- **Expected behavior**: The blocking script treats any value other than `"light"`, `"dark"`, or `"system"` as invalid. It falls back to `prefers-color-scheme` detection. No JavaScript error is thrown. On next toggle interaction, the correct value is written.
- **Test case**: `TC-dm-persist-corrupt-value`

### Rapid toggling

- **Trigger**: The user clicks the ThemeToggle segments rapidly in quick succession (e.g., Light -> Dark -> System -> Light within 500ms).
- **Expected behavior**: Each click updates the `data-theme` attribute and triggers a CSS transition. The final applied theme matches the last segment clicked. No visual glitches, uncaught exceptions, or stuck transition states occur. The `data-theme-transition` attribute cleanup (200ms timeout) handles overlapping transitions gracefully -- either the attribute stays present through all transitions or is re-added for each new one.
- **Test case**: Covered implicitly by `TC-dm-toggle-to-dark`, `TC-dm-toggle-to-light`, `TC-dm-toggle-to-system`. If rapid toggling reveals issues, a dedicated `TC-dm-rapid-toggle` should be created.

### OS preference changes during initial page load

- **Trigger**: The user's OS preference changes while the page is loading (after the blocking script runs but before React hydration completes).
- **Expected behavior**: The blocking script applies the theme based on the OS preference at the time it runs. If the OS changes between the blocking script and React hydration, the React app should reconcile by reading the current `matchMedia` value on mount and updating if necessary. The user may see a brief theme shift after hydration, which is acceptable since this is an extremely rare race condition.
- **Test case**: Covered implicitly by `TC-dm-realtime-os-dark-to-light` (which tests real-time tracking after mount).

### Theme preference set by another tab

- **Trigger**: The user has the app open in two tabs. They change the theme in tab A. Tab B has a `storage` event listener (if implemented).
- **Expected behavior**: The product spec does not require cross-tab synchronization. If tab B does not have a `storage` event listener, the theme in tab B will not update until the next page reload. This is acceptable behavior. If cross-tab sync is implemented as an enhancement, tab B should update to match tab A in real time.
- **Test case**: Not explicitly covered. This is a "nice to have" rather than a requirement.

---

## Regression Considerations

Dark mode introduces a theming layer that touches every visual surface. The following existing features are at risk of regression:

### Syntax Highlighting
- **Risk**: Shiki theme integration could break if the CSS variables mode is misconfigured. Tokens might all render as the same color, or the background override might fail.
- **What to verify**: `TC-dm-syntax-dark-readable`, `TC-dm-syntax-light-readable`, and all existing syntax highlighting test cases in `../qa/code-review-prompt.md` (e.g., `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`).

### Diff View Colors
- **Risk**: The diff view uses specific green/red tinted backgrounds for added/removed lines. Migrating these to CSS custom properties could break the color pairing or make added/removed lines indistinguishable.
- **What to verify**: `TC-dm-surface-diff-view` and existing diff view test cases in `../qa/diff-view.md`.

### Comment Visibility
- **Risk**: Comment bubbles have a tinted background distinct from the code background. In dark mode, the tinted background must remain visually distinguishable. If the comment background and code background are too similar, comments become invisible.
- **What to verify**: `TC-dm-surface-comments`. Ensure `#0C2D48` (comment bg) is visually distinct from `#0F172A` (code bg).

### Drop Zone States
- **Risk**: The drop zone has multiple states (empty, drag-hover, loading, error). Each state uses distinct colors. The migration to CSS custom properties must preserve all state distinctions.
- **What to verify**: `TC-dm-surface-drop-zone`. Test both the empty state and the drag-hover state.

### Dialog Readability
- **Risk**: Dialogs overlay the main content with a backdrop. The backdrop opacity, dialog background, and text colors must maintain readability in dark mode. A dark dialog on a dark backdrop with dark text would be unreadable.
- **What to verify**: `TC-dm-surface-dialogs`.

### Toast Notification Visibility
- **Risk**: Toast notifications use inverted colors between themes (dark toast on light page, light toast on dark page). Getting this inversion wrong could make toasts invisible against the page background.
- **What to verify**: `TC-dm-surface-toasts`.

### Scrollbar Styling
- **Risk**: Custom scrollbar styles (`::-webkit-scrollbar`) might not pick up CSS custom property changes in all browsers. The scrollbar could remain light-themed in dark mode.
- **What to verify**: Visual inspection during surface coverage tests. Scrollbar thumb should be `#475569` in dark mode, `#CBD5E1` in light mode.

### Performance Characteristics
- **Risk**: CSS custom property resolution adds a layer of indirection. While browser engines optimize this well, it could affect scroll performance on large files or animation smoothness.
- **What to verify**: `TC-dm-perf-no-regression`. Run existing performance benchmarks (render time, prompt generation, large file scrolling) with the theming system active.

### Inline Comment Editor
- **Risk**: The inline comment editor floats over the code viewer with a box shadow. In dark mode, the shadow opacity increases. If the editor background and the code background are too close, the editor may not stand out.
- **What to verify**: `TC-dm-surface-comments` (covers inline editor inspection).
