# Kickoff: $ARGUMENTS

You are kicking off a new feature. The user has described what they want as: **$ARGUMENTS**

Follow this sequence exactly. Each step depends on the previous one.

## Step 1: Product Requirements

Delegate to the product agent (operating in `product/`). Have it create a PRD markdown file for this feature based on the user's description. The file should follow the template in `product/CLAUDE.md`.

Ensure all requirement slugs follow the format: `FR-<feature>-<slug>`, `NFR-<feature>-<slug>`, `AC-<feature>-<slug>`

Before moving on, read back the product spec and verify it's complete. If the user's description was vague, the product agent should list open questions — present those to the user and resolve them before continuing.

## Step 2: Design Spec

Read the product spec created in Step 1. Delegate to the design agent (operating in `design/`) to create a design spec that addresses every requirement and user story. The file should follow the template in `design/CLAUDE.md` and reference specific requirement slugs.

## Step 3: Engineering Spec

Read both the product spec and design spec. Delegate to the engineering agent (operating in `engineering/`) to create a technical spec. The file should follow the template in `engineering/CLAUDE.md` and reference specific requirement slugs and design components.

Do NOT write code at this stage — only the technical spec.

## Step 4: QA Test Plan

Read the product spec, design spec, and engineering spec. Delegate to the QA agent (operating in `qa/`) to create a test plan with test cases covering every acceptance criterion. The file should follow the template in `qa/CLAUDE.md` and reference specific slugs.

## Step 5: Update Traceability Index

Update `index.md` at the project root. Add an entry for every slug defined in the product spec, linking to where it's referenced in design, engineering, and QA specs.

## Step 6: Update Glossary

Review the artifacts created. If any new domain terms were introduced, add them to `glossary.md`.

## Step 7: Log Decisions

If any significant decisions were made during this kickoff (technology choices, scope decisions, design patterns), append them to `decisions.md`.

## Step 8: Review

Run the reviewer pass: read all four artifacts together and check for gaps, inconsistencies, or mismatches between them. Report any issues found.

Run the consistency pass: check that terminology is consistent across all four artifacts and matches `glossary.md`.

Run `./scripts/audit-traceability.sh` to verify the index is correct.

Present a summary to the user of what was created.
