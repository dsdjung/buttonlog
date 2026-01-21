package com.buttonlog.app.data.repository

import android.content.SharedPreferences
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.LoginCredentials
import com.buttonlog.app.data.api.RegistrationData
import com.buttonlog.app.data.model.AuthUserData
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val apiService: APIService,
    private val sharedPreferences: SharedPreferences
) {
    companion object {
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
    }

    private val _isLoggedIn = MutableStateFlow(hasToken())
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

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
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Registration failed"
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun logout() {
        sharedPreferences.edit()
            .remove(KEY_AUTH_TOKEN)
            .remove(KEY_USER_ID)
            .remove(KEY_USER_EMAIL)
            .apply()
        _isLoggedIn.value = false
    }

    private fun saveAuthData(authUserData: AuthUserData) {
        sharedPreferences.edit()
            .putString(KEY_AUTH_TOKEN, authUserData.token)
            .putString(KEY_USER_ID, authUserData.user.id)
            .putString(KEY_USER_EMAIL, authUserData.user.email)
            .apply()
    }
}
