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

## 2026-02-21 -- Remove Generate button; auto-generate prompt on every comment/preamble change
**Context**: The CRPG required users to click a "Generate" button to produce the prompt after adding comments. This introduced an unnecessary manual step — users would add comments, forget to click Generate, and try to copy a stale or missing prompt.
**Decision**: Remove the Generate button entirely. The prompt is now automatically generated (and regenerated) whenever the user adds, edits, or deletes a comment, or modifies the preamble. The prompt preview is always current. The "stale prompt" concept and its yellow warning banner are eliminated.
**Alternatives considered**: Keep the Generate button but add an "auto-regenerate" toggle (adds complexity for minimal benefit), debounce auto-generation with a visible delay (unnecessary given sub-5ms generation time).
**Rationale**: Prompt generation completes in <5ms (`NFR-crp-prompt-gen-time` budget is 300ms), so there is zero performance reason for a manual trigger. Automatic generation simplifies the user's workflow from "annotate → generate → copy" to "annotate → copy" and eliminates the entire stale-prompt state machine. The `Cmd+Shift+G` keyboard shortcut is also removed, freeing that binding for future use.
**Consequences**: The Toolbar loses one button (Generate/Regenerate). The Zustand store no longer has a `generatePrompt` action or `isPromptStale` flag — instead, `buildPrompt()` is called inside `addComment`, `updateComment`, `deleteComment`, and `setPreamble`. The PromptPreview component drops its `stale` variant. QA test cases referencing the Generate button are updated to test auto-generation behavior.
**Slug references**: `FR-crp-prompt-generate`, `AC-crp-generate-prompt-no-comments`, `FR-crp-prompt-preview`

## 2026-02-21 -- Working tree diff (not committed-only) for changeset detection
**Context**: The initial implementation of `/shepherd-review` used `git diff --name-status MERGE_BASE...HEAD`, which only shows changes committed on the branch. When tested, this produced an empty changeset because the new files hadn't been committed yet. The whole point of the tool is to review changes before committing.
**Decision**: Use `git diff --name-status MERGE_BASE` (no dots, no `...HEAD`) to compare the working tree against the merge base, plus `git ls-files --others --exclude-standard` to capture untracked new files. This gives the full picture of what differs from main.
**Alternatives considered**: `git diff --name-status MERGE_BASE...HEAD` (committed only — misses the primary use case), `git status --porcelain` (only shows uncommitted changes, misses committed branch changes), `git diff --name-status HEAD` (only uncommitted changes relative to HEAD, misses branch changes vs main).
**Rationale**: The developer's mental model is "what's different from main in my working copy." This includes committed branch changes, staged changes, unstaged changes, and new untracked files. The no-dots form of `git diff` against the merge base captures exactly this.
**Consequences**: The changeset may include files that are modified in the working tree but will be reverted before committing. This is acceptable — the user can skip files during the review.
**Slug references**: `FR-sr-changeset-detection`

## 2026-02-21 -- Guided review: priority ordering, context, and feedback collection
**Context**: During first live test of `/shepherd-review`, the user identified three issues: (1) files were presented alphabetically rather than by importance, (2) there was no context about what changed in each file before opening it, (3) there was no way to collect review feedback for later action.
**Decision**: Add three features: priority-based file ordering using a general-purpose heuristic (source code > config > docs > supporting > tests), per-file context summaries derived from reading the actual diffs, and a feedback collection mechanism that accumulates CRPG output across files and presents it at the end for action.
**Alternatives considered**: For ordering — let the user manually reorder (too much friction), use file extension as sole heuristic (too crude). For context — show raw diff stats only (not enough insight), skip context and let the CRPG speak for itself (misses the guided aspect). For feedback — act on feedback immediately per-file (user explicitly wanted batch processing at the end), write to a file per-file (fragmented).
**Rationale**: The whole point of `/shepherd-review` is to be a *guided* review experience, not just a file iterator. The agent should leverage its ability to read and understand diffs to provide value at every step. Feedback collection makes the review a complete workflow: review, annotate, then act.
**Consequences**: The command now uses `Read` tool in addition to `Bash` (to read diffs for context). The iteration loop has a new "feedback" user action. The completion step includes a feedback handoff phase.
**Slug references**: `FR-sr-priority-ordering`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-feedback-collection`

## 2026-02-21 -- Three scope modes for changeset detection (default, --staged, --unstaged)
**Context**: After implementing working-tree-based changeset detection, the user requested the ability to differentiate between staged and unstaged changes. The use case: stage files you're happy with, then use `--unstaged` to review what's left, or use `--staged` to review exactly what will be committed.
**Decision**: Add an optional `$ARGUMENTS` parameter with three modes: default (all changes vs main), `--staged` (only staged files relative to merge base), `--unstaged` (only unstaged modifications + untracked files).
**Alternatives considered**: Separate commands (`/shepherd-review-staged`), interactive mode selection during the review, config file.
**Rationale**: A single command with a flag is the simplest interface. The three modes map directly to common git workflows: review everything, review what I'm about to commit, review what I haven't staged yet.
**Consequences**: The command now uses `$ARGUMENTS`. The scope label is shown in the file list header so the user knows which mode they're in.
**Slug references**: `FR-sr-scope-argument`

## 2026-02-21 -- Pure prompt file for /shepherd-review (no compiled code)
**Context**: Need to implement a multi-file review workflow that discovers git changesets, filters files, and iterates through them. Could be a compiled CLI tool, a shell script, or a Claude Code prompt file.
**Decision**: Implement `/shepherd-review` as a pure Claude Code custom command file (`.claude/commands/shepherd-review.md`) — a markdown prompt that instructs the agent to run git commands, apply filtering logic, and manage the review loop conversationally.
**Alternatives considered**: Shell script wrapper (would need to handle interactive I/O with the agent, awkward), Node.js CLI (unnecessary complexity — the agent can run git commands directly), compiled binary (massive overkill for a conversational workflow).
**Rationale**: The agent is already the execution environment. It can run `git diff`, parse output, apply filtering rules, track state in conversation context, and invoke `/shepherd` for each file. A prompt file achieves all of this with zero dependencies, zero compilation, and zero additional infrastructure. The existing `/shepherd` command proves this pattern works.
**Consequences**: The command's behavior depends on how well the agent interprets the prompt instructions. Exact formatting may vary slightly between invocations. This is acceptable for v1 — the command orchestrates a human-in-the-loop review, so minor output variations are tolerable.
**Slug references**: `FR-sr-command-file`, `FR-sr-scope-argument`, `NFR-sr-no-dependencies`, `NFR-sr-agent-native`

## 2026-02-21 -- Path-based file filtering only (no content reading)
**Context**: The review command needs to filter out "uninteresting" files from the changeset. Could inspect file contents (e.g., read bytes to detect binary) or use path patterns.
**Decision**: Filter purely by file path and extension patterns. Do not read file contents during filtering.
**Alternatives considered**: Read file headers to detect binary content (more accurate but slower), use `git diff --stat` to filter by change size (interesting but doesn't address file-type filtering), use `.gitattributes` (not all repos have this configured).
**Rationale**: Path-based filtering is fast (no I/O), simple to implement in a prompt, and catches the vast majority of uninteresting files. The agent can list all patterns inline in the prompt instructions. Files that pass filtering but turn out to be uninteresting can be skipped by the user during the review loop.
**Consequences**: Some edge cases may slip through (e.g., a `.ts` file that is entirely auto-generated but doesn't match any exclusion pattern). The user can skip these manually. Custom exclusion patterns are deferred to v2.
**Slug references**: `FR-sr-file-filtering`, `NFR-sr-startup-speed`

## 2026-02-21 -- Default to main as base branch (no auto-detection in v1)
**Context**: The review command compares the current branch against a base branch. Repositories use different default branch names (`main`, `master`, `develop`).
**Decision**: Default to `main` as the base branch. No auto-detection or override argument in v1.
**Alternatives considered**: Auto-detect via `git symbolic-ref refs/remotes/origin/HEAD` (not always configured, adds complexity), accept an optional `--base` argument (adds argument parsing to the prompt).
**Rationale**: `main` is the overwhelmingly common default for new repositories. The user already knows they're comparing against main. Auto-detection and override arguments are natural v2 enhancements that don't affect the core architecture.
**Consequences**: Users with `master` or other default branch names will get an error ("No changes found relative to main"). This is a known limitation for v1 and is documented in the product spec's Open Questions.
**Slug references**: `FR-sr-changeset-detection`, `AC-sr-no-changes`

## 2026-02-21 -- Test decision entry
**Context**: Testing the merge script.
**Decision**: This is a test.
**Alternatives considered**: None.
**Rationale**: Smoke test.
**Consequences**: None.
**Slug references**: N/A

## DEC: File-based handoff for prompt feedback loop
**Date**: 2026-02-21
**Context**: The user wanted a way to get the generated prompt from the CRPG back to the Claude Code agent without manual copy-paste. Multiple approaches were considered: (A) file handoff + manual confirm, (B) file-based watcher with blocking script, (C) clipboard + terminal focus switching, (D) SSE/streaming.
**Decision**: Use file-based handoff with a blocking watcher (Approach B). The CRPG POSTs the prompt to the server, which writes it to `~/.shepherd/prompt-output.md`. The slash command runs a blocking shell script that polls for the file every 1 second. When found, it reads and deletes the file.
**Rationale**: This is the simplest approach that achieves the "click Done and it just works" experience. The watcher is ~3 lines of portable POSIX shell. No filesystem event libraries, no WebSocket infrastructure, no platform-specific hacks. The 1-second polling interval is a good balance between responsiveness and resource usage. Clipboard copy runs in parallel as a fallback.
**Alternatives rejected**:
- Manual confirm (Approach A): Still requires 3 user steps (click Done, switch apps, tell agent). Doesn't meet the user's goal.
- Clipboard + focus (Approach C): Platform-specific (macOS AppleScript, etc.), fragile (which terminal app?), and still requires manual paste.
- SSE/streaming (Approach D): More robust than file polling but adds WebSocket/SSE complexity for marginal benefit over a 1-second poll.
## DEC: Done button visibility conditional on slash command mode
**Date**: 2026-02-21
**Context**: The CRPG can be used in two modes: standalone (paste/upload/drag-drop) and slash command mode (launched via `/shepherd`). The Done button only makes sense in slash command mode because there's no agent watcher in standalone mode.
**Decision**: The Done button is only rendered when `isSlashCommandMode` is true. In standalone mode, Copy remains the primary action. Slash command mode is detected by whether the file was loaded via the `?file=` URL parameter.
**Rationale**: Showing Done in standalone mode would be confusing — the POST would succeed but nobody would be listening. Hiding it keeps the UI clean and avoids a dead-end action.
## DEC: 30-minute watcher timeout
**Date**: 2026-02-21
**Context**: The file watcher blocks the agent while the user annotates in the browser. Need a timeout to prevent indefinite blocking.
**Decision**: 30-minute timeout. After timeout, the watcher exits and the agent informs the user they can paste manually.
**Rationale**: 30 minutes is generous enough for thorough annotation sessions but prevents abandoned watchers from running indefinitely. The clipboard fallback ensures the user can still complete the workflow even after timeout.
## DEC: App-mode browser window instead of regular tab
**Date**: 2026-02-22
**Context**: The CRPG was opening as a regular browser tab. This meant: (1) it mixed in with the user's other tabs, (2) closing it required finding the right tab, and (3) when the user clicked Done, they had to manually switch back to the terminal.
**Decision**: Open the CRPG using Chrome/Chromium's `--app` flag, which creates a chromeless standalone window. Fall back to the default browser if Chrome is not available.
**Rationale**: App-mode windows feel like a standalone tool rather than a website. When the window closes (via `window.close()` after Done), focus naturally returns to the terminal — the last active window. This eliminates the "switch back to terminal" step entirely. Chrome is the most common developer browser, so the `--app` flag is widely available. The fallback chain (Chrome → Chromium → default browser) ensures the feature never breaks.
## DEC: Auto-close window after Done action
**Date**: 2026-02-22
**Context**: After clicking Done, the user previously had to manually switch back to the terminal. With the app-mode window, we can close it programmatically.
**Decision**: After a successful prompt handoff, call `window.close()` to close the CRPG window. Use a 500ms timeout to detect if the close worked; if not, fall back to showing the "Sent" confirmation toast.
**Rationale**: `window.close()` works in Chrome app-mode windows because they are opened programmatically (via `--app`). In regular browser tabs, `window.close()` is blocked by browser security. The 500ms fallback ensures the user always sees feedback — either the window closes (best case) or they see the toast (fallback). Clipboard copy happens in parallel before the close attempt, so the prompt is always available.

## 2026-02-21 -- Launcher shell script to eliminate agent overhead in slash command
**Context**: The `/shepherd` slash command was too slow. The Claude Code custom command (`.claude/commands/shepherd.md`) instructed the agent to perform 5-7 sequential steps (resolve path, validate file, check server, start server, URL-encode, open browser), each requiring a separate AI inference round-trip and tool call. While the shell operations themselves took ~255ms total, the agent overhead added multiple seconds of AI inference time per step, making the total launch time unacceptably slow.
**Decision**: Create a launcher shell script (`scripts/shepherd-launch.sh`) that handles all validation and launch logic in a single invocation. The slash command file delegates to this script, reducing the agent's role to one tool call: `bash scripts/shepherd-launch.sh <filepath>`.
**Alternatives considered**: (1) Optimizing the prompt to reduce agent steps (marginal improvement — still multiple tool calls), (2) Pre-building the app and serving with a lightweight server (helps cold start but doesn't fix the agent overhead problem), (3) A Node.js CLI launcher (adds a runtime dependency; a shell script is simpler and needs only POSIX tools).
**Rationale**: A shell script eliminates the per-step AI inference overhead entirely. The script uses only standard POSIX tools (curl, head, tr, wc, realpath) and runs in ~265ms for a warm launch. Combined with a single agent tool call (~500-1500ms), this achieves the updated NFR target of <2 seconds for warm launches.
**Consequences**: The slash command file becomes a thin wrapper that invokes the script. Validation logic moves from agent-mediated shell commands to deterministic script logic, making error messages and exit codes consistent. The script must be kept in sync with any changes to the validation rules or server management approach.
**Slug references**: `FR-sc-launcher-script`, `NFR-sc-launch-speed`, `AC-sc-warm-launch-2s`, `AC-sc-cold-launch-8s`, `AC-sc-single-tool-call`
## 2026-02-21 -- Use unified/remark ecosystem for markdown rendering
**Context**: The markdown rendered view feature needs a client-side markdown parser that supports CommonMark + GFM, produces an AST for element identification and comment anchoring, and integrates with an HTML sanitization pipeline.
**Decision**: Use the unified/remark ecosystem (`remark-parse` + `remark-gfm` + `remark-rehype` + `rehype-sanitize` + `rehype-stringify`).
**Alternatives considered**: markdown-it (produces HTML strings, not ASTs — cannot assign stable element identifiers or compute AST-level diffs without re-parsing), marked (similar limitations), MDsveX (Svelte-specific).
**Rationale**: The unified ecosystem operates on ASTs at every stage of the pipeline. This gives us: (1) source position data on every node for AST-to-line mapping, (2) stable node indices for element identifiers, (3) a natural integration point for rehype-sanitize (AST-level sanitization before DOM insertion), and (4) the ability to diff two ASTs for the rendered diff view. The ~31 KB gzipped bundle size is acceptable.
**Consequences**: The rendering pipeline is: markdown source → remark-parse → MDAST → remark-gfm → remark-rehype → HAST → rehype-sanitize → rehype-stringify → HTML string. Element identifiers and source-line mappings are extracted from the MDAST before conversion.
**Slug references**: `FR-mdr-render-commonmark`, `FR-mdr-element-id`, `FR-mdr-rendered-diff-display`, `NFR-mdr-xss-safety`

## 2026-02-21 -- Separate comment store for rendered mode (three stores total)
**Context**: Rendered view comments anchor to AST element identifiers (e.g., `heading-0`, `paragraph-3`), which are fundamentally different from file-mode line numbers and diff-mode diff line identifiers. Need to decide how to store rendered-mode comments.
**Decision**: Add a third comment store (`renderedComments`) alongside the existing `comments` (file mode) and `diffComments` (diff mode). Switching between rendered and raw views clears comments with confirmation, consistent with the existing mode-switch behavior.
**Alternatives considered**: Map comments between rendered and raw views via AST-to-line mapping (technically possible but introduces edge cases — e.g., a paragraph spanning 5 raw lines, which line gets the comment?), unified polymorphic store (too complex, different anchor types).
**Rationale**: Consistent with the existing design decision to keep file-mode and diff-mode comment stores separate. Each view mode has a fundamentally different addressing model. Clean separation avoids lossy conversions. Comment mapping between views is deferred to v2 (Open Question #1 in the product spec).
**Consequences**: Three separate comment stores in Zustand. Three prompt builders (`buildPrompt`, `buildDiffPrompt`, `buildRenderedPrompt`). Mode switches always clear comments. Users are warned via confirmation dialog.
**Slug references**: `FR-mdr-rendered-comment-create`, `FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`

## 2026-02-21 -- Custom LCS-based block diff for rendered markdown diff (no tree edit distance)
**Context**: The rendered diff view needs to compare two markdown documents at the AST level to identify added, removed, modified, and unchanged blocks. Need a diffing algorithm.
**Decision**: Use a custom LCS (Longest Common Subsequence) based approach that flattens both ASTs to sequences of block-level elements, diffs the sequences, and applies word-level diffing (via jsdiff's `diffWords`) to modified blocks.
**Alternatives considered**: Full tree edit distance (e.g., Zhang-Shasha algorithm — overkill for shallow markdown documents), line-level diff of rendered HTML (would diff presentation not structure), existing AST diff libraries (none handle the markdown-specific requirements well).
**Rationale**: Markdown documents are shallow trees (depth rarely exceeds 3-4 levels). A flat block-level LCS is sufficient and much simpler than tree edit distance. Modified blocks (same position, different content) get word-level highlighting via the existing jsdiff dependency. The 80% changed-blocks threshold triggers a fallback to raw diff view.
**Consequences**: The diff algorithm has O(n*m) complexity where n and m are block counts. For practical markdown files (<500 blocks) this is fast. An 80% fallback threshold prevents unusable rendered diffs. Performance budget: 1s for <5K lines, 3s for 5-10K lines, 5s timeout with fallback.
**Slug references**: `FR-mdr-rendered-diff-display`, `NFR-mdr-rendered-diff-perf`, `AC-mdr-diff-fallback`

## 2026-02-21 -- Native scroll + content-visibility for rendered view (no virtualization)
**Context**: The rendered markdown view produces heterogeneous HTML elements (headings, paragraphs, tables, code blocks) of varying heights. The raw code viewer uses TanStack Virtual for virtualized scrolling, but this requires uniform or measurable row heights.
**Decision**: The rendered view uses native scrolling with CSS `content-visibility: auto` for large files, rather than virtualized rendering.
**Alternatives considered**: TanStack Virtual (would require treating each rendered block as a measured item — complex and fragile with heterogeneous content), intersection observer-based lazy rendering (more custom code for marginal benefit), pagination (poor UX for document reading).
**Rationale**: Heterogeneous rendered content makes virtualization impractical without significant complexity. `content-visibility: auto` provides a simpler optimization that lets the browser skip layout/paint for offscreen content. For files up to 10K lines, this is sufficient. The rendered view is expected to be used primarily for markdown files (typically <2K lines), where the performance budget is met easily.
**Consequences**: Very large markdown files (>10K lines) may have slower initial render than the raw view. The 500ms budget for 5-10K lines should still be met with `content-visibility`. If it isn't, a Web Worker can offload parsing.
**Slug references**: `NFR-mdr-render-scroll-perf`, `NFR-mdr-render-perf`, `AC-mdr-large-file-renders`

## DEC-multi-file-tab-bar: Use tab bar for multi-file navigation
**Date**: 2026-02-22
**Context**: Adding multi-file support to the CRPG. The user was unsure about the UI pattern — options included a left sidebar file panel, tabs, or a scrolling view.
**Decision**: Use a horizontal tab bar positioned between the toolbar and the code viewer panel. Tabs are ordered by load order. Each tab shows file name, comment count badge, and close button. A "+" button opens a file-loading modal.
**Rationale**: The tab bar fits naturally into the existing two-column layout (code viewer + sidebar) without stealing horizontal space from either panel. It's a familiar metaphor (browser tabs, IDE tabs), scales well for typical use cases (2-10 files), and provides clear affordance for switching, adding, and removing files.
**Alternatives considered**: Left sidebar panel (squeezes code viewer), scrolling file list (poor random access for many files), vertical tabs (uncommon pattern).
**Impacts**: `design/code-review-prompt.md` (new FileTabBar component), `engineering/code-review-prompt.md` (new component + state), `qa/code-review-prompt.md` (new test cases).
## DEC-multi-file-global-preamble: Single global preamble, not per-file
**Date**: 2026-02-22
**Context**: With multi-file support, the preamble could be global (one for the entire session) or per-file (one per loaded file).
**Decision**: V1 uses a single global preamble shared across all files. The preamble appears once at the top of the generated prompt, not per-file.
**Rationale**: Simpler UX — the preamble sets the overall intent for the entire review ("refactor for consistency across these files"). Per-file instructions can be captured as inline comments on specific files. Per-file preamble remains a candidate for v2 if users need it.
**Impacts**: `product/code-review-prompt.md` (Open Question #9), `engineering/code-review-prompt.md` (prompt builder), `design/code-review-prompt.md` (sidebar preamble input unchanged).
## DEC-multi-file-load-order: Files ordered by load order in prompt
**Date**: 2026-02-22
**Context**: Multi-file prompts need a file ordering strategy. Options: load order, alphabetical, user-reorderable.
**Decision**: V1 uses load order. Files appear in the prompt in the same order they were loaded (which matches tab bar order).
**Rationale**: Simple, predictable, and matches the visual order in the tab bar. Alphabetical sorting might not match the review narrative. Drag-to-reorder tabs is deferred to v2.
**Impacts**: `product/code-review-prompt.md` (Open Question #8), `engineering/code-review-prompt.md` (`fileOrder` array).
## DEC-multi-file-drop-all: Load all dropped files, not just the first
**Date**: 2026-02-22
**Context**: Previously, dropping multiple files loaded only the first. With multi-file support, this restriction no longer makes sense.
**Decision**: When multiple files are dropped simultaneously, all files are loaded. Binary files are rejected per-file with individual error toasts. A summary toast shows how many files were loaded and how many were skipped.
**Rationale**: The original single-file restriction existed because the app only supported one file. Now that it supports multiple files, the natural behavior is to load all of them.
**Impacts**: `product/code-review-prompt.md` (updated `FR-crp-file-load`), `design/code-review-prompt.md` (updated FileDropZone), `engineering/code-review-prompt.md` (updated drop handler).

## D-sr-batch-open -- Switch from sequential iteration to batch-open model
- **Date**: 2026-02-22
- **Context**: The `/shepherd-review` command originally iterated through files one-by-one, calling `/shepherd` for each file and waiting for the user to respond before opening the next. With the CRPG now supporting multi-file tabs, this sequential approach was unnecessarily slow.
- **Decision**: Replace the sequential one-file-at-a-time iteration with a batch-open model that opens all reviewable files at once in a single CRPG session.
- **Rationale**: The CRPG already has full multi-file support (tabs, per-file comments, multi-file prompt generation). Batch-opening eliminates the awkward agent-mediated iteration and lets the user control their review entirely within the CRPG UI. This is simpler for the user, faster, and produces a single unified prompt.
- **Alternatives considered**: (1) Keep sequential iteration but add a "batch mode" flag. Rejected: two modes adds complexity and the sequential mode has no clear advantage. (2) Open files via a file list API endpoint. Rejected: URL parameters are simpler and don't require new server infrastructure.
- **Affects**: `product/shepherd-review.md`, `design/shepherd-review.md`, `engineering/shepherd-review.md`, `qa/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `scripts/shepherd-launch.sh`, `engineering/apps/web/src/hooks/useFileFromUrl.ts`

## 2026-02-23 -- Context display location: collapsible panel above code viewer
**Context**: The review context (neutral + review feedback) needs a place in the CRPG layout.
**Decision**: Use a collapsible panel between the file tab bar and the code viewer, rather than a sidebar panel or overlay.
**Alternatives considered**: Sidebar panel (would compete with the existing preamble/prompt preview), overlay/modal (would obscure the code the user is reviewing), inline annotations per-line (too granular for changeset-level and file-level context).
**Rationale**: A horizontal panel above the code viewer is naturally glanceable without leaving the code. Collapsible so it doesn't permanently consume vertical space. Sidebar would compete with the existing preamble/prompt preview. Overlay would obscure code.
**Consequences**: The layout gains a new vertical region between the tab bar and code viewer. The panel must handle two levels of content: overall changeset context (always visible) and per-file context (switches with tabs). Collapse state should be preserved per session.
**Slug references**: `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`
## 2026-02-23 -- Context data transport: JSON file at ~/.shepherd/review-context.json
**Context**: The agent needs to pass structured context data to the CRPG.
**Decision**: Write a JSON file to `~/.shepherd/review-context.json`, read by the CRPG via `GET /api/review-context`.
**Alternatives considered**: URL query parameters (length limits for structured data), WebSocket/SSE (adds real-time infrastructure for a one-shot data transfer), embedding context in the launch script arguments (too large for command-line arguments).
**Rationale**: Consistent with the existing `prompt-output.md` file-based handoff pattern. Avoids URL length limits. The JSON structure preserves the neutral/review distinction and per-file keying.
**Consequences**: The agent writes the JSON file before invoking the launcher script. The CRPG reads it on startup via the file-serving API. The file is cleaned up after reading. The JSON schema must be documented in the engineering spec.
**Slug references**: `FR-sr-context-handoff`, `FR-crp-review-context-receive`
## 2026-02-23 -- Remove confirmation prompt before CRPG launch
**Context**: The current flow asks "Ready to start? Say 'go' to begin" before opening the CRPG.
**Decision**: Remove the confirmation prompt entirely. Auto-open the CRPG immediately after changeset analysis.
**Alternatives considered**: Keep the confirmation (provides a pause point), replace with a countdown timer (still adds delay).
**Rationale**: The user invoked `/shepherd-review`, so intent to review is established. The confirmation step adds a round-trip interaction with no value. Getting the user into the CRPG faster is strictly better.
**Consequences**: The command flow goes directly from changeset overview to CRPG launch. One fewer user interaction step. The agent no longer needs to parse user confirmation input.
**Slug references**: `AC-sr-auto-open`, `FR-sr-iteration-loop`
## 2026-02-23 -- Visual distinction: blue for neutral context, violet for review feedback
**Context**: The two types of context content need to be visually distinguishable.
**Decision**: Use blue tones (left border, icon) for neutral context ("What Changed") and violet tones (left border, background tint, icon) for review feedback ("Agent Review").
**Alternatives considered**: Single color with different icons only (weaker distinction), cards with different backgrounds only (insufficient for colorblind users), collapsible sections without color (relies entirely on labels).
**Rationale**: Color differentiation plus label differentiation plus icon differentiation provides a 4-layer visual distinction that works for colorblind users (via label and icon) and sighted users (via color). Blue and violet are thematically appropriate — blue for informational/factual, violet for AI-generated/subjective.
**Consequences**: The design system gains two new color token sets (neutral-context and review-feedback). Both light and dark mode need appropriate tones. The distinction must be documented in the glossary.
**Slug references**: `AC-crp-context-neutral-vs-review`, `FR-crp-review-context-display`

## 2026-02-23 -- Reviewed status tracked as a Set<string> in Zustand store
**Context**: The file review tracking feature (`FR-crp-file-reviewed-toggle`) needs to track which files are marked as reviewed. Need a data structure for O(1) lookups when rendering tabs and the progress indicator.
**Decision**: Use `reviewedFiles: Set<string>` in the Zustand AppState, storing file IDs.
**Alternatives considered**: A `reviewed: boolean` flag on each `FileInfo` object (natural but requires iterating all files for counts and grouping), a separate `Record<string, boolean>` map (equivalent to Set but more verbose).
**Rationale**: Set provides O(1) `has()` for per-tab rendering, O(1) `add()`/`delete()` for toggling, and `.size` for the progress count. Keeps the reviewed concern orthogonal to `FileInfo`, so file data and review status are independently mutable. Zustand handles Set serialization internally.
**Consequences**: `groupedFileOrder` derived selector iterates `fileOrder` and partitions by Set membership. `clearSession` resets to empty Set. `removeFile` deletes from Set.
**Slug references**: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-persistence`
## 2026-02-23 -- ReviewStatusBar as primary toggle, tab button as secondary
**Context**: Users need a way to mark files as reviewed (`FR-crp-file-reviewed-toggle`). Multiple affordances were considered for the toggle action.
**Decision**: Three toggle mechanisms: (1) ReviewStatusBar (checkbox bar below context panel, primary), (2) review toggle icon button on each tab in FileTabBar (secondary, works without switching files), (3) keyboard shortcut `Cmd+Shift+R` / `Ctrl+Shift+R`.
**Alternatives considered**: A single toolbar button (too far from context), only a tab-level toggle (too small and easy to miss), auto-marking on tab switch (violates the "manual-only" requirement).
**Rationale**: The ReviewStatusBar is always visible when viewing a file and provides a large click target with clear state feedback. The tab button enables marking files as reviewed without switching to them (useful for skimming). The keyboard shortcut supports power users. All three trigger the same `toggleFileReviewed(fileId)` store action.
**Consequences**: ReviewStatusBar is a new component positioned in the CodeViewerPanel. FileTabBar gains a review toggle icon per tab.
**Slug references**: `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`
## 2026-02-23 -- Tab grouping uses "To Review" first, "Reviewed" second
**Context**: File review tracking groups tabs by status (`FR-crp-file-reviewed-grouping`). Need to decide the visual ordering of groups.
**Decision**: Unreviewed ("To Review") group appears first (left), reviewed group appears second (right). Within each group, files maintain original load order.
**Alternatives considered**: Reviewed first (de-emphasizes remaining work), interleaved with visual markers only (harder to scan), user-configurable ordering (over-engineering for v1).
**Rationale**: Putting unreviewed files first keeps the "work remaining" prominent. The user's natural left-to-right reading order aligns with the workflow: work through files left to right, marking each as reviewed, until all tabs shift to the "Reviewed" group. Group labels and a divider provide clear visual separation.
**Consequences**: `groupedFileOrder` derived selector returns `{ toReview: string[], reviewed: string[] }`. FileTabBar renders groups with inline labels ("TO REVIEW" / "REVIEWED") and a vertical divider. Animated transitions move tabs between groups.
**Slug references**: `FR-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-grouping`

## 2026-02-23 -- Replace horizontal FileTabBar with vertical FileBrowser sidebar
**Context**: The CRPG's multi-file navigation used a horizontal tab bar (FileTabBar) above the code viewer. With many files, file names were truncated to ~20 characters in 120-200px tabs, making it hard to identify files. The reviewed/unreviewed file grouping was cramped in a horizontal layout.
**Decision**: Replace the FileTabBar with a FileBrowser sidebar panel -- a 240px fixed-width vertical file list on the left side of the layout. This creates a 3-column layout (FileBrowser | Code Viewer | Prompt Sidebar) instead of the previous 2-column layout with a tab bar above.
**Alternatives considered**: Keep the horizontal tab bar and increase tab width (truncation still occurs with many files), collapsible left sidebar that overlays the code viewer (obscures content), dropdown file selector (poor visibility of all files at once).
**Rationale**: File names have significantly more display space (~25-30 chars vs ~20 chars). Vertical list scales naturally to many files (10+) without horizontal scrolling. Reviewed/unreviewed grouping is more natural in a vertical list with section headers. Review progress indicator moves from the toolbar to the sidebar header, co-located with the file list. The 3-column layout still fits within the 1024px minimum viewport requirement (240 + code viewer + 360 = 600px for fixed panels, leaving 424px+ for code).
**Consequences**: Code viewer panel loses 240px of horizontal width in multi-file mode. At narrower viewports (1024-1279px), the right sidebar narrows to 280px to compensate. ARIA roles change from tablist/tab to listbox/option (different semantic model). Supersedes DEC-multi-file-tab-bar.
**Slug references**: `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-toggle`, `NFR-crp-responsive-layout`

## 2026-02-24 -- Nested directory tree layout for FileBrowser sidebar
**Context**: The FileBrowser sidebar needed to display file paths to help users identify files, especially when multiple files share the same name (e.g., `helpers.ts` in different directories). An initial design used a two-line row layout (filename on line 1, directory path on line 2). During review, the user found the two-line approach odd and requested a GitHub-style nested directory tree instead.
**Decision**: The FileBrowser sidebar uses a nested directory tree structure, similar to GitHub's pull request file browser. Files are organized under collapsible directory nodes that show the full hierarchy. Directory nodes (28px) have chevron toggles for collapse/expand. File nodes (32px, single-line) are leaves indented under their parent directories at 16px per nesting level. Within each directory, unreviewed files sort before reviewed files. The previous "To Review" / "Reviewed" group headers are removed — review status is shown through per-file visual indicators (checkmarks, muted text) at each file's tree position.
**Alternatives considered**: (a) Two-line file rows with directory path below filename (initially implemented, rejected by user as "odd"), (b) full path as a single line (truncates badly), (c) path prefix before filename (wastes horizontal space), (d) only showing paths when names are ambiguous (adds complexity).
**Rationale**: The tree structure is a familiar pattern from GitHub, VS Code, and other developer tools. It naturally shows where files are without needing a separate "directory path" text field. Collapsible directories help manage large changesets. The tree replaces the flat-list grouping model with a spatial hierarchy that is more intuitive for navigating a codebase.
**Consequences**: The FileBrowser component becomes more complex (tree rendering, collapse state management, deeper keyboard navigation). ARIA changes from `role="listbox"` to `role="tree"`. The "To Review" / "Reviewed" group headers are removed in favor of within-directory ordering. A new `buildFileTree` utility and `collapsedDirs` store state are needed. The `FR-crp-file-reviewed-grouping` requirement was updated to describe within-directory ordering instead of separate group sections.
**Slug references**: `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-grouping`, `AC-crp-file-path-display`, `AC-crp-file-path-single-dir`

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
