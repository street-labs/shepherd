# Slash Command Launcher — macOS Technical Spec

> Based on requirements in `../../product/slash-command.md`
> See also `../../product/macos/slash-command.md` for macOS-specific requirements.
> Based on design in `../../design/macos/code-review-prompt.md` (no separate design spec — the launch surface is the existing macOS CRPG window).

## Technical Approach

The macOS slash command (`/shepherd`) uses the staging-directory contract (`~/.shepherd/sessions/<id>/`) without any local web server. The launch flow is:

1. Slash command resolves and validates the file (shared logic with web).
2. Launcher script writes `~/.shepherd/sessions/<id>/session.json` containing the session ID, working directory, and one entry in `files[]` with the absolute file path and contents.
3. Launcher invokes the prebuilt `ShepherdApp` binary with `--session <id>`.
4. The macOS app reads `session.json` via `SessionClient.loadSession`, populates state, and presents the file in the code viewer.
5. On **Done**, the app writes `prompt-output.md` to the same directory.
6. The slash command Read-tool's the prompt output and surfaces it back to the agent.

No web server, no port management. The native binary owns its window and lifecycle.

## Components

### Prebuilt binary

- Located at `engineering/apps/macos/.build/release/ShepherdApp` after `swift build -c release`.
- Built once during `scripts/install-command.sh` execution.
- Already accepts `--session <id>` (see `ShepherdApp.swift:20–24`).
- Already understands `~/.shepherd/sessions/<id>/session.json` (see `Sources/Dependencies/SessionClient.swift:24–30`).

### Launcher script — `scripts/shepherd-launch.sh`

The launcher `scripts/shepherd-launch.sh` handles file resolution, binary detection, line-count warning, and session ID derivation.

Responsibilities:
1. Parse positional `<filepath>` argument (single file for v1; multi-file deferred until `/shepherd-review`).
2. Resolve the path with `realpath` (with a fallback when `realpath` is unavailable).
3. Validate: existence, readability, not-a-directory, null-byte-free.
4. Compute `SESSION_ID` from the project root basename.
5. Verify the prebuilt binary exists at `engineering/apps/macos/.build/release/ShepherdApp`. If missing, exit non-zero with a message instructing the user to re-run the installer.
6. Create `~/.shepherd/sessions/<id>/`, write `session.json`:
   ```json
   {
     "sessionID": "<id>",
     "workingDirectory": "<repo-root>",
     "projectName": "<basename>",
     "files": [{"path": "<absolute>", "content": "<file contents>"}],
     "reviewContext": null
   }
   ```
7. Launch the binary detached: `"$BINARY" --session "$SESSION_ID" >/dev/null 2>&1 &`. The `&` lets the script return immediately so the agent does not block on the GUI process.
8. Print `Session: <id>` and a one-line summary on stdout so the slash command can parse session info.

Exit codes: `0` success, `1` validation error, `2` launch failure (binary missing, etc.).

### Slash command file — `.claude/commands/shepherd.md`

The Claude Code command file `.claude/commands/shepherd.md`:
1. Launcher path: `bash "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" $ARGUMENTS`.
2. Help text references `/shepherd` and notes the macOS app is launched.

The post-launch flow (`AskUserQuestion` with Added comments / No comments / Cancel; `prompt-output.md` read; cleanup) follows the standard staging-directory contract.

### Opencode skill — `.config/opencode/skills/shepherd/SKILL.md`

The opencode skill `.config/opencode/skills/shepherd/SKILL.md` mirrors the Claude command file, using the same launcher.

### pi prompt template — `~/.pi/agent/prompts/shepherd.md`

pi (pi.dev) discovers prompt templates from `~/.pi/agent/prompts/<name>.md` and expands them as `/<name>`. Because pi supports `$ARGUMENTS` natively (the same token the Claude command uses), the installer symlinks the existing `.claude/commands/<name>.md` file directly into pi's prompts directory — no separate pi-specific copy is maintained. Updates propagate via `git pull` like the other two targets.

### Installer changes — `scripts/install-command.sh`

1. Add `shepherd` to the `COMMANDS` array so symlinks are created for Claude Code (`~/.claude/commands/`), opencode (`~/.config/opencode/skills/`), and pi (`~/.pi/agent/prompts/`).
2. After symlinks, add a prebuild step:
   ```bash
   if command -v swift >/dev/null 2>&1; then
     (cd "$REPO_ROOT/engineering/apps/macos" && swift build -c release) || \
       echo "Warning: macOS app build failed; /shepherd will not work until rebuilt"
   else
     echo "Warning: swift not found; /shepherd will not work until you install Swift and re-run this script"
   fi
   ```
3. Build failure does not abort the install (`AC-sc-mac-prebuild` allows degraded install when toolchain is missing).

## Why session.json instead of CLI args for files

The macOS app's existing `SessionClient.loadSession` reads `session.json`. Passing file paths via `--file` flags would require new CLI plumbing in the app and divergence from the existing handoff contract. Writing `session.json` from the launcher costs ~20 lines of bash and reuses the production code path that `/shepherd-review` (deferred) will also need.

## Why the binary, not `swift run`

`swift run` rebuilds on each invocation (~30s+ cold). `swift build -c release` once at install-time produces a static binary with sub-second startup, satisfying `NFR-sc-launch-speed`. The binary is regenerated on the next `git pull && ./scripts/install-command.sh` cycle.

## Implementation Plan

1. Add `scripts/shepherd-launch.sh`.
2. Update `scripts/install-command.sh` to (a) include `shepherd` in symlink loop and (b) prebuild the macOS app.
3. Add `.claude/commands/shepherd.md`.
4. Add `.config/opencode/skills/shepherd/SKILL.md`.
5. Run installer; verify binary exists and slash command resolves.
6. Manual smoke test: invoke `/shepherd` with a known file, confirm window opens with file loaded, click Done, verify prompt output round-trips.

## Out of Scope (deferred)

- `/shepherd-review` multi-file batch flow. Will reuse the launcher with a multi-file `session.json` writer once the single-file flow is proven.
- Code-signing / notarization. The binary runs unsigned for personal/dev use; first-launch Gatekeeper prompt is acceptable.
- Auto-rebuild on `git pull`. Users re-run the installer.
