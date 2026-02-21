Open the Code Review Prompt Generator (CRPG) with the specified file.

Allowed tools: Bash, Read

Arguments: $ARGUMENTS

Suggested arguments: <filepath>

## Instructions

Use the Task tool to launch a Bash subagent to handle the launch. The subagent should do ALL of the following in a single invocation so the user only sees the final result.

The file to open: `$ARGUMENTS`

If no file argument was provided (empty or blank), respond with: "Usage: /shepherd <filepath>" and stop. Do NOT launch a subagent.

Otherwise, launch a Bash subagent with a prompt like:

"Launch the CRPG for the file `$ARGUMENTS`. Do the following:
1. Resolve the path relative to the current working directory and verify it exists and is a file (not a directory). If it fails validation, return the error.
2. Check if http://localhost:5173 is responding (curl -s -o /dev/null -w '%{http_code}' http://localhost:5173). If not, start the dev server in the background: cd /Users/lstreet/Development/shepherd/engineering/apps/web && pnpm dev &, then wait up to 5 seconds for it to respond.
3. URL-encode the absolute file path and open the browser: open 'http://localhost:5173?file=<encoded-path>'
4. Count the lines in the file with wc -l.
5. Return ONLY a summary like: 'Opened CRPG at http://localhost:5173 — loaded <filename> (<N> lines)'. If the server was already running, add '(reusing server)'. If there were errors, return the error message instead."

Then relay the subagent's response to the user as your final message. Keep it brief — just the one-line summary or error.
