package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    val isLoggedIn: StateFlow<Boolean> = authRepository.isLoggedIn
    val onboardingCompleted: StateFlow<Boolean> = authRepository.onboardingCompleted

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.login(email, password)
                .onSuccess {
                    // Login successful, isLoggedIn will be updated by repository
                }
                .onFailure { error ->
                    _errorMessage.value = error.message ?: "Login failed"
                }

            _isLoading.value = false
        }
    }

    fun register(email: String, password: String, confirmPassword: String) {
        if (password != confirmPassword) {
            _errorMessage.value = "Passwords do not match"
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.register(email, password, confirmPassword)
                .onSuccess {
                    // Registration successful, isLoggedIn will be updated by repository
                }
                .onFailure { error ->
                    _errorMessage.value = error.message ?: "Registration failed"
                }

            _isLoading.value = false
        }
    }

    fun loginWithOAuth(
        provider: String,
        email: String,
        uid: String,
        name: String? = null,
        firstName: String? = null,
        lastName: String? = null,
        image: String? = null,
        accessToken: String? = null
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.loginWithOAuth(
                provider = provider,
                email = email,
                uid = uid,
                name = name,
                firstName = firstName,
                lastName = lastName,
                image = image,
                accessToken = accessToken
            )
                .onSuccess {
                    // OAuth login successful, isLoggedIn will be updated by repository
                }
                .onFailure { error ->
                    _errorMessage.value = error.message ?: "OAuth login failed"
                }

            _isLoading.value = false
        }
    }

    fun logout() {
        authRepository.logout()
    }

    fun completeOnboarding() {
        viewModelScope.launch {
            authRepository.completeOnboarding()
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun setError(message: String) {
        _errorMessage.value = message
    }
}
