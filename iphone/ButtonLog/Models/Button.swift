import Foundation
import SwiftUI

struct ButtonModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let type: ButtonType
    let icon: String
    let color: String
    let isActive: Bool
    let currentState: ButtonState
    let stateChangedAt: Date?
    let alertsEnabled: Bool
    let autoStopEnabled: Bool
    var autoStopMinutes: Int? = nil  // Duration in minutes (15, 30, 60, 120, 240, 480)
    var scheduledStopAt: Date? = nil  // When the button will auto-stop
    let calendarSyncEnabled: Bool
    let userId: String
    let createdAt: Date
    let updatedAt: Date

    // Gift button fields (with defaults for backwards compatibility)
    var createdByFriendId: String? = nil
    var createdByFriend: GiftCreator? = nil
    var giftMessage: String? = nil

    // Multiple choice options for one-time buttons
    var choices: [String]? = nil

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

    /// True if this one-time button has multiple choice options
    var hasChoices: Bool {
        return type == .oneTime && (choices?.count ?? 0) >= 2
    }

    /// Formatted auto-stop duration (e.g., "1 hour", "30 minutes")
    var autoStopDurationText: String? {
        guard let minutes = autoStopMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes == 60 {
            return "1 hour"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60) hours"
        } else {
            return "\(minutes / 60) hr \(minutes % 60) min"
        }
    }

    /// Time remaining until auto-stop (nil if not scheduled or already passed)
    var timeUntilAutoStop: TimeInterval? {
        guard let stopAt = scheduledStopAt else { return nil }
        let remaining = stopAt.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    /// Formatted time remaining until auto-stop
    var autoStopRemainingText: String? {
        guard let remaining = timeUntilAutoStop else { return nil }
        let minutes = Int(remaining / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(mins) min"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, icon, color, choices
        case isActive = "is_active"
        case currentState = "current_state"
        case stateChangedAt = "state_changed_at"
        case alertsEnabled = "alerts_enabled"
        case autoStopEnabled = "auto_stop_enabled"
        case autoStopMinutes = "auto_stop_minutes"
        case scheduledStopAt = "scheduled_stop_at"
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

/// Gift button created by the current user for a friend (recipient)
struct CreatedGiftButton: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let type: ButtonType
    let icon: String
    let color: String
    let isActive: Bool
    let currentState: ButtonState
    let stateChangedAt: Date?
    let alertsEnabled: Bool
    let autoStopEnabled: Bool
    let autoStopMinutes: Int?
    let calendarSyncEnabled: Bool
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let giftMessage: String?
    let choices: [String]?
    let recipient: GiftRecipient?

    var hexColor: String {
        return color.hasPrefix("#") ? color : "#\(color)"
    }

    var uiColor: Color {
        return Color(hex: hexColor)
    }

    /// Display name of the friend who received this gift
    var recipientName: String? {
        return recipient?.displayName ?? recipient?.username
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, icon, color, choices, recipient
        case isActive = "is_active"
        case currentState = "current_state"
        case stateChangedAt = "state_changed_at"
        case alertsEnabled = "alerts_enabled"
        case autoStopEnabled = "auto_stop_enabled"
        case autoStopMinutes = "auto_stop_minutes"
        case calendarSyncEnabled = "calendar_sync_enabled"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case giftMessage = "gift_message"
    }
}

/// Minimal user info for gift button recipient
struct GiftRecipient: Codable, Equatable {
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

// Friend alert mode for button creation
enum FriendAlertMode: String, CaseIterable {
    case none = "none"
    case allFriends = "all_friends"
    case selectSpecific = "select_specific"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .allFriends: return "All Friends"
        case .selectSpecific: return "Select Specific"
        }
    }

    var description: String {
        switch self {
        case .none: return "Only I see this button"
        case .allFriends: return "Notify all friends when clicked"
        case .selectSpecific: return "Choose specific friends to notify"
        }
    }
}

// Button creation form data
struct ButtonFormData {
    var name: String = ""
    var description: String = ""
    var type: ButtonType = .instant
    var icon: String = "star.fill"
    var color: String = "#00BFA5"
    var alertsEnabled: Bool = true
    var autoStopEnabled: Bool = false
    var autoStopMinutes: Int? = nil  // Duration in minutes (15, 30, 60, 120, 240, 480)
    var calendarSyncEnabled: Bool = false
    var choices: [String] = []  // Multiple choice options for one-time buttons

    // Friend alert configuration
    var friendAlertMode: FriendAlertMode = .none
    var selectedFriendIds: [String] = []

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// True if this form has valid choices (for one-time buttons)
    var hasValidChoices: Bool {
        let validChoices = choices.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return validChoices.count >= 2
    }

    /// Available auto-stop duration options
    static let autoStopOptions: [(minutes: Int, label: String)] = [
        (15, "15 minutes"),
        (30, "30 minutes"),
        (60, "1 hour"),
        (120, "2 hours"),
        (240, "4 hours"),
        (480, "8 hours")
    ]

    func toRequestBody() -> [String: Any] {
        var body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": description.isEmpty ? nil : description,
            "type": type.rawValue,
            "icon": icon,
            "color": color,
            "alerts_enabled": alertsEnabled,
            "auto_stop_enabled": autoStopEnabled,
            "calendar_sync_enabled": calendarSyncEnabled
        ].compactMapValues { $0 }

        // Only include auto_stop_minutes if auto-stop is enabled
        if autoStopEnabled, let minutes = autoStopMinutes {
            body["auto_stop_minutes"] = minutes
        }

        // Include choices for one-time buttons if valid
        if type == .oneTime {
            let validChoices = choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                      .filter { !$0.isEmpty }
            if validChoices.count >= 2 {
                body["choices"] = validChoices
            }
        }

        // Include friend_alerts configuration if not "none"
        if friendAlertMode != .none {
            var friendAlerts: [String: Any] = ["mode": friendAlertMode.rawValue]
            if friendAlertMode == .selectSpecific && !selectedFriendIds.isEmpty {
                friendAlerts["friend_ids"] = selectedFriendIds
            }
            body["friend_alerts"] = friendAlerts
        }

        return body
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
    let alertsEnabled: Bool
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
        case alertsEnabled = "alerts_enabled"
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

// Button alert preference for a specific friend
struct ButtonAlertPreference: Identifiable, Codable, Equatable {
    let friendId: String
    let friendUsername: String
    let friendDisplayName: String?
    var enabled: Bool
    var alertType: String

    var id: String { friendId }

    var displayName: String {
        friendDisplayName ?? friendUsername
    }

    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case friendUsername = "friend_username"
        case friendDisplayName = "friend_display_name"
        case enabled
        case alertType = "alert_type"
    }
}

// Response for toggling/setting alert preference
struct ButtonAlertPreferenceResponse: Codable {
    let friendId: String
    let enabled: Bool
    let alertType: String

    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case enabled
        case alertType = "alert_type"
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
    let selectedChoice: String?  // For one-time buttons with multiple choices
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, duration, device, platform, action
        case buttonId = "button_id"
        case userId = "user_id"
        case clickedAt = "clicked_at"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case selectedChoice = "selected_choice"
        case createdAt = "created_at"
    }
}

// MARK: - Diary Data Types

/// Diary data for a specific date
struct DiaryData: Codable {
    let date: String
    let summary: DiarySummary
    let activities: [DiaryActivity]
}

/// Summary statistics for a day
struct DiarySummary: Codable {
    let totalButtonsUsed: Int
    let totalClicks: Int
    let inProgressCount: Int

    enum CodingKeys: String, CodingKey {
        case totalButtonsUsed = "total_buttons_used"
        case totalClicks = "total_clicks"
        case inProgressCount = "in_progress_count"
    }
}

/// Activity for a single button on a given day
struct DiaryActivity: Identifiable, Codable {
    let button: DiaryButtonInfo
    let totalClicks: Int
    let clicks: [DiaryClick]

    var id: String { button.id }

    enum CodingKeys: String, CodingKey {
        case button
        case totalClicks = "total_clicks"
        case clicks
    }
}

/// Button info within diary activity
struct DiaryButtonInfo: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let icon: String
    let color: String
    let currentState: String?

    var buttonType: ButtonType {
        ButtonType(rawValue: type) ?? .instant
    }

    var hexColor: String {
        return color.hasPrefix("#") ? color : "#\(color)"
    }

    var uiColor: Color {
        return Color(hex: hexColor)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, icon, color
        case currentState = "current_state"
    }
}

/// Individual click within diary activity
struct DiaryClick: Identifiable, Codable {
    let id: String
    let clickedAt: String
    let action: String?
    let selectedChoice: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clickedAt = "clicked_at"
        case action
        case selectedChoice = "selected_choice"
    }

    /// Format the clicked_at time for display (e.g., "9:15 AM")
    var formattedTime: String {
        // Parse ISO date string
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime]

        // Try with fractional seconds first
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = inputFormatter.date(from: clickedAt) {
            return formatTime(date)
        }

        // Try without fractional seconds
        inputFormatter.formatOptions = [.withInternetDateTime]
        if let date = inputFormatter.date(from: clickedAt) {
            return formatTime(date)
        }

        // Try without timezone (backend sometimes sends "2026-01-22T01:50:40")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        if let date = dateFormatter.date(from: clickedAt) {
            return formatTime(date)
        }

        // Fallback: extract time portion
        if let timeStart = clickedAt.firstIndex(of: "T"),
           let timeEnd = clickedAt.firstIndex(of: ".") ?? clickedAt.firstIndex(of: "Z") {
            let timeSubstring = clickedAt[clickedAt.index(after: timeStart)..<timeEnd]
            return String(timeSubstring)
        }

        return clickedAt
    }

    private func formatTime(_ date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: date)
    }

    /// Format the action for display
    var formattedAction: String {
        switch action {
        case "start": return "Started"
        case "end": return "Stopped"
        case "click": return "Clicked"
        default: return "Clicked"
        }
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

    var hexString: String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
