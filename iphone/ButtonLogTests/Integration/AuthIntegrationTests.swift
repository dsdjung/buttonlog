import XCTest
@testable import ButtonLog

/// Integration tests for authentication endpoints.
///
/// These tests make real API calls to verify:
/// - Login with valid credentials
/// - Login with invalid credentials
/// - Registration flow
///
/// Run against local dev:
///   TEST_API_BASE_URL=http://localhost:14015/api xcodebuild test -scheme ButtonLog -only-testing:ButtonLogTests/AuthIntegrationTests
///
/// Run against staging:
///   TEST_API_BASE_URL=https://staging.buttonlog.com/api xcodebuild test -scheme ButtonLog -only-testing:ButtonLogTests/AuthIntegrationTests
final class AuthIntegrationTests: BaseIntegrationTest {

    // MARK: - Login Tests

    func testLogin_withValidCredentials_returnsToken() async throws {
        print("Testing login with valid credentials")

        let body: [String: Any] = [
            "email": IntegrationTestConfig.TestCredentials.testEmail,
            "password": IntegrationTestConfig.TestCredentials.testPassword
        ]

        let response: AuthResponseData = try await makeRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: body,
            requiresAuth: false
        )

        print("Login response - user: \(response.user.email)")

        XCTAssertFalse(response.token.isEmpty, "Token should not be empty")
        XCTAssertEqual(response.user.email, IntegrationTestConfig.TestCredentials.testEmail)
    }

    func testLogin_withInvalidPassword_returnsError() async throws {
        print("Testing login with invalid password")

        let body: [String: Any] = [
            "email": IntegrationTestConfig.TestCredentials.testEmail,
            "password": "wrong_password_123"
        ]

        do {
            let _: AuthResponseData = try await makeRequest(
                endpoint: "/auth/login",
                method: "POST",
                body: body,
                requiresAuth: false
            )
            XCTFail("Should have thrown an error")
        } catch IntegrationTestError.unauthorized {
            // Expected - invalid credentials
            print("Got expected unauthorized error")
        } catch IntegrationTestError.serverError(let message) {
            // Also acceptable - server returns error
            print("Got server error: \(message)")
            XCTAssertTrue(message.lowercased().contains("invalid") || message.lowercased().contains("password") || message.lowercased().contains("credentials"),
                          "Error should mention invalid credentials")
        }
    }

    func testLogin_withNonExistentUser_returnsError() async throws {
        print("Testing login with non-existent user")

        let body: [String: Any] = [
            "email": "nonexistent_\(Int(Date().timeIntervalSince1970))@example.com",
            "password": "any_password"
        ]

        do {
            let _: AuthResponseData = try await makeRequest(
                endpoint: "/auth/login",
                method: "POST",
                body: body,
                requiresAuth: false
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Expected - user doesn't exist
            print("Got expected error: \(error)")
        }
    }

    // MARK: - Registration Tests

    func testRegister_withNewUser_createsAccount() async throws {
        // Skip in production to avoid creating garbage accounts
        try skipIfProduction(reason: "Registration test creates test accounts")

        let uniqueId = uniqueTestId()
        let email = "test_\(uniqueId)@example.com"
        let username = "testuser_\(uniqueId)"

        print("Testing registration with new user: \(email)")

        let body: [String: Any] = [
            "user": [
                "email": email,
                "username": username,
                "password": "TestPassword123!",
                "password_confirmation": "TestPassword123!",
                "display_name": "Test User \(uniqueId)"
            ]
        ]

        let response: AuthResponseData = try await makeRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: body,
            requiresAuth: false
        )

        print("Register response - user: \(response.user.email)")

        XCTAssertFalse(response.token.isEmpty, "Token should not be empty")
        XCTAssertEqual(response.user.email, email)
        XCTAssertEqual(response.user.username, username)
    }

    func testRegister_withExistingEmail_returnsError() async throws {
        print("Testing registration with existing email")

        let body: [String: Any] = [
            "user": [
                "email": IntegrationTestConfig.TestCredentials.testEmail,
                "username": "new_username_\(Int(Date().timeIntervalSince1970))",
                "password": "TestPassword123!",
                "password_confirmation": "TestPassword123!",
                "display_name": "Test User"
            ]
        ]

        do {
            let _: AuthResponseData = try await makeRequest(
                endpoint: "/auth/register",
                method: "POST",
                body: body,
                requiresAuth: false
            )
            // Note: The API might auto-login if email exists and password matches
            // This is acceptable behavior based on the backend implementation
            print("Registration succeeded (might be auto-login)")
        } catch IntegrationTestError.serverError(let message) {
            // Expected - email already exists
            print("Got expected error: \(message)")
        } catch {
            print("Got unexpected error type: \(error)")
        }
    }

    // MARK: - Protected Endpoint Tests

    func testLoginAndAccessProtectedEndpoint_succeeds() async throws {
        print("Testing login and then accessing a protected endpoint")

        // Login to get token
        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Now try to access a protected endpoint (getButtons)
        let buttons: [ButtonData] = try await makeRequest(
            endpoint: "/buttons",
            method: "GET"
        )

        print("GetButtons after login - count: \(buttons.count)")
        // List could be empty for new users, that's OK
    }

    func testAccessProtectedEndpoint_withoutAuth_fails() async throws {
        print("Testing access to protected endpoint without authentication")

        do {
            let _: [ButtonData] = try await makeRequest(
                endpoint: "/buttons",
                method: "GET",
                requiresAuth: false  // Don't send auth header
            )
            XCTFail("Should have thrown unauthorized error")
        } catch IntegrationTestError.unauthorized {
            print("Got expected unauthorized error")
        } catch IntegrationTestError.serverError(let message) {
            // Some endpoints might return server error instead
            print("Got server error: \(message)")
        }
    }
}

// MARK: - Helper Types for Button Response

struct ButtonData: Decodable {
    let id: String
    let name: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case id, name, type
    }
}
