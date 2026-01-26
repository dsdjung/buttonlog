# ButtonLog iOS Tests

This directory contains unit tests and integration tests for the ButtonLog iOS application.

## Test Files Overview

### Unit Tests (14 files)
| File | Description |
|------|-------------|
| `APIServiceTests.swift` | Tests for HTTP methods, API errors, and response decoding |
| `AppStateTests.swift` | Tests for main AppState class and state management |
| `AuthenticationManagerTests.swift` | Tests for authentication flows and token management |
| `KeychainManagerTests.swift` | Tests for secure keychain operations |
| `ModelTests.swift` | Tests for all data models (Button, User, Friend, etc.) |
| `PushNotificationTests.swift` | Tests for push notification handling |
| `OfflineTests.swift` | Tests for offline functionality |
| `TestHelpers.swift` | Utility functions for creating mock data |

### Integration Tests (5 files in `Integration/`)
| File | Description |
|------|-------------|
| `BaseIntegrationTest.swift` | Base class for integration tests |
| `IntegrationTestConfig.swift` | Configuration for integration testing |
| `AuthIntegrationTests.swift` | End-to-end authentication tests |
| `ButtonIntegrationTests.swift` | End-to-end button operation tests |
| `FriendsIntegrationTests.swift` | End-to-end social feature tests |
| `NetworkErrorTests.swift` | Tests for network error handling |

## Setup Instructions

### Step 1: Add Test Targets in Xcode

1. Open `ButtonLog.xcodeproj` in Xcode
2. Click on the project in the Navigator (left sidebar)
3. Click the `+` button at the bottom of the targets list
4. Select **Unit Testing Bundle**
5. Configure:
   - **Product Name**: `ButtonLogTests`
   - **Team**: Your development team
   - **Host Application**: `ButtonLog`
6. Click **Finish**

### Step 2: Add Test Files to Target

1. In Xcode Navigator, expand the `ButtonLogTests` folder
2. Select all `.swift` files in `ButtonLogTests/`:
   - `APIServiceTests.swift`
   - `AppStateTests.swift`
   - `AuthenticationManagerTests.swift`
   - `KeychainManagerTests.swift`
   - `ModelTests.swift`
   - `PushNotificationTests.swift`
   - `OfflineTests.swift`
   - `TestHelpers.swift`
3. Select all files in `ButtonLogTests/Integration/`:
   - `BaseIntegrationTest.swift`
   - `IntegrationTestConfig.swift`
   - `AuthIntegrationTests.swift`
   - `ButtonIntegrationTests.swift`
   - `FriendsIntegrationTests.swift`
   - `NetworkErrorTests.swift`
4. In the File Inspector (right sidebar), ensure **ButtonLogTests** is checked under "Target Membership"

### Step 3: (Optional) Add UI Test Target

1. Click `+` in targets list
2. Select **UI Testing Bundle**
3. Configure:
   - **Product Name**: `ButtonLogUITests`
   - **Host Application**: `ButtonLog`
4. Add the UI test files from `ButtonLogUITests/`:
   - `AuthenticationUITests.swift`
   - `ButtonsUITests.swift`
   - `FriendsUITests.swift`

### Step 4: Configure Test Target Build Settings

1. Select the `ButtonLogTests` target
2. Go to **Build Settings** tab
3. Ensure these settings:
   - **Host Application**: `ButtonLog`
   - **iOS Deployment Target**: Matches main app
4. Go to **Build Phases** tab
5. Ensure **Link Binary With Libraries** includes necessary frameworks

## Running Tests

### From Xcode
- Press `Cmd + U` to run all tests
- Open Test Navigator (`Cmd + 6`) to see test results
- Click the play button next to individual tests to run specific tests

### From Command Line
```bash
# Run unit tests
xcodebuild test \
  -project ButtonLog.xcodeproj \
  -scheme ButtonLog \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ButtonLogTests

# Run UI tests
xcodebuild test \
  -project ButtonLog.xcodeproj \
  -scheme ButtonLog \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ButtonLogUITests
```

### From Fastlane
```bash
# Add to Fastfile:
lane :test do
  scan(
    project: "ButtonLog.xcodeproj",
    scheme: "ButtonLog",
    devices: ["iPhone 15"]
  )
end

# Then run:
fastlane test
```

## Writing New Tests

### Test File Template
```swift
import XCTest
@testable import ButtonLog

final class MyFeatureTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Setup code
    }

    override func tearDown() {
        // Cleanup code
        super.tearDown()
    }

    func testFeatureBehavior() {
        // Arrange
        let expected = "expected value"

        // Act
        let result = // ... call your code

        // Assert
        XCTAssertEqual(result, expected)
    }
}
```

### Using Test Helpers
```swift
import XCTest
@testable import ButtonLog

final class MyTests: XCTestCase {
    func testWithMockData() {
        let button = TestHelpers.createMockButton(
            name: "Custom Button",
            type: .timed
        )
        XCTAssertEqual(button.name, "Custom Button")
    }
}
```

## Test Categories

### Unit Tests
- Fast, isolated tests for individual components
- No network calls or external dependencies
- Use mock data from `TestHelpers.swift`

### Integration Tests
- Test interactions between components
- May require backend server running
- Configure endpoint in `IntegrationTestConfig.swift`

### UI Tests
- Test user interface flows
- Slower but comprehensive
- Verify end-to-end user journeys

## CI/CD Integration

### GitHub Actions Example
```yaml
name: iOS Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          xcodebuild test \
            -project iphone/ButtonLog.xcodeproj \
            -scheme ButtonLog \
            -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Best Practices

1. **Isolate tests**: Each test should be independent and not rely on other tests
2. **Use descriptive names**: `testLoginWithValidCredentialsSucceeds()`
3. **Test edge cases**: Include tests for error conditions and boundary values
4. **Keep tests fast**: Use mocks for network calls in unit tests
5. **Clean up state**: Use `setUp()` and `tearDown()` properly
