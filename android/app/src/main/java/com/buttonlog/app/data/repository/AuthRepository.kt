package com.buttonlog.app.data.repository

import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.DeviceRegistrationRequest
import com.buttonlog.app.data.api.LoginCredentials
import com.buttonlog.app.data.api.OAuthCallbackRequest
import com.buttonlog.app.data.api.OAuthUserInfo
import com.buttonlog.app.data.api.RegistrationData
import com.buttonlog.app.data.model.AuthUserData
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val apiService: APIService,
    private val sharedPreferences: SharedPreferences
) {
    companion object {
        private const val TAG = "AuthRepository"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
        private const val KEY_ONBOARDING_COMPLETED = "onboarding_completed"
    }

    private val _isLoggedIn = MutableStateFlow(hasToken())
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    private val _onboardingCompleted = MutableStateFlow(getStoredOnboardingStatus())
    val onboardingCompleted: StateFlow<Boolean> = _onboardingCompleted.asStateFlow()

    private fun getStoredOnboardingStatus(): Boolean {
        return sharedPreferences.getBoolean(KEY_ONBOARDING_COMPLETED, false)
    }

    fun hasToken(): Boolean {
        return sharedPreferences.getString(KEY_AUTH_TOKEN, null) != null
    }

    fun getToken(): String? {
        return sharedPreferences.getString(KEY_AUTH_TOKEN, null)
    }

    suspend fun login(email: String, password: String): Result<AuthUserData> {
        return try {
            val response = apiService.login(LoginCredentials(email, password))
            if (response.success && response.data != null) {
                saveAuthData(response.data)
                _isLoggedIn.value = true
                _onboardingCompleted.value = response.data.user.onboardingCompleted
                // Register FCM token for push notifications
                registerFcmToken()
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Login failed"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun register(
        email: String,
        password: String,
        passwordConfirmation: String,
        displayName: String = "",
        username: String = ""
    ): Result<AuthUserData> {
        return try {
            val response = apiService.register(
                RegistrationData(
                    displayName = displayName.ifEmpty { email.substringBefore("@") },
                    email = email,
                    username = username.ifEmpty { email.substringBefore("@") },
                    password = password,
                    passwordConfirmation = passwordConfirmation
                )
            )
            if (response.success && response.data != null) {
                saveAuthData(response.data)
                _isLoggedIn.value = true
                _onboardingCompleted.value = response.data.user.onboardingCompleted
                // Register FCM token for push notifications
                registerFcmToken()
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Registration failed"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun loginWithOAuth(
        provider: String,
        email: String,
        uid: String,
        name: String? = null,
        firstName: String? = null,
        lastName: String? = null,
        image: String? = null,
        accessToken: String? = null
    ): Result<AuthUserData> {
        return try {
            val response = apiService.oauthCallback(
                OAuthCallbackRequest(
                    provider = provider,
                    userInfo = OAuthUserInfo(
                        email = email,
                        uid = uid,
                        name = name,
                        firstName = firstName,
                        lastName = lastName,
                        image = image,
                        accessToken = accessToken
                    )
                )
            )
            if (response.success && response.data != null) {
                saveAuthData(response.data)
                _isLoggedIn.value = true
                _onboardingCompleted.value = response.data.user.onboardingCompleted
                // Register FCM token for push notifications
                registerFcmToken()
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "OAuth login failed"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun completeOnboarding(): Result<Unit> {
        return try {
            val response = apiService.completeOnboarding()
            if (response.success) {
                sharedPreferences.edit()
                    .putBoolean(KEY_ONBOARDING_COMPLETED, true)
                    .apply()
                _onboardingCompleted.value = true
                Result.success(Unit)
            } else {
                // Still mark as completed locally to not block the user
                sharedPreferences.edit()
                    .putBoolean(KEY_ONBOARDING_COMPLETED, true)
                    .apply()
                _onboardingCompleted.value = true
                Result.success(Unit)
            }
        } catch (e: Exception) {
            // Still mark as completed locally to not block the user
            sharedPreferences.edit()
                .putBoolean(KEY_ONBOARDING_COMPLETED, true)
                .apply()
            _onboardingCompleted.value = true
            Result.success(Unit)
        }
    }

    fun logout() {
        sharedPreferences.edit()
            .remove(KEY_AUTH_TOKEN)
            .remove(KEY_USER_ID)
            .remove(KEY_USER_EMAIL)
            .remove(KEY_ONBOARDING_COMPLETED)
            .apply()
        _isLoggedIn.value = false
        _onboardingCompleted.value = false
    }

    suspend fun refreshToken(): Result<String> {
        return try {
            val response = apiService.refreshToken()
            if (response.success && response.data != null) {
                sharedPreferences.edit()
                    .putString(KEY_AUTH_TOKEN, response.data.token)
                    .apply()
                Result.success(response.data.token)
            } else {
                val errorMessage = response.error?.message ?: "Token refresh failed"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            // If token refresh fails, log out the user
            logout()
            Result.failure(e)
        }
    }

    private fun saveAuthData(authUserData: AuthUserData) {
        sharedPreferences.edit()
            .putString(KEY_AUTH_TOKEN, authUserData.token)
            .putString(KEY_USER_ID, authUserData.user.id)
            .putString(KEY_USER_EMAIL, authUserData.user.email)
            .putBoolean(KEY_ONBOARDING_COMPLETED, authUserData.user.onboardingCompleted)
            .apply()
    }

    /**
     * Register FCM token with the backend for push notifications.
     * Should be called after successful login.
     */
    suspend fun registerFcmToken() {
        try {
            val token = FirebaseMessaging.getInstance().token.await()
            Log.d(TAG, "FCM token retrieved: ${token.take(20)}...")

            val request = DeviceRegistrationRequest(
                deviceToken = token,
                platform = "android",
                appVersion = "1.0",
                osVersion = Build.VERSION.RELEASE
            )

            val response = apiService.registerDevice(request)
            if (response.success) {
                Log.d(TAG, "FCM token registered with backend successfully")
            } else {
                Log.e(TAG, "Failed to register FCM token: ${response.error?.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error registering FCM token", e)
        }
    }
}
