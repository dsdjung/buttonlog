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
├── ios/
│   ├── setup/                  # Auth setup flows
│   │   ├── auth-user1.yaml     # User 1 OAuth setup
│   │   └── auth-user2.yaml     # User 2 OAuth setup
│   ├── login.yaml              # Login UI validation
│   ├── buttons.yaml            # Button operations
│   ├── friends.yaml            # Friends (single user)
│   ├── friends-multi-user1.yaml # Multi-user: User 1 perspective
│   ├── friends-multi-user2.yaml # Multi-user: User 2 perspective
│   ├── account.yaml            # Account/settings
│   └── navigation.yaml         # Tab navigation
├── android/
│   ├── setup/                  # Auth setup flows
│   │   ├── auth-user1.yaml     # User 1 OAuth setup
│   │   └── auth-user2.yaml     # User 2 OAuth setup
│   ├── login.yaml              # Login UI validation
│   ├── buttons.yaml            # Button operations
│   ├── friends.yaml            # Friends (single user)
│   ├── friends-multi-user1.yaml # Multi-user: User 1 perspective
│   ├── friends-multi-user2.yaml # Multi-user: User 2 perspective
│   ├── account.yaml            # Account/settings
│   └── navigation.yaml         # Tab navigation
├── shared/                     # Shared subflows
│   ├── wait-for-home.yaml
│   └── logout.yaml
├── scripts/                    # Helper scripts
│   ├── run-multi-user-ios.sh   # Run iOS multi-user tests
│   ├── run-multi-user-android.sh # Run Android multi-user tests
│   └── list-devices.sh         # List available devices
├── config.yaml                 # Maestro configuration
└── package.json                # npm scripts
```

## Quick Start

```bash
cd e2e-mobile

# List available devices
npm run devices:list

# Run all iOS tests (requires authenticated app)
npm run test:ios

# Run all Android tests (requires authenticated app)
npm run test:android
```

---

## Multi-User Testing (Friend Relationships)

Multi-user tests verify friend relationship features between two users, similar to the web E2E tests.

### Overview

| Component | Web E2E | Mobile E2E |
|-----------|---------|------------|
| Framework | Playwright | Maestro |
| User 1 Account | Same Google account | Same Google account |
| User 2 Account | Same Google account | Same Google account |
| Auth Storage | Browser cookies (JSON) | App secure storage |
| Multi-user | Two browser contexts | Two simulators/emulators |

### Step 1: Start Two Devices

#### iOS (Two Simulators)
```bash
# List available simulators
xcrun simctl list devices available

# Boot two different simulators
xcrun simctl boot "iPhone 15 Pro"
xcrun simctl boot "iPhone 15"

# Verify both are running
xcrun simctl list devices | grep Booted
```

#### Android (Two Emulators)
```bash
# List available AVDs
emulator -list-avds

# Start two emulators (in separate terminals)
emulator -avd Pixel_6_API_33 &
emulator -avd Pixel_7_API_34 &

# Verify both are connected
adb devices
```

### Step 2: Install ButtonLog App

#### iOS
```bash
# Build the app
cd iphone
xcodebuild -project ButtonLog.xcodeproj -scheme ButtonLog -sdk iphonesimulator build

# Install on both simulators
xcrun simctl install "iPhone 15 Pro" /path/to/ButtonLog.app
xcrun simctl install "iPhone 15" /path/to/ButtonLog.app
```

#### Android
```bash
# Build the app
cd android
./gradlew assembleDebug

# Install on both emulators (get device IDs from 'adb devices')
adb -s emulator-5554 install app/build/outputs/apk/debug/app-debug.apk
adb -s emulator-5556 install app/build/outputs/apk/debug/app-debug.apk
```

### Step 3: Authenticate Both Users

Use the **same Google accounts** as your web E2E tests (User 1 and User 2).

#### iOS
```bash
cd e2e-mobile

# On first simulator (User 1)
# Maestro will prompt you to complete Google OAuth
npm run setup:ios:user1

# On second simulator (User 2)
# Use --device flag to target specific simulator
maestro test --device <simulator-2-udid> ios/setup/auth-user2.yaml
```

#### Android
```bash
cd e2e-mobile

# On first emulator (User 1)
npm run setup:android:user1

# On second emulator (User 2)
maestro test --device <emulator-2-id> android/setup/auth-user2.yaml
```

### Step 4: Run Multi-User Tests

```bash
# iOS - runs User 1 and User 2 tests in parallel on two simulators
npm run test:ios:friends:multi

# Android - runs User 1 and User 2 tests in parallel on two emulators
npm run test:android:friends:multi
```

Or run manually on specific devices:
```bash
# Get device IDs
npm run devices

# Run on specific devices
maestro test --device <user1-device> ios/friends-multi-user1.yaml
maestro test --device <user2-device> ios/friends-multi-user2.yaml
```

---

## Single-User Tests

For tests that don't require multi-user interaction:

```bash
# Run all single-user tests
npm run test:ios
npm run test:android

# Run specific test
npm run test:ios:login
npm run test:ios:buttons
npm run test:ios:account
npm run test:ios:navigation

npm run test:android:login
npm run test:android:buttons
npm run test:android:account
npm run test:android:navigation
```

---

## All npm Scripts

| Script | Description |
|--------|-------------|
| `devices` | List Maestro-connected devices |
| `devices:list` | List all iOS simulators and Android emulators |
| `clear` | Clear Maestro cache |
| **Setup** | |
| `setup:ios:user1` | Authenticate User 1 on iOS |
| `setup:ios:user2` | Authenticate User 2 on iOS |
| `setup:android:user1` | Authenticate User 1 on Android |
| `setup:android:user2` | Authenticate User 2 on Android |
| **iOS Tests** | |
| `test:ios` | Run all iOS tests |
| `test:ios:login` | Test login UI |
| `test:ios:buttons` | Test button operations |
| `test:ios:friends` | Test friends (single user) |
| `test:ios:friends:multi` | Test friends (multi-user, parallel) |
| `test:ios:account` | Test account page |
| `test:ios:navigation` | Test tab navigation |
| **Android Tests** | |
| `test:android` | Run all Android tests |
| `test:android:login` | Test login UI |
| `test:android:buttons` | Test button operations |
| `test:android:friends` | Test friends (single user) |
| `test:android:friends:multi` | Test friends (multi-user, parallel) |
| `test:android:account` | Test account page |
| `test:android:navigation` | Test tab navigation |
| **Recording** | |
| `record:ios` | Record iOS test execution as video |
| `record:android` | Record Android test execution as video |

---

## OAuth Authentication Notes

Since ButtonLog uses Google OAuth, automated login is limited by Google's security:

1. **Setup flows guide manual login** - The `setup:*` scripts open the app and wait for you to complete OAuth manually
2. **Auth persists in app storage** - Once logged in, the session remains until you clear app data
3. **Use same accounts as web E2E** - For consistency, use the same Google accounts

### Tips for OAuth Setup

- **Don't clear app state** after authentication - tests expect pre-authenticated state
- **Use real Google accounts** - Test accounts work better than personal accounts
- **5-minute timeout** - You have 5 minutes to complete OAuth during setup

---

## Test Scenarios Covered

### Single-User Tests
- [x] Login UI validation (OAuth buttons visible)
- [x] Tab navigation (Buttons, Friends, Diary, Logs, Account)
- [x] Buttons page (list, create button flow)
- [x] Friends page (list, UI elements)
- [x] Account page (profile, settings)

### Multi-User Tests
- [x] User 1: View friends list
- [x] User 1: Send friend request
- [x] User 1: View pending requests
- [x] User 1: View friend profile
- [x] User 2: View friends list
- [x] User 2: Check for friend requests
- [x] User 2: Accept friend request
- [x] User 2: View friend's buttons

---

## Troubleshooting

### List Devices
```bash
# See all available devices
npm run devices:list

# Or directly
./scripts/list-devices.sh
```

### iOS Simulator Issues
```bash
# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Shutdown all simulators
xcrun simctl shutdown all

# Reset simulator (clears all app data)
xcrun simctl erase "iPhone 15 Pro"
```

### Android Emulator Issues
```bash
# Cold boot emulator
emulator -avd Pixel_6_API_33 -no-snapshot-load

# Kill all emulators
adb emu kill

# Clear app data only
adb shell pm clear com.buttonlog.app
```

### Maestro Issues
```bash
# Clear Maestro cache
npm run clear

# Run with debug output
maestro test --debug ios/login.yaml

# Check Maestro version
maestro --version
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
jobs:
  e2e-mobile-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Maestro
        run: curl -Ls "https://get.maestro.mobile.dev" | bash

      - name: Boot iOS Simulator
        run: xcrun simctl boot "iPhone 15 Pro"

      - name: Build iOS App
        run: |
          cd iphone
          xcodebuild -project ButtonLog.xcodeproj \
            -scheme ButtonLog \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            build

      - name: Install App
        run: xcrun simctl install booted path/to/ButtonLog.app

      # For CI, you'd need pre-authenticated app state or skip auth tests
      - name: Run E2E Tests
        run: cd e2e-mobile && npm run test:ios:navigation
```

Note: Multi-user OAuth tests require manual intervention and are best run locally.
