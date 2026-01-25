package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.WebhookSettings
import com.buttonlog.app.data.model.WebhookSettingsUpdate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WebhookRepository @Inject constructor(
    private val apiService: APIService
) {

    suspend fun getWebhookSettings(): ApiResult<WebhookSettings> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getWebhookSettings()
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to load webhook settings")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to load webhook settings")
        }
    }

    suspend fun updateWebhookSettings(
        webhookUrl: String?,
        webhookEnabled: Boolean,
        webhookSecret: String?,
        retryFailed: Boolean,
        maxRetries: Int
    ): ApiResult<WebhookSettings> = withContext(Dispatchers.IO) {
        try {
            val update = WebhookSettingsUpdate(
                defaultWebhookUrl = webhookUrl,
                defaultWebhookEnabled = webhookEnabled,
                webhookSecret = webhookSecret,
                retryFailed = retryFailed,
                maxRetries = maxRetries
            )
            val response = apiService.updateWebhookSettings(update)
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to update webhook settings")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to update webhook settings")
        }
    }

    suspend fun testWebhook(): ApiResult<String> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.testWebhook()
            if (response.success) {
                ApiResult.Success("Test webhook sent successfully")
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to send test webhook")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to send test webhook")
        }
    }
}
