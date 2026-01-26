package com.buttonlog.app.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.buttonlog.app.ui.viewmodels.ButtonsUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI component tests for ButtonsScreen.
 *
 * Note: These tests verify basic UI state behavior. For end-to-end API tests,
 * see the integration tests in com.buttonlog.app.integration package.
 */
@RunWith(AndroidJUnit4::class)
class ButtonsScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun buttonsUiState_initializes_withDefaults() {
        // Verify the default UI state initializes properly
        val uiState = ButtonsUiState()

        assert(!uiState.isLoading)
        assert(!uiState.isRefreshing)
        assert(uiState.buttons.isEmpty())
        assert(uiState.error == null)
    }

    @Test
    fun buttonsUiState_tracks_loadingState() {
        val uiState = ButtonsUiState(isLoading = true)

        assert(uiState.isLoading)
        assert(!uiState.isRefreshing)
    }

    @Test
    fun buttonsUiState_tracks_refreshingState() {
        val uiState = ButtonsUiState(isRefreshing = true)

        assert(uiState.isRefreshing)
        assert(!uiState.isLoading)
    }

    @Test
    fun buttonsUiState_tracks_errorState() {
        val errorMessage = "Network error"
        val uiState = ButtonsUiState(error = errorMessage)

        assert(uiState.error == errorMessage)
    }

    @Test
    fun buttonsUiState_tracks_clickingButtons() {
        val uiState = ButtonsUiState(clickingButtonIds = setOf("button-1", "button-2"))

        assert(uiState.clickingButtonIds.contains("button-1"))
        assert(uiState.clickingButtonIds.contains("button-2"))
        assert(!uiState.clickingButtonIds.contains("button-3"))
    }

    @Test
    fun buttonsUiState_tracks_searchQuery() {
        val uiState = ButtonsUiState(searchQuery = "exercise")

        assert(uiState.searchQuery == "exercise")
    }

    @Test
    fun buttonsUiState_tracks_sharingState() {
        val uiState = ButtonsUiState(isLoadingSharing = true)

        assert(uiState.isLoadingSharing)
    }

    @Test
    fun buttonsUiState_tracks_alertPreferencesState() {
        val uiState = ButtonsUiState(
            isLoadingAlertPreferences = true,
            alertPreferencesError = "Failed to load"
        )

        assert(uiState.isLoadingAlertPreferences)
        assert(uiState.alertPreferencesError == "Failed to load")
    }

    @Test
    fun buttonsUiState_tracks_diaryState() {
        val uiState = ButtonsUiState(
            isLoadingDiary = true,
            diaryError = "No data"
        )

        assert(uiState.isLoadingDiary)
        assert(uiState.diaryError == "No data")
    }
}
