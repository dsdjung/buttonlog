# ButtonLog iOS Tests

This directory contains unit tests for the ButtonLog iOS application.

## Setup Instructions

The test files need to be added to the Xcode project. Follow these steps:

### 1. Add Test Target in Xcode

1. Open `ButtonLog.xcodeproj` in Xcode
2. Click on the project in the Navigator
3. Click the `+` button at the bottom of the targets list
4. Select **Unit Testing Bundle**
5. Name it `ButtonLogTests`
6. Set the **Host Application** to `ButtonLog`
7. Click **Finish**

### 2. Add Test Files to Target

1. Right-click on the `ButtonLogTests` folder in Xcode Navigator
2. Select **Add Files to "ButtonLog"...**
3. Navigate to the `ButtonLogTests` folder
4. Select all `.swift` files:
   - `AppStateTests.swift`
   - `ModelTests.swift`
   - `TestHelpers.swift`
5. Ensure **ButtonLogTests** is checked in "Add to targets"
6. Click **Add**

### 3. Configure Test Target

Ensure the test target has access to the main app module:

1. Select the `ButtonLogTests` target
2. Go to **Build Settings**
3. Search for "Host Application"
4. Ensure it's set to `ButtonLog`

## Running Tests

### From Xcode

- Press `⌘ + U` to run all tests
- Click the test navigator (diamond icon) to see test results
- Click the play button next to individual tests to run specific tests

### From Command Line

```bash
xcodebuild test \
  -project ButtonLog.xcodeproj \
  -scheme ButtonLog \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Structure

### AppStateTests.swift
Tests for the main `AppState` class:
- Initial state verification
- Button management (add, update, remove)
- Friend management
- Notification handling
- Error handling

### ModelTests.swift
Tests for all model classes:
- `Button` model and `ButtonFormData`
- `User` and `PublicUser` models
- `Friend` and `FriendPermissions` models
- `AppNotification` model
- `SubscriptionPlan` and related models
- `ButtonClick` and `FriendButton` models

### TestHelpers.swift
Utility functions for creating mock data:
- `createMockButton()`
- `createMockFriend()`
- `createMockNotification()`
- `createMockButtonClick()`
- etc.

## Writing New Tests

### Adding a New Test File

1. Create a new Swift file in the `ButtonLogTests` directory
2. Import XCTest and the app module:
   ```swift
   import XCTest
   @testable import ButtonLog
   ```
3. Create a test class extending `XCTestCase`:
   ```swift
   final class MyNewTests: XCTestCase {
       func testSomething() {
           // Test code
       }
   }
   ```
4. Add the file to the test target in Xcode

### Test Naming Conventions

- Test methods should start with `test`
- Use descriptive names: `testButtonCreationWithValidData()`
- Group related tests in the same class

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

## Best Practices

1. **Isolate tests**: Each test should be independent
2. **Use setup/teardown**: Use `setUp()` and `tearDown()` for common setup
3. **Test edge cases**: Include tests for error conditions
4. **Mock external dependencies**: Use mock services for API calls
5. **Keep tests fast**: Avoid network calls in unit tests
