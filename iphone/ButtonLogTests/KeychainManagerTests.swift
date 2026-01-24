import XCTest
@testable import ButtonLog

final class KeychainManagerTests: XCTestCase {

    let testToken = "test-jwt-token-123"
    let testUserId = "user-id-456"

    override func setUpWithError() throws {
        // Clean up any existing test data
        KeychainManager.shared.clearAll()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        KeychainManager.shared.clearAll()
    }

    // MARK: - Singleton Tests

    func testKeychainManagerIsSingleton() {
        let instance1 = KeychainManager.shared
        let instance2 = KeychainManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Token Storage Tests

    func testSaveAndRetrieveToken() {
        // Save token
        let saveResult = KeychainManager.shared.saveToken(testToken)
        XCTAssertTrue(saveResult)

        // Retrieve token
        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, testToken)
    }

    func testGetTokenReturnsNilWhenNotSet() {
        let token = KeychainManager.shared.getToken()
        XCTAssertNil(token)
    }

    func testDeleteToken() {
        // Save then delete
        KeychainManager.shared.saveToken(testToken)
        KeychainManager.shared.deleteToken()

        // Should be nil after deletion
        let token = KeychainManager.shared.getToken()
        XCTAssertNil(token)
    }

    func testOverwriteToken() {
        let newToken = "new-token-789"

        // Save initial token
        KeychainManager.shared.saveToken(testToken)

        // Overwrite with new token
        let saveResult = KeychainManager.shared.saveToken(newToken)
        XCTAssertTrue(saveResult)

        // Should return new token
        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, newToken)
    }

    // MARK: - User ID Storage Tests

    func testSaveAndRetrieveUserId() {
        // Save user ID
        let saveResult = KeychainManager.shared.saveUserId(testUserId)
        XCTAssertTrue(saveResult)

        // Retrieve user ID
        let retrievedUserId = KeychainManager.shared.getUserId()
        XCTAssertEqual(retrievedUserId, testUserId)
    }

    func testGetUserIdReturnsNilWhenNotSet() {
        let userId = KeychainManager.shared.getUserId()
        XCTAssertNil(userId)
    }

    func testDeleteUserId() {
        // Save then delete
        KeychainManager.shared.saveUserId(testUserId)
        KeychainManager.shared.deleteUserId()

        // Should be nil after deletion
        let userId = KeychainManager.shared.getUserId()
        XCTAssertNil(userId)
    }

    // MARK: - Clear All Tests

    func testClearAllRemovesBothTokenAndUserId() {
        // Save both
        KeychainManager.shared.saveToken(testToken)
        KeychainManager.shared.saveUserId(testUserId)

        // Clear all
        KeychainManager.shared.clearAll()

        // Both should be nil
        XCTAssertNil(KeychainManager.shared.getToken())
        XCTAssertNil(KeychainManager.shared.getUserId())
    }

    // MARK: - Token Validity Tests

    func testHasValidToken() {
        // Initially should not have valid token
        XCTAssertFalse(KeychainManager.shared.hasValidToken())

        // After saving, should have valid token
        KeychainManager.shared.saveToken(testToken)
        XCTAssertTrue(KeychainManager.shared.hasValidToken())

        // After clearing, should not have valid token
        KeychainManager.shared.clearAll()
        XCTAssertFalse(KeychainManager.shared.hasValidToken())
    }

    // MARK: - Edge Case Tests

    func testSaveEmptyToken() {
        let emptyToken = ""
        let saveResult = KeychainManager.shared.saveToken(emptyToken)

        // Empty token should still be saveable
        XCTAssertTrue(saveResult)

        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, emptyToken)
    }

    func testSaveLongToken() {
        // Create a very long token (simulating a real JWT)
        let longToken = String(repeating: "a", count: 2000)
        let saveResult = KeychainManager.shared.saveToken(longToken)
        XCTAssertTrue(saveResult)

        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, longToken)
    }

    func testSaveTokenWithSpecialCharacters() {
        let specialToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        let saveResult = KeychainManager.shared.saveToken(specialToken)
        XCTAssertTrue(saveResult)

        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, specialToken)
    }

    func testSaveUserIdWithUUID() {
        let uuidUserId = "550e8400-e29b-41d4-a716-446655440000"
        let saveResult = KeychainManager.shared.saveUserId(uuidUserId)
        XCTAssertTrue(saveResult)

        let retrievedUserId = KeychainManager.shared.getUserId()
        XCTAssertEqual(retrievedUserId, uuidUserId)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentTokenAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        // Perform multiple concurrent saves and reads
        for i in 0..<10 {
            DispatchQueue.global().async {
                let token = "token-\(i)"
                KeychainManager.shared.saveToken(token)
                _ = KeychainManager.shared.getToken()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)

        // Verify we can still retrieve a token
        let finalToken = KeychainManager.shared.getToken()
        XCTAssertNotNil(finalToken)
    }

    // MARK: - Persistence Tests

    func testTokenPersistsAfterMultipleRetrievals() {
        KeychainManager.shared.saveToken(testToken)

        // Retrieve multiple times
        for _ in 0..<5 {
            let token = KeychainManager.shared.getToken()
            XCTAssertEqual(token, testToken)
        }
    }
}
