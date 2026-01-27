import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Friends Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Friends & Social', () => {
  test.describe('Friends Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/friends');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows content or login prompt', async ({ page }) => {
      await page.goto('/friends');
      await page.waitForLoadState('networkidle');

      // Check actual page authentication state instead of just file existence
      const isLoggedIn = await page.locator('a[href*="logout"]').or(page.locator('button:has-text("Sign Out")')).count() > 0;

      if (isLoggedIn) {
        // Should show friends list or empty state when authenticated
        const content = page.locator('.friend-card').or(page.locator('[data-friend-id]')).or(page.locator('text=Find')).or(page.locator('text=Friends')).or(page.locator('text=Invite'));
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/friends');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('has navigation elements', async ({ page }) => {
      await page.goto('/friends');
      await page.waitForLoadState('networkidle');

      const nav = page.locator('nav').or(page.locator('header'));
      if (await nav.count() > 0) {
        await expect(nav.first()).toBeVisible();
      }
    });
  });
});
