import XCTest
@testable import ButtonLog

// Mock APIService for testing
class MockAPIService {
    var getButtonsResult: Result<[ButtonModel], Error> = .success([])
    var getFriendsResult: Result<[Friend], Error> = .success([])
    var getNotificationsResult: Result<[AppNotification], Error> = .success([])
    var createButtonResult: Result<ButtonModel, Error>?
    var updateButtonResult: Result<ButtonModel, Error>?
    var deleteButtonResult: Result<Void, Error> = .success(())
    var clickButtonResult: Result<ButtonClick, Error>?
    var getButtonResult: Result<ButtonModel, Error>?

    var getButtonsCalled = false
    var getFriendsCalled = false
    var getNotificationsCalled = false
    var createButtonCalled = false
    var updateButtonCalled = false
    var deleteButtonCalled = false
    var clickButtonCalled = false

    func getButtons() async throws -> [ButtonModel] {
        getButtonsCalled = true
        switch getButtonsResult {
        case .success(let buttons): return buttons
        case .failure(let error): throw error
        }
    }

    func getFriends() async throws -> [Friend] {
        getFriendsCalled = true
        switch getFriendsResult {
        case .success(let friends): return friends
        case .failure(let error): throw error
        }
    }

    func getNotifications() async throws -> [AppNotification] {
        getNotificationsCalled = true
        switch getNotificationsResult {
        case .success(let notifications): return notifications
        case .failure(let error): throw error
        }
    }

    func createButton(_ formData: ButtonFormData) async throws -> ButtonModel {
        createButtonCalled = true
        guard let result = createButtonResult else {
            throw APIError.serverError("Not configured")
        }
        switch result {
        case .success(let button): return button
        case .failure(let error): throw error
        }
    }

    func updateButton(id: String, formData: ButtonFormData) async throws -> ButtonModel {
        updateButtonCalled = true
        guard let result = updateButtonResult else {
            throw APIError.serverError("Not configured")
        }
        switch result {
        case .success(let button): return button
        case .failure(let error): throw error
        }
    }

    func deleteButton(id: String) async throws {
        deleteButtonCalled = true
        switch deleteButtonResult {
        case .success: return
        case .failure(let error): throw error
        }
    }

    func clickButton(id: String) async throws -> ButtonClick {
        clickButtonCalled = true
        guard let result = clickButtonResult else {
            throw APIError.serverError("Not configured")
        }
        switch result {
        case .success(let click): return click
        case .failure(let error): throw error
        }
    }

    func getButton(id: String) async throws -> ButtonModel {
        guard let result = getButtonResult else {
            throw APIError.serverError("Not configured")
        }
        switch result {
        case .success(let button): return button
        case .failure(let error): throw error
        }
    }
}

@MainActor
final class AppStateTests: XCTestCase {

    // Helper to create test buttons
    func createTestButton(
        id: String = "test-id-1",
        name: String = "Test Button",
        type: ButtonType = .instant,
        isActive: Bool = true
    ) -> ButtonModel {
        return ButtonModel(
            id: id,
            name: name,
            description: "A test button",
            type: type,
            icon: "star",
            color: "#007AFF",
            isActive: isActive,
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
    }

    // Helper to create test friends
    func createTestFriend(
        id: String = "friend-1",
        friendId: String = "user-1",
        username: String = "testuser",
        status: FriendshipStatus = .accepted
    ) -> Friend {
        let user = PublicUser(
            id: friendId,
            username: username,
            displayName: "Test User",
            firstName: nil,
            lastName: nil,
            profileVisibility: .friends
        )
        let permissions = FriendPermissions(
            canSeeButtons: true,
            canSeeActivity: true,
            receiveNotifications: true,
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

    // Helper to create test notification
    func createTestNotification(
        id: String = "notification-1",
        isRead: Bool = false
    ) -> AppNotification {
        return AppNotification(
            id: id,
            type: .buttonClick,
            title: "Test Notification",
            message: "This is a test notification",
            data: nil,
            isRead: isRead,
            createdAt: Date(),
            sender: NotificationSender(
                id: "user-1",
                username: "testuser",
                displayName: "Test User"
            )
        )
    }

    // MARK: - Button Tests

    func testButtonsInitiallyEmpty() {
        let appState = AppState()
        XCTAssertTrue(appState.buttons.isEmpty)
    }

    func testLoadingStatesInitiallyFalse() {
        let appState = AppState()
        XCTAssertFalse(appState.isLoadingButtons)
        XCTAssertFalse(appState.isLoadingFriends)
        XCTAssertFalse(appState.isLoadingNotifications)
    }

    func testErrorMessageInitiallyNil() {
        let appState = AppState()
        XCTAssertNil(appState.errorMessage)
    }

    func testClearErrorResetsErrorMessage() {
        let appState = AppState()
        appState.errorMessage = "Some error"

        appState.clearError()

        XCTAssertNil(appState.errorMessage)
    }

    // MARK: - Notification Count Tests

    func testUnreadNotificationCount() {
        let appState = AppState()
        let unreadNotification = createTestNotification(id: "1", isRead: false)
        let readNotification = createTestNotification(id: "2", isRead: true)

        appState.notifications = [unreadNotification, readNotification]

        XCTAssertEqual(appState.unreadNotificationCount, 1)
    }

    func testUnreadNotificationCountAllRead() {
        let appState = AppState()
        let notification1 = createTestNotification(id: "1", isRead: true)
        let notification2 = createTestNotification(id: "2", isRead: true)

        appState.notifications = [notification1, notification2]

        XCTAssertEqual(appState.unreadNotificationCount, 0)
    }

    func testUnreadNotificationCountEmpty() {
        let appState = AppState()
        XCTAssertEqual(appState.unreadNotificationCount, 0)
    }

    // MARK: - Pending Friend Requests Tests

    func testPendingFriendRequests() {
        let appState = AppState()
        let acceptedFriend = createTestFriend(id: "1", status: .accepted)
        let pendingFriend = createTestFriend(id: "2", status: .pending)

        appState.friends = [acceptedFriend, pendingFriend]

        XCTAssertEqual(appState.pendingFriendRequests.count, 1)
        XCTAssertEqual(appState.pendingFriendRequests.first?.id, "2")
    }

    func testPendingFriendRequestsNoPending() {
        let appState = AppState()
        let friend1 = createTestFriend(id: "1", status: .accepted)
        let friend2 = createTestFriend(id: "2", status: .accepted)

        appState.friends = [friend1, friend2]

        XCTAssertTrue(appState.pendingFriendRequests.isEmpty)
    }

    // MARK: - State Management Tests

    func testButtonsCanBeSet() {
        let appState = AppState()
        let button = createTestButton()

        appState.buttons = [button]

        XCTAssertEqual(appState.buttons.count, 1)
        XCTAssertEqual(appState.buttons.first?.id, "test-id-1")
    }

    func testFriendsCanBeSet() {
        let appState = AppState()
        let friend = createTestFriend()

        appState.friends = [friend]

        XCTAssertEqual(appState.friends.count, 1)
        XCTAssertEqual(appState.friends.first?.id, "friend-1")
    }

    func testNotificationsCanBeSet() {
        let appState = AppState()
        let notification = createTestNotification()

        appState.notifications = [notification]

        XCTAssertEqual(appState.notifications.count, 1)
        XCTAssertEqual(appState.notifications.first?.id, "notification-1")
    }

    // MARK: - Button Removal Test

    func testButtonsCanBeRemoved() {
        let appState = AppState()
        let button1 = createTestButton(id: "1")
        let button2 = createTestButton(id: "2")

        appState.buttons = [button1, button2]
        appState.buttons.removeAll { $0.id == "1" }

        XCTAssertEqual(appState.buttons.count, 1)
        XCTAssertEqual(appState.buttons.first?.id, "2")
    }

    // MARK: - Friend Removal Test

    func testFriendsCanBeRemoved() {
        let appState = AppState()
        let friend1 = createTestFriend(id: "1", friendId: "user-1")
        let friend2 = createTestFriend(id: "2", friendId: "user-2")

        appState.friends = [friend1, friend2]
        appState.friends.removeAll { $0.friendId == "user-1" }

        XCTAssertEqual(appState.friends.count, 1)
        XCTAssertEqual(appState.friends.first?.friendId, "user-2")
    }

    // MARK: - Notification Removal Test

    func testNotificationsCanBeRemoved() {
        let appState = AppState()
        let notification1 = createTestNotification(id: "1")
        let notification2 = createTestNotification(id: "2")

        appState.notifications = [notification1, notification2]
        appState.notifications.removeAll { $0.id == "1" }

        XCTAssertEqual(appState.notifications.count, 1)
        XCTAssertEqual(appState.notifications.first?.id, "2")
    }

    // MARK: - Button Update Test

    func testButtonCanBeUpdated() {
        let appState = AppState()
        let button = createTestButton(id: "1", name: "Original Name")

        appState.buttons = [button]

        // Simulate update
        if let index = appState.buttons.firstIndex(where: { $0.id == "1" }) {
            let updatedButton = createTestButton(id: "1", name: "Updated Name")
            appState.buttons[index] = updatedButton
        }

        XCTAssertEqual(appState.buttons.first?.name, "Updated Name")
    }
}
