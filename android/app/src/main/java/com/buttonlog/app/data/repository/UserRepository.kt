package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.NotificationPreferences
import com.buttonlog.app.data.model.NotificationPreferencesUpdate
import com.buttonlog.app.data.model.PasswordChangeRequest
import com.buttonlog.app.data.model.User
import com.buttonlog.app.data.model.UserProfileUpdate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepository @Inject constructor(
    private val apiService: APIService
) {

    suspend fun getUserProfile(): ApiResult<User> = withContext(Dispatchers.IO) {
        try {
            val user = apiService.getUserProfile()
            ApiResult.Success(user)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to load user profile")
        }
    }

    suspend fun updateUserProfile(update: UserProfileUpdate): ApiResult<User> = withContext(Dispatchers.IO) {
        try {
            val user = apiService.updateUserProfile(update)
            ApiResult.Success(user)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to update profile")
        }
    }

    suspend fun getNotificationPreferences(): ApiResult<NotificationPreferences> = withContext(Dispatchers.IO) {
        try {
            val prefs = apiService.getNotificationPreferences()
            ApiResult.Success(prefs)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to load notification preferences")
        }
    }

    suspend fun updateNotificationPreferences(update: NotificationPreferencesUpdate): ApiResult<NotificationPreferences> = withContext(Dispatchers.IO) {
        try {
            val prefs = apiService.updateNotificationPreferences(update)
            ApiResult.Success(prefs)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to update notification preferences")
        }
    }

    suspend fun changePassword(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String
    ): ApiResult<String> = withContext(Dispatchers.IO) {
        try {
            val request = PasswordChangeRequest(
                currentPassword = currentPassword,
                newPassword = newPassword,
                confirmPassword = confirmPassword
            )
            val response = apiService.changePassword(request)
            if (response.success) {
                ApiResult.Success(response.data?.message ?: "Password changed successfully")
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to change password")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to change password")
        }
    }

    suspend fun exportData(format: String): ApiResult<Pair<ByteArray, String>> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.exportData(format)
            val contentDisposition = response.headers()["Content-Disposition"] ?: ""
            val body = response.body()

            if (response.isSuccessful && body != null) {
                val data = body.bytes()
                // Extract filename from Content-Disposition header
                val filename = if (contentDisposition.contains("filename=")) {
                    contentDisposition.substringAfter("filename=\"").substringBefore("\"")
                } else {
                    "buttonlog_export.$format"
                }
                ApiResult.Success(Pair(data, filename))
            } else {
                ApiResult.Error("Export failed: ${response.code()}")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Failed to export data")
        }
    }
}
