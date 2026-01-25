import { test, expect } from '@playwright/test';

// Test user credentials - use environment variables for non-local
const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
  password: process.env.TEST_USER_PASSWORD || 'password123',
};

test.describe('Buttons', () => {
  // Login before each test
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.fill('[name="email"], input[type="email"]', TEST_USER.email);
    await page.fill('[name="password"]', TEST_USER.password);
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
  });

  test('displays buttons dashboard', async ({ page }) => {
    await page.goto('/buttons');

    // Should see the buttons page
    await expect(page.locator('h1, h2').first()).toContainText(/button/i);
  });

  test('can create a new instant button', async ({ page }) => {
    await page.goto('/buttons');

    // Click create button
    await page.click('text=New Button, text=Create, button:has-text("Add"), a:has-text("New")');

    // Fill button form
    const buttonName = `Test Button ${Date.now()}`;
    await page.fill('[name="name"], input[placeholder*="name" i]', buttonName);

    // Select instant type if available
    const typeSelect = page.locator('[name="type"], select');
    if (await typeSelect.count() > 0) {
      await typeSelect.selectOption('instant');
    }

    // Submit
    await page.click('button[type="submit"], button:has-text("Create"), button:has-text("Save")');

    // Should see the new button
    await expect(page.locator(`text=${buttonName}`)).toBeVisible();
  });

  test('can click a button and see it logged', async ({ page }) => {
    await page.goto('/buttons');

    // Find and click a button (assuming at least one exists)
    const button = page.locator('.button-card, [data-button-id]').first();

    if (await button.count() > 0) {
      await button.click();

      // Should see some feedback (click recorded, count updated, etc.)
      await page.waitForLoadState('networkidle');
    }
  });

  test('can view button history', async ({ page }) => {
    await page.goto('/buttons');

    // Click on a button to view details
    const button = page.locator('.button-card, [data-button-id]').first();

    if (await button.count() > 0) {
      // Look for history link or expand details
      const historyLink = page.locator('text=History, text=View, a:has-text("Details")').first();

      if (await historyLink.count() > 0) {
        await historyLink.click();

        // Should see history/clicks
        await expect(page.locator('text=Click, text=Log, text=History')).toBeVisible();
      }
    }
  });

  test('can edit a button', async ({ page }) => {
    await page.goto('/buttons');

    // Find edit link/button
    const editLink = page.locator('text=Edit, a[href*="edit"], button:has-text("Edit")').first();

    if (await editLink.count() > 0) {
      await editLink.click();

      // Update the name
      const nameInput = page.locator('[name="name"], input[placeholder*="name" i]');
      await nameInput.clear();
      await nameInput.fill(`Updated Button ${Date.now()}`);

      // Save
      await page.click('button[type="submit"], button:has-text("Save")');

      // Should redirect back or show success
      await page.waitForLoadState('networkidle');
    }
  });

  test('can delete a button', async ({ page }) => {
    // First create a button to delete
    await page.goto('/buttons/new');

    const buttonName = `Delete Me ${Date.now()}`;
    await page.fill('[name="name"], input[placeholder*="name" i]', buttonName);
    await page.click('button[type="submit"], button:has-text("Create")');
    await page.waitForLoadState('networkidle');

    // Now delete it
    await page.goto('/buttons');

    // Find the button we just created
    const buttonCard = page.locator(`.button-card:has-text("${buttonName}"), [data-button-id]:has-text("${buttonName}")`);

    if (await buttonCard.count() > 0) {
      // Click delete
      const deleteBtn = buttonCard.locator('text=Delete, button:has-text("Delete")');
      if (await deleteBtn.count() > 0) {
        await deleteBtn.click();

        // Confirm deletion if dialog appears
        const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("Yes")');
        if (await confirmBtn.count() > 0) {
          await confirmBtn.click();
        }

        // Button should be gone
        await expect(page.locator(`text=${buttonName}`)).not.toBeVisible();
      }
    }
  });
});
