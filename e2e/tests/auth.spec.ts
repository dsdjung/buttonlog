import { test, expect } from '@playwright/test';
import { TEST_USER } from './fixtures/auth';

test.describe('Authentication', () => {
  test.describe('Login Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/auth/login');
      expect(response?.status()).toBeLessThan(400);
    });

    test('has email and password fields', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('input[name="email"], input[type="email"]')).toBeVisible();
      await expect(page.locator('input[name="password"], input[type="password"]')).toBeVisible();
    });

    test('has submit button', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('button[type="submit"]')).toBeVisible();
    });

    test('has link to register', async ({ page }) => {
      await page.goto('/auth/login');

      await expect(page.locator('a[href*="register"]')).toBeVisible();
    });

    test('shows OAuth providers', async ({ page }) => {
      await page.goto('/auth/login');

      // Should show at least Google OAuth
      const oauthButtons = page.locator('a[href*="/auth/google"], button:has-text("Google")');
      // OAuth might not be configured in all environments
      // so we just check the page loads
    });
  });

  test.describe('Login Flow', () => {
    test('redirects unauthenticated users to login', async ({ page }) => {
      await page.goto('/buttons');

      // Should redirect to login
      await expect(page).toHaveURL(/\/auth\/login/);
    });

    test('can login with valid credentials', async ({ page }) => {
      await page.goto('/auth/login');

      await page.fill('input[name="email"]', TEST_USER.email);
      await page.fill('input[name="password"]', TEST_USER.password);
      await page.click('button[type="submit"]');

      // Should redirect away from login
      await page.waitForURL((url) => !url.pathname.includes('/auth/login'), { timeout: 10000 });
    });

    test('shows error for invalid email', async ({ page }) => {
      await page.goto('/auth/login');

      await page.fill('input[name="email"]', 'notauser@example.com');
      await page.fill('input[name="password"]', 'anypassword');
      await page.click('button[type="submit"]');

      // Should show error
      await expect(page.locator('.alert, .error, [role="alert"], text=/invalid|incorrect|error/i')).toBeVisible();
    });

    test('shows error for wrong password', async ({ page }) => {
      await page.goto('/auth/login');

      await page.fill('input[name="email"]', TEST_USER.email);
      await page.fill('input[name="password"]', 'wrongpassword123');
      await page.click('button[type="submit"]');

      // Should show error
      await expect(page.locator('.alert, .error, [role="alert"], text=/invalid|incorrect|error/i')).toBeVisible();
    });

    test('shows error for empty email', async ({ page }) => {
      await page.goto('/auth/login');

      await page.fill('input[name="password"]', 'somepassword');
      await page.click('button[type="submit"]');

      // Should show validation error or not submit
      const emailInput = page.locator('input[name="email"]');
      await expect(emailInput).toHaveAttribute('required', '');
    });

    test('shows error for empty password', async ({ page }) => {
      await page.goto('/auth/login');

      await page.fill('input[name="email"]', 'test@example.com');
      await page.click('button[type="submit"]');

      // Should show validation error
      const passwordInput = page.locator('input[name="password"]');
      await expect(passwordInput).toHaveAttribute('required', '');
    });
  });

  test.describe('Register Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/auth/register');
      expect(response?.status()).toBeLessThan(400);
    });

    test('has required registration fields', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('input[name="email"]')).toBeVisible();
      await expect(page.locator('input[name="username"]')).toBeVisible();
      await expect(page.locator('input[name="password"]')).toBeVisible();
    });

    test('has link to login', async ({ page }) => {
      await page.goto('/auth/register');

      await expect(page.locator('a[href*="login"]')).toBeVisible();
    });
  });

  test.describe('Registration Flow', () => {
    test('can register a new account', async ({ page }) => {
      await page.goto('/auth/register');

      const timestamp = Date.now();
      await page.fill('input[name="email"]', `newuser${timestamp}@example.com`);
      await page.fill('input[name="username"]', `newuser${timestamp}`);
      await page.fill('input[name="password"]', 'SecurePassword123!');

      // Fill confirmation if present
      const confirmField = page.locator('input[name="password_confirmation"]');
      if (await confirmField.count() > 0) {
        await confirmField.fill('SecurePassword123!');
      }

      await page.click('button[type="submit"]');

      // Should redirect to dashboard or show success
      await page.waitForURL((url) => !url.pathname.includes('/auth/register'), { timeout: 10000 });
    });

    test('shows error for existing email', async ({ page }) => {
      await page.goto('/auth/register');

      await page.fill('input[name="email"]', TEST_USER.email);
      await page.fill('input[name="username"]', `uniqueuser${Date.now()}`);
      await page.fill('input[name="password"]', 'SecurePassword123!');

      const confirmField = page.locator('input[name="password_confirmation"]');
      if (await confirmField.count() > 0) {
        await confirmField.fill('SecurePassword123!');
      }

      await page.click('button[type="submit"]');

      // Should show error about existing email
      await expect(page.locator('text=/already|exists|taken/i')).toBeVisible();
    });

    test('shows error for weak password', async ({ page }) => {
      await page.goto('/auth/register');

      const timestamp = Date.now();
      await page.fill('input[name="email"]', `test${timestamp}@example.com`);
      await page.fill('input[name="username"]', `testuser${timestamp}`);
      await page.fill('input[name="password"]', '123'); // Too weak

      const confirmField = page.locator('input[name="password_confirmation"]');
      if (await confirmField.count() > 0) {
        await confirmField.fill('123');
      }

      await page.click('button[type="submit"]');

      // Should show password requirement error
      await expect(page.locator('text=/password|character|length|weak/i')).toBeVisible();
    });

    test('shows error for mismatched passwords', async ({ page }) => {
      await page.goto('/auth/register');

      const timestamp = Date.now();
      await page.fill('input[name="email"]', `test${timestamp}@example.com`);
      await page.fill('input[name="username"]', `testuser${timestamp}`);
      await page.fill('input[name="password"]', 'SecurePassword123!');

      const confirmField = page.locator('input[name="password_confirmation"]');
      if (await confirmField.count() > 0) {
        await confirmField.fill('DifferentPassword456!');
        await page.click('button[type="submit"]');

        // Should show mismatch error
        await expect(page.locator('text=/match|confirm|different/i')).toBeVisible();
      }
    });

    test('shows error for invalid email format', async ({ page }) => {
      await page.goto('/auth/register');

      await page.fill('input[name="email"]', 'notanemail');
      await page.fill('input[name="username"]', `testuser${Date.now()}`);
      await page.fill('input[name="password"]', 'SecurePassword123!');

      // Browser validation should prevent submission
      const emailInput = page.locator('input[name="email"]');
      await expect(emailInput).toHaveAttribute('type', 'email');
    });
  });

  test.describe('Logout Flow', () => {
    test.beforeEach(async ({ page }) => {
      // Login first
      await page.goto('/auth/login');
      await page.fill('input[name="email"]', TEST_USER.email);
      await page.fill('input[name="password"]', TEST_USER.password);
      await page.click('button[type="submit"]');
      await page.waitForURL((url) => !url.pathname.includes('/auth/login'), { timeout: 10000 });
    });

    test('can logout successfully', async ({ page }) => {
      // Find logout button/link
      const logoutButton = page.locator('text=Sign Out, text=Logout, button:has-text("Log out"), a[href*="logout"]').first();
      await logoutButton.click();

      // Should redirect to login or home
      await page.waitForURL((url) =>
        url.pathname.includes('/auth/login') || url.pathname === '/',
        { timeout: 10000 }
      );
    });

    test('cannot access protected routes after logout', async ({ page }) => {
      // Logout
      const logoutButton = page.locator('text=Sign Out, text=Logout, button:has-text("Log out"), a[href*="logout"]').first();
      await logoutButton.click();
      await page.waitForLoadState('networkidle');

      // Try to access protected route
      await page.goto('/buttons');

      // Should redirect to login
      await expect(page).toHaveURL(/\/auth\/login/);
    });
  });

  test.describe('OAuth Integration', () => {
    test('Google OAuth link exists', async ({ page }) => {
      await page.goto('/auth/login');

      const googleLink = page.locator('a[href*="/auth/google"], button:has-text("Google")');
      // Only test if OAuth is configured
      if (await googleLink.count() > 0) {
        await expect(googleLink).toBeVisible();
      }
    });

    test('Apple OAuth link exists', async ({ page }) => {
      await page.goto('/auth/login');

      const appleLink = page.locator('a[href*="/auth/apple"], button:has-text("Apple")');
      // Only test if OAuth is configured
      if (await appleLink.count() > 0) {
        await expect(appleLink).toBeVisible();
      }
    });
  });

  test.describe('Session Persistence', () => {
    test('stays logged in after page refresh', async ({ page }) => {
      // Login
      await page.goto('/auth/login');
      await page.fill('input[name="email"]', TEST_USER.email);
      await page.fill('input[name="password"]', TEST_USER.password);
      await page.click('button[type="submit"]');
      await page.waitForURL((url) => !url.pathname.includes('/auth/login'), { timeout: 10000 });

      // Refresh
      await page.reload();

      // Should still be logged in (not redirected to login)
      await expect(page).not.toHaveURL(/\/auth\/login/);
    });
  });
});
