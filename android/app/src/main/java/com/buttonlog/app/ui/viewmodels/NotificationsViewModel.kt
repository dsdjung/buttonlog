package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.Notification
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationsUiState(
    val notifications: List<Notification> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val showUnreadOnly: Boolean = false
) {
    val unreadCount: Int
        get() = notifications.count { !it.isRead }
}

@HiltViewModel
class NotificationsViewModel @Inject constructor(
    private val apiService: APIService
) : ViewModel() {

    private val _uiState = MutableStateFlow(NotificationsUiState())
    val uiState: StateFlow<NotificationsUiState> = _uiState.asStateFlow()

    init {
        loadNotifications()
    }

    fun loadNotifications() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val response = apiService.getNotifications()
                if (response.success) {
                    _uiState.value = _uiState.value.copy(
                        notifications = response.data,
                        isLoading = false
                    )
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load notifications"
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "An error occurred"
                )
            }
        }
    }

    fun markAsRead(notificationId: String) {
        viewModelScope.launch {
            try {
                apiService.markNotificationAsRead(notificationId)
                // Update local state
                _uiState.value = _uiState.value.copy(
                    notifications = _uiState.value.notifications.map { notification ->
                        if (notification.id == notificationId) {
                            notification.copy(isRead = true)
                        } else {
                            notification
                        }
                    }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = "Failed to mark notification as read"
                )
            }
        }
    }

    fun deleteNotification(notificationId: String) {
        viewModelScope.launch {
            try {
                apiService.deleteNotification(notificationId)
                // Remove from local state
                _uiState.value = _uiState.value.copy(
                    notifications = _uiState.value.notifications.filter { it.id != notificationId }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = "Failed to delete notification"
                )
            }
        }
    }

    fun markAllAsRead() {
        viewModelScope.launch {
            val unreadNotifications = _uiState.value.notifications.filter { !it.isRead }
            for (notification in unreadNotifications) {
                try {
                    apiService.markNotificationAsRead(notification.id)
                } catch (e: Exception) {
                    // Continue with other notifications
                }
            }
            // Update local state
            _uiState.value = _uiState.value.copy(
                notifications = _uiState.value.notifications.map { it.copy(isRead = true) }
            )
        }
    }

    fun toggleShowUnreadOnly() {
        _uiState.value = _uiState.value.copy(
            showUnreadOnly = !_uiState.value.showUnreadOnly
        )
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    val filteredNotifications: List<Notification>
        get() = if (_uiState.value.showUnreadOnly) {
            _uiState.value.notifications.filter { !it.isRead }
        } else {
            _uiState.value.notifications
        }
}
