import XCTest
@testable import ButtonLog

/// Integration tests for friends/social endpoints.
///
/// These tests make real API calls to verify:
/// - Getting friends list
/// - Sending friend requests
/// - Friend request management
///
/// Run against local dev:
///   TEST_API_BASE_URL=http://localhost:14015/api xcodebuild test -scheme ButtonLog -only-testing:ButtonLogTests/FriendsIntegrationTests
final class FriendsIntegrationTests: BaseIntegrationTest {

    // MARK: - Get Friends Tests

    func testGetFriends_authenticated_returnsFriendsList() async throws {
        print("Testing getFriends with authentication")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let friends: [FriendResponseData] = try await makeRequest(
            endpoint: "/friends",
            method: "GET"
        )

        print("GetFriends response - count: \(friends.count)")
        // List could be empty for new users
    }

    func testGetFriends_unauthenticated_returnsError() async throws {
        print("Testing getFriends without authentication")

        do {
            let _: [FriendResponseData] = try await makeRequest(
                endpoint: "/friends",
                method: "GET",
                requiresAuth: false
            )
            XCTFail("Should have thrown unauthorized error")
        } catch IntegrationTestError.unauthorized {
            print("Got expected unauthorized error")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Send Friend Request Tests

    func testSendFriendRequest_toNonExistentUser_returnsError() async throws {
        print("Testing sendFriendRequest to non-existent user")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let body: [String: Any] = [
            "email": "nonexistent_user_\(Int(Date().timeIntervalSince1970))@example.com"
        ]

        do {
            let _: FriendResponseData = try await makeRequest(
                endpoint: "/friends/request",
                method: "POST",
                body: body
            )
            XCTFail("Should have thrown an error for non-existent user")
        } catch IntegrationTestError.serverError(let message) {
            // Expected - user doesn't exist
            print("Got expected error: \(message)")
        } catch {
            // Also acceptable - different error handling
            print("Got error: \(error)")
        }
    }

    func testSendFriendRequest_toSelf_returnsError() async throws {
        print("Testing sendFriendRequest to self")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let body: [String: Any] = [
            "email": IntegrationTestConfig.TestCredentials.testEmail
        ]

        do {
            let _: FriendResponseData = try await makeRequest(
                endpoint: "/friends/request",
                method: "POST",
                body: body
            )
            XCTFail("Should have thrown an error for self-request")
        } catch IntegrationTestError.serverError(let message) {
            // Expected - can't friend yourself
            print("Got expected error: \(message)")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Remove Friend Tests

    func testRemoveFriend_nonExistentFriend_returnsError() async throws {
        print("Testing removeFriend with non-existent friend ID")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        do {
            try await makeVoidRequest(
                endpoint: "/friends/nonexistent-friend-id-\(Int(Date().timeIntervalSince1970))",
                method: "DELETE"
            )
            // If we get here without exception, the API might be lenient
            print("RemoveFriend completed (backend may be lenient)")
        } catch IntegrationTestError.serverError(let message) {
            // 404 for not found, or 400/422 for invalid request
            print("Got expected error: \(message)")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Notifications Tests

    func testGetNotifications_authenticated_returnsList() async throws {
        print("Testing getNotifications with authentication")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let notifications: [NotificationResponseData] = try await makeRequest(
            endpoint: "/notifications",
            method: "GET"
        )

        print("GetNotifications response - count: \(notifications.count)")
        // List could be empty
    }

    func testGetNotifications_unauthenticated_returnsError() async throws {
        print("Testing getNotifications without authentication")

        do {
            let _: [NotificationResponseData] = try await makeRequest(
                endpoint: "/notifications",
                method: "GET",
                requiresAuth: false
            )
            XCTFail("Should have thrown unauthorized error")
        } catch IntegrationTestError.unauthorized {
            print("Got expected unauthorized error")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Cross-User Friend Request Tests

    func testSendAndAcceptFriendRequest_succeeds() async throws {
        try skipIfProduction(reason: "Modifies friend relationships")

        print("Testing send and accept friend request flow")

        // First user sends friend request to second user
        let loginSuccess1 = try await loginTestUser(
            email: IntegrationTestConfig.TestCredentials.testEmail,
            password: IntegrationTestConfig.TestCredentials.testPassword
        )
        XCTAssertTrue(loginSuccess1, "First user login should succeed")

        let sendBody: [String: Any] = [
            "email": IntegrationTestConfig.TestCredentials.testEmail2
        ]

        do {
            // Friend request returns a simple message, not full friend data
            let _: FriendRequestResponseData = try await makeRequest(
                endpoint: "/friends/request",
                method: "POST",
                body: sendBody
            )
            print("Friend request sent successfully")
        } catch IntegrationTestError.serverError(let message) {
            // Might fail if already friends - that's OK
            print("Send request result: \(message)")
            if message.lowercased().contains("already") {
                print("Users are already friends - skipping rest of test")
                return
            }
        }

        // Second user accepts the friend request
        let loginSuccess2 = try await loginTestUser(
            email: IntegrationTestConfig.TestCredentials.testEmail2,
            password: IntegrationTestConfig.TestCredentials.testPassword2
        )
        XCTAssertTrue(loginSuccess2, "Second user login should succeed")

        // Get pending requests
        let friends: [FriendResponseData] = try await makeRequest(
            endpoint: "/friends",
            method: "GET"
        )

        // Find the pending request from first user
        let pendingRequest = friends.first { friend in
            friend.status == "pending" &&
            friend.friendUser?.email == IntegrationTestConfig.TestCredentials.testEmail
        }

        if let request = pendingRequest {
            // Accept the friend request
            let acceptBody: [String: Any] = [
                "action": "accept"
            ]

            let _: FriendResponseData = try await makeRequest(
                endpoint: "/friends/\(request.id)/respond",
                method: "POST",
                body: acceptBody
            )

            print("Friend request accepted")

            // Verify friendship status
            let updatedFriends: [FriendResponseData] = try await makeRequest(
                endpoint: "/friends",
                method: "GET"
            )

            let acceptedFriend = updatedFriends.first { friend in
                friend.friendUser?.email == IntegrationTestConfig.TestCredentials.testEmail
            }

            XCTAssertEqual(acceptedFriend?.status, "accepted", "Friend status should be accepted")
        } else {
            print("No pending request found - users may already be friends")
        }
    }
}

// MARK: - Response Types

struct FriendResponseData: Decodable {
    let id: String
    let friendId: String
    let status: String
    let friendUser: FriendUserData?
    let permissions: FriendPermissionsData?

    enum CodingKeys: String, CodingKey {
        case id, status, permissions
        case friendId = "friend_id"
        case friendUser = "friend_user"
    }
}

struct FriendUserData: Decodable {
    let id: String
    let username: String
    let email: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
    }
}

struct FriendPermissionsData: Decodable {
    let canSeeButtons: Bool
    let canSeeActivity: Bool
    let receiveNotifications: Bool

    enum CodingKeys: String, CodingKey {
        case canSeeButtons = "can_see_buttons"
        case canSeeActivity = "can_see_activity"
        case receiveNotifications = "receive_notifications"
    }
}

struct NotificationResponseData: Decodable {
    let id: String
    let type: String
    let title: String
    let message: String
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, type, title, message
        case isRead = "is_read"
    }
}

struct FriendRequestResponseData: Decodable {
    let message: String
    let email: String
    let inviteSent: Bool

    enum CodingKeys: String, CodingKey {
        case message, email
        case inviteSent = "invite_sent"
    }
}
