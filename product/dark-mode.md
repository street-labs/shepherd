# Dark Mode

## Overview

The CRPG currently renders in a fixed light color scheme with no theming system. Dark mode adds a complete light/dark/system theme capability to the application. The default behavior respects the user's operating system preference so the app looks right from the first load without any configuration. Users can also manually override the theme (light, dark, or system) via a toggle in the toolbar, and the choice persists locally so it survives reloads.

**Why**: Developers overwhelmingly prefer dark-themed tooling, especially when working in dimly lit environments or alongside dark-themed editors and terminals. A code review tool that forces a bright white UI clashes with the surrounding workflow. Respecting the OS setting by default means the app integrates seamlessly without any setup.

**Scope**: This is v1 of theming. It introduces the infrastructure (theming tokens, theme detection, persistence) and applies it across all existing UI surfaces. It does not include user-customizable accent colors, per-component theme overrides, or high-contrast accessibility modes beyond ensuring WCAG AA contrast ratios in both themes.

## User Stories

### US-dm-1: App matches my OS theme automatically
**As a** developer, **I want** the CRPG to automatically use dark mode when my OS is set to dark mode, **so that** the app matches my environment without me having to configure anything.

### US-dm-2: Manually switch themes
**As a** developer, **I want** to manually choose between light mode, dark mode, or following my system setting, **so that** I can override the automatic behavior when I prefer a specific look.

### US-dm-3: Theme preference is remembered
**As a** developer, **I want** my theme preference to persist across page reloads, **so that** I do not have to re-select my preferred theme every time I open the app.

### US-dm-4: App follows OS theme changes in real time
**As a** developer, **I want** the app to switch themes automatically when I change my OS appearance setting (while the app is on "system" mode), **so that** the app stays in sync without a page reload.

### US-dm-5: All surfaces are themed consistently
**As a** developer, **I want** every part of the UI (code viewer, toolbar, sidebar, comment bubbles, drop zone, diff view, dialogs) to respect the active theme, **so that** there are no jarring light-on-dark or dark-on-light mismatches.

## Requirements

### Functional Requirements

#### `FR-dm-system-preference` -- Detect and apply OS theme preference
On initial load, if no user override is stored, the application detects the OS color scheme preference using the platform's standard mechanism for detecting OS color scheme and applies the matching theme (light or dark). This is the default behavior for new users.

#### `FR-dm-manual-toggle` -- Manual theme toggle with three options
The application provides a theme toggle control in the toolbar with three options: **Light**, **Dark**, and **System**. Selecting Light or Dark forces that theme regardless of OS setting. Selecting System returns to OS-tracking behavior. The currently active option is visually indicated.

#### `FR-dm-persistence` -- Persist theme preference locally
The user's theme selection (light, dark, or system) is persisted using local storage appropriate to the platform. On subsequent launches, the stored preference is read and applied before the first visible paint. If the stored value is "system", the OS preference is detected and applied. If local storage is unavailable or the stored value is invalid, the app falls back to system preference detection. This is a deliberate, scoped exception to `NFR-crp-no-data-persistence`: theme preference is a UI setting, not user-generated session data.

#### `FR-dm-realtime-tracking` -- Real-time OS preference tracking
When the active theme selection is "system", the application listens for OS preference changes in real time and updates the applied theme in real time without a page reload. When the user has selected an explicit Light or Dark override, OS changes are ignored.

#### `FR-dm-full-surface-coverage` -- Theme applies to all UI surfaces
The active theme must be applied to every visual surface of the application, including but not limited to:
- **Toolbar**: background, text, icons, button states
- **Code viewer**: background, line numbers, gutter indicators, hover/selection highlights
- **Syntax highlighting**: Syntax highlighting must switch between appropriate light and dark variants
- **Comment bubbles**: background, text, border, action button states
- **Inline comment editor**: input background, border, placeholder text, buttons
- **Sidebar**: preamble input, prompt preview panel, section headers
- **Drop zone**: background, border, icon, instructional text, drag-hover state
- **Diff view**: added-line backgrounds, removed-line backgrounds, context lines, collapsed section separators
- **Dialogs**: confirmation dialogs (clear session, switch mode), backdrop
- **Scrollbars**: styled scrollbars must adapt to the active theme
- **Notifications/toasts**: background, text (e.g., "Copied to clipboard")

No surface should remain hardcoded to a single color scheme.

#### `FR-dm-css-custom-properties` -- Theme implemented via a structured theming mechanism
The theme system must use a structured mechanism (such as design tokens or variables) as the foundation for theming. All color values throughout the application reference these tokens rather than hardcoded colors. Switching themes updates the token values, and all surfaces update accordingly. This ensures a single, maintainable source of truth for color definitions. The specific implementation mechanism is an engineering decision.

### Non-Functional Requirements

#### `NFR-dm-no-fouc` -- No flash of wrong theme on load
The correct theme must be applied before the first visible paint. The user must never see a flash of light theme that then switches to dark (or vice versa). This requires applying the theme before any UI renders. The mechanism for achieving this is an engineering decision, but it must not depend on the application framework's initialization.

#### `NFR-dm-smooth-transition` -- Smooth theme transitions
When the user manually toggles themes, the color changes should animate smoothly (smooth, brief animation). The transition must not cause layout shifts. When the app first loads (applying the initial theme), no transition should occur -- transitions only apply to runtime theme switches.

#### `NFR-dm-syntax-highlight-both-themes` -- Syntax highlighting works in both themes
Syntax highlighting must be readable and visually appropriate in both light and dark themes. The syntax highlighting engine must support both light and dark color schemes. Token colors must have sufficient contrast against the code viewer background in both modes. The mechanism for switching themes is an engineering decision.

#### `NFR-dm-contrast-ratios` -- Sufficient contrast ratios in both themes
All text and interactive elements must meet WCAG 2.1 AA contrast requirements (minimum 4.5:1 for normal text, 3:1 for large text and UI components) in both light and dark themes. This applies to all surfaces listed in `FR-dm-full-surface-coverage`.

#### `NFR-dm-no-performance-impact` -- No measurable performance impact
The theming system must not degrade existing performance benchmarks. Specifically: initial render time (`NFR-crp-render-time`), prompt generation time (`NFR-crp-prompt-gen-time`), and large file scrolling performance (`NFR-crp-large-file-perf`) must remain within their existing thresholds. Theme token lookups should have negligible overhead.

## Acceptance Criteria

#### `AC-dm-default-respects-system` -- Default theme matches OS setting
**Given** the user has never used the app before (no stored preference) and their OS is set to dark mode, **when** the app loads, **then** the app renders in dark mode with no intermediate flash of light mode.

#### `AC-dm-default-light-system` -- Default is light when OS is light
**Given** the user has never visited the app before and their OS is set to light mode, **when** the app loads, **then** the app renders in light mode.

#### `AC-dm-toggle-to-dark` -- Manual switch to dark mode
**Given** the app is currently in light mode (either via system or manual), **when** the user selects "Dark" from the theme toggle, **then** all UI surfaces transition to dark mode colors smoothly, and the toggle indicates "Dark" as the active selection.

#### `AC-dm-toggle-to-light` -- Manual switch to light mode
**Given** the app is currently in dark mode, **when** the user selects "Light" from the theme toggle, **then** all UI surfaces transition to light mode colors smoothly, and the toggle indicates "Light" as the active selection.

#### `AC-dm-toggle-to-system` -- Manual switch back to system
**Given** the user previously selected "Dark" and their OS is set to light mode, **when** the user selects "System" from the theme toggle, **then** the app switches to light mode (matching the OS), and the toggle indicates "System" as the active selection.

#### `AC-dm-persistence-survives-reload` -- Theme preference survives page reload
**Given** the user has selected "Dark" from the theme toggle, **when** the user reloads the page, **then** the app loads in dark mode without any flash of light mode, and the toggle shows "Dark" as the active selection.

#### `AC-dm-persistence-system-survives-reload` -- System preference survives reload
**Given** the user has selected "System" and their OS is in dark mode, **when** the user reloads the page, **then** the app loads in dark mode (from system detection) without any flash of light mode, and the toggle shows "System" as the active selection.

#### `AC-dm-realtime-os-change` -- App follows OS change in system mode
**Given** the theme toggle is set to "System" and the OS is in light mode, **when** the user switches their OS to dark mode, **then** the app transitions to dark mode in real time without a page reload.

#### `AC-dm-manual-ignores-os` -- Manual override ignores OS changes
**Given** the user has selected "Light" from the theme toggle, **when** the user switches their OS to dark mode, **then** the app remains in light mode (the manual override takes precedence).

#### `AC-dm-syntax-highlight-dark` -- Syntax highlighting is readable in dark mode
**Given** a TypeScript file is loaded and the app is in dark mode, **when** the user views the code, **then** syntax highlighting uses a dark-appropriate color palette with all tokens clearly visible against the dark background.

#### `AC-dm-syntax-highlight-light` -- Syntax highlighting is readable in light mode
**Given** a TypeScript file is loaded and the app is in light mode, **when** the user views the code, **then** syntax highlighting uses a light-appropriate color palette with all tokens clearly visible against the light background.

#### `AC-dm-all-surfaces-themed` -- Every UI surface respects the theme
**Given** the app is in dark mode with a file loaded, comments placed, and the sidebar open, **when** the user inspects every visible surface (toolbar, code viewer, comment bubbles, gutter, sidebar, prompt preview, preamble input), **then** all surfaces use dark mode colors with no light-mode holdouts.

#### `AC-dm-diff-view-themed` -- Diff view respects the theme
**Given** the app is in dark mode and diff view is active, **when** the user inspects the diff view, **then** added-line backgrounds, removed-line backgrounds, context lines, collapsed section separators, and line numbers all use dark-mode-appropriate colors that remain distinguishable.

#### `AC-dm-drop-zone-themed` -- Drop zone respects the theme
**Given** the app is in dark mode with no file loaded, **when** the user views the drop zone empty state, **then** the drop zone background, border, icon, and text use dark mode colors. **When** the user drags a file over the drop zone, **then** the drag-hover state also uses dark mode colors.

#### `AC-dm-dialog-themed` -- Dialogs respect the theme
**Given** the app is in dark mode and the user has placed comments, **when** the user clicks Clear and the confirmation dialog appears, **then** the dialog background, text, buttons, and backdrop overlay all use dark mode colors.

#### `AC-dm-no-fouc` -- No flash of wrong theme on initial load
**Given** the user's stored preference is "Dark" (or system is dark with "System" stored), **when** the page loads and renders, **then** there is no visible flash of a light background that then transitions to dark. The initial paint is already dark.

#### `AC-dm-localstorage-unavailable` -- Graceful fallback without local storage
**Given** local storage is unavailable, **when** the app loads, **then** the app falls back to detecting the OS preference and applies the matching theme. The theme toggle still works for the current session (changes are not persisted).

#### `AC-dm-keyboard-toggle` -- Theme toggle is keyboard accessible
**Given** the user is navigating with the keyboard, **when** the user tabs to the theme toggle and interacts with it, **then** the user can cycle through Light/Dark/System options without using a mouse.

## Open Questions

No open questions. The scope is well-defined. The implementation approach is an engineering decision.

## Dependencies

- **Syntax highlighting dual-theme support** (`FR-crp-syntax-highlight`): The syntax highlighting engine must support two themes (one light, one dark). The engineering spec determines the approach.
- **Scoped exception to `NFR-crp-no-data-persistence`**: Theme preference persistence is explicitly permitted as a UI-settings-only exception. This does not set a precedent for persisting session data.
