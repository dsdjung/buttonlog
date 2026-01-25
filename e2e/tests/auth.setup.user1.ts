import { test as setup, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';

const authDir = path.join(__dirname, '../playwright/.auth');
const authFile = path.join(authDir, 'user1.json');

/**
 * Authentication Setup - User 1
 *
 * This test opens a browser for you to manually log in via Google OAuth.
 * After you complete the login, it saves your session as User 1.
 *
 * Run with: npm run test:setup:user1
 *
 * Note: This is one of two users needed for friend relationship testing.
 * After setting up both users, run: npm run test:friends
 */
setup('authenticate User 1 via Google OAuth', async ({ page }) => {
  // Ensure auth directory exists
  await fs.promises.mkdir(authDir, { recursive: true });

  // Navigate to login page
  await page.goto('/auth/login');

  // Wait for user to see the login page
  await expect(page.locator('text=Sign in')).toBeVisible();

  console.log('\n');
  console.log('='.repeat(60));
  console.log('USER 1 LOGIN REQUIRED');
  console.log('='.repeat(60));
  console.log('\n');
  console.log('This is User 1 - the first test account.');
  console.log('Use a DIFFERENT Google account than User 2!');
  console.log('\n');
  console.log('1. Click "Sign in with Google" in the browser window');
  console.log('2. Complete the Google OAuth login flow');
  console.log('3. Wait until you see the main app (buttons page)');
  console.log('4. The test will automatically save your session');
  console.log('\n');
  console.log('You have 5 minutes to complete the login...');
  console.log('='.repeat(60));
  console.log('\n');

  // Wait for user to complete OAuth login (up to 5 minutes)
  // The test waits until we're back on the app domain and not on auth pages
  await page.waitForURL((url) => {
    // Must be on our app domain (not Google's OAuth page)
    const isAppDomain = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    const path = url.pathname;
    const isNotAuthPage = !path.includes('/auth/');
    const isNotRoot = path !== '/';
    return isAppDomain && isNotAuthPage && isNotRoot;
  }, { timeout: 300000 });

  // Verify we're logged in by checking for authenticated UI elements
  // Wait for the page to settle
  await page.waitForLoadState('networkidle');

  // Check for signs of authentication (adjust selectors based on your app)
  const isAuthenticated = await page.locator('a[href*="logout"], button:has-text("Sign Out"), [data-user]').count() > 0;

  if (isAuthenticated) {
    console.log('\n');
    console.log('='.repeat(60));
    console.log('SUCCESS! User 1 authentication captured.');
    console.log('='.repeat(60));
    console.log('\n');
    console.log(`Session saved to: ${authFile}`);
    console.log('\n');
    console.log('Next steps:');
    console.log('  1. Run: npm run test:setup:user2 (to set up User 2)');
    console.log('  2. Run: npm run test:friends (to run friend tests)');
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
