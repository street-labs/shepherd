# Shepherd

A native macOS app for giving your AI coding agent feedback on its work. Annotate source code with inline comments, then generate a structured review prompt you hand back to the agent — so your feedback lands as precise, in-context instructions instead of vague prose.

> **Status:** early. Shepherd is a small, focused tool that we use daily; expect rough edges.

## Demo

> _Screenshots coming soon._ Drop PNGs into [`docs/demos/`](docs/demos/) and uncomment the block below.

<!-- Suggested shots — capture from the running macOS app:
![Annotating a file with inline comments](docs/demos/annotate.png)
![Reviewing a branch: the agent's self-review beside each diff (/shepherd-review)](docs/demos/shepherd-review.png)
![Diff view against git HEAD](docs/demos/diff.png)
![Rendered markdown review](docs/demos/markdown.png)
-->

## What It Does

AI coding agents produce a lot of code, fast. The bottleneck is *feedback* — telling the agent what to change, precisely, in context. Shepherd makes that loop tight: open the files the agent touched, mark them up like a code review, and export a structured prompt the agent can act on directly.

### Features

- **Load the work** — Paste, upload, or drag files in
- **Syntax highlighting** — 13+ languages
- **Inline comments** — Annotate single lines or ranges, right where the issue is
- **Rendered markdown** — Review docs and specs as formatted output, not raw source
- **Diff view** — Compare the working copy against git HEAD and comment on what changed
- **Structured prompt** — Export your comments paired with the exact code they refer to, ready to hand back to the agent
- **Local** — A native macOS app; your code stays on your machine

### Two ways to use it

**Open a single file** — straight from Claude Code:

```
/shepherd path/to/file.ts
```

Opens the file in Shepherd, ready to annotate. Supports diff view against git HEAD.

**Review a whole change — with the agent's own review already attached:**

```
/shepherd-review
```

This is the core loop. `/shepherd-review` takes the changeset of your current branch (vs. `main`) and:

1. **Discovers and filters** the changed files — skipping the noise (lockfiles, generated code, binaries) so you only see meaningful, human-relevant changes.
2. **Has the agent review its own work.** For each file it generates two kinds of context: a *neutral* description of what changed, and the agent's own *review feedback* — its opinions, concerns, and suggestions about the change it just made. The two are shown as visually distinct sections, so you always know which is the agent's self-critique.
3. **Opens everything in one session** — every reviewable file as a tab, each diff sitting next to the agent's self-review. You read the agent's take, add your own comments where you disagree or want changes, and skip the files you don't care about.
4. **Exports one prompt.** Click **Done** once and Shepherd produces a single structured prompt covering every file you commented on — your feedback paired with the exact code — ready to hand straight back to the agent.

The result: instead of eyeballing a raw diff and typing vague prose back at your agent, you review *with* the agent's self-assessment in front of you and hand back precise, in-context instructions.

## Install

Requires macOS and the Swift toolchain (Xcode or the Swift command-line tools).

```bash
git clone <repo-url>
cd shepherd
./scripts/install-command.sh
```

`install-command.sh` builds the native `ShepherdApp` release binary and installs the `/shepherd` and `/shepherd-review` slash commands for Claude Code (`~/.claude/commands/`), opencode (`~/.config/opencode/skills/`), and pi (`~/.pi/agent/prompts/`). Updates propagate via `git pull`.

## Testing

```bash
# App unit/logic tests (Swift)
cd engineering/apps/macos && swift test

# Spec traceability + lane-discipline audits
./scripts/audit-traceability.sh --check
./scripts/audit-lanes.sh
./scripts/audit-structure.sh
```

## How it's built

Shepherd is developed spec-first with [pdeq](https://github.com/street-labs/pdeq): markdown specs under `product/`, `design/`, `engineering/`, and `qa/` are the source of truth, and the app in `engineering/apps/macos/` (SwiftUI + [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)) is derived from them. Every requirement has a slug (`FR-`/`NFR-`/`AC-`) traced through `index.md` to its implementation and tests.

```
shepherd/
├── product/            # requirements, acceptance criteria
├── design/             # UI/UX specs
├── engineering/        # tech specs + source
│   └── apps/macos/     # the Shepherd macOS app (SwiftUI + TCA)
├── qa/                 # test plans, coverage
├── index.md            # traceability index (slug → all references)
└── .pdeq/              # the pdeq framework (git submodule)
```

## Contributing

Contributions come in as pull requests — see [`CONTRIBUTING.md`](CONTRIBUTING.md). The issue tracker is disabled; a bug report is a PR that adds a failing test. Please also read the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) © Street Labs
