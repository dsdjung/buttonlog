package com.buttonlog.app.ui.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.NotificationPreferencesUpdate
import com.buttonlog.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NotificationSettingsViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    var pushNotificationsEnabled by mutableStateOf(true)
        private set

    var emailNotificationsEnabled by mutableStateOf(true)
        private set

    var buttonNotifications by mutableStateOf(true)
        private set

    var friendNotifications by mutableStateOf(true)
        private set

    var systemNotifications by mutableStateOf(true)
        private set

    var quietHoursEnabled by mutableStateOf(false)
        private set

    var quietHoursStart by mutableStateOf<String?>(null)
        private set

    var quietHoursEnd by mutableStateOf<String?>(null)
        private set

    var isLoading by mutableStateOf(false)
        private set

    var isSaving by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    fun loadSettings() {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null

            when (val result = userRepository.getNotificationPreferences()) {
                is ApiResult.Success -> {
                    val prefs = result.data
                    pushNotificationsEnabled = prefs.pushNotificationsEnabled
                    emailNotificationsEnabled = prefs.emailNotificationsEnabled
                    buttonNotifications = prefs.buttonNotifications
                    friendNotifications = prefs.friendNotifications
                    systemNotifications = prefs.systemNotifications
                    quietHoursEnabled = prefs.quietHoursEnabled
                    quietHoursStart = prefs.quietHoursStart
                    quietHoursEnd = prefs.quietHoursEnd
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoading = false
        }
    }

    fun setPushNotificationsEnabled(enabled: Boolean) {
        pushNotificationsEnabled = enabled
        saveSettings()
    }

    fun setEmailNotificationsEnabled(enabled: Boolean) {
        emailNotificationsEnabled = enabled
        saveSettings()
    }

    fun setButtonNotifications(enabled: Boolean) {
        buttonNotifications = enabled
        saveSettings()
    }

    fun setFriendNotifications(enabled: Boolean) {
        friendNotifications = enabled
        saveSettings()
    }

    fun setSystemNotifications(enabled: Boolean) {
        systemNotifications = enabled
        saveSettings()
    }

    fun setQuietHoursEnabled(enabled: Boolean) {
        quietHoursEnabled = enabled
        saveSettings()
    }

    private fun saveSettings() {
        viewModelScope.launch {
            isSaving = true
            errorMessage = null

            val prefs = NotificationPreferencesUpdate(
                pushNotificationsEnabled = pushNotificationsEnabled,
                emailNotificationsEnabled = emailNotificationsEnabled,
                buttonNotifications = buttonNotifications,
                friendNotifications = friendNotifications,
                systemNotifications = systemNotifications,
                quietHoursEnabled = quietHoursEnabled,
                quietHoursStart = quietHoursStart,
                quietHoursEnd = quietHoursEnd
            )

            when (val result = userRepository.updateNotificationPreferences(prefs)) {
                is ApiResult.Success -> {
                    // Settings saved successfully
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                    // Reload settings on error to ensure consistency
                    loadSettings()
                }
                is ApiResult.Loading -> {}
            }

            isSaving = false
        }
    }

    fun clearError() {
        errorMessage = null
    }
}
