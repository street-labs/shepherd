Orchestrate a guided, multi-file code review of the current branch's changeset using the CRPG.

Allowed tools: Bash, Read

Arguments: $ARGUMENTS

Suggested arguments: [--staged | --unstaged]

## Instructions

You are orchestrating a guided code review. The user has invoked `/shepherd-review` to walk through all interesting changed files, one at a time, opening each in the Code Review Prompt Generator (CRPG) via the `/shepherd` command.

You provide context at every step: a changeset overview up front, per-file summaries before opening each file, and feedback collection throughout. At the end, all accumulated feedback is presented together.

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
2. Write per-file context summaries (Step 7).
3. Rank files by importance (Step 6).

---

### Step 6: Changeset overview and prioritized file list

**6a. Prioritize files by review importance.**

Rank files using these heuristics (highest priority first):
1. **Core source code** (application logic, components, business logic) — most important to review
2. **Configuration that affects behavior** (build config, CI, command definitions)
3. **Specs and documentation** (markdown specs, READMEs, design docs)
4. **Supporting files** (index files, glossaries, changelogs, decision logs)
5. **Test files** — usually least urgent to review manually

Within each tier, rank by the size/significance of the change (larger diffs first). Use your judgment — the goal is that the reviewer sees the most important files first.

**6b. Display the changeset overview and file list.**

First, write a brief (2-4 sentence) summary of the overall changeset: what is being changed, what's the theme or purpose of these changes as a whole. This helps the reviewer orient before diving into individual files.

Then display the file list:

```
Reviewing: <scope-label>

<changeset overview paragraph>

Found <N> files to review.

  1. <relative-path>  [<change-type>]
  2. <relative-path>  [<change-type>]
  ...

<M> files excluded (lockfiles, generated, binary).

Ready to start? Say "go" to begin, or "quit" to cancel.
```

Where `<scope-label>` is: `all changes vs main`, `staged changes only`, or `unstaged changes only`.

Files are listed in priority order (not alphabetical). Position numbers are right-aligned for 10+ files. The exclusion line is omitted if zero.

Use the `AskUserQuestion` tool to let the user choose:

- **"Start review"** (description: "Begin reviewing files one by one in the CRPG") → proceed to Step 7
- **"Cancel"** (description: "Skip the review for now") → output `Review cancelled.` and stop

---

### Step 7: Iteration loop

Initialize an empty feedback collection. This will accumulate comments from across all files.

For each file in the prioritized list:

**7a. Announce the file with context:**

```
[<position>/<total>] <relative-path>  [<change-type>]

<per-file context summary>

Opening in the Code Review Prompt Generator...
```

The `<per-file context summary>` is 2-4 sentences describing what changed in this specific file: what was added, modified, or removed, and why it matters. Derived from the diff you read in Step 5. Be specific — mention function names, sections, or structural changes. Do not just say "this file was modified."

**7b. Invoke /shepherd:**

`/shepherd <REPO_ROOT>/<relative-path>`

**7c. Prompt the user with interactive options:**

Use the `AskUserQuestion` tool to let the user choose what to do with this file:

- **"Looks good, next"** (description: "No comments, move to the next file") → Record as **reviewed**. Move to next file.
- **"I have feedback"** (description: "Paste comments from the CRPG for this file") → Prompt: `Paste your feedback for this file:` Wait for the user to paste. Store the pasted content tagged with the file path. Then say: `Feedback saved for <filename>. (<total> files with feedback so far)` Then use AskUserQuestion again for the same file (the user may want to also move on or add more).
- **"Skip"** (description: "Skip this file without reviewing") → Record as **skipped**. Move to next file.
- **"End review"** (description: "Stop reviewing and see the summary") → Record current file as **reviewed**. Go to Step 8.

The user may also respond with free text instead of clicking an option. Recognize these synonyms (case-insensitive):

| Input | Action |
|---|---|
| "next", "done", "continue", "n", "lgtm", "good" | Same as "Looks good, next" |
| "feedback", "comments", "paste", "f" | Same as "I have feedback" |
| "skip", "pass" | Same as "Skip" |
| "quit", "stop", "exit", "q" | Same as "End review" |
| "list", "show files", "files" | Re-display the file list with `>` on current file and `Currently reviewing file X of Y.` Then re-prompt with AskUserQuestion. Do NOT re-invoke /shepherd. |

**Important**: When the user says "feedback" and pastes content, store it in a running collection like:

```
## <relative-path>
<pasted content>
```

The user may provide feedback on multiple files. Accumulate all of it. Do NOT act on the feedback yet — just store it.

After the last file is processed, proceed to Step 8.

---

### Step 8: Completion summary and feedback handoff

Display the summary:

```
Review complete.
  <T> files in changeset
  <E> filtered out (lockfiles, generated, binary)
  <R> files to review
  <V> reviewed
  <S> skipped
  <F> files with feedback
```

If the user quit early, add: `  <Q> remaining (quit early)`

Right-align numbers.

**If there is accumulated feedback**, display it:

```
---

Collected feedback from this review:

## <relative-path-1>
<pasted feedback for file 1>

## <relative-path-2>
<pasted feedback for file 2>

...

---

```

If there is no feedback, just show the summary and say: `No feedback was collected during this review.` Then stop.

**If there is feedback**, use `AskUserQuestion` to ask what to do with it:

- **"Apply changes"** (description: "Implement the changes described in the feedback") → Begin implementing, file by file. Follow the project's cardinal rule (update specs first if behavior changes, then code).
- **"Discuss first"** (description: "Let's talk through the feedback before acting") → Engage in conversation about the feedback. Ask clarifying questions if needed.
- **"Save for later"** (description: "Write feedback to a file I can come back to") → Write to `review-feedback-<date>.md` in the repo root. Tell the user where it was saved.
- **"Done"** (description: "I'll handle it myself") → End the session.

---

### Important notes

- Emoji are welcome! Use them to make the review experience friendly and scannable (e.g., checkmarks for reviewed files, arrows for navigation cues).
- Provide helpful context but keep it concise. The per-file summaries should orient the reviewer, not overwhelm them.
- Track reviewed/skipped/remaining/feedback counts accurately.
- The `/shepherd` command handles server management and browser opening.
- Each invocation starts fresh. Feedback is accumulated in the conversation only.
- When reading diffs for context, use the Read tool or Bash — whichever is more practical.
