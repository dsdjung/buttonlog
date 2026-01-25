import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../playwright/.auth/user.json');

/**
 * Authentication Setup
 *
 * This test opens a browser for you to manually log in via Google OAuth.
 * After you complete the login, it saves your session to be used by
 * authenticated tests.
 *
 * Run with: npm run test:setup
 *
 * Note: This test is designed to be run interactively (headed mode).
 * It will pause to let you complete the OAuth flow manually.
 */
setup('authenticate via Google OAuth', async ({ page }) => {
  // Navigate to login page
  await page.goto('/auth/login');

  // Wait for user to see the login page
  await expect(page.locator('text=Sign in')).toBeVisible();

  console.log('\n');
  console.log('='.repeat(60));
  console.log('MANUAL LOGIN REQUIRED');
  console.log('='.repeat(60));
  console.log('\n');
  console.log('1. Click "Sign in with Google" in the browser window');
  console.log('2. Complete the Google OAuth login flow');
  console.log('3. Wait until you see the main app (buttons page)');
  console.log('4. The test will automatically save your session');
  console.log('\n');
  console.log('You have 2 minutes to complete the login...');
  console.log('='.repeat(60));
  console.log('\n');

  // Wait for user to complete OAuth login (up to 2 minutes)
  // The test waits until we're redirected away from auth pages
  await page.waitForURL((url) => {
    const path = url.pathname;
    return !path.includes('/auth/') && path !== '/';
  }, { timeout: 120000 });

  // Verify we're logged in by checking for authenticated UI elements
  // Wait for the page to settle
  await page.waitForLoadState('networkidle');

  // Check for signs of authentication (adjust selectors based on your app)
  const isAuthenticated = await page.locator('a[href*="logout"], button:has-text("Sign Out"), [data-user]').count() > 0;

  if (isAuthenticated) {
    console.log('\n');
    console.log('='.repeat(60));
    console.log('SUCCESS! Authentication captured.');
    console.log('='.repeat(60));
    console.log('\n');
    console.log(`Session saved to: ${authFile}`);
    console.log('\n');
    console.log('You can now run authenticated tests with:');
    console.log('  npm run test:auth');
    console.log('\n');
  } else {
    console.log('\n');
    console.log('='.repeat(60));
    console.log('WARNING: Could not verify authentication.');
    console.log('='.repeat(60));
    console.log('\n');
    console.log('The session will be saved, but tests may fail if login was incomplete.');
    console.log('\n');
  }

  // Save the authentication state
  await page.context().storageState({ path: authFile });
});
