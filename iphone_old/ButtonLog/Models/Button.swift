import Foundation

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
    
    var uiColor: String {
        return hexColor
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
    
    var icon: String {
        switch self {
        case .instant: return "bolt.fill"
        case .timed: return "timer"
        case .state: return "toggle.on"
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
    
    var color: String {
        switch self {
        case .idle: return "gray"
        case .active: return "green"
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
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, duration, device, platform
        case buttonId = "button_id"
        case userId = "user_id"
        case clickedAt = "clicked_at"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case createdAt = "created_at"
    }
}
