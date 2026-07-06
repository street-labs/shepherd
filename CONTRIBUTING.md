# Contributing to Shepherd

Thanks for your interest. A couple of things make contributing here different from a typical repo — please read this first.

## Pull requests only — no issues

**This project does not use the issue tracker** (it's disabled). All contributions, including bug reports, come in as pull requests.

- **Found a bug?** Open a PR that adds a **test reproducing it** — a failing test under `engineering/apps/macos/Tests/`. That's the minimum; a PR that also fixes the bug (turning the test green) is even better. A reproducing test never goes stale.
- **Want a feature or change?** Open a PR with the spec change and code (see the spec-driven flow below). Small, focused PRs review fastest.

Every PR ships with a test, or an explanation in the description of why one isn't possible.

## Spec-driven: markdown first, code second

Shepherd is developed with [pdeq](https://github.com/street-labs/pdeq): the markdown specs are the source of truth, and code is derived from them. Changes flow **markdown → code**, never the reverse. Before changing behavior:

1. Update the **product** spec (`product/<feature>.md`) if the *what* changed.
2. Update the **design**, **engineering**, and **QA** specs (`<lane>/macos/<feature>.md`) as needed.
3. **Then** update the Swift code to match, with an `// Implements: <slug>` marker at the implementing unit.
4. Update the traceability index (`index.md`) and add/adjust tests.

The full rules live in [`AGENTS.md`](AGENTS.md) and `.pdeq/`. A PR that changes behavior without the corresponding spec change will be asked to add it.

## Running the checks locally

These are the same checks CI runs:

```bash
# Build + app tests (requires the Swift toolchain on macOS)
cd engineering/apps/macos && swift build && swift test

# Spec audits (bash + python3 + git only)
./scripts/audit-traceability.sh --check   # slugs ↔ index ↔ markers reconcile
./scripts/audit-lanes.sh                  # product specs stay lane-clean (warn-only)
./scripts/audit-structure.sh              # blocking structural lane check
```

A pre-commit hook (installed via `.pdeq`) runs the audits and merges pending decision-log entries. If you didn't install the hooks, run the audits manually before pushing.

## Conventions worth knowing

- **Slugs are permanent.** `FR-`/`NFR-`/`AC-`/`TC-` identifiers are never renamed or reused. Use the reserved `-ex-` prefix (`FR-ex-…`) for examples in prose so the audits ignore them.
- **Domain vocabulary.** If a legitimately in-domain term (a language Shepherd supports, an OS it runs on) trips a lane audit, add it to `laneAudit.exclude` in `pdeq.json` rather than reworording the spec.
- **Decisions** go in `decisions-pending.md` during a change (the pre-commit hook merges them into `decisions.md`), never directly into `decisions.md`.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
