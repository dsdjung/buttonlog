package com.buttonlog.app.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AuthScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun loginScreen_showsEmailAndPasswordFields() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Email").assertIsDisplayed()
        composeTestRule.onNodeWithText("Password").assertIsDisplayed()
    }

    @Test
    fun loginScreen_showsLoginButton() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Login").assertIsDisplayed()
    }

    @Test
    fun loginScreen_showsRegisterLink() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Register", substring = true).assertIsDisplayed()
    }

    @Test
    fun loginScreen_showsGoogleSignInOption() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Google", substring = true).assertIsDisplayed()
    }

    @Test
    fun loginScreen_loginButtonEnabled_whenFieldsFilled() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = null
            )
        }

        // Enter email
        composeTestRule.onNodeWithText("Email").performTextInput("test@example.com")
        // Enter password
        composeTestRule.onNodeWithText("Password").performTextInput("password123")

        // Login button should be enabled
        composeTestRule.onNodeWithText("Login").assertIsEnabled()
    }

    @Test
    fun loginScreen_showsLoadingIndicator_whenLoading() {
        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = true,
                error = null
            )
        }

        // Loading indicator should be visible
        composeTestRule.onNode(hasProgressBarRangeInfo(ProgressBarRangeInfo.Indeterminate)).assertIsDisplayed()
    }

    @Test
    fun loginScreen_showsError_whenErrorExists() {
        val errorMessage = "Invalid credentials"

        composeTestRule.setContent {
            LoginScreen(
                onLoginClick = { _, _ -> },
                onRegisterClick = {},
                onGoogleSignInClick = {},
                isLoading = false,
                error = errorMessage
            )
        }

        composeTestRule.onNodeWithText(errorMessage).assertIsDisplayed()
    }

    @Test
    fun registerScreen_showsAllFields() {
        composeTestRule.setContent {
            RegisterScreen(
                onRegisterClick = { _, _, _, _, _ -> },
                onLoginClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Email").assertIsDisplayed()
        composeTestRule.onNodeWithText("Username").assertIsDisplayed()
        composeTestRule.onNodeWithText("Password").assertIsDisplayed()
        composeTestRule.onNodeWithText("Confirm Password").assertIsDisplayed()
    }

    @Test
    fun registerScreen_showsRegisterButton() {
        composeTestRule.setContent {
            RegisterScreen(
                onRegisterClick = { _, _, _, _, _ -> },
                onLoginClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Register").assertIsDisplayed()
    }

    @Test
    fun registerScreen_showsLoginLink() {
        composeTestRule.setContent {
            RegisterScreen(
                onRegisterClick = { _, _, _, _, _ -> },
                onLoginClick = {},
                isLoading = false,
                error = null
            )
        }

        composeTestRule.onNodeWithText("Login", substring = true).assertIsDisplayed()
    }

    @Test
    fun registerScreen_showsPasswordMismatchError() {
        composeTestRule.setContent {
            RegisterScreen(
                onRegisterClick = { _, _, _, _, _ -> },
                onLoginClick = {},
                isLoading = false,
                error = "Passwords do not match"
            )
        }

        composeTestRule.onNodeWithText("Passwords do not match").assertIsDisplayed()
    }
}
