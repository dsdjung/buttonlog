package com.buttonlog.app.ui.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.repository.WebhookRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class WebhookSettingsViewModel @Inject constructor(
    private val webhookRepository: WebhookRepository
) : ViewModel() {

    var webhookUrl by mutableStateOf("")
    var webhookEnabled by mutableStateOf(false)
    var webhookSecret by mutableStateOf("")
    var retryFailed by mutableStateOf(true)
    var maxRetries by mutableIntStateOf(3)

    var isLoading by mutableStateOf(true)
        private set

    var isSaving by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var successMessage by mutableStateOf<String?>(null)
        private set

    val isFormValid: Boolean
        get() = !webhookEnabled || webhookUrl.isNotBlank()

    init {
        loadSettings()
    }

    private fun loadSettings() {
        viewModelScope.launch {
            isLoading = true

            when (val result = webhookRepository.getWebhookSettings()) {
                is ApiResult.Success -> {
                    val settings = result.data
                    webhookUrl = settings.defaultWebhookUrl ?: ""
                    webhookEnabled = settings.defaultWebhookEnabled
                    webhookSecret = settings.webhookSecret ?: ""
                    retryFailed = settings.retryFailed
                    maxRetries = settings.maxRetries
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoading = false
        }
    }

    fun saveSettings() {
        viewModelScope.launch {
            isSaving = true
            errorMessage = null

            when (val result = webhookRepository.updateWebhookSettings(
                webhookUrl = webhookUrl.ifBlank { null },
                webhookEnabled = webhookEnabled,
                webhookSecret = webhookSecret.ifBlank { null },
                retryFailed = retryFailed,
                maxRetries = maxRetries
            )) {
                is ApiResult.Success -> {
                    successMessage = "Settings saved successfully"
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isSaving = false
        }
    }

    fun testWebhook() {
        viewModelScope.launch {
            when (val result = webhookRepository.testWebhook()) {
                is ApiResult.Success -> {
                    successMessage = "Test webhook sent successfully"
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }
        }
    }

    fun clearError() {
        errorMessage = null
    }

    fun clearSuccess() {
        successMessage = null
    }
}
