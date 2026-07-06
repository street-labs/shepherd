# Slash Command Launcher — macOS Platform

> macOS-specific requirements for the slash command launcher. See `../slash-command.md` for shared requirements.

## Overview

The slash command (`/shepherd`) lets developers launch the macOS Code Review Prompt Generator from within an AI coding agent. It opens the native macOS application in its own window.

There is no automatic platform detection — invoking `/shepherd` always launches the native macOS application.

## Shared Requirements — Applicability on macOS

The following shared requirements apply identically when invoking `/shepherd`, with the substitution of "the CRPG" for "the macOS CRPG application":

- `FR-sc-file-resolution` — Resolve file paths
- `FR-sc-file-validation` — Validate the target file before launch
- `FR-sc-auto-load-file` — Automatically load the file
- `FR-sc-invoke-command` — Argument handling and usage message
- `NFR-sc-launch-speed` — Launch latency budget
- `AC-sc-no-args-usage` — Usage message when no arguments
- `AC-sc-binary-file-rejected` — Binary file rejection
- `AC-sc-file-not-found` — Missing file rejection

The following shared requirements are **replaced** by macOS-specific variants below:

- `FR-sc-app-serve` — Replaced by `FR-sc-mac-launch` (no local server; the app is a standalone binary).
- `FR-sc-browser-open` — Replaced by `FR-sc-mac-launch` (no browser; the app opens its own window).
- `FR-sc-file-api` — Does not apply (no server). Replaced by `FR-sc-mac-session-handoff`.

## macOS-Specific Functional Requirements

#### `FR-sc-mac-invoke-command` -- Invoke the macOS CRPG via slash command
The user can type `/shepherd <filepath>` to launch the macOS CRPG with the specified file. Argument handling matches `/shepherd` exactly: missing arguments produce a usage message; invalid files produce the same error messages as `FR-sc-file-validation`.

#### `FR-sc-mac-launch` -- Launch the prebuilt macOS application
On invocation, the command launches the macOS CRPG application directly. The application opens its own window; no browser or local web server is involved. The application receives the session identifier via a launch argument and reads its file payload from a per-session staging location on disk.

#### `FR-sc-mac-session-handoff` -- Hand off file payload via session directory
Before launching the application, the slash command writes the validated file path and contents into the per-session staging area (the same `~/.shepherd/sessions/<id>/` directory used for prompt-output handoff). The application reads the staging file at startup, displays the file in the code viewer, and writes its prompt output back to the same directory when the user clicks **Done**, identically to the shared `FR-sc-prompt-receive` flow.

#### `FR-sc-mac-prebuild` -- Prepare the macOS application during install
The installer prepares the macOS application so the first invocation of `/shepherd` is fast. After the installer completes, invoking `/shepherd` does not require a build step or dependency download. If preparation fails (e.g., missing toolchain), the installer reports the failure but does not block the rest of the install.

## macOS-Specific Acceptance Criteria

- [ ] `AC-sc-mac-launches-app` — `/shepherd <valid-file>` opens the macOS CRPG window with the file loaded within the latency budget defined in `NFR-sc-launch-speed`.
- [ ] `AC-sc-mac-no-server` — Launching `/shepherd` does not start or rely on a local web server.
- [ ] `AC-sc-mac-prompt-roundtrip` — After clicking **Done** in the macOS app, the prompt output is delivered back to the agent conversation, matching the shared `FR-sc-prompt-receive` behavior.
- [ ] `AC-sc-mac-coexists` — Both `/shepherd` and `/shepherd-review` are available simultaneously after install. Invoking one does not affect the other.
- [ ] `AC-sc-mac-prebuild-fast` — On a machine where the installer completed successfully, the first `/shepherd` invocation reaches an open window within `NFR-sc-launch-speed`.
- [ ] `AC-sc-mac-prebuild` — When the prebuild step fails (e.g., missing Swift toolchain), the installer reports the failure but does not abort the rest of the install. `/shepherd` is unavailable until the user fixes the toolchain and reruns the installer.

## Open Questions

- Should `/shepherd-review` (the multi-file batch variant) ship in the same release? Currently deferred to a follow-up.

## Dependencies

- macOS variant of the Code Review Prompt Generator (`product/macos/code-review-prompt.md`).
- Session staging directory contract (`FR-crp-prompt-handoff`).
