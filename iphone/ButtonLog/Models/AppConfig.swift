import Foundation

/// App configuration from the server
/// Used for version requirements, feature flags, and maintenance status
struct AppConfig: Codable {
    let minSupportedVersion: VersionInfo
    let latestVersion: VersionInfo
    let features: FeatureFlags
    let maintenanceMode: Bool
    let maintenanceMessage: String?
    let apiVersion: String
    let serverTime: String

    enum CodingKeys: String, CodingKey {
        case minSupportedVersion = "min_supported_version"
        case latestVersion = "latest_version"
        case features
        case maintenanceMode = "maintenance_mode"
        case maintenanceMessage = "maintenance_message"
        case apiVersion = "api_version"
        case serverTime = "server_time"
    }
}

struct VersionInfo: Codable {
    let ios: String
    let android: String
}

struct FeatureFlags: Codable {
    let pushNotifications: Bool
    let friendAlerts: Bool
    let subscriptions: Bool
    let teams: Bool
    let organizations: Bool
    let diaryView: Bool
    let buttonSharing: Bool
    let giftButtons: Bool

    enum CodingKeys: String, CodingKey {
        case pushNotifications = "push_notifications"
        case friendAlerts = "friend_alerts"
        case subscriptions
        case teams
        case organizations
        case diaryView = "diary_view"
        case buttonSharing = "button_sharing"
        case giftButtons = "gift_buttons"
    }
}

// MARK: - Version Comparison

extension AppConfig {
    /// Check if the current app version is supported
    func isCurrentVersionSupported(currentVersion: String) -> Bool {
        return compareVersions(currentVersion, minSupportedVersion.ios) >= 0
    }

    /// Check if an update is available
    func isUpdateAvailable(currentVersion: String) -> Bool {
        return compareVersions(latestVersion.ios, currentVersion) > 0
    }

    /// Compare two semantic version strings
    /// Returns: negative if v1 < v2, 0 if equal, positive if v1 > v2
    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(parts1.count, parts2.count)

        for i in 0..<maxLength {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0

            if p1 != p2 {
                return p1 - p2
            }
        }

        return 0
    }
}
