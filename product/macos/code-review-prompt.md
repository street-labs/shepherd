# Code Review Prompt Generator — macOS Platform

> macOS-specific requirements for the CRPG. See `../code-review-prompt.md` for shared requirements.

## Shared Requirements — Applicability on macOS

Most shared requirements apply to macOS as-is. This section notes exceptions and modifications.

### Apply as-is (no macOS-specific changes needed)

The following shared requirements apply identically on macOS:

- `FR-crp-file-display` — Display file with line numbers
- `FR-crp-line-wrap` — Toggle line wrapping in the code viewer
- `FR-crp-syntax-highlight` — Syntax highlighting
- `FR-crp-line-comment-create` — Create an inline comment
- `FR-crp-line-comment-edit` — Edit an existing comment
- `FR-crp-line-comment-delete` — Delete a comment
- `FR-crp-comment-indicator` — Visual indicators for commented lines
- `FR-crp-comment-count` — Display total comment count
- `FR-crp-prompt-preamble` — Overall Comment
- `FR-crp-prompt-generate` — Automatically generated aggregated prompt
- `FR-crp-prompt-preview` — Live prompt preview
- `FR-crp-prompt-copy` — Copy prompt to clipboard
- `FR-crp-prompt-format` — Structured prompt format
- `FR-crp-prompt-handoff` — Prompt handoff to agent via server
- `FR-crp-clear-session` — Clear / reset session
- `FR-crp-filename-display` — Display file name
- `FR-crp-line-range-comment` — Comment on a range of lines
- `FR-crp-comment-navigation` — Navigate between comments
- `FR-crp-multi-file-load` — Load multiple files for review
- `FR-crp-multi-file-nav` — Navigate between loaded files
- `FR-crp-multi-file-remove` — Remove a file from the session
- `FR-crp-multi-file-prompt` — Combined multi-file prompt generation
- `FR-crp-multi-file-prompt-format` — Multi-file prompt format
- `FR-crp-review-context-receive` — Receive context data from the agent
- `FR-crp-review-context-display` — Display review context in the CRPG
- `FR-crp-review-context-overall` — Display overall changeset context
- `FR-crp-review-context-per-file` — Display per-file context
- `FR-crp-review-context-collapsible` — Collapsible review context
- `FR-crp-comment-summary` — All Comments summary view
- `FR-crp-panel-resize` — Resizable file browser sidebar
- `FR-crp-active-file-path` — Display active file path at top of code viewer
- `FR-crp-file-tooltip` — File row tooltip with full path and metadata
- `FR-crp-file-reviewed-toggle` — Mark/unmark a file as reviewed
- `FR-crp-file-reviewed-visual` — Visual distinction for reviewed files
- `FR-crp-file-reviewed-grouping` — Review status within the directory tree
- `FR-crp-file-reviewed-progress` — Review progress indicator
- `FR-crp-file-reviewed-persistence` — Review status session persistence
- `NFR-crp-large-file-perf` — Large file performance
- `NFR-crp-render-time` — Initial render time
- `NFR-crp-prompt-gen-time` — Prompt generation time
- `NFR-crp-client-only` — Client-side only architecture
- `NFR-crp-accessibility-keyboard` — Keyboard accessibility
- `NFR-crp-no-data-persistence` — No data persistence requirement

### Modified on macOS

- **`FR-crp-file-load`** — File loading behavior is the same (paste, upload, drag-and-drop), but macOS adds a native file open panel and Finder drag-and-drop. See `FR-crp-macos-file-open-panel` and `FR-crp-macos-drag-drop-finder`.

- **`FR-crp-done-action`** — The Done action behavior is the same, but on macOS the auto-close is reliable (no platform restrictions like the web). See `FR-crp-macos-auto-close`.

- **`FR-crp-session-identity`** — Session context is displayed in the native window title bar, following macOS window title conventions.

### Do not apply on macOS

- **`NFR-crp-browser-support`** — Not applicable. This is a native application, not a browser-based application.

- **`NFR-crp-responsive-layout`** — Not applicable. The macOS app uses a native resizable window rather than a browser viewport. See `FR-crp-macos-window-management` for window sizing behavior.

## macOS-Specific Functional Requirements

### `FR-crp-macos-window-management` -- Native window management

The application runs as a native macOS window. Each concurrent session opens in its own window. The user can open multiple windows for different review sessions simultaneously. Each window operates independently — actions in one window do not affect another. The application remembers window position and size between launches, restoring the last-used dimensions when a new window opens. Standard macOS window behaviors apply: minimize, zoom (maximize), full-screen, and close. The minimum window size must ensure all panels (file browser, code viewer, prompt preview) remain usable.

### `FR-crp-macos-menu-bar` -- Native menu bar integration

The application provides a standard macOS menu bar with menus appropriate to its functionality. Menus include at minimum: a File menu for opening files, an Edit menu for text operations (copy, paste, undo, redo), and a View menu for appearance and layout options. Menu items reflect the current application state — for example, the Copy Prompt menu item is disabled when no comments exist, and Undo/Redo are enabled only when applicable. Keyboard shortcut equivalents are displayed in the menu items. The application menu (named after the app) includes standard items: About, Preferences, and Quit.

### `FR-crp-macos-keyboard-shortcuts` -- macOS keyboard shortcuts

All keyboard shortcuts follow macOS conventions using standard modifier keys (Cmd, Option, Shift, Control). At minimum, the following shortcuts must be available:
- Open file (standard macOS open shortcut)
- Copy (contextual: copies the prompt text when the prompt panel is focused, standard text copy otherwise)
- Paste file content (pastes file content from clipboard into the session)
- Close window (closes the current window)
- Open preferences (standard macOS preferences shortcut)
- Undo and Redo for comment editing
Shortcuts must not conflict with each other or with standard system-wide macOS shortcuts. All shortcuts must be discoverable through the menu bar.

### `FR-crp-macos-file-open-panel` -- Native file open panel

The user can open files using the native macOS file open panel. The panel supports selecting one or multiple files simultaneously. When multiple files are selected, all are loaded into the current session. The file open panel respects the application's file type restrictions (plain-text files only; binary files are rejected per the shared spec's null-byte detection). The open panel remembers the last-used directory within the application session.

### `FR-crp-macos-drag-drop-finder` -- Drag and drop from Finder

The user can drag one or more files from Finder and drop them onto the application window to load them. Drag-and-drop works on any valid drop target area within the window (consistent with the shared spec's drag-and-drop behavior). Files loaded via drag-and-drop use their actual file system path for display and prompt generation. A visual indicator shows when files are being dragged over a valid drop target.

### `FR-crp-macos-clipboard` -- Native clipboard integration

Copy and paste operations use the native system clipboard. The "Copy Prompt" action places the prompt text on the system clipboard, making it available to all applications. Paste operations accept plain text content from the system clipboard for file loading (consistent with the shared spec's paste behavior).

### `FR-crp-macos-system-appearance` -- System appearance integration

The application follows the macOS system appearance setting (light or dark) automatically. When the user changes the system appearance in macOS System Settings, the application updates its appearance without requiring a restart or any in-app toggle. There is no separate in-app appearance toggle — the application always matches the system setting. This differs from the web platform, which provides its own dark mode toggle.

### `FR-crp-macos-auto-close` -- Reliable window close on Done

When the user clicks Done in slash command mode and the prompt handoff succeeds, the application window closes reliably. Unlike the web platform, the macOS native window close has no platform restrictions — it always succeeds. After the window closes, focus returns to the previously active application (typically the terminal). If only one window is open, closing it leaves the application running with no windows (standard macOS behavior); the application can be reactivated from the Dock or by launching a new session.

### `FR-crp-macos-slash-command-launch` -- Slash command session launch

The application can be launched by the CLI with a session ID to open directly into a review session. The session ID and associated data are passed at launch time. The application reads session data (files, context) from the session directory (`~/.shepherd/sessions/<session-id>/`). If the application is already running, launching a new session opens a new window for that session rather than replacing the current one. If launched with a session ID that already has an open window, the existing window is brought to the front instead of opening a duplicate.

### `FR-crp-macos-standalone-mode` -- Standalone mode without session

When the application is launched without a session ID (for example, by opening it from Finder or the Dock), it opens in standalone mode. In standalone mode, the user loads files via the file open panel, paste, or drag-and-drop. The Copy button is the primary action; the Done button is not shown. This matches the standalone behavior described in the shared spec.

### `FR-crp-macos-sandboxed-file-access` -- Secure file access

When the application is distributed as a standalone bundle outside the App Store, it handles file access permissions appropriately. Files opened via the file open panel or drag-and-drop are accessible through the standard security mechanisms. The application does not require blanket file system access — it only accesses files the user has explicitly selected or the session directory. If a file cannot be read due to permissions, the application shows a clear error message.

### `FR-crp-macos-distribution` -- Application distribution

The application is distributed as a standalone application bundle. It can be installed via a package manager or direct download. The application is signed and notarized for compatibility with the macOS security system (Gatekeeper), so users can open it without encountering "unidentified developer" warnings. The application does not require an App Store listing.

## macOS-Specific Non-Functional Requirements

### `NFR-crp-macos-launch-time` -- Application launch time

The application must launch and be ready for user interaction within 1 second from a cold start (the application is not already running). "Ready for interaction" means the window is visible and the user can load files or view session data. This is a native-app performance expectation.

### `NFR-crp-macos-memory` -- Memory usage

The application must use less than 200 MB of RAM for a typical session consisting of 10 loaded files with a total of 50 comments. Idle memory usage (application running with no files loaded) must be under 80 MB.

### `NFR-crp-macos-min-version` -- Minimum macOS version

The application requires macOS 14 (Sonoma) or later. Users on earlier macOS versions cannot run the application. The application may display a clear error or fail to launch with an informative message on unsupported versions.

## macOS-Specific Acceptance Criteria

### `AC-crp-macos-window-open` -- Each session opens in its own window
**Given** a review session is already open in a window, **when** a new session is launched via the CLI, **then** a new window opens for the new session. Both windows operate independently.

### `AC-crp-macos-window-restore` -- Window position and size are remembered
**Given** the user resizes and repositions the application window, **when** they quit the application and relaunch it, **then** the new window opens at the previously saved position and size.

### `AC-crp-macos-window-deduplicate` -- Duplicate session raises existing window
**Given** a session with ID "abc123" is already open in a window, **when** the CLI launches the application with the same session ID "abc123", **then** the existing window is brought to the front instead of opening a second window for the same session.

### `AC-crp-macos-menu-copy-disabled` -- Copy Prompt menu item disabled without comments
**Given** no comments exist on any file, **then** the Copy Prompt menu item in the Edit menu is disabled (grayed out). **When** the user adds a comment, **then** the Copy Prompt menu item becomes enabled.

### `AC-crp-macos-menu-shortcuts` -- Menu items show keyboard shortcuts
**Given** the user opens any menu, **then** each menu item that has a keyboard shortcut displays the shortcut key combination alongside the item name.

### `AC-crp-macos-open-panel-multi` -- File open panel supports multiple selection
**Given** the user opens the file open panel, **when** they select 3 files and confirm, **then** all 3 files are loaded into the session.

### `AC-crp-macos-drag-drop-finder-path` -- Drag-and-drop from Finder preserves file path
**Given** the user drags a file from Finder at path `/Users/dev/project/src/utils.ts`, **when** the file is dropped onto the application, **then** the file is loaded and its full path `src/utils.ts` (relative to the project root, or the full path) is used in the prompt and file browser.

### `AC-crp-macos-appearance-follows-system` -- Appearance follows system setting
**Given** the macOS system is set to dark appearance, **when** the application is launched, **then** it renders with a dark appearance. **When** the user switches the system to light appearance (via System Settings), **then** the application updates to light appearance without restarting.

### `AC-crp-macos-no-appearance-toggle` -- No in-app appearance toggle
**Given** the application is running, **then** there is no in-app toggle or setting for switching between light and dark appearance. The appearance is controlled solely by the system setting.

### `AC-crp-macos-auto-close-reliable` -- Done action reliably closes the window
**Given** the CRPG is running in slash command mode, **when** the user clicks Done and the handoff succeeds, **then** the window closes and focus returns to the previously active application (the terminal). There is no fallback confirmation state needed because the close is always reliable.

### `AC-crp-macos-slash-command-launch-session` -- CLI launch opens session with data
**Given** the CLI invokes the application with session ID "abc123", **when** the application opens, **then** it reads the session data from `~/.shepherd/sessions/abc123/` and loads the files and context specified by the session. The window title reflects the session context.

### `AC-crp-macos-standalone-no-done` -- Standalone mode hides Done button
**Given** the application is launched without a session ID (e.g., from Finder), **then** the Done button is not shown and the Copy button is the primary action.

### `AC-crp-macos-standalone-open-panel` -- Standalone mode supports file open panel
**Given** the application is in standalone mode, **when** the user uses the Open menu item or keyboard shortcut, **then** the native file open panel appears and files can be loaded into the session.

### `AC-crp-macos-file-permission-error` -- Inaccessible file shows error
**Given** the user attempts to open a file that the application does not have permission to read, **then** an error message is displayed indicating the file could not be read due to permissions, and the application does not crash.

### `AC-crp-macos-signed-notarized` -- Application passes Gatekeeper
**Given** the application is downloaded from the distribution channel, **when** the user opens it for the first time, **then** macOS does not show an "unidentified developer" warning. The application opens normally.

### `AC-crp-macos-launch-cold` -- Cold launch within 1 second
**Given** the application is not running, **when** it is launched, **then** the window is visible and interactive within 1 second.

### `AC-crp-macos-memory-typical` -- Memory stays under 200 MB for typical session
**Given** 10 files are loaded with a total of 50 comments, **then** the application's memory usage does not exceed 200 MB.

### `AC-crp-macos-min-version-enforced` -- Application requires macOS 14+
**Given** a user is running macOS 13 or earlier, **when** they attempt to launch the application, **then** the application does not launch (or displays an informative error). On macOS 14 or later, the application launches normally.

### `AC-crp-macos-multi-window-independent` -- Windows operate independently
**Given** two session windows are open, **when** the user adds a comment in window A, **then** window B is unaffected — its files, comments, and state remain unchanged.

### `AC-crp-macos-close-last-window` -- Closing last window keeps app running
**Given** only one window is open, **when** the user closes it (via Done or the close button), **then** the application remains running with no windows (visible in the Dock). The user can open a new window by launching a new session or reactivating the application.

## macOS-Specific Notes

- `NFR-crp-client-only` on macOS: All processing happens locally within the native application process. In slash command mode, the application reads session data from the local file system and writes prompt output to the session directory. No data leaves the local machine.

- `NFR-crp-no-data-persistence` on macOS: Session data (loaded files, comments, preamble) is held in memory and not persisted. However, window geometry (position and size) IS persisted across launches as this is standard macOS application behavior and is not session data.

- `NFR-crp-accessibility-keyboard` on macOS: Keyboard accessibility is achieved through macOS keyboard navigation conventions (Tab to move focus, Space to activate, standard modifier-key shortcuts). The application supports the macOS accessibility frameworks for VoiceOver compatibility.

## Open Questions

1. **URL scheme vs. direct launch**: Should the CLI launch the macOS app via a custom URL scheme (e.g., `shepherd://open?session=<id>`), by launching the app bundle directly with command-line arguments, or via an XPC service? This is an engineering decision, but product needs to know whether both methods should be supported for flexibility.

2. **Multiple-window limit**: Should there be a maximum number of concurrent session windows? The shared spec has no file count limit; similarly, no window count limit is proposed, but very large numbers of windows (20+) may degrade the user experience.

3. **Session recovery on relaunch**: When the application quits with open session windows (e.g., due to a system restart), should it offer to reopen those sessions on next launch? This is deferred consistent with `NFR-crp-no-data-persistence`, but it is a natural future enhancement for the native app.

4. **Homebrew cask naming**: The distribution mentions Homebrew cask as an installation method. The cask name and tap location are engineering/distribution decisions, but product should confirm the desired install experience (e.g., `brew install --cask shepherd`).
