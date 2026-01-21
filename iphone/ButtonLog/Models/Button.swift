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
    
    // Computed properties
    var hexColor: String {
        return color.hasPrefix("#") ? color : "#\(color)"
    }
    
    var uiColor: Color {
        return Color(hex: hexColor)
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
    }
}

enum ButtonType: String, Codable, CaseIterable {
    case instant = "instant"
    case timed = "timed"
    case state = "state"
    
    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .timed: return "Timed"
        case .state: return "State"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .instant: return "bolt.fill"
        case .timed: return "timer"
        case .state: return "power"
        }
    }
    
    var description: String {
        switch self {
        case .instant: return "Single click actions"
        case .timed: return "Start/stop timing"
        case .state: return "On/off states"
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
