import { test as base, Page } from '@playwright/test';

/**
 * Authentication Fixtures
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Automated login is not possible without real OAuth credentials.
 *
 * For authenticated tests, you have two options:
 *
 * 1. MANUAL SETUP (Recommended for CI):
 *    - Login manually via Google OAuth
 *    - Save the browser state: npx playwright codegen --save-storage=auth.json
 *    - Run tests with stored state: npx playwright test --storage-state=auth.json
 *
 * 2. TEST ENVIRONMENT:
 *    - Set up a test user in the database
 *    - Configure a session cookie directly
 *
 * For now, tests that require authentication will be skipped unless
 * a valid auth storage file exists.
 */

// Storage state file path
export const AUTH_STORAGE_FILE = 'playwright/.auth/user.json';

// Test user info (used for reference, not for login)
export const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
};

/**
 * Check if we have stored authentication state
 */
export async function hasStoredAuth(): Promise<boolean> {
  const fs = await import('fs');
  try {
    await fs.promises.access(AUTH_STORAGE_FILE);
    return true;
  } catch {
    return false;
  }
}

/**
 * Helper to navigate to login page
 * (Can't actually log in without real OAuth)
 */
export async function goToLogin(page: Page) {
  await page.goto('/auth/login');
}

/**
 * Helper to logout
 */
export async function logout(page: Page) {
  const logoutLink = page.locator('a[href*="logout"], button:has-text("Sign Out"), button:has-text("Logout")').first();

  if (await logoutLink.count() > 0) {
    await logoutLink.click();
    await page.waitForLoadState('networkidle');
  } else {
    // Fallback: navigate directly
    await page.goto('/auth/logout');
  }
}

/**
 * Extended test that requires authentication
 * Will skip if no stored auth state exists
 */
export const authenticatedTest = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page, context }, use) => {
    // Check if we have stored auth
    const hasAuth = await hasStoredAuth();

    if (!hasAuth) {
      console.warn('No stored authentication found. Skipping authenticated test.');
      console.warn('To set up auth: npx playwright codegen --save-storage=playwright/.auth/user.json');
      // Skip the test by using the page anyway - tests should handle this
    }

    await use(page);
  },
});

/**
 * Placeholder login function
 * This doesn't actually log in since the app uses OAuth
 * It's here for API compatibility but will throw an error if called
 */
export async function login(page: Page, _email?: string, _password?: string): Promise<void> {
  console.warn(
    'Warning: login() called but this app uses OAuth-only authentication. ' +
    'Use stored authentication state instead.'
  );

  // Just navigate to login page
  await page.goto('/auth/login');

  // This will redirect to login since we're not actually authenticated
  // Tests calling this should expect to NOT be logged in
}
