import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let data: NotificationData?
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

    // Computed property to get userId from sender for backwards compatibility
    var userId: String? {
        sender?.id
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
        case .general: return "bell"
        }
    }
}

struct NotificationData: Codable {
    let buttonId: String?
    let buttonName: String?
    let friendId: String?
    let friendName: String?
    let actionUrl: String?

    // Store additional unknown fields
    private var additionalData: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case buttonId = "button_id"
        case buttonName = "button_name"
        case friendId = "friend_id"
        case friendName = "friend_name"
        case actionUrl = "action_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        buttonId = try container.decodeIfPresent(String.self, forKey: .buttonId)
        buttonName = try container.decodeIfPresent(String.self, forKey: .buttonName)
        friendId = try container.decodeIfPresent(String.self, forKey: .friendId)
        friendName = try container.decodeIfPresent(String.self, forKey: .friendName)
        actionUrl = try container.decodeIfPresent(String.self, forKey: .actionUrl)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(buttonId, forKey: .buttonId)
        try container.encodeIfPresent(buttonName, forKey: .buttonName)
        try container.encodeIfPresent(friendId, forKey: .friendId)
        try container.encodeIfPresent(friendName, forKey: .friendName)
        try container.encodeIfPresent(actionUrl, forKey: .actionUrl)
    }
}

/// Helper for handling dynamic JSON values
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
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