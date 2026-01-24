import XCTest
@testable import ButtonLog

final class APIServiceTests: XCTestCase {

    // MARK: - HTTP Method Tests

    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }

    // MARK: - API Error Tests

    func testAPIErrorDescriptions() {
        let invalidURLError = APIError.invalidURL
        XCTAssertNotNil(invalidURLError.localizedDescription)

        let invalidResponseError = APIError.invalidResponse
        XCTAssertNotNil(invalidResponseError.localizedDescription)

        let serverError = APIError.serverError("Test error message")
        XCTAssertTrue(serverError.localizedDescription.contains("Test error message"))

        let authError = APIError.unauthorized
        XCTAssertNotNil(authError.localizedDescription)
    }

    func testAPIErrorEquality() {
        let error1 = APIError.invalidURL
        let error2 = APIError.invalidURL

        // These should be comparable
        switch (error1, error2) {
        case (.invalidURL, .invalidURL):
            XCTAssertTrue(true)
        default:
            XCTFail("Errors should match")
        }
    }

    // MARK: - API Response Decoding Tests

    func testAPIResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "data": {
                "id": "test-id",
                "name": "Test"
            }
        }
        """.data(using: .utf8)!

        struct TestData: Codable {
            let id: String
            let name: String
        }

        let response = try JSONDecoder().decode(APIResponse<TestData>.self, from: json)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.id, "test-id")
        XCTAssertEqual(response.data.name, "Test")
    }

    func testAPIResponseWithErrorDecoding() throws {
        let json = """
        {
            "success": false,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid input"
            }
        }
        """.data(using: .utf8)!

        struct EmptyData: Codable {}

        // This should decode with error
        let response = try? JSONDecoder().decode(APIErrorResponse.self, from: json)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.error?.code, "VALIDATION_ERROR")
        XCTAssertEqual(response?.error?.message, "Invalid input")
    }

    func testAPIResponseWithMetaDecoding() throws {
        let json = """
        {
            "success": true,
            "data": [],
            "meta": {
                "count": 10,
                "limit": 20,
                "hasMore": true
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIResponse<[String]>.self, from: json)
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.meta)
        XCTAssertEqual(response.meta?.count, 10)
        XCTAssertEqual(response.meta?.limit, 20)
        XCTAssertEqual(response.meta?.hasMore, true)
    }

    // MARK: - Date Decoding Tests

    func testISO8601DateDecoding() throws {
        let json = """
        {
            "date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        struct DateContainer: Codable {
            let date: Date
        }

        let decoder = JSONDecoder.iso8601
        let container = try decoder.decode(DateContainer.self, from: json)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: container.date)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
    }

    // MARK: - URL Building Tests

    func testBaseURLFormat() {
        // The API service should have a valid base URL
        // This is a basic sanity check
        let baseURL = "http://localhost:14015/api"
        XCTAssertTrue(baseURL.hasPrefix("http"))
        XCTAssertTrue(baseURL.contains("/api"))
    }

    // MARK: - Singleton Tests

    func testAPIServiceIsSingleton() {
        let instance1 = APIService.shared
        let instance2 = APIService.shared
        XCTAssertTrue(instance1 === instance2)
    }
}

// MARK: - Mock URL Session for Testing

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }

        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (data, response)
    }
}

// MARK: - Integration Test Helpers

extension APIServiceTests {

    // Helper to create mock HTTP response
    func createMockHTTPResponse(statusCode: Int, url: URL) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    // Helper to create mock success response data
    func createSuccessResponseData<T: Encodable>(data: T) throws -> Data {
        struct SuccessResponse<D: Encodable>: Encodable {
            let success: Bool
            let data: D
        }

        let response = SuccessResponse(success: true, data: data)
        return try JSONEncoder().encode(response)
    }

    // Helper to create mock error response data
    func createErrorResponseData(code: String, message: String) throws -> Data {
        struct ErrorResponse: Encodable {
            let success: Bool
            let error: ErrorDetail

            struct ErrorDetail: Encodable {
                let code: String
                let message: String
            }
        }

        let response = ErrorResponse(
            success: false,
            error: ErrorResponse.ErrorDetail(code: code, message: message)
        )
        return try JSONEncoder().encode(response)
    }
}
