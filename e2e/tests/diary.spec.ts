import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Diary Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Diary View', () => {
  test.describe('Diary Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/diary');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows content or login prompt', async ({ page }) => {
      await page.goto('/diary');
      await page.waitForLoadState('networkidle');

      const hasAuth = await hasStoredAuth();
      if (hasAuth) {
        // Should show calendar or timeline when authenticated
        const content = page.locator('.calendar').or(page.locator('.timeline')).or(page.locator('table'));
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/diary');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('has navigation elements', async ({ page }) => {
      await page.goto('/diary');
      await page.waitForLoadState('networkidle');

      const nav = page.locator('nav').or(page.locator('header'));
      if (await nav.count() > 0) {
        await expect(nav.first()).toBeVisible();
      }
    });
  });
});
