import { test, expect } from '@playwright/test';

test.describe('Public Pages', () => {
  test.describe('Home Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/');
      expect(response?.status()).toBeLessThan(400);
    });

    test('has navigation to main features', async ({ page }) => {
      await page.goto('/');

      // Should have links to key pages
      await expect(page.locator('a[href*="login"], a[href*="register"], button:has-text("Get Started")')).toBeVisible();
    });

    test('displays app branding', async ({ page }) => {
      await page.goto('/');

      // Should show ButtonLog branding
      await expect(page.locator('text=ButtonLog')).toBeVisible();
    });
  });

  test.describe('Pricing Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/pricing');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays subscription plans', async ({ page }) => {
      await page.goto('/pricing');

      // Should show Free plan
      await expect(page.locator('text=Free')).toBeVisible();

      // Should show Premium plan
      await expect(page.locator('text=Premium')).toBeVisible();
    });

    test('shows pricing information', async ({ page }) => {
      await page.goto('/pricing');

      // Should display price or "free"
      const priceIndicator = page.locator('text=/\\$\\d+|free|Free/i');
      await expect(priceIndicator.first()).toBeVisible();
    });

    test('has call-to-action buttons', async ({ page }) => {
      await page.goto('/pricing');

      // Should have upgrade/signup buttons
      const ctaButton = page.locator('button:has-text("Get Started"), button:has-text("Subscribe"), button:has-text("Upgrade"), a:has-text("Sign Up")');
      await expect(ctaButton.first()).toBeVisible();
    });

    test('displays feature comparison', async ({ page }) => {
      await page.goto('/pricing');

      // Should list features for each plan
      const features = page.locator('text=/button|friend|export|notification/i');
      expect(await features.count()).toBeGreaterThan(0);
    });
  });

  test.describe('About Page', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/about');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays app information', async ({ page }) => {
      await page.goto('/about');

      // Should have page title
      await expect(page.locator('h1, h2').first()).toContainText(/about/i);

      // Should mention ButtonLog
      await expect(page.locator('text=ButtonLog')).toBeVisible();
    });

    test('shows version information', async ({ page }) => {
      await page.goto('/about');

      // Should display version
      const versionText = page.locator('text=/version|v\\d+\\.\\d+/i');
      await expect(versionText.first()).toBeVisible();
    });
  });

  test.describe('Terms of Service', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/terms');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays terms content', async ({ page }) => {
      await page.goto('/terms');

      // Should have title
      await expect(page.locator('h1, h2').first()).toContainText(/terms/i);

      // Should have substantive legal content
      const content = await page.locator('body').textContent();
      expect(content?.length).toBeGreaterThan(500);
    });

    test('contains required legal sections', async ({ page }) => {
      await page.goto('/terms');

      // Check for common ToS sections (case insensitive)
      const body = page.locator('body');
      await expect(body).toContainText(/service|agreement|use|account|termination/i);
    });
  });

  test.describe('Privacy Policy', () => {
    test('loads successfully', async ({ page }) => {
      const response = await page.goto('/privacy');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays privacy content', async ({ page }) => {
      await page.goto('/privacy');

      // Should have title
      await expect(page.locator('h1, h2').first()).toContainText(/privacy/i);

      // Should have substantive content
      const content = await page.locator('body').textContent();
      expect(content?.length).toBeGreaterThan(500);
    });

    test('contains required privacy sections', async ({ page }) => {
      await page.goto('/privacy');

      // Check for common privacy policy sections
      const body = page.locator('body');
      await expect(body).toContainText(/data|information|collect|personal/i);
    });
  });

  test.describe('Health Check', () => {
    test('returns healthy status', async ({ page }) => {
      const response = await page.goto('/health');
      expect(response?.status()).toBe(200);
    });
  });
});
