package com.buttonlog.app.data.repository

import app.cash.turbine.test
import com.buttonlog.app.data.api.APIResponse
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.CreateButtonRequest
import com.buttonlog.app.data.api.UpdateButtonRequest
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonClick
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.ButtonType
import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ButtonRepositoryTest {

    private lateinit var apiService: APIService
    private lateinit var repository: ButtonRepository

    private val testButton = Button(
        id = "test-id-1",
        name = "Test Button",
        description = "A test button",
        type = ButtonType.INSTANT,
        icon = "star",
        color = "#007AFF",
        clickCount = 5,
        currentState = ButtonState.IDLE,
        isActive = false,
        notificationsEnabled = true,
        autoStopEnabled = false,
        calendarSyncEnabled = false,
        createdAt = "2024-01-01T00:00:00Z",
        updatedAt = "2024-01-01T00:00:00Z",
        latestClick = null
    )

    private val testButtonClick = ButtonClick(
        id = "click-1",
        buttonId = "test-id-1",
        action = "click",
        clickedAt = "2024-01-01T12:00:00Z",
        duration = null,
        location = null,
        device = "Test Device",
        platform = "android"
    )

    @Before
    fun setup() {
        apiService = mockk()
        repository = ButtonRepository(apiService)
    }

    @Test
    fun `fetchButtons success updates buttons flow`() = runTest {
        // Given
        val buttons = listOf(testButton)
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = buttons,
            error = null
        )

        // When
        repository.fetchButtons()

        // Then
        repository.buttons.test {
            assertThat(awaitItem()).isEqualTo(buttons)
        }
        coVerify { apiService.getButtons() }
    }

    @Test
    fun `fetchButtons failure updates error flow`() = runTest {
        // Given
        coEvery { apiService.getButtons() } returns APIResponse(
            success = false,
            data = null,
            error = com.buttonlog.app.data.api.APIError(
                code = "ERROR",
                message = "Network error"
            )
        )

        // When
        repository.fetchButtons()

        // Then
        repository.error.test {
            assertThat(awaitItem()).isEqualTo("Network error")
        }
    }

    @Test
    fun `fetchButtons exception updates error flow`() = runTest {
        // Given
        coEvery { apiService.getButtons() } throws RuntimeException("Connection failed")

        // When
        repository.fetchButtons()

        // Then
        repository.error.test {
            assertThat(awaitItem()).isEqualTo("Connection failed")
        }
    }

    @Test
    fun `fetchButtons updates loading state correctly`() = runTest {
        // Given
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = emptyList(),
            error = null
        )

        // Then - verify loading is false after completion
        repository.fetchButtons()
        repository.isLoading.test {
            assertThat(awaitItem()).isFalse()
        }
    }

    @Test
    fun `createButton success adds button to list`() = runTest {
        // Given
        val formData = ButtonFormData(
            name = "New Button",
            description = "Description",
            type = ButtonType.INSTANT,
            icon = "star",
            color = "#FF0000"
        )
        coEvery { apiService.createButton(any()) } returns APIResponse(
            success = true,
            data = testButton,
            error = null
        )

        // When
        val result = repository.createButton(formData)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(testButton)
        repository.buttons.test {
            assertThat(awaitItem()).contains(testButton)
        }
    }

    @Test
    fun `createButton failure returns error result`() = runTest {
        // Given
        val formData = ButtonFormData(
            name = "New Button",
            description = null,
            type = ButtonType.INSTANT,
            icon = "star",
            color = "#FF0000"
        )
        coEvery { apiService.createButton(any()) } returns APIResponse(
            success = false,
            data = null,
            error = com.buttonlog.app.data.api.APIError(
                code = "ERROR",
                message = "Validation failed"
            )
        )

        // When
        val result = repository.createButton(formData)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).isEqualTo("Validation failed")
    }

    @Test
    fun `updateButton success updates button in list`() = runTest {
        // Given - First add a button to the list
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton),
            error = null
        )
        repository.fetchButtons()

        val updatedButton = testButton.copy(name = "Updated Name")
        coEvery { apiService.updateButton(testButton.id, any()) } returns APIResponse(
            success = true,
            data = updatedButton,
            error = null
        )

        // When
        val result = repository.updateButton(updatedButton)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.name).isEqualTo("Updated Name")
    }

    @Test
    fun `deleteButton success removes button from list`() = runTest {
        // Given - First add a button to the list
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton),
            error = null
        )
        repository.fetchButtons()

        coEvery { apiService.deleteButton(testButton.id) } returns Unit

        // When
        val result = repository.deleteButton(testButton.id)

        // Then
        assertThat(result.isSuccess).isTrue()
        repository.buttons.test {
            assertThat(awaitItem()).doesNotContain(testButton)
        }
    }

    @Test
    fun `clickButton success returns click and refreshes buttons`() = runTest {
        // Given
        coEvery { apiService.clickButton(testButton.id) } returns APIResponse(
            success = true,
            data = testButtonClick,
            error = null
        )
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton.copy(clickCount = 6)),
            error = null
        )

        // When
        val result = repository.clickButton(testButton.id)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(testButtonClick)
        coVerify { apiService.getButtons() }
    }

    @Test
    fun `getButton returns button from list`() = runTest {
        // Given
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton),
            error = null
        )
        repository.fetchButtons()

        // When
        val result = repository.getButton(testButton.id)

        // Then
        assertThat(result).isEqualTo(testButton)
    }

    @Test
    fun `getButton returns null for non-existent id`() = runTest {
        // Given
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton),
            error = null
        )
        repository.fetchButtons()

        // When
        val result = repository.getButton("non-existent-id")

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `searchButtons filters by name`() = runTest {
        // Given
        val button1 = testButton.copy(id = "1", name = "Exercise Button")
        val button2 = testButton.copy(id = "2", name = "Water Tracker")
        val button3 = testButton.copy(id = "3", name = "Daily Exercise Log")

        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(button1, button2, button3),
            error = null
        )
        repository.fetchButtons()

        // When
        val results = repository.searchButtons("exercise")

        // Then
        assertThat(results).hasSize(2)
        assertThat(results.map { it.id }).containsExactly("1", "3")
    }

    @Test
    fun `searchButtons with empty query returns all buttons`() = runTest {
        // Given
        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(testButton),
            error = null
        )
        repository.fetchButtons()

        // When
        val results = repository.searchButtons("")

        // Then
        assertThat(results).hasSize(1)
    }

    @Test
    fun `getButtonsByType filters correctly`() = runTest {
        // Given
        val instantButton = testButton.copy(id = "1", type = ButtonType.INSTANT)
        val timedButton = testButton.copy(id = "2", type = ButtonType.TIMED)
        val stateButton = testButton.copy(id = "3", type = ButtonType.STATE)

        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(instantButton, timedButton, stateButton),
            error = null
        )
        repository.fetchButtons()

        // When
        val timedButtons = repository.getButtonsByType(ButtonType.TIMED)

        // Then
        assertThat(timedButtons).hasSize(1)
        assertThat(timedButtons.first().id).isEqualTo("2")
    }

    @Test
    fun `getActiveButtons returns only active buttons`() = runTest {
        // Given
        val activeButton = testButton.copy(id = "1", isActive = true)
        val inactiveButton = testButton.copy(id = "2", isActive = false)

        coEvery { apiService.getButtons() } returns APIResponse(
            success = true,
            data = listOf(activeButton, inactiveButton),
            error = null
        )
        repository.fetchButtons()

        // When
        val activeButtons = repository.getActiveButtons()

        // Then
        assertThat(activeButtons).hasSize(1)
        assertThat(activeButtons.first().id).isEqualTo("1")
    }

    @Test
    fun `clearError resets error state`() = runTest {
        // Given - First cause an error
        coEvery { apiService.getButtons() } returns APIResponse(
            success = false,
            data = null,
            error = com.buttonlog.app.data.api.APIError(code = "ERROR", message = "Some error")
        )
        repository.fetchButtons()

        // Verify error is set
        repository.error.test {
            assertThat(awaitItem()).isNotNull()
        }

        // When
        repository.clearError()

        // Then
        repository.error.test {
            assertThat(awaitItem()).isNull()
        }
    }

    @Test
    fun `getButtonHistory success returns click history`() = runTest {
        // Given
        val clicks = listOf(testButtonClick)
        coEvery { apiService.getButtonHistory(testButton.id, 50) } returns APIResponse(
            success = true,
            data = clicks,
            error = null
        )

        // When
        val result = repository.getButtonHistory(testButton.id)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(clicks)
    }

    @Test
    fun `getButtonHistory failure returns error`() = runTest {
        // Given
        coEvery { apiService.getButtonHistory(testButton.id, 50) } returns APIResponse(
            success = false,
            data = null,
            error = com.buttonlog.app.data.api.APIError(code = "ERROR", message = "Not found")
        )

        // When
        val result = repository.getButtonHistory(testButton.id)

        // Then
        assertThat(result.isFailure).isTrue()
    }
}
