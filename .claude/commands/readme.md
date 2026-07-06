Regenerate the project README with fresh demo screenshots.

Do the following steps in order:

1. **Capture demo screenshots** using Playwright:
   ```bash
   cd engineering/apps/web && npx playwright test --config ../../../scripts/capture-demos.config.ts
   ```
   This saves screenshots to `docs/demos/`. If the dev server isn't running, Playwright will start it automatically.

2. **Regenerate README.md** from project specs:
   ```bash
   ./scripts/generate-readme.sh
   ```
   This reads the current specs, test counts, and available screenshots, then writes README.md only if the content has actually changed.

3. **Report what changed**:
   - If screenshots were updated, list which ones
   - If README.md was updated, show a brief diff summary
   - If nothing changed, say "README is already up to date"

Do NOT commit automatically. Just prepare the files and let the user decide when to commit.
