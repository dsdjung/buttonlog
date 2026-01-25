import { test as base, Page, BrowserContext } from '@playwright/test';
import path from 'path';
import fs from 'fs';

/**
 * Authentication Fixtures
 *
 * This app uses OAuth-only authentication (Google).
 * Automated login is not possible without real OAuth credentials.
 *
 * ## Setting Up Authentication
 *
 * ### Single User (Basic)
 * 1. Start the backend server: cd backend && mix phx.server
 * 2. Run auth setup: npm run test:setup
 * 3. Complete Google OAuth login in the browser window
 * 4. Your session is saved automatically
 *
 * ### Multiple Users (For Friend Tests)
 * 1. Run: npm run test:setup:user1 (log in as first user)
 * 2. Run: npm run test:setup:user2 (log in as second user)
 * 3. Run: npm run test:friends (tests using both accounts)
 *
 * ## Running Authenticated Tests
 *
 * After setup, run: npm run test:auth
 *
 * ## Alternative: Using codegen
 *
 * You can also capture auth state with:
 *   npm run codegen:auth
 *
 * This opens a browser where you can log in manually.
 * The session is saved to playwright/.auth/user.json
 */

// Storage state file paths
export const AUTH_DIR = path.join(__dirname, '../../playwright/.auth');
export const AUTH_STORAGE_FILE = path.join(AUTH_DIR, 'user.json');
export const USER1_STORAGE_FILE = path.join(AUTH_DIR, 'user1.json');
export const USER2_STORAGE_FILE = path.join(AUTH_DIR, 'user2.json');

// Test user info (used for reference)
export const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
};

/**
 * Check if we have stored authentication state
 */
export async function hasStoredAuth(): Promise<boolean> {
  try {
    await fs.promises.access(AUTH_STORAGE_FILE);
    const content = await fs.promises.readFile(AUTH_STORAGE_FILE, 'utf-8');
    const state = JSON.parse(content);
    // Check if there are any cookies (basic validation)
    return state.cookies && state.cookies.length > 0;
  } catch {
    return false;
  }
}

/**
 * Get the stored auth state if it exists
 */
export async function getStoredAuthState(): Promise<object | null> {
  try {
    const content = await fs.promises.readFile(AUTH_STORAGE_FILE, 'utf-8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

/**
 * Helper to navigate to login page
 */
export async function goToLogin(page: Page) {
  await page.goto('/auth/login');
  await page.waitForLoadState('networkidle');
}

/**
 * Helper to logout
 */
export async function logout(page: Page) {
  const logoutLink = page.locator('a[href*="logout"]').or(page.locator('button:has-text("Sign Out")')).or(page.locator('button:has-text("Logout")'));

  if (await logoutLink.count() > 0) {
    await logoutLink.first().click();
    await page.waitForLoadState('networkidle');
  } else {
    // Fallback: navigate directly
    await page.goto('/auth/logout');
  }
}

/**
 * Check if the current page shows authenticated user UI
 */
export async function isAuthenticated(page: Page): Promise<boolean> {
  await page.waitForLoadState('networkidle');

  // Check for authenticated UI indicators
  const authIndicators = page.locator('a[href*="logout"]').or(page.locator('button:has-text("Sign Out")')).or(page.locator('button:has-text("Logout")')).or(page.locator('[data-user]'));

  return await authIndicators.count() > 0;
}

/**
 * Assert that the user is authenticated
 * Useful in authenticated test setup
 */
export async function assertAuthenticated(page: Page) {
  const authenticated = await isAuthenticated(page);
  if (!authenticated) {
    throw new Error(
      'User is not authenticated. Run "npm run test:setup" to set up authentication state.'
    );
  }
}

/**
 * Extended test fixture that provides an authenticated page
 * Will warn if no stored auth state exists
 */
export const authenticatedTest = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page }, use) => {
    const hasAuth = await hasStoredAuth();

    if (!hasAuth) {
      console.warn('\n');
      console.warn('='.repeat(60));
      console.warn('No stored authentication found.');
      console.warn('Run: npm run test:setup');
      console.warn('='.repeat(60));
      console.warn('\n');
    }

    await use(page);
  },
});

/**
 * Placeholder login function (for API compatibility)
 * This doesn't actually log in since the app uses OAuth
 */
export async function login(page: Page, _email?: string, _password?: string): Promise<void> {
  console.warn(
    'Warning: login() called but this app uses OAuth-only authentication. ' +
    'Use stored authentication state instead (npm run test:setup).'
  );

  await page.goto('/auth/login');
}

// ============================================================================
// Multi-User Authentication Support
// ============================================================================

/**
 * Check if a specific user's auth file exists
 */
export async function hasUserAuth(userFile: string): Promise<boolean> {
  try {
    await fs.promises.access(userFile);
    const content = await fs.promises.readFile(userFile, 'utf-8');
    const state = JSON.parse(content);
    return state.cookies && state.cookies.length > 0;
  } catch {
    return false;
  }
}

/**
 * Check if User 1 auth exists
 */
export async function hasUser1Auth(): Promise<boolean> {
  return hasUserAuth(USER1_STORAGE_FILE);
}

/**
 * Check if User 2 auth exists
 */
export async function hasUser2Auth(): Promise<boolean> {
  return hasUserAuth(USER2_STORAGE_FILE);
}

/**
 * Check if both users have auth (required for friend tests)
 */
export async function hasBothUsersAuth(): Promise<boolean> {
  const [user1, user2] = await Promise.all([hasUser1Auth(), hasUser2Auth()]);
  return user1 && user2;
}

/**
 * Get user auth state by file path
 */
export async function getUserAuthState(userFile: string): Promise<object | null> {
  try {
    const content = await fs.promises.readFile(userFile, 'utf-8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

/**
 * Extended test fixture that provides two authenticated pages for friend tests
 * User 1 and User 2 are in separate browser contexts
 */
export const multiUserTest = base.extend<{
  user1Page: Page;
  user2Page: Page;
  user1Context: BrowserContext;
  user2Context: BrowserContext;
}>({
  user1Context: async ({ browser }, use) => {
    const hasAuth = await hasUser1Auth();
    if (!hasAuth) {
      console.warn('\n');
      console.warn('='.repeat(60));
      console.warn('No User 1 authentication found.');
      console.warn('Run: npm run test:setup:user1');
      console.warn('='.repeat(60));
      console.warn('\n');
      throw new Error('User 1 auth not found. Run: npm run test:setup:user1');
    }
    const context = await browser.newContext({ storageState: USER1_STORAGE_FILE });
    await use(context);
    await context.close();
  },

  user2Context: async ({ browser }, use) => {
    const hasAuth = await hasUser2Auth();
    if (!hasAuth) {
      console.warn('\n');
      console.warn('='.repeat(60));
      console.warn('No User 2 authentication found.');
      console.warn('Run: npm run test:setup:user2');
      console.warn('='.repeat(60));
      console.warn('\n');
      throw new Error('User 2 auth not found. Run: npm run test:setup:user2');
    }
    const context = await browser.newContext({ storageState: USER2_STORAGE_FILE });
    await use(context);
    await context.close();
  },

  user1Page: async ({ user1Context }, use) => {
    const page = await user1Context.newPage();
    await use(page);
    await page.close();
  },

  user2Page: async ({ user2Context }, use) => {
    const page = await user2Context.newPage();
    await use(page);
    await page.close();
  },
});
