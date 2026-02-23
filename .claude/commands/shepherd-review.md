Orchestrate a guided, multi-file code review of the current branch's changeset using the CRPG.

Allowed tools: Bash, Read

Arguments: $ARGUMENTS

Suggested arguments: [--staged | --unstaged]

## Instructions

You are orchestrating a guided code review. The user has invoked `/shepherd-review` to open all interesting changed files at once in the Code Review Prompt Generator (CRPG), using the batch-open feature of `shepherd-launch.sh`.

You provide context up front: a changeset overview with per-file summaries, then open all files in one go. After the user finishes reviewing in the CRPG, you collect the prompt output and present feedback options.

Follow these steps in order.

---

### Step 1: Verify git repository

Run:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

If this fails (non-zero exit), output exactly:

```
Not a git repository. /shepherd-review must be run from within a git repo.
```

Then stop.

---

### Step 2: Get repository root and parse arguments

Run:

```bash
git rev-parse --show-toplevel
```

Store the result as REPO_ROOT.

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

---

### Step 3: Find changeset

**3a. Find the merge base** (needed for `all` and `staged` scopes):

If SCOPE is `all` or `staged`, run:

```bash
git merge-base HEAD main 2>/dev/null
```

If this fails, output: `No changes found relative to main.` and stop. Store the result as MERGE_BASE.

**3b. Get changed files based on scope:**

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

**3c. Parse the diff output.**

- `M` = modified. `A` = added. `D` = deleted (exclude, count as filtered). `R` = renamed (use new path). `C` = added. `T` = modified.

For untracked files, add as `added` unless already present.

---

### Step 4: Filter files

A file is excluded if it matches **any** exclusion rule. **Exclusion rules take precedence over inclusion rules.**

**Lockfiles** (exact filename): `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`

**Generated files**: directories `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`; extensions `.min.js`, `.min.css`, `.map`, `.d.ts`; basenames containing `.generated.` or `.auto.`

**Binary files**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.webp`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.webm`, `.avi`, `.zip`, `.tar`, `.gz`, `.bz2`, `.7z`, `.pdf`, `.exe`, `.dll`, `.so`, `.dylib`

**IDE/editor**: `.idea/`, `.vscode/`, `.DS_Store`

**Snapshots**: `.snap`, `.snapshot`

**Included config** (NOT excluded unless in an excluded directory): `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`, `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.claude/commands/*.md`

If zero files remain after filtering, output: `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` and stop.

---

### Step 5: Read file diffs for context

For each reviewable file, get its diff so you can provide context. Run:

```bash
git diff $MERGE_BASE -- <path>
```

(For `unstaged` scope, use `git diff -- <path>`. For new/untracked files, there is no diff — note them as entirely new.)

Read each diff output. You will use this to:
1. Write the changeset overview (Step 6).
2. Write per-file context summaries (Step 6).
3. Rank files by importance (Step 6).

---

### Step 6: Changeset overview and batch open

**6a. Prioritize files by review importance.**

Rank files using these heuristics (highest priority first):
1. **Core source code** (application logic, components, business logic) — most important to review
2. **Configuration that affects behavior** (build config, CI, command definitions)
3. **Specs and documentation** (markdown specs, READMEs, design docs)
4. **Supporting files** (index files, glossaries, changelogs, decision logs)
5. **Test files** — usually least urgent to review manually

Within each tier, rank by the size/significance of the change (larger diffs first). Use your judgment — the goal is that the reviewer sees the most important files first.

**6b. Display the changeset overview with per-file summaries.**

First, write a brief (2-4 sentence) summary of the overall changeset: what is being changed, what's the theme or purpose of these changes as a whole. This helps the reviewer orient before diving into individual files.

Then display the file list with a per-file context summary for each file (1-2 sentences describing what changed). Be specific — mention function names, sections, or structural changes:

```
Reviewing: <scope-label>

<changeset overview paragraph>

Found <N> files to review (<M> filtered out):

  1. <relative-path>  [<change-type>]
     <per-file context summary>

  2. <relative-path>  [<change-type>]
     <per-file context summary>

  ...

Ready to open all files in the CRPG.
```

Where `<scope-label>` is: `all changes vs main`, `staged changes only`, or `unstaged changes only`.

Files are listed in priority order (not alphabetical). Position numbers are right-aligned for 10+ files. The "filtered out" parenthetical is omitted if zero.

Use the `AskUserQuestion` tool to let the user choose:

- **"Go"** (description: "Open all files in the CRPG for review") → proceed to Step 7
- **"Quit"** (description: "Cancel the review") → output `Review cancelled.` and stop

---

### Step 7: Open all files in CRPG and wait for review

**7a. Clean stale prompt output.**

Remove any previous prompt output file so we can detect a fresh one:

```bash
rm -f ~/.shepherd/prompt-output.md
```

**7b. Launch all files in the CRPG.**

Build the command with all absolute file paths and invoke the launch script:

```bash
bash <REPO_ROOT>/scripts/shepherd-launch.sh <absolute-path-1> <absolute-path-2> ... <absolute-path-N>
```

Use the absolute paths (`REPO_ROOT/<relative-path>`) for each file in the prioritized list, space-separated. Quote each path properly.

After launching, output:

```
Opened <N> files in the CRPG. Review them in your browser.

When you're done, click "Done" in the CRPG to send back your review prompt, or say "done" here to continue.
```

**7c. Wait for the prompt output.**

Poll for the prompt output file. The CRPG writes to `~/.shepherd/prompt-output.md` when the user clicks "Done":

```bash
test -f ~/.shepherd/prompt-output.md && echo "EXISTS" || echo "WAITING"
```

Poll every 3 seconds, up to a maximum of 10 minutes (200 attempts). If the user says "done" or similar in chat before the file appears, stop polling and proceed.

When the file exists, read it with the Read tool and store the contents as PROMPT_OUTPUT.

If the poll times out without the file appearing, output: `Timed out waiting for CRPG output. You can still use the review in your browser.` and proceed to Step 8 without prompt output.

---

### Step 8: Summary and feedback actions

**8a. Display the review summary.**

```
Review complete.
  <N> files opened in CRPG
  <M> files filtered out (lockfiles, generated, binary)
```

Right-align numbers. The "filtered out" line is omitted if zero.

**8b. Display prompt output (if available).**

If PROMPT_OUTPUT was collected, display it:

```
---

Prompt output from CRPG:

<PROMPT_OUTPUT contents>

---
```

**8c. Ask what to do with the feedback.**

Use `AskUserQuestion` to let the user choose:

- **"Apply changes"** (description: "Implement the changes described in the review feedback") → Begin implementing, file by file. Follow the project's cardinal rule (update specs first if behavior changes, then code).
- **"Discuss first"** (description: "Let's talk through the feedback before acting") → Engage in conversation about the feedback. Ask clarifying questions if needed.
- **"Save for later"** (description: "Write the review output to a file I can come back to") → Write to `review-feedback-<date>.md` in the repo root. Tell the user where it was saved.
- **"Done"** (description: "I'll handle it myself") → End the session.

If no prompt output was collected (timeout or user skipped), skip the prompt output display and the feedback action question. Just show the summary and end.

---

### Important notes

- Provide helpful context but keep it concise. The per-file summaries should orient the reviewer, not overwhelm them.
- The `/shepherd` launch script handles server management and browser opening.
- Each invocation starts fresh.
- When reading diffs for context, use the Read tool or Bash — whichever is more practical.
