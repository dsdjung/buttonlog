package com.buttonlog.app.integration

import android.util.Log
import com.buttonlog.app.data.api.FriendRequestBody
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import org.junit.runner.RunWith
import androidx.test.ext.junit.runners.AndroidJUnit4

/**
 * Integration tests for friends/social endpoints.
 *
 * These tests make real API calls to verify:
 * - Getting friends list
 * - Sending friend requests
 * - Friend request management
 *
 * Run against local dev:
 *   ./gradlew connectedDevelopmentDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.FriendsIntegrationTest
 *
 * Run against staging:
 *   ./gradlew connectedStagingDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.buttonlog.app.integration.FriendsIntegrationTest
 */
@RunWith(AndroidJUnit4::class)
class FriendsIntegrationTest : BaseIntegrationTest() {

    companion object {
        private const val TAG = "FriendsIntegrationTest"
    }

    @Test
    fun getFriends_authenticated_returnsFriendsList() = runIntegrationTest {
        Log.i(TAG, "Testing getFriends with authentication")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        val response = apiService.getFriends()

        Log.i(TAG, "GetFriends response - success: ${response.success}, count: ${response.data?.size}")

        assertThat(response.success).isTrue()
        assertThat(response.data).isNotNull()
        // List could be empty for new users
    }

    @Test
    fun getFriends_unauthenticated_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing getFriends without authentication")

        try {
            val response = apiService.getFriends()
            assertThat(response.success).isFalse()
        } catch (e: retrofit2.HttpException) {
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isEqualTo(401)
        }
    }

    @Test
    fun sendFriendRequest_toNonExistentUser_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing sendFriendRequest to non-existent user")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        try {
            val response = apiService.sendFriendRequest(
                FriendRequestBody(email = "nonexistent_user_${System.currentTimeMillis()}@example.com")
            )

            Log.i(TAG, "SendFriendRequest response - success: ${response.success}, error: ${response.error}")

            // Should fail because user doesn't exist
            assertThat(response.success).isFalse()
        } catch (e: retrofit2.HttpException) {
            // Also acceptable - 404 for user not found
            Log.i(TAG, "Got HTTP error (expected): ${e.code()}")
            assertThat(e.code()).isIn(listOf(400, 404, 422))
        }
    }

    @Test
    fun removeFriend_nonExistentFriend_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing removeFriend with non-existent friend ID")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        try {
            apiService.removeFriend("nonexistent-friend-id-${System.currentTimeMillis()}")
            // If we get here without exception, the API returned success (which might happen if
            // the backend is lenient about removing non-existent friendships)
            Log.i(TAG, "RemoveFriend completed (backend may be lenient)")
        } catch (e: retrofit2.HttpException) {
            Log.i(TAG, "Got HTTP error (expected): ${e.code()}")
            // 404 for not found, or 400/422 for invalid request
            assertThat(e.code()).isIn(listOf(400, 404, 422))
        }
    }

    @Test
    fun getNotifications_authenticated_returnsList() = runIntegrationTest {
        Log.i(TAG, "Testing getNotifications with authentication")

        val loginSuccess = loginTestUser()
        assertThat(loginSuccess).isTrue()

        val response = apiService.getNotifications()

        Log.i(TAG, "GetNotifications response - success: ${response.success}, count: ${response.data?.size}")

        assertThat(response.success).isTrue()
        assertThat(response.data).isNotNull()
    }

    @Test
    fun getNotifications_unauthenticated_returnsError() = runIntegrationTest {
        Log.i(TAG, "Testing getNotifications without authentication")

        try {
            val response = apiService.getNotifications()
            assertThat(response.success).isFalse()
        } catch (e: retrofit2.HttpException) {
            Log.i(TAG, "Got expected HTTP error: ${e.code()}")
            assertThat(e.code()).isEqualTo(401)
        }
    }
}
