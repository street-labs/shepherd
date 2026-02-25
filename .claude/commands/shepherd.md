Open the Code Review Prompt Generator (CRPG) with the specified file.

Allowed tools: Bash

Arguments: $ARGUMENTS

Suggested arguments: <filepath>

## Instructions

The file to open: `$ARGUMENTS`

If no file argument was provided (empty or blank), respond with: "Usage: /shepherd <filepath>" and stop.

Otherwise, do the following steps:

### Step 1: Locate the Shepherd repository and run the launcher script

First, resolve the Shepherd repo root. This skill may be invoked from any repo via a global symlink, so we cannot assume the current working directory is the Shepherd repo. Try these in order:

1. **Saved repo path** (set by `sq run ... install`):
```bash
SHEPHERD_ROOT="$(cat ~/.shepherd/repo-path 2>/dev/null)"
```

2. **Symlink resolution** (if installed via manual symlink):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$(cd "$(dirname "$(readlink -f "$(echo ~/.claude/commands/shepherd.md)")")"/../.. && pwd)"
```

3. **Current repo fallback** (if running from within the Shepherd repo):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
```

If `$SHEPHERD_ROOT/scripts/shepherd-launch.sh` still doesn't exist, output: "Could not find shepherd-launch.sh. Run `sq run personal-lstreet-shepherd install --full-clone` to set up Shepherd." and stop.

Derive the session ID (same logic as the launch script) and clean stale session data before launching, so review context from a prior `/shepherd-review` doesn't leak through:

```bash
SESSION_ID=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
rm -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md ~/.shepherd/sessions/$SESSION_ID/review-context.json
```

Then run the launcher script to validate the file, ensure the dev server is running, and open the CRPG in an app-mode browser window:

```
bash "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" $ARGUMENTS
```

The script handles file validation, dev server management, and browser opening — all in one shot.

Relay the script's stdout as a summary message. If the script exits non-zero, relay its stderr as an error message instead.

Parse the `Session: <id>` line from the script's stdout to extract the SESSION_ID.

### Step 2: Ask the user about their review

Tell the user: "Annotate your code and click **Done** when you're finished, then come back here."

Use `AskUserQuestion` to present the user with these options:

- **"Added comments"** (description: "I annotated the code in the CRPG and clicked Done")
- **"No comments"** (description: "I'm done but have no comments to add")
- **"Cancel"** (description: "Abandon this session")

Based on the response:

- **"Added comments"**: Read `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` with the Read tool. If the file does not exist, tell the user "Could not find prompt output. Make sure you clicked 'Done' in the CRPG." and re-ask. Otherwise, the file contents are the review prompt. Read it carefully and proceed to make the requested code changes based on the prompt contents. Clean up the session directory afterwards: `rm -rf ~/.shepherd/sessions/$SESSION_ID`.
- **"No comments"**: Output "No comments added. Session complete." and stop.
- **"Cancel"**: Output "Session cancelled." Clean up: `rm -rf ~/.shepherd/sessions/$SESSION_ID`. Stop.
