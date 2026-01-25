import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('shows login page for unauthenticated users', async ({ page }) => {
    await page.goto('/');

    // Should redirect to login or show login form
    await expect(page).toHaveURL(/\/(login|auth)/);
  });

  test('can register a new account', async ({ page }) => {
    await page.goto('/register');

    // Fill registration form
    const timestamp = Date.now();
    await page.fill('[name="email"], input[type="email"]', `test${timestamp}@example.com`);
    await page.fill('[name="username"]', `testuser${timestamp}`);
    await page.fill('[name="password"]', 'TestPassword123!');
    await page.fill('[name="password_confirmation"]', 'TestPassword123!');

    // Submit
    await page.click('button[type="submit"]');

    // Should redirect to dashboard or show success
    await expect(page).not.toHaveURL(/\/register/);
  });

  test('can login with valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Fill login form
    await page.fill('[name="email"], input[type="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');

    // Submit
    await page.click('button[type="submit"]');

    // Wait for navigation
    await page.waitForLoadState('networkidle');
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"], input[type="email"]', 'invalid@example.com');
    await page.fill('[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');

    // Should show error message
    await expect(page.locator('.alert-danger, .error, [role="alert"]')).toBeVisible();
  });

  test('can logout', async ({ page }) => {
    // First login
    await page.goto('/login');
    await page.fill('[name="email"], input[type="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Find and click logout
    await page.click('text=Sign Out, text=Logout, button:has-text("Log")');

    // Should redirect to login
    await expect(page).toHaveURL(/\/(login|auth|$)/);
  });
});
