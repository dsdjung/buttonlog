package com.buttonlog.app.notifications

import com.google.common.truth.Truth.assertThat
import com.google.gson.Gson
import org.junit.Test

/**
 * Tests for push notification handling.
 *
 * These tests verify:
 * - Notification payload parsing
 * - Notification handling logic
 * - Deep link extraction
 * - Badge count management
 */
class PushNotificationTests {

    private val gson = Gson()

    // MARK: - Notification Payload Parsing

    @Test
    fun `button click notification parses correctly`() {
        val payload = mapOf(
            "type" to "button_click",
            "title" to "Button Clicked",
            "body" to "John clicked 'Morning Routine'",
            "data" to mapOf(
                "button_id" to "btn-123",
                "button_name" to "Morning Routine",
                "user_id" to "user-456",
                "user_name" to "John"
            )
        )

        val notification = parseNotificationPayload(payload)

        assertThat(notification.type).isEqualTo("button_click")
        assertThat(notification.title).isEqualTo("Button Clicked")
        assertThat(notification.body).isEqualTo("John clicked 'Morning Routine'")
        assertThat(notification.data?.get("button_id")).isEqualTo("btn-123")
    }

    @Test
    fun `friend request notification parses correctly`() {
        val payload = mapOf(
            "type" to "friend_request",
            "title" to "Friend Request",
            "body" to "Jane sent you a friend request",
            "data" to mapOf(
                "friend_id" to "friend-789",
                "user_id" to "user-456",
                "user_name" to "Jane"
            )
        )

        val notification = parseNotificationPayload(payload)

        assertThat(notification.type).isEqualTo("friend_request")
        assertThat(notification.title).isEqualTo("Friend Request")
        assertThat(notification.data?.get("friend_id")).isEqualTo("friend-789")
    }

    @Test
    fun `system notification parses correctly`() {
        val payload = mapOf(
            "type" to "system",
            "title" to "ButtonLog",
            "body" to "Your subscription has been renewed",
            "data" to mapOf(
                "message_type" to "subscription_renewed"
            )
        )

        val notification = parseNotificationPayload(payload)

        assertThat(notification.type).isEqualTo("system")
        assertThat(notification.data?.get("message_type")).isEqualTo("subscription_renewed")
    }

    @Test
    fun `notification with missing fields has defaults`() {
        val payload = mapOf(
            "type" to "button_click"
            // Missing title, body, and data
        )

        val notification = parseNotificationPayload(payload)

        assertThat(notification.type).isEqualTo("button_click")
        assertThat(notification.title).isEmpty()
        assertThat(notification.body).isEmpty()
        assertThat(notification.data).isNull()
    }

    // MARK: - Deep Link Extraction

    @Test
    fun `button click deep link extracts correctly`() {
        val notificationData = mapOf("button_id" to "btn-123")

        val deepLink = extractDeepLink("button_click", notificationData)

        assertThat(deepLink).isEqualTo("buttonlog://button/btn-123")
    }

    @Test
    fun `friend request deep link extracts correctly`() {
        val notificationData = mapOf("friend_id" to "friend-456")

        val deepLink = extractDeepLink("friend_request", notificationData)

        assertThat(deepLink).isEqualTo("buttonlog://friends/requests")
    }

    @Test
    fun `friend accepted deep link goes to friends`() {
        val notificationData = mapOf("friend_id" to "friend-456")

        val deepLink = extractDeepLink("friend_accepted", notificationData)

        assertThat(deepLink).isEqualTo("buttonlog://friends")
    }

    @Test
    fun `unknown type deep link returns home`() {
        val deepLink = extractDeepLink("unknown", emptyMap())

        assertThat(deepLink).isEqualTo("buttonlog://home")
    }

    // MARK: - Notification Channel Tests

    @Test
    fun `notification channel IDs are correct`() {
        assertThat(NotificationChannels.BUTTON_ALERTS.id).isEqualTo("button_alerts")
        assertThat(NotificationChannels.FRIEND_REQUESTS.id).isEqualTo("friend_requests")
        assertThat(NotificationChannels.SYSTEM.id).isEqualTo("system")
    }

    @Test
    fun `notification type maps to correct channel`() {
        assertThat(getChannelForType("button_click")).isEqualTo(NotificationChannels.BUTTON_ALERTS)
        assertThat(getChannelForType("friend_request")).isEqualTo(NotificationChannels.FRIEND_REQUESTS)
        assertThat(getChannelForType("friend_accepted")).isEqualTo(NotificationChannels.FRIEND_REQUESTS)
        assertThat(getChannelForType("system")).isEqualTo(NotificationChannels.SYSTEM)
        assertThat(getChannelForType("unknown")).isEqualTo(NotificationChannels.SYSTEM)
    }

    // MARK: - Notification Grouping

    @Test
    fun `notifications group by type`() {
        val notifications = listOf(
            ParsedNotification("button_click", "Click 1", "", mapOf("button_id" to "btn-1")),
            ParsedNotification("button_click", "Click 2", "", mapOf("button_id" to "btn-1")),
            ParsedNotification("friend_request", "Request", "", emptyMap())
        )

        val grouped = groupNotifications(notifications)

        assertThat(grouped["button_click"]?.size).isEqualTo(2)
        assertThat(grouped["friend_request"]?.size).isEqualTo(1)
    }

    @Test
    fun `button click notifications group by button`() {
        val notifications = listOf(
            ParsedNotification("button_click", "Click 1", "", mapOf("button_id" to "btn-1")),
            ParsedNotification("button_click", "Click 2", "", mapOf("button_id" to "btn-1")),
            ParsedNotification("button_click", "Click 3", "", mapOf("button_id" to "btn-2"))
        )

        val grouped = groupButtonNotifications(notifications)

        assertThat(grouped["btn-1"]?.size).isEqualTo(2)
        assertThat(grouped["btn-2"]?.size).isEqualTo(1)
    }

    // MARK: - Notification Priority Tests

    @Test
    fun `button click has high priority`() {
        val priority = getPriority("button_click")
        assertThat(priority).isEqualTo(NotificationPriority.HIGH)
    }

    @Test
    fun `friend request has default priority`() {
        val priority = getPriority("friend_request")
        assertThat(priority).isEqualTo(NotificationPriority.DEFAULT)
    }

    @Test
    fun `system notification has low priority`() {
        val priority = getPriority("system")
        assertThat(priority).isEqualTo(NotificationPriority.LOW)
    }

    // MARK: - FCM Token Handling

    @Test
    fun `FCM token is validated correctly`() {
        val validToken = "fMxwX-example-token-123456789:APA91b-valid-token"
        val invalidToken = ""
        val shortToken = "abc"

        assertThat(isValidFCMToken(validToken)).isTrue()
        assertThat(isValidFCMToken(invalidToken)).isFalse()
        assertThat(isValidFCMToken(shortToken)).isFalse()
    }

    // MARK: - Notification Actions

    @Test
    fun `button click action is correct`() {
        val action = getActionForType("button_click")
        assertThat(action).isEqualTo("VIEW_BUTTON")
    }

    @Test
    fun `friend request has accept and decline actions`() {
        val actions = getActionsForType("friend_request")
        assertThat(actions).containsExactly("ACCEPT", "DECLINE")
    }

    // MARK: - Helper Methods

    private fun parseNotificationPayload(payload: Map<String, Any?>): ParsedNotification {
        val type = payload["type"] as? String ?: "unknown"
        val title = payload["title"] as? String ?: ""
        val body = payload["body"] as? String ?: ""
        @Suppress("UNCHECKED_CAST")
        val data = payload["data"] as? Map<String, String>

        return ParsedNotification(type, title, body, data)
    }

    private fun extractDeepLink(type: String, data: Map<String, String>): String {
        return when (type) {
            "button_click" -> {
                val buttonId = data["button_id"]
                if (buttonId != null) "buttonlog://button/$buttonId"
                else "buttonlog://buttons"
            }
            "friend_request" -> "buttonlog://friends/requests"
            "friend_accepted" -> "buttonlog://friends"
            else -> "buttonlog://home"
        }
    }

    private fun getChannelForType(type: String): NotificationChannels {
        return when (type) {
            "button_click" -> NotificationChannels.BUTTON_ALERTS
            "friend_request", "friend_accepted" -> NotificationChannels.FRIEND_REQUESTS
            else -> NotificationChannels.SYSTEM
        }
    }

    private fun groupNotifications(notifications: List<ParsedNotification>): Map<String, List<ParsedNotification>> {
        return notifications.groupBy { it.type }
    }

    private fun groupButtonNotifications(notifications: List<ParsedNotification>): Map<String, List<ParsedNotification>> {
        return notifications
            .filter { it.type == "button_click" }
            .groupBy { it.data?.get("button_id") ?: "unknown" }
    }

    private fun getPriority(type: String): NotificationPriority {
        return when (type) {
            "button_click" -> NotificationPriority.HIGH
            "friend_request", "friend_accepted" -> NotificationPriority.DEFAULT
            else -> NotificationPriority.LOW
        }
    }

    private fun isValidFCMToken(token: String): Boolean {
        return token.isNotBlank() && token.length > 10
    }

    private fun getActionForType(type: String): String {
        return when (type) {
            "button_click" -> "VIEW_BUTTON"
            "friend_request" -> "VIEW_REQUEST"
            else -> "VIEW"
        }
    }

    private fun getActionsForType(type: String): List<String> {
        return when (type) {
            "friend_request" -> listOf("ACCEPT", "DECLINE")
            else -> emptyList()
        }
    }
}

// MARK: - Data Classes

data class ParsedNotification(
    val type: String,
    val title: String,
    val body: String,
    val data: Map<String, String>?
)

enum class NotificationChannels(val id: String) {
    BUTTON_ALERTS("button_alerts"),
    FRIEND_REQUESTS("friend_requests"),
    SYSTEM("system")
}

enum class NotificationPriority {
    LOW, DEFAULT, HIGH
}
