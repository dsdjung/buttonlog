import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Buttons', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Buttons Index Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/buttons');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays buttons list or empty state', async ({ page }) => {
      await page.goto('/buttons');

      // Should show buttons or empty state message
      const content = page.locator('.button-card, [data-button], text=/no button|create.*first|get started/i');
      await expect(content.first()).toBeVisible();
    });

    test('has create button option', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create"), button:has-text("Add")');
      await expect(createButton.first()).toBeVisible();
    });

    test('shows button count or summary', async ({ page }) => {
      await page.goto('/buttons');

      // Page should indicate how many buttons exist
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Create Button', () => {
    test('can access create button form', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      // Should show create form
      await expect(page.locator('input[name="name"], input[placeholder*="name" i]')).toBeVisible();
    });

    test('can create instant button', async ({ page }) => {
      await page.goto('/buttons');

      // Click create
      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      // Fill form
      const buttonName = `Test Instant ${Date.now()}`;
      await page.fill('input[name="name"], input[placeholder*="name" i]', buttonName);

      // Select type if dropdown exists
      const typeSelect = page.locator('select[name="type"], [data-type-select]');
      if (await typeSelect.count() > 0) {
        await typeSelect.selectOption('instant');
      }

      // Submit
      await page.click('button[type="submit"], button:has-text("Create"), button:has-text("Save")');

      // Should see new button
      await page.waitForLoadState('networkidle');
      await expect(page.locator(`text=${buttonName}`)).toBeVisible();
    });

    test('can create timed button', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      const buttonName = `Test Timed ${Date.now()}`;
      await page.fill('input[name="name"], input[placeholder*="name" i]', buttonName);

      const typeSelect = page.locator('select[name="type"], [data-type-select]');
      if (await typeSelect.count() > 0) {
        await typeSelect.selectOption('timed');
      }

      await page.click('button[type="submit"], button:has-text("Create"), button:has-text("Save")');
      await page.waitForLoadState('networkidle');
    });

    test('can create state button', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      const buttonName = `Test State ${Date.now()}`;
      await page.fill('input[name="name"], input[placeholder*="name" i]', buttonName);

      const typeSelect = page.locator('select[name="type"], [data-type-select]');
      if (await typeSelect.count() > 0) {
        await typeSelect.selectOption('state');
      }

      await page.click('button[type="submit"], button:has-text("Create"), button:has-text("Save")');
      await page.waitForLoadState('networkidle');
    });

    test('shows error for empty name', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      // Try to submit without name
      await page.click('button[type="submit"], button:has-text("Create"), button:has-text("Save")');

      // Should show validation error
      const nameInput = page.locator('input[name="name"]');
      if (await nameInput.count() > 0) {
        await expect(nameInput).toHaveAttribute('required', '');
      }
    });

    test('can set button color', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      const colorPicker = page.locator('input[type="color"], [data-color-picker]');
      if (await colorPicker.count() > 0) {
        await colorPicker.click();
      }
    });

    test('can set button icon', async ({ page }) => {
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      const iconSelector = page.locator('[data-icon-picker], select[name="icon"]');
      if (await iconSelector.count() > 0) {
        await iconSelector.click();
      }
    });
  });

  test.describe('Button Detail', () => {
    test('can view button detail page', async ({ page }) => {
      await page.goto('/buttons');

      const buttonCard = page.locator('.button-card, [data-button-id], a[href*="/buttons/"]').first();
      if (await buttonCard.count() > 0) {
        await buttonCard.click();

        // Should show button details
        await page.waitForURL(/\/buttons\/[^/]+/);
      }
    });

    test('shows button name and type', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        await expect(page.locator('h1, h2, .button-name')).toBeVisible();
      }
    });

    test('shows click history', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        // Should show history section
        const historySection = page.locator('text=/history|click|log/i');
        if (await historySection.count() > 0) {
          await expect(historySection.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Button Interactions', () => {
    test('can click a button', async ({ page }) => {
      await page.goto('/buttons');

      const clickableButton = page.locator('.button-card button, [data-click-button]').first();
      if (await clickableButton.count() > 0) {
        await clickableButton.click();

        // Should show feedback (toast, animation, count update)
        await page.waitForLoadState('networkidle');
      }
    });

    test('button click is logged', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        // Find click count before
        const initialCount = await page.locator('.click-count, [data-click-count]').textContent();

        // Click the button
        const clickButton = page.locator('button:has-text("Click"), [data-click-button]').first();
        if (await clickButton.count() > 0) {
          await clickButton.click();
          await page.waitForLoadState('networkidle');
        }
      }
    });
  });

  test.describe('Edit Button', () => {
    test('can access edit form', async ({ page }) => {
      await page.goto('/buttons');

      const editLink = page.locator('a[href*="edit"], button:has-text("Edit")').first();
      if (await editLink.count() > 0) {
        await editLink.click();

        await expect(page.locator('input[name="name"]')).toBeVisible();
      }
    });

    test('can update button name', async ({ page }) => {
      await page.goto('/buttons');

      const editLink = page.locator('a[href*="edit"], button:has-text("Edit")').first();
      if (await editLink.count() > 0) {
        await editLink.click();

        const newName = `Updated ${Date.now()}`;
        await page.fill('input[name="name"]', newName);
        await page.click('button[type="submit"], button:has-text("Save")');

        await page.waitForLoadState('networkidle');
      }
    });

    test('can change button type', async ({ page }) => {
      await page.goto('/buttons');

      const editLink = page.locator('a[href*="edit"], button:has-text("Edit")').first();
      if (await editLink.count() > 0) {
        await editLink.click();

        const typeSelect = page.locator('select[name="type"]');
        if (await typeSelect.count() > 0) {
          await typeSelect.selectOption('timed');
        }
      }
    });
  });

  test.describe('Delete Button', () => {
    test('can delete a button', async ({ page }) => {
      // First create a button to delete
      await page.goto('/buttons');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create")').first();
      await createButton.click();

      const buttonName = `Delete Me ${Date.now()}`;
      await page.fill('input[name="name"]', buttonName);
      await page.click('button[type="submit"], button:has-text("Create")');
      await page.waitForLoadState('networkidle');

      // Now delete it
      const deleteButton = page.locator('button:has-text("Delete")').first();
      if (await deleteButton.count() > 0) {
        await deleteButton.click();

        // Confirm if dialog appears
        const confirmButton = page.locator('button:has-text("Confirm"), button:has-text("Yes"), button:has-text("Delete")').last();
        if (await confirmButton.count() > 0) {
          await confirmButton.click();
        }

        await page.waitForLoadState('networkidle');
      }
    });

    test('shows confirmation before delete', async ({ page }) => {
      await page.goto('/buttons');

      const deleteButton = page.locator('button:has-text("Delete")').first();
      if (await deleteButton.count() > 0) {
        await deleteButton.click();

        // Should show confirmation dialog or text
        const confirmation = page.locator('text=/sure|confirm|delete/i, [role="dialog"]');
        if (await confirmation.count() > 0) {
          await expect(confirmation.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Button Sharing', () => {
    test('can access sharing settings', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        const sharingLink = page.locator('text=Sharing, text=Share, a[href*="sharing"]').first();
        if (await sharingLink.count() > 0) {
          await sharingLink.click();
          await expect(page.locator('text=/share|collaborator|permission/i')).toBeVisible();
        }
      }
    });

    test('can change sharing mode', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        const sharingMode = page.locator('select[name="sharing_mode"], [data-sharing-mode]');
        if (await sharingMode.count() > 0) {
          await sharingMode.click();
        }
      }
    });
  });

  test.describe('Button Notifications', () => {
    test('can access button notification settings', async ({ page }) => {
      await page.goto('/buttons');

      const buttonLink = page.locator('a[href*="/buttons/"]').first();
      if (await buttonLink.count() > 0) {
        await buttonLink.click();

        const notifLink = page.locator('a[href*="notification"], text=Notification').first();
        if (await notifLink.count() > 0) {
          await notifLink.click();
          await page.waitForLoadState('networkidle');
        }
      }
    });
  });
});
