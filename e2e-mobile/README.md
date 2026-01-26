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
│   ├── login.yaml              # Login UI validation
│   ├── buttons.yaml            # Button operations
│   ├── friends.yaml            # Friends (single user)
│   ├── friends-multi-user1.yaml # Multi-user: User 1 perspective
│   ├── account.yaml            # Account/settings
│   └── navigation.yaml         # Tab navigation
├── android/
│   ├── setup/                  # Auth setup flows
│   ├── login.yaml              # Login UI validation
│   ├── buttons.yaml            # Button operations
│   ├── friends.yaml            # Friends (single user)
│   ├── friends-multi-user2.yaml # Multi-user: User 2 perspective
│   ├── account.yaml            # Account/settings
│   └── navigation.yaml         # Tab navigation
├── shared/                     # Shared subflows
├── scripts/                    # Helper scripts
│   ├── run-multi-user-cross-platform.sh  # Recommended: iOS + Android
│   ├── run-multi-user-ios.sh   # iOS-only (has limitations)
│   ├── run-multi-user-android.sh
│   └── list-devices.sh
├── config.yaml
└── package.json
```

## Quick Start

```bash
cd e2e-mobile

# List available devices
npm run devices:list

# Run single-user iOS tests
npm run test:ios

# Run single-user Android tests
npm run test:android
```

---

## Multi-User Testing (Recommended: Cross-Platform)

For multi-user testing (friend relationships), use **cross-platform testing** with:
- **User 1**: iOS Simulator
- **User 2**: Android Emulator

This is the recommended approach because:
1. Tests real cross-platform compatibility
2. Avoids iOS gesture limitation (only one gesture at a time across simulators)
3. Uses same accounts as web E2E tests

### Setup

#### 1. Start One iOS Simulator + One Android Emulator

```bash
# iOS
xcrun simctl boot "iPhone 16 Pro"

# Android (from Android Studio or command line)
$HOME/Library/Android/sdk/emulator/emulator -avd <avd-name> &
```

#### 2. Install ButtonLog App on Both Devices

**iOS**: Build and run from Xcode targeting the simulator

**Android**:
```bash
cd android && ./gradlew installDebug
```

#### 3. Authenticate Users

Use the **same Google accounts** as web E2E:
- iOS Simulator → User 1's Google account
- Android Emulator → User 2's Google account

Complete OAuth manually on each device.

#### 4. Run Cross-Platform Multi-User Tests

```bash
cd e2e-mobile
npm run test:cross-platform:multi
```

This runs:
- User 1 friend tests on iOS
- User 2 friend tests on Android

---

## All npm Scripts

| Script | Description |
|--------|-------------|
| `devices` | List Maestro-connected devices |
| `devices:list` | List all iOS simulators and Android emulators |
| `clear` | Clear Maestro cache |
| **Setup** | |
| `setup:ios:user1` | Authenticate User 1 on iOS |
| `setup:android:user2` | Authenticate User 2 on Android |
| **Single-User Tests** | |
| `test:ios` | Run all iOS tests |
| `test:ios:login` | Test login UI |
| `test:ios:buttons` | Test button operations |
| `test:ios:friends` | Test friends (single user) |
| `test:ios:account` | Test account page |
| `test:ios:navigation` | Test tab navigation |
| `test:android` | Run all Android tests |
| `test:android:login` | Test login UI |
| `test:android:buttons` | Test button operations |
| `test:android:friends` | Test friends (single user) |
| `test:android:account` | Test account page |
| `test:android:navigation` | Test tab navigation |
| **Multi-User Tests** | |
| `test:cross-platform:multi` | **Recommended**: iOS User 1 + Android User 2 |
| `test:ios:friends:multi` | iOS-only (requires 2 simulators, has limitations) |
| `test:android:friends:multi` | Android-only (requires 2 emulators) |
| **Recording** | |
| `record:ios` | Record iOS test execution as video |
| `record:android` | Record Android test execution as video |

---

## Test Coverage

### Single-User Tests
- Login UI validation (OAuth buttons visible)
- Tab navigation (Buttons, Friends, Diary, Logs, Account)
- Buttons page (list, create button flow)
- Friends page (list, UI elements)
- Account page (profile, settings)

### Multi-User Tests (Cross-Platform)
- User 1 (iOS): View friends, add friend, view pending, view friend profile
- User 2 (Android): View friends, check requests, accept request, view friend buttons

---

## Troubleshooting

### List Devices
```bash
npm run devices:list
```

### iOS Simulator
```bash
# Boot simulator
xcrun simctl boot "iPhone 16 Pro"

# Shutdown
xcrun simctl shutdown "iPhone 16 Pro"
```

### Android Emulator
```bash
# List AVDs
$HOME/Library/Android/sdk/emulator/emulator -list-avds

# Start emulator
$HOME/Library/Android/sdk/emulator/emulator -avd <avd-name> &

# Check connected
$HOME/Library/Android/sdk/platform-tools/adb devices
```

### Maestro
```bash
# Clear cache
npm run clear

# Debug mode
maestro test --debug ios/login.yaml
```

---

## OAuth Notes

- Setup flows guide manual OAuth login (Google's security prevents automation)
- Auth persists in app storage until cleared
- Use same Google accounts as web E2E (User 1 and User 2)
- 5-minute timeout for OAuth completion during setup
