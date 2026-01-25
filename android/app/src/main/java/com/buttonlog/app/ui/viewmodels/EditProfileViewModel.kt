package com.buttonlog.app.ui.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.User
import com.buttonlog.app.data.model.UserProfileUpdate
import com.buttonlog.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class EditProfileViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    var user by mutableStateOf<User?>(null)
        private set

    var displayName by mutableStateOf("")
    var firstName by mutableStateOf("")
    var lastName by mutableStateOf("")

    var isLoading by mutableStateOf(false)
        private set

    var isSaving by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var saveSuccess by mutableStateOf(false)
        private set

    fun loadUserProfile() {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null

            when (val result = userRepository.getUserProfile()) {
                is ApiResult.Success -> {
                    user = result.data
                    displayName = result.data.displayName ?: ""
                    firstName = result.data.firstName ?: ""
                    lastName = result.data.lastName ?: ""
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoading = false
        }
    }

    fun saveProfile(onSuccess: () -> Unit) {
        viewModelScope.launch {
            isSaving = true
            errorMessage = null
            saveSuccess = false

            val update = UserProfileUpdate(
                displayName = displayName.ifBlank { null },
                firstName = firstName.ifBlank { null },
                lastName = lastName.ifBlank { null },
                profileVisibility = user?.profileVisibility,
                activityVisibility = user?.activityVisibility
            )

            when (val result = userRepository.updateUserProfile(update)) {
                is ApiResult.Success -> {
                    user = result.data
                    saveSuccess = true
                    onSuccess()
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isSaving = false
        }
    }

    fun clearError() {
        errorMessage = null
    }

    fun clearSaveSuccess() {
        saveSuccess = false
    }
}
