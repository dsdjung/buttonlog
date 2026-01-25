import { defineConfig, devices } from '@playwright/test';
import path from 'path';

/**
 * Environment configuration for ButtonLog E2E tests
 *
 * Usage:
 *   npm test                    # Run against local (default)
 *   npm run test:staging        # Run against staging
 *   npm run test:prod           # Run against production
 *   npm run test:auth           # Run only authenticated tests
 */

// Environment URLs
// NOTE: Local dev server runs on port 14015 (configured in backend/config/dev.exs)
const environments = {
  local: 'http://localhost:14015',
  staging: process.env.STAGING_URL || 'https://staging.buttonlog.com',
  production: process.env.PROD_URL || 'https://buttonlog.com',
};

// Get target environment from ENV or default to local
const targetEnv = (process.env.TEST_ENV || 'local') as keyof typeof environments;
const baseURL = environments[targetEnv];

// Auth storage file path
const authFile = path.join(__dirname, 'playwright/.auth/user.json');

export default defineConfig({
  testDir: './tests',

  // Run tests in parallel
  fullyParallel: true,

  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Opt out of parallel tests on CI
  workers: process.env.CI ? 1 : undefined,

  // Reporter to use
  reporter: [
    ['html', { open: 'never' }],
    ['list'],
  ],

  // Shared settings for all projects
  use: {
    baseURL,

    // Collect trace when retrying the failed test
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Video on failure
    video: 'on-first-retry',
  },

  // Configure projects for major browsers
  projects: [
    // Setup project - captures auth state (run manually with: npm run test:setup)
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },

    // Unauthenticated tests - run without stored auth
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      testIgnore: /.*\.auth\.spec\.ts/,
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      testIgnore: /.*\.auth\.spec\.ts/,
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
      testIgnore: /.*\.auth\.spec\.ts/,
    },

    // Authenticated tests - require stored auth state
    {
      name: 'chromium-auth',
      use: {
        ...devices['Desktop Chrome'],
        storageState: authFile,
      },
      testMatch: /.*\.auth\.spec\.ts/,
    },

    // Mobile viewports (unauthenticated)
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
      testIgnore: /.*\.auth\.spec\.ts/,
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 12'] },
      testIgnore: /.*\.auth\.spec\.ts/,
    },
  ],

  // Run local dev server before starting tests (only for local environment)
  ...(targetEnv === 'local' ? {
    webServer: {
      command: 'cd ../backend && source .env 2>/dev/null; mix phx.server',
      url: 'http://localhost:14015',
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
    },
  } : {}),
});
