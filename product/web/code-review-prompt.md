# Code Review Prompt Generator — Web Platform

> Web-specific requirements for the CRPG. See `../code-review-prompt.md` for shared requirements.

## Web-Specific Requirements

### `NFR-crp-browser-support` -- Browser compatibility
The application must work in the latest stable versions of Chrome, Firefox, Safari, and Edge.

### `NFR-crp-responsive-layout` -- Responsive layout
The application must be usable on viewports from 1024px wide and above. Below 1024px, the application may show a message recommending a wider viewport. It is not required to support mobile.

## Web-Specific Acceptance Criteria

### `AC-crp-done-auto-close` -- Window closes automatically after Done succeeds (web)
**Given** the CRPG is running in an app-mode browser window (opened via Chrome's `--app` flag) and the user clicks Done and the handoff succeeds, **then** the browser window closes automatically via `window.close()`, returning focus to the terminal. If the window cannot be closed (e.g., opened as a regular browser tab instead of app mode), the CRPG falls back to showing the confirmation state.

### `AC-crp-done-confirmation` -- Done action shows confirmation state (web fallback)
**Given** the user clicks Done, the prompt handoff succeeds, but the browser window cannot be auto-closed (not in app-mode), **then** the CRPG shows a confirmation message (e.g., "Prompt sent to agent! Switch back to your terminal.") and the Done button changes to a "Sent" state.

## Web-Specific Notes

- `NFR-crp-client-only` on web: The app runs client-side in the browser. In slash command mode, same-origin requests go to the local Vite dev server for file loading and prompt handoff. No data leaves the local machine.
