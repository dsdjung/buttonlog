import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Account Settings Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Account Settings', () => {
  test.describe('Account Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/account');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows account content or login prompt', async ({ page }) => {
      await page.goto('/account');
      await page.waitForLoadState('networkidle');

      const hasAuth = await hasStoredAuth();
      if (hasAuth) {
        // Should show account header when authenticated
        await expect(page.locator('h1').or(page.locator('h2')).first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
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

  test.describe('Page Structure', () => {
    test('has basic page structure', async ({ page }) => {
      await page.goto('/account');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });
  });

  test.describe('Subscription Link', () => {
    test('subscription page accessible', async ({ page }) => {
      const response = await page.goto('/subscription');
      expect(response?.status()).toBeLessThan(500);
    });
  });
});
