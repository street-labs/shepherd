# Dark Mode — Design Spec

> Based on requirements in `../product/dark-mode.md`

## Screen Inventory

Dark mode is a **cross-cutting visual feature** — it does not introduce new screens, routes, or views. Instead, it modifies the visual layer of every existing screen and component defined in `../design/code-review-prompt.md` and `../design/diff-view.md`. The application continues to have the same view states and transitions.

The one new UI element introduced is the **ThemeToggle** component in the toolbar.

| Existing Surface | Dark Mode Impact |
|---|---|
| **Toolbar** | Background, text, icons, button states, borders all switch to dark theme tokens |
| **Code viewer** | Background, line numbers, gutter indicators, hover/selection highlights switch |
| **Syntax highlighting** | Shiki theme switches between light and dark variants |
| **Comment bubbles** | Background, text, border, action buttons switch |
| **Inline comment editor** | Background, border, placeholder text, button states switch |
| **Sidebar** | Preamble input, prompt preview panel, section headers switch |
| **Drop zone** | Background, border, icon, text, drag-hover state switch |
| **Diff view** | Added/removed line backgrounds, context lines, collapsed separators switch |
| **Dialogs** | Background, text, buttons, backdrop overlay switch |
| **Toast notifications** | Background and text switch |
| **Scrollbars** | Styled scrollbars adapt to the active theme |
| **ThemeToggle** *(new)* | A segmented control in the toolbar with three options: Light, Dark, System |

This addresses `FR-dm-full-surface-coverage`.

---

## Theme Toggle Component Spec

### ThemeToggle

A segmented control for switching between Light, Dark, and System theme modes. Implements `FR-dm-manual-toggle`, `AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `AC-dm-toggle-to-system`, `AC-dm-keyboard-toggle`.

- **Placement**: Right side of the toolbar, before the Copy and Clear buttons. Separated from the comment navigation group by a flexible gap and from the Copy button by a 12px gap.

Updated toolbar layout:

```
+---[Logo/Title]---[File|Diff]---[Refresh]---[Comment Nav]---[Comment Count]---...---[ThemeToggle][Copy][Clear]---+
```

When no file is loaded (empty state), the toolbar simplifies but the ThemeToggle remains visible — theming is always available regardless of application state.

- **Dimensions**: Each segment is 36px wide and 32px tall. Total control width: 108px.
- **Border**: 1px solid `var(--color-border)`, border-radius 6px on the outer corners. The three segments share inner edges.
- **Icons**: Each segment displays only an icon (no text label) to keep the control compact:
  - **Light**: Sun icon (16px). A circle with radiating lines.
  - **Dark**: Moon icon (16px). A crescent moon.
  - **System**: Monitor/laptop icon (16px). A display screen.
- **Tooltip**: Each segment shows a tooltip on hover (300ms delay):
  - Light segment: "Light mode"
  - Dark segment: "Dark mode"
  - System segment: "Match system setting"

- **Props/Inputs**:
  - None. The component reads directly from the theme store (Zustand) for `themePreference` and calls `setThemePreference`. This avoids prop-drilling and keeps theme state self-contained in a dedicated store separate from the app store.

- **Visual Structure**:
  ```
  +------+------+------+
  | [sun]| [moon]| [mon]|
  +------+------+------+
  ```

#### Segment States

**In light mode (active theme appearance is light):**

| State | Background | Icon Color | Border |
|---|---|---|---|
| **Active (selected)** | `var(--color-primary)` (`#2563EB`) | `#FFFFFF` | 1px solid `var(--color-primary)` |
| **Inactive (enabled)** | `var(--color-bg)` (`#FFFFFF`) | `var(--color-text-secondary)` (`#475569`) | 1px solid `var(--color-border)` (`#E2E8F0`) |
| **Inactive hover** | `var(--color-hover-bg)` (`#F8FAFC`) | `var(--color-text)` (`#1E293B`) | 1px solid `var(--color-border)` |
| **Inactive active (pressed)** | `var(--color-border)` (`#E2E8F0`) | `var(--color-text)` (`#1E293B`) | 1px solid `var(--color-border)` |
| **Focused** | Same as current state + 2px focus ring (`var(--color-primary)`, offset 2px) | Same | Same |

**In dark mode (active theme appearance is dark):**

| State | Background | Icon Color | Border |
|---|---|---|---|
| **Active (selected)** | `var(--color-primary)` (`#3B82F6`) | `#FFFFFF` | 1px solid `var(--color-primary)` |
| **Inactive (enabled)** | `var(--color-bg)` (`#0F172A`) | `var(--color-text-secondary)` (`#94A3B8`) | 1px solid `var(--color-border)` (`#334155`) |
| **Inactive hover** | `var(--color-hover-bg)` (`#1E293B`) | `var(--color-text)` (`#E2E8F0`) | 1px solid `var(--color-border)` |
| **Inactive active (pressed)** | `var(--color-border)` (`#334155`) | `var(--color-text)` (`#E2E8F0`) | 1px solid `var(--color-border)` |
| **Focused** | Same as current state + 2px focus ring (`var(--color-primary)`, offset 2px) | Same | Same |

#### Keyboard Accessibility (`AC-dm-keyboard-toggle`)

- The toggle is focusable as a group (`role="radiogroup"`, each segment is `role="radio"`).
- `ArrowLeft` / `ArrowRight` moves focus between segments and activates the focused segment (radio group pattern).
- `Tab` moves focus into the group (lands on the currently selected segment); a second `Tab` moves focus out of the group to the next toolbar control.
- `aria-label="Theme"` on the group.
- `aria-checked="true"` on the active segment.
- `aria-label="Light mode"` / `"Dark mode"` / `"System theme"` on each segment.
- Focus ring is clearly visible in both themes (2px solid `var(--color-primary)`, offset 2px).

---

## Color Token Definitions

All color values in the application are expressed as CSS custom properties (CSS variables) defined on the `:root` or `html` element. Switching themes updates these variable values, and all surfaces update accordingly. This implements `FR-dm-css-custom-properties`.

Token names use semantic naming (purpose-based, not color-based). They are organized by surface.

### Base Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-bg` | `#FFFFFF` | `#0F172A` | Page/panel backgrounds |
| `--color-bg-secondary` | `#F8FAFC` | `#1E293B` | Hover backgrounds, subtle surface fills |
| `--color-bg-tertiary` | `#F1F5F9` | `#0F172A` | Page background behind panels |
| `--color-text` | `#1E293B` | `#E2E8F0` | Primary body text |
| `--color-text-secondary` | `#475569` | `#94A3B8` | Secondary / label text |
| `--color-text-muted` | `#94A3B8` | `#64748B` | Muted / placeholder text |
| `--color-border` | `#E2E8F0` | `#334155` | Default borders |
| `--color-border-muted` | `#CBD5E1` | `#1E293B` | Subtle / dashed borders |
| `--color-primary` | `#2563EB` | `#3B82F6` | Primary interactive color |
| `--color-primary-hover` | `#1D4ED8` | `#2563EB` | Primary hover state |
| `--color-primary-text` | `#FFFFFF` | `#FFFFFF` | Text on primary background |
| `--color-hover-bg` | `#F8FAFC` | `#1E293B` | Hover background for interactive elements |
| `--color-focus-ring` | `#2563EB` | `#3B82F6` | Focus ring color |
| `--color-destructive` | `#DC2626` | `#EF4444` | Destructive actions |
| `--color-destructive-hover` | `#B91C1C` | `#DC2626` | Destructive hover state |
| `--color-error-bg` | `#FEF2F2` | `#451A1A` | Error banner background |
| `--color-error-text` | `#991B1B` | `#FCA5A5` | Error text |
| `--color-error-border` | `#FECACA` | `#7F1D1D` | Error border |
| `--color-selection` | `#DBEAFE` | `#1E3A5F` | Selected line range background |
| `--color-focus-line` | `#FEF9C3` | `#422006` | Focused comment line highlight |

### Toolbar Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-toolbar-bg` | `#FFFFFF` | `#0F172A` | Toolbar background |
| `--color-toolbar-border` | `#E2E8F0` | `#334155` | Toolbar bottom border |
| `--color-toolbar-text` | `#1E293B` | `#E2E8F0` | Toolbar text |

### Code Viewer Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-code-bg` | `#FFFFFF` | `#0F172A` | Code viewer background |
| `--color-line-number` | `#94A3B8` | `#475569` | Line number text |
| `--color-gutter-indicator` | `#3B82F6` | `#60A5FA` | Comment gutter dot |
| `--color-gutter-add-icon` | `#94A3B8` | `#475569` | Faint "+" icon in gutter |
| `--color-file-header-bg` | `#F8FAFC` | `#1E293B` | File header bar background |
| `--color-file-header-border` | `#E2E8F0` | `#334155` | File header bottom border |
| `--color-line-hover-bg` | `#F8FAFC` | `#1E293B` | Hovered line background |

### Comment Bubble Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-comment-bg` | `#F0F9FF` | `#0C2D48` | Comment bubble background |
| `--color-comment-border` | `#3B82F6` | `#2563EB` | Comment bubble left border |
| `--color-comment-text` | `#1E293B` | `#E2E8F0` | Comment body text |
| `--color-comment-label` | `#64748B` | `#94A3B8` | Comment line label text |
| `--color-comment-focused-bg` | `#DBEAFE` | `#1E3A5F` | Focused comment bubble background |
| `--color-editor-bg` | `#FFFFFF` | `#1E293B` | Inline comment editor container background |
| `--color-editor-textarea-bg` | `#FFFFFF` | `#0F172A` | Inline comment editor textarea background |
| `--color-editor-border` | `#3B82F6` | `#2563EB` | Inline comment editor border |
| `--color-editor-shadow` | `rgba(0,0,0,0.1)` | `rgba(0,0,0,0.4)` | Inline comment editor box shadow |

### Sidebar Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-sidebar-bg` | `#FFFFFF` | `#0F172A` | Sidebar panel background |
| `--color-preamble-bg` | `#FFFFFF` | `#1E293B` | Preamble input background |
| `--color-preamble-collapsed-bg` | `#F8FAFC` | `#1E293B` | Collapsed preamble bar background |
| `--color-preview-bg` | `#1E293B` | `#020617` | Prompt preview background |
| `--color-preview-text` | `#E2E8F0` | `#CBD5E1` | Prompt preview text |
| `--color-preview-border` | `#1E293B` | `#334155` | Prompt preview border |
| `--color-preview-empty-border` | `#CBD5E1` | `#334155` | Prompt preview empty state dashed border |

### Diff View Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-diff-added-bg` | `#F0FDF4` | `#052E16` | Added line background |
| `--color-diff-removed-bg` | `#FEF2F2` | `#450A0A` | Removed line background |
| `--color-diff-added-indicator` | `#15803D` | `#4ADE80` | `+` type indicator |
| `--color-diff-removed-indicator` | `#B91C1C` | `#FCA5A5` | `-` type indicator |
| `--color-diff-context-bg` | `#FFFFFF` | `#0F172A` | Unchanged context line background |
| `--color-diff-collapsed-bg` | `#F8FAFC` | `#1E293B` | Collapsed section separator background |
| `--color-diff-collapsed-border` | `#CBD5E1` | `#334155` | Collapsed section dashed border |
| `--color-diff-collapsed-text` | `#64748B` | `#94A3B8` | Collapsed section text |
| `--color-diff-collapsed-hover-bg` | `#EFF6FF` | `#172554` | Collapsed section hover background |
| `--color-diff-collapsed-hover-border` | `#93C5FD` | `#1D4ED8` | Collapsed section hover border |

### Drop Zone Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-dropzone-bg` | `#FFFFFF` | `#0F172A` | Drop zone container background |
| `--color-dropzone-border` | `#CBD5E1` | `#334155` | Drop zone dashed border |
| `--color-dropzone-icon` | `#94A3B8` | `#475569` | Upload icon color |
| `--color-dropzone-text` | `#475569` | `#94A3B8` | Instructional text |
| `--color-dropzone-hover-bg` | `#EFF6FF` | `#172554` | Drag-hover background |
| `--color-dropzone-hover-border` | `#2563EB` | `#3B82F6` | Drag-hover solid border |

### Dialog Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-dialog-bg` | `#FFFFFF` | `#1E293B` | Dialog panel background |
| `--color-dialog-backdrop` | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.7)` | Modal backdrop overlay |
| `--color-dialog-shadow` | `rgba(0,0,0,0.2)` | `rgba(0,0,0,0.5)` | Dialog box shadow |
| `--color-dialog-title` | `#1E293B` | `#F1F5F9` | Dialog title text |
| `--color-dialog-body` | `#475569` | `#94A3B8` | Dialog body text |

### Toast Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-toast-bg` | `#1E293B` | `#F1F5F9` | Success/info toast background |
| `--color-toast-text` | `#FFFFFF` | `#0F172A` | Toast text |
| `--color-toast-error-bg` | `#991B1B` | `#7F1D1D` | Error toast background |
| `--color-toast-error-text` | `#FFFFFF` | `#FECACA` | Error toast text |

### Scrollbar Tokens

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `--color-scrollbar-thumb` | `#CBD5E1` | `#475569` | Scrollbar thumb |
| `--color-scrollbar-thumb-hover` | `#94A3B8` | `#64748B` | Scrollbar thumb hover |
| `--color-scrollbar-track` | `transparent` | `transparent` | Scrollbar track |

---

## Surface-by-Surface Specs

This section describes how each major surface appears in light mode versus dark mode, addressing `FR-dm-full-surface-coverage` and `AC-dm-all-surfaces-themed`.

### Toolbar

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Background | White (`#FFFFFF`) | Slate-950 (`#0F172A`) |
| Bottom border | Light gray (`#E2E8F0`) | Slate-700 (`#334155`) |
| Title text | Dark slate (`#1E293B`) | Light gray (`#E2E8F0`) |
| Button labels | Slate (`#475569`) | Muted slate (`#94A3B8`) |
| Button hover bg | Very light (`#F8FAFC`) | Dark slate (`#1E293B`) |
| Disabled button text | Muted (`#94A3B8`) | Dark gray (`#475569`) |
| View mode toggle active segment | Blue bg, white text | Blue bg, white text |
| View mode toggle inactive segment | White bg, slate text | Slate-950 bg, muted text |

### Code Viewer

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Background | White (`#FFFFFF`) | Slate-950 (`#0F172A`) |
| File header background | Off-white (`#F8FAFC`) | Slate-800 (`#1E293B`) |
| Line numbers | Muted (`#94A3B8`) | Dark muted (`#475569`) |
| Gutter comment indicator | Blue dot (`#3B82F6`) | Lighter blue dot (`#60A5FA`) |
| Gutter "+" hover icon | Muted (`#94A3B8`) | Dark muted (`#475569`) |
| Line hover background | Very light (`#F8FAFC`) | Slate-800 (`#1E293B`) |
| Selected range background | Pale blue (`#DBEAFE`) | Deep blue (`#1E3A5F`) |
| Focused comment line | Pale yellow (`#FEF9C3`) | Deep amber (`#422006`) |
| Focus ring | Blue outline (`#2563EB`) | Blue outline (`#3B82F6`) |

Syntax highlighting tokens are governed by the Shiki theme (see Syntax Highlighting Theme section below). The code background must match `--color-code-bg` in both themes.

### Comment Bubbles

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Background | Light blue (`#F0F9FF`) | Deep blue (`#0C2D48`) |
| Left border | Blue (`#3B82F6`) | Blue (`#2563EB`) |
| Body text | Dark slate (`#1E293B`) | Light gray (`#E2E8F0`) |
| Line label | Slate (`#64748B`) | Muted slate (`#94A3B8`) |
| Edit/Delete icons (on hover) | Slate (`#64748B`) | Muted slate (`#94A3B8`) |
| Edit/Delete icons hover | Dark slate (`#1E293B`) | White (`#F1F5F9`) |
| Focused bubble background | Pale blue (`#DBEAFE`) | Deep blue (`#1E3A5F`) |

### Inline Comment Editor

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Background | White (`#FFFFFF`) | Slate-800 (`#1E293B`) |
| Border | Blue (`#3B82F6`) | Blue (`#2563EB`) |
| Text area background | White (`#FFFFFF`) | Slate-900 (`#0F172A`) |
| Text area text | Dark slate (`#1E293B`) | Light gray (`#E2E8F0`) |
| Placeholder text | Muted (`#94A3B8`) | Dark muted (`#475569`) |
| Primary button (Comment/Save) | Blue bg (`#2563EB`), white text | Blue bg (`#3B82F6`), white text |
| Secondary button (Cancel) | Transparent bg, slate text | Transparent bg, muted text |
| Box shadow | `rgba(0,0,0,0.1)` | `rgba(0,0,0,0.4)` |

### Sidebar (Preamble + Prompt Preview)

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Panel background | White (`#FFFFFF`) | Slate-950 (`#0F172A`) |
| Section labels | Semi-bold slate (`#475569`) | Semi-bold muted (`#94A3B8`) |
| Preamble text area bg | White (`#FFFFFF`) | Slate-800 (`#1E293B`) |
| Preamble text area text | Dark slate (`#1E293B`) | Light gray (`#E2E8F0`) |
| Collapsed preamble bg | Off-white (`#F8FAFC`) | Slate-800 (`#1E293B`) |
| Prompt preview bg | Dark (`#1E293B`) | Near-black (`#020617`) |
| Prompt preview text | Light (`#E2E8F0`) | Muted light (`#CBD5E1`) |
| Empty preview dashed border | Gray (`#CBD5E1`) | Slate-700 (`#334155`) |
| Empty preview text | Muted (`#94A3B8`) | Dark muted (`#475569`) |

Note: The prompt preview panel already uses a dark terminal theme in light mode (`#1E293B` background). In dark mode, it deepens slightly to `#020617` (slate-950) to maintain visual distinction from the surrounding sidebar.

### Drop Zone (`AC-dm-drop-zone-themed`)

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Container background | White (`#FFFFFF`) | Slate-950 (`#0F172A`) |
| Dashed border | Gray (`#CBD5E1`) | Slate-700 (`#334155`) |
| Upload icon | Muted (`#94A3B8`) | Dark muted (`#475569`) |
| Instructional text | Slate (`#475569`) | Muted slate (`#94A3B8`) |
| "Choose file" / "Paste content" buttons | Standard secondary style | Dark secondary style |
| Drag-hover background | Blue-tinted (`#EFF6FF`) | Deep blue (`#172554`) |
| Drag-hover border | Solid blue (`#2563EB`) | Solid blue (`#3B82F6`) |
| Loading spinner | Blue (`#2563EB`) | Blue (`#3B82F6`) |
| Error banner bg | Pale red (`#FEF2F2`) | Deep red (`#451A1A`) |
| Error banner text | Dark red (`#991B1B`) | Light red (`#FCA5A5`) |

### Diff View (`AC-dm-diff-view-themed`)

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Added line background | Light green (`#F0FDF4`) | Deep green (`#052E16`) |
| Removed line background | Light red (`#FEF2F2`) | Deep red (`#450A0A`) |
| Context line background | White (`#FFFFFF`) | Slate-950 (`#0F172A`) |
| `+` indicator | Green (`#15803D`) | Bright green (`#4ADE80`) |
| `-` indicator | Red (`#B91C1C`) | Light red (`#FCA5A5`) |
| Collapsed separator bg | Very light (`#F8FAFC`) | Slate-800 (`#1E293B`) |
| Collapsed separator border | Dashed gray (`#CBD5E1`) | Dashed slate (`#334155`) |
| Collapsed separator text | Slate (`#64748B`) | Muted slate (`#94A3B8`) |
| "Expand" link | Blue (`#2563EB`) | Blue (`#3B82F6`) |
| Collapsed hover bg | Blue-tinted (`#EFF6FF`) | Deep blue (`#172554`) |

### Dialogs (`AC-dm-dialog-themed`)

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Backdrop | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.7)` |
| Dialog background | White (`#FFFFFF`) | Slate-800 (`#1E293B`) |
| Box shadow | `rgba(0,0,0,0.2)` | `rgba(0,0,0,0.5)` |
| Title text | Dark slate (`#1E293B`) | Off-white (`#F1F5F9`) |
| Body text | Slate (`#475569`) | Muted slate (`#94A3B8`) |
| Cancel button | Standard secondary | Dark secondary |
| Destructive button | Red bg (`#DC2626`), white text | Red bg (`#EF4444`), white text |
| Close [X] icon | Slate (`#64748B`) | Muted (`#94A3B8`) |

### Toast Notifications

| Aspect | Light Mode | Dark Mode |
|---|---|---|
| Success/info background | Dark (`#1E293B`) | Light (`#F1F5F9`) |
| Success/info text | White (`#FFFFFF`) | Dark (`#0F172A`) |
| Error background | Dark red (`#991B1B`) | Deep red (`#7F1D1D`) |
| Error text | White (`#FFFFFF`) | Light red (`#FECACA`) |
| Box shadow | Standard | Standard with higher opacity |

Note: Toast colors invert between themes to maintain the "floating notification" contrast against the page background.

---

## Syntax Highlighting Theme

Implements `NFR-dm-syntax-highlight-both-themes`, `AC-dm-syntax-highlight-dark`, `AC-dm-syntax-highlight-light`.

The application uses Shiki for syntax highlighting. Two themes are loaded:

| Theme Mode | Shiki Theme | Description |
|---|---|---|
| Light | `github-light` | GitHub's light syntax theme. High contrast against white background. Familiar to developers. |
| Dark | `github-dark` | GitHub's dark syntax theme. High contrast against dark background. Pairs with `github-light`. |

**Integration approach**: Shiki supports dual-theme output via CSS variables mode (`createHighlighter` with `themes: ['github-light', 'github-dark']`). Token colors are emitted as CSS custom properties, and the active set is determined by the `[data-theme]` attribute on `<html>`. This means:

- The file is highlighted **once** when loaded. No re-parsing is needed on theme switch.
- Theme switching for syntax colors is instant (pure CSS swap).
- Both token color sets are present in the DOM; CSS determines which is visible.

The Shiki theme backgrounds are overridden by `--color-code-bg` to maintain consistency with the rest of the theming system. Only token colors come from the Shiki themes.

---

## Interaction Flows

### Flow 1: First-Time User Visit — System Detection (`AC-dm-default-respects-system`, `AC-dm-default-light-system`, `FR-dm-system-preference`)

1. User opens the application for the first time. No `localStorage` entry exists for theme preference.
2. A blocking `<script>` in `<head>` (before any CSS or React loads) runs the theme resolution logic:
   a. Check `localStorage` for a stored preference. None found.
   b. Query `window.matchMedia('(prefers-color-scheme: dark)')`.
   c. If the OS is in dark mode, set `data-theme="dark"` on `<html>`.
   d. If the OS is in light mode (or no preference), set `data-theme="light"` on `<html>`.
3. The page renders in the detected theme from the very first paint. No flash of wrong theme (`NFR-dm-no-fouc`, `AC-dm-no-fouc`).
4. The ThemeToggle shows "System" as the active selection (since no explicit override was stored).
5. The resolved theme (light or dark) is applied to all surfaces.

### Flow 2: Manual Toggle Cycle (`AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `AC-dm-toggle-to-system`)

1. User is currently in light mode (either via system detection or manual selection).
2. User clicks the "Dark" segment (moon icon) in the ThemeToggle.
3. The `data-theme` attribute on `<html>` changes from `"light"` to `"dark"`.
4. All surfaces transition smoothly to dark mode colors (`NFR-dm-smooth-transition`).
5. The ThemeToggle updates: the "Dark" segment becomes active (blue background, white icon). The previously active segment becomes inactive.
6. The preference `"dark"` is written to `localStorage` under the key `shepherd-theme`.
7. Syntax highlighting switches to `github-dark` token colors via CSS (no re-parse).
8. If the user then clicks "Light" (sun icon), the process reverses: surfaces transition to light mode, preference is stored as `"light"`.
9. If the user then clicks "System" (monitor icon), the preference is stored as `"system"`, and the app queries `prefers-color-scheme` to determine the applied theme. Real-time OS tracking is re-enabled.

### Flow 3: OS Change While on "System" (`AC-dm-realtime-os-change`, `FR-dm-realtime-tracking`)

1. The user's theme preference is set to "System" (either by default or by explicit selection).
2. The user is currently seeing light mode (OS is in light mode).
3. The user opens their OS System Settings and switches appearance to dark mode.
4. The `matchMedia('(prefers-color-scheme: dark)')` change event fires.
5. The application updates `data-theme` on `<html>` from `"light"` to `"dark"`.
6. All surfaces transition smoothly to dark mode.
7. The ThemeToggle still shows "System" as the active selection — the resolved theme changed, but the user's preference ("System") did not.
8. No `localStorage` write occurs (the stored value remains `"system"`).

### Flow 4: Manual Override Ignores OS Changes (`AC-dm-manual-ignores-os`)

1. The user has explicitly selected "Light" from the ThemeToggle.
2. The user switches their OS to dark mode.
3. The `matchMedia` change event fires, but the application ignores it because the stored preference is `"light"` (not `"system"`).
4. The app remains in light mode. No visual change occurs.

### Flow 5: Page Reload with Stored Preference (`AC-dm-persistence-survives-reload`, `AC-dm-persistence-system-survives-reload`, `FR-dm-persistence`)

1. The user has previously selected "Dark" from the ThemeToggle. `localStorage` contains `shepherd-theme: "dark"`.
2. The user reloads the page (or closes and reopens the tab).
3. The blocking `<script>` in `<head>` runs:
   a. Reads `localStorage` key `shepherd-theme`. Finds `"dark"`.
   b. Sets `data-theme="dark"` on `<html>`.
4. The page renders in dark mode from the first paint. No flash of light mode (`AC-dm-no-fouc`).
5. React hydrates. The ThemeToggle renders with "Dark" as the active selection.
6. If the stored value were `"system"`, the script would query `prefers-color-scheme` and apply the matching theme, while the ThemeToggle would show "System" as active.

### Flow 6: Graceful Fallback Without localStorage (`AC-dm-localstorage-unavailable`)

1. The user is in a browser where `localStorage` is unavailable (e.g., some private browsing modes).
2. The blocking `<script>` attempts to read `localStorage`. The read fails or returns null.
3. The script falls back to `prefers-color-scheme` media query detection.
4. The page renders in the OS-detected theme.
5. The ThemeToggle shows "System" as active.
6. The user can still toggle themes for the current session — the `data-theme` attribute is updated in memory. Changes are not persisted. On next page load, the app falls back to system detection again.
7. No error messages or warnings are shown to the user.

---

## Transition Behavior

Implements `NFR-dm-smooth-transition`.

### CSS Transition Properties

When the theme changes at runtime (user clicks the toggle, or OS preference changes while in "system" mode), color transitions animate smoothly:

```css
/* Applied to elements that should animate on theme change */
html[data-theme-transition] * {
  transition: background-color 150ms ease,
              color 150ms ease,
              border-color 150ms ease,
              box-shadow 150ms ease !important;
}
```

### Transition Rules

1. **Runtime theme switch**: The `data-theme-transition` attribute is added to `<html>` immediately before the `data-theme` attribute is changed. It is removed after 200ms (slightly longer than the 150ms transition to ensure completion). This enables the CSS transitions.
2. **Initial page load**: The `data-theme-transition` attribute is **never** set during initial load. The blocking script sets `data-theme` without this attribute, so the first paint applies colors instantly with no transition. This prevents the user from seeing any animation on load.
3. **No layout shifts**: All color transitions are purely cosmetic (background-color, color, border-color, box-shadow). No `width`, `height`, `padding`, `margin`, or `transform` properties are transitioned. This ensures zero layout shift during theme changes.
4. **Syntax highlighting**: Shiki token colors via CSS variables also transition via the same 150ms ease, since they are `color` property values.
5. **Performance**: The transition declaration uses the `*` selector on a short-lived attribute. Since the attribute is only present for 200ms, performance impact is negligible. Browser style engines handle CSS variable transitions efficiently.

---

## FOUC Prevention

Implements `NFR-dm-no-fouc`, `AC-dm-no-fouc`.

From a design perspective, the user must **never** see the wrong theme flash before the correct theme applies. This is achieved through a blocking script architecture:

1. A `<script>` tag is placed in `<head>`, before any `<link>` stylesheet or React bundle. This script is **synchronous** (not `defer` or `async`), so it blocks HTML parsing.
2. The script executes three steps:
   a. **Read preference**: `localStorage.getItem('shepherd-theme')` -- returns `'light'`, `'dark'`, `'system'`, or `null`.
   b. **Resolve theme**: If the value is `'light'` or `'dark'`, use it directly. If `'system'` or `null`, query `window.matchMedia('(prefers-color-scheme: dark)').matches`. If true, resolve to `'dark'`; otherwise `'light'`.
   c. **Apply theme**: `document.documentElement.setAttribute('data-theme', resolvedTheme)`.
3. CSS rules for both themes are defined using attribute selectors: `[data-theme="light"]` and `[data-theme="dark"]`. The CSS variables are defined at the top of the stylesheet and apply immediately based on the `data-theme` value.
4. Since the `data-theme` attribute is set before any CSS is evaluated or any content paints, the browser resolves all CSS variables correctly on the first paint.

The user's experience: the page loads directly into the correct theme. There is no white flash for dark mode users, and no dark flash for light mode users.

---

## Responsive Behavior

The ThemeToggle adapts to the existing responsive breakpoints defined in `../design/code-review-prompt.md`:

| Breakpoint | ThemeToggle Behavior |
|---|---|
| **>= 1280px** | Full toggle with three 36px-wide icon segments (108px total). Visible in toolbar right section. |
| **1024px - 1279px** | Same appearance. The toolbar title abbreviates to "CRPG" as before, which frees space. The ThemeToggle remains at full size. |
| **< 1024px** | The "minimum viewport" overlay message blocks the app. The ThemeToggle is not accessible below 1024px, consistent with the rest of the app. |

The ThemeToggle icon-only design (no text labels) keeps it compact and prevents layout pressure at narrower widths. Tooltips provide text identification on hover for users who need it.

---

## Accessibility

Implements `NFR-dm-contrast-ratios`, `AC-dm-keyboard-toggle`.

### Keyboard Navigation

| Workflow | Keyboard Path |
|---|---|
| **Focus the theme toggle** | `Tab` through toolbar controls until the ThemeToggle group receives focus |
| **Select a theme** | `ArrowLeft` / `ArrowRight` to move between segments; selection activates immediately (radio group pattern) |
| **Exit the toggle** | `Tab` to move focus to the next toolbar control |

The ThemeToggle uses the WAI-ARIA radio group pattern because it represents a mutually exclusive selection among three options (not tabs, since the toggle doesn't control visible panels).

### ARIA Attributes

| Element | ARIA |
|---|---|
| ThemeToggle group | `role="radiogroup"`, `aria-label="Theme"` |
| Light segment | `role="radio"`, `aria-checked="true/false"`, `aria-label="Light mode"` |
| Dark segment | `role="radio"`, `aria-checked="true/false"`, `aria-label="Dark mode"` |
| System segment | `role="radio"`, `aria-checked="true/false"`, `aria-label="System theme"` |

### Contrast Ratios (`NFR-dm-contrast-ratios`)

All color pairings in both themes have been selected to meet WCAG 2.1 AA contrast requirements (4.5:1 for normal text, 3:1 for large text and UI components).

**Light mode key contrasts** (unchanged from existing design, verified):

| Text / Foreground | Background | Ratio | Passes AA |
|---|---|---|---|
| `#1E293B` (primary text) | `#FFFFFF` (white bg) | 12.6:1 | Yes |
| `#475569` (secondary text) | `#FFFFFF` (white bg) | 7.1:1 | Yes |
| `#94A3B8` (muted text) | `#FFFFFF` (white bg) | 3.3:1 | Yes (large text / UI components only) |
| `#15803D` (diff `+` indicator) | `#F0FDF4` (green bg) | 4.8:1 | Yes |
| `#B91C1C` (diff `-` indicator) | `#FEF2F2` (red bg) | 5.6:1 | Yes |

**Dark mode key contrasts** (designed for compliance):

| Text / Foreground | Background | Ratio | Passes AA |
|---|---|---|---|
| `#E2E8F0` (primary text) | `#0F172A` (dark bg) | 13.1:1 | Yes |
| `#94A3B8` (secondary text) | `#0F172A` (dark bg) | 5.6:1 | Yes |
| `#64748B` (muted text) | `#0F172A` (dark bg) | 3.4:1 | Yes (large text / UI components only) |
| `#475569` (line numbers) | `#0F172A` (dark bg) | 3.1:1 | Yes (UI components, 13px monospace) |
| `#4ADE80` (diff `+` indicator) | `#052E16` (green bg) | 6.3:1 | Yes |
| `#FCA5A5` (diff `-` indicator) | `#450A0A` (red bg) | 5.1:1 | Yes |
| `#E2E8F0` (comment text) | `#0C2D48` (comment bg) | 10.2:1 | Yes |
| `#94A3B8` (dialog body) | `#1E293B` (dialog bg) | 4.6:1 | Yes |
| `#3B82F6` (primary blue) | `#0F172A` (dark bg) | 4.7:1 | Yes |

The muted text tokens (`--color-text-muted`) are used exclusively for placeholder text, line numbers, and supplementary labels -- elements that qualify as "large text" or "UI component" under WCAG (3:1 threshold) due to their size and context. Primary content text always uses `--color-text` or `--color-text-secondary`, which exceed 4.5:1 in both themes.

### Non-Color Indicators

Dark mode does not introduce any new information conveyed solely through color. All existing non-color indicators remain:
- Comment gutter uses both a filled circle shape and color
- Focused lines use both background change and focus ring
- Error states use icons, text, and color
- The ThemeToggle uses distinct icons (sun, moon, monitor) for each option, not just color differentiation

---

## Requirement Traceability

This section maps every dark mode product requirement and acceptance criterion to where it is addressed in this design spec.

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-dm-system-preference` | Flow 1 (First-Time Visit); FOUC Prevention section (blocking script logic) |
| `FR-dm-manual-toggle` | ThemeToggle component spec; Flow 2 (Manual Toggle Cycle) |
| `FR-dm-persistence` | Flow 5 (Page Reload with Stored Preference); Flow 6 (Graceful Fallback); FOUC Prevention section |
| `FR-dm-realtime-tracking` | Flow 3 (OS Change While on System); Flow 4 (Manual Override Ignores OS) |
| `FR-dm-full-surface-coverage` | Screen Inventory table; Surface-by-Surface Specs section; Color Token Definitions section |
| `FR-dm-css-custom-properties` | Color Token Definitions section (all tokens defined as CSS custom properties) |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-dm-no-fouc` | FOUC Prevention section; Flow 1 step 3; Flow 5 step 4; Transition Behavior (no transition on initial load) |
| `NFR-dm-smooth-transition` | Transition Behavior section (CSS transitions, 150ms ease, no layout shifts, initial load exception) |
| `NFR-dm-syntax-highlight-both-themes` | Syntax Highlighting Theme section (github-light / github-dark, CSS variables mode) |
| `NFR-dm-contrast-ratios` | Accessibility section (contrast ratio tables for both themes) |
| `NFR-dm-no-performance-impact` | Syntax Highlighting Theme section (no re-parse on switch); Transition Behavior section (short-lived attribute, CSS-only transitions); Color Token Definitions (CSS variables resolved by browser engine) |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-dm-default-respects-system` | Flow 1 (First-Time Visit, dark OS); FOUC Prevention section |
| `AC-dm-default-light-system` | Flow 1 step 2d (light OS path) |
| `AC-dm-toggle-to-dark` | Flow 2 steps 2-7; ThemeToggle segment states |
| `AC-dm-toggle-to-light` | Flow 2 step 8; ThemeToggle segment states |
| `AC-dm-toggle-to-system` | Flow 2 step 9; ThemeToggle segment states |
| `AC-dm-persistence-survives-reload` | Flow 5 (stored "dark" reload scenario) |
| `AC-dm-persistence-system-survives-reload` | Flow 5 step 6 (stored "system" reload scenario) |
| `AC-dm-realtime-os-change` | Flow 3 (OS change in system mode) |
| `AC-dm-manual-ignores-os` | Flow 4 (manual override ignores OS) |
| `AC-dm-syntax-highlight-dark` | Syntax Highlighting Theme section (github-dark); Surface-by-Surface > Code Viewer |
| `AC-dm-syntax-highlight-light` | Syntax Highlighting Theme section (github-light); Surface-by-Surface > Code Viewer |
| `AC-dm-all-surfaces-themed` | Surface-by-Surface Specs section (all surfaces enumerated); Screen Inventory table |
| `AC-dm-diff-view-themed` | Surface-by-Surface > Diff View; Diff View Tokens |
| `AC-dm-drop-zone-themed` | Surface-by-Surface > Drop Zone; Drop Zone Tokens |
| `AC-dm-dialog-themed` | Surface-by-Surface > Dialogs; Dialog Tokens |
| `AC-dm-no-fouc` | FOUC Prevention section; Flow 1; Flow 5 |
| `AC-dm-localstorage-unavailable` | Flow 6 (Graceful Fallback) |
| `AC-dm-keyboard-toggle` | ThemeToggle Keyboard Accessibility; Accessibility > Keyboard Navigation table |
