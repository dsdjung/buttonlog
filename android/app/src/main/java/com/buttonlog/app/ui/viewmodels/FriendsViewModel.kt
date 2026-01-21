package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.repository.FriendsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FriendsViewModel @Inject constructor(
    private val friendsRepository: FriendsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FriendsUiState())
    val uiState: StateFlow<FriendsUiState> = _uiState.asStateFlow()

    init {
        // Observe friends from repository
        friendsRepository.friends.onEach { friends ->
            _uiState.update {
                it.copy(
                    friends = friends,
                    acceptedFriends = friends.filter { f -> f.status == FriendshipStatus.ACCEPTED },
                    pendingRequests = friends.filter { f -> f.status == FriendshipStatus.PENDING }
                )
            }
        }.launchIn(viewModelScope)

        // Observe loading state
        friendsRepository.isLoading.onEach { isLoading ->
            _uiState.update { it.copy(isLoading = isLoading) }
        }.launchIn(viewModelScope)

        // Observe errors
        friendsRepository.error.onEach { error ->
            _uiState.update { it.copy(error = error) }
        }.launchIn(viewModelScope)
    }

    fun fetchFriends() {
        viewModelScope.launch {
            friendsRepository.fetchFriends()
        }
    }

    fun sendFriendRequest(email: String? = null, username: String? = null) {
        viewModelScope.launch {
            val result = friendsRepository.sendFriendRequest(email, username)
            if (result.isSuccess) {
                _uiState.update { it.copy(friendRequestSent = true) }
            }
        }
    }

    fun acceptFriendRequest(friendshipId: String) {
        viewModelScope.launch {
            friendsRepository.acceptFriendRequest(friendshipId)
        }
    }

    fun removeFriend(friendshipId: String) {
        viewModelScope.launch {
            friendsRepository.removeFriend(friendshipId)
        }
    }

    fun loadFriendPermissions(friendId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingPermissions = true) }
            val result = friendsRepository.getFriendPermissions(friendId)
            result.fold(
                onSuccess = { permissions ->
                    _uiState.update {
                        it.copy(
                            selectedFriendPermissions = permissions,
                            isLoadingPermissions = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isLoadingPermissions = false
                        )
                    }
                }
            )
        }
    }

    fun updateFriendPermissions(friendId: String, permissions: FriendPermissionUpdate) {
        viewModelScope.launch {
            val result = friendsRepository.updateFriendPermissions(friendId, permissions)
            result.fold(
                onSuccess = { updatedPermissions ->
                    _uiState.update {
                        it.copy(selectedFriendPermissions = updatedPermissions)
                    }
                },
                onFailure = { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            )
        }
    }

    fun loadFriendButtons(friendId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingFriendButtons = true) }
            val result = friendsRepository.getFriendButtons(friendId)
            result.fold(
                onSuccess = { buttons ->
                    _uiState.update {
                        it.copy(
                            friendButtons = buttons,
                            isLoadingFriendButtons = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isLoadingFriendButtons = false
                        )
                    }
                }
            )
        }
    }

    fun selectFriend(friend: Friend?) {
        _uiState.update {
            it.copy(
                selectedFriend = friend,
                friendButtons = emptyList(),
                selectedFriendPermissions = null
            )
        }
        friend?.let {
            loadFriendPermissions(it.friendId)
            loadFriendButtons(it.friendId)
        }
    }

    fun clearFriendRequestSent() {
        _uiState.update { it.copy(friendRequestSent = false) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
        friendsRepository.clearError()
    }
}

data class FriendsUiState(
    val friends: List<Friend> = emptyList(),
    val acceptedFriends: List<Friend> = emptyList(),
    val pendingRequests: List<Friend> = emptyList(),
    val selectedFriend: Friend? = null,
    val selectedFriendPermissions: FriendPermissions? = null,
    val friendButtons: List<Button> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingPermissions: Boolean = false,
    val isLoadingFriendButtons: Boolean = false,
    val friendRequestSent: Boolean = false,
    val error: String? = null
)
