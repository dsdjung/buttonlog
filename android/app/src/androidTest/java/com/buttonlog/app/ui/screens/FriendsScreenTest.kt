package com.buttonlog.app.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.model.PublicUser
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class FriendsScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun friendsScreen_showsHeader_withInviteButton() {
        composeTestRule.setContent {
            FriendsScreen(
                onFriendSelected = {},
                onCreatedGiftButtonsClick = {}
            )
        }

        composeTestRule.onNodeWithText("Friends").assertIsDisplayed()
        composeTestRule.onNodeWithText("Invite").assertIsDisplayed()
    }

    @Test
    fun emptyFriendsView_showsNoFriendsMessage() {
        composeTestRule.setContent {
            EmptyFriendsView(onAddFriend = {})
        }

        composeTestRule.onNodeWithText("No friends yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Invite friends to see their buttons and activity").assertIsDisplayed()
    }

    @Test
    fun emptyFriendsView_inviteButtonWorks() {
        var inviteClicked = false

        composeTestRule.setContent {
            EmptyFriendsView(onAddFriend = { inviteClicked = true })
        }

        composeTestRule.onNodeWithText("Invite Friend").performClick()
        assert(inviteClicked)
    }

    @Test
    fun pendingFriendRequestCard_showsAcceptAndDeclineButtons() {
        val friend = createTestFriend(status = FriendshipStatus.PENDING)

        composeTestRule.setContent {
            PendingFriendRequestCard(
                friend = friend,
                onAccept = {}
            )
        }

        composeTestRule.onNodeWithText("Accept").assertIsDisplayed()
        composeTestRule.onNodeWithText("Decline").assertIsDisplayed()
    }

    @Test
    fun pendingFriendRequestCard_showsFriendName() {
        val friend = createTestFriend(
            displayName = "John Doe",
            username = "johndoe",
            status = FriendshipStatus.PENDING
        )

        composeTestRule.setContent {
            PendingFriendRequestCard(
                friend = friend,
                onAccept = {}
            )
        }

        composeTestRule.onNodeWithText("John Doe").assertIsDisplayed()
        composeTestRule.onNodeWithText("@johndoe").assertIsDisplayed()
    }

    @Test
    fun friendCard_showsFriendInfo() {
        val friend = createTestFriend(
            displayName = "Jane Smith",
            username = "janesmith",
            status = FriendshipStatus.ACCEPTED
        )

        composeTestRule.setContent {
            FriendCard(
                friend = friend,
                onClick = {}
            )
        }

        composeTestRule.onNodeWithText("Jane Smith").assertIsDisplayed()
        composeTestRule.onNodeWithText("@janesmith").assertIsDisplayed()
    }

    @Test
    fun friendCard_isClickable() {
        var clicked = false
        val friend = createTestFriend()

        composeTestRule.setContent {
            FriendCard(
                friend = friend,
                onClick = { clicked = true }
            )
        }

        composeTestRule.onNodeWithText("Test User").performClick()
        assert(clicked)
    }

    @Test
    fun createdGiftButtonsCard_isClickable() {
        var clicked = false

        composeTestRule.setContent {
            CreatedGiftButtonsCard(onClick = { clicked = true })
        }

        composeTestRule.onNodeWithText("Buttons I Created for Friends").performClick()
        assert(clicked)
    }

    @Test
    fun addFriendDialog_showsEmailField() {
        composeTestRule.setContent {
            AddFriendDialog(
                onDismiss = {},
                onSendRequest = { _, _ -> }
            )
        }

        composeTestRule.onNodeWithText("Invite Friend").assertIsDisplayed()
        composeTestRule.onNodeWithText("Email address").assertIsDisplayed()
    }

    @Test
    fun addFriendDialog_sendButtonDisabled_whenEmailEmpty() {
        composeTestRule.setContent {
            AddFriendDialog(
                onDismiss = {},
                onSendRequest = { _, _ -> }
            )
        }

        // Send button should be disabled when email is empty
        composeTestRule.onNodeWithText("Send Invite").assertIsNotEnabled()
    }

    @Test
    fun addFriendDialog_sendButtonEnabled_whenValidEmail() {
        composeTestRule.setContent {
            AddFriendDialog(
                onDismiss = {},
                onSendRequest = { _, _ -> }
            )
        }

        // Enter valid email
        composeTestRule.onNodeWithText("Email address").performTextInput("test@example.com")

        // Send button should be enabled
        composeTestRule.onNodeWithText("Send Invite").assertIsEnabled()
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
