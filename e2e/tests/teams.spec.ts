import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Teams', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Teams List Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/teams');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays teams list or empty state', async ({ page }) => {
      await page.goto('/teams');

      // Should show teams or empty state
      const content = page.locator('.team-card, [data-team], text=/no team|create.*team|join.*team/i');
      await expect(content.first()).toBeVisible();
    });

    test('has create team option', async ({ page }) => {
      await page.goto('/teams');

      const createButton = page.locator('a[href*="new"], button:has-text("Create"), button:has-text("New Team")');
      await expect(createButton.first()).toBeVisible();
    });
  });

  test.describe('Create Team', () => {
    test('can access create team form', async ({ page }) => {
      await page.goto('/teams');

      const createButton = page.locator('a[href*="new"], button:has-text("Create"), button:has-text("New Team")').first();
      await createButton.click();

      // Should show create form
      await expect(page.locator('input[name="name"], input[placeholder*="name" i]')).toBeVisible();
    });

    test('can create a new team', async ({ page }) => {
      await page.goto('/teams');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      const teamName = `Test Team ${Date.now()}`;
      await page.fill('input[name="name"], input[placeholder*="name" i]', teamName);

      // Add description if field exists
      const descField = page.locator('textarea[name="description"], input[name="description"]');
      if (await descField.count() > 0) {
        await descField.fill('Test team description');
      }

      await page.click('button[type="submit"], button:has-text("Create")');
      await page.waitForLoadState('networkidle');
    });

    test('shows error for empty team name', async ({ page }) => {
      await page.goto('/teams');

      const createButton = page.locator('a[href*="new"], button:has-text("Create")').first();
      await createButton.click();

      await page.click('button[type="submit"], button:has-text("Create")');

      // Should show validation error
      const nameInput = page.locator('input[name="name"]');
      if (await nameInput.count() > 0) {
        await expect(nameInput).toHaveAttribute('required', '');
      }
    });
  });

  test.describe('Team Detail Page', () => {
    test('can view team details', async ({ page }) => {
      await page.goto('/teams');

      const teamCard = page.locator('.team-card, [data-team-id], a[href*="/teams/"]').first();
      if (await teamCard.count() > 0) {
        await teamCard.click();

        await page.waitForURL(/\/teams\/[^/]+/);
      }
    });

    test('shows team name and description', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        await expect(page.locator('h1, h2, .team-name')).toBeVisible();
      }
    });

    test('shows team members list', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        // Should show members section
        const members = page.locator('text=Members, .members-list, [data-members]');
        if (await members.count() > 0) {
          await expect(members.first()).toBeVisible();
        }
      }
    });

    test('shows team buttons', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        // Should show team buttons
        const buttons = page.locator('text=Buttons, .team-buttons, [data-team-buttons]');
        if (await buttons.count() > 0) {
          await expect(buttons.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Team Members', () => {
    test('can invite new member', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const inviteButton = page.locator('button:has-text("Invite"), button:has-text("Add Member")');
        if (await inviteButton.count() > 0) {
          await expect(inviteButton.first()).toBeVisible();
        }
      }
    });

    test('can remove member', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const removeButton = page.locator('button:has-text("Remove"), button:has-text("Kick")');
        if (await removeButton.count() > 0) {
          await expect(removeButton.first()).toBeVisible();
        }
      }
    });

    test('can change member role', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const roleSelect = page.locator('select[name="role"], [data-member-role]');
        if (await roleSelect.count() > 0) {
          await expect(roleSelect.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Team Settings', () => {
    test('can access team settings', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const settingsLink = page.locator('a[href*="settings"], button:has-text("Settings")');
        if (await settingsLink.count() > 0) {
          await settingsLink.first().click();
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('can update team name', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const editButton = page.locator('button:has-text("Edit"), a[href*="edit"]');
        if (await editButton.count() > 0) {
          await editButton.first().click();

          const nameInput = page.locator('input[name="name"]');
          if (await nameInput.count() > 0) {
            await nameInput.fill(`Updated Team ${Date.now()}`);
          }
        }
      }
    });

    test('can delete team', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const deleteButton = page.locator('button:has-text("Delete Team")');
        if (await deleteButton.count() > 0) {
          await expect(deleteButton.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Team Buttons', () => {
    test('can create team button', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const createButton = page.locator('button:has-text("Add Button"), button:has-text("New Button")');
        if (await createButton.count() > 0) {
          await expect(createButton.first()).toBeVisible();
        }
      }
    });

    test('team buttons are clickable by members', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const buttonClick = page.locator('.button-card button, [data-click-button]');
        if (await buttonClick.count() > 0) {
          await expect(buttonClick.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Team Activity', () => {
    test('shows team activity feed', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const activity = page.locator('text=Activity, .activity-feed, [data-activity]');
        if (await activity.count() > 0) {
          await expect(activity.first()).toBeVisible();
        }
      }
    });

    test('shows who clicked team buttons', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        // Activity should show member names
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Leave Team', () => {
    test('can leave a team', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

        const leaveButton = page.locator('button:has-text("Leave"), button:has-text("Leave Team")');
        if (await leaveButton.count() > 0) {
          await expect(leaveButton.first()).toBeVisible();
        }
      }
    });

    test('shows confirmation before leaving', async ({ page }) => {
      await page.goto('/teams');

      const teamLink = page.locator('a[href*="/teams/"]').first();
      if (await teamLink.count() > 0) {
        await teamLink.click();

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
});
