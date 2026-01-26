package com.buttonlog.app.ui.viewmodels

import android.util.Log
import app.cash.turbine.test
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendButton
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.data.model.FriendshipStatus
import com.buttonlog.app.data.model.PublicUser
import com.buttonlog.app.data.repository.ActivityPage
import com.buttonlog.app.data.repository.FriendsRepository
import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.unmockkStatic
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class FriendsViewModelTest {

    private lateinit var friendsRepository: FriendsRepository
    private lateinit var viewModel: FriendsViewModel

    private val testDispatcher = StandardTestDispatcher()

    private val testPublicUser = PublicUser(
        id = "user-1",
        username = "testuser",
        displayName = "Test User",
        firstName = null,
        lastName = null,
        profileVisibility = "public"
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
        createdAt = "2024-01-01T00:00:00Z",
        updatedAt = "2024-01-01T00:00:00Z"
    )

    private val pendingFriend = Friend(
        id = "friendship-2",
        friendId = "user-2",
        friendUser = testPublicUser.copy(id = "user-2", username = "pendinguser"),
        status = FriendshipStatus.PENDING,
        permissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = true,
            receiveNotifications = true,
            canComment = false
        ),
        createdAt = "2024-01-01T00:00:00Z",
        updatedAt = "2024-01-01T00:00:00Z"
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)

        // Mock Android Log class for unit tests
        mockkStatic(Log::class)
        every { Log.d(any(), any()) } returns 0
        every { Log.e(any(), any()) } returns 0
        every { Log.e(any(), any(), any()) } returns 0
        every { Log.i(any(), any()) } returns 0
        every { Log.w(any(), any<String>()) } returns 0
        every { Log.v(any(), any()) } returns 0

        friendsRepository = mockk(relaxed = true)

        every { friendsRepository.friends } returns MutableStateFlow(emptyList())
        every { friendsRepository.isLoading } returns MutableStateFlow(false)
        every { friendsRepository.error } returns MutableStateFlow(null)

        viewModel = FriendsViewModel(friendsRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
        unmockkStatic(Log::class)
    }

    @Test
    fun `initial state has empty friends list`() = runTest {
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friends).isEmpty()
            assertThat(state.acceptedFriends).isEmpty()
            assertThat(state.pendingRequests).isEmpty()
            assertThat(state.error).isNull()
            assertThat(state.isLoading).isFalse()
        }
    }

    @Test
    fun `fetchFriends calls repository`() = runTest {
        viewModel.fetchFriends()
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { friendsRepository.fetchFriends() }
    }

    @Test
    fun `friends flow updates acceptedFriends and pendingRequests`() = runTest {
        // Given
        val friendsList = listOf(testFriend, pendingFriend)
        every { friendsRepository.friends } returns MutableStateFlow(friendsList)

        // Recreate viewModel to pick up new mock
        viewModel = FriendsViewModel(friendsRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friends).hasSize(2)
            assertThat(state.acceptedFriends).hasSize(1)
            assertThat(state.acceptedFriends.first().status).isEqualTo(FriendshipStatus.ACCEPTED)
            assertThat(state.pendingRequests).hasSize(1)
            assertThat(state.pendingRequests.first().status).isEqualTo(FriendshipStatus.PENDING)
        }
    }

    @Test
    fun `sendFriendRequest with email calls repository`() = runTest {
        // Given
        coEvery { friendsRepository.sendFriendRequest(email = "friend@example.com", username = null) } returns Result.success(Unit)

        // When
        viewModel.sendFriendRequest(email = "friend@example.com")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { friendsRepository.sendFriendRequest(email = "friend@example.com", username = null) }
    }

    @Test
    fun `sendFriendRequest with username calls repository`() = runTest {
        // Given
        coEvery { friendsRepository.sendFriendRequest(email = null, username = "frienduser") } returns Result.success(Unit)

        // When
        viewModel.sendFriendRequest(username = "frienduser")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { friendsRepository.sendFriendRequest(email = null, username = "frienduser") }
    }

    @Test
    fun `sendFriendRequest success sets friendRequestSent flag`() = runTest {
        // Given
        coEvery { friendsRepository.sendFriendRequest(any(), any()) } returns Result.success(Unit)

        // When
        viewModel.sendFriendRequest(email = "friend@example.com")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friendRequestSent).isTrue()
        }
    }

    @Test
    fun `acceptFriendRequest calls repository`() = runTest {
        // When
        viewModel.acceptFriendRequest("friendship-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { friendsRepository.acceptFriendRequest("friendship-id") }
    }

    @Test
    fun `removeFriend calls repository`() = runTest {
        // When
        viewModel.removeFriend("friendship-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { friendsRepository.removeFriend("friendship-id") }
    }

    @Test
    fun `loadFriendPermissions calls repository and updates state`() = runTest {
        // Given
        val permissions = FriendPermissions(
            canSeeButtons = true,
            canSeeActivity = false,
            receiveNotifications = true,
            canComment = false
        )
        coEvery { friendsRepository.getFriendPermissions("friend-id") } returns Result.success(permissions)

        // When
        viewModel.loadFriendPermissions("friend-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.selectedFriendPermissions).isEqualTo(permissions)
            assertThat(state.isLoadingPermissions).isFalse()
        }
    }

    @Test
    fun `loadFriendPermissions failure sets error`() = runTest {
        // Given
        coEvery { friendsRepository.getFriendPermissions("friend-id") } returns Result.failure(
            Exception("Failed to load permissions")
        )

        // When
        viewModel.loadFriendPermissions("friend-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.error).isEqualTo("Failed to load permissions")
            assertThat(state.isLoadingPermissions).isFalse()
        }
    }

    @Test
    fun `updateFriendPermissions calls repository and updates state`() = runTest {
        // Given
        val update = FriendPermissionUpdate(
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
        coEvery { friendsRepository.updateFriendPermissions("friend-id", update) } returns Result.success(updatedPermissions)

        // When
        viewModel.updateFriendPermissions("friend-id", update)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.selectedFriendPermissions).isEqualTo(updatedPermissions)
        }
    }

    @Test
    fun `loadFriendButtons calls repository and updates state`() = runTest {
        // Given
        val buttons = listOf(
            FriendButton(
                id = "button-1",
                name = "Friend's Button",
                description = null,
                type = ButtonType.INSTANT,
                icon = "star",
                color = "#FF0000",
                isActive = true,
                currentState = ButtonState.IDLE,
                stateChangedAt = null,
                alertsEnabled = true,
                autoStopEnabled = false,
                calendarSyncEnabled = false,
                userId = "user-1",
                createdAt = "2024-01-01T00:00:00Z",
                updatedAt = "2024-01-01T00:00:00Z",
                latestClickAt = null,
                latestClickAction = null,
                latestClickLocation = null,
                latestClickDevice = null,
                latestClickPlatform = null
            )
        )
        coEvery { friendsRepository.getFriendButtons("friend-id") } returns Result.success(buttons)

        // When
        viewModel.loadFriendButtons("friend-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friendButtons).hasSize(1)
            assertThat(state.friendButtons.first().name).isEqualTo("Friend's Button")
            assertThat(state.isLoadingFriendButtons).isFalse()
        }
    }

    @Test
    fun `selectFriend updates state and loads friend data`() = runTest {
        // Given
        coEvery { friendsRepository.getFriendPermissions(any()) } returns Result.success(
            FriendPermissions(true, true, true, false)
        )
        coEvery { friendsRepository.getFriendButtons(any()) } returns Result.success(emptyList())
        coEvery { friendsRepository.getFriendActivity(any(), any(), any()) } returns Result.success(
            ActivityPage(emptyList(), false, null)
        )

        // When
        viewModel.selectFriend(testFriend)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.selectedFriend).isEqualTo(testFriend)
        }

        // Verify data loading was triggered
        coVerify { friendsRepository.getFriendPermissions(testFriend.friendId) }
        coVerify { friendsRepository.getFriendButtons(testFriend.friendId) }
        coVerify { friendsRepository.getFriendActivity(testFriend.friendId, any(), any()) }
    }

    @Test
    fun `selectFriend with null clears selected friend state`() = runTest {
        // When
        viewModel.selectFriend(null)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.selectedFriend).isNull()
            assertThat(state.friendButtons).isEmpty()
            assertThat(state.friendActivity).isEmpty()
            assertThat(state.selectedFriendPermissions).isNull()
        }
    }

    @Test
    fun `clearFriendRequestSent resets flag`() = runTest {
        // Given - send a request first
        coEvery { friendsRepository.sendFriendRequest(any(), any()) } returns Result.success(Unit)
        viewModel.sendFriendRequest(email = "friend@example.com")
        testDispatcher.scheduler.advanceUntilIdle()

        // Verify it's set
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friendRequestSent).isTrue()
        }

        // When
        viewModel.clearFriendRequestSent()

        // Then
        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.friendRequestSent).isFalse()
        }
    }

    @Test
    fun `clearError calls repository and resets local error`() = runTest {
        // When
        viewModel.clearError()

        // Then
        verify { friendsRepository.clearError() }

        viewModel.uiState.test {
            val state = awaitItem()
            assertThat(state.error).isNull()
        }
    }

    @Test
    fun `loadMoreActivity respects hasMore flag`() = runTest {
        // Given - no more activity available
        viewModel = FriendsViewModel(friendsRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // When - try to load more
        viewModel.loadMoreActivity("friend-id")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then - should not call repository since hasMore is false
        coVerify(exactly = 0) { friendsRepository.getFriendActivity(any(), any(), any()) }
    }
}
