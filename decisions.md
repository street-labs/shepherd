# Decision Log

Append-only record of key decisions made during this project. Newest entries at the bottom.

This log provides **historical context for how the project evolved** — why choices were made, what alternatives were considered, and what changed over time. While specs are living documents that reflect current state, this log preserves the reasoning trail. When you read the specs and wonder "why is it done this way?", the answer should be here.

**Do not edit or delete past entries.** If a decision is reversed, add a new entry that references the original.

## 2026-02-20 -- Use Vite as the build tool
**Context**: Need a build tool for the React + TypeScript SPA. Must support fast development and production bundling.
**Decision**: Use Vite with the `react-ts` template.
**Alternatives considered**: Create React App (deprecated), Next.js (overkill for client-only SPA), Parcel, webpack.
**Rationale**: Vite is the industry standard for new React SPAs. Native ESM dev server with fast HMR. Zero-config for React/TS. Excellent ecosystem support.
**Consequences**: All build configuration uses `vite.config.ts`. Dev server runs on Vite.
**Slug references**: `NFR-crp-client-only`

## 2026-02-20 -- Use Shiki for syntax highlighting
**Context**: The code viewer requires syntax highlighting for 14+ languages (`FR-crp-syntax-highlight`). Need a client-side library that supports all required languages with high accuracy.
**Decision**: Use Shiki with the `github-light` theme and lazy language loading.
**Alternatives considered**: Prism.js (lighter weight, but less accurate for languages like Rust/Go; regex-based vs TextMate grammars), CodeMirror (full editor runtime is unnecessary overhead -- we only need read-only display).
**Rationale**: Shiki uses the same TextMate grammars as VS Code, giving the most accurate highlighting across all 14 languages. WASM-based engine runs in the browser. Produces static HTML tokens with no runtime overhead. Lazy language loading keeps initial bundle small.
**Consequences**: WASM adds ~200 KB to the initial bundle (gzipped). Language grammars load on demand (~10-50 KB each). Progressive highlighting strategy needed for large files to meet `NFR-crp-render-time`.
**Slug references**: `FR-crp-syntax-highlight`, `NFR-crp-render-time`, `AC-crp-syntax-highlight-detected`

## 2026-02-20 -- Use TanStack Virtual for virtualized scrolling
**Context**: Files up to 10,000 lines must scroll without jank (`NFR-crp-large-file-perf`). The code viewer needs virtualized rendering to avoid creating 10,000+ DOM nodes.
**Decision**: Use TanStack Virtual (v3) for row virtualization.
**Alternatives considered**: react-window (does not support variable-height rows well -- needed for inline comment bubbles), react-virtuoso (heavier, more opinionated), custom virtualizer (unnecessary build-vs-buy risk).
**Rationale**: TanStack Virtual is lightweight (~5 KB), headless (no DOM opinions), React-first, and supports variable-height rows natively via `measureElement`. Handles the interleaved code-line and comment-bubble rendering model cleanly.
**Consequences**: Comment bubbles and the inline editor are rendered as variable-height items within the virtual list. Dynamic height measurement via `ResizeObserver` is required.
**Slug references**: `NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`

## 2026-02-20 -- Use Zustand for state management
**Context**: Need a state management approach for the SPA. State includes file content, comments, preamble, generated prompt, and UI state (editor open/closed, focused comment, selected range).
**Decision**: Use Zustand as the single state store.
**Alternatives considered**: React Context + useReducer (would work but causes unnecessary re-renders in the code viewer without careful memoization), Redux Toolkit (too much boilerplate for this app's complexity), Jotai (atomic model is less natural for this interconnected state).
**Rationale**: Zustand provides fine-grained subscriptions (components only re-render when their selected slice changes), minimal boilerplate, and works outside React components (useful for the prompt generation logic). Clean separation of state logic from components.
**Consequences**: Single store in `src/store/appStore.ts`. No React Context providers needed. Components access state via `useAppStore` hook with selectors.
**Slug references**: `NFR-crp-no-data-persistence`

## 2026-02-20 -- Use Tailwind CSS v4 for styling
**Context**: Need a CSS approach for the application. The design spec provides explicit color tokens and spacing values.
**Decision**: Use Tailwind CSS v4 with custom theme tokens matching the design spec's color palette.
**Alternatives considered**: CSS Modules (good scoping but more verbose; harder to match the design spec's explicit token system), styled-components (runtime CSS-in-JS adds overhead), vanilla CSS (no scoping, harder to maintain).
**Rationale**: Utility-first approach matches well with component-based architecture. No CSS naming collisions. v4 uses CSS-native cascade layers and `@theme` directive, eliminating PostCSS config complexity. Design spec's color tokens map directly to Tailwind theme values.
**Consequences**: All styling is utility-class-based in JSX. Custom theme tokens defined in `src/styles/app.css`.
**Slug references**: `NFR-crp-responsive-layout`

## 2026-02-21 -- Two-mode slash command architecture (Claude Code command + standalone CLI)
**Context**: The user wants to invoke the CRPG via `/shepherd <filepath>` from an AI coding agent. Need to decide how the command is distributed and executed.
**Decision**: Implement two modes: (1) A Claude Code custom command file (`.claude/commands/shepherd.md`) for in-repo use — zero code, just a markdown prompt that instructs the agent. (2) A standalone Node.js CLI package (`engineering/apps/cli/`) for global installation via npm.
**Alternatives considered**: CLI-only (would require npm install for everyone, even in-repo users), Claude Code command-only (wouldn't work outside Claude Code or outside the repo), VS Code extension (too platform-specific).
**Rationale**: The Claude Code custom command is the simplest possible solution for the primary use case — it's just a `.md` file. The standalone CLI provides distribution for users outside the repo or using other agents. Both share the same file-serving API and CRPG web app.
**Consequences**: Two entry points to maintain. The Vite dev server needs a file-serving API plugin. The CLI needs to bundle built web assets and run its own HTTP server.
**Slug references**: `FR-sc-invoke-command`, `FR-sc-install`, `FR-sc-app-serve`

## 2026-02-21 -- Vite plugin for file-serving API (no additional dependencies)
**Context**: The CRPG needs a localhost API endpoint to read local files when launched via the slash command. In dev mode, Vite serves the app.
**Decision**: Implement the `/api/file` endpoint as a Vite plugin using the `configureServer` hook, requiring zero additional npm dependencies.
**Alternatives considered**: Express middleware (adds a dependency), separate sidecar server (more complex), reading files directly in the browser (not possible — browser can't access filesystem by path).
**Rationale**: Vite's `configureServer` hook provides direct access to the dev server's Connect middleware. This keeps the file API colocated with the dev server, adds no dependencies, and works identically in dev and preview modes.
**Consequences**: The file API only exists when served by Vite (dev/preview) or the standalone CLI server. The built static assets alone cannot serve files — they need a server with the API.
**Slug references**: `FR-sc-file-api`, `FR-sc-auto-load-file`

## 2026-02-21 -- Prompt format changed to code-snippet-per-comment (no full file, no line numbers)
**Context**: During testing of the CRPG, the user identified that including the full file content and line numbers in the generated prompt was problematic — line numbers change as the file is edited, making them unreliable references.
**Decision**: The generated prompt now includes only the file path/language and each comment paired with the actual code snippet it references. No full file content, no line numbers.
**Alternatives considered**: Keep full file with line numbers (original spec), include only changed regions with surrounding context.
**Rationale**: Code snippets are stable references that remain meaningful even after the file is edited. The prompt is also shorter and more focused. Comments may be feedback, questions, or affirmations — not always change requests.
**Consequences**: The `buildPrompt()` function extracts code slices per comment instead of formatting the entire file. Prompt output size scales with comment count, not file length.
**Slug references**: `FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`

## 2026-02-21 -- Use jsdiff for client-side diff computation
**Context**: The diff view feature needs to compute unified diffs between two file versions entirely in the browser (`NFR-diff-client-compute`). Need a diff library that produces structured hunks suitable for rendering.
**Decision**: Use the `diff` npm package (jsdiff) with its `structuredPatch` function.
**Alternatives considered**: Custom Myers diff implementation (unnecessary build-vs-buy risk), `diff-match-patch` by Google (character-level, not line-level — wrong granularity), running `git diff` on the server (violates `NFR-crp-client-only` principle of keeping computation client-side).
**Rationale**: jsdiff is the standard JavaScript diff library (10M+ weekly npm downloads), battle-tested, zero dependencies, works in the browser, and `structuredPatch` directly produces the hunk data structure we need for rendering. Performance is well within `NFR-diff-compute-perf` targets for files up to 10K lines.
**Consequences**: The server serves two plain text file versions; the browser computes the diff. If profiling shows blocking on very large files, the pure function can be trivially moved to a Web Worker.
**Slug references**: `FR-diff-compute`, `NFR-diff-compute-perf`, `NFR-diff-client-compute`

## 2026-02-21 -- Separate comment stores for file mode and diff mode
**Context**: Diff view comments anchor to `DiffLineId` (line type + old/new line numbers), while file view comments anchor to simple line numbers. Need to decide whether to unify or separate the comment models.
**Decision**: Maintain separate comment stores — `comments` for file mode and `diffComments` for diff mode. Switching modes clears the active mode's comments with user confirmation.
**Alternatives considered**: Unified comment store with polymorphic anchoring (complex, error-prone mapping between modes), attempt to map comments between modes (fundamentally different line models make this unreliable and confusing).
**Rationale**: File view and diff view have fundamentally different line addressing models. A comment on "line 42" in file view has no reliable mapping to a diff line, and vice versa. Separate stores keep the data model clean and avoid lossy conversions. The confirmation dialog on mode switch makes the behavior explicit.
**Consequences**: Users lose comments when switching modes. This is clearly communicated via the confirmation dialog. The prompt builder has two code paths: `buildPrompt` for file mode and `buildDiffPrompt` for diff mode.
**Slug references**: `FR-diff-mode-toggle`, `FR-diff-comment-create`, `AC-diff-switch-clears-comments`

## 2026-02-21 -- Unified diff only (no side-by-side view) for v1
**Context**: Diff views commonly offer both unified and side-by-side display modes. Need to decide scope for the initial implementation.
**Decision**: Support unified diff view only in v1. Side-by-side is deferred.
**Alternatives considered**: Side-by-side view (more space-efficient for reviewing changes but doubles the component complexity), both views with a toggle (too much scope for v1).
**Rationale**: Unified diff is simpler to implement, works better with the existing single-column code viewer layout, and is the standard format developers use in CLI tools. Side-by-side can be added as a follow-up if users request it.
**Consequences**: The DiffViewer component renders a single column with line type indicators, dual line numbers, and colored backgrounds. The existing layout (code viewer + sidebar) works without modification.
**Slug references**: `FR-diff-display`, `FR-diff-collapse`

## 2026-02-21 -- HEAD-only baseline (no arbitrary commit/branch baselines) for v1
**Context**: The diff view needs a baseline version to diff against. Need to decide what baselines to support.
**Decision**: The baseline is always `git HEAD` for v1. No support for diffing against specific commits, branches, or the staged version.
**Alternatives considered**: Arbitrary commit selection (adds UI complexity for commit picker), staged vs unstaged diff (useful but secondary use case), branch comparison (more of a merge/PR review workflow).
**Rationale**: The primary use case is "an AI agent just modified my file, what changed?" — this is always the working copy vs the last committed version. HEAD is the right baseline for this workflow. More baselines can be added later without changing the architecture.
**Consequences**: The `/api/file/head` endpoint runs `git show HEAD:<path>`. If the file is untracked (no HEAD version), all lines show as additions. More baseline options can be added by extending the API endpoint.
**Slug references**: `FR-diff-baseline-fetch`, `AC-diff-no-git-history`

## 2026-02-21 -- Formalize the engineering-QA iteration loop
**Context**: Bugs have been found manually through iteration rather than caught systematically. The project has 130+ test cases defined in QA test plans and the test toolchain is installed (Vitest, RTL, Playwright), but zero test code exists. The process is linear with no documented feedback loop between engineering and QA, and no design/product sign-off step.
**Decision**: Formalize a structured iteration loop: QA executes tests and reports failures with TC- slugs and observed vs expected behavior, engineering fixes (updating specs first if the fix changes architecture), QA re-verifies, and the loop continues until all tests pass. Add a design/product final review gate before a feature is considered "done". Extend the pre-commit hook to run unit tests when .ts/.tsx files are staged. Write automated unit, integration, and E2E tests based on existing QA test plans.
**Alternatives considered**: Continue with ad-hoc manual testing (does not scale), add a CI pipeline (premature — no tests exist yet to run), hire a QA person (this is a process problem, not a people problem).
**Rationale**: Test plans without test code provide no automated safety net. A documented iteration loop ensures bugs are caught systematically, fixes are verified, and features meet their acceptance criteria before sign-off. Co-locating tests with source and running them on pre-commit creates a fast feedback loop.
**Consequences**: Engineering must write test code alongside feature code. QA must execute tests and report results, not just write plans. The pre-commit hook now also runs Vitest when TypeScript files change. All four agents (product, design, engineering, QA) participate in the sign-off process.
**Slug references**: All existing `TC-` slugs, `AC-crp-*`, `AC-diff-*`, `FR-crp-*`, `FR-diff-*`

<!--
Entry template:

## YYYY-MM-DD — [Decision Title]
**Context**: Why this decision came up.
**Decision**: What was decided.
**Alternatives considered**: What else was on the table.
**Rationale**: Why this option was chosen.
**Consequences**: What this means going forward.
**Slug references**: [Any requirement slugs this affects]
-->
