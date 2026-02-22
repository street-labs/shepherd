# Kickoff: $ARGUMENTS

The user has described what they want: **$ARGUMENTS**

Follow this sequence exactly. Steps are sequential unless noted otherwise.

---

## Step 0: Triage — Decide What's Needed

Before doing anything, analyze the request and decide:

### A) Which platform(s) are in scope?

Determine the target platform(s) for this request:
- **Single-platform (web)** — Affects only the web app. Use base spec files (no suffix).
- **Single-platform (other)** — Affects only a non-web platform. Use platform-suffixed spec files (e.g., `feature.macos.md`).
- **Cross-platform** — Affects multiple platforms. Create/update the base spec (shared behavior), then create/update platform-specific variants where behavior diverges.
- **Porting** — An existing feature being brought to a new platform. Base specs exist; create only platform-specific variants.

If the request doesn't specify a platform, ask the user. For the current project, the active platforms are listed in the "Multi-Platform Support" section of CLAUDE.md.

### B) Which existing spec does this belong to?

Read the files in `product/` (excluding CLAUDE.md) to see what specs already exist. Determine whether this request:
- **Modifies an existing feature** → Update the existing spec file(s). Do NOT create a new file.
- **Adds a genuinely new feature** → Create a new spec file only if this is truly a distinct feature that doesn't belong in any existing spec.

Specs are **living documents** that represent the product as it is (or will be). Think of each spec as the single source of truth for that feature area. Modifications, enhancements, and refinements go into the existing spec — they do not spawn new files.

When porting to a new platform, the base spec already exists — check if a platform-specific variant already exists too.

### C) Which functional areas are actually needed?

Not every request requires all four areas. Decide which are relevant:

| Request type | Product | Design | Engineering | QA |
|---|---|---|---|---|
| New user-facing feature | Yes | Yes | Yes | Yes |
| UX/UI change to existing feature | Maybe (if requirements change) | Yes | Yes | Yes |
| Technical/performance improvement | Maybe (add NFR if needed) | No (unless UX is affected) | Yes | Yes (performance tests) |
| Bug fix | No (unless requirements were wrong) | No (unless design was wrong) | Yes | Yes |
| Refactoring / tech debt | No | No | Yes | Maybe |
| Porting existing feature to new platform | Maybe (if platform-specific reqs) | Yes (if UI differs) | Yes | Yes |

**Be honest about what's needed.** A request like "make it launch faster" is primarily an engineering concern. Product might add a brief NFR ("app should launch within Xms"), but it doesn't need a design spec. Don't create artifacts just to check boxes.

Announce your triage decision to the user before proceeding:
- Which platform(s) are targeted
- Which spec file(s) will be created or updated (including platform-specific variants)
- Which functional areas will be involved and why
- Which functional areas are being skipped and why

---

## Step 1: Product Requirements

**Only if triage determined product work is needed.**

Delegate to the product agent (operating in `product/`). Be explicit about whether this is a **new spec**, an **update to an existing spec**, or a **platform-specific variant**:

- **Updating an existing spec**: Tell the agent which file to update, what sections need changes, and what to add/modify. The agent should read the existing file first and make targeted edits — not rewrite the whole file.
- **New spec**: Have it create a new PRD markdown file following the template in `product/CLAUDE.md`.
- **Platform-specific variant**: Tell the agent which base spec to reference (e.g., `product/code-review-prompt.md`) and have it create a `<feature>.<platform>.md` file that covers only platform-specific requirements and divergences. The variant must reference the base spec and not duplicate shared requirements.

For cross-platform work, always do the base spec first, then platform variants.

Ensure all requirement slugs follow the format: `FR-<feature>-<slug>`, `NFR-<feature>-<slug>`, `AC-<feature>-<slug>`

Before moving on, read back the product spec and verify it's complete. If the user's description was vague, the product agent should list open questions — present those to the user and resolve them before continuing.

**Do not proceed to Step 2 until this step is fully complete and verified.**

---

## Step 2: Design Spec

**Only if triage determined design work is needed. Wait for Step 1 to complete first.**

Read the product spec from Step 1 (or the existing product spec if Step 1 was skipped). Delegate to the design agent (operating in `design/`):

- **Updating an existing spec**: Tell the agent which file to update and what changed in the product spec. The agent should make targeted updates — not rewrite.
- **New spec**: Have it create a design spec following `design/CLAUDE.md`.
- **Platform-specific variant**: Tell the agent which base design spec to reference and have it create a `<feature>.<platform>.md` file. The variant covers platform-specific UI/UX (e.g., native controls, platform conventions) and references the base spec for shared behavior.

For cross-platform work, do the base design spec first, then platform variants.

The design spec must address every requirement and user story. Reference specific requirement slugs.

**Do not proceed to Step 3 until this step is fully complete.**

---

## Step 3: Engineering Spec + QA Test Plan (parallel)

**Wait for Step 2 to complete first (or Step 1 if design was skipped).**

These two can run **in parallel** because both depend on the same upstream inputs (product spec + design spec) and neither depends on the other at the spec level.

### Engineering Spec

Read the product spec and design spec (whichever exist). Delegate to the engineering agent (operating in `engineering/`):

- **Updating an existing spec**: Tell the agent which file to update, what changed upstream, and what technical approach needs revisiting.
- **New spec**: Have it create a technical spec following `engineering/CLAUDE.md`.
- **Platform-specific variant**: Tell the agent which base engineering spec to reference and have it create a `<feature>.<platform>.md` file. The variant covers platform-specific architecture (e.g., SwiftUI vs React, native APIs vs web APIs) and references the base spec for shared patterns.

Do NOT write code at this stage — only the technical spec.

### QA Test Plan

**Only if triage determined QA work is needed.**

Read the product spec and design spec. Delegate to the QA agent (operating in `qa/`):

- **Updating an existing test plan**: Tell the agent which file to update, what changed, and which test cases need adding/modifying.
- **New test plan**: Have it create a test plan following `qa/CLAUDE.md`.
- **Platform-specific variant**: Tell the agent which base test plan to reference and have it create a `<feature>.<platform>.md` file. The variant covers platform-specific test cases (e.g., XCTest instead of Playwright, native UI testing) and references the base plan for shared test logic.

Test cases must cover every acceptance criterion. Reference specific slugs.

**Note:** When it later comes time to *implement* (write actual code and tests), that must be sequential — engineering implements first, then QA writes/runs tests against the implementation. But at the spec-writing stage, they can work simultaneously. For cross-platform work, platform-specific engineering and QA variants can also be written in parallel.

---

## Step 4: Update Traceability Index

Update `index.md` at the project root. For any new slugs, add entries linking to all referencing files. For modified slugs, update the references.

## Step 5: Update Glossary

Review the artifacts created or modified. If any new domain terms were introduced, add them to `glossary.md`.

## Step 6: Log Decisions

If any significant decisions were made during this kickoff (technology choices, scope decisions, design patterns), append them to `decisions-pending.md` (not `decisions.md` directly — the pre-commit hook merges pending entries at commit time).

## Step 7: Review

Run the reviewer pass: read all artifacts that were created or modified and check for gaps, inconsistencies, or mismatches between them. Report any issues found.

Run the consistency pass: check that terminology is consistent across all artifacts and matches `glossary.md`.

Run `./scripts/audit-traceability.sh` to verify the index is correct.

Present a summary to the user:
- What was **created** (new files)
- What was **updated** (existing files, with a summary of changes)
- What was **skipped** and why
- Any issues found during review
