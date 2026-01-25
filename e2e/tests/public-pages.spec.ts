import { test, expect } from '@playwright/test';

test.describe('Public Pages', () => {
  test.describe('Home Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/');
      expect(response?.status()).toBeLessThan(400);
    });

    test('has navigation to main features', async ({ page }) => {
      await page.goto('/');

      // Should have links to login or register (use .first() since multiple may exist)
      const authLink = page.locator('a[href*="login"], a[href*="register"]').first();
      await expect(authLink).toBeVisible();
    });

    test('displays app branding', async ({ page }) => {
      await page.goto('/');

      // Should show branding - check for logo or app name
      const branding = page.locator('img[alt*="logo" i], .logo, [data-logo], header').first();
      await expect(branding).toBeVisible();
    });
  });

  test.describe('Pricing Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/pricing');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays subscription plans', async ({ page }) => {
      await page.goto('/pricing');

      // Should show Free plan
      await expect(page.locator('text=Free').first()).toBeVisible();
    });

    test('shows pricing information', async ({ page }) => {
      await page.goto('/pricing');

      // Should display price or "free"
      const priceIndicator = page.locator('text=/\\$\\d+|free|Free/i');
      await expect(priceIndicator.first()).toBeVisible();
    });

    test('has call-to-action buttons', async ({ page }) => {
      await page.goto('/pricing');

      // Should have upgrade/signup/login buttons
      const ctaButton = page.locator('button, a[href*="login"], a[href*="register"]').first();
      await expect(ctaButton).toBeVisible();
    });

    test('displays feature comparison', async ({ page }) => {
      await page.goto('/pricing');

      // Should list features for each plan
      const features = page.locator('text=/button|friend|export|notification/i');
      expect(await features.count()).toBeGreaterThan(0);
    });
  });

  test.describe('Health Check', () => {
    test('returns healthy status', async ({ page }) => {
      const response = await page.goto('/health');
      expect(response?.status()).toBe(200);
    });
  });

  test.describe('Auth Pages (Public)', () => {
    test('login page loads', async ({ page }) => {
      const response = await page.goto('/auth/login');
      expect(response?.status()).toBeLessThan(400);
    });

    test('register page loads', async ({ page }) => {
      const response = await page.goto('/auth/register');
      expect(response?.status()).toBeLessThan(400);
    });

    test('login page has OAuth option', async ({ page }) => {
      await page.goto('/auth/login');

      // App uses OAuth-only authentication (Google)
      const googleAuth = page.locator('a[href*="/auth/google"]').first();
      await expect(googleAuth).toBeVisible();
    });

    test('register page has OAuth option', async ({ page }) => {
      await page.goto('/auth/register');

      // App uses OAuth-only authentication (Google)
      const googleAuth = page.locator('a[href*="/auth/google"]').first();
      await expect(googleAuth).toBeVisible();
    });

    test('register page has link to login', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('a[href*="login"]')).toBeVisible();
    });
  });
});
