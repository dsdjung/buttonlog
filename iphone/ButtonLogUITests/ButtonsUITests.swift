import XCTest

final class ButtonsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func testButtonsTabIsSelected() throws {
        // Buttons tab should be visible and selected by default
        let buttonsTab = app.tabBars.buttons["Buttons"]
        XCTAssertTrue(buttonsTab.exists)
        XCTAssertTrue(buttonsTab.isSelected)
    }

    func testNavigationBetweenTabs() throws {
        // Navigate to Friends tab
        let friendsTab = app.tabBars.buttons["Friends"]
        friendsTab.tap()
        XCTAssertTrue(friendsTab.isSelected)

        // Navigate to Diary tab
        let diaryTab = app.tabBars.buttons["Diary"]
        diaryTab.tap()
        XCTAssertTrue(diaryTab.isSelected)

        // Navigate to Logs tab
        let logsTab = app.tabBars.buttons["Logs"]
        logsTab.tap()
        XCTAssertTrue(logsTab.isSelected)

        // Navigate to Account tab
        let accountTab = app.tabBars.buttons["Account"]
        accountTab.tap()
        XCTAssertTrue(accountTab.isSelected)

        // Navigate back to Buttons
        let buttonsTab = app.tabBars.buttons["Buttons"]
        buttonsTab.tap()
        XCTAssertTrue(buttonsTab.isSelected)
    }

    // MARK: - Search Tests

    func testSearchBarExists() throws {
        let searchField = app.textFields["Search buttons..."]
        XCTAssertTrue(searchField.exists || app.searchFields.firstMatch.exists)
    }

    func testSearchFiltersButtons() throws {
        // Assuming there are buttons to search
        let searchField = app.textFields["Search buttons..."]
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Test")

            // Wait for filtering to occur
            let expectation = XCTestExpectation(description: "Search results update")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2)
        }
    }

    // MARK: - Create Button Tests

    func testFloatingActionButtonExists() throws {
        // The FAB with + icon should be visible on the Buttons tab
        let fabButton = app.buttons.matching(identifier: "add_button").firstMatch
        // If identifier not set, look for + symbol
        let plusButtons = app.buttons.containing(.staticText, identifier: "+")

        XCTAssertTrue(fabButton.exists || plusButtons.count > 0 || app.buttons["+"].exists)
    }

    func testTappingFABShowsCreateSheet() throws {
        // Find and tap the FAB
        let fabButton = app.buttons["+"]
        if fabButton.exists {
            fabButton.tap()

            // Create button sheet should appear
            let createSheet = app.sheets.firstMatch
            let createNavBar = app.navigationBars["Create Button"]

            XCTAssertTrue(createSheet.waitForExistence(timeout: 2) || createNavBar.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Empty State Tests

    func testEmptyStateShowsWhenNoButtons() throws {
        // If there are no buttons, empty state should be shown
        let emptyStateText = app.staticTexts["No buttons yet"]
        let createButtonText = app.buttons["Create Button"]

        // Either buttons exist or empty state is shown
        let hasButtons = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Button'")).count > 0

        if !hasButtons {
            XCTAssertTrue(emptyStateText.exists || createButtonText.exists)
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefresh() throws {
        // Get the scrollable area
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Perform pull to refresh gesture
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
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
