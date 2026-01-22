package com.buttonlog.app.data.repository

import app.cash.turbine.test
import com.buttonlog.app.data.api.APIResponse
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.FriendActivityResponse
import com.buttonlog.app.data.api.FriendPermissionUpdateRequest
import com.buttonlog.app.data.api.FriendRequestBody
import com.buttonlog.app.data.api.PaginationMeta
import com.buttonlog.app.data.model.ActivityCursor
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendActivity
import com.buttonlog.app.data.model.FriendButton
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.model.PublicUser
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.ButtonState
import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class FriendsRepositoryTest {

    private lateinit var apiService: APIService
    private lateinit var repository: FriendsRepository

    private val testPublicUser = PublicUser(
        id = "user-1",
        username = "testuser",
        displayName = "Test User",
        avatar = null
    )

    private val testFriend = Friend(
        id = "friendship-1",
        friendId = "user-1",
        friendUser = testPublicUser,
        status = FriendshipStatus.ACCEPTED,
        permissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = true,
            receiveNotifications = true,
            canComment = false
        ),
        createdAt = "2024-01-01T00:00:00Z"
    )

    private val testFriendButton = FriendButton(
        id = "button-1",
        name = "Test Button",
        type = ButtonType.INSTANT,
        icon = "star",
        color = "#007AFF",
        currentState = ButtonState.IDLE,
        latestClickAt = "2024-01-01T12:00:00Z",
        latestClickAction = "click",
        latestClickLocation = null,
        latestClickDevice = "Android",
        latestClickPlatform = "android"
    )

    private val testFriendActivity = FriendActivity(
        id = "activity-1",
        buttonId = "button-1",
        buttonName = "Test Button",
        buttonType = "instant",
        buttonColor = "#007AFF",
        action = "click",
        clickedAt = "2024-01-01T12:00:00Z",
        duration = null
    )

    @Before
    fun setup() {
        apiService = mockk()
        repository = FriendsRepository(apiService)
    }

    @Test
    fun `fetchFriends success updates friends flow`() = runTest {
        // Given
        val friends = listOf(testFriend)
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = friends,
            error = null
        )

        // When
        repository.fetchFriends()

        // Then
        repository.friends.test {
            assertThat(awaitItem()).isEqualTo(friends)
        }
    }

    @Test
    fun `fetchFriends failure updates error flow`() = runTest {
        // Given
        coEvery { apiService.getFriends() } returns APIResponse(
            success = false,
            data = emptyList(),
            error = com.buttonlog.app.data.api.APIError(
                code = "ERROR",
                message = "Network error"
            )
        )

        // When
        repository.fetchFriends()

        // Then
        repository.error.test {
            assertThat(awaitItem()).isEqualTo("Network error")
        }
    }

    @Test
    fun `acceptedFriends returns only accepted friends`() = runTest {
        // Given
        val pendingFriend = testFriend.copy(id = "2", status = FriendshipStatus.PENDING)
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend, pendingFriend),
            error = null
        )
        repository.fetchFriends()

        // When
        val accepted = repository.acceptedFriends

        // Then
        assertThat(accepted).hasSize(1)
        assertThat(accepted.first().id).isEqualTo("friendship-1")
    }

    @Test
    fun `pendingFriendRequests returns only pending friends`() = runTest {
        // Given
        val pendingFriend = testFriend.copy(id = "2", status = FriendshipStatus.PENDING)
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend, pendingFriend),
            error = null
        )
        repository.fetchFriends()

        // When
        val pending = repository.pendingFriendRequests

        // Then
        assertThat(pending).hasSize(1)
        assertThat(pending.first().id).isEqualTo("2")
    }

    @Test
    fun `sendFriendRequest success`() = runTest {
        // Given
        coEvery { apiService.sendFriendRequest(any()) } returns APIResponse(
            success = true,
            data = Unit,
            error = null
        )

        // When
        val result = repository.sendFriendRequest(email = "test@example.com")

        // Then
        assertThat(result.isSuccess).isTrue()
        coVerify { apiService.sendFriendRequest(FriendRequestBody(email = "test@example.com", username = null)) }
    }

    @Test
    fun `sendFriendRequest failure returns error`() = runTest {
        // Given
        coEvery { apiService.sendFriendRequest(any()) } returns APIResponse(
            success = false,
            data = Unit,
            error = com.buttonlog.app.data.api.APIError(
                code = "USER_NOT_FOUND",
                message = "User not found"
            )
        )

        // When
        val result = repository.sendFriendRequest(email = "nonexistent@example.com")

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).isEqualTo("User not found")
    }

    @Test
    fun `acceptFriendRequest success refetches friends`() = runTest {
        // Given
        coEvery { apiService.acceptFriendRequest("friendship-1") } returns APIResponse(
            success = true,
            data = Unit,
            error = null
        )
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend),
            error = null
        )

        // When
        val result = repository.acceptFriendRequest("friendship-1")

        // Then
        assertThat(result.isSuccess).isTrue()
        coVerify { apiService.getFriends() }
    }

    @Test
    fun `removeFriend success removes friend from list`() = runTest {
        // Given - first load friends
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend),
            error = null
        )
        repository.fetchFriends()

        coEvery { apiService.removeFriend("friendship-1") } returns APIResponse(
            success = true,
            data = Unit,
            error = null
        )

        // When
        val result = repository.removeFriend("friendship-1")

        // Then
        assertThat(result.isSuccess).isTrue()
        repository.friends.test {
            assertThat(awaitItem()).isEmpty()
        }
    }

    @Test
    fun `getFriendPermissions success returns permissions`() = runTest {
        // Given
        val permissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = false,
            receiveNotifications = true,
            canComment = false
        )
        coEvery { apiService.getFriendPermissions("friend-1") } returns APIResponse(
            success = true,
            data = permissions,
            error = null
        )

        // When
        val result = repository.getFriendPermissions("friend-1")

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(permissions)
    }

    @Test
    fun `updateFriendPermissions success returns updated permissions`() = runTest {
        // Given
        val permissionUpdate = FriendPermissionUpdate(
            canSeeButtons = true,
            canSeeActivity = true,
            receiveNotifications = false,
            canComment = false
        )
        val updatedPermissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = true,
            receiveNotifications = false,
            canComment = false
        )
        coEvery { apiService.updateFriendPermissions("friend-1", any()) } returns APIResponse(
            success = true,
            data = updatedPermissions,
            error = null
        )

        // When
        val result = repository.updateFriendPermissions("friend-1", permissionUpdate)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.receiveNotifications).isFalse()
    }

    @Test
    fun `getFriendButtons success returns buttons`() = runTest {
        // Given
        val buttons = listOf(testFriendButton)
        coEvery { apiService.getFriendButtons("friend-1") } returns APIResponse(
            success = true,
            data = buttons,
            error = null
        )

        // When
        val result = repository.getFriendButtons("friend-1")

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(buttons)
    }

    @Test
    fun `getFriendButtons failure returns error`() = runTest {
        // Given
        coEvery { apiService.getFriendButtons("friend-1") } returns APIResponse(
            success = false,
            data = emptyList(),
            error = com.buttonlog.app.data.api.APIError(
                code = "NOT_FRIENDS",
                message = "Not friends"
            )
        )

        // When
        val result = repository.getFriendButtons("friend-1")

        // Then
        assertThat(result.isFailure).isTrue()
    }

    @Test
    fun `getFriendActivity success returns activity page`() = runTest {
        // Given
        val activities = listOf(testFriendActivity)
        coEvery { apiService.getFriendActivity("friend-1", 20, null, null) } returns FriendActivityResponse(
            success = true,
            data = activities,
            error = null,
            meta = PaginationMeta(hasMore = false, nextCursor = null)
        )

        // When
        val result = repository.getFriendActivity("friend-1")

        // Then
        assertThat(result.isSuccess).isTrue()
        val page = result.getOrNull()!!
        assertThat(page.activities).isEqualTo(activities)
        assertThat(page.hasMore).isFalse()
    }

    @Test
    fun `getFriendActivity with pagination cursor`() = runTest {
        // Given
        val cursor = ActivityCursor(id = "activity-1", clickedAt = "2024-01-01T11:00:00Z")
        val activities = listOf(testFriendActivity)
        coEvery { apiService.getFriendActivity("friend-1", 20, cursor.clickedAt, cursor.id) } returns FriendActivityResponse(
            success = true,
            data = activities,
            error = null,
            meta = PaginationMeta(hasMore = true, nextCursor = ActivityCursor("activity-2", "2024-01-01T10:00:00Z"))
        )

        // When
        val result = repository.getFriendActivity("friend-1", cursor = cursor)

        // Then
        assertThat(result.isSuccess).isTrue()
        val page = result.getOrNull()!!
        assertThat(page.hasMore).isTrue()
        assertThat(page.nextCursor?.id).isEqualTo("activity-2")
    }

    @Test
    fun `getFriendActivity permission denied returns PermissionDeniedException`() = runTest {
        // Given
        coEvery { apiService.getFriendActivity("friend-1", 20, null, null) } returns FriendActivityResponse(
            success = false,
            data = emptyList(),
            error = com.buttonlog.app.data.api.APIError(
                code = "PERMISSION_DENIED",
                message = "Permission denied to view activity"
            ),
            meta = null
        )

        // When
        val result = repository.getFriendActivity("friend-1")

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(PermissionDeniedException::class.java)
    }

    @Test
    fun `getFriend returns friend from list`() = runTest {
        // Given
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend),
            error = null
        )
        repository.fetchFriends()

        // When
        val friend = repository.getFriend("user-1")

        // Then
        assertThat(friend).isEqualTo(testFriend)
    }

    @Test
    fun `getFriend returns null for non-existent friend`() = runTest {
        // Given
        coEvery { apiService.getFriends() } returns APIResponse(
            success = true,
            data = listOf(testFriend),
            error = null
        )
        repository.fetchFriends()

        // When
        val friend = repository.getFriend("non-existent-id")

        // Then
        assertThat(friend).isNull()
    }

    @Test
    fun `clearError resets error state`() = runTest {
        // Given - first cause an error
        coEvery { apiService.getFriends() } returns APIResponse(
            success = false,
            data = emptyList(),
            error = com.buttonlog.app.data.api.APIError(code = "ERROR", message = "Some error")
        )
        repository.fetchFriends()

        // Verify error is set
        repository.error.test {
            assertThat(awaitItem()).isNotNull()
        }

        // When
        repository.clearError()

        // Then
        repository.error.test {
            assertThat(awaitItem()).isNull()
        }
    }
}
