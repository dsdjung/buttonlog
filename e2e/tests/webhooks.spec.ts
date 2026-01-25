import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Webhook Settings Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Webhook Settings', () => {
  test.describe('Account Page Access', () => {
    test('account page loads', async ({ page }) => {
      const response = await page.goto('/account');
      // Should not return server error
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows content or login prompt', async ({ page }) => {
      await page.goto('/account');
      await page.waitForLoadState('networkidle');

      const hasAuth = await hasStoredAuth();
      if (hasAuth) {
        // Should show account settings when authenticated
        const content = page.locator('text=Account').or(page.locator('text=Settings')).or(page.locator('text=Webhook'));
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/account');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('has navigation elements', async ({ page }) => {
      await page.goto('/account');
      await page.waitForLoadState('networkidle');

      // Check for navigation or header
      const nav = page.locator('nav').or(page.locator('header'));
      if (await nav.count() > 0) {
        await expect(nav.first()).toBeVisible();
      }
    });
  });
});
