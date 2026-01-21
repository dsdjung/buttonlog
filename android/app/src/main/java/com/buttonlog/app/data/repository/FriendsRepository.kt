package com.buttonlog.app.data.repository

import android.util.Log
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.FriendPermissionUpdateRequest
import com.buttonlog.app.data.api.FriendRequestBody
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendButton
import com.buttonlog.app.data.model.FriendActivity
import com.buttonlog.app.data.model.FriendActivityResponse
import com.buttonlog.app.data.model.ActivityCursor
import com.buttonlog.app.data.model.FriendPermissions
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.data.model.FriendshipStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "FriendsRepository"

@Singleton
class FriendsRepository @Inject constructor(
    private val apiService: APIService
) {

    private val _friends = MutableStateFlow<List<Friend>>(emptyList())
    val friends: StateFlow<List<Friend>> = _friends.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Derived state for accepted friends
    val acceptedFriends: List<Friend>
        get() = _friends.value.filter { it.status == FriendshipStatus.ACCEPTED }

    // Derived state for pending requests
    val pendingFriendRequests: List<Friend>
        get() = _friends.value.filter { it.status == FriendshipStatus.PENDING }

    suspend fun fetchFriends() {
        try {
            _isLoading.value = true
            _error.value = null

            Log.d(TAG, "Fetching friends...")
            val response = apiService.getFriends()
            Log.d(TAG, "Friends response - success: ${response.success}, data count: ${response.data.size}")
            if (response.success) {
                _friends.value = response.data
                Log.d(TAG, "Friends loaded: ${response.data.map { it.friendUser.displayNameOrUsername }}")
            } else {
                val errorMsg = response.error?.message ?: "Failed to fetch friends"
                Log.e(TAG, "Friends API error: $errorMsg")
                _error.value = errorMsg
            }

        } catch (e: Exception) {
            Log.e(TAG, "Exception fetching friends", e)
            _error.value = e.message ?: "Failed to fetch friends"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun sendFriendRequest(email: String? = null, username: String? = null): Result<Unit> {
        return try {
            _isLoading.value = true
            _error.value = null

            val request = FriendRequestBody(email = email, username = username)
            val response = apiService.sendFriendRequest(request)

            if (response.success) {
                Result.success(Unit)
            } else {
                val errorMessage = response.error?.message ?: "Failed to send friend request"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to send friend request"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun acceptFriendRequest(friendshipId: String): Result<Unit> {
        return try {
            _isLoading.value = true
            _error.value = null

            val response = apiService.acceptFriendRequest(friendshipId)

            if (response.success) {
                // Refetch friends to get updated list
                fetchFriends()
                Result.success(Unit)
            } else {
                val errorMessage = response.error?.message ?: "Failed to accept friend request"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to accept friend request"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun removeFriend(friendshipId: String): Result<Unit> {
        return try {
            _isLoading.value = true
            _error.value = null

            val response = apiService.removeFriend(friendshipId)

            if (response.success) {
                _friends.value = _friends.value.filter { it.id != friendshipId }
                Result.success(Unit)
            } else {
                val errorMessage = response.error?.message ?: "Failed to remove friend"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to remove friend"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun getFriendPermissions(friendId: String): Result<FriendPermissions> {
        return try {
            val response = apiService.getFriendPermissions(friendId)

            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to get permissions"
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateFriendPermissions(friendId: String, permissions: FriendPermissionUpdate): Result<FriendPermissions> {
        return try {
            _isLoading.value = true
            _error.value = null

            val request = FriendPermissionUpdateRequest(permissions)
            val response = apiService.updateFriendPermissions(friendId, request)

            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to update permissions"
                _error.value = errorMessage
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to update permissions"
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun getFriendButtons(friendId: String): Result<List<FriendButton>> {
        return try {
            val response = apiService.getFriendButtons(friendId)

            if (response.success) {
                Result.success(response.data)
            } else {
                val errorMessage = response.error?.message ?: "Failed to get friend's buttons"
                Result.failure(Exception(errorMessage))
            }

        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getFriendActivity(
        friendId: String,
        limit: Int = 20,
        cursor: ActivityCursor? = null
    ): Result<ActivityPage> {
        return try {
            Log.d(TAG, "getFriendActivity: friendId=$friendId, limit=$limit, cursor=$cursor")
            val response = apiService.getFriendActivity(
                friendId = friendId,
                limit = limit,
                cursor = cursor?.clickedAt,
                cursorId = cursor?.id
            )

            Log.d(TAG, "getFriendActivity response: success=${response.success}, data.size=${response.data.size}, meta=${response.meta}")

            if (response.success) {
                Result.success(
                    ActivityPage(
                        activities = response.data,
                        hasMore = response.meta?.hasMore ?: false,
                        nextCursor = response.meta?.nextCursor
                    )
                )
            } else {
                val errorMessage = response.error?.message ?: "Failed to get friend's activity"
                // Check if this is a permission denied error
                if (errorMessage.contains("permission", ignoreCase = true) ||
                    errorMessage.contains("PERMISSION_DENIED", ignoreCase = true)) {
                    Result.failure(PermissionDeniedException(errorMessage))
                } else {
                    Result.failure(Exception(errorMessage))
                }
            }

        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getFriend(friendId: String): Friend? {
        return _friends.value.find { it.friendId == friendId }
    }

    fun clearError() {
        _error.value = null
    }
}

class PermissionDeniedException(message: String) : Exception(message)

data class ActivityPage(
    val activities: List<FriendActivity>,
    val hasMore: Boolean,
    val nextCursor: ActivityCursor?
)
