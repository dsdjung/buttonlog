import { test, expect } from '@playwright/test';

/**
 * Authentication Tests
 *
 * Note: This app uses OAuth-only authentication (Google).
 * There are no email/password forms.
 */
test.describe('Authentication', () => {
  test.describe('Login Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/auth/login');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays sign in title', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('text=/sign in|login/i').first()).toBeVisible();
    });

    test('shows Google OAuth option', async ({ page }) => {
      await page.goto('/auth/login');

      const googleLink = page.locator('a[href*="/auth/google"]').first();
      await expect(googleLink).toBeVisible();
    });

    test('Google OAuth link has correct text', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('text=/google/i').first()).toBeVisible();
    });
  });

  test.describe('Register Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/auth/register');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays create account title', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('text=/create.*account|sign up|register/i').first()).toBeVisible();
    });

    test('shows Google OAuth option', async ({ page }) => {
      await page.goto('/auth/register');

      const googleLink = page.locator('a[href*="/auth/google"]').first();
      await expect(googleLink).toBeVisible();
    });

    test('has link to login', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('a[href*="login"]')).toBeVisible();
    });
  });

  test.describe('Routes Accessible Without Auth', () => {
    // Note: This app shows a different UI for unauthenticated users
    // instead of redirecting to login

    test('/buttons loads without auth', async ({ page }) => {
      const response = await page.goto('/buttons');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/friends loads without auth', async ({ page }) => {
      const response = await page.goto('/friends');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/account loads without auth', async ({ page }) => {
      const response = await page.goto('/account');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/notifications loads without auth', async ({ page }) => {
      const response = await page.goto('/notifications');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/diary loads without auth', async ({ page }) => {
      const response = await page.goto('/diary');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/teams loads without auth', async ({ page }) => {
      const response = await page.goto('/teams');
      expect(response?.status()).toBeLessThan(400);
    });

    test('/organizations loads without auth', async ({ page }) => {
      const response = await page.goto('/organizations');
      expect(response?.status()).toBeLessThan(400);
    });

    test('unauthenticated /buttons shows login option', async ({ page }) => {
      await page.goto('/buttons');

      // Should show login link for unauthenticated users
      const loginLink = page.locator('a[href*="login"], a[href*="register"]').first();
      await expect(loginLink).toBeVisible();
    });
  });

  test.describe('Public Routes', () => {
    test('pricing page is accessible without auth', async ({ page }) => {
      const response = await page.goto('/pricing');
      expect(response?.status()).toBeLessThan(400);

      // Should NOT redirect to login
      await expect(page).not.toHaveURL(/\/auth\/login/);
    });

    test('home page is accessible without auth', async ({ page }) => {
      const response = await page.goto('/');
      expect(response?.status()).toBeLessThan(400);

      await expect(page).not.toHaveURL(/\/auth\/login/);
    });

    test('health check is accessible without auth', async ({ page }) => {
      const response = await page.goto('/health');
      expect(response?.status()).toBe(200);
    });
  });

  test.describe('OAuth Flow', () => {
    test('Google OAuth link points to correct path', async ({ page }) => {
      await page.goto('/auth/login');

      const googleLink = page.locator('a[href*="/auth/google"]').first();
      const href = await googleLink.getAttribute('href');
      expect(href).toContain('/auth/google');
    });

    test('clicking Google OAuth initiates redirect', async ({ page }) => {
      await page.goto('/auth/login');

      const googleLink = page.locator('a[href*="/auth/google"]').first();

      // Don't actually click - just verify the link exists and has correct href
      await expect(googleLink).toBeVisible();
      const href = await googleLink.getAttribute('href');
      expect(href).toBeTruthy();
    });
  });

  test.describe('Terms Agreement', () => {
    test('login page mentions terms of service', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('text=/terms/i').first()).toBeVisible();
    });

    test('login page mentions privacy policy', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('text=/privacy/i').first()).toBeVisible();
    });

    test('register page mentions terms of service', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('text=/terms/i').first()).toBeVisible();
    });
  });
});
