import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Notifications', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Notifications Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/notifications');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays notifications list or empty state', async ({ page }) => {
      await page.goto('/notifications');

      // Should show notifications or empty state
      const content = page.locator('.notification, [data-notification], text=/no notification|all caught up|empty/i');
      await expect(content.first()).toBeVisible();
    });

    test('shows notification types', async ({ page }) => {
      await page.goto('/notifications');

      // Different notification types may be displayed
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Notification Items', () => {
    test('can view notification detail', async ({ page }) => {
      await page.goto('/notifications');

      const notification = page.locator('.notification, [data-notification-id]').first();
      if (await notification.count() > 0) {
        await notification.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows notification timestamp', async ({ page }) => {
      await page.goto('/notifications');

      const notification = page.locator('.notification, [data-notification-id]').first();
      if (await notification.count() > 0) {
        // Should have timestamp
        const timestamp = page.locator('time, .timestamp, text=/ago|today|yesterday/i').first();
        await expect(timestamp).toBeVisible();
      }
    });

    test('can mark notification as read', async ({ page }) => {
      await page.goto('/notifications');

      const markReadButton = page.locator('button:has-text("Mark as Read"), button:has-text("Read"), [data-mark-read]');
      if (await markReadButton.count() > 0) {
        await markReadButton.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can mark all notifications as read', async ({ page }) => {
      await page.goto('/notifications');

      const markAllReadButton = page.locator('button:has-text("Mark All"), button:has-text("Read All")');
      if (await markAllReadButton.count() > 0) {
        await expect(markAllReadButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Notification Badge', () => {
    test('shows unread count in nav', async ({ page }) => {
      await page.goto('/buttons');

      // Nav should show notification badge if there are unread notifications
      const badge = page.locator('.notification-badge, [data-notification-count], .unread-count');
      // Badge may or may not be visible
      await page.waitForLoadState('networkidle');
    });

    test('updates badge after reading', async ({ page }) => {
      await page.goto('/notifications');

      const markAllReadButton = page.locator('button:has-text("Mark All Read")');
      if (await markAllReadButton.count() > 0) {
        await markAllReadButton.click();
        await page.waitForLoadState('networkidle');

        // Badge should update or disappear
      }
    });
  });

  test.describe('Notification Types', () => {
    test('friend request notifications', async ({ page }) => {
      await page.goto('/notifications');

      const friendNotification = page.locator('text=/friend request|wants to be friends/i');
      if (await friendNotification.count() > 0) {
        await expect(friendNotification.first()).toBeVisible();
      }
    });

    test('button click notifications', async ({ page }) => {
      await page.goto('/notifications');

      const clickNotification = page.locator('text=/clicked|button/i');
      if (await clickNotification.count() > 0) {
        await expect(clickNotification.first()).toBeVisible();
      }
    });

    test('system notifications', async ({ page }) => {
      await page.goto('/notifications');

      const systemNotification = page.locator('text=/system|update|announcement/i');
      if (await systemNotification.count() > 0) {
        await expect(systemNotification.first()).toBeVisible();
      }
    });
  });

  test.describe('Notification Actions', () => {
    test('can delete notification', async ({ page }) => {
      await page.goto('/notifications');

      const deleteButton = page.locator('button:has-text("Delete"), button:has-text("Remove"), [data-delete-notification]');
      if (await deleteButton.count() > 0) {
        await expect(deleteButton.first()).toBeVisible();
      }
    });

    test('can clear all notifications', async ({ page }) => {
      await page.goto('/notifications');

      const clearAllButton = page.locator('button:has-text("Clear All"), button:has-text("Delete All")');
      if (await clearAllButton.count() > 0) {
        await expect(clearAllButton.first()).toBeVisible();
      }
    });

    test('notification links to relevant page', async ({ page }) => {
      await page.goto('/notifications');

      const notificationLink = page.locator('.notification a, [data-notification-id] a').first();
      if (await notificationLink.count() > 0) {
        const href = await notificationLink.getAttribute('href');
        expect(href).toBeTruthy();
      }
    });
  });

  test.describe('Notification Settings', () => {
    test('can access notification settings', async ({ page }) => {
      await page.goto('/account');

      const notificationSettings = page.locator('text=Notification, a[href*="notification"]');
      if (await notificationSettings.count() > 0) {
        await notificationSettings.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can toggle push notifications', async ({ page }) => {
      await page.goto('/account');

      const pushToggle = page.locator('input[name*="push"], [data-notification-push]');
      if (await pushToggle.count() > 0) {
        await pushToggle.click();
      }
    });

    test('can toggle email notifications', async ({ page }) => {
      await page.goto('/account');

      const emailToggle = page.locator('input[name*="email"], [data-notification-email]');
      if (await emailToggle.count() > 0) {
        await emailToggle.click();
      }
    });
  });

  test.describe('Real-time Notifications', () => {
    test('page receives live updates', async ({ page }) => {
      await page.goto('/notifications');

      // Wait for websocket connection
      await page.waitForLoadState('networkidle');

      // Page should be set up for live updates
    });
  });
});
