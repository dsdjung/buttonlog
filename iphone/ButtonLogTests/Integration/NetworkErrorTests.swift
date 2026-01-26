import XCTest
@testable import ButtonLog

/// Tests for network error handling scenarios.
///
/// These tests verify the app handles various network failure conditions:
/// - Connection timeouts
/// - Server errors (5xx)
/// - Malformed responses
/// - Network connectivity issues
final class NetworkErrorTests: XCTestCase {

    var session: URLSession!

    override func setUp() async throws {
        try await super.setUp()

        // Create session with short timeout for testing
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 10.0
        session = URLSession(configuration: config)
    }

    override func tearDown() async throws {
        session = nil
        try await super.tearDown()
    }

    // MARK: - Timeout Tests

    func testRequest_withTimeout_handlesGracefully() async throws {
        // Use a non-routable IP to force timeout
        let url = URL(string: "http://10.255.255.1/api/test")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0 // Short timeout

        do {
            let _ = try await session.data(for: request)
            XCTFail("Should have timed out")
        } catch let error as URLError {
            // Expected timeout error
            XCTAssertTrue(
                error.code == .timedOut || error.code == .cannotConnectToHost,
                "Expected timeout or connection error, got: \(error.code)"
            )
            print("Got expected timeout error: \(error.localizedDescription)")
        } catch {
            print("Got error: \(error)")
            // Other network errors are acceptable
        }
    }

    func testRequest_withInvalidHost_handlesGracefully() async throws {
        let url = URL(string: "http://invalid.host.that.does.not.exist.buttonlog.test/api/test")!

        do {
            let _ = try await session.data(for: URLRequest(url: url))
            XCTFail("Should have failed with invalid host")
        } catch let error as URLError {
            XCTAssertTrue(
                error.code == .cannotFindHost || error.code == .cannotConnectToHost,
                "Expected host resolution error, got: \(error.code)"
            )
            print("Got expected DNS error: \(error.localizedDescription)")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Malformed Response Tests

    func testAPIService_withMalformedJSON_handlesGracefully() async throws {
        // Test that the decoder handles malformed JSON properly
        let malformedJSON = "{ invalid json }"
        let data = malformedJSON.data(using: .utf8)!

        do {
            let _ = try JSONDecoder().decode(IntegrationAPIResponse<[String]>.self, from: data)
            XCTFail("Should have thrown decoding error")
        } catch is DecodingError {
            print("Got expected decoding error for malformed JSON")
        }
    }

    func testAPIService_withEmptyResponse_handlesGracefully() async throws {
        let emptyData = Data()

        do {
            let _ = try JSONDecoder().decode(IntegrationAPIResponse<[String]>.self, from: emptyData)
            XCTFail("Should have thrown decoding error")
        } catch is DecodingError {
            print("Got expected decoding error for empty response")
        }
    }

    func testAPIService_withUnexpectedStructure_handlesGracefully() async throws {
        // Response with different structure than expected
        let unexpectedJSON = """
        {
            "unexpected_field": "value",
            "another_field": 123
        }
        """.data(using: .utf8)!

        do {
            let response = try JSONDecoder().decode(IntegrationAPIResponse<[String]>.self, from: unexpectedJSON)
            // If it decodes, success should be false and data should be nil
            XCTAssertFalse(response.success)
        } catch is DecodingError {
            print("Got expected decoding error for unexpected structure")
        }
    }

    // MARK: - HTTP Error Code Tests

    func testAPIError_unauthorized_parsesCorrectly() async throws {
        let errorJSON = """
        {
            "success": false,
            "error": {
                "code": "UNAUTHORIZED",
                "message": "Authentication required"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(IntegrationErrorResponse.self, from: errorJSON)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error?.code, "UNAUTHORIZED")
        XCTAssertEqual(response.error?.message, "Authentication required")
    }

    func testAPIError_validationError_parsesCorrectly() async throws {
        let errorJSON = """
        {
            "success": false,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Email is invalid",
                "details": {
                    "email": ["is invalid format"]
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(IntegrationErrorResponse.self, from: errorJSON)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error?.code, "VALIDATION_ERROR")
        XCTAssertTrue(response.error?.message?.contains("invalid") ?? false)
    }

    func testAPIError_serverError_parsesCorrectly() async throws {
        let errorJSON = """
        {
            "success": false,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "Something went wrong"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(IntegrationErrorResponse.self, from: errorJSON)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error?.code, "INTERNAL_SERVER_ERROR")
    }

    func testAPIError_rateLimited_parsesCorrectly() async throws {
        let errorJSON = """
        {
            "success": false,
            "error": {
                "code": "RATE_LIMITED",
                "message": "Too many requests. Please try again later."
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(IntegrationErrorResponse.self, from: errorJSON)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error?.code, "RATE_LIMITED")
    }

    // MARK: - Retry Logic Tests

    func testRetryableError_identifiesCorrectly() {
        // Test which errors should trigger retry
        let retryableErrors: [URLError.Code] = [
            .timedOut,
            .networkConnectionLost,
            .notConnectedToInternet
        ]

        let nonRetryableErrors: [URLError.Code] = [
            .badURL,
            .unsupportedURL,
            .cannotFindHost,
            .cancelled
        ]

        for code in retryableErrors {
            let error = URLError(code)
            XCTAssertTrue(isRetryableError(error), "\(code) should be retryable")
        }

        for code in nonRetryableErrors {
            let error = URLError(code)
            XCTAssertFalse(isRetryableError(error), "\(code) should not be retryable")
        }
    }

    // MARK: - Connection State Tests

    func testConnectionState_offline_handlesGracefully() async throws {
        // Simulate offline by using invalid URL
        let url = URL(string: "http://0.0.0.0:1/api/test")!

        do {
            let _ = try await session.data(for: URLRequest(url: url))
            XCTFail("Should have failed when offline")
        } catch {
            print("Got expected error for offline state: \(error.localizedDescription)")
            // Any network error is acceptable here
        }
    }

    // MARK: - Helper Methods

    private func isRetryableError(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet:
            return true
        default:
            return false
        }
    }
}

// MARK: - Mock Server Response Tests

extension NetworkErrorTests {

    /// Tests that the app correctly handles various HTTP status codes
    func testHTTPStatusCode_handling() {
        // 2xx - Success
        XCTAssertTrue(isSuccessStatusCode(200))
        XCTAssertTrue(isSuccessStatusCode(201))
        XCTAssertTrue(isSuccessStatusCode(204))

        // 4xx - Client errors
        XCTAssertFalse(isSuccessStatusCode(400)) // Bad Request
        XCTAssertFalse(isSuccessStatusCode(401)) // Unauthorized
        XCTAssertFalse(isSuccessStatusCode(403)) // Forbidden
        XCTAssertFalse(isSuccessStatusCode(404)) // Not Found
        XCTAssertFalse(isSuccessStatusCode(422)) // Unprocessable Entity
        XCTAssertFalse(isSuccessStatusCode(429)) // Too Many Requests

        // 5xx - Server errors
        XCTAssertFalse(isSuccessStatusCode(500)) // Internal Server Error
        XCTAssertFalse(isSuccessStatusCode(502)) // Bad Gateway
        XCTAssertFalse(isSuccessStatusCode(503)) // Service Unavailable
        XCTAssertFalse(isSuccessStatusCode(504)) // Gateway Timeout
    }

    private func isSuccessStatusCode(_ code: Int) -> Bool {
        return code >= 200 && code < 300
    }
}
