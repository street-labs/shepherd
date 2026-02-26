# Dark Mode -- Technical Spec

> Based on requirements in `../../product/dark-mode.md`
> Based on design in `../../design/web/dark-mode.md`

## Technical Approach

Dark mode is implemented as a pure CSS theming layer driven by CSS custom properties on the `<html>` element. The mechanism is:

1. **CSS custom properties** define every color token used by the application. Two sets of values are declared under `[data-theme="light"]` and `[data-theme="dark"]` attribute selectors. Switching themes means changing the `data-theme` attribute; all surfaces update instantly because every color reference is a `var(--color-*)` lookup. This implements `FR-dm-css-custom-properties`.

2. **Zustand store** holds the user's theme preference (`'light' | 'dark' | 'system'`) and the resolved theme (`'light' | 'dark'`). The store reads/writes `localStorage`, listens to `matchMedia` for system preference changes, and keeps `document.documentElement.dataset.theme` in sync. This implements `FR-dm-manual-toggle`, `FR-dm-persistence`, `FR-dm-realtime-tracking`.

3. **Blocking inline script** in `<head>` of `index.html` reads `localStorage` and `matchMedia` before any CSS or React loads, setting `data-theme` on `<html>` so the first paint is always the correct theme. This implements `NFR-dm-no-fouc`.

4. **Shiki dual-theme via CSS variables mode** highlights code once with both `github-light` and `github-dark` token colors emitted as CSS custom properties. The active set is determined by `[data-theme]` on `<html>`. Theme switches for syntax highlighting are instant CSS swaps with no re-parsing. This implements `NFR-dm-syntax-highlight-both-themes`.

No new dependencies are introduced. Shiki already supports CSS variables mode natively. Zustand is already the application's state manager. Tailwind CSS v4 works seamlessly with CSS custom properties via the `@theme` directive.

---

## Data Model

### Types

```typescript
/** The user's stored preference. Persisted to localStorage. */
type ThemePreference = 'light' | 'dark' | 'system';

/** The actual theme applied to the DOM. Derived from ThemePreference + OS setting. */
type ResolvedTheme = 'light' | 'dark';

/** Shape of the theme slice in the Zustand store. */
interface ThemeState {
  /** The user's explicit choice. Defaults to 'system' if nothing stored. */
  themePreference: ThemePreference;
  /** The theme currently applied to the DOM. Derived from themePreference + matchMedia. */
  resolvedTheme: ResolvedTheme;
  /** Update the user's preference. Persists to localStorage and updates the DOM. */
  setThemePreference: (pref: ThemePreference) => void;
}
```

### localStorage Schema

| Key | Value | Default |
|---|---|---|
| `shepherd-theme` | `'light'` \| `'dark'` \| `'system'` | Not present (treated as `'system'`) |

The key name `shepherd-theme` matches the design spec's reference. This is a scoped exception to `NFR-crp-no-data-persistence` as documented in `FR-dm-persistence`.

### Resolving the Theme

The resolution algorithm is used in two places (the blocking script and the Zustand store):

```
function resolveTheme(preference: ThemePreference): ResolvedTheme {
  if (preference === 'light') return 'light';
  if (preference === 'dark') return 'dark';
  // preference === 'system' or unknown
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}
```

---

## Component Architecture

### New Files

| File | Purpose |
|---|---|
| `src/styles/theme.css` | CSS custom property definitions for both themes, transition classes |
| `src/components/ThemeToggle.tsx` | Segmented control component for Light/Dark/System |
| `src/store/themeStore.ts` | Zustand store for theme state |
| `src/lib/themeScript.ts` | Source for the blocking `<script>` (inlined into `index.html` at build time) |

### Modified Files

| File | Change |
|---|---|
| `index.html` | Add blocking `<script>` in `<head>` before any `<link>` or `<script>` tags |
| `src/styles/app.css` | Replace all hardcoded color values with `var(--color-*)` references; import `theme.css` |
| `src/components/Toolbar.tsx` | Add `<ThemeToggle />` to the right section of the toolbar |
| `src/App.tsx` | No direct changes needed; theme is applied globally via CSS |
| `src/lib/highlighter.ts` | Switch from single-theme to CSS variables mode with dual themes |
| `src/types/index.ts` | Add `ThemePreference`, `ResolvedTheme` type exports |
| All component `.tsx` files | Audit and replace any inline color references with theme tokens (most already use Tailwind utilities that reference `app.css` tokens) |

### ThemeToggle Component

Implements `FR-dm-manual-toggle`, `AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `AC-dm-toggle-to-system`, `AC-dm-keyboard-toggle`.

```
src/components/ThemeToggle.tsx
```

**Props**: None. Reads directly from `themeStore` (Zustand) for `themePreference` and calls `setThemePreference`.

**Structure**:

```tsx
<div role="radiogroup" aria-label="Theme" className="theme-toggle">
  <button role="radio" aria-checked={pref === 'light'} aria-label="Light mode"
          onClick={() => setThemePreference('light')}>
    <SunIcon />
  </button>
  <button role="radio" aria-checked={pref === 'dark'} aria-label="Dark mode"
          onClick={() => setThemePreference('dark')}>
    <MoonIcon />
  </button>
  <button role="radio" aria-checked={pref === 'system'} aria-label="System theme"
          onClick={() => setThemePreference('system')}>
    <MonitorIcon />
  </button>
</div>
```

**Keyboard behavior**: `ArrowLeft` / `ArrowRight` cycles between segments and activates immediately (WAI-ARIA radio group pattern). `Tab` enters/exits the group. Implemented with `onKeyDown` handler and `tabIndex` management per the radio group pattern.

**Icons**: Inline SVG icons (sun, moon, monitor) at 16px. No icon library dependency -- three simple SVGs kept in a `src/components/icons/` directory or inlined directly in the component.

**Dimensions**: Each segment 36px wide x 32px tall. Total 108px wide. 1px border, 6px outer border-radius. Styled with CSS classes referencing theme tokens.

### Theme Initialization Script

Implements `NFR-dm-no-fouc`, `AC-dm-no-fouc`, `AC-dm-persistence-survives-reload`.

A synchronous `<script>` block is placed in the `<head>` of `index.html`, before any `<link>` stylesheet or the Vite module script. This script:

1. Reads `localStorage.getItem('shepherd-theme')`.
2. Validates the value is `'light'`, `'dark'`, or `'system'`. Falls back to `'system'` on invalid/missing values.
3. Resolves to a concrete theme:
   - `'light'` or `'dark'` -> use directly.
   - `'system'` -> query `window.matchMedia('(prefers-color-scheme: dark)').matches`.
4. Sets `document.documentElement.setAttribute('data-theme', resolvedTheme)`.
5. Wraps the `localStorage` access in a `try/catch` to handle `SecurityError` when storage is unavailable (`AC-dm-localstorage-unavailable`).

```html
<script>
  // FOUC prevention: resolve theme before first paint
  (function() {
    var STORAGE_KEY = 'shepherd-theme';
    var pref = 'system';
    try { pref = localStorage.getItem(STORAGE_KEY) || 'system'; } catch(e) {}
    if (pref !== 'light' && pref !== 'dark' && pref !== 'system') pref = 'system';
    var resolved = pref;
    if (pref === 'system') {
      resolved = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    document.documentElement.setAttribute('data-theme', resolved);
  })();
</script>
```

This script must remain as a raw inline `<script>` in `index.html`. It cannot be a module, cannot use `defer` or `async`, and cannot import anything. It must be self-contained and execute synchronously during HTML parsing.

### Toolbar Integration

The `ThemeToggle` is placed in the right section of the `Toolbar` component, between the comment navigation group and the Copy button, separated by a flexible gap from navigation and a 12px gap from Copy. This matches the design spec layout:

```
[Logo/Title]---[File|Diff]---[Refresh]---[Comment Nav]---[Count]---...---[ThemeToggle][Copy][Clear]
```

When no file is loaded (empty state toolbar), the `ThemeToggle` still renders -- theming is always available.

---

## State Management

### Theme Store (`src/store/themeStore.ts`)

A dedicated Zustand store (not a slice of `appStore`) to keep theme concerns isolated. Theme state is orthogonal to application state (file, comments, prompt) and should not be cleared when the user clears a session.

```typescript
import { create } from 'zustand';

const STORAGE_KEY = 'shepherd-theme';

type ThemePreference = 'light' | 'dark' | 'system';
type ResolvedTheme = 'light' | 'dark';

interface ThemeState {
  themePreference: ThemePreference;
  resolvedTheme: ResolvedTheme;
  setThemePreference: (pref: ThemePreference) => void;
}

function getSystemTheme(): ResolvedTheme {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function resolveTheme(pref: ThemePreference): ResolvedTheme {
  if (pref === 'light' || pref === 'dark') return pref;
  return getSystemTheme();
}

function readStoredPreference(): ThemePreference {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'light' || stored === 'dark' || stored === 'system') return stored;
  } catch { /* localStorage unavailable */ }
  return 'system';
}

function applyThemeToDOM(resolved: ResolvedTheme, animate: boolean): void {
  const html = document.documentElement;
  if (animate) {
    html.setAttribute('data-theme-transition', '');
  }
  html.setAttribute('data-theme', resolved);
  if (animate) {
    setTimeout(() => html.removeAttribute('data-theme-transition'), 200);
  }
}

export const useThemeStore = create<ThemeState>((set, get) => {
  // Initialize from what the blocking script already set
  const initialPref = readStoredPreference();
  const initialResolved = resolveTheme(initialPref);

  // Listen for OS preference changes
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  mediaQuery.addEventListener('change', () => {
    const { themePreference } = get();
    if (themePreference === 'system') {
      const newResolved = getSystemTheme();
      applyThemeToDOM(newResolved, true);
      set({ resolvedTheme: newResolved });
    }
  });

  return {
    themePreference: initialPref,
    resolvedTheme: initialResolved,
    setThemePreference: (pref: ThemePreference) => {
      const resolved = resolveTheme(pref);
      try { localStorage.setItem(STORAGE_KEY, pref); } catch { /* ignore */ }
      applyThemeToDOM(resolved, true);
      set({ themePreference: pref, resolvedTheme: resolved });
    },
  };
});
```

**Key design decisions:**

1. **Separate store, not an `appStore` slice**: `clearSession()` in `appStore` resets file, comments, and prompt. Theme must survive session clears. A separate store avoids accidental coupling.

2. **DOM is the source of truth for CSS**: The store calls `applyThemeToDOM` which sets `data-theme` on `<html>`. CSS variables resolve from that attribute. React components don't need to read `resolvedTheme` to style themselves -- CSS handles it globally. The store's `resolvedTheme` is available for components that need to know the theme programmatically (e.g., ThemeToggle's active state, or passing theme info to Shiki).

3. **Transition class management**: `applyThemeToDOM` adds `data-theme-transition` before changing `data-theme` and removes it after 200ms. This enables CSS transitions only during runtime switches, not on initial load (`NFR-dm-smooth-transition`).

4. **matchMedia listener**: Registered once at store creation. Only triggers a DOM/state update when `themePreference === 'system'`, implementing `FR-dm-realtime-tracking` and `AC-dm-manual-ignores-os`.

5. **localStorage writes wrapped in try/catch**: Implements `AC-dm-localstorage-unavailable`. The toggle still works for the current session; changes just won't persist.

---

## FOUC Prevention

Implements `NFR-dm-no-fouc`, `AC-dm-no-fouc`, `AC-dm-persistence-survives-reload`, `AC-dm-persistence-system-survives-reload`.

### Architecture

The FOUC prevention strategy uses a **two-phase initialization**:

**Phase 1: Blocking script (before CSS, before React)**
- An inline synchronous `<script>` in `<head>` of `index.html`.
- Runs during HTML parsing, before the browser evaluates any `<link>` stylesheets or module scripts.
- Reads `localStorage`, resolves theme, sets `data-theme` on `<html>`.
- Result: by the time CSS files are parsed, `[data-theme="light"]` or `[data-theme="dark"]` is already on the root element, so the correct variable values are used from the very first paint.

**Phase 2: Zustand store initialization (after React mounts)**
- The `themeStore` reads the same `localStorage` key and sets its internal state to match.
- It does NOT re-apply the DOM attribute (the blocking script already did).
- It registers the `matchMedia` change listener for future OS preference updates.
- It provides `setThemePreference` for the ThemeToggle component.

This two-phase design means:
- The blocking script is ~400 bytes of vanilla JS with no dependencies.
- React doesn't need to load, parse, or hydrate before the correct theme is visible.
- The Zustand store and the blocking script use the same resolution logic and the same `localStorage` key, ensuring consistency.

### index.html Structure After Modification

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Code Review Prompt Generator</title>
    <script>
      // Phase 1: FOUC prevention — resolve and apply theme before first paint
      (function() {
        var K = 'shepherd-theme', p = 'system';
        try { p = localStorage.getItem(K) || 'system'; } catch(e) {}
        if (p !== 'light' && p !== 'dark' && p !== 'system') p = 'system';
        var r = p;
        if (p === 'system') {
          r = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
        }
        document.documentElement.setAttribute('data-theme', r);
      })();
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

---

## CSS Architecture

Implements `FR-dm-css-custom-properties`, `FR-dm-full-surface-coverage`, `NFR-dm-smooth-transition`, `NFR-dm-contrast-ratios`.

### Token File: `src/styles/theme.css`

All color tokens are defined in a single `theme.css` file using `[data-theme]` attribute selectors. This file is imported at the top of `app.css` (before the Tailwind import) so that the tokens are available to all utility classes and custom CSS.

```css
/* ============================================================
   Theme Token Definitions
   Implements: FR-dm-css-custom-properties, FR-dm-full-surface-coverage
   ============================================================ */

/* --- Light theme (default) --- */
[data-theme="light"] {
  /* Base */
  --color-bg: #FFFFFF;
  --color-bg-secondary: #F8FAFC;
  --color-bg-tertiary: #F1F5F9;
  --color-text: #1E293B;
  --color-text-secondary: #475569;
  --color-text-muted: #94A3B8;
  --color-border: #E2E8F0;
  --color-border-muted: #CBD5E1;

  /* Interactive */
  --color-primary: #2563EB;
  --color-primary-hover: #1D4ED8;
  --color-primary-text: #FFFFFF;
  --color-hover-bg: #F8FAFC;
  --color-focus-ring: #2563EB;
  --color-destructive: #DC2626;
  --color-destructive-hover: #B91C1C;

  /* Selection/Focus */
  --color-selection: #DBEAFE;
  --color-focus-line: #FEF9C3;

  /* Error */
  --color-error-bg: #FEF2F2;
  --color-error-text: #991B1B;
  --color-error-border: #FECACA;

  /* Toolbar */
  --color-toolbar-bg: #FFFFFF;
  --color-toolbar-border: #E2E8F0;
  --color-toolbar-text: #1E293B;

  /* Code viewer */
  --color-code-bg: #FFFFFF;
  --color-line-number: #94A3B8;
  --color-gutter-indicator: #3B82F6;
  --color-gutter-add-icon: #94A3B8;
  --color-file-header-bg: #F8FAFC;
  --color-file-header-border: #E2E8F0;
  --color-line-hover-bg: #F8FAFC;

  /* Comment bubbles */
  --color-comment-bg: #F0F9FF;
  --color-comment-border: #3B82F6;
  --color-comment-text: #1E293B;
  --color-comment-label: #64748B;
  --color-comment-focused-bg: #DBEAFE;
  --color-editor-bg: #FFFFFF;
  --color-editor-textarea-bg: #FFFFFF;
  --color-editor-border: #3B82F6;
  --color-editor-shadow: rgba(0,0,0,0.1);

  /* Sidebar */
  --color-sidebar-bg: #FFFFFF;
  --color-preamble-bg: #FFFFFF;
  --color-preamble-collapsed-bg: #F8FAFC;
  --color-preview-bg: #1E293B;
  --color-preview-text: #E2E8F0;
  --color-preview-border: #1E293B;
  --color-preview-empty-border: #CBD5E1;

  /* Diff */
  --color-diff-added-bg: #F0FDF4;
  --color-diff-removed-bg: #FEF2F2;
  --color-diff-added-indicator: #15803D;
  --color-diff-removed-indicator: #B91C1C;
  --color-diff-context-bg: #FFFFFF;
  --color-diff-collapsed-bg: #F8FAFC;
  --color-diff-collapsed-border: #CBD5E1;
  --color-diff-collapsed-text: #64748B;
  --color-diff-collapsed-hover-bg: #EFF6FF;
  --color-diff-collapsed-hover-border: #93C5FD;

  /* Drop zone */
  --color-dropzone-bg: #FFFFFF;
  --color-dropzone-border: #CBD5E1;
  --color-dropzone-icon: #94A3B8;
  --color-dropzone-text: #475569;
  --color-dropzone-hover-bg: #EFF6FF;
  --color-dropzone-hover-border: #2563EB;

  /* Dialog */
  --color-dialog-bg: #FFFFFF;
  --color-dialog-backdrop: rgba(0,0,0,0.5);
  --color-dialog-shadow: rgba(0,0,0,0.2);
  --color-dialog-title: #1E293B;
  --color-dialog-body: #475569;

  /* Toast */
  --color-toast-bg: #1E293B;
  --color-toast-text: #FFFFFF;
  --color-toast-error-bg: #991B1B;
  --color-toast-error-text: #FFFFFF;

  /* Scrollbar */
  --color-scrollbar-thumb: #CBD5E1;
  --color-scrollbar-thumb-hover: #94A3B8;
  --color-scrollbar-track: transparent;
}

/* --- Dark theme --- */
[data-theme="dark"] {
  /* Base */
  --color-bg: #0F172A;
  --color-bg-secondary: #1E293B;
  --color-bg-tertiary: #0F172A;
  --color-text: #E2E8F0;
  --color-text-secondary: #94A3B8;
  --color-text-muted: #64748B;
  --color-border: #334155;
  --color-border-muted: #1E293B;

  /* Interactive */
  --color-primary: #3B82F6;
  --color-primary-hover: #2563EB;
  --color-primary-text: #FFFFFF;
  --color-hover-bg: #1E293B;
  --color-focus-ring: #3B82F6;
  --color-destructive: #EF4444;
  --color-destructive-hover: #DC2626;

  /* Selection/Focus */
  --color-selection: #1E3A5F;
  --color-focus-line: #422006;

  /* Error */
  --color-error-bg: #451A1A;
  --color-error-text: #FCA5A5;
  --color-error-border: #7F1D1D;

  /* Toolbar */
  --color-toolbar-bg: #0F172A;
  --color-toolbar-border: #334155;
  --color-toolbar-text: #E2E8F0;

  /* Code viewer */
  --color-code-bg: #0F172A;
  --color-line-number: #475569;
  --color-gutter-indicator: #60A5FA;
  --color-gutter-add-icon: #475569;
  --color-file-header-bg: #1E293B;
  --color-file-header-border: #334155;
  --color-line-hover-bg: #1E293B;

  /* Comment bubbles */
  --color-comment-bg: #0C2D48;
  --color-comment-border: #2563EB;
  --color-comment-text: #E2E8F0;
  --color-comment-label: #94A3B8;
  --color-comment-focused-bg: #1E3A5F;
  --color-editor-bg: #1E293B;
  --color-editor-textarea-bg: #0F172A;
  --color-editor-border: #2563EB;
  --color-editor-shadow: rgba(0,0,0,0.4);

  /* Sidebar */
  --color-sidebar-bg: #0F172A;
  --color-preamble-bg: #1E293B;
  --color-preamble-collapsed-bg: #1E293B;
  --color-preview-bg: #020617;
  --color-preview-text: #CBD5E1;
  --color-preview-border: #334155;
  --color-preview-empty-border: #334155;

  /* Diff */
  --color-diff-added-bg: #052E16;
  --color-diff-removed-bg: #450A0A;
  --color-diff-added-indicator: #4ADE80;
  --color-diff-removed-indicator: #FCA5A5;
  --color-diff-context-bg: #0F172A;
  --color-diff-collapsed-bg: #1E293B;
  --color-diff-collapsed-border: #334155;
  --color-diff-collapsed-text: #94A3B8;
  --color-diff-collapsed-hover-bg: #172554;
  --color-diff-collapsed-hover-border: #1D4ED8;

  /* Drop zone */
  --color-dropzone-bg: #0F172A;
  --color-dropzone-border: #334155;
  --color-dropzone-icon: #475569;
  --color-dropzone-text: #94A3B8;
  --color-dropzone-hover-bg: #172554;
  --color-dropzone-hover-border: #3B82F6;

  /* Dialog */
  --color-dialog-bg: #1E293B;
  --color-dialog-backdrop: rgba(0,0,0,0.7);
  --color-dialog-shadow: rgba(0,0,0,0.5);
  --color-dialog-title: #F1F5F9;
  --color-dialog-body: #94A3B8;

  /* Toast */
  --color-toast-bg: #F1F5F9;
  --color-toast-text: #0F172A;
  --color-toast-error-bg: #7F1D1D;
  --color-toast-error-text: #FECACA;

  /* Scrollbar */
  --color-scrollbar-thumb: #475569;
  --color-scrollbar-thumb-hover: #64748B;
  --color-scrollbar-track: transparent;
}

/* --- Transitions (runtime only) --- */
/* Implements: NFR-dm-smooth-transition */
html[data-theme-transition] * {
  transition: background-color 150ms ease,
              color 150ms ease,
              border-color 150ms ease,
              box-shadow 150ms ease !important;
}
```

### Migration of `app.css`

The current `app.css` uses a Tailwind v4 `@theme` block with hardcoded color values (e.g., `--color-surface-primary: #ffffff`). The migration replaces this:

**Before** (current `app.css`):
```css
@import "tailwindcss";

@theme {
  --color-primary-500: #3b82f6;
  --color-surface-primary: #ffffff;
  --color-text-primary: #111827;
  /* ... ~50 hardcoded color tokens ... */
}
```

**After** (migrated `app.css`):
```css
@import "./theme.css";
@import "tailwindcss";

@theme {
  /* Non-color tokens remain here */
  --spacing-line-height: 20px;
  --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;

  /* Color tokens now reference the CSS custom properties from theme.css.
     Tailwind v4's @theme directive registers these as design tokens
     so they can be used in utility classes (e.g., bg-surface-primary). */
  --color-surface-primary: var(--color-bg);
  --color-surface-secondary: var(--color-bg-secondary);
  --color-surface-toolbar: var(--color-toolbar-bg);
  --color-surface-code: var(--color-code-bg);
  --color-surface-sidebar: var(--color-sidebar-bg);
  --color-text-primary: var(--color-text);
  --color-text-secondary: var(--color-text-secondary);
  --color-text-tertiary: var(--color-text-muted);
  --color-border-default: var(--color-border);
  --color-border-strong: var(--color-border-muted);
  --color-primary-500: var(--color-primary);
  --color-primary-600: var(--color-primary);
  --color-primary-700: var(--color-primary-hover);
  --color-destructive-500: var(--color-destructive);
  --color-destructive-600: var(--color-destructive);
  --color-comment-bg: var(--color-comment-bg);
  --color-comment-border: var(--color-comment-border);
  --color-comment-gutter: var(--color-gutter-indicator);
  --color-diff-added-bg: var(--color-diff-added-bg);
  --color-diff-removed-bg: var(--color-diff-removed-bg);
  --color-diff-added-indicator: var(--color-diff-added-indicator);
  --color-diff-removed-indicator: var(--color-diff-removed-indicator);
  --color-diff-separator-bg: var(--color-diff-collapsed-bg);
  --color-diff-separator-border: var(--color-diff-collapsed-border);
  /* ... remaining mappings ... */
}
```

This approach is **non-breaking**: existing Tailwind utility classes (e.g., `bg-surface-primary`, `text-text-primary`) continue to work. They now resolve through an extra level of indirection (`Tailwind token -> @theme value -> var(--color-*) -> [data-theme] attribute selector -> concrete hex value`) but this is transparent to components.

Over time, components can migrate directly to the `var(--color-*)` tokens, eliminating the Tailwind `@theme` bridge. This is not required for v1.

### Scrollbar Styling

Custom scrollbar styles are added to `theme.css`:

```css
/* Scrollbar theming */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: var(--color-scrollbar-track);
}

::-webkit-scrollbar-thumb {
  background: var(--color-scrollbar-thumb);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--color-scrollbar-thumb-hover);
}

/* Firefox */
* {
  scrollbar-width: thin;
  scrollbar-color: var(--color-scrollbar-thumb) var(--color-scrollbar-track);
}
```

---

## Shiki Integration

Implements `NFR-dm-syntax-highlight-both-themes`, `AC-dm-syntax-highlight-dark`, `AC-dm-syntax-highlight-light`.

### Current State

The current `src/lib/highlighter.ts` creates a highlighter with a single theme (`github-light`) and returns token arrays with hardcoded `color` properties:

```typescript
// Current: single theme
highlighterPromise = createHighlighter({
  themes: ['github-light'],
  langs: ['plaintext'],
});

// Current: returns { content, color } tokens
const result = highlighter.codeToTokens(content, {
  lang: language,
  theme: 'github-light',
});
```

### Target State: CSS Variables Mode

Shiki's CSS variables mode emits token colors as CSS custom properties instead of inline `color` values. Two themes are loaded, and the active one is selected by a CSS scope matching the `[data-theme]` attribute.

**Updated `src/lib/highlighter.ts`:**

```typescript
import type { HighlighterGeneric } from 'shiki';

let highlighterPromise: Promise<HighlighterGeneric<any, any>> | null = null;

async function getHighlighter() {
  if (!highlighterPromise) {
    const { createHighlighter } = await import('shiki');
    highlighterPromise = createHighlighter({
      themes: ['github-light', 'github-dark'],
      langs: ['plaintext'],
    });
  }
  return highlighterPromise;
}

export async function highlightCode(
  content: string,
  language: string,
): Promise<string> {
  try {
    const highlighter = await getHighlighter();

    if (language !== 'plaintext') {
      const loaded = highlighter.getLoadedLanguages();
      if (!loaded.includes(language)) {
        await highlighter.loadLanguage(
          language as Parameters<typeof highlighter.loadLanguage>[0],
        );
      }
    }

    // CSS variables mode: produces HTML with CSS custom properties for token colors.
    // Light theme tokens use --shiki-light-*, dark theme tokens use --shiki-dark-*.
    // A small CSS block scopes them to [data-theme="light"] and [data-theme="dark"].
    return highlighter.codeToHtml(content, {
      lang: language,
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
      defaultColor: false,  // Use CSS variables, not inline colors
    });
  } catch {
    // Fallback: return plain text wrapped in <pre>
    return `<pre><code>${escapeHtml(content)}</code></pre>`;
  }
}
```

**Key changes:**
1. **Two themes loaded**: `['github-light', 'github-dark']` passed to `createHighlighter`.
2. **`codeToHtml` replaces `codeToTokens`**: In CSS variables mode, Shiki produces an HTML string with `style` attributes using CSS custom properties (`--shiki-light`, `--shiki-dark`). We render this HTML string directly into the DOM using `dangerouslySetInnerHTML`.
3. **`defaultColor: false`**: Tells Shiki to emit CSS variables instead of picking one theme's colors as inline styles.
4. **No re-highlighting on theme switch**: Because both light and dark token colors are present in the DOM as CSS variables, switching `data-theme` causes the CSS to activate the correct set. No JavaScript runs.

**CSS for Shiki CSS variables mode** (added to `theme.css`):

```css
/* Shiki dual-theme support via CSS variables */
/* Implements: NFR-dm-syntax-highlight-both-themes */
[data-theme="light"] .shiki,
[data-theme="light"] .shiki span {
  color: var(--shiki-light);
  background-color: transparent;
  font-style: var(--shiki-light-font-style);
  font-weight: var(--shiki-light-font-weight);
  text-decoration: var(--shiki-light-text-decoration);
}

[data-theme="dark"] .shiki,
[data-theme="dark"] .shiki span {
  color: var(--shiki-dark);
  background-color: transparent;
  font-style: var(--shiki-dark-font-style);
  font-weight: var(--shiki-dark-font-weight);
  text-decoration: var(--shiki-dark-text-decoration);
}
```

**Impact on CodeViewer component**: The `CodeViewer` currently renders tokens from the `HighlightToken[][]` array with inline `style={{ color: token.color }}`. With the CSS variables approach, the component instead renders the HTML string from `codeToHtml` using `dangerouslySetInnerHTML`. The line-by-line rendering logic needs to be adjusted -- rather than mapping over a token array, the component will parse the HTML output per-line or use Shiki's line-based API. The exact approach will be determined during implementation, but the key architectural constraint is: **no inline `color` styles; all token colors come from CSS variables**.

**Shiki background override**: Shiki sets its own background color on the `<pre>` element. We override this to ensure the code viewer background comes from the theme system:

```css
.shiki {
  background-color: var(--color-code-bg) !important;
}
```

---

## Performance Considerations

Implements `NFR-dm-no-performance-impact`.

### CSS Variable Resolution

CSS custom property lookups are resolved by the browser's style engine during the style calculation phase. This is a native, highly optimized operation. The extra level of indirection (`var(--color-bg)` instead of `#FFFFFF`) has **no measurable performance impact** on rendering, layout, or paint.

Switching themes changes CSS variable values on a single element (`<html>`), which triggers a style recalculation for the page. This is a single-frame operation -- the browser batches all variable changes and repaints once. No JavaScript layout thrashing or forced reflow occurs.

### Shiki Dual-Theme

The CSS variables mode adds approximately 2x the inline style data per token (light + dark color variables instead of one resolved color). For a 1000-line file with ~10 tokens per line, this is approximately 10,000 extra CSS variable declarations in the DOM. This is well within browser performance budgets and does not cause measurable layout or paint overhead.

The critical benefit is that **theme switching does not re-invoke the Shiki highlighter**. The file is highlighted once when loaded. On theme switch, only CSS variables are re-resolved -- no JavaScript runs, no WASM grammar parsing, no DOM manipulation. This preserves existing performance for initial render time (`NFR-crp-render-time`) and large file scrolling (`NFR-crp-large-file-perf`).

### Transition Performance

The `html[data-theme-transition] *` selector is intentionally short-lived (200ms). While active, it applies transition properties to all elements, which could theoretically cause jank on low-end devices. However:
- The transitions are limited to `background-color`, `color`, `border-color`, and `box-shadow` -- all compositor-friendly properties that do not trigger layout.
- The 150ms duration is short enough to be imperceptible on modern devices.
- The universal `*` selector is only active during the brief transition window.

### Blocking Script

The FOUC prevention script is ~400 bytes of vanilla JavaScript. It executes synchronously during HTML parsing, adding ~0.1ms to page load time. The `localStorage.getItem` call is synchronous and returns in microseconds. The `matchMedia` query is also synchronous. This has no measurable impact on time-to-first-paint.

---

## Error Handling

### localStorage Unavailable (`AC-dm-localstorage-unavailable`)

Both the blocking script and the Zustand store wrap `localStorage` access in `try/catch`:

- **Read failure**: Fall back to `'system'` preference. The app uses OS detection and works normally.
- **Write failure**: The toggle still works for the current session (state is held in the Zustand store and the DOM attribute). Changes are not persisted. No error is shown to the user.

### Invalid Stored Value

If `localStorage` contains an unexpected value (not `'light'`, `'dark'`, or `'system'`), both the blocking script and the store treat it as `'system'`. The invalid value is overwritten on the next `setThemePreference` call.

### matchMedia Unavailable

If `window.matchMedia` is somehow unavailable (extremely unlikely in target browsers), the blocking script defaults to `'light'`. The store also defaults to `'light'` if it cannot query the media query. This is a graceful degradation -- the app works in light mode.

---

## Implementation Plan

Ordered steps with file paths. Each step produces a testable increment.

### Step 1: Create Theme Token File

**File**: `src/styles/theme.css`

Define all CSS custom properties for both `[data-theme="light"]` and `[data-theme="dark"]` selectors. Include transition class, scrollbar styles, and Shiki CSS variable scope rules. All token names and values come directly from the design spec color tables.

**Implements**: `FR-dm-css-custom-properties`, `FR-dm-full-surface-coverage` (token layer)

### Step 2: Add Blocking Theme Script to index.html

**File**: `index.html`

Insert the synchronous `<script>` block in `<head>`, before any `<link>` or module scripts. The script reads `localStorage('shepherd-theme')`, resolves to light/dark, and sets `data-theme` on `<html>`.

**Implements**: `NFR-dm-no-fouc`, `AC-dm-no-fouc`, `AC-dm-persistence-survives-reload`, `AC-dm-persistence-system-survives-reload`, `AC-dm-localstorage-unavailable`

### Step 3: Create Theme Zustand Store

**File**: `src/store/themeStore.ts`

Implement the `ThemeState` interface with `themePreference`, `resolvedTheme`, and `setThemePreference`. Register `matchMedia` change listener. Implement `applyThemeToDOM` with transition class management.

**Implements**: `FR-dm-persistence`, `FR-dm-realtime-tracking`, `FR-dm-manual-toggle` (state layer), `NFR-dm-smooth-transition` (transition class management)

### Step 4: Create ThemeToggle Component

**Files**: `src/components/ThemeToggle.tsx`, `src/components/icons/SunIcon.tsx`, `src/components/icons/MoonIcon.tsx`, `src/components/icons/MonitorIcon.tsx` (or inline SVGs)

Build the segmented control with three options. Wire to `useThemeStore`. Implement WAI-ARIA radio group pattern with keyboard navigation (`ArrowLeft`/`ArrowRight`). Style using theme tokens.

**Implements**: `FR-dm-manual-toggle`, `AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `AC-dm-toggle-to-system`, `AC-dm-keyboard-toggle`

### Step 5: Integrate ThemeToggle into Toolbar

**File**: `src/components/Toolbar.tsx`

Add `<ThemeToggle />` to the right section of the toolbar between navigation controls and Copy button. Ensure it renders in both the file-loaded and empty states.

**Implements**: `FR-dm-manual-toggle` (UI placement)

### Step 6: Migrate app.css to Use Theme Tokens

**File**: `src/styles/app.css`

Import `theme.css`. Replace all hardcoded color values in the `@theme` block with `var(--color-*)` references. Keep non-color tokens (spacing, fonts) unchanged. Verify all Tailwind utility classes still resolve correctly.

**Implements**: `FR-dm-css-custom-properties`, `FR-dm-full-surface-coverage` (bridge layer)

### Step 7: Audit and Migrate Component CSS

**Files**: All `src/components/*.tsx` files

Audit every component for hardcoded color values (inline styles, Tailwind classes with hardcoded colors like `bg-[#fff]`). Replace with theme-token-referencing Tailwind utilities or `var(--color-*)` custom properties. Key components to audit:

- `CodeViewer.tsx` -- line backgrounds, gutter colors, selection highlights
- `CommentBubble.tsx` -- bubble background, border, text colors
- `InlineCommentEditor.tsx` -- editor background, border, shadow
- `FileDropZone.tsx` -- drop zone background, border, hover states
- `DiffViewer.tsx` -- added/removed line backgrounds, indicators
- `CollapsedSectionSeparator.tsx` -- separator background, border, text
- `ConfirmationDialog.tsx` -- dialog background, backdrop, text
- `ToastNotification.tsx` -- toast background, text
- `PreambleInput.tsx` -- input background, border
- `PromptPreview.tsx` -- preview background, text
- `Toolbar.tsx` -- toolbar background, border, button states
- `FileHeader.tsx` -- header background, border

**Implements**: `FR-dm-full-surface-coverage`, `AC-dm-all-surfaces-themed`, `AC-dm-diff-view-themed`, `AC-dm-drop-zone-themed`, `AC-dm-dialog-themed`

### Step 8: Configure Shiki Dual-Theme

**File**: `src/lib/highlighter.ts`

Switch from single-theme `codeToTokens` to dual-theme `codeToHtml` with CSS variables mode. Load both `github-light` and `github-dark` themes. Update the return type and adjust `CodeViewer` to render HTML output.

**Implements**: `NFR-dm-syntax-highlight-both-themes`, `AC-dm-syntax-highlight-dark`, `AC-dm-syntax-highlight-light`

### Step 9: Add matchMedia Listener for Real-Time OS Tracking

**File**: `src/store/themeStore.ts` (already handled in Step 3, but verified here)

Confirm the `matchMedia('(prefers-color-scheme: dark)')` change listener is working. Verify it only fires theme updates when `themePreference === 'system'`. Verify manual overrides (`'light'` / `'dark'`) ignore OS changes.

**Implements**: `FR-dm-realtime-tracking`, `AC-dm-realtime-os-change`, `AC-dm-manual-ignores-os`

### Step 10: Write Tests

**Files**: `src/store/themeStore.test.ts`, `src/components/ThemeToggle.test.tsx`, `e2e/dark-mode.spec.ts`

**Unit tests** (Vitest):
- `themeStore`: preference persistence, resolution logic, DOM attribute updates, localStorage fallback, matchMedia listener behavior
- `ThemeToggle`: rendering, active state display, click handlers, keyboard navigation

**Integration tests** (React Testing Library):
- ThemeToggle + themeStore integration: clicking a segment updates the store and DOM
- Toolbar rendering with ThemeToggle in both file-loaded and empty states

**E2E tests** (Playwright):
- Full page load respects system preference (emulate `prefers-color-scheme`)
- Manual toggle cycle: light -> dark -> system
- Persistence across reload
- Verify no FOUC (screenshot comparison on initial paint)
- All surfaces themed (spot-check key selectors for CSS variable values)

**Implements**: Verification of `AC-dm-default-respects-system`, `AC-dm-default-light-system`, `AC-dm-toggle-to-dark`, `AC-dm-toggle-to-light`, `AC-dm-toggle-to-system`, `AC-dm-persistence-survives-reload`, `AC-dm-persistence-system-survives-reload`, `AC-dm-realtime-os-change`, `AC-dm-manual-ignores-os`, `AC-dm-no-fouc`, `AC-dm-localstorage-unavailable`, `AC-dm-keyboard-toggle`

---

## Requirement Traceability

### Functional Requirements

| Slug | Spec Coverage |
|---|---|
| `FR-dm-system-preference` | FOUC Prevention (blocking script logic); Theme Store (resolveTheme); Implementation Plan Steps 2, 3 |
| `FR-dm-manual-toggle` | ThemeToggle Component; Theme Store (setThemePreference); Implementation Plan Steps 3, 4, 5 |
| `FR-dm-persistence` | Data Model (localStorage schema); Theme Store (read/write localStorage); FOUC Prevention (Phase 1 reads localStorage); Implementation Plan Steps 2, 3 |
| `FR-dm-realtime-tracking` | State Management (matchMedia listener); Implementation Plan Steps 3, 9 |
| `FR-dm-full-surface-coverage` | CSS Architecture (theme.css token file, app.css migration); Implementation Plan Steps 1, 6, 7 |
| `FR-dm-css-custom-properties` | CSS Architecture (entire section); Data Model (token definitions); Implementation Plan Steps 1, 6 |

### Non-Functional Requirements

| Slug | Spec Coverage |
|---|---|
| `NFR-dm-no-fouc` | FOUC Prevention (entire section); Implementation Plan Step 2 |
| `NFR-dm-smooth-transition` | CSS Architecture (transition class in theme.css); State Management (applyThemeToDOM transition logic); Implementation Plan Steps 1, 3 |
| `NFR-dm-syntax-highlight-both-themes` | Shiki Integration (entire section); Implementation Plan Step 8 |
| `NFR-dm-contrast-ratios` | CSS Architecture (token values match design spec contrast-verified values); All tokens are taken directly from design spec's verified contrast tables |
| `NFR-dm-no-performance-impact` | Performance Considerations (entire section) |

### Acceptance Criteria

| Slug | Spec Coverage |
|---|---|
| `AC-dm-default-respects-system` | FOUC Prevention (blocking script reads matchMedia); Theme Store (initializes from matchMedia) |
| `AC-dm-default-light-system` | FOUC Prevention (blocking script defaults to light when matchMedia is false) |
| `AC-dm-toggle-to-dark` | ThemeToggle Component; State Management (setThemePreference) |
| `AC-dm-toggle-to-light` | ThemeToggle Component; State Management (setThemePreference) |
| `AC-dm-toggle-to-system` | ThemeToggle Component; State Management (setThemePreference re-enables matchMedia tracking) |
| `AC-dm-persistence-survives-reload` | FOUC Prevention (blocking script reads localStorage); Data Model (localStorage key) |
| `AC-dm-persistence-system-survives-reload` | FOUC Prevention (blocking script reads 'system' then queries matchMedia) |
| `AC-dm-realtime-os-change` | State Management (matchMedia change listener fires when preference is 'system') |
| `AC-dm-manual-ignores-os` | State Management (matchMedia listener checks themePreference before acting) |
| `AC-dm-syntax-highlight-dark` | Shiki Integration (github-dark theme loaded, CSS variables mode) |
| `AC-dm-syntax-highlight-light` | Shiki Integration (github-light theme loaded, CSS variables mode) |
| `AC-dm-all-surfaces-themed` | CSS Architecture (all surfaces have tokens); Implementation Plan Step 7 (component audit) |
| `AC-dm-diff-view-themed` | CSS Architecture (diff tokens); Implementation Plan Step 7 |
| `AC-dm-drop-zone-themed` | CSS Architecture (drop zone tokens); Implementation Plan Step 7 |
| `AC-dm-dialog-themed` | CSS Architecture (dialog tokens); Implementation Plan Step 7 |
| `AC-dm-no-fouc` | FOUC Prevention (entire section) |
| `AC-dm-localstorage-unavailable` | Error Handling (localStorage unavailable); FOUC Prevention (try/catch in blocking script); State Management (try/catch in store) |
| `AC-dm-keyboard-toggle` | ThemeToggle Component (WAI-ARIA radio group pattern, ArrowLeft/ArrowRight) |
