Open the Code Review Prompt Generator (CRPG) with the specified file.

Allowed tools: Bash, Read

Arguments: $ARGUMENTS

Suggested arguments: <filepath>

## Instructions

The file to open: `$ARGUMENTS`

If no file argument was provided (empty or blank), respond with: "Usage: /shepherd <filepath>" and stop.

Otherwise, do the following steps:

### Step 1: Validate the file

Resolve the path relative to the current working directory. Verify:
- The file exists (if not: "Error: File not found: <resolved-path>")
- It is a file, not a directory (if not: "Error: Path is a directory, not a file: <resolved-path>")
- It is readable (if not: "Error: Permission denied: <resolved-path>")
- It is not binary — check the first 8192 bytes for null bytes (if binary: "Error: Binary file not supported: <resolved-path>")
- Count the lines. If > 10000, warn: "Warning: <file> has <N> lines. Performance may be degraded."

If validation fails, report the error and stop. Do NOT continue to the next steps.

### Step 2: Ensure the dev server is running

Check if http://localhost:5173 is responding:
```bash
curl -s -o /dev/null -w '%{http_code}' http://localhost:5173
```

If not responding, start the dev server in the background:
```bash
cd /Users/lstreet/Development/shepherd/engineering/apps/web && pnpm dev &
```
Then wait up to 10 seconds for it to respond.

### Step 3: Open the CRPG in an app-mode window

URL-encode the absolute file path. Open the CRPG in a Chrome/Chromium app-mode window (standalone, no browser chrome). Use the platform-appropriate fallback chain:

**macOS:**
```bash
open -na 'Google Chrome' --args --app='http://localhost:5173?file=<encoded-path>' 2>/dev/null || open -na 'Chromium' --args --app='http://localhost:5173?file=<encoded-path>' 2>/dev/null || open 'http://localhost:5173?file=<encoded-path>'
```

**Linux:**
```bash
google-chrome --app='http://localhost:5173?file=<encoded-path>' 2>/dev/null || chromium-browser --app='http://localhost:5173?file=<encoded-path>' 2>/dev/null || xdg-open 'http://localhost:5173?file=<encoded-path>'
```

### Step 4: Report success

Print a brief summary:
```
Opened CRPG at http://localhost:5173 — loaded <filename> (<N> lines)
```

### Step 5: Clean up stale prompt output

Remove any leftover output file from a previous session:
```bash
rm -f ~/.shepherd/prompt-output.md
```

### Step 6: Wait for the prompt

Tell the user: "Annotate your code and click **Done** when you're finished. I'll wait for your prompt."

Then run the file watcher — a blocking loop that waits for the CRPG's Done action to write the prompt:
```bash
i=0; while [ ! -f ~/.shepherd/prompt-output.md ] && [ $i -lt 1800 ]; do sleep 1; i=$((i+1)); done; if [ -f ~/.shepherd/prompt-output.md ]; then cat ~/.shepherd/prompt-output.md; rm ~/.shepherd/prompt-output.md; else echo "SHEPHERD_TIMEOUT"; fi
```

Interpret the output:
- **If the output is NOT "SHEPHERD_TIMEOUT"**: The output is the review prompt from the user. Read it carefully and proceed to make the requested code changes based on the prompt contents.
- **If the output is "SHEPHERD_TIMEOUT"**: The session timed out after 30 minutes. Tell the user: "The annotation session timed out. You can still paste your prompt here — it should be on your clipboard if you clicked Done in the tool."
