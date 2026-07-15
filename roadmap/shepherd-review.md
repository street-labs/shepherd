@.pdeq/roadmap/AGENTS.md

# Shepherd Review — Roadmap

See current state in [../product/shepherd-review.md](../product/shepherd-review.md).

## V2

- **[Base branch detection]** — The spec defaults to `main` as the base branch. Some repositories use `master`, `develop`, or other branch names. Should the command attempt to auto-detect the default branch (e.g., by reading `git symbolic-ref refs/remotes/origin/HEAD`), or should it accept an optional argument to override the base branch? V1 assumes `main`; auto-detection or an override argument is a natural v2 enhancement.
- **[Review branch cleanup]** — After a patch review session ends, should the `review/patch-*` branch be auto-deleted, kept for inspection, or prompt the user? V1 keeps the branch (user can delete manually). Auto-cleanup could be a config option in v2.
