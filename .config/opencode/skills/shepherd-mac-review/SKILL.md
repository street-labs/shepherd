Orchestrate a guided, multi-file code review of uncommitted changes using the macOS CRPG.

<!-- Implements: FR-srm-command-file, FR-srm-multi-file-launch, FR-srm-context-handoff -->

Allowed tools: Bash, Read, Write

Arguments: $ARGUMENTS

Suggested arguments: [--staged | --unstaged | <commit-or-branch>]

## Instructions

You are orchestrating a guided code review. The user has invoked `/shepherd-mac-review` to open all interesting changed files at once in the **macOS** Code Review Prompt Generator (CRPG), using the batch-open feature of `shepherd-launch-macos.sh`.

You provide context up front: a changeset overview with per-file summaries, then open all files in one go. After the user finishes reviewing in the macOS app, you collect the prompt output and present feedback options.

**Efficiency rule: Do not comment on changeset size.** Never say the changeset is "huge", "large", or "significant", and never deliberate about whether to narrow the scope or use a different git strategy. Apply the filtering rules mechanically and proceed. The steps below handle noise reduction — your job is to execute them exactly, not editorialize about volume or improvise alternative approaches.

**CWD rule:** All git commands MUST use `git -C "$REPO_ROOT"` to ensure they run from the repository root, regardless of your current working directory. This prevents silent failures in monorepos where the CWD may be a subdirectory.

Follow these steps in order.

---

### Step 1: Verify git repo, get root, locate Shepherd, and parse arguments

Run a single command to verify the repo and get the root:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git rev-parse --show-toplevel
```

If `--is-inside-work-tree` fails (non-zero exit on the first command), output exactly:

```
Not a git repository. /shepherd-mac-review must be run from within a git repo.
```

Then stop.

Store the second line as REPO_ROOT.

Next, resolve the Shepherd repo root. This skill may be invoked from any repo via a global symlink, so we cannot assume REPO_ROOT contains the launch script. Try these in order:

1. **Saved repo path** (set by `sq run ... install`):
```bash
SHEPHERD_ROOT="$(cat ~/.shepherd/repo-path 2>/dev/null)"
```

2. **Symlink resolution** (if installed via manual symlink):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch-macos.sh" ] && SHEPHERD_ROOT="$(cd "$(dirname "$(readlink -f "$(echo ~/.config/opencode/skills/shepherd-mac-review/SKILL.md)")")"/../.. && pwd)"
```

3. **Current repo fallback** (if running from within the Shepherd repo):
```bash
[ ! -f "$SHEPHERD_ROOT/scripts/shepherd-launch-macos.sh" ] && SHEPHERD_ROOT="$REPO_ROOT"
```

If `$SHEPHERD_ROOT/scripts/shepherd-launch-macos.sh` still doesn't exist, output: "Could not find shepherd-launch-macos.sh. Run `./scripts/install-command.sh` from the Shepherd repo to set it up." and stop.

Parse the argument: `$ARGUMENTS`

- If empty or blank → SCOPE = `working` (default: all uncommitted changes)
- If `--staged` → SCOPE = `staged`
- If `--unstaged` → SCOPE = `unstaged`
- Otherwise → treat the argument as a git ref (commit, branch, tag). Verify it resolves:
  ```bash
  git -C "$REPO_ROOT" rev-parse --verify "$ARGUMENTS" 2>/dev/null
  ```
  If it resolves → SCOPE = `ref`, DIFF_REF = the resolved value.
  If it does NOT resolve → output the usage message below and stop.

```
Usage: /shepherd-mac-review [--staged | --unstaged | <ref>]

Review uncommitted changes in the macOS CRPG.

Scopes:
  (default)     All uncommitted changes (staged + unstaged + untracked)
  --staged      Only staged changes
  --unstaged    Only unstaged changes and untracked files
  <ref>         Diff working tree against a commit, branch, or tag
```

---

### Step 2: Find changeset

This tool reviews the **working copy** — what's dirty right now. No branch comparison logic.

Run the appropriate git commands based on SCOPE. All commands use `git -C "$REPO_ROOT"`.

**SCOPE = `working`** (default):

```bash
git -C "$REPO_ROOT" diff HEAD --name-status && git -C "$REPO_ROOT" diff --cached --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

This captures staged changes, unstaged changes, and untracked files in a single command chain.

**SCOPE = `staged`**:

```bash
git -C "$REPO_ROOT" diff --cached --name-status
```

**SCOPE = `unstaged`**:

```bash
git -C "$REPO_ROOT" diff --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

**SCOPE = `ref`**:

```bash
git -C "$REPO_ROOT" diff "$DIFF_REF" --name-status && git -C "$REPO_ROOT" ls-files --others --exclude-standard
```

Merge and deduplicate all output by path. Untracked files (from `ls-files`) get change type `added`.

If the combined output is empty, output: `No changes found.` and stop.

**Parse statuses:**

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

**Included config** (NOT excluded unless in an excluded directory): `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`, `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.config/opencode/skills/*.md`

If zero files remain after filtering, output: `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` and stop.

---

### Step 4: Read all diffs in one batch, generate context, and proceed

Get diffs for **all** reviewable files in a single command. Separate modified/renamed files (which have diffs) from new/untracked files (which don't).

For files that have diffs, run **one** command with all paths, using the same diff base as Step 2:

| SCOPE | Diff command |
|---|---|
| `working` | `git -C "$REPO_ROOT" diff HEAD -- <path1> <path2> ...` |
| `staged` | `git -C "$REPO_ROOT" diff --cached -- <path1> <path2> ...` |
| `unstaged` | `git -C "$REPO_ROOT" diff -- <path1> <path2> ...` |
| `ref` | `git -C "$REPO_ROOT" diff "$DIFF_REF" -- <path1> <path2> ...` |

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
SESSION_ID=$(basename "$REPO_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
```

**4c. Generate structured review context JSON in a temp file.**

Create a temp file path the launcher will read:

```bash
CTX=$(mktemp -t shepherd-review-context.XXXXXX.json)
```

Build a JSON object with the following structure and write it to `$CTX` using the Write tool:

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

Use **absolute file paths** as keys in the `files` object. These keys MUST exactly match the absolute paths passed to `shepherd-launch-macos.sh` so the macOS app can correlate per-file context to its tab. Use the same `REPO_ROOT/<relative-path>` form for both.

The launcher inlines this file's contents into `session.json` at launch time and the macOS app reads it directly via `SessionClient.loadSession`. There is no Vite endpoint and no `~/.shepherd/sessions/<id>/review-context.json` file involved.

**4d. Display a brief summary and proceed immediately.**

Output a brief summary (no per-file details — those are now in the macOS app):

```
Reviewing: <scope-label>
Opening <N> files in the macOS app for review.
<M> files excluded (lockfiles, generated, binary).
```

Where `<scope-label>` is: `all uncommitted changes`, `staged changes only`, `unstaged changes only`, or `changes vs <ref>`.

The "excluded" line is omitted if zero files were filtered. **Do not use `AskUserQuestion` here — proceed directly to Step 5.**

---

### Step 5: Open all files in the macOS CRPG and wait for review

**5a. Clean stale prompt output.**

Remove any previous prompt output file so we can detect a fresh one:

```bash
rm -f ~/.shepherd/sessions/$SESSION_ID/prompt-output.md
```

**5b. Launch all files in the macOS CRPG.**

Build the command with `--context "$CTX"` and all absolute file paths, then invoke the launch script:

```bash
bash "$SHEPHERD_ROOT/scripts/shepherd-launch-macos.sh" --context "$CTX" "<absolute-path-1>" "<absolute-path-2>" ... "<absolute-path-N>"
```

Use the absolute paths (`REPO_ROOT/<relative-path>`) for each file in the prioritized list. Quote each path properly. After the launcher returns, delete the temp context file:

```bash
rm -f "$CTX"
```

After launching, output:

```
Opened <N> files in the macOS app. Review them in the native window, then come back here when you're done.
```

**5c. Ask the user about their review.**

Use `AskUserQuestion` to present the user with these options:

- **"Added comments"** (description: "I reviewed files in the macOS app and clicked Done")
- **"Reviewed, no comments"** (description: "I looked at the files but have no comments to add")
- **"Cancel"** (description: "Abandon this review session")

Based on the response:

- **"Added comments"**: Read `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` with the Read tool. Store the contents as PROMPT_OUTPUT. If the file does not exist, tell the user "Could not find prompt output. Make sure you clicked 'Done' in the macOS app." and re-ask.
- **"Reviewed, no comments"**: Set PROMPT_OUTPUT to empty. Proceed to Step 6.
- **"Cancel"**: Output "Review session cancelled." and stop. The native window stays open — the user closes it via standard macOS chrome whenever they want. Do not proceed to Step 6.

---

### Step 6: Summary and feedback actions

**6a. Display the review summary.**

```
Review complete.
  <N> files opened in macOS CRPG
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
- The `shepherd-launch-macos.sh` script handles file validation, `session.json` writing, and launching the prebuilt native binary. No browser opens. No Vite server starts.
- Each invocation starts fresh — the launcher overwrites `session.json` for the current session ID.
- When reading diffs for context, use the Read tool or Bash — whichever is more practical.
