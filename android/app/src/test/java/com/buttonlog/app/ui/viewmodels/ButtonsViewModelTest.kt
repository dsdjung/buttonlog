package com.buttonlog.app.ui.viewmodels

import app.cash.turbine.test
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonSharingSetting
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.repository.ButtonRepository
import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ButtonsViewModelTest {

    private lateinit var buttonRepository: ButtonRepository
    private lateinit var viewModel: ButtonsViewModel

    private val testDispatcher = StandardTestDispatcher()

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

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        buttonRepository = mockk(relaxed = true)

        // Setup default flows
        every { buttonRepository.buttons } returns MutableStateFlow(emptyList())
        every { buttonRepository.isLoading } returns MutableStateFlow(false)
        every { buttonRepository.error } returns MutableStateFlow(null)

        viewModel = ButtonsViewModel(buttonRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state has empty buttons and no error`() = runTest {
        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.buttons).isEmpty()
            assertThat(state.filteredButtons).isEmpty()
            assertThat(state.error).isNull()
            assertThat(state.isLoading).isFalse()
        }
    }

    @Test
    fun `fetchButtons calls repository`() = runTest {
        // When
        viewModel.fetchButtons()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.fetchButtons() }
    }

    @Test
    fun `updateSearchQuery filters buttons`() = runTest {
        // Given
        val button1 = testButton.copy(id = "1", name = "Exercise Button")
        val button2 = testButton.copy(id = "2", name = "Water Tracker")

        every { buttonRepository.buttons } returns MutableStateFlow(listOf(button1, button2))

        // Recreate viewModel with new mock
        viewModel = ButtonsViewModel(buttonRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.updateSearchQuery("exercise")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.searchQuery).isEqualTo("exercise")
            assertThat(state.filteredButtons).hasSize(1)
            assertThat(state.filteredButtons.first().name).isEqualTo("Exercise Button")
        }
    }

    @Test
    fun `updateSearchQuery with empty string returns all buttons`() = runTest {
        // Given
        val buttons = listOf(
            testButton.copy(id = "1", name = "Button 1"),
            testButton.copy(id = "2", name = "Button 2")
        )
        every { buttonRepository.buttons } returns MutableStateFlow(buttons)

        viewModel = ButtonsViewModel(buttonRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.updateSearchQuery("")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.filteredButtons).hasSize(2)
        }
    }

    @Test
    fun `clickButton calls repository`() = runTest {
        // Given
        coEvery { buttonRepository.clickButton(any()) } returns Result.success(mockk())

        // When
        viewModel.clickButton("button-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.clickButton("button-id") }
    }

    @Test
    fun `createButton calls repository`() = runTest {
        // Given
        val formData = ButtonFormData(
            name = "New Button",
            description = "Description",
            type = ButtonType.INSTANT,
            icon = "star",
            color = "#FF0000"
        )
        coEvery { buttonRepository.createButton(formData) } returns Result.success(testButton)

        // When
        viewModel.createButton(formData)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.createButton(formData) }
    }

    @Test
    fun `updateButton calls repository`() = runTest {
        // Given
        coEvery { buttonRepository.updateButton(testButton) } returns Result.success(testButton)

        // When
        viewModel.updateButton(testButton)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.updateButton(testButton) }
    }

    @Test
    fun `deleteButton calls repository`() = runTest {
        // Given
        coEvery { buttonRepository.deleteButton("button-id") } returns Result.success(Unit)

        // When
        viewModel.deleteButton("button-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.deleteButton("button-id") }
    }

    @Test
    fun `clearError updates state`() = runTest {
        // Given - set up with an error
        every { buttonRepository.error } returns MutableStateFlow("Some error")
        viewModel = ButtonsViewModel(buttonRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.clearError()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.error).isNull()
        }
    }

    @Test
    fun `loadButtonSharing updates state with sharing settings`() = runTest {
        // Given
        val sharingSettings = listOf(
            ButtonSharingSetting(
                friendId = "friend-1",
                friendUsername = "friend1",
                friendDisplayName = "Friend One",
                isShared = true
            )
        )
        coEvery { buttonRepository.getButtonSharing("button-id") } returns Result.success(sharingSettings)

        // When
        viewModel.loadButtonSharing("button-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.buttonSharingSettings).isEqualTo(sharingSettings)
            assertThat(state.isLoadingSharing).isFalse()
        }
    }

    @Test
    fun `loadButtonSharing failure updates error state`() = runTest {
        // Given
        coEvery { buttonRepository.getButtonSharing("button-id") } returns Result.failure(
            Exception("Failed to load")
        )

        // When
        viewModel.loadButtonSharing("button-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.error).isEqualTo("Failed to load")
            assertThat(state.isLoadingSharing).isFalse()
        }
    }

    @Test
    fun `updateButtonWithSharing calls repository methods`() = runTest {
        // Given
        val sharingSettings = listOf(
            ButtonSharingSetting(
                friendId = "friend-1",
                friendUsername = "friend1",
                friendDisplayName = null,
                isShared = true
            )
        )
        coEvery { buttonRepository.updateButton(testButton) } returns Result.success(testButton)
        coEvery { buttonRepository.updateButtonSharing(testButton.id, sharingSettings) } returns Result.success(sharingSettings)

        // When
        viewModel.updateButtonWithSharing(testButton, sharingSettings)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { buttonRepository.updateButton(testButton) }
        coVerify { buttonRepository.updateButtonSharing(testButton.id, sharingSettings) }
    }

    @Test
    fun `clearButtonSharing resets sharing settings`() = runTest {
        // Given - first load some settings
        val sharingSettings = listOf(
            ButtonSharingSetting(
                friendId = "friend-1",
                friendUsername = "friend1",
                friendDisplayName = null,
                isShared = true
            )
        )
        coEvery { buttonRepository.getButtonSharing("button-id") } returns Result.success(sharingSettings)
        viewModel.loadButtonSharing("button-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.clearButtonSharing()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.buttonSharingSettings).isEmpty()
        }
    }

    @Test
    fun `search filters by description as well`() = runTest {
        // Given
        val button1 = testButton.copy(id = "1", name = "Button A", description = "Track water intake")
        val button2 = testButton.copy(id = "2", name = "Button B", description = "Track sleep")

        every { buttonRepository.buttons } returns MutableStateFlow(listOf(button1, button2))
        viewModel = ButtonsViewModel(buttonRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.updateSearchQuery("water")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.filteredButtons).hasSize(1)
            assertThat(state.filteredButtons.first().id).isEqualTo("1")
        }
    }

    @Test
    fun `search is case insensitive`() = runTest {
        // Given
        val button = testButton.copy(name = "Exercise Button")
        every { buttonRepository.buttons } returns MutableStateFlow(listOf(button))
        viewModel = ButtonsViewModel(buttonRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.updateSearchQuery("EXERCISE")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.filteredButtons).hasSize(1)
        }
    }
}
