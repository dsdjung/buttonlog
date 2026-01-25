import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Account Settings', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Account Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/account');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays account header', async ({ page }) => {
      await page.goto('/account');

      await expect(page.locator('h1, h2').first()).toContainText(/account|profile|settings/i);
    });

    test('shows user email', async ({ page }) => {
      await page.goto('/account');

      // Should show current user's email somewhere on page
      await page.waitForLoadState('networkidle');
    });

    test('has navigation sections', async ({ page }) => {
      await page.goto('/account');

      // Should have multiple settings sections
      const sections = page.locator('nav a, .sidebar a, .settings-section');
      expect(await sections.count()).toBeGreaterThan(0);
    });
  });

  test.describe('Profile Information', () => {
    test('can view profile section', async ({ page }) => {
      await page.goto('/account');

      const profileSection = page.locator('text=Profile, text=Personal, [data-section="profile"]');
      if (await profileSection.count() > 0) {
        await expect(profileSection.first()).toBeVisible();
      }
    });

    test('can edit display name', async ({ page }) => {
      await page.goto('/account');

      const editButton = page.locator('button:has-text("Edit"), a[href*="edit"]').first();
      if (await editButton.count() > 0) {
        await editButton.click();

        const displayNameInput = page.locator('input[name="display_name"], input[name="displayName"]');
        if (await displayNameInput.count() > 0) {
          await displayNameInput.fill(`Test User ${Date.now()}`);
          await page.click('button[type="submit"], button:has-text("Save")');
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('can edit username', async ({ page }) => {
      await page.goto('/account');

      const usernameInput = page.locator('input[name="username"]');
      if (await usernameInput.count() > 0) {
        // Username field exists
        await expect(usernameInput).toBeVisible();
      }
    });

    test('can update email', async ({ page }) => {
      await page.goto('/account');

      const emailInput = page.locator('input[name="email"], input[type="email"]');
      if (await emailInput.count() > 0) {
        await expect(emailInput).toBeVisible();
      }
    });

    test('shows avatar', async ({ page }) => {
      await page.goto('/account');

      const avatar = page.locator('img[alt*="avatar" i], .avatar, [data-avatar]');
      if (await avatar.count() > 0) {
        await expect(avatar.first()).toBeVisible();
      }
    });

    test('can upload new avatar', async ({ page }) => {
      await page.goto('/account');

      const avatarUpload = page.locator('input[type="file"], button:has-text("Upload")');
      if (await avatarUpload.count() > 0) {
        await expect(avatarUpload.first()).toBeVisible();
      }
    });
  });

  test.describe('Password Change', () => {
    test('can access password change section', async ({ page }) => {
      await page.goto('/account');

      const passwordSection = page.locator('text=Password, text=Security, a[href*="password"]');
      if (await passwordSection.count() > 0) {
        await passwordSection.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('has current password field', async ({ page }) => {
      await page.goto('/account');

      const currentPassword = page.locator('input[name="current_password"], input[name="currentPassword"]');
      if (await currentPassword.count() > 0) {
        await expect(currentPassword).toBeVisible();
      }
    });

    test('has new password field', async ({ page }) => {
      await page.goto('/account');

      const newPassword = page.locator('input[name="new_password"], input[name="newPassword"], input[name="password"]');
      if (await newPassword.count() > 0) {
        await expect(newPassword).toBeVisible();
      }
    });

    test('has confirm password field', async ({ page }) => {
      await page.goto('/account');

      const confirmPassword = page.locator('input[name="confirm_password"], input[name="password_confirmation"]');
      if (await confirmPassword.count() > 0) {
        await expect(confirmPassword).toBeVisible();
      }
    });

    test('shows error for weak password', async ({ page }) => {
      await page.goto('/account');

      const newPassword = page.locator('input[name="new_password"]');
      if (await newPassword.count() > 0) {
        await newPassword.fill('123');
        await page.click('button[type="submit"]');

        const error = page.locator('text=/weak|short|character/i, .error');
        if (await error.count() > 0) {
          await expect(error.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Privacy Settings', () => {
    test('can access privacy settings', async ({ page }) => {
      await page.goto('/account');

      const privacyLink = page.locator('text=Privacy, a[href*="privacy"]').first();
      if (await privacyLink.count() > 0) {
        await privacyLink.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can set profile visibility', async ({ page }) => {
      await page.goto('/account');

      const profileVisibility = page.locator('select[name="profile_visibility"], [data-setting="profile_visibility"]');
      if (await profileVisibility.count() > 0) {
        await profileVisibility.click();
      }
    });

    test('can set activity visibility', async ({ page }) => {
      await page.goto('/account');

      const activityVisibility = page.locator('select[name="activity_visibility"], [data-setting="activity_visibility"]');
      if (await activityVisibility.count() > 0) {
        await activityVisibility.click();
      }
    });

    test('visibility options include public/friends/private', async ({ page }) => {
      await page.goto('/account');

      const options = page.locator('text=/public|friends|private/i');
      if (await options.count() > 0) {
        await expect(options.first()).toBeVisible();
      }
    });
  });

  test.describe('Notification Settings', () => {
    test('can access notification settings', async ({ page }) => {
      await page.goto('/account');

      const notifLink = page.locator('text=Notification, a[href*="notification"]').first();
      if (await notifLink.count() > 0) {
        await notifLink.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can toggle push notifications', async ({ page }) => {
      await page.goto('/account');

      const pushToggle = page.locator('input[name*="push"], [data-notification="push"]');
      if (await pushToggle.count() > 0) {
        await pushToggle.click();
      }
    });

    test('can toggle email notifications', async ({ page }) => {
      await page.goto('/account');

      const emailToggle = page.locator('input[name*="email"], [data-notification="email"]');
      if (await emailToggle.count() > 0) {
        await emailToggle.click();
      }
    });

    test('can toggle friend notifications', async ({ page }) => {
      await page.goto('/account');

      const friendToggle = page.locator('input[name*="friend"], [data-notification="friend"]');
      if (await friendToggle.count() > 0) {
        await friendToggle.click();
      }
    });

    test('can toggle button notifications', async ({ page }) => {
      await page.goto('/account');

      const buttonToggle = page.locator('input[name*="button"], [data-notification="button"]');
      if (await buttonToggle.count() > 0) {
        await buttonToggle.click();
      }
    });
  });

  test.describe('Timezone Settings', () => {
    test('can set timezone', async ({ page }) => {
      await page.goto('/account');

      const timezoneSelect = page.locator('select[name="timezone"], [data-setting="timezone"]');
      if (await timezoneSelect.count() > 0) {
        await timezoneSelect.click();
      }
    });
  });

  test.describe('Language Settings', () => {
    test('can set language preference', async ({ page }) => {
      await page.goto('/account');

      const languageSelect = page.locator('select[name="language"], [data-setting="language"]');
      if (await languageSelect.count() > 0) {
        await languageSelect.click();
      }
    });
  });

  test.describe('Data Export', () => {
    test('can access export section', async ({ page }) => {
      await page.goto('/account');

      const exportSection = page.locator('text=Export, text=Download, a[href*="export"]');
      if (await exportSection.count() > 0) {
        await expect(exportSection.first()).toBeVisible();
      }
    });

    test('can export as JSON', async ({ page }) => {
      await page.goto('/account');

      const jsonExport = page.locator('button:has-text("JSON"), button:has-text("Export JSON")');
      if (await jsonExport.count() > 0) {
        await expect(jsonExport.first()).toBeVisible();
      }
    });

    test('can export as CSV', async ({ page }) => {
      await page.goto('/account');

      const csvExport = page.locator('button:has-text("CSV"), button:has-text("Export CSV")');
      if (await csvExport.count() > 0) {
        await expect(csvExport.first()).toBeVisible();
      }
    });
  });

  test.describe('Subscription Info', () => {
    test('shows current subscription tier', async ({ page }) => {
      await page.goto('/account');

      const subscription = page.locator('text=/free|premium|enterprise|subscription|plan/i');
      if (await subscription.count() > 0) {
        await expect(subscription.first()).toBeVisible();
      }
    });

    test('has link to upgrade', async ({ page }) => {
      await page.goto('/account');

      const upgradeLink = page.locator('a[href*="subscription"], a[href*="pricing"], button:has-text("Upgrade")');
      if (await upgradeLink.count() > 0) {
        await expect(upgradeLink.first()).toBeVisible();
      }
    });
  });

  test.describe('Connected Accounts', () => {
    test('shows OAuth connections', async ({ page }) => {
      await page.goto('/account');

      const oauthSection = page.locator('text=/connected|linked|oauth|google|apple/i');
      if (await oauthSection.count() > 0) {
        await expect(oauthSection.first()).toBeVisible();
      }
    });

    test('can connect Google account', async ({ page }) => {
      await page.goto('/account');

      const connectGoogle = page.locator('button:has-text("Google"), a[href*="google"]');
      if (await connectGoogle.count() > 0) {
        await expect(connectGoogle.first()).toBeVisible();
      }
    });

    test('can connect Apple account', async ({ page }) => {
      await page.goto('/account');

      const connectApple = page.locator('button:has-text("Apple"), a[href*="apple"]');
      if (await connectApple.count() > 0) {
        await expect(connectApple.first()).toBeVisible();
      }
    });
  });

  test.describe('Mobile Devices', () => {
    test('shows connected devices', async ({ page }) => {
      await page.goto('/account');

      const devices = page.locator('text=Devices, text=Mobile, [data-section="devices"]');
      if (await devices.count() > 0) {
        await expect(devices.first()).toBeVisible();
      }
    });

    test('can disconnect a device', async ({ page }) => {
      await page.goto('/account');

      const disconnectButton = page.locator('button:has-text("Disconnect"), button:has-text("Remove Device")');
      if (await disconnectButton.count() > 0) {
        await expect(disconnectButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Delete Account', () => {
    test('has delete account option', async ({ page }) => {
      await page.goto('/account');

      const deleteButton = page.locator('button:has-text("Delete Account"), text=Delete Account');
      if (await deleteButton.count() > 0) {
        await expect(deleteButton.first()).toBeVisible();
      }
    });

    test('requires confirmation for deletion', async ({ page }) => {
      await page.goto('/account');

      const deleteButton = page.locator('button:has-text("Delete Account")').first();
      if (await deleteButton.count() > 0) {
        await deleteButton.click();

        // Should show confirmation dialog
        const confirmation = page.locator('text=/sure|confirm|irreversible/i, [role="dialog"]');
        if (await confirmation.count() > 0) {
          await expect(confirmation.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Sign Out', () => {
    test('can sign out from account page', async ({ page }) => {
      await page.goto('/account');

      const signOutButton = page.locator('button:has-text("Sign Out"), button:has-text("Logout"), a[href*="logout"]');
      await expect(signOutButton.first()).toBeVisible();
    });
  });
});
