import { Page, expect } from '@playwright/test';

/**
 * Loads a test file into the CRPG by using the Paste code flow.
 * Clicks "Paste code" -> fills textarea -> clicks "Load Code".
 */
export async function loadFileViaPaste(page: Page, content: string) {
  // Click "Paste code" to enter paste mode
  await page.getByRole('button', { name: 'Paste code' }).click();

  // Fill the textarea
  await page.getByPlaceholder('Paste your code here...').fill(content);

  // Click "Load Code"
  await page.getByRole('button', { name: 'Load Code' }).click();

  // Wait for the code viewer to appear
  await expect(page.getByRole('grid', { name: 'Code viewer' })).toBeVisible({ timeout: 10000 });
}

/**
 * Sample TypeScript content for testing.
 */
export const SAMPLE_TS_CONTENT = `function greet(name: string): string {
  return \`Hello, \${name}!\`;
}

export function add(a: number, b: number): number {
  return a + b;
}

const result = add(1, 2);
console.log(greet("World"));
`;
