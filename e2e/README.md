# ButtonLog E2E Tests

End-to-end tests for ButtonLog using [Playwright](https://playwright.dev/).

## Setup

```bash
cd e2e
npm install
npx playwright install  # Install browser binaries
```

## Running Tests

### Quick Start
```bash
# Run unauthenticated tests (default)
npm test

# Run authenticated tests (requires setup first)
npm run test:setup   # One-time: log in and save session
npm run test:auth    # Run tests using saved session
```

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

## Authentication

**Important:** This app uses OAuth-only authentication (Google). There are no email/password forms.

### Setting Up Authenticated Tests

#### Step 1: Run Auth Setup
```bash
npm run test:setup
```

This opens a browser window where you:
1. Click "Sign in with Google"
2. Complete the Google OAuth login
3. Wait for redirect to the app

Your session is automatically saved to `playwright/.auth/user.json`.

#### Step 2: Run Authenticated Tests
```bash
npm run test:auth
```

### Alternative: Using Codegen
```bash
npm run codegen:auth
```

This opens a browser where you can log in manually and the session is saved automatically.

### Test Types

| Command | Description | Auth Required |
|---------|-------------|---------------|
| `npm test` | Run unauthenticated tests | No |
| `npm run test:auth` | Run authenticated tests | Yes (run setup first) |
| `npm run test:all` | Run all browsers (unauth) | No |

## Useful Commands

| Command | Description |
|---------|-------------|
| `npm test` | Run tests against local (chromium) |
| `npm run test:all` | Run all browser tests |
| `npm run test:staging` | Run tests against staging |
| `npm run test:prod` | Run tests against production |
| `npm run test:setup` | Set up authentication (interactive) |
| `npm run test:auth` | Run authenticated tests |
| `npm run test:auth:headed` | Run authenticated tests with visible browser |
| `npm run test:ui` | Open Playwright UI mode |
| `npm run test:headed` | Run tests with visible browser |
| `npm run test:debug` | Debug mode with inspector |
| `npm run test:chromium` | Run only in Chrome |
| `npm run test:firefox` | Run only in Firefox |
| `npm run test:webkit` | Run only in Safari |
| `npm run test:mobile` | Run mobile viewport tests |
| `npm run report` | View HTML test report |
| `npm run codegen` | Generate tests by recording |
| `npm run codegen:auth` | Record and save auth state |

## Test Structure

```
e2e/
├── tests/
│   ├── fixtures/
│   │   └── auth.ts              # Authentication helpers
│   ├── auth.setup.ts            # Auth setup script (run with test:setup)
│   ├── public-pages.spec.ts     # Public pages (unauthenticated)
│   ├── auth.spec.ts             # OAuth flow tests (unauthenticated)
│   ├── buttons.spec.ts          # Button tests (unauthenticated)
│   ├── buttons.auth.spec.ts     # Button tests (authenticated)
│   ├── friends.spec.ts          # Friends tests
│   ├── notifications.spec.ts    # Notifications tests
│   ├── diary.spec.ts            # Diary tests
│   ├── teams.spec.ts            # Teams tests
│   ├── organizations.spec.ts    # Organizations tests
│   ├── account.spec.ts          # Account tests
│   ├── webhooks.spec.ts         # Webhook tests
│   ├── support.spec.ts          # Support tests
│   └── subscription.spec.ts     # Subscription tests
├── playwright/
│   └── .auth/
│       └── user.json            # Stored auth state (gitignored)
├── playwright.config.ts         # Playwright configuration
├── package.json
└── README.md
```

## Test Naming Convention

| Pattern | Description |
|---------|-------------|
| `*.spec.ts` | Unauthenticated tests |
| `*.auth.spec.ts` | Authenticated tests (require stored auth) |
| `*.setup.ts` | Setup scripts |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TEST_ENV` | Target environment | `local` |
| `STAGING_URL` | Staging server URL | `https://staging.buttonlog.com` |
| `PROD_URL` | Production server URL | `https://buttonlog.com` |

## Writing New Tests

### Unauthenticated Tests
```typescript
// myfeature.spec.ts
import { test, expect } from '@playwright/test';

test.describe('My Feature', () => {
  test('loads page', async ({ page }) => {
    await page.goto('/my-page');
    await expect(page.locator('h1')).toContainText('Expected');
  });
});
```

### Authenticated Tests
```typescript
// myfeature.auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('My Feature (Authenticated)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/protected-page');
  });

  test('shows authenticated content', async ({ page }) => {
    // This test runs with stored auth state
    await expect(page.locator('.user-content')).toBeVisible();
  });
});
```

### Using Auth Helpers
```typescript
import { test, expect } from '@playwright/test';
import { hasStoredAuth, isAuthenticated } from './fixtures/auth';

test('conditional test', async ({ page }) => {
  await page.goto('/page');

  if (await hasStoredAuth()) {
    // Run authenticated assertions
  } else {
    // Run unauthenticated assertions
  }
});
```

## CI/CD Integration

Tests run automatically via GitHub Actions:
- On every push to main/master
- On pull requests
- Manual trigger with environment selection

### CI with Authentication

For CI/CD with authenticated tests, you need to:

1. Run `npm run test:setup` locally
2. Copy the contents of `playwright/.auth/user.json`
3. Store it as a GitHub secret: `E2E_AUTH_STATE`
4. In your CI workflow, create the file from the secret

Example workflow step:
```yaml
- name: Set up auth state
  run: |
    mkdir -p e2e/playwright/.auth
    echo '${{ secrets.E2E_AUTH_STATE }}' > e2e/playwright/.auth/user.json
```

## Troubleshooting

### "No stored authentication found"
Run `npm run test:setup` to capture your login session.

### Tests fail with "Target closed"
The server might have crashed. Check Phoenix logs.

### Tests timeout
Increase timeout in `playwright.config.ts` or check network connectivity.

### Authentication expired
Re-run `npm run test:setup` to capture a fresh session.

### Screenshots not captured
Screenshots are only captured on failure. Check `test-results/` folder.
