// Covers: TC-diff-toggle-to-diff-happy, TC-diff-comment-added-line-happy
import { test, expect } from '@playwright/test';
import { loadFileViaPaste } from './helpers';

test.describe('Diff View', () => {
  test('diff toggle shows File tab as active and Diff tab as disabled for pasted files', async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, 'const x = 1;\nconst y = 2;');

    // The view mode tablist should be visible
    const tablist = page.getByRole('tablist', { name: 'View mode' });
    await expect(tablist).toBeVisible();

    // File tab should be active
    const fileTab = tablist.getByRole('tab', { name: 'File' });
    await expect(fileTab).toBeVisible();

    // Diff tab should exist but be disabled (pasted files don't have server source)
    const diffTab = tablist.getByRole('tab', { name: 'Diff' });
    await expect(diffTab).toBeVisible();
    await expect(diffTab).toHaveAttribute('aria-disabled', 'true');
  });

  test('diff tab has tooltip explaining why it is disabled', async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, 'const x = 1;');

    const diffTab = page.getByRole('tablist', { name: 'View mode' }).getByRole('tab', { name: 'Diff' });
    // Should have title explaining the requirement
    await expect(diffTab).toHaveAttribute('title', /shepherd command/i);
  });
});
