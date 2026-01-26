import XCTest
@testable import ButtonLog

final class ModelTests: XCTestCase {

    // MARK: - Button Model Tests

    func testButtonCreation() {
        let button = ButtonModel(
            id: "test-id",
            name: "Test Button",
            description: "A test button",
            type: .instant,
            icon: "star",
            color: "#007AFF",
            isActive: true,
            currentState: .idle,
            stateChangedAt: nil,
            alertsEnabled: true,
            autoStopEnabled: false,
            autoStopMinutes: nil,
            scheduledStopAt: nil,
            calendarSyncEnabled: false,
            userId: "user-1",
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

        XCTAssertEqual(button.id, "test-id")
        XCTAssertEqual(button.name, "Test Button")
        XCTAssertEqual(button.type, .instant)
        XCTAssertTrue(button.isActive)
        XCTAssertEqual(button.currentState, .idle)
    }

    func testButtonTypes() {
        XCTAssertEqual(ButtonType.instant.rawValue, "instant")
        XCTAssertEqual(ButtonType.toggle.rawValue, "toggle")
        XCTAssertEqual(ButtonType.oneTime.rawValue, "one-time")
        XCTAssertEqual(ButtonType.workflow.rawValue, "workflow")
    }

    func testButtonStates() {
        XCTAssertEqual(ButtonState.idle.rawValue, "idle")
        XCTAssertEqual(ButtonState.active.rawValue, "active")
    }

    func testButtonFormDataCreation() {
        var formData = ButtonFormData()
        formData.name = "New Button"
        formData.description = "Description"
        formData.type = .toggle
        formData.icon = "heart"
        formData.color = "#FF0000"

        XCTAssertEqual(formData.name, "New Button")
        XCTAssertEqual(formData.type, .toggle)
        XCTAssertEqual(formData.color, "#FF0000")
    }

    func testButtonFormDataIsValid() {
        var emptyFormData = ButtonFormData()
        XCTAssertFalse(emptyFormData.isValid)

        var validFormData = ButtonFormData()
        validFormData.name = "Valid Button"
        XCTAssertTrue(validFormData.isValid)
    }

    // MARK: - User Model Tests

    func testUserCreation() {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            username: "testuser",
            displayName: "Test User",
            firstName: "Test",
            lastName: "User",
            profileVisibility: .friends,
            activityVisibility: .friends,
            subscriptionTier: .free,
            isActive: true,
            emailVerified: true,
            onboardingCompleted: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.username, "testuser")
        XCTAssertTrue(user.emailVerified)
    }

    func testPublicUserDisplayNameOrUsername() {
        let userWithDisplayName = PublicUser(
            id: "1",
            username: "testuser",
            displayName: "Display Name",
            firstName: nil,
            lastName: nil,
            profileVisibility: .friends
        )

        let userWithoutDisplayName = PublicUser(
            id: "2",
            username: "testuser2",
            displayName: nil,
            firstName: nil,
            lastName: nil,
            profileVisibility: .friends
        )

        XCTAssertEqual(userWithDisplayName.displayNameOrUsername, "Display Name")
        XCTAssertEqual(userWithoutDisplayName.displayNameOrUsername, "testuser2")
    }

    func testPublicUserFullName() {
        let userWithNames = PublicUser(
            id: "1",
            username: "testuser",
            displayName: "Display Name",
            firstName: "John",
            lastName: "Doe",
            profileVisibility: .friends
        )

        XCTAssertEqual(userWithNames.fullName, "John Doe")

        let userWithDisplayName = PublicUser(
            id: "2",
            username: "testuser2",
            displayName: "Full Display Name",
            firstName: nil,
            lastName: nil,
            profileVisibility: .friends
        )

        XCTAssertEqual(userWithDisplayName.fullName, "Full Display Name")
    }

    // MARK: - Friend Model Tests

    func testFriendCreation() {
        let publicUser = PublicUser(
            id: "friend-user-id",
            username: "frienduser",
            displayName: "Friend User",
            firstName: nil,
            lastName: nil,
            profileVisibility: .friends
        )
        let permissions = FriendPermissions(
            canSeeButtons: true,
            canSeeActivity: false,
            receiveNotifications: true,
            canComment: false
        )
        let friend = Friend(
            id: "friendship-id",
            friendId: "friend-user-id",
            friendUser: publicUser,
            status: .accepted,
            permissions: permissions,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(friend.id, "friendship-id")
        XCTAssertEqual(friend.friendId, "friend-user-id")
        XCTAssertEqual(friend.status, .accepted)
        XCTAssertTrue(friend.permissions.canSeeButtons)
        XCTAssertFalse(friend.permissions.canSeeActivity)
    }

    func testFriendshipStatus() {
        XCTAssertEqual(FriendshipStatus.pending.rawValue, "pending")
        XCTAssertEqual(FriendshipStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(FriendshipStatus.blocked.rawValue, "blocked")
    }

    func testFriendRequest() {
        var request = FriendRequest()
        request.email = "friend@example.com"
        request.username = ""
        request.message = "Let's be friends!"

        XCTAssertEqual(request.email, "friend@example.com")
        XCTAssertEqual(request.message, "Let's be friends!")
    }

    func testFriendRequestIsValid() {
        var requestWithEmail = FriendRequest()
        requestWithEmail.email = "test@example.com"
        XCTAssertTrue(requestWithEmail.isValid)

        var requestWithUsername = FriendRequest()
        requestWithUsername.username = "testuser"
        XCTAssertTrue(requestWithUsername.isValid)

        let emptyRequest = FriendRequest()
        XCTAssertFalse(emptyRequest.isValid)
    }

    // MARK: - Notification Model Tests

    func testAppNotificationCreation() {
        let sender = NotificationSender(
            id: "user-id",
            username: "testuser",
            displayName: "Test User"
        )
        let notification = AppNotification(
            id: "notification-id",
            type: .buttonClick,
            title: "Button Clicked",
            message: "Your friend clicked a button",
            data: nil,
            isRead: false,
            createdAt: Date(),
            sender: sender
        )

        XCTAssertEqual(notification.id, "notification-id")
        XCTAssertEqual(notification.type, .buttonClick)
        XCTAssertFalse(notification.isRead)
        XCTAssertEqual(notification.userId, "user-id")
        XCTAssertEqual(notification.sender?.username, "testuser")
    }

    func testNotificationTypes() {
        XCTAssertEqual(NotificationType.buttonClick.rawValue, "button_click")
        XCTAssertEqual(NotificationType.friendRequest.rawValue, "friend_request")
        XCTAssertEqual(NotificationType.friendAccepted.rawValue, "friend_accepted")
        XCTAssertEqual(NotificationType.general.rawValue, "general")
    }

    // MARK: - Subscription Model Tests

    func testSubscriptionPlanCreation() {
        let features = SubscriptionFeatures(
            analytics: true,
            calendarSync: true,
            apiAccess: true,
            customThemes: true,
            prioritySupport: true,
            teamFeatures: false,
            whiteLabelOptions: false
        )
        let limits = SubscriptionLimits(
            maxButtons: 100,
            maxFriends: 100,
            maxClicksPerMonth: 10000,
            analyticsHistoryDays: 365,
            exportHistoryDays: 365
        )
        let plan = SubscriptionPlan(
            id: "plan-123",
            name: "Premium",
            slug: "premium",
            description: "Premium features",
            monthlyPrice: 9.99,
            yearlyPrice: 99.99,
            features: features,
            limits: limits,
            trialDays: 14,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(plan.slug, "premium")
        XCTAssertEqual(plan.monthlyPrice, 9.99)
        XCTAssertTrue(plan.isActive)
        XCTAssertTrue(plan.features.analytics)
    }

    func testBillingCycle() {
        XCTAssertEqual(BillingCycle.monthly.rawValue, "monthly")
        XCTAssertEqual(BillingCycle.yearly.rawValue, "yearly")
    }

    func testSubscriptionStatus() {
        XCTAssertEqual(SubscriptionStatus.active.rawValue, "active")
        XCTAssertEqual(SubscriptionStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(SubscriptionStatus.paused.rawValue, "paused")
        XCTAssertEqual(SubscriptionStatus.pastDue.rawValue, "past_due")
        XCTAssertEqual(SubscriptionStatus.trialing.rawValue, "trialing")
    }

    // MARK: - Button Click Model Tests

    func testButtonClickCreation() {
        let click = ButtonClick(
            id: "click-123",
            buttonId: "button-456",
            userId: "user-789",
            clickedAt: Date(),
            duration: 30,
            locationLat: nil,
            locationLng: nil,
            device: "iPhone 15",
            platform: "iphone",
            action: "click",
            selectedChoice: nil,
            createdAt: Date()
        )

        XCTAssertEqual(click.id, "click-123")
        XCTAssertEqual(click.buttonId, "button-456")
        XCTAssertEqual(click.action, "click")
        XCTAssertEqual(click.duration, 30)
    }

    func testButtonClickWithLocation() {
        let click = ButtonClick(
            id: "click-123",
            buttonId: "button-456",
            userId: "user-789",
            clickedAt: Date(),
            duration: nil,
            locationLat: 37.7749,
            locationLng: -122.4194,
            device: "iPhone 15",
            platform: "iphone",
            action: "start",
            selectedChoice: nil,
            createdAt: Date()
        )

        XCTAssertNotNil(click.locationLat)
        XCTAssertNotNil(click.locationLng)
        XCTAssertEqual(click.locationLat, 37.7749)
        XCTAssertEqual(click.locationLng, -122.4194)
    }

    // MARK: - FriendButton Model Tests

    func testFriendButtonCreation() {
        let friendButton = FriendButton(
            id: "button-id",
            name: "Friend's Button",
            description: nil,
            type: .instant,
            icon: "star",
            color: "#FF0000",
            isActive: true,
            currentState: .idle,
            stateChangedAt: nil,
            alertsEnabled: true,
            autoStopEnabled: false,
            calendarSyncEnabled: false,
            userId: "friend-user-1",
            createdAt: Date(),
            updatedAt: Date(),
            latestClickAt: Date(),
            latestClickAction: "click",
            latestClickLocation: nil,
            latestClickDevice: "iPhone",
            latestClickPlatform: "iphone"
        )

        XCTAssertEqual(friendButton.id, "button-id")
        XCTAssertEqual(friendButton.name, "Friend's Button")
        XCTAssertEqual(friendButton.type, .instant)
    }

    // MARK: - Button Sharing Model Tests

    func testButtonSharingSettingCreation() {
        let sharing = ButtonSharingSetting(
            friendId: "friend-id",
            friendUsername: "frienduser",
            friendDisplayName: "Friend User",
            isShared: true
        )

        XCTAssertEqual(sharing.friendId, "friend-id")
        XCTAssertEqual(sharing.friendUsername, "frienduser")
        XCTAssertTrue(sharing.isShared)
    }

    // MARK: - Equality Tests

    func testButtonEquality() {
        let button1 = ButtonModel(
            id: "same-id",
            name: "Button",
            description: nil,
            type: .instant,
            icon: "star",
            color: "#007AFF",
            isActive: true,
            currentState: .idle,
            stateChangedAt: nil,
            alertsEnabled: true,
            autoStopEnabled: false,
            autoStopMinutes: nil,
            scheduledStopAt: nil,
            calendarSyncEnabled: false,
            userId: "user-1",
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

        let button2 = ButtonModel(
            id: "same-id",
            name: "Button",
            description: nil,
            type: .instant,
            icon: "star",
            color: "#007AFF",
            isActive: true,
            currentState: .idle,
            stateChangedAt: nil,
            alertsEnabled: true,
            autoStopEnabled: false,
            autoStopMinutes: nil,
            scheduledStopAt: nil,
            calendarSyncEnabled: false,
            userId: "user-1",
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

        XCTAssertEqual(button1.id, button2.id)
    }
}
