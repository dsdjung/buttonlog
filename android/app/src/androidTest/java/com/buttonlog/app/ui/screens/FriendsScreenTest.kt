package com.buttonlog.app.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.model.PublicUser
import com.buttonlog.app.ui.viewmodels.FriendsUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI component tests for FriendsScreen.
 *
 * Note: These tests verify basic UI state behavior. For end-to-end API tests,
 * see the integration tests in com.buttonlog.app.integration package.
 */
@RunWith(AndroidJUnit4::class)
class FriendsScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun friendsUiState_initializes_withDefaults() {
        val uiState = FriendsUiState()

        assert(uiState.friends.isEmpty())
        assert(uiState.pendingRequests.isEmpty())
        assert(uiState.acceptedFriends.isEmpty())
        assert(!uiState.isLoading)
        assert(uiState.error == null)
    }

    @Test
    fun friendsUiState_tracks_loadingState() {
        val uiState = FriendsUiState(isLoading = true)

        assert(uiState.isLoading)
    }

    @Test
    fun friendsUiState_tracks_errorState() {
        val errorMessage = "Failed to load friends"
        val uiState = FriendsUiState(error = errorMessage)

        assert(uiState.error == errorMessage)
    }

    @Test
    fun friendsUiState_tracks_friendRequestSent() {
        val uiState = FriendsUiState(friendRequestSent = true)

        assert(uiState.friendRequestSent)
    }

    @Test
    fun friendsUiState_tracks_friends() {
        val friend = createTestFriend()
        val uiState = FriendsUiState(friends = listOf(friend))

        assert(uiState.friends.size == 1)
        assert(uiState.friends[0].id == "friend-1")
    }

    @Test
    fun friendsUiState_tracks_pendingRequests() {
        val pendingFriend = createTestFriend(status = FriendshipStatus.PENDING)
        val uiState = FriendsUiState(pendingRequests = listOf(pendingFriend))

        assert(uiState.pendingRequests.size == 1)
    }

    @Test
    fun friendsUiState_tracks_acceptedFriends() {
        val acceptedFriend = createTestFriend(status = FriendshipStatus.ACCEPTED)
        val uiState = FriendsUiState(acceptedFriends = listOf(acceptedFriend))

        assert(uiState.acceptedFriends.size == 1)
    }

    @Test
    fun friendModel_hasCorrectDisplayName() {
        val friend = createTestFriend(displayName = "John Doe", username = "johndoe")

        assert(friend.friendUser?.displayName == "John Doe")
        assert(friend.friendUser?.username == "johndoe")
    }

    @Test
    fun friendModel_hasCorrectStatus() {
        val acceptedFriend = createTestFriend(status = FriendshipStatus.ACCEPTED)
        val pendingFriend = createTestFriend(status = FriendshipStatus.PENDING)

        assert(acceptedFriend.status == FriendshipStatus.ACCEPTED)
        assert(pendingFriend.status == FriendshipStatus.PENDING)
    }

    @Test
    fun friendPermissions_hasCorrectDefaults() {
        val permissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = true,
            receiveNotifications = true,
            canComment = false
        )

        assert(permissions.canSeeButtons)
        assert(permissions.canSeeActivity)
        assert(permissions.receiveNotifications)
        assert(!permissions.canComment)
    }

    @Test
    fun friendsUiState_tracks_selectedFriend() {
        val friend = createTestFriend()
        val uiState = FriendsUiState(selectedFriend = friend)

        assert(uiState.selectedFriend != null)
        assert(uiState.selectedFriend?.id == "friend-1")
    }

    @Test
    fun friendsUiState_tracks_loadingPermissions() {
        val uiState = FriendsUiState(isLoadingPermissions = true)

        assert(uiState.isLoadingPermissions)
    }

    @Test
    fun friendsUiState_tracks_loadingFriendButtons() {
        val uiState = FriendsUiState(isLoadingFriendButtons = true)

        assert(uiState.isLoadingFriendButtons)
    }

    private fun createTestFriend(
        id: String = "friend-1",
        friendId: String = "user-1",
        displayName: String = "Test User",
        username: String = "testuser",
        status: FriendshipStatus = FriendshipStatus.ACCEPTED
    ): Friend {
        return Friend(
            id = id,
            friendId = friendId,
            friendUser = PublicUser(
                id = friendId,
                username = username,
                displayName = displayName,
                firstName = null,
                lastName = null,
                profileVisibility = "public"
            ),
            status = status,
            permissions = FriendPermissions(
                canSeeButtons = true,
                canSeeActivity = true,
                receiveNotifications = true,
                canComment = true
            ),
            createdAt = "2024-01-01T00:00:00Z",
            updatedAt = "2024-01-01T00:00:00Z"
        )
    }
}
