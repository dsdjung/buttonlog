import Foundation
@testable import ButtonLog

/// Configuration for iOS integration tests.
///
/// The base URL is determined by the TEST_API_BASE_URL environment variable
/// or defaults to the local development server.
///
/// Usage:
///   TEST_API_BASE_URL=http://localhost:14015/api xcodebuild test ...
///   TEST_API_BASE_URL=https://staging.buttonlog.com/api xcodebuild test ...
enum IntegrationTestConfig {

    /// The API base URL for integration tests.
    static var apiBaseURL: String {
        if let envURL = ProcessInfo.processInfo.environment["TEST_API_BASE_URL"] {
            return envURL.hasSuffix("/") ? String(envURL.dropLast()) : envURL
        }
        // Default to local development server
        return "http://localhost:14015/api"
    }

    /// Test user credentials for integration tests.
    /// These accounts exist in both local dev and staging environments.
    enum TestCredentials {
        // Primary iOS test user
        static let testEmail = "dsdjungtest@gmail.com"
        static let testPassword = "Test123!"
        static let testUsername = "dsdjungtest"

        // Secondary test user (Android test account) for friend operations
        static let testEmail2 = "dsdjungtest1@gmail.com"
        static let testPassword2 = "Test123!"
        static let testUsername2 = "dsdjungtest1"
    }

    /// Timeouts for integration tests (in seconds)
    enum Timeouts {
        static let apiCall: TimeInterval = 30.0
        static let testOverall: TimeInterval = 60.0
    }

    /// Check if we're running against a local development server.
    static var isLocalDev: Bool {
        apiBaseURL.contains("localhost") || apiBaseURL.contains("127.0.0.1")
    }

    /// Check if we're running against staging.
    static var isStaging: Bool {
        apiBaseURL.contains("staging")
    }

    /// Check if we're running against production.
    static var isProduction: Bool {
        apiBaseURL.contains("buttonlog.com") && !isStaging
    }
}
