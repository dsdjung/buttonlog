package com.buttonlog.app.data.api

import com.buttonlog.app.data.model.*
import com.google.gson.annotations.SerializedName
import retrofit2.http.*

interface APIService {

    // MARK: - App Configuration

    @GET("config")
    suspend fun getConfig(): AppConfig

    // MARK: - Authentication Endpoints

    @POST("auth/login")
    suspend fun login(@Body credentials: LoginCredentials): AuthResponse

    @POST("auth/register")
    suspend fun register(@Body data: RegistrationData): AuthResponse

    @POST("auth/oauth/callback")
    suspend fun oauthCallback(@Body data: OAuthCallbackRequest): AuthResponse

    @POST("auth/refresh")
    suspend fun refreshToken(): TokenRefreshResponse

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
    suspend fun clickButton(@Path("id") id: String, @Body request: ClickButtonRequest? = null): ButtonClickResponse

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

    @GET("buttons/created-gifts")
    suspend fun getCreatedGiftButtons(): CreatedGiftButtonsResponse

    // Button alert preferences
    @GET("buttons/{id}/alerts")
    suspend fun getButtonAlertPreferences(@Path("id") buttonId: String): ApiResponse<List<ButtonAlertPreference>>

    @POST("buttons/{id}/alerts/{friendId}/toggle")
    suspend fun toggleButtonAlertPreference(
        @Path("id") buttonId: String,
        @Path("friendId") friendId: String
    ): ApiResponse<ButtonAlertPreferenceResponse>

    @PUT("buttons/{id}/alerts/{friendId}")
    suspend fun setButtonAlertPreference(
        @Path("id") buttonId: String,
        @Path("friendId") friendId: String,
        @Body request: SetAlertPreferenceRequest
    ): ApiResponse<ButtonAlertPreferenceResponse>

    @POST("buttons/{id}/alerts/select-all")
    suspend fun selectAllButtonAlerts(@Path("id") buttonId: String): ApiResponse<SelectAllAlertsResponse>

    @POST("buttons/{id}/alerts/deselect-all")
    suspend fun deselectAllButtonAlerts(@Path("id") buttonId: String): ApiResponse<SelectAllAlertsResponse>

    // MARK: - Diary Endpoints

    @GET("diary")
    suspend fun getDiary(@Query("date") date: String? = null): DiaryResponse

    // MARK: - User Endpoints

    @GET("users/profile")
    suspend fun getUserProfile(): User

    @PUT("users/profile")
    suspend fun updateUserProfile(@Body update: UserProfileUpdate): User

    @POST("users/complete-onboarding")
    suspend fun completeOnboarding(): GenericResponse

    @GET("users/notification-preferences")
    suspend fun getNotificationPreferences(): NotificationPreferences

    @PUT("users/notification-preferences")
    suspend fun updateNotificationPreferences(@Body update: NotificationPreferencesUpdate): NotificationPreferences

    @PUT("users/password")
    suspend fun changePassword(@Body request: PasswordChangeRequest): PasswordChangeResponse

    @GET("users/export")
    @Streaming
    suspend fun exportData(@Query("format") format: String): retrofit2.Response<okhttp3.ResponseBody>

    // MARK: - Webhook Settings

    @GET("notifications/settings")
    suspend fun getWebhookSettings(): WebhookSettingsResponse

    @PUT("notifications/settings")
    suspend fun updateWebhookSettings(@Body update: WebhookSettingsUpdate): WebhookSettingsResponse

    @POST("notifications/test")
    suspend fun testWebhook(): WebhookTestResponse

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

    @POST("devices/test-notification")
    suspend fun sendTestNotification(@Body request: TestNotificationRequest? = null): TestNotificationResponse

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

    @POST("teams/{teamId}/leave")
    suspend fun leaveTeam(@Path("teamId") teamId: String): ApiResponse<Unit>

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

    @POST("organizations/{orgId}/leave")
    suspend fun leaveOrganization(@Path("orgId") orgId: String): ApiResponse<Unit>

    // MARK: - Subscription Endpoints

    @GET("subscriptions/plans")
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

data class OAuthCallbackRequest(
    val provider: String,
    @SerializedName("user_info")
    val userInfo: OAuthUserInfo
)

data class OAuthUserInfo(
    val email: String,
    val uid: String,
    val name: String? = null,
    @SerializedName("first_name")
    val firstName: String? = null,
    @SerializedName("last_name")
    val lastName: String? = null,
    val image: String? = null,
    @SerializedName("access_token")
    val accessToken: String? = null,
    @SerializedName("refresh_token")
    val refreshToken: String? = null,
    @SerializedName("expires_at")
    val expiresAt: Long? = null
)

data class FriendPermissionUpdateRequest(
    val permissions: FriendPermissionUpdate
)

data class GenericResponse(
    val success: Boolean,
    val data: Any?,
    val error: ApiError?
)

data class TokenRefreshResponse(
    val success: Boolean,
    val data: TokenData?,
    val error: ApiError?
)

data class TokenData(
    val token: String
)

// Button request wrappers (backend expects {"button": {...}})
data class CreateButtonRequest(
    val button: ButtonRequestData
) {
    companion object {
        fun from(formData: ButtonFormData): CreateButtonRequest {
            return CreateButtonRequest(ButtonRequestData.from(formData))
        }
    }
}

data class UpdateButtonRequest(
    val button: ButtonUpdateData
)

data class CreateGiftButtonRequest(
    @SerializedName("friend_id")
    val friendId: String,
    val button: ButtonRequestData,
    val message: String? = null
) {
    companion object {
        fun from(friendId: String, formData: ButtonFormData, message: String? = null): CreateGiftButtonRequest {
            return CreateGiftButtonRequest(
                friendId = friendId,
                button = ButtonRequestData.from(formData),
                message = message
            )
        }
    }
}

/**
 * Properly serialized button data for API requests.
 * Handles filtering of choices and proper snake_case field names.
 */
data class ButtonRequestData(
    val name: String,
    val description: String?,
    val type: String,  // Already in API format: "instant", "toggle", "one-time", "workflow"
    val icon: String,
    val color: String,
    @SerializedName("alerts_enabled")
    val alertsEnabled: Boolean,
    @SerializedName("auto_stop_enabled")
    val autoStopEnabled: Boolean,
    @SerializedName("auto_stop_minutes")
    val autoStopMinutes: Int?,
    @SerializedName("calendar_sync_enabled")
    val calendarSyncEnabled: Boolean,
    val choices: List<String>?  // Only included if valid (2+ non-empty choices for one-time buttons)
) {
    companion object {
        fun from(formData: ButtonFormData): ButtonRequestData {
            // Convert ButtonType to API string format
            val typeString = when (formData.type) {
                ButtonType.INSTANT -> "instant"
                ButtonType.TOGGLE -> "toggle"
                ButtonType.ONE_TIME -> "one-time"
                ButtonType.WORKFLOW -> "workflow"
            }

            // Filter and trim choices, only include for one-time buttons with 2+ valid choices
            val validChoices = if (formData.type == ButtonType.ONE_TIME) {
                formData.choices.map { it.trim() }.filter { it.isNotEmpty() }.takeIf { it.size >= 2 }
            } else {
                null
            }

            return ButtonRequestData(
                name = formData.name.trim(),
                description = formData.description.ifEmpty { null },
                type = typeString,
                icon = formData.icon,
                color = formData.color,
                alertsEnabled = formData.alertsEnabled,
                autoStopEnabled = formData.autoStopEnabled,
                autoStopMinutes = if (formData.autoStopEnabled) formData.autoStopMinutes else null,
                calendarSyncEnabled = formData.calendarSyncEnabled,
                choices = validChoices
            )
        }
    }
}

data class ClickButtonRequest(
    val choice: String? = null
)

data class ButtonUpdateData(
    val name: String?,
    val description: String?,
    val icon: String?,
    val color: String?,
    val choices: List<String>?,
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

data class TestNotificationRequest(
    val title: String? = null,
    val body: String? = null
)

data class TestNotificationData(
    val message: String,
    val successes: Int,
    val failures: Int,
    @SerializedName("total_devices")
    val totalDevices: Int
)

data class TestNotificationResponse(
    val success: Boolean,
    val data: TestNotificationData?,
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
    data class UpgradeRequired(override val message: String, val upgradeInfo: UpgradeInfo) : ApiException(message)
}

// MARK: - Upgrade Info Model

data class UpgradeInfo(
    val reason: String,
    @SerializedName("current_plan")
    val currentPlan: String,
    @SerializedName("current_usage")
    val currentUsage: Int?,
    val limit: Int?,
    @SerializedName("recommended_plan")
    val recommendedPlan: String,
    @SerializedName("upgrade_benefit")
    val upgradeBenefit: String,
    val message: String
)

data class ApiErrorWithUpgrade(
    val code: String,
    val message: String,
    @SerializedName("upgrade_info")
    val upgradeInfo: UpgradeInfo?
)

// MARK: - Button Alert Preferences Models

data class ButtonAlertPreference(
    @SerializedName("friend_id")
    val friendId: String,
    @SerializedName("friend_username")
    val friendUsername: String,
    @SerializedName("friend_display_name")
    val friendDisplayName: String?,
    val enabled: Boolean,
    @SerializedName("alert_type")
    val alertType: String
) {
    val displayName: String
        get() = friendDisplayName ?: friendUsername
}

data class ButtonAlertPreferenceResponse(
    @SerializedName("friend_id")
    val friendId: String,
    val enabled: Boolean,
    @SerializedName("alert_type")
    val alertType: String
)

data class SetAlertPreferenceRequest(
    val enabled: Boolean,
    @SerializedName("alert_type")
    val alertType: String = "click"
)

data class SelectAllAlertsResponse(
    val message: String,
    val count: Int
)

// MARK: - Diary Models

data class DiaryResponse(
    val success: Boolean,
    val data: DiaryData?,
    val error: ApiError?
)

data class DiaryData(
    val date: String,
    val summary: DiarySummary,
    val activities: List<DiaryActivity>
)

data class DiarySummary(
    val date: String,
    @SerializedName("total_buttons_used")
    val totalButtonsUsed: Int,
    @SerializedName("total_clicks")
    val totalClicks: Int,
    @SerializedName("button_types_used")
    val buttonTypesUsed: List<String>,
    @SerializedName("in_progress_count")
    val inProgressCount: Int,
    @SerializedName("is_today")
    val isToday: Boolean,
    @SerializedName("is_empty")
    val isEmpty: Boolean
)

data class DiaryActivity(
    val button: DiaryButtonInfo,
    @SerializedName("total_clicks")
    val totalClicks: Int,
    @SerializedName("first_click_at")
    val firstClickAt: String?,
    @SerializedName("last_click_at")
    val lastClickAt: String?,
    val clicks: List<DiaryClick>
)

data class DiaryButtonInfo(
    val id: String,
    val name: String,
    val type: String,
    val icon: String,
    val color: String,
    @SerializedName("current_state")
    val currentState: String?
)

data class DiaryClick(
    val id: String,
    @SerializedName("clicked_at")
    val clickedAt: String,
    val action: String?,
    @SerializedName("selected_choice")
    val selectedChoice: String?
)

// MARK: - App Configuration Model

/**
 * App configuration from the server.
 * Used for version requirements, feature flags, and maintenance status.
 */
data class AppConfig(
    @SerializedName("min_supported_version")
    val minSupportedVersion: VersionInfo,
    @SerializedName("latest_version")
    val latestVersion: VersionInfo,
    val features: FeatureFlags,
    @SerializedName("maintenance_mode")
    val maintenanceMode: Boolean,
    @SerializedName("maintenance_message")
    val maintenanceMessage: String?,
    @SerializedName("api_version")
    val apiVersion: String,
    @SerializedName("server_time")
    val serverTime: String
) {
    /**
     * Check if the current app version is supported.
     */
    fun isCurrentVersionSupported(currentVersion: String): Boolean {
        return compareVersions(currentVersion, minSupportedVersion.android) >= 0
    }

    /**
     * Check if an update is available.
     */
    fun isUpdateAvailable(currentVersion: String): Boolean {
        return compareVersions(latestVersion.android, currentVersion) > 0
    }

    /**
     * Compare two semantic version strings.
     * Returns: negative if v1 < v2, 0 if equal, positive if v1 > v2
     */
    private fun compareVersions(v1: String, v2: String): Int {
        val parts1 = v1.split(".").mapNotNull { it.toIntOrNull() }
        val parts2 = v2.split(".").mapNotNull { it.toIntOrNull() }

        val maxLength = maxOf(parts1.size, parts2.size)

        for (i in 0 until maxLength) {
            val p1 = parts1.getOrElse(i) { 0 }
            val p2 = parts2.getOrElse(i) { 0 }

            if (p1 != p2) {
                return p1 - p2
            }
        }

        return 0
    }
}

data class VersionInfo(
    val ios: String,
    val android: String
)

data class FeatureFlags(
    @SerializedName("push_notifications")
    val pushNotifications: Boolean,
    @SerializedName("friend_alerts")
    val friendAlerts: Boolean,
    val subscriptions: Boolean,
    val teams: Boolean,
    val organizations: Boolean,
    @SerializedName("diary_view")
    val diaryView: Boolean,
    @SerializedName("button_sharing")
    val buttonSharing: Boolean,
    @SerializedName("gift_buttons")
    val giftButtons: Boolean
)

// MARK: - API Configuration

object ApiConfig {
    const val BASE_URL = "http://10.0.2.2:14015/api/" // Android emulator localhost (port 14015)
    const val TIMEOUT_SECONDS = 30L

    // Headers
    const val HEADER_AUTHORIZATION = "Authorization"
    const val HEADER_CONTENT_TYPE = "Content-Type"
    const val HEADER_ACCEPT = "Accept"

    // Client version tracking headers
    const val HEADER_APP_VERSION = "X-App-Version"
    const val HEADER_PLATFORM = "X-Platform"
    const val HEADER_DEVICE_ID = "X-Device-Id"

    // Content types
    const val CONTENT_TYPE_JSON = "application/json"
    const val CONTENT_TYPE_FORM = "application/x-www-form-urlencoded"
}

