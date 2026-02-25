Land current changes on main, push, return to branch, and rebase.

Allowed tools: Bash, AskUserQuestion

Arguments: $ARGUMENTS

Suggested arguments: [commit message]

## Instructions

You are landing uncommitted changes directly onto `main`, pushing, and rebasing the current branch. This supports a multi-worktree workflow where several worktrees contribute to main independently.

**Do not editorialize.** Execute the steps mechanically. Do not comment on whether this workflow is unusual or suggest alternatives.

Follow these steps in order.

---

### Step 1: Verify state and gather info

Run a single command to get the current branch, repo root, and check for changes:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git rev-parse --abbrev-ref HEAD && git rev-parse --show-toplevel && git status --porcelain
```

If not a git repo, output: `Not a git repository.` and stop.

Store the second line as CURRENT_BRANCH. Store the third line as REPO_ROOT. The remaining lines are the working tree status.

If CURRENT_BRANCH is `main`, output: `Already on main. Just commit and push directly.` and stop.

If the status output is empty (no uncommitted changes), output: `No uncommitted changes to land.` and stop.

---

### Step 2: Determine commit message

If `$ARGUMENTS` is non-empty, use it as the COMMIT_MESSAGE.

If `$ARGUMENTS` is empty, run:

```bash
git diff --stat
git diff --cached --stat
```

Review the output and draft a concise commit message (1-2 sentences, imperative mood). Show it to the user with `AskUserQuestion`:

- **"Use this message"** (description: the drafted message)
- **"Let me type one"** (description: "I'll provide my own commit message")

If the user picks "Let me type one", use their response as COMMIT_MESSAGE.

---

### Step 3: Stash, switch to main, apply, commit, push

Run these commands sequentially. If any command fails, report the error and attempt to restore the original state (pop stash if needed, checkout CURRENT_BRANCH).

```bash
git stash push -u -m "land-on-main: temp stash"
```

```bash
git checkout main && git pull --ff-only origin main
```

```bash
git stash pop
```

Stage all changes and commit:

```bash
git add -A && git commit -m "<COMMIT_MESSAGE>"
```

Push:

```bash
git push origin main
```

---

### Step 4: Return to branch and rebase

```bash
git checkout <CURRENT_BRANCH> && git rebase main
```

If the rebase has conflicts, output:

```
Landed on main and pushed. Rebase onto main has conflicts.
Resolve conflicts, then run: git rebase --continue
```

And stop.

---

### Step 5: Confirm

Output:

```
Landed on main and pushed.
Rebased <CURRENT_BRANCH> onto main.
```
