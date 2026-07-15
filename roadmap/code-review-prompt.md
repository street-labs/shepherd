@.pdeq/roadmap/AGENTS.md

# Code Review Prompt Generator — Roadmap

See current state in [../product/code-review-prompt.md](../product/code-review-prompt.md).

## V2

- **[File ordering in prompt]** — Should files in the generated prompt be ordered by load order, alphabetically, or user-reorderable? V1 assumes load order.
- **[Per-file preamble]** — Should users be able to add per-file instructions in addition to the global preamble? V1 assumes a single global preamble only.
- **[Maximum file count]** — Should there be a hard limit on the number of files that can be loaded? V1 has no hard limit but acknowledges performance may degrade past 20 files.
