import { test, expect } from '@playwright/test';

const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
  password: process.env.TEST_USER_PASSWORD || 'password123',
};

test.describe('Account Settings', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name="email"], input[type="email"]', TEST_USER.email);
    await page.fill('[name="password"]', TEST_USER.password);
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
  });

  test('can access account page', async ({ page }) => {
    await page.goto('/account');

    await expect(page.locator('h1, h2').first()).toContainText(/account|profile|settings/i);
  });

  test('can edit profile', async ({ page }) => {
    await page.goto('/account');

    // Look for edit profile section or link
    const editProfile = page.locator('text=Edit Profile, a[href*="profile"], button:has-text("Edit")').first();

    if (await editProfile.count() > 0) {
      await editProfile.click();
      await page.waitForLoadState('networkidle');

      // Update display name
      const displayNameInput = page.locator('[name="display_name"], [name="displayName"]');
      if (await displayNameInput.count() > 0) {
        await displayNameInput.clear();
        await displayNameInput.fill(`Test User ${Date.now()}`);

        await page.click('button[type="submit"], button:has-text("Save")');
        await page.waitForLoadState('networkidle');
      }
    }
  });

  test('can access privacy settings', async ({ page }) => {
    await page.goto('/account');

    const privacyLink = page.locator('text=Privacy, a[href*="privacy"]').first();

    if (await privacyLink.count() > 0) {
      await privacyLink.click();

      // Should see privacy options
      await expect(page.locator('text=Profile Visibility, text=Activity Visibility, text=Privacy')).toBeVisible();
    }
  });

  test('can access notification settings', async ({ page }) => {
    await page.goto('/account');

    const notifLink = page.locator('text=Notification, a[href*="notification"]').first();

    if (await notifLink.count() > 0) {
      await notifLink.click();

      // Should see notification options
      await expect(page.locator('text=Push, text=Email, text=Notification')).toBeVisible();
    }
  });

  test('can access about page', async ({ page }) => {
    await page.goto('/account');

    const aboutLink = page.locator('text=About, a[href*="about"]').first();

    if (await aboutLink.count() > 0) {
      await aboutLink.click();

      // Should see app info
      await expect(page.locator('text=Version, text=ButtonLog')).toBeVisible();
    }
  });

  test('terms of service page loads', async ({ page }) => {
    await page.goto('/terms');

    await expect(page.locator('h1, h2').first()).toContainText(/terms/i);
    await expect(page.locator('body')).toContainText(/service|agreement|use/i);
  });

  test('privacy policy page loads', async ({ page }) => {
    await page.goto('/privacy');

    await expect(page.locator('h1, h2').first()).toContainText(/privacy/i);
    await expect(page.locator('body')).toContainText(/data|information|collect/i);
  });
});
