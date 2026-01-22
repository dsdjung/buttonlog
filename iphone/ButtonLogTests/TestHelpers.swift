import XCTest
@testable import ButtonLog

/// Test helper utilities for ButtonLog tests
enum TestHelpers {

    // MARK: - Mock Data Generators

    /// Creates a mock Button with customizable properties
    static func createMockButton(
        id: String = UUID().uuidString,
        name: String = "Test Button",
        description: String? = nil,
        type: ButtonType = .instant,
        icon: String = "star",
        color: String = "#007AFF",
        clickCount: Int = 0,
        currentState: ButtonState = .idle,
        alertsEnabled: Bool = true
    ) -> ButtonModel {
        return ButtonModel(
            id: id,
            name: name,
            description: description,
            type: type,
            icon: icon,
            color: color,
            clickCount: clickCount,
            currentState: currentState,
            alertsEnabled: alertsEnabled,
            autoStopEnabled: false,
            calendarSyncEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            latestClick: nil
        )
    }

    /// Creates a mock PublicUser
    static func createMockPublicUser(
        id: String = UUID().uuidString,
        username: String = "testuser",
        displayName: String? = "Test User",
        avatar: String? = nil
    ) -> PublicUser {
        return PublicUser(
            id: id,
            username: username,
            displayName: displayName,
            avatar: avatar
        )
    }

    /// Creates a mock Friend
    static func createMockFriend(
        id: String = UUID().uuidString,
        friendId: String = UUID().uuidString,
        username: String = "friend",
        displayName: String? = "Friend",
        status: FriendshipStatus = .accepted,
        canSeeButtons: Bool = true,
        canSeeActivity: Bool = true,
        receiveNotifications: Bool = true
    ) -> Friend {
        let user = createMockPublicUser(
            id: friendId,
            username: username,
            displayName: displayName
        )
        let permissions = FriendPermissions(
            canSeeButtons: canSeeButtons,
            canSeeActivity: canSeeActivity,
            receiveNotifications: receiveNotifications,
            canComment: false
        )
        return Friend(
            id: id,
            friendId: friendId,
            friendUser: user,
            status: status,
            permissions: permissions,
            createdAt: Date()
        )
    }

    /// Creates a mock NotificationSender
    static func createMockNotificationSender(
        id: String = UUID().uuidString,
        username: String = "testuser",
        displayName: String? = "Test User"
    ) -> NotificationSender {
        return NotificationSender(
            id: id,
            username: username,
            displayName: displayName
        )
    }

    /// Creates a mock AppNotification
    static func createMockNotification(
        id: String = UUID().uuidString,
        type: NotificationType = .buttonClick,
        title: String = "Test Notification",
        message: String = "Test message",
        isRead: Bool = false,
        sender: NotificationSender? = nil
    ) -> AppNotification {
        return AppNotification(
            id: id,
            type: type,
            title: title,
            message: message,
            data: nil,
            isRead: isRead,
            createdAt: Date(),
            sender: sender ?? createMockNotificationSender()
        )
    }

    /// Creates a mock ButtonClick
    static func createMockButtonClick(
        id: String = UUID().uuidString,
        buttonId: String = "button-1",
        action: String = "click",
        duration: Int? = nil
    ) -> ButtonClick {
        return ButtonClick(
            id: id,
            buttonId: buttonId,
            action: action,
            clickedAt: Date(),
            duration: duration,
            location: nil,
            device: "Test Device",
            platform: "iphone"
        )
    }

    /// Creates a mock SubscriptionPlan
    static func createMockSubscriptionPlan(
        id: String = UUID().uuidString,
        slug: String = "free",
        name: String = "Free",
        monthlyPrice: String = "0",
        yearlyPrice: String = "0",
        isActive: Bool = true
    ) -> SubscriptionPlan {
        return SubscriptionPlan(
            id: id,
            slug: slug,
            name: name,
            description: "Test plan",
            monthlyPrice: monthlyPrice,
            yearlyPrice: yearlyPrice,
            features: ["Feature 1", "Feature 2"],
            limits: [:],
            isActive: isActive
        )
    }

    /// Creates a mock FriendButton
    static func createMockFriendButton(
        id: String = UUID().uuidString,
        name: String = "Friend's Button",
        type: ButtonType = .instant,
        currentState: ButtonState = .idle
    ) -> FriendButton {
        return FriendButton(
            id: id,
            name: name,
            type: type,
            icon: "star",
            color: "#007AFF",
            currentState: currentState,
            latestClickAt: Date(),
            latestClickAction: "click",
            latestClickLocation: nil,
            latestClickDevice: "iPhone",
            latestClickPlatform: "iphone"
        )
    }

    // MARK: - Assertion Helpers

    /// Asserts that an async operation completes within the given timeout
    static func assertAsyncOperation(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Async operation should complete")

        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Operation failed with error: \(error)", file: file, line: line)
            }
        }

        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Operation timed out", file: file, line: line)
        }
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {

    /// Creates an expectation and waits for async code to complete
    func awaitAsync(
        timeout: TimeInterval = 5.0,
        _ asyncBlock: @escaping () async throws -> Void
    ) {
        let expectation = self.expectation(description: "Async block should complete")

        Task {
            do {
                try await asyncBlock()
                expectation.fulfill()
            } catch {
                XCTFail("Async block failed with error: \(error)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: timeout)
    }
}
