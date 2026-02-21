# Decision Log

Append-only record of key decisions made during this project. Newest entries at the bottom.

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
