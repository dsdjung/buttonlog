import XCTest
@testable import ButtonLog

final class KeychainManagerTests: XCTestCase {

    let testToken = "test-jwt-token-123"
    let testKey = "test-data-key"

    override func setUpWithError() throws {
        // Clean up any existing test data
        KeychainManager.shared.deleteToken()
        KeychainManager.shared.delete(forKey: testKey)
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        KeychainManager.shared.deleteToken()
        KeychainManager.shared.delete(forKey: testKey)
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
        KeychainManager.shared.saveToken(testToken)

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
        KeychainManager.shared.saveToken(newToken)

        // Should return new token
        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, newToken)
    }

    // MARK: - Generic Data Storage Tests

    func testSaveAndRetrieveData() {
        let testData = "Test data value".data(using: .utf8)!

        // Save data
        KeychainManager.shared.save(testData, forKey: testKey)

        // Retrieve data
        let retrievedData = KeychainManager.shared.getData(forKey: testKey)
        XCTAssertEqual(retrievedData, testData)
    }

    func testGetDataReturnsNilWhenNotSet() {
        let data = KeychainManager.shared.getData(forKey: "nonexistent-key")
        XCTAssertNil(data)
    }

    func testDeleteData() {
        let testData = "Test data".data(using: .utf8)!

        // Save then delete
        KeychainManager.shared.save(testData, forKey: testKey)
        KeychainManager.shared.delete(forKey: testKey)

        // Should be nil after deletion
        let data = KeychainManager.shared.getData(forKey: testKey)
        XCTAssertNil(data)
    }

    func testOverwriteData() {
        let initialData = "Initial".data(using: .utf8)!
        let newData = "New data".data(using: .utf8)!

        // Save initial data
        KeychainManager.shared.save(initialData, forKey: testKey)

        // Overwrite with new data
        KeychainManager.shared.save(newData, forKey: testKey)

        // Should return new data
        let retrievedData = KeychainManager.shared.getData(forKey: testKey)
        XCTAssertEqual(retrievedData, newData)
    }

    // MARK: - Edge Case Tests

    func testSaveEmptyToken() {
        let emptyToken = ""

        // Save empty token
        KeychainManager.shared.saveToken(emptyToken)

        // Should be retrievable
        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, emptyToken)
    }

    func testSaveLongToken() {
        // Create a very long token (simulating a real JWT)
        let longToken = String(repeating: "a", count: 2000)
        KeychainManager.shared.saveToken(longToken)

        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, longToken)
    }

    func testSaveTokenWithSpecialCharacters() {
        let specialToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        KeychainManager.shared.saveToken(specialToken)

        let retrievedToken = KeychainManager.shared.getToken()
        XCTAssertEqual(retrievedToken, specialToken)
    }

    func testSaveEmptyData() {
        let emptyData = Data()

        KeychainManager.shared.save(emptyData, forKey: testKey)

        let retrievedData = KeychainManager.shared.getData(forKey: testKey)
        XCTAssertEqual(retrievedData, emptyData)
    }

    func testSaveLargeData() {
        // Create large data (10KB)
        let largeData = Data(repeating: 0xAB, count: 10240)

        KeychainManager.shared.save(largeData, forKey: testKey)

        let retrievedData = KeychainManager.shared.getData(forKey: testKey)
        XCTAssertEqual(retrievedData, largeData)
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

    func testDataPersistsAfterMultipleRetrievals() {
        let testData = "Persistent data".data(using: .utf8)!
        KeychainManager.shared.save(testData, forKey: testKey)

        // Retrieve multiple times
        for _ in 0..<5 {
            let data = KeychainManager.shared.getData(forKey: testKey)
            XCTAssertEqual(data, testData)
        }
    }

    // MARK: - Key Isolation Tests

    func testDifferentKeysAreIsolated() {
        let key1 = "key1"
        let key2 = "key2"
        let data1 = "Data for key 1".data(using: .utf8)!
        let data2 = "Data for key 2".data(using: .utf8)!

        // Save different data for different keys
        KeychainManager.shared.save(data1, forKey: key1)
        KeychainManager.shared.save(data2, forKey: key2)

        // Each key should return its own data
        XCTAssertEqual(KeychainManager.shared.getData(forKey: key1), data1)
        XCTAssertEqual(KeychainManager.shared.getData(forKey: key2), data2)

        // Deleting one key shouldn't affect the other
        KeychainManager.shared.delete(forKey: key1)
        XCTAssertNil(KeychainManager.shared.getData(forKey: key1))
        XCTAssertEqual(KeychainManager.shared.getData(forKey: key2), data2)

        // Clean up
        KeychainManager.shared.delete(forKey: key2)
    }
}
