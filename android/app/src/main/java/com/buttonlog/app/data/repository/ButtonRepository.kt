package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ButtonAlertPreference
import com.buttonlog.app.data.api.ButtonUpdateData
import com.buttonlog.app.data.api.ClickButtonRequest
import com.buttonlog.app.data.api.CreateButtonRequest
import com.buttonlog.app.data.api.CreateGiftButtonRequest
import com.buttonlog.app.data.api.SetAlertPreferenceRequest
import com.buttonlog.app.data.api.UpdateButtonRequest
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonClick
import com.buttonlog.app.data.model.ButtonSharingSetting
import com.buttonlog.app.data.model.ButtonSharingUpdateRequest
import com.buttonlog.app.data.model.ButtonSharingUpdate
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ButtonRepository @Inject constructor(
    private val apiService: APIService
) {
    
    private val _buttons = MutableStateFlow<List<Button>>(emptyList())
    val buttons: StateFlow<List<Button>> = _buttons.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    suspend fun fetchButtons() {
        try {
            _isLoading.value = true
            _error.value = null

            val response = apiService.getButtons()
            if (response.success && response.data != null) {
                _buttons.value = response.data
            } else {
                _error.value = response.error?.message ?: "Failed to fetch buttons"
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch buttons"
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun createButton(buttonData: ButtonFormData): Result<Button> {
        return try {
            _isLoading.value = true
            _error.value = null

            val response = apiService.createButton(CreateButtonRequest(buttonData))
            if (response.success && response.data != null) {
                _buttons.value = _buttons.value + response.data
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to create button"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to create button"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun updateButton(button: Button): Result<Button> {
        return try {
            _isLoading.value = true
            _error.value = null

            val updateData = ButtonUpdateData(
                name = button.name,
                description = button.description,
                icon = button.icon,
                color = button.color,
                alertsEnabled = button.alertsEnabled,
                autoStopEnabled = button.autoStopEnabled,
                calendarSyncEnabled = button.calendarSyncEnabled
            )
            val response = apiService.updateButton(button.id, UpdateButtonRequest(updateData))
            if (response.success && response.data != null) {
                val currentButtons = _buttons.value.toMutableList()
                val index = currentButtons.indexOfFirst { it.id == button.id }

                if (index != -1) {
                    currentButtons[index] = response.data
                    _buttons.value = currentButtons
                }

                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to update button"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to update button"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun deleteButton(buttonId: String): Result<Unit> {
        return try {
            _isLoading.value = true
            _error.value = null
            
            apiService.deleteButton(buttonId)
            _buttons.value = _buttons.value.filter { it.id != buttonId }
            
            Result.success(Unit)
            
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to delete button"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun clickButton(buttonId: String, choice: String? = null): Result<ButtonClick> {
        return try {
            _error.value = null

            val request = if (choice != null) ClickButtonRequest(choice = choice) else null
            val response = apiService.clickButton(buttonId, request)
            if (response.success && response.data != null) {
                // Refetch buttons to get updated state from server
                // This ensures we have the latest button state after clicking
                fetchButtons()

                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to click button"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to click button"
            Result.failure(e)
        }
    }
    
    fun getButton(id: String): Button? {
        return _buttons.value.find { it.id == id }
    }

    suspend fun getButtonHistory(buttonId: String, limit: Int = 50): Result<List<ButtonClick>> {
        return try {
            val response = apiService.getButtonHistory(buttonId, limit)
            if (response.success && response.data != null) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to fetch history"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun getButtonsByType(type: com.buttonlog.app.data.model.ButtonType): List<Button> {
        return _buttons.value.filter { it.type == type }
    }
    
    fun getActiveButtons(): List<Button> {
        return _buttons.value.filter { it.isActive }
    }
    
    fun searchButtons(query: String): List<Button> {
        if (query.isEmpty()) {
            return _buttons.value
        }
        
        return _buttons.value.filter { button ->
            button.name.contains(query, ignoreCase = true) ||
            (button.description?.contains(query, ignoreCase = true) ?: false)
        }
    }
    
    fun clearError() {
        _error.value = null
    }

    suspend fun getButtonSharing(buttonId: String): Result<List<ButtonSharingSetting>> {
        return try {
            val response = apiService.getButtonSharing(buttonId)
            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to fetch sharing settings"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateButtonSharing(buttonId: String, settings: List<ButtonSharingSetting>): Result<List<ButtonSharingSetting>> {
        return try {
            val request = ButtonSharingUpdateRequest(
                sharing = settings.map { ButtonSharingUpdate(it.friendId, it.isShared) }
            )
            val response = apiService.updateButtonSharing(buttonId, request)
            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to update sharing settings"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Create a button for a friend (gift button).
     * The button will appear in the friend's button list and
     * the creator will be notified when the friend uses it.
     */
    suspend fun createButtonForFriend(
        friendId: String,
        buttonData: ButtonFormData,
        message: String? = null
    ): Result<Button> {
        return try {
            _isLoading.value = true
            _error.value = null

            val request = CreateGiftButtonRequest(
                friendId = friendId,
                button = buttonData,
                message = message
            )
            val response = apiService.createButtonForFriend(request)
            if (response.success && response.data != null) {
                // Note: The created button belongs to the friend, not the creator,
                // so we don't add it to our local buttons list
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to create gift button"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to create gift button"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }

    // MARK: - Button Alert Preferences

    suspend fun getButtonAlertPreferences(buttonId: String): Result<List<ButtonAlertPreference>> {
        return try {
            val response = apiService.getButtonAlertPreferences(buttonId)
            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to fetch alert preferences"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun toggleButtonAlertPreference(buttonId: String, friendId: String): Result<Boolean> {
        return try {
            val response = apiService.toggleButtonAlertPreference(buttonId, friendId)
            if (response.success) {
                Result.success(response.data.enabled)
            } else {
                val errorMessage = response.error?.message ?: "Failed to toggle alert preference"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun setButtonAlertPreference(
        buttonId: String,
        friendId: String,
        enabled: Boolean,
        alertType: String = "click"
    ): Result<Boolean> {
        return try {
            val request = SetAlertPreferenceRequest(enabled = enabled, alertType = alertType)
            val response = apiService.setButtonAlertPreference(buttonId, friendId, request)
            if (response.success) {
                Result.success(response.data.enabled)
            } else {
                val errorMessage = response.error?.message ?: "Failed to set alert preference"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun selectAllButtonAlerts(buttonId: String): Result<Int> {
        return try {
            val response = apiService.selectAllButtonAlerts(buttonId)
            if (response.success) {
                Result.success(response.data.count)
            } else {
                val errorMessage = response.error?.message ?: "Failed to select all alerts"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deselectAllButtonAlerts(buttonId: String): Result<Int> {
        return try {
            val response = apiService.deselectAllButtonAlerts(buttonId)
            if (response.success) {
                Result.success(response.data.count)
            } else {
                val errorMessage = response.error?.message ?: "Failed to deselect all alerts"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

