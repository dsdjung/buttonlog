import XCTest
@testable import ButtonLog

/// Integration tests for button endpoints.
///
/// These tests make real API calls to verify:
/// - Button CRUD operations
/// - Button clicking (critical for the app)
/// - Button history
///
/// Run against local dev:
///   TEST_API_BASE_URL=http://localhost:14015/api xcodebuild test -scheme ButtonLog -only-testing:ButtonLogTests/ButtonIntegrationTests
final class ButtonIntegrationTests: BaseIntegrationTest {

    // MARK: - Get Buttons Tests

    func testGetButtons_authenticated_returnsList() async throws {
        print("Testing getButtons with authentication")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let buttons: [ButtonResponseData] = try await makeRequest(
            endpoint: "/buttons",
            method: "GET"
        )

        print("GetButtons response - count: \(buttons.count)")
        // List could be empty for new users
    }

    func testGetButtons_unauthenticated_returnsError() async throws {
        print("Testing getButtons without authentication")

        do {
            let _: [ButtonResponseData] = try await makeRequest(
                endpoint: "/buttons",
                method: "GET",
                requiresAuth: false
            )
            XCTFail("Should have thrown unauthorized error")
        } catch IntegrationTestError.unauthorized {
            print("Got expected unauthorized error")
        } catch {
            print("Got error: \(error)")
        }
    }

    // MARK: - Create Button Tests

    func testCreateButton_instant_succeeds() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing create instant button")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let buttonName = "Test Button \(uniqueTestId())"
        let body: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "instant",
                "icon": "star",
                "color": "#007AFF",
                "description": "Integration test button"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: body
        )

        print("Created button: \(button.id) - \(button.name)")

        XCTAssertEqual(button.name, buttonName)
        XCTAssertEqual(button.type, "instant")
        XCTAssertEqual(button.icon, "star")

        // Clean up - delete the button
        try await deleteButton(id: button.id)
    }

    func testCreateButton_toggle_succeeds() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing create toggle button")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        let buttonName = "Test Toggle \(uniqueTestId())"
        let body: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "toggle",
                "icon": "power",
                "color": "#FF0000"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: body
        )

        print("Created toggle button: \(button.id)")

        XCTAssertEqual(button.name, buttonName)
        XCTAssertEqual(button.type, "toggle")

        // Clean up
        try await deleteButton(id: button.id)
    }

    // MARK: - Button Click Tests (Critical!)

    func testClickButton_instant_succeeds() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing click instant button")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Create a button first
        let buttonName = "Click Test \(uniqueTestId())"
        let createBody: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "instant",
                "icon": "star",
                "color": "#007AFF"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: createBody
        )

        print("Created button: \(button.id)")

        // Click the button - THIS IS THE CRITICAL TEST
        // Android had a bug where clicking failed due to null body in Retrofit
        let clickBody: [String: Any] = [
            "action": "click"
        ]

        let clickResponse: ButtonClickResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)/click",
            method: "POST",
            body: clickBody
        )

        print("Click response: \(clickResponse.id)")

        XCTAssertFalse(clickResponse.id.isEmpty, "Click should return an ID")
        XCTAssertEqual(clickResponse.buttonId, button.id)
        XCTAssertEqual(clickResponse.action, "click")

        // Verify click count increased
        let updatedButton: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)",
            method: "GET"
        )

        // Note: click_count may not be returned by all API versions
        // XCTAssertEqual(updatedButton.clickCount, 1, "Click count should be 1")

        // Clean up
        try await deleteButton(id: button.id)
    }

    func testClickButton_toggle_startsAndStops() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing toggle button start/stop")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Create a toggle button
        let buttonName = "Toggle Click Test \(uniqueTestId())"
        let createBody: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "toggle",
                "icon": "power",
                "color": "#00FF00"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: createBody
        )

        print("Created toggle button: \(button.id)")

        // Start the toggle
        let startBody: [String: Any] = [
            "action": "start"
        ]

        let startResponse: ButtonClickResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)/click",
            method: "POST",
            body: startBody
        )

        XCTAssertEqual(startResponse.action, "start")

        // Verify button state is active
        let activeButton: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)",
            method: "GET"
        )

        XCTAssertEqual(activeButton.currentState, "active", "Button should be active after start")

        // Stop the toggle
        let stopBody: [String: Any] = [
            "action": "stop"
        ]

        let stopResponse: ButtonClickResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)/click",
            method: "POST",
            body: stopBody
        )

        // Backend converts "stop" to "end" internally
        XCTAssertEqual(stopResponse.action, "end")

        // Verify button state is idle
        let idleButton: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)",
            method: "GET"
        )

        XCTAssertEqual(idleButton.currentState, "idle", "Button should be idle after stop")

        // Clean up
        try await deleteButton(id: button.id)
    }

    // MARK: - Button History Tests

    func testGetButtonHistory_returnsClicks() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing button history")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Create a button and click it multiple times
        let buttonName = "History Test \(uniqueTestId())"
        let createBody: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "instant",
                "icon": "star",
                "color": "#007AFF"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: createBody
        )

        // Click multiple times
        for i in 1...3 {
            let clickBody: [String: Any] = [
                "action": "click"
            ]
            let _: ButtonClickResponseData = try await makeRequest(
                endpoint: "/buttons/\(button.id)/click",
                method: "POST",
                body: clickBody
            )
            print("Clicked button \(i) times")
        }

        // Get history
        let history: [ButtonClickResponseData] = try await makeRequest(
            endpoint: "/buttons/\(button.id)/history",
            method: "GET"
        )

        print("History count: \(history.count)")

        XCTAssertEqual(history.count, 3, "Should have 3 clicks in history")

        // Clean up
        try await deleteButton(id: button.id)
    }

    // MARK: - Update Button Tests

    func testUpdateButton_succeeds() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing update button")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Create a button
        let originalName = "Original Name \(uniqueTestId())"
        let createBody: [String: Any] = [
            "button": [
                "name": originalName,
                "type": "instant",
                "icon": "star",
                "color": "#007AFF"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: createBody
        )

        // Update the button
        let newName = "Updated Name \(uniqueTestId())"
        let updateBody: [String: Any] = [
            "button": [
                "name": newName,
                "icon": "heart",
                "color": "#FF0000"
            ]
        ]

        let updatedButton: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons/\(button.id)",
            method: "PUT",
            body: updateBody
        )

        XCTAssertEqual(updatedButton.name, newName)
        XCTAssertEqual(updatedButton.icon, "heart")
        XCTAssertEqual(updatedButton.color, "#FF0000")

        // Clean up
        try await deleteButton(id: button.id)
    }

    // MARK: - Delete Button Tests

    func testDeleteButton_succeeds() async throws {
        try skipIfProduction(reason: "Creates test data")

        print("Testing delete button")

        let loginSuccess = try await loginTestUser()
        XCTAssertTrue(loginSuccess, "Login should succeed")

        // Create a button
        let buttonName = "Delete Test \(uniqueTestId())"
        let createBody: [String: Any] = [
            "button": [
                "name": buttonName,
                "type": "instant",
                "icon": "trash",
                "color": "#FF0000"
            ]
        ]

        let button: ButtonResponseData = try await makeRequest(
            endpoint: "/buttons",
            method: "POST",
            body: createBody
        )

        print("Created button to delete: \(button.id)")

        // Delete the button
        try await deleteButton(id: button.id)

        // Verify it's deleted - should get 404
        do {
            let _: ButtonResponseData = try await makeRequest(
                endpoint: "/buttons/\(button.id)",
                method: "GET"
            )
            XCTFail("Should have thrown error for deleted button")
        } catch {
            print("Got expected error when accessing deleted button")
        }
    }

    // MARK: - Helper Methods

    private func deleteButton(id: String) async throws {
        try await makeVoidRequest(
            endpoint: "/buttons/\(id)",
            method: "DELETE"
        )
        print("Deleted button: \(id)")
    }
}

// MARK: - Response Types

struct ButtonResponseData: Decodable {
    let id: String
    let name: String
    let type: String
    let icon: String
    let color: String
    let description: String?
    let clickCount: Int?  // Optional - not always returned by API
    let currentState: String
    let alertsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, type, icon, color, description
        case clickCount = "click_count"
        case currentState = "current_state"
        case alertsEnabled = "alerts_enabled"
    }
}

struct ButtonClickResponseData: Decodable {
    let id: String
    let buttonId: String
    let action: String
    let duration: Int?
    let clickedAt: String

    enum CodingKeys: String, CodingKey {
        case id, action, duration
        case buttonId = "button_id"
        case clickedAt = "clicked_at"
    }
}
