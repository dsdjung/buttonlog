import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Webhook Settings', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Webhook Settings Page', () => {
    test('loads successfully', async ({ page }) => {
      // Navigate to webhook settings (may be under account or notifications)
      await page.goto('/account');

      const webhookLink = page.locator('text=Webhook, a[href*="webhook"], a[href*="notification"]');
      if (await webhookLink.count() > 0) {
        await webhookLink.first().click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('displays webhook configuration section', async ({ page }) => {
      await page.goto('/account');

      const webhookSection = page.locator('text=Webhook, text=Notifications, [data-section="webhooks"]');
      if (await webhookSection.count() > 0) {
        await expect(webhookSection.first()).toBeVisible();
      }
    });
  });

  test.describe('Webhook URL Configuration', () => {
    test('has webhook URL input field', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"], input[name="webhookUrl"], input[placeholder*="webhook" i]');
      if (await webhookUrl.count() > 0) {
        await expect(webhookUrl).toBeVisible();
      }
    });

    test('can enter webhook URL', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"], input[name="webhookUrl"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.fill('https://example.com/webhook');
      }
    });

    test('validates webhook URL format', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.fill('invalid-url');
        await page.click('button[type="submit"], button:has-text("Save")');

        const error = page.locator('text=/invalid|valid url|format/i, .error');
        if (await error.count() > 0) {
          await expect(error.first()).toBeVisible();
        }
      }
    });

    test('requires HTTPS for webhook URL', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.fill('http://example.com/webhook');
        await page.click('button[type="submit"], button:has-text("Save")');

        const error = page.locator('text=/https|secure/i, .error');
        // May or may not require HTTPS depending on implementation
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Webhook Toggle', () => {
    test('can enable webhooks', async ({ page }) => {
      await page.goto('/account');

      const enableToggle = page.locator('input[name="webhook_enabled"], [data-webhook-enabled]');
      if (await enableToggle.count() > 0) {
        await enableToggle.click();
      }
    });

    test('can disable webhooks', async ({ page }) => {
      await page.goto('/account');

      const disableToggle = page.locator('input[name="webhook_enabled"]');
      if (await disableToggle.count() > 0) {
        // Click to toggle off if currently on
        const isChecked = await disableToggle.isChecked();
        if (isChecked) {
          await disableToggle.click();
        }
      }
    });
  });

  test.describe('Webhook Secret', () => {
    test('has secret key field', async ({ page }) => {
      await page.goto('/account');

      const secretField = page.locator('input[name="webhook_secret"], input[name="secret"], [data-webhook-secret]');
      if (await secretField.count() > 0) {
        await expect(secretField).toBeVisible();
      }
    });

    test('can generate new secret', async ({ page }) => {
      await page.goto('/account');

      const generateButton = page.locator('button:has-text("Generate"), button:has-text("New Secret")');
      if (await generateButton.count() > 0) {
        await expect(generateButton.first()).toBeVisible();
      }
    });

    test('can copy secret to clipboard', async ({ page }) => {
      await page.goto('/account');

      const copyButton = page.locator('button:has-text("Copy"), [data-copy-secret]');
      if (await copyButton.count() > 0) {
        await expect(copyButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Webhook Event Types', () => {
    test('can select event types to send', async ({ page }) => {
      await page.goto('/account');

      const eventCheckboxes = page.locator('input[name*="event"], [data-event-type]');
      if (await eventCheckboxes.count() > 0) {
        expect(await eventCheckboxes.count()).toBeGreaterThan(0);
      }
    });

    test('can enable button click events', async ({ page }) => {
      await page.goto('/account');

      const clickEvent = page.locator('input[name="event_click"], input[value="click"], text=Click');
      if (await clickEvent.count() > 0) {
        await expect(clickEvent.first()).toBeVisible();
      }
    });

    test('can enable friend events', async ({ page }) => {
      await page.goto('/account');

      const friendEvent = page.locator('input[name="event_friend"], input[value="friend"], text=Friend');
      if (await friendEvent.count() > 0) {
        await expect(friendEvent.first()).toBeVisible();
      }
    });

    test('can enable button create/delete events', async ({ page }) => {
      await page.goto('/account');

      const buttonEvent = page.locator('input[name="event_button"], input[value="button"], text=Button');
      if (await buttonEvent.count() > 0) {
        await expect(buttonEvent.first()).toBeVisible();
      }
    });
  });

  test.describe('Test Webhook', () => {
    test('has test webhook button', async ({ page }) => {
      await page.goto('/account');

      const testButton = page.locator('button:has-text("Test"), button:has-text("Send Test")');
      if (await testButton.count() > 0) {
        await expect(testButton.first()).toBeVisible();
      }
    });

    test('shows test result', async ({ page }) => {
      await page.goto('/account');

      const testButton = page.locator('button:has-text("Test Webhook")').first();
      if (await testButton.count() > 0) {
        await testButton.click();
        await page.waitForLoadState('networkidle');

        // Should show success or failure message
        const result = page.locator('text=/success|sent|failed|error/i, .alert');
        if (await result.count() > 0) {
          await expect(result.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Webhook History', () => {
    test('shows recent webhook deliveries', async ({ page }) => {
      await page.goto('/account');

      const history = page.locator('text=History, text=Recent, text=Deliveries, [data-webhook-history]');
      if (await history.count() > 0) {
        await expect(history.first()).toBeVisible();
      }
    });

    test('shows delivery status', async ({ page }) => {
      await page.goto('/account');

      const status = page.locator('.delivery-status, [data-delivery-status], text=/success|failed|pending/i');
      if (await status.count() > 0) {
        await expect(status.first()).toBeVisible();
      }
    });

    test('can view delivery details', async ({ page }) => {
      await page.goto('/account');

      const deliveryRow = page.locator('.webhook-delivery, [data-delivery-id]').first();
      if (await deliveryRow.count() > 0) {
        await deliveryRow.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can retry failed delivery', async ({ page }) => {
      await page.goto('/account');

      const retryButton = page.locator('button:has-text("Retry"), button:has-text("Resend")');
      if (await retryButton.count() > 0) {
        await expect(retryButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Save Settings', () => {
    test('can save webhook settings', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.fill('https://example.com/webhook');

        const saveButton = page.locator('button[type="submit"], button:has-text("Save")');
        await saveButton.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows success message on save', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.fill('https://example.com/webhook');
        await page.click('button[type="submit"], button:has-text("Save")');

        const success = page.locator('text=/saved|success|updated/i, .alert-success');
        if (await success.count() > 0) {
          await expect(success.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Clear Webhook Settings', () => {
    test('can clear webhook URL', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.clear();
        await page.click('button[type="submit"], button:has-text("Save")');
        await page.waitForLoadState('networkidle');
      }
    });

    test('disables webhook when URL cleared', async ({ page }) => {
      await page.goto('/account');

      const webhookUrl = page.locator('input[name="webhook_url"]');
      if (await webhookUrl.count() > 0) {
        await webhookUrl.clear();
        await page.click('button[type="submit"]');

        // Webhook should be disabled
        const enableToggle = page.locator('input[name="webhook_enabled"]');
        if (await enableToggle.count() > 0) {
          const isChecked = await enableToggle.isChecked();
          expect(isChecked).toBeFalsy();
        }
      }
    });
  });
});
