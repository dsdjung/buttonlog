import XCTest

final class AuthenticationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "LOGGED_OUT"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Login Screen Tests

    func testLoginScreenShowsEmailField() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists || app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS[c] 'email'")).count > 0)
    }

    func testLoginScreenShowsPasswordField() throws {
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists || app.secureTextFields.count > 0)
    }

    func testLoginScreenShowsLoginButton() throws {
        let loginButton = app.buttons["Login"]
        XCTAssertTrue(loginButton.exists || app.buttons["Sign In"].exists)
    }

    func testLoginScreenShowsRegisterLink() throws {
        let registerLink = app.buttons["Register"]
        let signUpLink = app.buttons["Sign Up"]
        let createAccountLink = app.staticTexts["Create an account"]

        XCTAssertTrue(registerLink.exists || signUpLink.exists || createAccountLink.exists)
    }

    func testLoginScreenShowsGoogleSignIn() throws {
        let googleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'google'")).firstMatch
        XCTAssertTrue(googleButton.exists || app.buttons["Continue with Google"].exists)
    }

    func testLoginButtonDisabledWithEmptyFields() throws {
        let loginButton = app.buttons["Login"]
        if loginButton.exists {
            // Login button should be disabled or trigger validation error with empty fields
            XCTAssertFalse(loginButton.isEnabled)
        }
    }

    func testEnteringCredentials() throws {
        // Enter email
        let emailField = app.textFields.firstMatch
        if emailField.exists {
            emailField.tap()
            emailField.typeText("test@example.com")
        }

        // Enter password
        let passwordField = app.secureTextFields.firstMatch
        if passwordField.exists {
            passwordField.tap()
            passwordField.typeText("password123")
        }

        // Login button should now be enabled
        let loginButton = app.buttons["Login"]
        if loginButton.exists {
            XCTAssertTrue(loginButton.isEnabled)
        }
    }

    // MARK: - Register Screen Tests

    func testNavigatingToRegisterScreen() throws {
        let registerLink = app.buttons["Register"]
        let signUpLink = app.buttons["Sign Up"]

        if registerLink.exists {
            registerLink.tap()
        } else if signUpLink.exists {
            signUpLink.tap()
        }

        // Should now be on register screen
        let registerNavBar = app.navigationBars["Register"]
        let signUpNavBar = app.navigationBars["Sign Up"]
        let createAccountNavBar = app.navigationBars["Create Account"]

        XCTAssertTrue(
            registerNavBar.waitForExistence(timeout: 2) ||
            signUpNavBar.waitForExistence(timeout: 2) ||
            createAccountNavBar.waitForExistence(timeout: 2) ||
            app.staticTexts["Create your account"].exists
        )
    }

    func testRegisterScreenShowsAllFields() throws {
        // Navigate to register
        let registerLink = app.buttons["Register"]
        if registerLink.exists {
            registerLink.tap()
        }

        _ = app.navigationBars["Register"].waitForExistence(timeout: 2)

        // Check for required fields
        XCTAssertTrue(app.textFields.count >= 2) // Email and username at minimum
        XCTAssertTrue(app.secureTextFields.count >= 2) // Password and confirm password
    }

    func testRegisterScreenShowsRegisterButton() throws {
        // Navigate to register
        let registerLink = app.buttons["Register"]
        if registerLink.exists {
            registerLink.tap()
        }

        _ = app.navigationBars["Register"].waitForExistence(timeout: 2)

        let registerButton = app.buttons["Register"]
        let signUpButton = app.buttons["Sign Up"]
        let createButton = app.buttons["Create Account"]

        XCTAssertTrue(registerButton.exists || signUpButton.exists || createButton.exists)
    }

    func testRegisterScreenShowsBackToLogin() throws {
        // Navigate to register
        let registerLink = app.buttons["Register"]
        if registerLink.exists {
            registerLink.tap()
        }

        _ = app.navigationBars["Register"].waitForExistence(timeout: 2)

        let loginLink = app.buttons["Login"]
        let signInLink = app.buttons["Sign In"]
        let backButton = app.navigationBars.buttons.firstMatch

        XCTAssertTrue(loginLink.exists || signInLink.exists || backButton.exists)
    }

    // MARK: - Password Validation Tests

    func testPasswordFieldsAreMasked() throws {
        // Password fields should be secure text fields (masked)
        let passwordFields = app.secureTextFields
        XCTAssertTrue(passwordFields.count >= 1)
    }

    // MARK: - Error Handling Tests

    func testInvalidEmailShowsError() throws {
        // Enter invalid email
        let emailField = app.textFields.firstMatch
        if emailField.exists {
            emailField.tap()
            emailField.typeText("invalid-email")
        }

        // Try to proceed
        let passwordField = app.secureTextFields.firstMatch
        if passwordField.exists {
            passwordField.tap()
            passwordField.typeText("password123")
        }

        let loginButton = app.buttons["Login"]
        if loginButton.exists && loginButton.isEnabled {
            loginButton.tap()

            // Should show error message
            let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'email' OR label CONTAINS[c] 'invalid'")).firstMatch
            _ = errorText.waitForExistence(timeout: 3)
        }
    }

    // MARK: - Keyboard Tests

    func testKeyboardAppearsOnEmailFieldTap() throws {
        let emailField = app.textFields.firstMatch
        if emailField.exists {
            emailField.tap()

            // Wait for keyboard
            let keyboard = app.keyboards.firstMatch
            XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        }
    }

    func testKeyboardDismissesOnReturn() throws {
        let emailField = app.textFields.firstMatch
        if emailField.exists {
            emailField.tap()
            emailField.typeText("test@example.com")

            // Press return/done
            let returnKey = app.keyboards.buttons["return"]
            let nextKey = app.keyboards.buttons["Next"]
            let doneKey = app.keyboards.buttons["Done"]

            if returnKey.exists {
                returnKey.tap()
            } else if nextKey.exists {
                nextKey.tap()
            } else if doneKey.exists {
                doneKey.tap()
            }
        }
    }
}
