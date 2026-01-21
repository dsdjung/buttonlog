package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonClick
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
            
            val fetchedButtons = apiService.getButtons()
            _buttons.value = fetchedButtons
            
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
            
            val newButton = apiService.createButton(buttonData)
            _buttons.value = _buttons.value + newButton
            
            Result.success(newButton)
            
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
            
            val updatedButton = apiService.updateButton(button)
            val currentButtons = _buttons.value.toMutableList()
            val index = currentButtons.indexOfFirst { it.id == button.id }
            
            if (index != -1) {
                currentButtons[index] = updatedButton
                _buttons.value = currentButtons
            }
            
            Result.success(updatedButton)
            
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
    
    suspend fun clickButton(buttonId: String): Result<ButtonClick> {
        return try {
            _error.value = null
            
            val click = apiService.clickButton(buttonId)
            
            // Update button state if it's a state button
            val currentButtons = _buttons.value.toMutableList()
            val buttonIndex = currentButtons.indexOfFirst { it.id == buttonId }
            
            if (buttonIndex != -1) {
                val button = currentButtons[buttonIndex]
                if (button.type == com.buttonlog.app.data.model.ButtonType.STATE) {
                    // Toggle state
                    val newState = if (button.currentState == com.buttonlog.app.data.model.ButtonState.IDLE) {
                        com.buttonlog.app.data.model.ButtonState.ACTIVE
                    } else {
                        com.buttonlog.app.data.model.ButtonState.IDLE
                    }
                    
                    val updatedButton = button.copy(
                        currentState = newState,
                        stateChangedAt = java.util.Date()
                    )
                    
                    currentButtons[buttonIndex] = updatedButton
                    _buttons.value = currentButtons
                }
            }
            
            Result.success(click)
            
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to click button"
            Result.failure(e)
        }
    }
    
    fun getButton(by id: String): Button? {
        return _buttons.value.find { it.id == id }
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
}

