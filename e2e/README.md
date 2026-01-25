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
# Make sure Phoenix server is running on localhost:4000
npm test

# Or let Playwright start the server automatically
npm test  # Config will start `mix phx.server` if needed
```

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
│   ├── auth.spec.ts        # Authentication flows
│   ├── buttons.spec.ts     # Button CRUD operations
│   ├── account.spec.ts     # Account settings
│   └── subscription.spec.ts # Subscription pages
├── playwright.config.ts    # Playwright configuration
└── package.json
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TEST_ENV` | Target environment | `local` |
| `STAGING_URL` | Staging server URL | `https://staging.buttonlog.com` |
| `PROD_URL` | Production server URL | `https://buttonlog.com` |
| `TEST_USER_EMAIL` | Test user email | `test@example.com` |
| `TEST_USER_PASSWORD` | Test user password | `password123` |

## Writing New Tests

1. Use `npm run codegen` to record actions and generate test code
2. Create a new file in `tests/` with `.spec.ts` extension
3. Follow existing patterns for login/setup

Example:
```typescript
import { test, expect } from '@playwright/test';

test.describe('My Feature', () => {
  test('does something', async ({ page }) => {
    await page.goto('/my-page');
    await expect(page.locator('h1')).toContainText('Expected');
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
