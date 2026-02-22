// Covers: TC-crp-add-comment-single-line-happy
import { test, expect } from '@playwright/test';
import { loadFileViaPaste } from './helpers';

test.describe('Comments', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, 'line one\nline two\nline three\nline four\nline five');
  });

  test('adds a single-line comment via gutter click', async ({ page }) => {
    // Click the gutter for line 1 to open the editor
    const gutter = page.getByRole('rowheader', { name: 'Line 1 gutter' });
    await gutter.click();

    // The inline editor textarea should appear
    const commentInput = page.getByPlaceholder('Add your comment...');
    await expect(commentInput).toBeVisible();
    await commentInput.fill('This needs a fix');

    // Click "Add" to save the comment
    await page.getByRole('button', { name: 'Add' }).click();

    // Comment bubble should appear with the text
    await expect(page.getByText('This needs a fix')).toBeVisible();

    // Comment count in the toolbar should show 1
    await expect(page.getByText('1', { exact: true }).locator('visible=true')).toBeVisible();
  });
});
