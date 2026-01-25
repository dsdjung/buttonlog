package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiResult
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
}
