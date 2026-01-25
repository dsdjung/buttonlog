# ButtonLog E2E Tests

End-to-end tests for ButtonLog using [Playwright](https://playwright.dev/).

## Setup

```bash
cd e2e
npm install
npx playwright install  # Install browser binaries
```

## Running Tests

### Against Local (default)
```bash
# Make sure Phoenix server is running on localhost:14015
npm test

# Or let Playwright start the server automatically
npm test  # Config will start `mix phx.server` if needed
```

**Note:** Local dev server runs on port **14015** (configured in `backend/config/dev.exs`).

### Against Staging
```bash
npm run test:staging

# Or with custom URL
STAGING_URL=https://staging.buttonlog.com npm run test:staging
```

### Against Production
```bash
npm run test:prod

# Or with custom URL
PROD_URL=https://buttonlog.com npm run test:prod
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `npm test` | Run all tests against local |
| `npm run test:staging` | Run all tests against staging |
| `npm run test:prod` | Run all tests against production |
| `npm run test:ui` | Open Playwright UI mode |
| `npm run test:headed` | Run tests with visible browser |
| `npm run test:debug` | Debug mode with inspector |
| `npm run test:chromium` | Run only in Chrome |
| `npm run test:mobile` | Run mobile viewport tests |
| `npm run report` | View HTML test report |
| `npm run codegen` | Generate tests by recording |

## Test Structure

```
e2e/
├── tests/
│   ├── fixtures/
│   │   └── auth.ts              # Shared authentication helpers
│   ├── public-pages.spec.ts     # Home, pricing, about, terms, privacy
│   ├── auth.spec.ts             # Login, register, logout, OAuth
│   ├── buttons.spec.ts          # Button CRUD and interactions
│   ├── friends.spec.ts          # Friends/social features
│   ├── notifications.spec.ts    # Notifications and alerts
│   ├── diary.spec.ts            # Diary/calendar view
│   ├── teams.spec.ts            # Teams functionality
│   ├── organizations.spec.ts    # Organizations management
│   ├── account.spec.ts          # Account settings (profile, privacy, etc.)
│   ├── webhooks.spec.ts         # Webhook configuration
│   ├── support.spec.ts          # Support tickets
│   └── subscription.spec.ts     # Subscription and payments
├── playwright.config.ts         # Playwright configuration
├── package.json
└── README.md
```

## Test Coverage

| Test File | Coverage Area | Tests |
|-----------|--------------|-------|
| `public-pages.spec.ts` | Home, pricing, health check, login page | ~10 |
| `auth.spec.ts` | OAuth login, route accessibility | ~15 |
| `buttons.spec.ts` | Button CRUD, types, interactions, sharing, notifications | ~30 |
| `friends.spec.ts` | Friend requests, permissions, blocking, activity | ~20 |
| `notifications.spec.ts` | Notifications list, types, actions, settings | ~15 |
| `diary.spec.ts` | Calendar view, navigation, filtering, statistics | ~20 |
| `teams.spec.ts` | Team CRUD, members, settings, buttons | ~20 |
| `organizations.spec.ts` | Organization CRUD, members, teams, billing | ~25 |
| `account.spec.ts` | Profile, password, privacy, export, devices | ~35 |
| `webhooks.spec.ts` | Webhook URL, events, testing, history | ~20 |
| `support.spec.ts` | Ticket CRUD, replies, attachments, FAQ | ~20 |
| `subscription.spec.ts` | Plans, payments, billing, usage, promo codes | ~35 |

## Authentication

**Important:** This app uses OAuth-only authentication (Google). There are no email/password forms.

### Testing Authenticated Features

For tests that require authentication, you have two options:

#### Option 1: Manual Setup (Recommended for CI)
```bash
# 1. Login manually via Google OAuth in a browser
# 2. Save the browser state:
npx playwright codegen --save-storage=playwright/.auth/user.json

# 3. Run tests with stored state:
npx playwright test --storage-state=playwright/.auth/user.json
```

#### Option 2: Test Unauthenticated Behavior
Tests will verify that:
- Pages load without errors
- Login prompts are shown for protected features
- Public content is accessible

### Test Categories

| Category | Auth Required | Notes |
|----------|---------------|-------|
| Public pages | No | Home, pricing, health check |
| Auth pages | No | Login/register page structure |
| Buttons, Friends, etc. | Yes | Require stored auth state |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TEST_ENV` | Target environment | `local` |
| `STAGING_URL` | Staging server URL | `https://staging.buttonlog.com` |
| `PROD_URL` | Production server URL | `https://buttonlog.com` |

## Writing New Tests

1. Use `npm run codegen` to record actions and generate test code
2. Create a new file in `tests/` with `.spec.ts` extension
3. For authenticated tests, use the `authenticatedTest` fixture or check for stored auth

Example (public page):
```typescript
import { test, expect } from '@playwright/test';

test.describe('My Feature', () => {
  test('loads page', async ({ page }) => {
    await page.goto('/my-page');
    await expect(page.locator('h1')).toContainText('Expected');
  });
});
```

Example (authenticated feature):
```typescript
import { test, expect } from '@playwright/test';
import { hasStoredAuth } from './fixtures/auth';

test.describe('Protected Feature', () => {
  test.beforeEach(async ({ page }) => {
    // Tests will check for login prompt if not authenticated
    await page.goto('/protected-page');
  });

  test('shows feature or login prompt', async ({ page }) => {
    const hasAuth = await hasStoredAuth();
    if (hasAuth) {
      await expect(page.locator('.feature')).toBeVisible();
    } else {
      // Verify login prompt is shown
      const loginLink = page.locator('a[href*="/auth"]');
      await expect(loginLink.first()).toBeVisible();
    }
  });
});
```

## CI/CD Integration

Tests run automatically via GitHub Actions:
- On every push to main/master
- On pull requests
- Manual trigger with environment selection

See `.github/workflows/e2e.yml` for configuration.

## Troubleshooting

### Tests fail with "Target closed"
The server might have crashed. Check Phoenix logs.

### Tests timeout
Increase timeout in `playwright.config.ts` or check network connectivity.

### Screenshots not captured
Screenshots are only captured on failure. Check `test-results/` folder.
