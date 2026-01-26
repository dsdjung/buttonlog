import XCTest
@testable import ButtonLog

/// Base class for integration tests that make real API calls.
///
/// This class sets up a real URLSession that connects to the configured
/// API server. Use this for testing actual API behavior.
///
/// Usage:
///   class MyIntegrationTest: BaseIntegrationTest {
///       func testSomething() async throws {
///           try await loginTestUser()
///           let response = try await makeRequest(...)
///           // assertions
///       }
///   }
class BaseIntegrationTest: XCTestCase {

    /// The URL session for making requests
    var session: URLSession!

    /// Store auth token for authenticated requests
    var authToken: String?

    /// Base URL for API requests
    var baseURL: String {
        IntegrationTestConfig.apiBaseURL
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        print("Setting up integration test")
        print("API Base URL: \(baseURL)")

        // Create URL session with timeout configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = IntegrationTestConfig.Timeouts.apiCall
        config.timeoutIntervalForResource = IntegrationTestConfig.Timeouts.testOverall
        session = URLSession(configuration: config)

        authToken = nil
    }

    override func tearDown() async throws {
        authToken = nil
        session = nil
        try await super.tearDown()
    }

    // MARK: - Authentication Helpers

    /// Login with test credentials and store the auth token.
    @discardableResult
    func loginTestUser(
        email: String = IntegrationTestConfig.TestCredentials.testEmail,
        password: String = IntegrationTestConfig.TestCredentials.testPassword
    ) async throws -> Bool {
        print("Logging in test user: \(email)")

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        do {
            let response: AuthResponseData = try await makeRequest(
                endpoint: "/auth/login",
                method: "POST",
                body: body,
                requiresAuth: false
            )
            authToken = response.token
            print("Login successful, token obtained")
            return true
        } catch {
            print("Login failed: \(error)")
            return false
        }
    }

    // MARK: - Request Helpers

    /// Make an API request and decode the response
    func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw IntegrationTestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("1.0.0", forHTTPHeaderField: "X-App-Version")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")

        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        print("Making \(method) request to \(url)")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.invalidResponse
        }

        print("Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString.prefix(500))")
        }

        // Decode the API response wrapper
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let apiResponse = try decoder.decode(IntegrationAPIResponse<T>.self, from: data)
            if apiResponse.success {
                guard let responseData = apiResponse.data else {
                    throw IntegrationTestError.noData
                }
                return responseData
            } else {
                throw IntegrationTestError.serverError(apiResponse.error?.message ?? "Unknown error")
            }
        } else if httpResponse.statusCode == 401 {
            throw IntegrationTestError.unauthorized
        } else {
            let errorResponse = try? decoder.decode(IntegrationErrorResponse.self, from: data)
            throw IntegrationTestError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    /// Make an API request that returns a simple success/failure response
    func makeVoidRequest(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw IntegrationTestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.invalidResponse
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let decoder = JSONDecoder()
            let errorResponse = try? decoder.decode(IntegrationErrorResponse.self, from: data)
            throw IntegrationTestError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    // MARK: - Test Helpers

    /// Skip test if running against production (for destructive tests).
    func skipIfProduction(reason: String = "Test skipped in production environment") throws {
        try XCTSkipIf(IntegrationTestConfig.isProduction, reason)
    }

    /// Generate a unique test identifier for test data.
    func uniqueTestId() -> String {
        return "test_\(Int(Date().timeIntervalSince1970))_\(Int.random(in: 1000...9999))"
    }
}

// MARK: - Response Types for Integration Tests

struct IntegrationAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: IntegrationAPIError?
}

struct IntegrationErrorResponse: Decodable {
    let success: Bool
    let error: IntegrationAPIError?
}

struct IntegrationAPIError: Decodable {
    let code: String?
    let message: String?
}

struct AuthResponseData: Decodable {
    let token: String
    let user: AuthUserData
}

struct AuthUserData: Decodable {
    let id: String
    let email: String
    let username: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case displayName = "display_name"
    }
}

// MARK: - Error Types

enum IntegrationTestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data in response"
        case .unauthorized:
            return "Unauthorized"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
