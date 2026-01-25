# ButtonLog Mobile E2E Tests

End-to-end tests for ButtonLog iOS and Android apps using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

### Install Maestro

```bash
# macOS
curl -Ls "https://get.maestro.mobile.dev" | bash

# Verify installation
maestro --version
```

### iOS Requirements
- Xcode installed
- iOS Simulator available
- ButtonLog iOS app built and installed on simulator

### Android Requirements
- Android Studio installed
- Android Emulator available (or physical device with USB debugging)
- ButtonLog Android app built and installed

## Project Structure

```
e2e-mobile/
├── ios/                    # iOS-specific test flows
│   ├── login.yaml          # OAuth login flow
│   ├── buttons.yaml        # Button operations
│   └── account.yaml        # Account/settings
├── android/                # Android-specific test flows
│   ├── login.yaml          # OAuth login flow
│   ├── buttons.yaml        # Button operations
│   └── account.yaml        # Account/settings
├── shared/                 # Shared subflows (reusable)
│   ├── wait-for-home.yaml  # Wait for home screen
│   └── logout.yaml         # Logout flow
├── config.yaml             # Maestro configuration
└── package.json            # npm scripts
```

## Running Tests

### Quick Start

```bash
cd e2e-mobile

# Run all iOS tests
npm run test:ios

# Run all Android tests
npm run test:android

# Run specific test file
npm run test:ios:login
npm run test:android:buttons
```

### Manual Maestro Commands

```bash
# Run single test
maestro test ios/login.yaml

# Run all tests in a directory
maestro test ios/

# Run with debug output
maestro test --debug ios/login.yaml

# Record test execution as video
maestro record ios/login.yaml
```

## Test Configuration

### Environment Variables

Tests can be configured via environment variables or the `config.yaml` file:

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ID_IOS` | iOS app bundle identifier | `com.buttonlog.app` |
| `APP_ID_ANDROID` | Android app package name | `com.buttonlog.app` |
| `TEST_USER_EMAIL` | Test user email (for OAuth) | - |

### Config File (config.yaml)

```yaml
# Maestro configuration
appId:
  ios: com.buttonlog.app
  android: com.buttonlog.app

# Test timeouts (milliseconds)
timeout: 30000

# Screenshots on failure
screenshotOnFailure: true
```

## Writing Tests

### Basic Maestro Syntax

```yaml
appId: com.buttonlog.app
---
# Tap on element by text
- tapOn: "Sign In"

# Tap on element by ID
- tapOn:
    id: "login_button"

# Enter text
- inputText: "test@example.com"

# Assert element visible
- assertVisible: "Welcome"

# Wait for element
- waitForAnimationToEnd

# Scroll
- scroll

# Run subflow
- runFlow: ../shared/logout.yaml
```

### Platform-Specific Tests

iOS and Android may have different UI elements. Create separate test files when needed:

```yaml
# ios/login.yaml - iOS-specific selectors
- tapOn:
    id: "GoogleSignInButton"

# android/login.yaml - Android-specific selectors
- tapOn:
    id: "google_sign_in_button"
```

## OAuth Testing Note

Since ButtonLog uses Google OAuth for authentication, automated login testing requires either:

1. **Pre-authenticated state**: Install app with existing auth tokens
2. **Manual login step**: Run tests that start from already-logged-in state
3. **Test account**: Use a Google account that allows automated sign-in

For CI/CD, consider using authenticated app state snapshots.

## Test Scenarios

### Authentication
- [ ] Sign in with Google OAuth
- [ ] Sign out
- [ ] Session persistence

### Buttons
- [ ] View button list
- [ ] Create new button (instant, timed, state types)
- [ ] Click/tap button
- [ ] Edit button
- [ ] Delete button

### Friends
- [ ] View friends list
- [ ] Send friend request
- [ ] Accept friend request
- [ ] View friend's buttons (with permission)

### Account
- [ ] View profile
- [ ] Edit profile
- [ ] View subscription
- [ ] Notification settings

## Troubleshooting

### iOS Simulator Issues

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app on simulator
xcrun simctl install booted /path/to/ButtonLog.app
```

### Android Emulator Issues

```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_6_API_33

# Install app on emulator
adb install /path/to/buttonlog.apk
```

### Maestro Issues

```bash
# Check connected devices
maestro devices

# Clear Maestro cache
maestro clear

# Run with verbose logging
maestro test --debug test.yaml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
jobs:
  e2e-mobile:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Maestro
        run: curl -Ls "https://get.maestro.mobile.dev" | bash

      - name: Boot iOS Simulator
        run: xcrun simctl boot "iPhone 15 Pro"

      - name: Build iOS App
        run: xcodebuild -project iphone/ButtonLog.xcodeproj -scheme ButtonLog -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

      - name: Install App
        run: xcrun simctl install booted path/to/ButtonLog.app

      - name: Run E2E Tests
        run: cd e2e-mobile && npm run test:ios
```
