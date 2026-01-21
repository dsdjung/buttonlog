package com.buttonlog.app.data.api

import com.buttonlog.app.data.model.*
import com.google.gson.annotations.SerializedName
import retrofit2.http.*

interface APIService {
    
    // MARK: - Authentication Endpoints
    
    @POST("auth/login")
    suspend fun login(@Body credentials: LoginCredentials): AuthUser
    
    @POST("auth/register")
    suspend fun register(@Body data: RegistrationData): AuthUser
    
    @DELETE("auth/logout")
    suspend fun logout()
    
    // MARK: - Button Endpoints
    
    @GET("buttons")
    suspend fun getButtons(): List<Button>
    
    @POST("buttons")
    suspend fun createButton(@Body button: ButtonFormData): Button
    
    @PUT("buttons/{id}")
    suspend fun updateButton(@Path("id") id: String, @Body button: Button): Button
    
    @DELETE("buttons/{id}")
    suspend fun deleteButton(@Path("id") id: String)
    
    @POST("buttons/{id}/click")
    suspend fun clickButton(@Path("id") id: String): ButtonClick
    
    // MARK: - User Endpoints
    
    @GET("users/profile")
    suspend fun getUserProfile(): User
    
    @PUT("users/profile")
    suspend fun updateUserProfile(@Body user: User): User
    
    // MARK: - Social Endpoints
    
    @GET("friends")
    suspend fun getFriends(): List<User>
    
    @POST("friends/request")
    suspend fun sendFriendRequest(@Body request: FriendRequest): Unit
    
    @PUT("friends/{id}/accept")
    suspend fun acceptFriendRequest(@Path("id") id: String): Unit
    
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

data class FriendRequest(
    val username: String
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
    const val BASE_URL = "http://10.0.2.2:4000/api/" // Android emulator localhost
    const val TIMEOUT_SECONDS = 30L
    
    // Headers
    const val HEADER_AUTHORIZATION = "Authorization"
    const val HEADER_CONTENT_TYPE = "Content-Type"
    const val HEADER_ACCEPT = "Accept"
    
    // Content types
    const val CONTENT_TYPE_JSON = "application/json"
    const val CONTENT_TYPE_FORM = "application/x-www-form-urlencoded"
}

