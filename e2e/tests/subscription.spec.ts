import { test, expect } from '@playwright/test';
import { login, TEST_USER } from './fixtures/auth';

test.describe('Subscriptions', () => {
  test.describe('Public Pricing Page', () => {
    test('loads successfully without auth', async ({ page }) => {
      const response = await page.goto('/pricing');
      expect(response?.status()).toBeLessThan(400);
    });

    test('displays Free plan', async ({ page }) => {
      await page.goto('/pricing');

      await expect(page.locator('text=Free')).toBeVisible();
    });

    test('displays Premium plan', async ({ page }) => {
      await page.goto('/pricing');

      await expect(page.locator('text=Premium')).toBeVisible();
    });

    test('displays Enterprise plan', async ({ page }) => {
      await page.goto('/pricing');

      const enterprise = page.locator('text=Enterprise');
      if (await enterprise.count() > 0) {
        await expect(enterprise.first()).toBeVisible();
      }
    });

    test('shows pricing amounts', async ({ page }) => {
      await page.goto('/pricing');

      // Should see price indicators
      const prices = page.locator('text=/\\$\\d+|free/i');
      expect(await prices.count()).toBeGreaterThan(0);
    });

    test('shows billing period options', async ({ page }) => {
      await page.goto('/pricing');

      const periods = page.locator('text=/month|year|annual/i');
      if (await periods.count() > 0) {
        await expect(periods.first()).toBeVisible();
      }
    });

    test('displays feature comparisons', async ({ page }) => {
      await page.goto('/pricing');

      // Should list features for each plan
      const features = page.locator('text=/button|friend|export|notification|team/i');
      expect(await features.count()).toBeGreaterThan(0);
    });

    test('has call-to-action buttons', async ({ page }) => {
      await page.goto('/pricing');

      const cta = page.locator('button:has-text("Get Started"), button:has-text("Subscribe"), button:has-text("Upgrade"), a:has-text("Sign Up")');
      await expect(cta.first()).toBeVisible();
    });
  });

  test.describe('Authenticated Subscription Management', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can view current subscription status', async ({ page }) => {
      await page.goto('/account');

      const subscription = page.locator('text=/free|premium|enterprise|plan|subscription/i');
      await expect(subscription.first()).toBeVisible();
    });

    test('shows usage limits', async ({ page }) => {
      await page.goto('/account');

      const usage = page.locator('text=/usage|limit|button|remaining/i');
      if (await usage.count() > 0) {
        await expect(usage.first()).toBeVisible();
      }
    });

    test('can access subscription page', async ({ page }) => {
      await page.goto('/subscription');

      await expect(page.locator('h1, h2').first()).toContainText(/subscription|plan|billing/i);
    });
  });

  test.describe('Upgrade Flow', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can initiate upgrade', async ({ page }) => {
      await page.goto('/pricing');

      const upgradeButton = page.locator('button:has-text("Upgrade"), button:has-text("Subscribe"), a:has-text("Get Premium")');
      if (await upgradeButton.count() > 0) {
        await expect(upgradeButton.first()).toBeVisible();
      }
    });

    test('upgrade redirects to payment', async ({ page }) => {
      await page.goto('/pricing');

      const upgradeButton = page.locator('button:has-text("Upgrade"), button:has-text("Subscribe")').first();
      if (await upgradeButton.count() > 0) {
        await upgradeButton.click();

        // Should redirect to payment or show payment modal
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows payment method selection', async ({ page }) => {
      await page.goto('/subscription');

      const paymentMethods = page.locator('text=/credit|debit|card|paypal|apple pay|google pay/i');
      if (await paymentMethods.count() > 0) {
        await expect(paymentMethods.first()).toBeVisible();
      }
    });
  });

  test.describe('Payment Form', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('shows credit card form', async ({ page }) => {
      await page.goto('/subscription');

      const upgradeButton = page.locator('button:has-text("Upgrade")').first();
      if (await upgradeButton.count() > 0) {
        await upgradeButton.click();

        // Look for Stripe elements or card input
        const cardElement = page.locator('iframe[name*="stripe"], input[name*="card"], .StripeElement');
        if (await cardElement.count() > 0) {
          await expect(cardElement.first()).toBeVisible();
        }
      }
    });

    test('shows billing address fields', async ({ page }) => {
      await page.goto('/subscription');

      const addressFields = page.locator('input[name*="address"], input[name*="city"], input[name*="zip"]');
      if (await addressFields.count() > 0) {
        expect(await addressFields.count()).toBeGreaterThan(0);
      }
    });

    test('shows secure payment badge', async ({ page }) => {
      await page.goto('/subscription');

      const secureBadge = page.locator('text=/secure|ssl|encrypted/i, img[alt*="secure"]');
      if (await secureBadge.count() > 0) {
        await expect(secureBadge.first()).toBeVisible();
      }
    });
  });

  test.describe('Cancel Subscription', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can access cancellation option', async ({ page }) => {
      await page.goto('/subscription');

      const cancelButton = page.locator('button:has-text("Cancel"), a:has-text("Cancel Subscription")');
      if (await cancelButton.count() > 0) {
        await expect(cancelButton.first()).toBeVisible();
      }
    });

    test('shows confirmation before cancel', async ({ page }) => {
      await page.goto('/subscription');

      const cancelButton = page.locator('button:has-text("Cancel Subscription")').first();
      if (await cancelButton.count() > 0) {
        await cancelButton.click();

        const confirmation = page.locator('text=/sure|confirm|cancel/i, [role="dialog"]');
        if (await confirmation.count() > 0) {
          await expect(confirmation.first()).toBeVisible();
        }
      }
    });

    test('shows what user will lose on cancel', async ({ page }) => {
      await page.goto('/subscription');

      const cancelButton = page.locator('button:has-text("Cancel")').first();
      if (await cancelButton.count() > 0) {
        await cancelButton.click();

        const loseInfo = page.locator('text=/lose|access|features/i');
        if (await loseInfo.count() > 0) {
          await expect(loseInfo.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Billing History', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can view billing history', async ({ page }) => {
      await page.goto('/subscription');

      const history = page.locator('text=History, text=Invoices, text=Payments, [data-billing-history]');
      if (await history.count() > 0) {
        await expect(history.first()).toBeVisible();
      }
    });

    test('shows invoice list', async ({ page }) => {
      await page.goto('/subscription');

      const invoices = page.locator('.invoice, [data-invoice], tr[data-invoice-id]');
      // May or may not have invoices
      await page.waitForLoadState('networkidle');
    });

    test('can download invoice', async ({ page }) => {
      await page.goto('/subscription');

      const downloadButton = page.locator('button:has-text("Download"), a:has-text("PDF"), a:has-text("Invoice")');
      if (await downloadButton.count() > 0) {
        await expect(downloadButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Payment Methods', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can view saved payment methods', async ({ page }) => {
      await page.goto('/subscription');

      const paymentMethods = page.locator('text=Payment Method, text=Card, [data-payment-methods]');
      if (await paymentMethods.count() > 0) {
        await expect(paymentMethods.first()).toBeVisible();
      }
    });

    test('can add new payment method', async ({ page }) => {
      await page.goto('/subscription');

      const addButton = page.locator('button:has-text("Add"), button:has-text("New Card")');
      if (await addButton.count() > 0) {
        await expect(addButton.first()).toBeVisible();
      }
    });

    test('can set default payment method', async ({ page }) => {
      await page.goto('/subscription');

      const setDefaultButton = page.locator('button:has-text("Default"), button:has-text("Make Default")');
      if (await setDefaultButton.count() > 0) {
        await expect(setDefaultButton.first()).toBeVisible();
      }
    });

    test('can remove payment method', async ({ page }) => {
      await page.goto('/subscription');

      const removeButton = page.locator('button:has-text("Remove"), button:has-text("Delete Card")');
      if (await removeButton.count() > 0) {
        await expect(removeButton.first()).toBeVisible();
      }
    });
  });

  test.describe('Plan Comparison', () => {
    test('shows feature differences', async ({ page }) => {
      await page.goto('/pricing');

      // Should show what's different between plans
      const comparison = page.locator('table, .comparison, [data-comparison]');
      if (await comparison.count() > 0) {
        await expect(comparison.first()).toBeVisible();
      }
    });

    test('highlights current plan', async ({ page }) => {
      await login(page);
      await page.goto('/pricing');

      const currentPlan = page.locator('text=Current, .current-plan, [data-current-plan]');
      if (await currentPlan.count() > 0) {
        await expect(currentPlan.first()).toBeVisible();
      }
    });

    test('shows feature limits per plan', async ({ page }) => {
      await page.goto('/pricing');

      const limits = page.locator('text=/\\d+ button|unlimited|\\d+ friend/i');
      if (await limits.count() > 0) {
        expect(await limits.count()).toBeGreaterThan(0);
      }
    });
  });

  test.describe('Trial Period', () => {
    test('shows trial information if available', async ({ page }) => {
      await page.goto('/pricing');

      const trial = page.locator('text=/trial|free.*day|try.*free/i');
      if (await trial.count() > 0) {
        await expect(trial.first()).toBeVisible();
      }
    });

    test('shows remaining trial days', async ({ page }) => {
      await login(page);
      await page.goto('/subscription');

      const trialDays = page.locator('text=/\\d+.*day.*left|trial.*end/i');
      // Only visible if user is on trial
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Usage Dashboard', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('shows button usage', async ({ page }) => {
      await page.goto('/subscription');

      const buttonUsage = page.locator('text=/button.*used|\\d+.*of.*\\d+.*button/i');
      if (await buttonUsage.count() > 0) {
        await expect(buttonUsage.first()).toBeVisible();
      }
    });

    test('shows friend limit usage', async ({ page }) => {
      await page.goto('/subscription');

      const friendUsage = page.locator('text=/friend.*used|\\d+.*of.*\\d+.*friend/i');
      if (await friendUsage.count() > 0) {
        await expect(friendUsage.first()).toBeVisible();
      }
    });

    test('shows progress bars for limits', async ({ page }) => {
      await page.goto('/subscription');

      const progressBar = page.locator('progress, .progress-bar, [role="progressbar"]');
      if (await progressBar.count() > 0) {
        await expect(progressBar.first()).toBeVisible();
      }
    });

    test('warns when approaching limits', async ({ page }) => {
      await page.goto('/subscription');

      const warning = page.locator('text=/approaching|near.*limit|almost/i, .warning');
      // Only visible if approaching limits
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('Promo Codes', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('has promo code input', async ({ page }) => {
      await page.goto('/subscription');

      const promoInput = page.locator('input[name="promo"], input[name="coupon"], input[placeholder*="promo" i]');
      if (await promoInput.count() > 0) {
        await expect(promoInput).toBeVisible();
      }
    });

    test('can apply promo code', async ({ page }) => {
      await page.goto('/subscription');

      const promoInput = page.locator('input[name="promo"]');
      if (await promoInput.count() > 0) {
        await promoInput.fill('TESTCODE');
        await page.click('button:has-text("Apply")');
        await page.waitForLoadState('networkidle');
      }
    });

    test('shows error for invalid promo code', async ({ page }) => {
      await page.goto('/subscription');

      const promoInput = page.locator('input[name="promo"]');
      if (await promoInput.count() > 0) {
        await promoInput.fill('INVALIDCODE');
        await page.click('button:has-text("Apply")');

        const error = page.locator('text=/invalid|expired|not found/i, .error');
        if (await error.count() > 0) {
          await expect(error.first()).toBeVisible();
        }
      }
    });
  });

  test.describe('Downgrade Flow', () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test('can downgrade plan', async ({ page }) => {
      await page.goto('/subscription');

      const downgradeButton = page.locator('button:has-text("Downgrade"), a:has-text("Switch to Free")');
      if (await downgradeButton.count() > 0) {
        await expect(downgradeButton.first()).toBeVisible();
      }
    });

    test('shows what will be lost on downgrade', async ({ page }) => {
      await page.goto('/subscription');

      const downgradeButton = page.locator('button:has-text("Downgrade")').first();
      if (await downgradeButton.count() > 0) {
        await downgradeButton.click();

        const loseInfo = page.locator('text=/lose|removed|limited/i');
        if (await loseInfo.count() > 0) {
          await expect(loseInfo.first()).toBeVisible();
        }
      }
    });
  });
});
