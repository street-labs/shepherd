Open the Code Review Prompt Generator (CRPG) with the specified file.

Allowed tools: Bash

Arguments: $ARGUMENTS

Suggested arguments: <filepath>

## Instructions

The file to open: `$ARGUMENTS`

If no file argument was provided (empty or blank), respond with: "Usage: /shepherd <filepath>" and stop.

Otherwise, do the following steps:

### Step 1: Run the launcher script

Run the launcher script to validate the file, ensure the dev server is running, and open the CRPG in an app-mode browser window:

```
bash "$REPO_ROOT/scripts/shepherd-launch.sh" "$ARGUMENTS"
```

Where `$REPO_ROOT` is the root of the Shepherd repository (the directory containing this `.claude/` folder). The script handles file validation, dev server management, and browser opening — all in one shot.

Relay the script's stdout as a summary message. If the script exits non-zero, relay its stderr as an error message instead.

Parse the `Session: <id>` line from the script's stdout to extract the SESSION_ID.

### Step 2: Clean up stale prompt output

Remove any leftover output file from a previous session:
```bash
rm -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md
```

### Step 3: Wait for the prompt

Tell the user: "Annotate your code and click **Done** when you're finished. I'll wait for your prompt."

Then run the file watcher — a blocking loop that waits for the CRPG's Done action to write the prompt:
```bash
i=0; while [ ! -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md ] && [ $i -lt 1800 ]; do sleep 1; i=$((i+1)); done; if [ -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md ]; then cat ~/.shepherd/sessions/$SESSION_ID/prompt-output.md; rm -rf ~/.shepherd/sessions/$SESSION_ID; else echo "SHEPHERD_TIMEOUT"; fi
```

Interpret the output:
- **If the output is NOT "SHEPHERD_TIMEOUT"**: The output is the review prompt from the user. Read it carefully and proceed to make the requested code changes based on the prompt contents.
- **If the output is "SHEPHERD_TIMEOUT"**: The session timed out after 30 minutes. Tell the user: "The annotation session timed out. You can still paste your prompt here — it should be on your clipboard if you clicked Done in the tool."
