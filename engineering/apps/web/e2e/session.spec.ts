// Covers: TC-crp-clear-confirmation-confirm-clears
import { test, expect } from '@playwright/test';
import { loadFileViaPaste } from './helpers';

test.describe('Session Management', () => {
  test('clear session with comments shows confirmation then resets', async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, 'some code content\nline two');

    // Add a comment so the session has data to confirm clearing
    await page.getByRole('rowheader', { name: 'Line 1 gutter' }).click();
    await page.getByPlaceholder('Add your comment...').fill('A comment');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(page.getByText('A comment')).toBeVisible();

    // Click the Clear button in the toolbar
    await page.getByRole('toolbar').getByRole('button', { name: 'Clear' }).click();

    // A confirmation dialog should appear since we have comments
    await expect(page.getByText('Clear session?')).toBeVisible();

    // Click "Clear" in the dialog to confirm
    await page.getByRole('button', { name: 'Clear' }).last().click();

    // Should return to empty state with the file drop zone
    await expect(page.getByRole('button', { name: 'Paste code' })).toBeVisible({ timeout: 5000 });
  });
});
