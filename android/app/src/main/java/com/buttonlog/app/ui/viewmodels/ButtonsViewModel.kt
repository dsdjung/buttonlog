package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ButtonAlertPreference
import com.buttonlog.app.data.api.DiaryData
import com.buttonlog.app.data.api.UpgradeInfo
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonSharingSetting
import com.buttonlog.app.data.repository.ButtonRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class ButtonsViewModel @Inject constructor(
    val buttonRepository: ButtonRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ButtonsUiState())
    val uiState: StateFlow<ButtonsUiState> = _uiState.asStateFlow()
    
    init {
        // Set up search filtering
        combine(
            buttonRepository.buttons,
            _uiState.map { it.searchQuery }
        ) { buttons, query ->
            val filteredButtons = if (query.isEmpty()) {
                buttons
            } else {
                buttons.filter { button ->
                    button.name.contains(query, ignoreCase = true) ||
                    (button.description?.contains(query, ignoreCase = true) ?: false)
                }
            }
            filteredButtons
        }.onEach { filteredButtons ->
            _uiState.update { it.copy(filteredButtons = filteredButtons) }
        }.launchIn(viewModelScope)
        
        // Observe buttons from repository
        buttonRepository.buttons.onEach { buttons ->
            _uiState.update { it.copy(buttons = buttons) }
        }.launchIn(viewModelScope)
        
        // Observe loading state
        buttonRepository.isLoading.onEach { isLoading ->
            _uiState.update { it.copy(isLoading = isLoading) }
        }.launchIn(viewModelScope)
        
        // Observe errors
        buttonRepository.error.onEach { error ->
            _uiState.update { it.copy(error = error) }
        }.launchIn(viewModelScope)

        // Observe upgrade required
        buttonRepository.upgradeRequired.onEach { upgradeInfo ->
            _uiState.update { it.copy(upgradeRequired = upgradeInfo) }
        }.launchIn(viewModelScope)
    }

    fun clearUpgradeRequired() {
        buttonRepository.clearUpgradeRequired()
    }
    
    fun fetchButtons() {
        viewModelScope.launch {
            buttonRepository.fetchButtons()
            fetchStreaks()
        }
    }

    fun refreshButtons() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }
            buttonRepository.fetchButtons()
            fetchStreaks()
            _uiState.update { it.copy(isRefreshing = false) }
        }
    }

    fun fetchStreaks() {
        viewModelScope.launch {
            try {
                val timezoneOffset = java.util.TimeZone.getDefault().rawOffset / 3600000
                val result = buttonRepository.getStreaks(timezoneOffset)
                result.onSuccess { streakData ->
                    _uiState.update { it.copy(streakData = streakData) }
                }
            } catch (e: Exception) {
                // Silently fail - streaks are optional UI enhancement
            }
        }
    }

    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }
    
    fun clickButton(buttonId: String, choice: String? = null) {
        viewModelScope.launch {
            // Mark button as clicking to disable it in UI
            _uiState.update { it.copy(clickingButtonIds = it.clickingButtonIds + buttonId) }

            buttonRepository.clickButton(buttonId, choice)

            // Remove from clicking set after completion
            _uiState.update { it.copy(clickingButtonIds = it.clickingButtonIds - buttonId) }
        }
    }
    
    fun createButton(buttonData: ButtonFormData) {
        viewModelScope.launch {
            buttonRepository.createButton(buttonData)
        }
    }
    
    fun updateButton(button: Button) {
        viewModelScope.launch {
            buttonRepository.updateButton(button)
        }
    }
    
    fun deleteButton(buttonId: String) {
        viewModelScope.launch {
            buttonRepository.deleteButton(buttonId)
        }
    }
    
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun loadButtonSharing(buttonId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingSharing = true) }
            val result = buttonRepository.getButtonSharing(buttonId)
            result.fold(
                onSuccess = { settings ->
                    _uiState.update {
                        it.copy(
                            buttonSharingSettings = settings,
                            isLoadingSharing = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isLoadingSharing = false
                        )
                    }
                }
            )
        }
    }

    fun updateButtonWithSharing(button: Button, sharingSettings: List<ButtonSharingSetting>) {
        viewModelScope.launch {
            // Update button
            buttonRepository.updateButton(button)

            // Update sharing settings
            if (sharingSettings.isNotEmpty()) {
                buttonRepository.updateButtonSharing(button.id, sharingSettings)
            }
        }
    }

    fun clearButtonSharing() {
        _uiState.update { it.copy(buttonSharingSettings = emptyList()) }
    }

    fun createButtonForFriend(friendId: String, buttonData: ButtonFormData, message: String? = null) {
        viewModelScope.launch {
            val result = buttonRepository.createButtonForFriend(friendId, buttonData, message)
            result.fold(
                onSuccess = {
                    // Button created successfully - no need to update local list
                    // since it belongs to the friend, not the current user
                    _uiState.update { it.copy(error = null) }
                },
                onFailure = { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            )
        }
    }

    // MARK: - Button Alert Preferences

    fun loadButtonAlertPreferences(buttonId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingAlertPreferences = true, alertPreferencesError = null) }
            val result = buttonRepository.getButtonAlertPreferences(buttonId)
            result.fold(
                onSuccess = { preferences ->
                    _uiState.update {
                        it.copy(
                            buttonAlertPreferences = preferences,
                            isLoadingAlertPreferences = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            alertPreferencesError = error.message,
                            isLoadingAlertPreferences = false
                        )
                    }
                }
            )
        }
    }

    fun toggleAlertPreference(buttonId: String, friendId: String, enabled: Boolean) {
        viewModelScope.launch {
            // Optimistically update UI
            _uiState.update { state ->
                val updatedPreferences = state.buttonAlertPreferences.map { pref ->
                    if (pref.friendId == friendId) {
                        pref.copy(enabled = enabled)
                    } else {
                        pref
                    }
                }
                state.copy(buttonAlertPreferences = updatedPreferences)
            }

            // Make API call
            val result = buttonRepository.setButtonAlertPreference(buttonId, friendId, enabled)
            result.onFailure { error ->
                // Revert on failure
                _uiState.update { state ->
                    val revertedPreferences = state.buttonAlertPreferences.map { pref ->
                        if (pref.friendId == friendId) {
                            pref.copy(enabled = !enabled)
                        } else {
                            pref
                        }
                    }
                    state.copy(
                        buttonAlertPreferences = revertedPreferences,
                        alertPreferencesError = error.message
                    )
                }
            }
        }
    }

    fun selectAllAlerts(buttonId: String) {
        viewModelScope.launch {
            // Optimistically update UI
            _uiState.update { state ->
                val updatedPreferences = state.buttonAlertPreferences.map { it.copy(enabled = true) }
                state.copy(buttonAlertPreferences = updatedPreferences)
            }

            val result = buttonRepository.selectAllButtonAlerts(buttonId)
            result.onFailure { error ->
                // Reload on failure
                loadButtonAlertPreferences(buttonId)
                _uiState.update { it.copy(alertPreferencesError = error.message) }
            }
        }
    }

    fun deselectAllAlerts(buttonId: String) {
        viewModelScope.launch {
            // Optimistically update UI
            _uiState.update { state ->
                val updatedPreferences = state.buttonAlertPreferences.map { it.copy(enabled = false) }
                state.copy(buttonAlertPreferences = updatedPreferences)
            }

            val result = buttonRepository.deselectAllButtonAlerts(buttonId)
            result.onFailure { error ->
                // Reload on failure
                loadButtonAlertPreferences(buttonId)
                _uiState.update { it.copy(alertPreferencesError = error.message) }
            }
        }
    }

    fun clearAlertPreferences() {
        _uiState.update { it.copy(buttonAlertPreferences = emptyList(), alertPreferencesError = null) }
    }

    // MARK: - Diary

    fun fetchDiary(date: Date? = null) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingDiary = true, diaryError = null) }

            // Format date to ISO format if provided
            val dateString = date?.let {
                SimpleDateFormat("yyyy-MM-dd", Locale.US).format(it)
            }

            val result = buttonRepository.getDiary(dateString)
            result.fold(
                onSuccess = { diaryData ->
                    _uiState.update {
                        it.copy(
                            diaryData = diaryData,
                            isLoadingDiary = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            diaryError = error.message,
                            isLoadingDiary = false
                        )
                    }
                }
            )
        }
    }

    fun clearDiaryError() {
        _uiState.update { it.copy(diaryError = null) }
    }
}

data class ButtonsUiState(
    val buttons: List<Button> = emptyList(),
    val filteredButtons: List<Button> = emptyList(),
    val searchQuery: String = "",
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isLoadingSharing: Boolean = false,
    val buttonSharingSettings: List<ButtonSharingSetting> = emptyList(),
    val error: String? = null,
    // Track buttons currently being clicked (to disable one-time buttons during click)
    val clickingButtonIds: Set<String> = emptySet(),
    // Alert preferences
    val buttonAlertPreferences: List<ButtonAlertPreference> = emptyList(),
    val isLoadingAlertPreferences: Boolean = false,
    val alertPreferencesError: String? = null,
    // Diary
    val diaryData: DiaryData? = null,
    val isLoadingDiary: Boolean = false,
    val diaryError: String? = null,
    // Upgrade prompt
    val upgradeRequired: UpgradeInfo? = null,
    // Streaks
    val streakData: com.buttonlog.app.data.model.StreakData? = null
)

