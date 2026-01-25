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
class PrivacySettingsViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private var user: User? = null

    var profileVisibility by mutableStateOf("friends")
        private set

    var activityVisibility by mutableStateOf("friends")
        private set

    var isLoading by mutableStateOf(false)
        private set

    var isSaving by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var saveSuccess by mutableStateOf(false)
        private set

    fun loadSettings() {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null

            when (val result = userRepository.getUserProfile()) {
                is ApiResult.Success -> {
                    user = result.data
                    profileVisibility = result.data.profileVisibility ?: "friends"
                    activityVisibility = result.data.activityVisibility ?: "friends"
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoading = false
        }
    }

    fun setProfileVisibility(visibility: String) {
        if (profileVisibility == visibility) return
        profileVisibility = visibility
        saveSettings()
    }

    fun setActivityVisibility(visibility: String) {
        if (activityVisibility == visibility) return
        activityVisibility = visibility
        saveSettings()
    }

    private fun saveSettings() {
        viewModelScope.launch {
            isSaving = true
            errorMessage = null
            saveSuccess = false

            val update = UserProfileUpdate(
                displayName = user?.displayName,
                firstName = user?.firstName,
                lastName = user?.lastName,
                profileVisibility = profileVisibility,
                activityVisibility = activityVisibility
            )

            when (val result = userRepository.updateUserProfile(update)) {
                is ApiResult.Success -> {
                    user = result.data
                    saveSuccess = true
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                    // Revert to previous values on error
                    user?.let {
                        profileVisibility = it.profileVisibility ?: "friends"
                        activityVisibility = it.activityVisibility ?: "friends"
                    }
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
