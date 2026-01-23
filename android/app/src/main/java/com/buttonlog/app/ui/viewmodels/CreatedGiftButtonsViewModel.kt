package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.CreatedGiftButton
import com.buttonlog.app.data.repository.ButtonRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CreatedGiftButtonsUiState(
    val giftButtons: List<CreatedGiftButton> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class CreatedGiftButtonsViewModel @Inject constructor(
    private val buttonRepository: ButtonRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreatedGiftButtonsUiState())
    val uiState: StateFlow<CreatedGiftButtonsUiState> = _uiState.asStateFlow()

    fun fetchCreatedGiftButtons() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            buttonRepository.getCreatedGiftButtons()
                .onSuccess { buttons ->
                    _uiState.update { it.copy(giftButtons = buttons, isLoading = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    fun refreshCreatedGiftButtons() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true, error = null) }

            buttonRepository.getCreatedGiftButtons()
                .onSuccess { buttons ->
                    _uiState.update { it.copy(giftButtons = buttons, isRefreshing = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isRefreshing = false) }
                }
        }
    }

    fun updateGiftButton(buttonId: String, formData: ButtonFormData) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            buttonRepository.updateGiftButton(buttonId, formData)
                .onSuccess {
                    // Refresh the list to get updated data
                    fetchCreatedGiftButtons()
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    fun deleteGiftButton(buttonId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            buttonRepository.deleteButton(buttonId)
                .onSuccess {
                    // Remove from local list
                    _uiState.update { state ->
                        state.copy(
                            giftButtons = state.giftButtons.filter { it.id != buttonId },
                            isLoading = false
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
