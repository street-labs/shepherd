// Covers: TC-crp-binary-file-rejected-upload
import { test, expect } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

test.describe('Error Handling', () => {
  test('rejects binary file upload', async ({ page }) => {
    await page.goto('/');

    // Create a temporary binary file
    const tmpDir = os.tmpdir();
    const binaryPath = path.join(tmpDir, 'test-binary.bin');
    const binaryContent = Buffer.from([0x00, 0x01, 0x02, 0x03, 0x48, 0x65, 0x6c, 0x6c, 0x6f]);
    fs.writeFileSync(binaryPath, binaryContent);

    try {
      // Find the hidden file input and upload the binary file
      const fileInput = page.locator('input[type="file"]');
      await fileInput.setInputFiles(binaryPath);

      // Should show an error about binary files
      await expect(page.getByText(/binary|cannot.*open|unsupported/i)).toBeVisible({ timeout: 5000 });

      // The code viewer should NOT appear
      await expect(page.getByRole('grid', { name: 'Code viewer' })).not.toBeVisible();
    } finally {
      fs.unlinkSync(binaryPath);
    }
  });
});
