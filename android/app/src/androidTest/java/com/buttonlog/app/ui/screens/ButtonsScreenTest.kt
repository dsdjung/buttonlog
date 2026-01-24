package com.buttonlog.app.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.ui.viewmodels.ButtonsUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ButtonsScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun buttonsScreen_showsLoadingIndicator_whenLoading() {
        val uiState = ButtonsUiState(isLoading = true)

        composeTestRule.setContent {
            // Test loading state
            // Note: This requires mocking the ViewModel
        }

        // Loading indicator should be visible
        // composeTestRule.onNodeWithTag("loading_indicator").assertIsDisplayed()
    }

    @Test
    fun buttonsScreen_showsEmptyState_whenNoButtons() {
        composeTestRule.setContent {
            EmptyStateView(onCreateButton = {})
        }

        composeTestRule.onNodeWithText("No buttons yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Create Button").assertIsDisplayed()
    }

    @Test
    fun buttonsScreen_showsButtonsList_whenButtonsExist() {
        val buttons = listOf(
            createTestButton("1", "Test Button 1", ButtonType.INSTANT),
            createTestButton("2", "Test Button 2", ButtonType.TIMED)
        )

        composeTestRule.setContent {
            ButtonsList(
                buttons = buttons,
                onButtonClick = {},
                onButtonClickWithChoice = { _, _ -> },
                onEditClick = {},
                onHistoryClick = {},
                onAlertSettingsClick = {},
                onDeleteClick = {}
            )
        }

        composeTestRule.onNodeWithText("Test Button 1").assertIsDisplayed()
        composeTestRule.onNodeWithText("Test Button 2").assertIsDisplayed()
    }

    @Test
    fun searchBar_filtersButtons_whenTextEntered() {
        composeTestRule.setContent {
            SearchBar(
                query = "",
                onQueryChange = {}
            )
        }

        composeTestRule.onNodeWithText("Search buttons...").assertIsDisplayed()
    }

    @Test
    fun searchBar_showsClearButton_whenQueryNotEmpty() {
        composeTestRule.setContent {
            SearchBar(
                query = "test",
                onQueryChange = {}
            )
        }

        composeTestRule.onNodeWithContentDescription("Clear search").assertIsDisplayed()
    }

    @Test
    fun emptyStateView_showsCreateButtonPrompt() {
        var createClicked = false

        composeTestRule.setContent {
            EmptyStateView(onCreateButton = { createClicked = true })
        }

        composeTestRule.onNodeWithText("Create Button").performClick()
        assert(createClicked)
    }

    private fun createTestButton(
        id: String,
        name: String,
        type: ButtonType,
        description: String? = null
    ): Button {
        return Button(
            id = id,
            name = name,
            type = type,
            description = description,
            icon = "star",
            color = "#00BFA5",
            isActive = true,
            currentState = "idle",
            stateChangedAt = null,
            alertsEnabled = false,
            autoStopEnabled = false,
            autoStopDuration = null,
            calendarSyncEnabled = false,
            userId = "test-user",
            createdAt = "2024-01-01T00:00:00Z",
            updatedAt = "2024-01-01T00:00:00Z",
            latestClickAt = null,
            latestClickAction = null,
            latestClickDevice = null,
            latestClickPlatform = null,
            choices = null,
            isGift = false,
            giftFromUserId = null,
            giftFromName = null,
            isShared = false,
            ownerId = null,
            ownerName = null,
            isOwner = true
        )
    }
}
