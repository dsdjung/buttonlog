import XCTest
@testable import ButtonLog

final class ModelTests: XCTestCase {

    // MARK: - Button Model Tests

    func testButtonCreation() {
        let button = Button(
            id: "test-id",
            name: "Test Button",
            description: "A test button",
            type: .instant,
            icon: "star",
            color: "#007AFF",
            clickCount: 5,
            currentState: .idle,
            notificationsEnabled: true,
            autoStopEnabled: false,
            calendarSyncEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            latestClick: nil
        )

        XCTAssertEqual(button.id, "test-id")
        XCTAssertEqual(button.name, "Test Button")
        XCTAssertEqual(button.type, .instant)
        XCTAssertEqual(button.clickCount, 5)
        XCTAssertEqual(button.currentState, .idle)
    }

    func testButtonTypes() {
        XCTAssertEqual(ButtonType.instant.rawValue, "instant")
        XCTAssertEqual(ButtonType.timed.rawValue, "timed")
        XCTAssertEqual(ButtonType.state.rawValue, "state")
    }

    func testButtonStates() {
        XCTAssertEqual(ButtonState.idle.rawValue, "idle")
        XCTAssertEqual(ButtonState.active.rawValue, "active")
    }

    func testButtonFormDataCreation() {
        let formData = ButtonFormData(
            name: "New Button",
            description: "Description",
            type: .timed,
            icon: "heart",
            color: "#FF0000"
        )

        XCTAssertEqual(formData.name, "New Button")
        XCTAssertEqual(formData.type, .timed)
        XCTAssertEqual(formData.color, "#FF0000")
    }

    func testButtonFormDataFromButton() {
        let button = Button(
            id: "test-id",
            name: "Existing Button",
            description: "Existing description",
            type: .state,
            icon: "bolt",
            color: "#00FF00",
            clickCount: 10,
            currentState: .active,
            notificationsEnabled: false,
            autoStopEnabled: true,
            calendarSyncEnabled: true,
            createdAt: Date(),
            updatedAt: Date(),
            latestClick: nil
        )

        let formData = ButtonFormData(from: button)

        XCTAssertEqual(formData.name, button.name)
        XCTAssertEqual(formData.description, button.description)
        XCTAssertEqual(formData.type, button.type)
        XCTAssertEqual(formData.icon, button.icon)
        XCTAssertEqual(formData.color, button.color)
    }

    // MARK: - User Model Tests

    func testUserCreation() {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            username: "testuser",
            displayName: "Test User",
            avatar: nil,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.username, "testuser")
        XCTAssertTrue(user.isVerified)
    }

    func testPublicUserDisplayNameOrUsername() {
        let userWithDisplayName = PublicUser(
            id: "1",
            username: "testuser",
            displayName: "Display Name",
            avatar: nil
        )

        let userWithoutDisplayName = PublicUser(
            id: "2",
            username: "testuser2",
            displayName: nil,
            avatar: nil
        )

        XCTAssertEqual(userWithDisplayName.displayNameOrUsername, "Display Name")
        XCTAssertEqual(userWithoutDisplayName.displayNameOrUsername, "testuser2")
    }

    func testPublicUserFullName() {
        let userWithDisplayName = PublicUser(
            id: "1",
            username: "testuser",
            displayName: "Full Display Name",
            avatar: nil
        )

        XCTAssertEqual(userWithDisplayName.fullName, "Full Display Name")
    }

    // MARK: - Friend Model Tests

    func testFriendCreation() {
        let publicUser = PublicUser(
            id: "friend-user-id",
            username: "frienduser",
            displayName: "Friend User",
            avatar: nil
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
            createdAt: Date()
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

        var emptyRequest = FriendRequest()
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
        let plan = SubscriptionPlan(
            id: "plan-123",
            slug: "premium",
            name: "Premium",
            description: "Premium features",
            monthlyPrice: "9.99",
            yearlyPrice: "99.99",
            features: ["Unlimited buttons", "Priority support"],
            limits: ["max_buttons": 100],
            isActive: true
        )

        XCTAssertEqual(plan.slug, "premium")
        XCTAssertEqual(plan.monthlyPrice, "9.99")
        XCTAssertTrue(plan.isActive)
        XCTAssertEqual(plan.features.count, 2)
    }

    func testBillingCycle() {
        XCTAssertEqual(BillingCycle.monthly.rawValue, "monthly")
        XCTAssertEqual(BillingCycle.yearly.rawValue, "yearly")
    }

    func testSubscriptionStatus() {
        XCTAssertEqual(SubscriptionStatus.active.rawValue, "active")
        XCTAssertEqual(SubscriptionStatus.canceled.rawValue, "canceled")
        XCTAssertEqual(SubscriptionStatus.paused.rawValue, "paused")
        XCTAssertEqual(SubscriptionStatus.expired.rawValue, "expired")
    }

    // MARK: - Button Click Model Tests

    func testButtonClickCreation() {
        let click = ButtonClick(
            id: "click-123",
            buttonId: "button-456",
            action: "click",
            clickedAt: Date(),
            duration: 30,
            location: nil,
            device: "iPhone 15",
            platform: "iphone"
        )

        XCTAssertEqual(click.id, "click-123")
        XCTAssertEqual(click.buttonId, "button-456")
        XCTAssertEqual(click.action, "click")
        XCTAssertEqual(click.duration, 30)
    }

    func testButtonClickWithLocation() {
        let location = ClickLocation(lat: 37.7749, lng: -122.4194)
        let click = ButtonClick(
            id: "click-123",
            buttonId: "button-456",
            action: "start",
            clickedAt: Date(),
            duration: nil,
            location: location,
            device: "iPhone 15",
            platform: "iphone"
        )

        XCTAssertNotNil(click.location)
        XCTAssertEqual(click.location?.lat, 37.7749)
        XCTAssertEqual(click.location?.lng, -122.4194)
    }

    // MARK: - FriendButton Model Tests

    func testFriendButtonCreation() {
        let friendButton = FriendButton(
            id: "button-id",
            name: "Friend's Button",
            type: .instant,
            icon: "star",
            color: "#FF0000",
            currentState: .idle,
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
        let button1 = Button(
            id: "same-id",
            name: "Button",
            description: nil,
            type: .instant,
            icon: "star",
            color: "#007AFF",
            clickCount: 0,
            currentState: .idle,
            notificationsEnabled: true,
            autoStopEnabled: false,
            calendarSyncEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            latestClick: nil
        )

        let button2 = Button(
            id: "same-id",
            name: "Button",
            description: nil,
            type: .instant,
            icon: "star",
            color: "#007AFF",
            clickCount: 0,
            currentState: .idle,
            notificationsEnabled: true,
            autoStopEnabled: false,
            calendarSyncEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            latestClick: nil
        )

        XCTAssertEqual(button1.id, button2.id)
    }
}
