import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';

export default defineConfig({
  testDir: path.resolve(__dirname),
  testMatch: 'capture-demos.ts',
  fullyParallel: false,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:5173',
    viewport: { width: 1280, height: 720 },
    colorScheme: 'light',
  },
  projects: [
    {
      name: 'screenshots',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    cwd: path.resolve(__dirname, '../engineering/apps/web'),
    reuseExistingServer: true,
  },
});
