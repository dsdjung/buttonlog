import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let data: [String: String]?
    let isRead: Bool
    let createdAt: Date
    let sender: NotificationSender?

    enum CodingKeys: String, CodingKey {
        case id
        case type, title, data
        case message = "body"
        case isRead = "is_read"
        case createdAt = "inserted_at"
        case sender
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sender = try container.decodeIfPresent(NotificationSender.self, forKey: .sender)
        // Try to decode data as [String: String], fall back to nil if it fails
        // This handles empty objects {} or objects with non-string values
        data = try? container.decodeIfPresent([String: String].self, forKey: .data)
    }

    init(id: String, type: NotificationType, title: String, message: String,
         data: [String: String]?, isRead: Bool, createdAt: Date, sender: NotificationSender?) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.data = data
        self.isRead = isRead
        self.createdAt = createdAt
        self.sender = sender
    }

    // Computed property to get userId from sender for backwards compatibility
    var userId: String? {
        sender?.id
    }

    // Helper to extract common notification data fields
    var buttonId: String? {
        data?["button_id"]
    }

    var buttonName: String? {
        data?["button_name"]
    }

    var friendId: String? {
        data?["friend_id"]
    }

    var friendName: String? {
        data?["friend_name"]
    }

    var ticketId: String? {
        data?["ticket_id"]
    }
}

struct NotificationSender: Codable {
    let id: String
    let username: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
    }
}

enum NotificationType: String, Codable {
    case buttonClick = "button_click"
    case friendRequest = "friend_request"
    case friendAccepted = "friend_accepted"
    case buttonShared = "button_shared"
    case systemAnnouncement = "system_announcement"
    case subscriptionExpiring = "subscription_expiring"
    case subscriptionRenewed = "subscription_renewed"
    case supportTicketReply = "support_ticket_reply"
    case supportTicketStatusUpdate = "support_ticket_status_update"
    case giftButtonReceived = "gift_button_received"
    case giftButtonClicked = "gift_button_clicked"
    case giftButtonSent = "gift_button_sent"
    case giftButtonDeleted = "gift_button_deleted"
    case general = "general"

    // Handle unknown types gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationType(rawValue: rawValue) ?? .general
    }

    var displayName: String {
        switch self {
        case .buttonClick: return "Button Activity"
        case .friendRequest: return "Friend Request"
        case .friendAccepted: return "Friend Accepted"
        case .buttonShared: return "Button Shared"
        case .systemAnnouncement: return "Announcement"
        case .subscriptionExpiring: return "Subscription"
        case .subscriptionRenewed: return "Subscription"
        case .supportTicketReply: return "Support"
        case .supportTicketStatusUpdate: return "Support"
        case .giftButtonReceived, .giftButtonClicked, .giftButtonSent, .giftButtonDeleted: return "Gift Button"
        case .general: return "Notification"
        }
    }

    var systemIcon: String {
        switch self {
        case .buttonClick: return "hand.tap"
        case .friendRequest: return "person.crop.circle.badge.plus"
        case .friendAccepted: return "person.crop.circle.badge.checkmark"
        case .buttonShared: return "square.and.arrow.up"
        case .systemAnnouncement: return "megaphone"
        case .subscriptionExpiring: return "exclamationmark.triangle"
        case .subscriptionRenewed: return "checkmark.circle"
        case .supportTicketReply, .supportTicketStatusUpdate: return "questionmark.circle"
        case .giftButtonReceived, .giftButtonClicked, .giftButtonSent, .giftButtonDeleted: return "gift"
        case .general: return "bell"
        }
    }
}

struct NotificationPreferences: Codable {
    let buttonClickNotifications: Bool
    let friendRequestNotifications: Bool
    let systemNotifications: Bool
    let emailNotifications: Bool
    let pushNotifications: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: String?
    let quietHoursEnd: String?

    enum CodingKeys: String, CodingKey {
        case buttonClickNotifications = "button_click_notifications"
        case friendRequestNotifications = "friend_request_notifications"
        case systemNotifications = "system_notifications"
        case emailNotifications = "email_notifications"
        case pushNotifications = "push_notifications"
        case quietHoursEnabled = "quiet_hours_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }
}

// Device registration response
struct DeviceRegistration: Codable {
    let id: String
    let deviceToken: String
    let platform: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case deviceToken = "device_token"
        case platform
        case isActive = "is_active"
    }
}

struct TestNotificationResult: Codable {
    let message: String
    let successes: Int
    let failures: Int
    let totalDevices: Int

    enum CodingKeys: String, CodingKey {
        case message
        case successes
        case failures
        case totalDevices = "total_devices"
    }
}