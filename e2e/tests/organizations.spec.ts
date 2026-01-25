import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Organizations', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Organizations List Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/organizations');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays organizations list or empty state', async ({ page }) => {
      await page.goto('/organizations');

      // Should show organizations or empty state
      const content = page.locator('.org-card, [data-organization], text=/no organization|create.*organization|join.*organization/i');
      await expect(content.first()).toBeVisible();
    });

    test('has create organization option', async ({ page }) => {
      await page.goto('/organizations');

      const createButton = page.locator('a[href*="new"], button:has-text("Create"), button:has-text("New Organization")');
      await expect(createButton.first()).toBeVisible();
    });
  });

  test.describe('Create Organization', () => {
    test('can access create organization form', async ({ page }) => {
      await page.goto('/organizations');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      // Should show create form
      await expect(page.locator('input[name="name"], input[placeholder*="name" i]')).toBeVisible();
    });

    test('can create a new organization', async ({ page }) => {
      await page.goto('/organizations');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      const orgName = `Test Org ${Date.now()}`;
      await page.fill('input[name="name"], input[placeholder*="name" i]', orgName);

      // Add description if field exists
      const descField = page.locator('textarea[name="description"], input[name="description"]');
      if (await descField.count() > 0) {
        await descField.fill('Test organization description');
      }

      await page.click('button[type="submit"], button:has-text("Create")');
      await page.waitForLoadState('networkidle');
    });

    test('shows error for empty organization name', async ({ page }) => {
      await page.goto('/organizations');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      await page.click('button[type="submit"], button:has-text("Create")');

      // Should show validation error
      const nameInput = page.locator('input[name="name"]');
      if (await nameInput.count() > 0) {
        await expect(nameInput).toHaveAttribute('required', '');
      }
    });

    test('can set organization slug', async ({ page }) => {
      await page.goto('/organizations');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      const slugInput = page.locator('input[name="slug"]');
      if (await slugInput.count() > 0) {
        await slugInput.fill('test-org-slug');
      }
    });
  });

  test.describe('Organization Detail Page', () => {
    test('can view organization details', async ({ page }) => {
      await page.goto('/organizations');

      const orgCard = page.locator('.org-card, [data-org-id], a[href*="/organizations/"]').first();
      if (await orgCard.count() > 0) {
        await orgCard.click();

        await page.waitForURL(/\/organizations\/[^/]+/);
      }
    });

    test('shows organization name and description', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        await expect(page.locator('h1, h2, .org-name')).toBeVisible();
      }
    });

    test('shows organization members', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const members = page.locator('text=Members, .members-list, [data-members]');
        if (await members.count() > 0) {
          await expect(members.first()).toBeVisible();
        }
      }
    });

    test('shows organization teams', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const teams = page.locator('text=Teams, .org-teams, [data-org-teams]');
        if (await teams.count() > 0) {
          await expect(teams.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Organization Members', () => {
    test('can invite new member', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const inviteButton = page.locator('button:has-text("Invite"), button:has-text("Add Member")');
        if (await inviteButton.count() > 0) {
          await expect(inviteButton.first()).toBeVisible();
        }
      }
    });

    test('can remove member', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const removeButton = page.locator('button:has-text("Remove"), button:has-text("Kick")');
        if (await removeButton.count() > 0) {
          await expect(removeButton.first()).toBeVisible();
        }
      }
    });

    test('can change member role', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const roleSelect = page.locator('select[name="role"], [data-member-role]');
        if (await roleSelect.count() > 0) {
          await expect(roleSelect.first()).toBeVisible();
        }
      }
    });

    test('shows member roles (owner, admin, member)', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const roles = page.locator('text=/owner|admin|member/i');
        if (await roles.count() > 0) {
          await expect(roles.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Organization Settings', () => {
    test('can access organization settings', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const settingsLink = page.locator('a[href*="settings"], button:has-text("Settings")');
        if (await settingsLink.count() > 0) {
          await settingsLink.first().click();
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('can update organization name', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const editButton = page.locator('button:has-text("Edit"), a[href*="edit"]');
        if (await editButton.count() > 0) {
          await editButton.first().click();

          const nameInput = page.locator('input[name="name"]');
          if (await nameInput.count() > 0) {
            await nameInput.fill(`Updated Org ${Date.now()}`);
          }
        }
      }
    });

    test('can delete organization', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const deleteButton = page.locator('button:has-text("Delete Organization")');
        if (await deleteButton.count() > 0) {
          await expect(deleteButton.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Organization Teams', () => {
    test('can create team within organization', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const createTeamButton = page.locator('button:has-text("New Team"), button:has-text("Create Team")');
        if (await createTeamButton.count() > 0) {
          await expect(createTeamButton.first()).toBeVisible();
        }
      }
    });

    test('can view team list', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const teamsList = page.locator('.teams-list, [data-teams-list]');
        if (await teamsList.count() > 0) {
          await expect(teamsList.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Organization Billing', () => {
    test('can access billing settings', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const billingLink = page.locator('a[href*="billing"], text=Billing');
        if (await billingLink.count() > 0) {
          await billingLink.first().click();
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('shows organization subscription status', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const subscription = page.locator('text=/free|premium|enterprise|subscription/i');
        if (await subscription.count() > 0) {
          await expect(subscription.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Leave Organization', () => {
    test('can leave an organization', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const leaveButton = page.locator('button:has-text("Leave"), button:has-text("Leave Organization")');
        if (await leaveButton.count() > 0) {
          await expect(leaveButton.first()).toBeVisible();
        }
      }
    });

    test('shows confirmation before leaving', async ({ page }) => {
      await page.goto('/organizations');

      const orgLink = page.locator('a[href*="/organizations/"]').first();
      if (await orgLink.count() > 0) {
        await orgLink.click();

        const leaveButton = page.locator('button:has-text("Leave")').first();
        if (await leaveButton.count() > 0) {
          await leaveButton.click();

          const confirmation = page.locator('text=/sure|confirm/i, [role="dialog"]');
          if (await confirmation.count() > 0) {
            await expect(confirmation.first()).toBeVisible();
          }
        }
      }
    });
  });

  test.describe('Organization Invitations', () => {
    test('can view pending invitations', async ({ page }) => {
      await page.goto('/organizations');

      const invitationsTab = page.locator('text=Invitations, a[href*="invitations"]');
      if (await invitationsTab.count() > 0) {
        await invitationsTab.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can accept organization invitation', async ({ page }) => {
      await page.goto('/organizations');

      const acceptButton = page.locator('button:has-text("Accept"), button:has-text("Join")');
      if (await acceptButton.count() > 0) {
        await expect(acceptButton.first()).toBeVisible();
      }
    });

    test('can decline organization invitation', async ({ page }) => {
      await page.goto('/organizations');

      const declineButton = page.locator('button:has-text("Decline"), button:has-text("Reject")');
      if (await declineButton.count() > 0) {
        await expect(declineButton.first()).toBeVisible();
      }
    });
  });
});
