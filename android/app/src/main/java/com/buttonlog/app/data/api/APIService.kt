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

    @GET("buttons/{id}/sharing")
    suspend fun getButtonSharing(@Path("id") id: String): ButtonSharingResponse

    @PUT("buttons/{id}/sharing")
    suspend fun updateButtonSharing(@Path("id") id: String, @Body request: ButtonSharingUpdateRequest): ButtonSharingResponse

    // Sharing mode management
    @PUT("buttons/{id}/sharing-mode")
    suspend fun updateSharingMode(@Path("id") id: String, @Body request: SharingModeUpdateRequest): ButtonResponse

    @POST("buttons/{id}/share-link")
    suspend fun generateShareLink(@Path("id") id: String): ShareLinkApiResponse

    @DELETE("buttons/{id}/share-link")
    suspend fun revokeShareLink(@Path("id") id: String): ButtonResponse

    // Collaborator management
    @GET("buttons/{id}/collaborators")
    suspend fun getCollaborators(@Path("id") id: String): CollaboratorsResponse

    @POST("buttons/{id}/collaborators")
    suspend fun addCollaborator(@Path("id") id: String, @Body request: AddCollaboratorRequest): CollaboratorResponse

    @DELETE("buttons/{id}/collaborators/{userId}")
    suspend fun removeCollaborator(@Path("id") buttonId: String, @Path("userId") userId: String): GenericResponse

    // Join via share token
    @POST("buttons/join/{token}")
    suspend fun joinByShareToken(@Path("token") token: String): ButtonResponse

    @POST("buttons/gift")
    suspend fun createButtonForFriend(@Body request: CreateGiftButtonRequest): ButtonResponse

    // MARK: - User Endpoints

    @GET("users/profile")
    suspend fun getUserProfile(): User

    @PUT("users/profile")
    suspend fun updateUserProfile(@Body user: User): User

    @POST("users/complete-onboarding")
    suspend fun completeOnboarding(): GenericResponse

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
    suspend fun getNotifications(): NotificationsResponse

    @PUT("notifications/{id}/read")
    suspend fun markNotificationAsRead(@Path("id") id: String): GenericResponse

    @DELETE("notifications/{id}")
    suspend fun deleteNotification(@Path("id") id: String): GenericResponse

    // MARK: - Device Registration (Push Notifications)

    @POST("devices/register")
    suspend fun registerDevice(@Body request: DeviceRegistrationRequest): DeviceRegistrationResponse

    @HTTP(method = "DELETE", path = "devices/unregister", hasBody = true)
    suspend fun unregisterDevice(@Body request: DeviceUnregisterRequest): GenericResponse

    @GET("devices")
    suspend fun getDevices(): DevicesResponse

    // MARK: - Support Ticket Endpoints

    @GET("support/tickets")
    suspend fun getSupportTickets(): SupportTicketsResponse

    @GET("support/tickets/{id}")
    suspend fun getSupportTicket(@Path("id") id: String): SupportTicketResponse

    @POST("support/tickets")
    suspend fun createSupportTicket(@Body request: CreateTicketRequest): SupportTicketResponse

    @POST("support/tickets/{id}/messages")
    suspend fun sendTicketMessage(
        @Path("id") ticketId: String,
        @Body request: SendMessageRequest
    ): TicketMessageResponse

    // MARK: - Team Endpoints

    @GET("teams")
    suspend fun getTeams(): ApiResponse<TeamsResponse>

    @GET("teams/{id}")
    suspend fun getTeam(@Path("id") id: String): ApiResponse<Team>

    @POST("teams")
    suspend fun createTeam(@Body request: CreateTeamRequest): ApiResponse<Team>

    @PUT("teams/{id}")
    suspend fun updateTeam(@Path("id") id: String, @Body request: CreateTeamRequest): ApiResponse<Team>

    @DELETE("teams/{id}")
    suspend fun deleteTeam(@Path("id") id: String): ApiResponse<Unit>

    @POST("teams/{teamId}/invitations")
    suspend fun inviteTeamMember(@Path("teamId") teamId: String, @Body request: Map<String, String>): ApiResponse<Unit>

    @POST("teams/invitations/{id}/accept")
    suspend fun acceptTeamInvitation(@Path("id") id: String): ApiResponse<Team>

    @POST("teams/invitations/{id}/decline")
    suspend fun declineTeamInvitation(@Path("id") id: String): ApiResponse<Unit>

    // MARK: - Organization Endpoints

    @GET("organizations")
    suspend fun getOrganizations(): ApiResponse<OrganizationsResponse>

    @GET("organizations/{id}")
    suspend fun getOrganization(@Path("id") id: String): ApiResponse<Organization>

    @POST("organizations")
    suspend fun createOrganization(@Body request: CreateOrganizationRequest): ApiResponse<Organization>

    @PUT("organizations/{id}")
    suspend fun updateOrganization(@Path("id") id: String, @Body request: CreateOrganizationRequest): ApiResponse<Organization>

    @DELETE("organizations/{id}")
    suspend fun deleteOrganization(@Path("id") id: String): ApiResponse<Unit>

    @POST("organizations/{orgId}/invitations")
    suspend fun inviteOrganizationMember(@Path("orgId") orgId: String, @Body request: Map<String, String>): ApiResponse<Unit>

    @POST("organizations/invitations/{id}/accept")
    suspend fun acceptOrganizationInvitation(@Path("id") id: String): ApiResponse<Organization>

    @POST("organizations/invitations/{id}/decline")
    suspend fun declineOrganizationInvitation(@Path("id") id: String): ApiResponse<Unit>

    // MARK: - Subscription Endpoints

    @GET("subscriptions")
    suspend fun getSubscriptionPlans(): SubscriptionPlansResponse

    @GET("subscriptions/current")
    suspend fun getCurrentSubscription(): UserSubscriptionResponse

    @POST("subscriptions")
    suspend fun createSubscription(@Body request: CreateSubscriptionRequest): UserSubscriptionResponse

    @DELETE("subscriptions")
    suspend fun cancelSubscription(): GenericResponse

    @POST("subscriptions/pause")
    suspend fun pauseSubscription(): GenericResponse

    @POST("subscriptions/resume")
    suspend fun resumeSubscription(): GenericResponse

    @GET("subscriptions/stats")
    suspend fun getSubscriptionStats(): SubscriptionStatsResponse

    @POST("subscriptions/check-permission")
    suspend fun checkPermission(@Body request: PermissionCheckRequest): PermissionCheckResponse

    // MARK: - Stripe Payment Integration

    @POST("subscriptions/checkout")
    suspend fun createCheckoutSession(@Body request: CreateCheckoutSessionRequest): CheckoutSessionResponse

    @POST("subscriptions/portal")
    suspend fun createPortalSession(): PortalSessionResponse

    @POST("subscriptions/setup-intent")
    suspend fun createSetupIntent(): SetupIntentResponse

    // MARK: - Payment Method Endpoints

    @GET("payment-methods")
    suspend fun getPaymentMethods(): PaymentMethodsResponse

    @POST("payment-methods")
    suspend fun addPaymentMethod(@Body request: AddPaymentMethodRequest): PaymentMethodResponse

    @DELETE("payment-methods/{id}")
    suspend fun removePaymentMethod(@Path("id") id: String): GenericResponse

    @PUT("payment-methods/{id}/default")
    suspend fun setDefaultPaymentMethod(@Path("id") id: String): GenericResponse

    // MARK: - Invoice Endpoints

    @GET("invoices")
    suspend fun getInvoices(): InvoicesResponse

    @GET("invoices/{id}")
    suspend fun getInvoice(@Path("id") id: String): InvoiceResponse

    // MARK: - Coupon Endpoints

    @POST("coupons/apply")
    suspend fun applyCoupon(@Body request: ApplyCouponRequest): ApplyCouponApiResponse
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

data class CreateGiftButtonRequest(
    @SerializedName("friend_id")
    val friendId: String,
    val button: ButtonFormData,
    val message: String? = null
)

data class ButtonUpdateData(
    val name: String?,
    val description: String?,
    val icon: String?,
    val color: String?,
    @SerializedName("alerts_enabled")
    val alertsEnabled: Boolean?,
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
    val sender: NotificationSender?,
    @SerializedName("inserted_at")
    val insertedAt: String
)

data class NotificationSender(
    val id: String,
    val username: String,
    @SerializedName("display_name")
    val displayName: String?
)

data class NotificationsResponse(
    val success: Boolean,
    val data: List<Notification>
)

// MARK: - Device Registration Models

data class DeviceRegistrationRequest(
    @SerializedName("device_token")
    val deviceToken: String,
    val platform: String = "android",
    @SerializedName("app_version")
    val appVersion: String,
    @SerializedName("os_version")
    val osVersion: String
)

data class DeviceUnregisterRequest(
    @SerializedName("device_token")
    val deviceToken: String
)

data class DeviceRegistration(
    val id: String,
    @SerializedName("device_token")
    val deviceToken: String,
    val platform: String,
    @SerializedName("is_active")
    val isActive: Boolean
)

data class DeviceRegistrationResponse(
    val success: Boolean,
    val data: DeviceRegistration?,
    val error: ApiError?
)

data class DevicesResponse(
    val success: Boolean,
    val data: List<DeviceRegistration>,
    val error: ApiError?
)

// MARK: - API Response Wrapper

data class ApiResponse<T>(
    val success: Boolean,
    val data: T,
    val error: ApiError? = null
)

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

