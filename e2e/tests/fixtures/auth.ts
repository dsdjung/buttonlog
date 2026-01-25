import { test as base, expect, Page } from '@playwright/test';

// Test user credentials
export const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
  password: process.env.TEST_USER_PASSWORD || 'password123',
};

// Admin user for admin tests
export const ADMIN_USER = {
  email: process.env.ADMIN_USER_EMAIL || 'admin@example.com',
  password: process.env.ADMIN_USER_PASSWORD || 'adminpassword123',
};

// Helper function to login
export async function login(page: Page, email?: string, password?: string) {
  await page.goto('/auth/login');

  await page.fill('input[name="email"], input[type="email"]', email || TEST_USER.email);
  await page.fill('input[name="password"]', password || TEST_USER.password);
  await page.click('button[type="submit"]');

  // Wait for redirect after successful login
  await page.waitForURL((url) => !url.pathname.includes('/auth/login'), { timeout: 10000 });
}

// Helper function to register a new user
export async function register(page: Page, userData?: {
  email?: string;
  username?: string;
  password?: string;
}) {
  const timestamp = Date.now();
  const data = {
    email: userData?.email || `test${timestamp}@example.com`,
    username: userData?.username || `testuser${timestamp}`,
    password: userData?.password || 'TestPassword123!',
  };

  await page.goto('/auth/register');

  await page.fill('input[name="email"]', data.email);
  await page.fill('input[name="username"]', data.username);
  await page.fill('input[name="password"]', data.password);

  const confirmField = page.locator('input[name="password_confirmation"]');
  if (await confirmField.count() > 0) {
    await confirmField.fill(data.password);
  }

  await page.click('button[type="submit"]');

  return data;
}

// Helper to logout
export async function logout(page: Page) {
  // Try different logout methods
  const logoutLink = page.locator('a[href*="logout"], button:has-text("Sign Out"), button:has-text("Logout")').first();

  if (await logoutLink.count() > 0) {
    await logoutLink.click();
  } else {
    // Fallback: navigate directly
    await page.goto('/auth/logout');
  }
}

// Extended test with authenticated user
export const authenticatedTest = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page }, use) => {
    await login(page);
    await use(page);
  },
});
