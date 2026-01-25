package com.buttonlog.app.ui.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PasswordChangeViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    var currentPassword by mutableStateOf("")
    var newPassword by mutableStateOf("")
    var confirmPassword by mutableStateOf("")

    var isLoading by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var successMessage by mutableStateOf<String?>(null)
        private set

    val isFormValid: Boolean
        get() = currentPassword.isNotBlank() &&
                newPassword.length >= 8 &&
                newPassword == confirmPassword

    fun changePassword() {
        if (!isFormValid) return

        viewModelScope.launch {
            isLoading = true
            errorMessage = null
            successMessage = null

            when (val result = userRepository.changePassword(
                currentPassword = currentPassword,
                newPassword = newPassword,
                confirmPassword = confirmPassword
            )) {
                is ApiResult.Success -> {
                    successMessage = "Password changed successfully"
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoading = false
        }
    }

    fun clearError() {
        errorMessage = null
    }

    fun clearSuccess() {
        successMessage = null
    }
}
