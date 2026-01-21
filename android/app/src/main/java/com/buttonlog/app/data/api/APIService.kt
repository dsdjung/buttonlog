package com.buttonlog.app.data.api

import com.buttonlog.app.data.model.*
import com.google.gson.annotations.SerializedName
import retrofit2.http.*

interface APIService {
    
    // MARK: - Authentication Endpoints
    
    @POST("auth/login")
    suspend fun login(@Body credentials: LoginCredentials): AuthResponse

    @POST("auth/register")
    suspend fun register(@Body data: RegistrationData): AuthResponse
    
    @DELETE("auth/logout")
    suspend fun logout()
    
    // MARK: - Button Endpoints

    @GET("buttons")
    suspend fun getButtons(): ButtonsResponse

    @POST("buttons")
    suspend fun createButton(@Body button: CreateButtonRequest): ButtonResponse

    @PUT("buttons/{id}")
    suspend fun updateButton(@Path("id") id: String, @Body button: UpdateButtonRequest): ButtonResponse

    @DELETE("buttons/{id}")
    suspend fun deleteButton(@Path("id") id: String)

    @POST("buttons/{id}/click")
    suspend fun clickButton(@Path("id") id: String): ButtonClickResponse

    @GET("buttons/{id}/history")
    suspend fun getButtonHistory(@Path("id") id: String, @Query("limit") limit: Int = 50): ButtonHistoryResponse

    // MARK: - User Endpoints
    
    @GET("users/profile")
    suspend fun getUserProfile(): User
    
    @PUT("users/profile")
    suspend fun updateUserProfile(@Body user: User): User
    
    // MARK: - Social Endpoints

    @GET("friends")
    suspend fun getFriends(): FriendsResponse

    @POST("friends/request")
    suspend fun sendFriendRequest(@Body request: FriendRequestBody): GenericResponse

    @PUT("friends/{id}/accept")
    suspend fun acceptFriendRequest(@Path("id") id: String): GenericResponse

    @DELETE("friends/{id}")
    suspend fun removeFriend(@Path("id") id: String): GenericResponse

    @GET("friends/{friendId}/permissions")
    suspend fun getFriendPermissions(@Path("friendId") friendId: String): FriendPermissionsResponse

    @PUT("friends/{friendId}/permissions")
    suspend fun updateFriendPermissions(
        @Path("friendId") friendId: String,
        @Body permissions: FriendPermissionUpdateRequest
    ): FriendPermissionsResponse

    @GET("friends/{friendId}/buttons")
    suspend fun getFriendButtons(@Path("friendId") friendId: String): FriendButtonsResponse

    @GET("friends/{friendId}/activity")
    suspend fun getFriendActivity(
        @Path("friendId") friendId: String,
        @Query("limit") limit: Int = 20,
        @Query("cursor") cursor: String? = null,
        @Query("cursor_id") cursorId: String? = null
    ): FriendActivityResponse

    // MARK: - Notification Endpoints
    
    @GET("notifications")
    suspend fun getNotifications(): List<Notification>
    
    @PUT("notifications/{id}/read")
    suspend fun markNotificationAsRead(@Path("id") id: String): Unit
}

// MARK: - Request/Response Models

data class LoginCredentials(
    val email: String,
    val password: String
)

data class RegistrationData(
    @SerializedName("display_name")
    val displayName: String,
    val email: String,
    val username: String,
    val password: String,
    @SerializedName("password_confirmation")
    val passwordConfirmation: String
)

data class FriendRequestBody(
    val email: String? = null,
    val username: String? = null,
    @SerializedName("friend_id")
    val friendId: String? = null,
    val message: String? = null
)

data class FriendPermissionUpdateRequest(
    val permissions: FriendPermissionUpdate
)

data class GenericResponse(
    val success: Boolean,
    val data: Any?,
    val error: ApiError?
)

// Button request wrappers (backend expects {"button": {...}})
data class CreateButtonRequest(
    val button: ButtonFormData
)

data class UpdateButtonRequest(
    val button: ButtonUpdateData
)

data class ButtonUpdateData(
    val name: String?,
    val description: String?,
    val icon: String?,
    val color: String?,
    @SerializedName("notifications_enabled")
    val notificationsEnabled: Boolean?,
    @SerializedName("auto_stop_enabled")
    val autoStopEnabled: Boolean?,
    @SerializedName("calendar_sync_enabled")
    val calendarSyncEnabled: Boolean?
)

data class Notification(
    val id: String,
    val title: String,
    val body: String,
    val type: String,
    @SerializedName("is_read")
    val isRead: Boolean,
    val data: Map<String, Any>?,
    @SerializedName("created_at")
    val createdAt: java.util.Date
)

// MARK: - API Response Wrapper

sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: Int? = null) : ApiResult<Nothing>()
    object Loading : ApiResult<Nothing>()
}

// MARK: - API Error Handling

sealed class ApiException(message: String) : Exception(message) {
    data class Unauthorized(override val message: String = "Unauthorized access") : ApiException(message)
    data class ServerError(override val message: String, val code: Int) : ApiException(message)
    data class NetworkError(override val message: String) : ApiException(message)
    data class DecodingError(override val message: String) : ApiException(message)
}

// MARK: - API Configuration

object ApiConfig {
    const val BASE_URL = "http://10.0.2.2:14015/api/" // Android emulator localhost (port 14015)
    const val TIMEOUT_SECONDS = 30L
    
    // Headers
    const val HEADER_AUTHORIZATION = "Authorization"
    const val HEADER_CONTENT_TYPE = "Content-Type"
    const val HEADER_ACCEPT = "Accept"
    
    // Content types
    const val CONTENT_TYPE_JSON = "application/json"
    const val CONTENT_TYPE_FORM = "application/x-www-form-urlencoded"
}

