Orchestrate a guided, multi-file code review of the current branch's changeset using the CRPG.

Allowed tools: Bash, Read, Write

Arguments: $ARGUMENTS

Suggested arguments: [--staged | --unstaged]

## Instructions

You are orchestrating a guided code review. The user has invoked `/shepherd-review` to open all interesting changed files at once in the Code Review Prompt Generator (CRPG), using the batch-open feature of `shepherd-launch.sh`.

You provide context up front: a changeset overview with per-file summaries, then open all files in one go. After the user finishes reviewing in the CRPG, you collect the prompt output and present feedback options.

**Efficiency rule: Do not comment on changeset size.** Never say the changeset is "huge", "large", or "significant", and never deliberate about whether to narrow the scope. Apply the filtering rules mechanically and proceed. The filtering step handles noise reduction — your job is to execute, not editorialize about volume.

Follow these steps in order.

---

### Step 1: Verify git repo, get root, find merge base, locate Shepherd, and parse arguments

Run a single command to verify the repo, get the root, and find the merge base:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git rev-parse --show-toplevel && git merge-base HEAD main 2>/dev/null
```

If `--is-inside-work-tree` fails (non-zero exit on the first command), output exactly:

```
Not a git repository. /shepherd-review must be run from within a git repo.
```

Then stop.

Store the second line as REPO_ROOT (the repo being reviewed). Store the third line as MERGE_BASE. If `merge-base` fails (no third line), that's OK for `unstaged` scope — but for `all` or `staged` scope, output: `No changes found relative to main.` and stop.

Next, resolve the Shepherd repo root. This skill may be invoked from any repo via a global symlink, so we cannot assume REPO_ROOT contains the launch script. Try these in order:

1. **Saved repo path** (set by `sq run ... install`):
```bash
SHEPHERD_ROOT="$(cat ~/.shepherd/repo-path 2>/dev/null)"
```

2. **Symlink resolution** (if installed via manual symlink):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$(cd "$(dirname "$(readlink -f "$(echo ~/.claude/commands/shepherd-review.md)")")"/../.. && pwd)"
```

3. **Current repo fallback** (if running from within the Shepherd repo):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch.sh" ] && SHEPHERD_ROOT="$REPO_ROOT"
```

If `$SHEPHERD_ROOT/scripts/shepherd-launch.sh` still doesn't exist, output: "Could not find shepherd-launch.sh. Run `sq run personal-lstreet-shepherd install --full-clone` to set up Shepherd." and stop.

Parse the argument: `$ARGUMENTS`

- If empty or blank → SCOPE = `all` (default)
- If `--staged` → SCOPE = `staged`
- If `--unstaged` → SCOPE = `unstaged`
- Anything else → output the following usage message and stop:

```
Usage: /shepherd-review [--staged | --unstaged]

Guided review of changed files in the CRPG.

Scopes:
  (default)     All changes relative to main (committed + staged + unstaged + untracked)
  --staged      Only staged changes (what will be committed)
  --unstaged    Only unstaged changes and untracked files
```

### Step 2: Find changeset

**2a. Get changed files based on scope:**

| Scope | Diff command | Also include untracked? |
|---|---|---|
| `all` | `git diff --name-status $MERGE_BASE` | Yes: `git ls-files --others --exclude-standard` |
| `staged` | `git diff --name-status --cached $MERGE_BASE` | No |
| `unstaged` | `git diff --name-status` | Yes: `git ls-files --others --exclude-standard` |

For `all`: NO dots, NO `...HEAD` — compares merge base to working tree.
For `staged`: `--cached` shows only staged content relative to merge base.
For `unstaged`: no commit ref — unstaged modifications relative to index.

Merge diff output with untracked files (if applicable), deduplicating by path. Untracked files get change type `added`.

If the combined output is empty, output: `No changes found relative to main.` and stop.

**2b. Parse the diff output.**

- `M` = modified. `A` = added. `D` = deleted (exclude, count as filtered). `R` = renamed (use new path). `C` = added. `T` = modified.

For untracked files, add as `added` unless already present.

---

### Step 3: Filter files

A file is excluded if it matches **any** exclusion rule. **Exclusion rules take precedence over inclusion rules.**

**Lockfiles** (exact filename): `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`

**Generated files**: directories `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`; extensions `.min.js`, `.min.css`, `.map`, `.d.ts`; basenames containing `.generated.` or `.auto.`

**Binary files**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.webp`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.webm`, `.avi`, `.zip`, `.tar`, `.gz`, `.bz2`, `.7z`, `.pdf`, `.exe`, `.dll`, `.so`, `.dylib`

**IDE/editor**: `.idea/`, `.vscode/`, `.DS_Store`

**Snapshots**: `.snap`, `.snapshot`

**Included config** (NOT excluded unless in an excluded directory): `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`, `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.claude/commands/*.md`

If zero files remain after filtering, output: `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` and stop.

---

### Step 4: Read all diffs in one batch, generate context, and proceed

Get diffs for **all** reviewable files in a single command. Separate modified/renamed files (which have diffs) from new/untracked files (which don't).

For files that have diffs, run **one** command with all paths:

```bash
git diff $MERGE_BASE -- <path1> <path2> <path3> ...
```

(For `unstaged` scope, use `git diff -- <path1> <path2> ...`.)

For new/untracked files, read their contents using the Read tool (they have no diff to compare against — note them as entirely new).

This gives you all the information you need in one Bash call plus Read calls for new files only. Use this to:
1. Rank files by importance.
2. Generate structured review context JSON.
3. Display a brief summary.

**4a. Prioritize files by review importance.**

Rank files using these heuristics (highest priority first):
1. **Core source code** (application logic, components, business logic) — most important to review
2. **Configuration that affects behavior** (build config, CI, command definitions)
3. **Specs and documentation** (markdown specs, READMEs, design docs)
4. **Supporting files** (index files, glossaries, changelogs, decision logs)
5. **Test files** — usually least urgent to review manually

Within each tier, rank by the size/significance of the change (larger diffs first). Use your judgment — the goal is that the reviewer sees the most important files first.

**4b. Derive the session ID.**

Compute the session ID the same way the launch script does:

```bash
SESSION_ID=$(basename "$(git rev-parse --show-toplevel)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
```

**4c. Generate structured review context JSON.**

Build a JSON object with the following structure and write it to `~/.shepherd/sessions/$SESSION_ID/review-context.json` using the Write tool (create the directory first with `mkdir -p ~/.shepherd/sessions/$SESSION_ID`):

```json
{
  "overall": {
    "neutral": "<factual 2-4 sentence summary of what changed across the changeset>",
    "review": "<your opinion: what looks good, what deserves attention, potential concerns>"
  },
  "files": {
    "<absolute-file-path>": {
      "neutral": "<factual 1-2 sentence summary of what changed in this file>",
      "review": "<your opinion on this file's changes: quality, concerns, suggestions>"
    }
  }
}
```

The `neutral` fields should be purely factual — what changed, which functions/sections were modified, structural changes. No opinions.

The `review` fields contain your agent assessment — what looks good, what might be risky, suggestions for the reviewer to focus on.

Use **absolute file paths** as keys in the `files` object (these must match the paths passed to `shepherd-launch.sh` so the CRPG can correlate them with loaded files).

**4d. Display a brief summary and proceed immediately.**

Output a brief summary (no per-file details — those are now in the CRPG):

```
Reviewing: <scope-label>
Opening <N> files for review.
<M> files excluded (lockfiles, generated, binary).
```

Where `<scope-label>` is: `all changes vs main`, `staged changes only`, or `unstaged changes only`.

The "excluded" line is omitted if zero files were filtered. **Do not use `AskUserQuestion` here — proceed directly to Step 5.**

---

### Step 5: Open all files in CRPG and wait for review

**5a. Clean stale prompt output.**

Remove any previous prompt output file so we can detect a fresh one (do NOT remove `review-context.json` — it was just freshly written in Step 4):

```bash
rm -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md
```

**5b. Launch all files in the CRPG.**

Build the command with all absolute file paths and invoke the launch script:

```bash
bash $SHEPHERD_ROOT/scripts/shepherd-launch.sh <absolute-path-1> <absolute-path-2> ... <absolute-path-N>
```

Use the absolute paths (`REPO_ROOT/<relative-path>`) for each file in the prioritized list, space-separated. Quote each path properly.

After launching, output:

```
Opened <N> files in the CRPG. Review them in your browser, then come back here when you're done.
```

**5c. Ask the user about their review.**

Use `AskUserQuestion` to present the user with these options:

- **"Added comments"** (description: "I reviewed files in the CRPG and clicked Done")
- **"Reviewed, no comments"** (description: "I looked at the files but have no comments to add")
- **"Cancel"** (description: "Abandon this review session")

Based on the response:

- **"Added comments"**: Read `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` with the Read tool. Store the contents as PROMPT_OUTPUT. If the file does not exist, tell the user "Could not find prompt output. Make sure you clicked 'Done' in the CRPG." and re-ask.
- **"Reviewed, no comments"**: Set PROMPT_OUTPUT to empty. Proceed to Step 6.
- **"Cancel"**: Output "Review session cancelled." and stop. Do not proceed to Step 6.

---

### Step 6: Summary and feedback actions

**6a. Display the review summary.**

```
Review complete.
  <N> files opened in CRPG
  <M> files filtered out (lockfiles, generated, binary)
```

Right-align numbers. The "filtered out" line is omitted if zero.

**6b. Display prompt output (if available).**

If PROMPT_OUTPUT was collected, display it:

```
---

Prompt output from CRPG:

<PROMPT_OUTPUT contents>

---
```

**6c. Clean up session directory.**

```bash
rm -rf ~/.shepherd/sessions/$SESSION_ID
```

**6d. Ask what to do with the feedback.**

Use `AskUserQuestion` to let the user choose:

- **"Apply changes"** (description: "Implement the changes described in the review feedback") → Begin implementing, file by file. Follow the project's cardinal rule (update specs first if behavior changes, then code).
- **"Discuss first"** (description: "Let's talk through the feedback before acting") → Engage in conversation about the feedback. Ask clarifying questions if needed.
- **"Save for later"** (description: "Write the review output to a file I can come back to") → Write to `review-feedback-<date>.md` in the repo root. Tell the user where it was saved.
- **"Done"** (description: "I'll handle it myself") → End the session.

If PROMPT_OUTPUT is empty (from "Reviewed, no comments"), display the summary with "0 files with comments" and output: "No comments were added during the review. Session complete." Do NOT present the feedback action options. Just end.

---

### Important notes

- Provide helpful context but keep it concise. The per-file summaries should orient the reviewer, not overwhelm them.
- The `/shepherd` launch script handles server management and browser opening.
- Each invocation starts fresh.
- When reading diffs for context, use the Read tool or Bash — whichever is more practical.
