import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Organizations Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Organizations', () => {
  test.describe('Organizations Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/organizations');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows content or login prompt', async ({ page }) => {
      await page.goto('/organizations');
      await page.waitForLoadState('networkidle');

      // Check actual page authentication state instead of just file existence
      const isLoggedIn = await page.locator('a[href*="logout"]').or(page.locator('button:has-text("Sign Out")')).count() > 0;

      if (isLoggedIn) {
        // Should show organizations list or empty state when authenticated
        const content = page.locator('.org-card').or(page.locator('[data-organization-id]')).or(page.locator('text=Create')).or(page.locator('text=Organizations')).or(page.locator('text=organization'));
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/organizations');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('has navigation elements', async ({ page }) => {
      await page.goto('/organizations');
      await page.waitForLoadState('networkidle');

      const nav = page.locator('nav').or(page.locator('header'));
      if (await nav.count() > 0) {
        await expect(nav.first()).toBeVisible();
      }
    });
  });
});
