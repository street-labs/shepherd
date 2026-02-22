// Covers: TC-crp-empty-state-instructions, TC-crp-load-upload-happy
import { test, expect } from '@playwright/test';
import { loadFileViaPaste, SAMPLE_TS_CONTENT } from './helpers';

test.describe('File Loading', () => {
  test('shows empty state with upload and paste buttons on initial load', async ({ page }) => {
    await page.goto('/');

    // Empty state should show the "Upload file" and "Paste code" buttons
    await expect(page.getByRole('button', { name: 'Upload file' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Paste code' })).toBeVisible();

    // Should show the instructional heading
    await expect(page.getByText('Drop a file here to get started')).toBeVisible();
  });

  test('loads a file via paste and displays content in code viewer', async ({ page }) => {
    await page.goto('/');
    await loadFileViaPaste(page, SAMPLE_TS_CONTENT);

    // The code viewer should be visible with the content
    await expect(page.getByRole('grid', { name: 'Code viewer' })).toBeVisible();
    await expect(page.getByText('function greet')).toBeVisible();
  });
});
