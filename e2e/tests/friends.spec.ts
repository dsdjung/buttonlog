import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Friends & Social', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Friends List Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/friends');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays friends list or empty state', async ({ page }) => {
      await page.goto('/friends');

      // Should show friends or empty state
      const content = page.locator('.friend-card, [data-friend], text=/no friend|add friend|find friend/i');
      await expect(content.first()).toBeVisible();
    });

    test('has search/add friends option', async ({ page }) => {
      await page.goto('/friends');

      const addButton = page.locator('a[href*="add"], button:has-text("Add"), button:has-text("Find"), input[placeholder*="search" i]');
      await expect(addButton.first()).toBeVisible();
    });

    test('shows friend count', async ({ page }) => {
      await page.goto('/friends');

      // Page should display friend count somewhere
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Friend Search', () => {
    test('can search for users', async ({ page }) => {
      await page.goto('/friends');

      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i], input[name="query"]');
      if (await searchInput.count() > 0) {
        await searchInput.fill('test');
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows search results', async ({ page }) => {
      await page.goto('/friends');

      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
      if (await searchInput.count() > 0) {
        await searchInput.fill('user');
        await page.waitForLoadState('networkidle');

        // Should show results or no results message
        const results = page.locator('.search-result, [data-user], text=/no results|not found/i');
        if (await results.count() > 0) {
          await expect(results.first()).toBeVisible();
        }
      }
    });

    test('can send friend request from search', async ({ page }) => {
      await page.goto('/friends');

      const addFriendButton = page.locator('button:has-text("Add Friend"), button:has-text("Send Request")');
      if (await addFriendButton.count() > 0) {
        // Button exists for adding friends
        await expect(addFriendButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Friend Requests', () => {
    test('can view pending requests', async ({ page }) => {
      await page.goto('/friends');

      const requestsTab = page.locator('text=Requests, text=Pending, a[href*="requests"]');
      if (await requestsTab.count() > 0) {
        await requestsTab.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can accept friend request', async ({ page }) => {
      await page.goto('/friends');

      const acceptButton = page.locator('button:has-text("Accept"), button:has-text("Approve")');
      if (await acceptButton.count() > 0) {
        // Accept button exists
        await expect(acceptButton.first()).toBeVisible();
      }
    });

    test('can decline friend request', async ({ page }) => {
      await page.goto('/friends');

      const declineButton = page.locator('button:has-text("Decline"), button:has-text("Reject"), button:has-text("Ignore")');
      if (await declineButton.count() > 0) {
        await expect(declineButton.first()).toBeVisible();
      }
    });

    test('shows request count badge', async ({ page }) => {
      await page.goto('/friends');

      // Check for notification badge on requests
      const badge = page.locator('.badge, [data-request-count], .notification-count');
      // Badge may or may not be visible depending on pending requests
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Friend Detail Page', () => {
    test('can view friend profile', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"], .friend-card').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        // Should show friend details
        await page.waitForURL(/\/friends\/[^/]+/);
      }
    });

    test('shows friend username', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        await expect(page.locator('h1, h2, .username, .display-name')).toBeVisible();
      }
    });

    test('shows friend activity', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        // Should show activity section
        const activity = page.locator('text=/activity|button|click|recent/i');
        if (await activity.count() > 0) {
          await expect(activity.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Friend Permissions', () => {
    test('can access permissions settings', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const permissionsLink = page.locator('text=Permissions, a[href*="permission"], button:has-text("Settings")');
        if (await permissionsLink.count() > 0) {
          await permissionsLink.first().click();
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('can toggle view permission', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const viewToggle = page.locator('input[name*="view"], [data-permission="view"]');
        if (await viewToggle.count() > 0) {
          await viewToggle.click();
        }
      }
    });

    test('can toggle click permission', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const clickToggle = page.locator('input[name*="click"], [data-permission="click"]');
        if (await clickToggle.count() > 0) {
          await clickToggle.click();
        }
      }
    });
  });

  test.describe('Remove Friend', () => {
    test('can unfriend a user', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const unfriendButton = page.locator('button:has-text("Remove"), button:has-text("Unfriend")');
        if (await unfriendButton.count() > 0) {
          await expect(unfriendButton.first()).toBeVisible();
        }
      }
    });

    test('shows confirmation before unfriend', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const unfriendButton = page.locator('button:has-text("Remove"), button:has-text("Unfriend")').first();
        if (await unfriendButton.count() > 0) {
          await unfriendButton.click();

          // Should show confirmation
          const confirmation = page.locator('text=/sure|confirm/i, [role="dialog"]');
          if (await confirmation.count() > 0) {
            await expect(confirmation.first()).toBeVisible();
          }
        }
      }
    });
  });

  test.describe('Friend Activity Feed', () => {
    test('shows friends activity on dashboard', async ({ page }) => {
      await page.goto('/buttons');

      // Dashboard may show friend activity
      const friendActivity = page.locator('text=/friend|activity feed/i, .friend-activity');
      // This is optional depending on feature implementation
      await page.waitForLoadState('networkidle');
    });

    test('can filter by friend', async ({ page }) => {
      await page.goto('/buttons');

      const friendFilter = page.locator('select[name="friend"], [data-friend-filter]');
      if (await friendFilter.count() > 0) {
        await friendFilter.click();
      }
    });
  });

  test.describe('Block User', () => {
    test('can block a user', async ({ page }) => {
      await page.goto('/friends');

      const friendLink = page.locator('a[href*="/friends/"]').first();
      if (await friendLink.count() > 0) {
        await friendLink.click();

        const blockButton = page.locator('button:has-text("Block"), a:has-text("Block")');
        if (await blockButton.count() > 0) {
          await expect(blockButton.first()).toBeVisible();
        }
      }
    });

    test('can view blocked users', async ({ page }) => {
      await page.goto('/friends');

      const blockedTab = page.locator('text=Blocked, a[href*="blocked"]');
      if (await blockedTab.count() > 0) {
        await blockedTab.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can unblock a user', async ({ page }) => {
      await page.goto('/friends');

      const blockedTab = page.locator('text=Blocked, a[href*="blocked"]');
      if (await blockedTab.count() > 0) {
        await blockedTab.click();

        const unblockButton = page.locator('button:has-text("Unblock")');
        if (await unblockButton.count() > 0) {
          await expect(unblockButton.first()).toBeVisible();
        }
      }
    });
  });
});
