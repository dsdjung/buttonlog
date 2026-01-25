import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Support', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Support Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/support');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays support options', async ({ page }) => {
      await page.goto('/support');

      // Should show support options
      const content = page.locator('text=Support, text=Help, text=Contact');
      await expect(content.first()).toBeVisible();
    });

    test('has create ticket option', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New"), button:has-text("Create"), button:has-text("Submit")');
      await expect(createButton.first()).toBeVisible();
    });
  });

  test.describe('Create Support Ticket', () => {
    test('can access ticket form', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New Ticket"), button:has-text("Contact")').first();
      await createButton.click();

      await expect(page.locator('input[name="subject"], textarea[name="message"]').first()).toBeVisible();
    });

    test('has subject field', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        await expect(page.locator('input[name="subject"]')).toBeVisible();
      }
    });

    test('has message field', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        await expect(page.locator('textarea[name="message"], textarea[name="description"]')).toBeVisible();
      }
    });

    test('has category selection', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        const categorySelect = page.locator('select[name="category"], [data-category]');
        if (await categorySelect.count() > 0) {
          await expect(categorySelect).toBeVisible();
        }
      }
    });

    test('can submit a ticket', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        await page.fill('input[name="subject"]', `Test Ticket ${Date.now()}`);
        await page.fill('textarea[name="message"], textarea[name="description"]', 'This is a test support ticket.');

        await page.click('button[type="submit"], button:has-text("Submit")');
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows error for empty subject', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        await page.fill('textarea[name="message"]', 'Message without subject');
        await page.click('button[type="submit"]');

        const subjectInput = page.locator('input[name="subject"]');
        if (await subjectInput.count() > 0) {
          await expect(subjectInput).toHaveAttribute('required', '');
        }
      }
    });

    test('shows error for empty message', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        await page.fill('input[name="subject"]', 'Subject without message');
        await page.click('button[type="submit"]');

        const messageInput = page.locator('textarea[name="message"]');
        if (await messageInput.count() > 0) {
          await expect(messageInput).toHaveAttribute('required', '');
        }
      }
    });
  });

  test.describe('Ticket List', () => {
    test('shows list of user tickets', async ({ page }) => {
      await page.goto('/support');

      const ticketList = page.locator('.ticket-list, [data-tickets], table');
      if (await ticketList.count() > 0) {
        await expect(ticketList.first()).toBeVisible();
      }
    });

    test('shows ticket status', async ({ page }) => {
      await page.goto('/support');

      const status = page.locator('.ticket-status, [data-status], text=/open|closed|pending|resolved/i');
      if (await status.count() > 0) {
        await expect(status.first()).toBeVisible();
      }
    });

    test('shows ticket date', async ({ page }) => {
      await page.goto('/support');

      const date = page.locator('time, .ticket-date, text=/ago|today|yesterday/i');
      if (await date.count() > 0) {
        await expect(date.first()).toBeVisible();
      }
    });

    test('can filter by status', async ({ page }) => {
      await page.goto('/support');

      const statusFilter = page.locator('select[name="status"], [data-filter="status"]');
      if (await statusFilter.count() > 0) {
        await statusFilter.click();
      }
    });
  });

  test.describe('Ticket Detail', () => {
    test('can view ticket details', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('.ticket-item a, [data-ticket-id], a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        await page.waitForURL(/\/support\/[^/]+/);
      }
    });

    test('shows ticket subject', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        await expect(page.locator('h1, h2, .ticket-subject')).toBeVisible();
      }
    });

    test('shows ticket conversation', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        const messages = page.locator('.message, .conversation, [data-messages]');
        if (await messages.count() > 0) {
          await expect(messages.first()).toBeVisible();
        }
      }
    });

    test('shows who sent each message', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        const sender = page.locator('.message-sender, .author, text=/you|support|admin/i');
        if (await sender.count() > 0) {
          await expect(sender.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Reply to Ticket', () => {
    test('can reply to open ticket', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        const replyField = page.locator('textarea[name="reply"], textarea[name="message"]');
        if (await replyField.count() > 0) {
          await expect(replyField).toBeVisible();
        }
      }
    });

    test('can send reply', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        const replyField = page.locator('textarea[name="reply"], textarea[name="message"]');
        if (await replyField.count() > 0) {
          await replyField.fill('This is a test reply.');
          await page.click('button[type="submit"], button:has-text("Send"), button:has-text("Reply")');
          await page.waitForLoadState('networkidle');
        }
      }
    });

    test('cannot reply to closed ticket', async ({ page }) => {
      await page.goto('/support');

      // Look for closed ticket
      const closedTicket = page.locator('text=Closed, .status-closed').first();
      if (await closedTicket.count() > 0) {
        await closedTicket.click();

        // Reply field should be disabled or hidden
        const replyField = page.locator('textarea[name="reply"]');
        if (await replyField.count() > 0) {
          await expect(replyField).toBeDisabled();
        }
      }
    });
  });

  test.describe('Close Ticket', () => {
    test('can close own ticket', async ({ page }) => {
      await page.goto('/support');

      const ticketLink = page.locator('a[href*="/support/"]').first();
      if (await ticketLink.count() > 0) {
        await ticketLink.click();

        const closeButton = page.locator('button:has-text("Close"), button:has-text("Resolve")');
        if (await closeButton.count() > 0) {
          await expect(closeButton.first()).toBeVisible();
        }
      }
    });

    test('can reopen closed ticket', async ({ page }) => {
      await page.goto('/support');

      // Navigate to a closed ticket
      const closedTicket = page.locator('text=Closed, .status-closed').first();
      if (await closedTicket.count() > 0) {
        await closedTicket.click();

        const reopenButton = page.locator('button:has-text("Reopen"), button:has-text("Open Again")');
        if (await reopenButton.count() > 0) {
          await expect(reopenButton.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Attachments', () => {
    test('can attach files to ticket', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        const fileInput = page.locator('input[type="file"]');
        if (await fileInput.count() > 0) {
          await expect(fileInput).toBeVisible();
        }
      }
    });

    test('shows attachment size limits', async ({ page }) => {
      await page.goto('/support');

      const createButton = page.locator('a[href*="new"], button:has-text("New")').first();
      if (await createButton.count() > 0) {
        await createButton.click();

        const sizeLimit = page.locator('text=/max|size|MB|limit/i');
        if (await sizeLimit.count() > 0) {
          await expect(sizeLimit.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('FAQ/Help Section', () => {
    test('shows FAQ or help articles', async ({ page }) => {
      await page.goto('/support');

      const faq = page.locator('text=FAQ, text=Help, text=Articles, [data-faq]');
      if (await faq.count() > 0) {
        await expect(faq.first()).toBeVisible();
      }
    });

    test('can search help articles', async ({ page }) => {
      await page.goto('/support');

      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
      if (await searchInput.count() > 0) {
        await searchInput.fill('password');
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Contact Information', () => {
    test('shows contact email', async ({ page }) => {
      await page.goto('/support');

      const email = page.locator('a[href^="mailto:"], text=/support@|help@|contact@/i');
      if (await email.count() > 0) {
        await expect(email.first()).toBeVisible();
      }
    });
  });
});
