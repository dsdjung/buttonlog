import XCTest
@testable import ButtonLog

@MainActor
final class AuthenticationManagerTests: XCTestCase {

    // MARK: - Initial State Tests

    func testInitialStateNotAuthenticated() {
        // Clear any existing token
        KeychainManager.shared.deleteToken()

        let authManager = AuthenticationManager()

        // Wait for initial check to complete
        let expectation = XCTestExpectation(description: "Auth check completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertNil(authManager.errorMessage)
    }

    // MARK: - Registration Validation Tests

    func testRegisterPasswordMismatchSetsError() async {
        let authManager = AuthenticationManager()

        await authManager.register(
            email: "test@example.com",
            password: "password123",
            confirmPassword: "differentpassword"
        )

        XCTAssertEqual(authManager.errorMessage, "Passwords do not match")
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isLoading)
    }

    // MARK: - Logout Tests

    func testLogoutClearsAuthState() async {
        let authManager = AuthenticationManager()

        // Simulate being logged in
        authManager.isAuthenticated = true

        // Mock user
        let user = User(
            id: "test-id",
            email: "test@example.com",
            username: "testuser",
            displayName: "Test User",
            avatar: nil,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        authManager.currentUser = user

        await authManager.logout()

        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertFalse(authManager.onboardingCompleted)
    }

    func testLogoutClearsToken() async {
        let authManager = AuthenticationManager()

        // Store a token first
        KeychainManager.shared.saveToken("test-token")
        XCTAssertNotNil(KeychainManager.shared.getToken())

        await authManager.logout()

        XCTAssertNil(KeychainManager.shared.getToken())
    }

    // MARK: - Onboarding State Tests

    func testOnboardingStatePersistsToUserDefaults() async {
        let authManager = AuthenticationManager()

        // Simulate completing onboarding
        await authManager.completeOnboarding()

        // Check UserDefaults
        let persistedValue = UserDefaults.standard.bool(forKey: "buttonlog_onboarding_completed")
        XCTAssertTrue(persistedValue)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "buttonlog_onboarding_completed")
    }

    func testOnboardingStateClearsOnLogout() async {
        let authManager = AuthenticationManager()

        // Set onboarding as completed
        await authManager.completeOnboarding()
        XCTAssertTrue(authManager.onboardingCompleted)

        await authManager.logout()

        XCTAssertFalse(authManager.onboardingCompleted)
    }

    // MARK: - Loading State Tests

    func testLoadingStateStartsAtFalse() {
        let authManager = AuthenticationManager()
        XCTAssertFalse(authManager.isLoading)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageInitiallyNil() {
        let authManager = AuthenticationManager()
        XCTAssertNil(authManager.errorMessage)
    }

    // MARK: - Token Check Tests

    func testCheckAuthenticationStatusWithNoToken() {
        // Clear any existing token
        KeychainManager.shared.deleteToken()

        let authManager = AuthenticationManager()

        // Give time for auth check
        let expectation = XCTestExpectation(description: "Auth check completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(authManager.isAuthenticated)
    }

    func testCheckAuthenticationStatusWithToken() {
        // Store a test token
        KeychainManager.shared.saveToken("test-token")

        let authManager = AuthenticationManager()

        // The presence of a token should initially set isAuthenticated to true
        // (before server verification)
        XCTAssertTrue(authManager.isAuthenticated)

        // Clean up
        KeychainManager.shared.deleteToken()
    }
}
