import Foundation
import SwiftUI

struct Button: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let type: ButtonType
    let icon: String
    let color: String
    let isActive: Bool
    let currentState: ButtonState
    let stateChangedAt: Date?
    let notificationsEnabled: Bool
    let autoStopEnabled: Bool
    let calendarSyncEnabled: Bool
    let userId: String
    let createdAt: Date
    let updatedAt: Date

    // Gift button fields (with defaults for backwards compatibility)
    var createdByFriendId: String? = nil
    var createdByFriend: GiftCreator? = nil
    var giftMessage: String? = nil

    // Sharing fields
    var sharingMode: SharingMode? = nil
    var shareToken: String? = nil
    var shareTokenExpiresAt: Date? = nil
    var isSharedWithMe: Bool? = nil  // True if button belongs to someone else
    var ownerId: String? = nil
    var ownerName: String? = nil  // Display name of owner for shared buttons

    // Computed properties
    var hexColor: String {
        return color.hasPrefix("#") ? color : "#\(color)"
    }

    var uiColor: Color {
        return Color(hex: hexColor)
    }

    /// True if this button was created by a friend as a gift
    var isGift: Bool {
        return createdByFriendId != nil
    }

    /// Display name of the friend who created this button as a gift
    var giftFromName: String? {
        return createdByFriend?.displayName ?? createdByFriend?.username
    }

    /// True if this is someone else's button shared with the current user
    var isShared: Bool {
        return isSharedWithMe == true
    }

    /// True if the current user is the owner of this button
    var isOwner: Bool {
        return isSharedWithMe != true
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, icon, color
        case isActive = "is_active"
        case currentState = "current_state"
        case stateChangedAt = "state_changed_at"
        case notificationsEnabled = "notifications_enabled"
        case autoStopEnabled = "auto_stop_enabled"
        case calendarSyncEnabled = "calendar_sync_enabled"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdByFriendId = "created_by_friend_id"
        case createdByFriend = "created_by_friend"
        case giftMessage = "gift_message"
        case sharingMode = "sharing_mode"
        case shareToken = "share_token"
        case shareTokenExpiresAt = "share_token_expires_at"
        case isSharedWithMe = "is_shared_with_me"
        case ownerId = "owner_id"
        case ownerName = "owner_name"
    }
}

// MARK: - Sharing Mode
enum SharingMode: String, Codable, CaseIterable {
    case `private` = "private"
    case friends = "friends"
    case inviteOnly = "invite_only"
    case `public` = "public"

    var displayName: String {
        switch self {
        case .private: return "Private"
        case .friends: return "Friends Only"
        case .inviteOnly: return "Invite Only"
        case .public: return "Public Link"
        }
    }

    var description: String {
        switch self {
        case .private: return "Only you can click this button"
        case .friends: return "All your friends can click this button"
        case .inviteOnly: return "Only invited users can click this button"
        case .public: return "Anyone with the link can click this button"
        }
    }

    var systemIcon: String {
        switch self {
        case .private: return "lock.fill"
        case .friends: return "person.2.fill"
        case .inviteOnly: return "envelope.fill"
        case .public: return "link"
        }
    }
}

// MARK: - Button Collaborator
struct ButtonCollaborator: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let userName: String?
    let userDisplayName: String?
    let permission: String
    let acceptedAt: Date?
    let createdAt: Date

    var displayName: String {
        userDisplayName ?? userName ?? "Unknown"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userDisplayName = "user_display_name"
        case permission
        case acceptedAt = "accepted_at"
        case createdAt = "created_at"
    }
}

// MARK: - Share Link Response
struct ShareLinkResponse: Codable {
    let shareToken: String
    let shareUrl: String

    enum CodingKeys: String, CodingKey {
        case shareToken = "share_token"
        case shareUrl = "share_url"
    }
}

/// Minimal user info for gift button creator
struct GiftCreator: Codable, Equatable {
    let id: String
    let username: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
    }
}

enum ButtonType: String, Codable, CaseIterable {
    case instant = "instant"
    case toggle = "toggle"
    case oneTime = "one-time"
    case workflow = "workflow"

    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .toggle: return "Toggle"
        case .oneTime: return "One-Time"
        case .workflow: return "Workflow"
        }
    }

    var systemIcon: String {
        switch self {
        case .instant: return "bolt.fill"
        case .toggle: return "power"
        case .oneTime: return "1.circle.fill"
        case .workflow: return "list.bullet"
        }
    }

    var description: String {
        switch self {
        case .instant: return "Single click actions"
        case .toggle: return "Start/stop with duration tracking"
        case .oneTime: return "Use once, then archived"
        case .workflow: return "Predefined sequence of states"
        }
    }
}

enum ButtonState: String, Codable, CaseIterable {
    case idle = "idle"
    case active = "active"
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .active: return "Active"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .secondary
        case .active: return .green
        }
    }
}

// Button creation form data
struct ButtonFormData {
    var name: String = ""
    var description: String = ""
    var type: ButtonType = .instant
    var icon: String = "star.fill"
    var color: String = "#007AFF"
    var notificationsEnabled: Bool = true
    var autoStopEnabled: Bool = false
    var calendarSyncEnabled: Bool = false
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func toRequestBody() -> [String: Any] {
        return [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": description.isEmpty ? nil : description,
            "type": type.rawValue,
            "icon": icon,
            "color": color,
            "notifications_enabled": notificationsEnabled,
            "auto_stop_enabled": autoStopEnabled,
            "calendar_sync_enabled": calendarSyncEnabled
        ].compactMapValues { $0 }
    }
}

// Friend's button with latest click info (status, time, location)
struct FriendButton: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let type: ButtonType
    let icon: String
    let color: String
    let isActive: Bool
    let currentState: ButtonState
    let stateChangedAt: Date?
    let notificationsEnabled: Bool
    let autoStopEnabled: Bool
    let calendarSyncEnabled: Bool
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    // Latest click info
    let latestClickAt: Date?
    let latestClickAction: String?
    let latestClickLocation: ClickLocation?
    let latestClickDevice: String?
    let latestClickPlatform: String?

    var hexColor: String {
        return color.hasPrefix("#") ? color : "#\(color)"
    }

    var uiColor: Color {
        return Color(hex: hexColor)
    }

    var displayAction: String {
        latestClickAction ?? "click"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, icon, color
        case isActive = "is_active"
        case currentState = "current_state"
        case stateChangedAt = "state_changed_at"
        case notificationsEnabled = "notifications_enabled"
        case autoStopEnabled = "auto_stop_enabled"
        case calendarSyncEnabled = "calendar_sync_enabled"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case latestClickAt = "latest_click_at"
        case latestClickAction = "latest_click_action"
        case latestClickLocation = "latest_click_location"
        case latestClickDevice = "latest_click_device"
        case latestClickPlatform = "latest_click_platform"
    }
}

struct ClickLocation: Codable, Equatable {
    let lat: Double
    let lng: Double
}

// Button sharing setting for a specific friend
struct ButtonSharingSetting: Identifiable, Codable, Equatable {
    let friendId: String
    let friendUsername: String
    let friendDisplayName: String?
    var isShared: Bool

    var id: String { friendId }

    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case friendUsername = "friend_username"
        case friendDisplayName = "friend_display_name"
        case isShared = "is_shared"
    }
}

// Button click data
struct ButtonClick: Identifiable, Codable {
    let id: String
    let buttonId: String
    let userId: String
    let clickedAt: Date
    let duration: Int?
    let locationLat: Double?
    let locationLng: Double?
    let device: String?
    let platform: String
    let action: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, duration, device, platform, action
        case buttonId = "button_id"
        case userId = "user_id"
        case clickedAt = "clicked_at"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case createdAt = "created_at"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
