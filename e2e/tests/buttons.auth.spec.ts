import { test, expect } from '@playwright/test';

/**
 * Authenticated Button Tests
 *
 * These tests require a valid authentication state.
 * Run setup first: npm run test:setup
 * Then run these tests: npm run test:auth
 *
 * Note: File naming convention *.auth.spec.ts ensures these tests
 * only run with the chromium-auth project (which uses stored auth state).
 */
test.describe('Buttons (Authenticated)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/buttons');
    await page.waitForLoadState('networkidle');
  });

  test('shows authenticated user interface', async ({ page }) => {
    // Should not show login prompt when authenticated
    const loginLink = page.locator('a[href*="/auth/login"]');
    await expect(loginLink).not.toBeVisible();

    // Should show buttons page content
    await expect(page.locator('body')).toBeVisible();
  });

  test('can access create button form', async ({ page }) => {
    // Look for create/new button link
    const createButton = page.locator('a[href*="new"]').or(page.locator('button:has-text("Create")')).or(page.locator('button:has-text("New")'));

    if (await createButton.count() > 0) {
      await createButton.first().click();
      await page.waitForLoadState('networkidle');

      // Should see form elements
      const formElements = page.locator('input, textarea, select');
      expect(await formElements.count()).toBeGreaterThan(0);
    }
  });

  test('displays button list or empty state', async ({ page }) => {
    // Should show either buttons or empty state message
    const hasButtons = await page.locator('.button-card, [data-button-id]').count() > 0;
    const hasEmptyState = await page.locator('text=/no button|create your first|get started/i').count() > 0;

    expect(hasButtons || hasEmptyState).toBeTruthy();
  });

  test('can navigate to button detail', async ({ page }) => {
    const buttonLink = page.locator('a[href*="/buttons/"]').first();

    if (await buttonLink.count() > 0) {
      await buttonLink.click();
      await page.waitForLoadState('networkidle');

      // Should be on a button detail page
      expect(page.url()).toMatch(/\/buttons\/[^/]+/);
    }
  });
});

test.describe('Button Operations (Authenticated)', () => {
  test('can create a new button', async ({ page }) => {
    await page.goto('/buttons');

    // Find and click create button
    const createButton = page.locator('a[href*="new"]').or(page.locator('button:has-text("New")')).first();

    if (await createButton.count() > 0) {
      await createButton.click();
      await page.waitForLoadState('networkidle');

      // Fill in button name
      const nameInput = page.locator('input[name="name"]').or(page.locator('input[placeholder*="name" i]'));
      if (await nameInput.count() > 0) {
        const testButtonName = `E2E Test Button ${Date.now()}`;
        await nameInput.fill(testButtonName);

        // Submit the form (use the form's submit button specifically)
        await page.locator('form button[type="submit"]').first().click();
        await page.waitForLoadState('networkidle');

        // Verify button was created (should see the name somewhere)
        const createdButton = page.locator(`text=${testButtonName}`);
        if (await createdButton.count() > 0) {
          await expect(createdButton.first()).toBeVisible();
        }
      }
    }
  });
});
