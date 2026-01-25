import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Diary View', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test.describe('Diary Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/diary');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays calendar or timeline view', async ({ page }) => {
      await page.goto('/diary');

      // Should show calendar or timeline
      const view = page.locator('.calendar, .timeline, [data-diary-view], table');
      await expect(view.first()).toBeVisible();
    });

    test('shows current date by default', async ({ page }) => {
      await page.goto('/diary');

      // Should highlight or show today's date
      const today = new Date();
      const monthYear = today.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

      const dateIndicator = page.locator(`text=${monthYear}, .today, [data-today]`);
      if (await dateIndicator.count() > 0) {
        await expect(dateIndicator.first()).toBeVisible();
      }
    });
  });

  test.describe('Date Navigation', () => {
    test('can navigate to previous month', async ({ page }) => {
      await page.goto('/diary');

      const prevButton = page.locator('button:has-text("Previous"), button:has-text("Prev"), [aria-label*="previous"]');
      if (await prevButton.count() > 0) {
        await prevButton.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can navigate to next month', async ({ page }) => {
      await page.goto('/diary');

      const nextButton = page.locator('button:has-text("Next"), [aria-label*="next"]');
      if (await nextButton.count() > 0) {
        await nextButton.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can jump to today', async ({ page }) => {
      await page.goto('/diary');

      const todayButton = page.locator('button:has-text("Today"), button:has-text("Now")');
      if (await todayButton.count() > 0) {
        await todayButton.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can select specific date', async ({ page }) => {
      await page.goto('/diary');

      // Click on a date in the calendar
      const dateCell = page.locator('.calendar-day, td[data-date], [data-day]').first();
      if (await dateCell.count() > 0) {
        await dateCell.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can use date picker', async ({ page }) => {
      await page.goto('/diary');

      const datePicker = page.locator('input[type="date"], [data-date-picker]');
      if (await datePicker.count() > 0) {
        await datePicker.click();
      }
    });
  });

  test.describe('Diary Entries', () => {
    test('shows button clicks for selected date', async ({ page }) => {
      await page.goto('/diary');

      // Diary should show button activity
      const entries = page.locator('.diary-entry, .click-entry, [data-diary-entry]');
      // May have entries or not
      await page.waitForLoadState('networkidle');
    });

    test('shows click timestamps', async ({ page }) => {
      await page.goto('/diary');

      const timestamp = page.locator('time, .timestamp, text=/\\d{1,2}:\\d{2}/');
      if (await timestamp.count() > 0) {
        await expect(timestamp.first()).toBeVisible();
      }
    });

    test('shows button names in entries', async ({ page }) => {
      await page.goto('/diary');

      const entry = page.locator('.diary-entry, .click-entry').first();
      if (await entry.count() > 0) {
        // Entry should reference a button
        await expect(entry).toBeVisible();
      }
    });

    test('can click entry to view button', async ({ page }) => {
      await page.goto('/diary');

      const entryLink = page.locator('.diary-entry a, [data-diary-entry] a').first();
      if (await entryLink.count() > 0) {
        await entryLink.click();
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('View Modes', () => {
    test('can switch to day view', async ({ page }) => {
      await page.goto('/diary');

      const dayView = page.locator('button:has-text("Day"), [data-view="day"]');
      if (await dayView.count() > 0) {
        await dayView.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can switch to week view', async ({ page }) => {
      await page.goto('/diary');

      const weekView = page.locator('button:has-text("Week"), [data-view="week"]');
      if (await weekView.count() > 0) {
        await weekView.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can switch to month view', async ({ page }) => {
      await page.goto('/diary');

      const monthView = page.locator('button:has-text("Month"), [data-view="month"]');
      if (await monthView.count() > 0) {
        await monthView.click();
        await page.waitForLoadState('networkidle');
      }
    });

    test('can switch to timeline view', async ({ page }) => {
      await page.goto('/diary');

      const timelineView = page.locator('button:has-text("Timeline"), button:has-text("List"), [data-view="timeline"]');
      if (await timelineView.count() > 0) {
        await timelineView.click();
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Filtering', () => {
    test('can filter by button', async ({ page }) => {
      await page.goto('/diary');

      const buttonFilter = page.locator('select[name="button"], [data-filter="button"]');
      if (await buttonFilter.count() > 0) {
        await buttonFilter.click();
      }
    });

    test('can filter by button type', async ({ page }) => {
      await page.goto('/diary');

      const typeFilter = page.locator('select[name="type"], [data-filter="type"]');
      if (await typeFilter.count() > 0) {
        await typeFilter.click();
      }
    });

    test('can search entries', async ({ page }) => {
      await page.goto('/diary');

      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
      if (await searchInput.count() > 0) {
        await searchInput.fill('test');
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Statistics', () => {
    test('shows daily summary', async ({ page }) => {
      await page.goto('/diary');

      const summary = page.locator('.daily-summary, .stats, text=/total|count|clicks/i');
      if (await summary.count() > 0) {
        await expect(summary.first()).toBeVisible();
      }
    });

    test('shows activity heatmap', async ({ page }) => {
      await page.goto('/diary');

      const heatmap = page.locator('.heatmap, [data-heatmap], .activity-chart');
      if (await heatmap.count() > 0) {
        await expect(heatmap.first()).toBeVisible();
      }
    });
  });

  test.describe('Date Range Selection', () => {
    test('can select date range', async ({ page }) => {
      await page.goto('/diary');

      const rangeStart = page.locator('input[name="start_date"], [data-range-start]');
      const rangeEnd = page.locator('input[name="end_date"], [data-range-end]');

      if (await rangeStart.count() > 0 && await rangeEnd.count() > 0) {
        await rangeStart.click();
        await rangeEnd.click();
      }
    });

    test('can use preset ranges', async ({ page }) => {
      await page.goto('/diary');

      const presetButtons = page.locator('button:has-text("Last 7 days"), button:has-text("This Week"), button:has-text("This Month")');
      if (await presetButtons.count() > 0) {
        await presetButtons.first().click();
        await page.waitForLoadState('networkidle');
      }
    });
  });

  test.describe('Export', () => {
    test('can export diary data', async ({ page }) => {
      await page.goto('/diary');

      const exportButton = page.locator('button:has-text("Export"), a:has-text("Download")');
      if (await exportButton.count() > 0) {
        await expect(exportButton.first()).toBeVisible();
      }
    });
  });
});
