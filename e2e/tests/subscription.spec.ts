import { test, expect } from '@playwright/test';

const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
  password: process.env.TEST_USER_PASSWORD || 'password123',
};

test.describe('Subscriptions', () => {
  test('subscription plans page is publicly accessible', async ({ page }) => {
    await page.goto('/subscriptions');

    // Should see subscription plans
    await expect(page.locator('text=Free, text=Premium, text=Plan')).toBeVisible();
  });

  test('displays pricing information', async ({ page }) => {
    await page.goto('/subscriptions');

    // Should see pricing
    await expect(page.locator('text=$, text=/mo, text=/month, text=free')).toBeVisible();
  });

  test('authenticated user can view subscription status', async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name="email"], input[type="email"]', TEST_USER.email);
    await page.fill('[name="password"]', TEST_USER.password);
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Go to account and check subscription
    await page.goto('/account');

    // Should see current plan info
    await expect(page.locator('text=Plan, text=Subscription, text=Free, text=Premium')).toBeVisible();
  });
});
