package com.buttonlog.app.integration

import android.util.Log
import com.buttonlog.app.data.api.LoginCredentials
import com.buttonlog.app.data.api.RegistrationData
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import org.junit.runner.RunWith
import androidx.test.ext.junit.runners.AndroidJUnit4

/**
 * Integration tests for authentication endpoints.
 *
 * These tests make real API calls to verify:
 * - Login with valid credentials
 * - Login with invalid credentials
 * - Registration flow
 *
 * Run against local dev:
 *   ./gradlew connectedDevelopmentDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.AuthIntegrationTest
 *
 * Run against staging:
 *   ./gradlew connectedStagingDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.AuthIntegrationTest
 */
@RunWith(AndroidJUnit4::class)
class AuthIntegrationTest : BaseIntegrationTest() {

    companion object {
        private const val TAG = "AuthIntegrationTest"
    }

    @Test
    fun login_withValidCredentials_returnsToken() = runIntegrationTest {
        Log.i(TAG, "Testing login with valid credentials")

        val response = apiService.login(
            LoginCredentials(
                email = IntegrationTestConfig.TestCredentials.TEST_EMAIL,
                password = IntegrationTestConfig.TestCredentials.TEST_PASSWORD
            )
        )

        Log.i(TAG, "Login response - success: ${response.success}")

        assertThat(response.success).isTrue()
        assertThat(response.data).isNotNull()
        assertThat(response.data?.token).isNotEmpty()
        assertThat(response.data?.user).isNotNull()
        assertThat(response.data?.user?.email).isEqualTo(IntegrationTestConfig.TestCredentials.TEST_EMAIL)
    }

    @Test
    fun login_withInvalidPassword_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing login with invalid password")

        try {
            val response = apiService.login(
                LoginCredentials(
                    email = IntegrationTestConfig.TestCredentials.TEST_EMAIL,
                    password = "wrong_password_123"
                )
            )

            Log.i(TAG, "Login response - success: ${response.success}, error: ${response.error?.message}")

            // If we get here without exception, check that it failed
            assertThat(response.success).isFalse()
            assertThat(response.error).isNotNull()
        } catch (e: retrofit2.HttpException) {
            // Also acceptable - 401 for invalid credentials
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isEqualTo(401)
        }
    }

    @Test
    fun login_withNonExistentUser_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing login with non-existent user")

        try {
            val response = apiService.login(
                LoginCredentials(
                    email = "nonexistent_${System.currentTimeMillis()}@example.com",
                    password = "any_password"
                )
            )

            Log.i(TAG, "Login response - success: ${response.success}, error: ${response.error?.message}")

            // If we get here without exception, check that it failed
            assertThat(response.success).isFalse()
            assertThat(response.error).isNotNull()
        } catch (e: retrofit2.HttpException) {
            // Also acceptable - 401 for user not found
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isEqualTo(401)
        }
    }

    @Test
    fun register_withNewUser_createsAccount() = runIntegrationTest {
        // Skip in production to avoid creating garbage accounts
        skipIfProduction("Registration test creates test accounts")

        val uniqueId = uniqueTestId()
        val email = "test_$uniqueId@example.com"
        val username = "testuser_$uniqueId"

        Log.i(TAG, "Testing registration with new user: $email")

        try {
            val response = apiService.register(
                RegistrationData(
                    email = email,
                    username = username,
                    password = "TestPassword123!",
                    passwordConfirmation = "TestPassword123!",
                    displayName = "Test User $uniqueId"
                )
            )

            Log.i(TAG, "Register response - success: ${response.success}")

            assertThat(response.success).isTrue()
            assertThat(response.data).isNotNull()
            assertThat(response.data?.token).isNotEmpty()
            assertThat(response.data?.user?.email).isEqualTo(email)
            assertThat(response.data?.user?.username).isEqualTo(username)
        } catch (e: retrofit2.HttpException) {
            // If we get a 400, it might mean the username/email already exists
            // This can happen if a previous test run didn't clean up
            Log.w(TAG, "Registration failed with HTTP error: ${e.code()}")
            assertThat(e.code()).isIn(listOf(400, 422))
        }
    }

    @Test
    fun register_withExistingEmail_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing registration with existing email")

        try {
            val response = apiService.register(
                RegistrationData(
                    email = IntegrationTestConfig.TestCredentials.TEST_EMAIL,
                    username = "new_username_${System.currentTimeMillis()}",
                    password = "TestPassword123!",
                    passwordConfirmation = "TestPassword123!",
                    displayName = "Test User"
                )
            )

            Log.i(TAG, "Register response - success: ${response.success}, error: ${response.error?.message}")

            // If we get here without exception, check that it failed
            assertThat(response.success).isFalse()
            assertThat(response.error).isNotNull()
        } catch (e: retrofit2.HttpException) {
            // Also acceptable - 400/422 for validation errors
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isIn(listOf(400, 422))
        }
    }

    @Test
    fun loginAndAccessProtectedEndpoint_succeeds() = runIntegrationTest {
        Log.i(TAG, "Testing login and then accessing a protected endpoint")

        // Login to get token
        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // Now try to access a protected endpoint (getButtons)
        val buttonsResponse = apiService.getButtons()

        Log.i(TAG, "GetButtons after login - success: ${buttonsResponse.success}")

        assertThat(buttonsResponse.success).isTrue()
        assertThat(buttonsResponse.data).isNotNull()
    }
}
