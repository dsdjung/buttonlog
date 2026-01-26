import Foundation

/// Environment configuration for ButtonLog app.
/// Determines which backend server the app connects to.
enum AppEnvironment: String {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"

    /// The base URL for API requests
    var apiBaseURL: String {
        switch self {
        case .development:
            // Local development server (Mac running Phoenix)
            // Use localhost for simulator, or your Mac's IP for physical device
            return "http://localhost:14015/api"
        case .staging:
            return "https://staging.buttonlog.com/api"
        case .production:
            return "https://buttonlog.com/api"
        }
    }

    /// The base URL for web/OAuth endpoints (without /api)
    var webBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:14015"
        case .staging:
            return "https://staging.buttonlog.com"
        case .production:
            return "https://buttonlog.com"
        }
    }

    /// Whether to enable debug logging
    var isDebugLoggingEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }

    /// Display name for the environment (shown in UI for non-production)
    var displayName: String {
        return self.rawValue
    }
}

/// Global configuration manager for the app
final class AppConfiguration {
    static let shared = AppConfiguration()

    /// The current environment
    let environment: AppEnvironment

    /// The API base URL
    var apiBaseURL: String {
        environment.apiBaseURL
    }

    /// The web base URL (for OAuth)
    var webBaseURL: String {
        environment.webBaseURL
    }

    /// Whether debug logging is enabled
    var isDebugLoggingEnabled: Bool {
        environment.isDebugLoggingEnabled
    }

    private init() {
        // Determine environment from build configuration
        // Check Info.plist for custom environment override first
        if let envString = Bundle.main.object(forInfoDictionaryKey: "APP_ENVIRONMENT") as? String,
           let env = AppEnvironment(rawValue: envString) {
            self.environment = env
        } else {
            // Fallback to compile-time configuration
            #if DEBUG
            // In DEBUG builds, check for environment override from launch arguments
            // This allows switching environments during development
            if CommandLine.arguments.contains("-staging") {
                self.environment = .staging
            } else if CommandLine.arguments.contains("-production") {
                self.environment = .production
            } else {
                self.environment = .development
            }
            #else
            // Release builds default to production unless overridden in Info.plist
            self.environment = .production
            #endif
        }

        print("ButtonLog: Initialized with \(environment.displayName) environment")
        print("ButtonLog: API URL = \(apiBaseURL)")
    }
}
