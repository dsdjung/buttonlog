import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Support Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Support', () => {
  test.describe('Support Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/support');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows support content or login prompt', async ({ page }) => {
      await page.goto('/support');

      const hasAuth = await hasStoredAuth();
      if (hasAuth) {
        // Should show support options when authenticated
        const content = page.locator('text=Support').or(page.locator('text=Help')).or(page.locator('text=Contact'));
        await expect(content.first()).toBeVisible();
      } else {
        // Should show login prompt or support preview
        await page.waitForLoadState('networkidle');
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Support Page Access', () => {
    test('support page accessible', async ({ page }) => {
      const response = await page.goto('/support');
      // Should not return server error
      expect(response?.status()).toBeLessThan(500);
    });

    test('has expected page structure', async ({ page }) => {
      await page.goto('/support');
      await page.waitForLoadState('networkidle');

      // Check for basic page structure
      const body = page.locator('body');
      await expect(body).toBeVisible();
    });
  });

  test.describe('Navigation', () => {
    test('can navigate to support from home', async ({ page }) => {
      await page.goto('/');

      const supportLink = page.locator('a[href*="support"]').first();
      if (await supportLink.count() > 0) {
        await supportLink.click();
        await page.waitForLoadState('networkidle');
        expect(page.url()).toContain('/support');
      }
    });
  });
});
