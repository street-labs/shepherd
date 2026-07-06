<!--
Shepherd accepts contributions via pull request only (issues are disabled).
Bug report? This PR should add a test that reproduces it.
-->

## What & why

<!-- One or two sentences. If this fixes a bug, describe the wrong behavior. -->

## Test

<!-- Required. Point to the test that reproduces the bug or covers the change. -->

- [ ] Adds/updates a test under `engineering/apps/macos/Tests/` (or explains why none is possible)

## Spec-driven checklist

- [ ] If behavior changed, the **markdown spec was updated first** (product → design/engineering/QA), and code carries an `// Implements: <slug>` marker
- [ ] `./scripts/audit-traceability.sh --check` passes
- [ ] `./scripts/audit-structure.sh` passes (specs stay in-lane)
- [ ] `swift build && swift test` pass in `engineering/apps/macos`

<!-- Not every PR touches specs (docs/CI/tooling); tick what applies. -->
