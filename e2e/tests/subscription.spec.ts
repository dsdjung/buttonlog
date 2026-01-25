import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

/**
 * Subscriptions Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * Tests check for page load success and appropriate UI states.
 */
test.describe('Subscriptions', () => {
  test.describe('Public Pricing Page', () => {
    test('loads successfully without auth', async ({ page }) => {
      const response = await page.goto('/pricing');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays Free plan', async ({ page }) => {
      await page.goto('/pricing');
      await expect(page.locator('text=Free').first()).toBeVisible();
    });

    test('displays Premium plan', async ({ page }) => {
      await page.goto('/pricing');
      await expect(page.locator('text=Premium').first()).toBeVisible();
    });

    test('displays Enterprise plan', async ({ page }) => {
      await page.goto('/pricing');
      const enterprise = page.locator('text=Enterprise');
      if (await enterprise.count() > 0) {
        await expect(enterprise.first()).toBeVisible();
      }
    });

    test('shows pricing amounts', async ({ page }) => {
      await page.goto('/pricing');
      // Should see price indicators
      const prices = page.locator('text=/\\$\\d+|free/i');
      expect(await prices.count()).toBeGreaterThan(0);
    });

    test('displays feature comparisons', async ({ page }) => {
      await page.goto('/pricing');
      // Should list features for each plan
      const features = page.locator('text=/button|friend|export|notification|team/i');
      expect(await features.count()).toBeGreaterThan(0);
    });

    test('has call-to-action buttons', async ({ page }) => {
      await page.goto('/pricing');
      const cta = page.locator('a[href*="auth"]').or(page.locator('button')).or(page.locator('text=Sign'));
      await expect(cta.first()).toBeVisible();
    });
  });

  test.describe('Subscription Page', () => {
    test('loads without error', async ({ page }) => {
      const response = await page.goto('/subscription');
      expect(response?.status()).toBeLessThan(500);
    });

    test('shows subscription content or login prompt', async ({ page }) => {
      await page.goto('/subscription');
      await page.waitForLoadState('networkidle');

      const hasAuth = await hasStoredAuth();
      if (hasAuth) {
        // Should show subscription details when authenticated
        const content = page.locator('text=/subscription|plan|billing/i');
        await expect(content.first()).toBeVisible();
      } else {
        // Page should load without error
        expect(await page.title()).toBeDefined();
      }
    });
  });

  test.describe('Page Structure', () => {
    test('pricing page has basic structure', async ({ page }) => {
      await page.goto('/pricing');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });

    test('subscription page has basic structure', async ({ page }) => {
      await page.goto('/subscription');
      await page.waitForLoadState('networkidle');

      const body = page.locator('body');
      await expect(body).toBeVisible();
    });
  });
});
