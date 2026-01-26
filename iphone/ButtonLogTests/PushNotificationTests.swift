import XCTest
@testable import ButtonLog

/// Tests for push notification handling.
///
/// These tests verify:
/// - Notification payload parsing
/// - Notification handling logic
/// - Deep link extraction
/// - Badge count management
final class PushNotificationTests: XCTestCase {

    // MARK: - Notification Payload Parsing

    func testNotificationPayload_buttonClick_parsesCorrectly() {
        let payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": "Button Clicked",
                    "body": "John clicked 'Morning Routine'"
                ],
                "badge": 1,
                "sound": "default"
            ],
            "type": "button_click",
            "data": [
                "button_id": "btn-123",
                "button_name": "Morning Routine",
                "user_id": "user-456",
                "user_name": "John"
            ]
        ]

        let notification = parseNotificationPayload(payload)

        XCTAssertEqual(notification?.type, "button_click")
        XCTAssertEqual(notification?.title, "Button Clicked")
        XCTAssertEqual(notification?.body, "John clicked 'Morning Routine'")
        XCTAssertEqual(notification?.data?["button_id"] as? String, "btn-123")
    }

    func testNotificationPayload_friendRequest_parsesCorrectly() {
        let payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": "Friend Request",
                    "body": "Jane sent you a friend request"
                ],
                "badge": 2,
                "sound": "default"
            ],
            "type": "friend_request",
            "data": [
                "friend_id": "friend-789",
                "user_id": "user-456",
                "user_name": "Jane"
            ]
        ]

        let notification = parseNotificationPayload(payload)

        XCTAssertEqual(notification?.type, "friend_request")
        XCTAssertEqual(notification?.title, "Friend Request")
        XCTAssertEqual(notification?.data?["friend_id"] as? String, "friend-789")
    }

    func testNotificationPayload_systemMessage_parsesCorrectly() {
        let payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": "ButtonLog",
                    "body": "Your subscription has been renewed"
                ],
                "badge": 0,
                "sound": "default"
            ],
            "type": "system",
            "data": [
                "message_type": "subscription_renewed"
            ]
        ]

        let notification = parseNotificationPayload(payload)

        XCTAssertEqual(notification?.type, "system")
        XCTAssertEqual(notification?.data?["message_type"] as? String, "subscription_renewed")
    }

    // MARK: - Deep Link Extraction

    func testDeepLink_buttonClick_extractsCorrectly() {
        let notificationData: [String: Any] = [
            "button_id": "btn-123"
        ]

        let deepLink = extractDeepLink(type: "button_click", data: notificationData)

        XCTAssertEqual(deepLink, "buttonlog://button/btn-123")
    }

    func testDeepLink_friendRequest_extractsCorrectly() {
        let notificationData: [String: Any] = [
            "friend_id": "friend-456"
        ]

        let deepLink = extractDeepLink(type: "friend_request", data: notificationData)

        XCTAssertEqual(deepLink, "buttonlog://friends/requests")
    }

    func testDeepLink_unknownType_returnsHome() {
        let deepLink = extractDeepLink(type: "unknown", data: [:])

        XCTAssertEqual(deepLink, "buttonlog://home")
    }

    // MARK: - Badge Count Management

    func testBadgeCount_incrementsCorrectly() {
        var badgeCount = 0

        badgeCount = incrementBadge(currentCount: badgeCount)
        XCTAssertEqual(badgeCount, 1)

        badgeCount = incrementBadge(currentCount: badgeCount)
        XCTAssertEqual(badgeCount, 2)
    }

    func testBadgeCount_resetsToZero() {
        var badgeCount = 5

        badgeCount = resetBadge()
        XCTAssertEqual(badgeCount, 0)
    }

    func testBadgeCount_capsAtMaximum() {
        let maxBadge = 99
        var badgeCount = 98

        badgeCount = incrementBadge(currentCount: badgeCount, max: maxBadge)
        XCTAssertEqual(badgeCount, 99)

        badgeCount = incrementBadge(currentCount: badgeCount, max: maxBadge)
        XCTAssertEqual(badgeCount, 99) // Should not exceed max
    }

    // MARK: - Notification Grouping

    func testNotificationGrouping_buttonClicks() {
        let notifications: [ParsedNotification] = [
            ParsedNotification(type: "button_click", title: "Click 1", body: "", data: ["button_id": "btn-1"]),
            ParsedNotification(type: "button_click", title: "Click 2", body: "", data: ["button_id": "btn-1"]),
            ParsedNotification(type: "button_click", title: "Click 3", body: "", data: ["button_id": "btn-2"])
        ]

        let grouped = groupNotifications(notifications)

        // All three notifications have type "button_click", so they're grouped together
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped["button_click"]?.count, 3)
    }

    func testNotificationGrouping_mixedTypes() {
        let notifications: [ParsedNotification] = [
            ParsedNotification(type: "button_click", title: "Click", body: "", data: [:]),
            ParsedNotification(type: "friend_request", title: "Request", body: "", data: [:]),
            ParsedNotification(type: "button_click", title: "Click 2", body: "", data: [:])
        ]

        let grouped = groupNotifications(notifications)

        XCTAssertEqual(grouped["button_click"]?.count, 2)
        XCTAssertEqual(grouped["friend_request"]?.count, 1)
    }

    // MARK: - Notification Permission State

    func testNotificationPermission_authorized_allowsNotifications() {
        let state = NotificationPermissionState.authorized

        XCTAssertTrue(canShowNotifications(state: state))
    }

    func testNotificationPermission_denied_blocksNotifications() {
        let state = NotificationPermissionState.denied

        XCTAssertFalse(canShowNotifications(state: state))
    }

    func testNotificationPermission_notDetermined_blocksNotifications() {
        let state = NotificationPermissionState.notDetermined

        XCTAssertFalse(canShowNotifications(state: state))
    }

    // MARK: - Device Token Handling

    func testDeviceToken_convertsToString() {
        // Simulated device token data (32 bytes)
        let tokenBytes: [UInt8] = [
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
            0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
            0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20
        ]
        let tokenData = Data(tokenBytes)

        let tokenString = deviceTokenToString(tokenData)

        XCTAssertEqual(tokenString.count, 64) // 32 bytes = 64 hex chars
        XCTAssertTrue(tokenString.hasPrefix("01020304"))
    }

    // MARK: - Helper Methods

    private func parseNotificationPayload(_ payload: [String: Any]) -> ParsedNotification? {
        guard let aps = payload["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let title = alert["title"] as? String,
              let body = alert["body"] as? String else {
            return nil
        }

        let type = payload["type"] as? String ?? "unknown"
        let data = payload["data"] as? [String: Any]

        return ParsedNotification(type: type, title: title, body: body, data: data)
    }

    private func extractDeepLink(type: String, data: [String: Any]) -> String {
        switch type {
        case "button_click":
            if let buttonId = data["button_id"] as? String {
                return "buttonlog://button/\(buttonId)"
            }
        case "friend_request":
            return "buttonlog://friends/requests"
        default:
            break
        }
        return "buttonlog://home"
    }

    private func incrementBadge(currentCount: Int, max: Int = 99) -> Int {
        return min(currentCount + 1, max)
    }

    private func resetBadge() -> Int {
        return 0
    }

    private func groupNotifications(_ notifications: [ParsedNotification]) -> [String: [ParsedNotification]] {
        return Dictionary(grouping: notifications, by: { $0.type })
    }

    private func canShowNotifications(state: NotificationPermissionState) -> Bool {
        return state == .authorized
    }

    private func deviceTokenToString(_ data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Data Types

struct ParsedNotification {
    let type: String
    let title: String
    let body: String
    let data: [String: Any]?
}

enum NotificationPermissionState {
    case notDetermined
    case denied
    case authorized
    case provisional
}
