/**
 * Captures demo screenshots of the CRPG web app for the README.
 *
 * Usage:
 *   npx playwright test --config scripts/capture-demos.config.ts
 *
 * Or via the /readme slash command.
 *
 * Outputs screenshots to docs/demos/.
 */
import { test, expect } from '@playwright/test';
import * as path from 'path';

const DEMOS_DIR = path.resolve(__dirname, '../docs/demos');

test.describe('README Demo Screenshots', () => {
  test('01 - Empty state', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByText('Drop a file here to get started')).toBeVisible();
    await page.screenshot({ path: path.join(DEMOS_DIR, '01-empty-state.png'), fullPage: false });
  });

  test('02 - File loaded with syntax highlighting', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Paste code' }).click();
    await page.getByPlaceholder('Paste your code here...').fill(
`import { useState } from 'react';

interface Props {
  name: string;
  count?: number;
}

export function Greeting({ name, count = 0 }: Props) {
  const [clicks, setClicks] = useState(count);

  return (
    <div className="greeting">
      <h1>Hello, {name}!</h1>
      <p>You clicked {clicks} times</p>
      <button onClick={() => setClicks(c => c + 1)}>
        Click me
      </button>
    </div>
  );
}`
    );
    await page.getByRole('button', { name: 'Load Code' }).click();
    await expect(page.getByRole('grid', { name: 'Code viewer' })).toBeVisible();
    // Wait for syntax highlighting to load
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(DEMOS_DIR, '02-file-loaded.png'), fullPage: false });
  });

  test('03 - File with comments', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Paste code' }).click();
    await page.getByPlaceholder('Paste your code here...').fill(
`import { useState } from 'react';

interface Props {
  name: string;
  count?: number;
}

export function Greeting({ name, count = 0 }: Props) {
  const [clicks, setClicks] = useState(count);

  return (
    <div className="greeting">
      <h1>Hello, {name}!</h1>
      <p>You clicked {clicks} times</p>
      <button onClick={() => setClicks(c => c + 1)}>
        Click me
      </button>
    </div>
  );
}`
    );
    await page.getByRole('button', { name: 'Load Code' }).click();
    await expect(page.getByRole('grid', { name: 'Code viewer' })).toBeVisible();
    await page.waitForTimeout(500);

    // Add a comment on line 3
    await page.getByRole('rowheader', { name: 'Line 3 gutter' }).click();
    await page.getByPlaceholder('Add your comment...').fill('Consider making this a generic type parameter instead of a concrete interface');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(page.getByText('Consider making this')).toBeVisible();

    // Add a comment on line 10
    await page.getByRole('rowheader', { name: 'Line 10 gutter' }).click();
    await page.getByPlaceholder('Add your comment...').fill('The initial state should come from props, not be hardcoded');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(page.getByText('The initial state')).toBeVisible();

    await page.screenshot({ path: path.join(DEMOS_DIR, '03-with-comments.png'), fullPage: false });
  });

  test('04 - Generated prompt', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Paste code' }).click();
    await page.getByPlaceholder('Paste your code here...').fill(
`export function add(a: number, b: number) {
  return a + b;
}

export function multiply(a: number, b: number) {
  return a * b;
}`
    );
    await page.getByRole('button', { name: 'Load Code' }).click();
    await expect(page.getByRole('grid', { name: 'Code viewer' })).toBeVisible();
    await page.waitForTimeout(500);

    // Add a comment
    await page.getByRole('rowheader', { name: 'Line 1 gutter' }).click();
    await page.getByPlaceholder('Add your comment...').fill('Add input validation for NaN and Infinity');
    await page.getByRole('button', { name: 'Add' }).click();

    // Generate prompt
    await page.getByRole('button', { name: 'Generate' }).click();
    await expect(page.locator('pre')).toBeVisible();

    await page.screenshot({ path: path.join(DEMOS_DIR, '04-prompt-generated.png'), fullPage: false });
  });
});
