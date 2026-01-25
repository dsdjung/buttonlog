package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.NotificationPreferences
import com.buttonlog.app.data.model.NotificationPreferencesUpdate
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
}
