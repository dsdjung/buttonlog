package com.buttonlog.app.integration

import android.util.Log
import com.buttonlog.app.data.api.CreateButtonRequest
import com.buttonlog.app.data.api.ClickButtonRequest
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonType
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import org.junit.runner.RunWith
import androidx.test.ext.junit.runners.AndroidJUnit4

/**
 * Integration tests for button endpoints.
 *
 * These tests make real API calls to verify:
 * - Button CRUD operations (create, read, update, delete)
 * - Button click (the critical operation we fixed)
 * - Button click with choice
 * - Button history
 *
 * IMPORTANT: These tests specifically verify the button click fix where
 * Retrofit was failing with "Body parameter value must not be null".
 *
 * Run against local dev:
 *   ./gradlew connectedDevelopmentDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.ButtonIntegrationTest
 *
 * Run against staging:
 *   ./gradlew connectedStagingDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.ButtonIntegrationTest
 */
@RunWith(AndroidJUnit4::class)
class ButtonIntegrationTest : BaseIntegrationTest() {

    companion object {
        private const val TAG = "ButtonIntegrationTest"
    }

    @Test
    fun getButtons_authenticated_returnsButtonList() = runIntegrationTest {
        Log.i(TAG, "Testing getButtons with authentication")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        val response = apiService.getButtons()

        Log.i(TAG, "GetButtons response - success: ${response.success}, count: ${response.data?.size}")

        assertThat(response.success).isTrue()
        assertThat(response.data).isNotNull()
        // List could be empty for new users, that's OK
    }

    @Test
    fun getButtons_unauthenticated_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing getButtons without authentication")

        try {
            val response = apiService.getButtons()
            // If we get here, check that it failed
            assertThat(response.success).isFalse()
        } catch (e: retrofit2.HttpException) {
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isEqualTo(401)
        }
    }

    @Test
    fun createButton_withValidData_createsButton() = runIntegrationTest {
        skipIfProduction("Creates test data")

        Log.i(TAG, "Testing createButton")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "Test Button $uniqueId",
            description = "Integration test button",
            type = ButtonType.INSTANT,
            icon = "star",
            color = "#007AFF"
        )
        val request = CreateButtonRequest.from(formData)

        val response = apiService.createButton(request)

        Log.i(TAG, "CreateButton response - success: ${response.success}, id: ${response.data?.id}")

        assertThat(response.success).isTrue()
        assertThat(response.data).isNotNull()
        assertThat(response.data?.name).isEqualTo("Test Button $uniqueId")
        assertThat(response.data?.id).isNotEmpty()

        // Clean up - delete the button
        response.data?.id?.let { buttonId ->
            try {
                apiService.deleteButton(buttonId)
                Log.i(TAG, "Cleaned up test button: $buttonId")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clean up test button: ${e.message}")
            }
        }
    }

    /**
     * CRITICAL TEST: This tests the exact bug we fixed.
     *
     * The bug was: Retrofit throws IllegalArgumentException when calling
     * clickButton with a null body parameter. We fixed this by creating
     * two separate API methods - one without body for simple clicks, and
     * one with body for clicks with a choice.
     */
    @Test
    fun clickButton_withoutChoice_succeeds() = runIntegrationTest {
        skipIfProduction("Creates test data")

        Log.i(TAG, "Testing clickButton WITHOUT choice (the exact bug we fixed)")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // First create a button to click
        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "Click Test Button $uniqueId",
            description = "Button for click integration test",
            type = ButtonType.INSTANT,
            icon = "hand.tap",
            color = "#FF5733"
        )
        val createResponse = apiService.createButton(CreateButtonRequest.from(formData))

        assertThat(createResponse.success).isTrue()
        val buttonId = createResponse.data?.id
        assertThat(buttonId).isNotNull()
        assertThat(buttonId).isNotEmpty()

        Log.i(TAG, "Created test button: $buttonId")

        // NOW THE CRITICAL TEST: Click the button WITHOUT a choice
        // This is what was broken before - Retrofit threw:
        // "Body parameter value must not be null"
        Log.i(TAG, "Clicking button WITHOUT choice...")

        val clickResponse = apiService.clickButton(buttonId!!)

        Log.i(TAG, "ClickButton response - success: ${clickResponse.success}, click id: ${clickResponse.data?.id}")

        assertThat(clickResponse.success).isTrue()
        assertThat(clickResponse.data).isNotNull()
        assertThat(clickResponse.data?.buttonId).isEqualTo(buttonId)

        // Clean up
        try {
            apiService.deleteButton(buttonId)
            Log.i(TAG, "Cleaned up test button: $buttonId")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to clean up test button: ${e.message}")
        }
    }

    @Test
    fun clickButton_withChoice_succeeds() = runIntegrationTest {
        skipIfProduction("Creates test data")

        Log.i(TAG, "Testing clickButton WITH choice")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // Create a button with choices (must be ONE_TIME type for choices)
        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "Choice Button $uniqueId",
            description = "Button with choices for integration test",
            type = ButtonType.ONE_TIME,
            icon = "list.bullet",
            color = "#4CAF50",
            choices = mutableListOf("Option A", "Option B", "Option C")
        )
        val createResponse = apiService.createButton(CreateButtonRequest.from(formData))

        assertThat(createResponse.success).isTrue()
        val buttonId = createResponse.data?.id
        assertThat(buttonId).isNotNull()

        Log.i(TAG, "Created test button with choices: $buttonId")

        // Click with a choice
        val clickResponse = apiService.clickButtonWithChoice(
            buttonId!!,
            ClickButtonRequest(choice = "Option B")
        )

        Log.i(TAG, "ClickButton with choice response - success: ${clickResponse.success}")

        assertThat(clickResponse.success).isTrue()
        assertThat(clickResponse.data).isNotNull()
        assertThat(clickResponse.data?.buttonId).isEqualTo(buttonId)

        // Clean up
        try {
            apiService.deleteButton(buttonId)
            Log.i(TAG, "Cleaned up test button: $buttonId")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to clean up test button: ${e.message}")
        }
    }

    @Test
    fun getButtonHistory_returnsClickHistory() = runIntegrationTest {
        skipIfProduction("Creates test data")

        Log.i(TAG, "Testing getButtonHistory")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // Create a button and click it a few times
        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "History Test Button $uniqueId",
            description = "Button for history test",
            type = ButtonType.INSTANT,
            icon = "clock",
            color = "#9C27B0"
        )
        val createResponse = apiService.createButton(CreateButtonRequest.from(formData))

        assertThat(createResponse.success).isTrue()
        val buttonId = createResponse.data?.id!!

        // Click it 3 times
        repeat(3) { index ->
            Log.i(TAG, "Click ${index + 1}/3...")
            apiService.clickButton(buttonId)
            // Small delay between clicks
            kotlinx.coroutines.delay(100)
        }

        // Get history
        val historyResponse = apiService.getButtonHistory(buttonId, 50)

        Log.i(TAG, "GetButtonHistory response - success: ${historyResponse.success}, count: ${historyResponse.data?.size}")

        assertThat(historyResponse.success).isTrue()
        assertThat(historyResponse.data).isNotNull()
        assertThat(historyResponse.data?.size).isAtLeast(3)

        // Clean up
        try {
            apiService.deleteButton(buttonId)
            Log.i(TAG, "Cleaned up test button: $buttonId")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to clean up test button: ${e.message}")
        }
    }

    @Test
    fun deleteButton_removesButton() = runIntegrationTest {
        skipIfProduction("Creates and deletes test data")

        Log.i(TAG, "Testing deleteButton")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // Create a button
        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "Delete Test Button $uniqueId",
            description = "Button to be deleted",
            type = ButtonType.INSTANT,
            icon = "trash",
            color = "#F44336"
        )
        val createResponse = apiService.createButton(CreateButtonRequest.from(formData))

        assertThat(createResponse.success).isTrue()
        val buttonId = createResponse.data?.id!!

        Log.i(TAG, "Created button to delete: $buttonId")

        // Delete it
        apiService.deleteButton(buttonId)
        Log.i(TAG, "Delete request completed")

        // Verify it's gone - get buttons and check
        val buttonsResponse = apiService.getButtons()
        assertThat(buttonsResponse.success).isTrue()

        val buttonIds = buttonsResponse.data?.map { it.id } ?: emptyList()
        assertThat(buttonIds).doesNotContain(buttonId)

        Log.i(TAG, "Verified button was deleted")
    }

    @Test
    fun multipleQuickClicks_allSucceed() = runIntegrationTest {
        skipIfProduction("Creates test data")

        Log.i(TAG, "Testing multiple quick button clicks (stress test)")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        // Create a button
        val uniqueId = uniqueTestId()
        val formData = ButtonFormData(
            name = "Rapid Click Test $uniqueId",
            description = "Button for rapid click test",
            type = ButtonType.INSTANT,
            icon = "bolt",
            color = "#FF9800"
        )
        val createResponse = apiService.createButton(CreateButtonRequest.from(formData))

        assertThat(createResponse.success).isTrue()
        val buttonId = createResponse.data?.id!!

        // Click it rapidly 5 times
        val clickResults = mutableListOf<Boolean>()
        repeat(5) { index ->
            try {
                val response = apiService.clickButton(buttonId)
                clickResults.add(response.success)
                Log.i(TAG, "Rapid click ${index + 1}/5 - success: ${response.success}")
            } catch (e: Exception) {
                clickResults.add(false)
                Log.e(TAG, "Rapid click ${index + 1}/5 - failed: ${e.message}")
            }
        }

        // All clicks should succeed
        assertThat(clickResults).containsExactly(true, true, true, true, true)

        // Clean up
        try {
            apiService.deleteButton(buttonId)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to clean up: ${e.message}")
        }
    }
}
