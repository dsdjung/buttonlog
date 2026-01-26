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
        isActive: Bool = true,
        currentState: ButtonState = .idle,
        stateChangedAt: Date? = nil,
        alertsEnabled: Bool = true,
        autoStopEnabled: Bool = false,
        autoStopMinutes: Int? = nil,
        calendarSyncEnabled: Bool = false,
        userId: String = "user-1"
    ) -> ButtonModel {
        return ButtonModel(
            id: id,
            name: name,
            description: description,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            currentState: currentState,
            stateChangedAt: stateChangedAt,
            alertsEnabled: alertsEnabled,
            autoStopEnabled: autoStopEnabled,
            autoStopMinutes: autoStopMinutes,
            scheduledStopAt: nil,
            calendarSyncEnabled: calendarSyncEnabled,
            userId: userId,
            createdAt: Date(),
            updatedAt: Date(),
            createdByFriendId: nil,
            createdByFriend: nil,
            giftMessage: nil,
            choices: nil,
            sharingMode: nil,
            shareToken: nil,
            shareTokenExpiresAt: nil,
            isSharedWithMe: nil,
            ownerId: nil,
            ownerName: nil
        )
    }

    /// Creates a mock PublicUser
    static func createMockPublicUser(
        id: String = UUID().uuidString,
        username: String = "testuser",
        displayName: String? = "Test User",
        firstName: String? = nil,
        lastName: String? = nil,
        profileVisibility: ProfileVisibility = .friends
    ) -> PublicUser {
        return PublicUser(
            id: id,
            username: username,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            profileVisibility: profileVisibility
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
            createdAt: Date(),
            updatedAt: Date()
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
        userId: String = "user-1",
        action: String? = "click",
        duration: Int? = nil,
        selectedChoice: String? = nil
    ) -> ButtonClick {
        return ButtonClick(
            id: id,
            buttonId: buttonId,
            userId: userId,
            clickedAt: Date(),
            duration: duration,
            locationLat: nil,
            locationLng: nil,
            device: "Test Device",
            platform: "iphone",
            action: action,
            selectedChoice: selectedChoice,
            createdAt: Date()
        )
    }

    /// Creates a mock SubscriptionPlan
    static func createMockSubscriptionPlan(
        id: String = UUID().uuidString,
        name: String = "Free",
        slug: String = "free",
        description: String = "Test plan",
        monthlyPrice: Double = 0.0,
        yearlyPrice: Double = 0.0,
        isActive: Bool = true
    ) -> SubscriptionPlan {
        let features = SubscriptionFeatures(
            analytics: false,
            calendarSync: false,
            apiAccess: false,
            customThemes: false,
            prioritySupport: false,
            teamFeatures: false,
            whiteLabelOptions: false
        )
        let limits = SubscriptionLimits(
            maxButtons: 5,
            maxFriends: 10,
            maxClicksPerMonth: 1000,
            analyticsHistoryDays: 7,
            exportHistoryDays: 7
        )
        return SubscriptionPlan(
            id: id,
            name: name,
            slug: slug,
            description: description,
            monthlyPrice: monthlyPrice,
            yearlyPrice: yearlyPrice,
            features: features,
            limits: limits,
            trialDays: nil,
            isActive: isActive,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Creates a mock FriendButton
    static func createMockFriendButton(
        id: String = UUID().uuidString,
        name: String = "Friend's Button",
        description: String? = nil,
        type: ButtonType = .instant,
        icon: String = "star",
        color: String = "#007AFF",
        isActive: Bool = true,
        currentState: ButtonState = .idle,
        stateChangedAt: Date? = nil,
        alertsEnabled: Bool = true,
        autoStopEnabled: Bool = false,
        calendarSyncEnabled: Bool = false,
        userId: String = "friend-user-1"
    ) -> FriendButton {
        return FriendButton(
            id: id,
            name: name,
            description: description,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            currentState: currentState,
            stateChangedAt: stateChangedAt,
            alertsEnabled: alertsEnabled,
            autoStopEnabled: autoStopEnabled,
            calendarSyncEnabled: calendarSyncEnabled,
            userId: userId,
            createdAt: Date(),
            updatedAt: Date(),
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
