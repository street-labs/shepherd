// Covers: TC-crp-generate-prompt-structure-happy, TC-crp-copy-clipboard-happy
import { test, expect } from '@playwright/test';
import { loadFileViaPaste } from './helpers';

test.describe('Prompt Generation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, 'function hello() {\n  return "world";\n}');

    // Add a comment so Generate is enabled
    await page.getByRole('rowheader', { name: 'Line 1 gutter' }).click();
    await page.getByPlaceholder('Add your comment...').fill('Review this function');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(page.getByText('Review this function')).toBeVisible();
  });

  test('generates a prompt and shows it in the preview', async ({ page }) => {
    await page.getByRole('button', { name: 'Generate' }).click();

    // The preview area should show the generated prompt
    const preview = page.locator('pre');
    await expect(preview).toBeVisible({ timeout: 5000 });
    await expect(preview).toContainText('Review this function');
  });

  test('copy button is available after generating prompt', async ({ page }) => {
    await page.getByRole('button', { name: 'Generate' }).click();

    // Wait for prompt to appear
    await expect(page.locator('pre')).toBeVisible({ timeout: 5000 });

    // The toolbar Copy button should now be enabled
    const copyButton = page.getByRole('toolbar').getByRole('button', { name: 'Copy' });
    await expect(copyButton).toBeEnabled();
  });
});
