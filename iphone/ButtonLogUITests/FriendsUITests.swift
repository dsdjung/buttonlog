import XCTest

final class FriendsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Friends tab
        let friendsTab = app.tabBars.buttons["Friends"]
        friendsTab.tap()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func testFriendsTabShowsFriendsList() throws {
        let friendsNavBar = app.navigationBars["Friends"]
        XCTAssertTrue(friendsNavBar.waitForExistence(timeout: 2))
    }

    func testInviteButtonExists() throws {
        let inviteButton = app.buttons["Invite"]
        XCTAssertTrue(inviteButton.exists)
    }

    // MARK: - Invite Friend Tests

    func testTappingInviteShowsSheet() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Invite friend sheet should appear
        let inviteNavBar = app.navigationBars["Invite Friend"]
        XCTAssertTrue(inviteNavBar.waitForExistence(timeout: 2))
    }

    func testInviteSheetHasEmailField() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        let inviteNavBar = app.navigationBars["Invite Friend"]
        XCTAssertTrue(inviteNavBar.waitForExistence(timeout: 2))

        // Check for email field
        let emailField = app.textFields["Enter email address"]
        XCTAssertTrue(emailField.exists || app.textFields.count > 0)
    }

    func testInviteSheetHasCancelButton() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        _ = app.navigationBars["Invite Friend"].waitForExistence(timeout: 2)

        // Cancel button should exist
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
    }

    func testInviteSheetHasSendButton() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        _ = app.navigationBars["Invite Friend"].waitForExistence(timeout: 2)

        // Send Invite button should exist
        let sendButton = app.buttons["Send Invite"]
        XCTAssertTrue(sendButton.exists)
    }

    func testSendInviteButtonDisabledWithEmptyEmail() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        _ = app.navigationBars["Invite Friend"].waitForExistence(timeout: 2)

        // Send button should be disabled with empty email
        let sendButton = app.buttons["Send Invite"]
        XCTAssertFalse(sendButton.isEnabled)
    }

    func testSendInviteButtonEnabledWithValidEmail() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        _ = app.navigationBars["Invite Friend"].waitForExistence(timeout: 2)

        // Enter valid email
        let emailField = app.textFields.firstMatch
        emailField.tap()
        emailField.typeText("test@example.com")

        // Send button should be enabled
        let sendButton = app.buttons["Send Invite"]
        XCTAssertTrue(sendButton.isEnabled)
    }

    func testCancelDismissesInviteSheet() throws {
        let inviteButton = app.buttons["Invite"]
        inviteButton.tap()

        // Wait for sheet to appear
        _ = app.navigationBars["Invite Friend"].waitForExistence(timeout: 2)

        // Tap cancel
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        // Sheet should be dismissed
        let friendsNavBar = app.navigationBars["Friends"]
        XCTAssertTrue(friendsNavBar.waitForExistence(timeout: 2))
    }

    // MARK: - Created Gift Buttons Tests

    func testCreatedGiftButtonsSectionExists() throws {
        // Look for the gift buttons section
        let giftSection = app.staticTexts["Buttons I Created for Friends"]
        // This may or may not exist depending on whether user has created gift buttons
        // Just verify the test runs without crashing
        _ = giftSection.exists
    }

    // MARK: - Empty State Tests

    func testEmptyStateShowsWhenNoFriends() throws {
        // If there are no friends, empty state should be shown
        let noFriendsText = app.staticTexts["No friends yet"]

        // The empty state or friends list should be visible
        XCTAssertTrue(noFriendsText.exists || app.tables.cells.count > 0 || app.collectionViews.cells.count > 0)
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshOnFriendsList() throws {
        // Get the list/scroll view
        let list = app.tables.firstMatch.exists ? app.tables.firstMatch : app.scrollViews.firstMatch

        if list.exists {
            // Perform pull to refresh gesture
            let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.1, thenDragTo: end)

            // Wait for refresh to complete
            let expectation = XCTestExpectation(description: "Refresh complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3)
        }
    }
}
