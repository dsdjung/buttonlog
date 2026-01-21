import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let data: NotificationData?
    let isRead: Bool
    let createdAt: Date
    let readAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, message, data
        case isRead = "is_read"
        case createdAt = "created_at"
        case readAt = "read_at"
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
    
    var displayName: String {
        switch self {
        case .buttonClick: return "Button Activity"
        case .friendRequest: return "Friend Request"
        case .friendAccepted: return "Friend Accepted"
        case .buttonShared: return "Button Shared"
        case .systemAnnouncement: return "Announcement"
        case .subscriptionExpiring: return "Subscription"
        case .subscriptionRenewed: return "Subscription"
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
        }
    }
}

struct NotificationData: Codable {
    let buttonId: String?
    let buttonName: String?
    let friendId: String?
    let friendName: String?
    let actionUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case buttonId = "button_id"
        case buttonName = "button_name"
        case friendId = "friend_id"
        case friendName = "friend_name"
        case actionUrl = "action_url"
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