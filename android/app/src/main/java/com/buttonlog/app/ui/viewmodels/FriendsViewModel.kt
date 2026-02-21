package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.AcceptedFriend
import com.buttonlog.app.data.api.InviteLinkData
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendButton
import com.buttonlog.app.data.model.FriendActivity
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.model.ActivityCursor
import com.buttonlog.app.data.repository.FriendsRepository
import com.buttonlog.app.data.repository.PermissionDeniedException
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

    fun refreshFriends() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }
            friendsRepository.fetchFriends()
            _uiState.update { it.copy(isRefreshing = false) }
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

    fun loadFriendActivity(friendId: String, refresh: Boolean = true) {
        viewModelScope.launch {
            val currentCursor = if (refresh) null else _uiState.value.activityNextCursor
            android.util.Log.d("FriendsViewModel", "loadFriendActivity: friendId=$friendId, refresh=$refresh, cursor=$currentCursor")

            _uiState.update {
                it.copy(
                    isLoadingFriendActivity = refresh && it.friendActivity.isEmpty(),
                    isLoadingMoreActivity = !refresh,
                    activityPermissionDenied = false
                )
            }

            val result = friendsRepository.getFriendActivity(friendId, cursor = currentCursor)
            result.fold(
                onSuccess = { page ->
                    android.util.Log.d("FriendsViewModel", "loadFriendActivity success: received ${page.activities.size} activities, hasMore=${page.hasMore}")
                    _uiState.update {
                        val newActivities = if (refresh) page.activities else it.friendActivity + page.activities
                        android.util.Log.d("FriendsViewModel", "loadFriendActivity: total activities now ${newActivities.size}")
                        it.copy(
                            friendActivity = newActivities,
                            activityHasMore = page.hasMore,
                            activityNextCursor = page.nextCursor,
                            isLoadingFriendActivity = false,
                            isLoadingMoreActivity = false,
                            activityPermissionDenied = false
                        )
                    }
                },
                onFailure = { error ->
                    val isPermissionDenied = error is PermissionDeniedException
                    _uiState.update {
                        it.copy(
                            error = if (isPermissionDenied) null else error.message,
                            isLoadingFriendActivity = false,
                            isLoadingMoreActivity = false,
                            activityPermissionDenied = isPermissionDenied
                        )
                    }
                }
            )
        }
    }

    fun loadMoreActivity(friendId: String) {
        val state = _uiState.value
        if (state.activityHasMore && !state.isLoadingMoreActivity && state.activityNextCursor != null) {
            loadFriendActivity(friendId, refresh = false)
        }
    }

    fun selectFriend(friend: Friend?) {
        _uiState.update {
            it.copy(
                selectedFriend = friend,
                friendButtons = emptyList(),
                friendActivity = emptyList(),
                selectedFriendPermissions = null,
                activityPermissionDenied = false,
                activityHasMore = false,
                activityNextCursor = null
            )
        }
        friend?.let {
            loadFriendPermissions(it.friendId)
            loadFriendButtons(it.friendId)
            loadFriendActivity(it.friendId, refresh = true)
        }
    }

    fun clearFriendRequestSent() {
        _uiState.update { it.copy(friendRequestSent = false) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
        friendsRepository.clearError()
    }

    // MARK: - Invite Links

    fun loadInviteLink() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingInviteLink = true) }
            val result = friendsRepository.getInviteLink()
            result.fold(
                onSuccess = { inviteData ->
                    _uiState.update {
                        it.copy(
                            inviteLinkData = inviteData,
                            isLoadingInviteLink = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isLoadingInviteLink = false
                        )
                    }
                }
            )
        }
    }

    fun acceptInvite(code: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isAcceptingInvite = true) }
            val result = friendsRepository.acceptInvite(code)
            result.fold(
                onSuccess = { data ->
                    _uiState.update {
                        it.copy(
                            acceptedFriend = data.friend,
                            showInviteAcceptedDialog = true,
                            isAcceptingInvite = false
                        )
                    }
                    // Refresh friends list
                    fetchFriends()
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            error = error.message,
                            isAcceptingInvite = false
                        )
                    }
                }
            )
        }
    }

    fun clearInviteAcceptedDialog() {
        _uiState.update {
            it.copy(
                showInviteAcceptedDialog = false,
                acceptedFriend = null
            )
        }
    }
}

data class FriendsUiState(
    val friends: List<Friend> = emptyList(),
    val acceptedFriends: List<Friend> = emptyList(),
    val pendingRequests: List<Friend> = emptyList(),
    val selectedFriend: Friend? = null,
    val selectedFriendPermissions: FriendPermissions? = null,
    val friendButtons: List<FriendButton> = emptyList(),
    val friendActivity: List<FriendActivity> = emptyList(),
    val activityHasMore: Boolean = false,
    val activityNextCursor: ActivityCursor? = null,
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isLoadingPermissions: Boolean = false,
    val isLoadingFriendButtons: Boolean = false,
    val isLoadingFriendActivity: Boolean = false,
    val isLoadingMoreActivity: Boolean = false,
    val activityPermissionDenied: Boolean = false,
    val friendRequestSent: Boolean = false,
    val error: String? = null,
    // Invite link state
    val inviteLinkData: InviteLinkData? = null,
    val isLoadingInviteLink: Boolean = false,
    val isAcceptingInvite: Boolean = false,
    val acceptedFriend: AcceptedFriend? = null,
    val showInviteAcceptedDialog: Boolean = false
)
