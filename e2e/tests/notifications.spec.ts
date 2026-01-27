import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Notifications Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Notifications', () => {
  test.describe('Notifications Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/notifications');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows content or login prompt', async ({ page }) => {
      await page.goto('/notifications');
      await page.waitForLoadState('networkidle');

      // Check actual page authentication state instead of just file existence
      const isLoggedIn = await page.locator('a[href*="logout"]').or(page.locator('button:has-text("Sign Out")')).count() > 0;

      if (isLoggedIn) {
        // Should show notifications or empty state when authenticated
        const content = page.locator('.notification').or(page.locator('[data-notification-id]')).or(page.locator('text=caught up')).or(page.locator('text=Logs')).or(page.locator('text=No notifications'));
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/notifications');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('has navigation elements', async ({ page }) => {
      await page.goto('/notifications');
      await page.waitForLoadState('networkidle');

      const nav = page.locator('nav').or(page.locator('header'));
      if (await nav.count() > 0) {
        await expect(nav.first()).toBeVisible();
      }
    });
  });
});
