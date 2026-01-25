package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName
import java.util.*

data class User(
    val id: String,
    val email: String,
    val username: String?,
    @SerializedName("display_name")
    val displayName: String?,
    @SerializedName("first_name")
    val firstName: String?,
    @SerializedName("last_name")
    val lastName: String?,
    @SerializedName("profile_visibility")
    val profileVisibility: String?,
    @SerializedName("activity_visibility")
    val activityVisibility: String?,
    @SerializedName("subscription_tier")
    val subscriptionTier: String?,
    @SerializedName("is_active")
    val isActive: Boolean?,
    @SerializedName("email_verified")
    val emailVerified: Boolean?,
    @SerializedName("onboarding_completed")
    val onboardingCompleted: Boolean = false,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)

enum class SubscriptionTier(val displayName: String) {
    @SerializedName("free")
    FREE("Free"),
    
    @SerializedName("premium")
    PREMIUM("Premium"),
    
    @SerializedName("enterprise")
    ENTERPRISE("Enterprise")
}

enum class ProfileVisibility(val displayName: String) {
    @SerializedName("public")
    PUBLIC("Public"),
    
    @SerializedName("friends")
    FRIENDS("Friends Only"),
    
    @SerializedName("private")
    PRIVATE("Private")
}

enum class ActivityVisibility(val displayName: String) {
    @SerializedName("public")
    PUBLIC("Public"),
    
    @SerializedName("friends")
    FRIENDS("Friends Only"),
    
    @SerializedName("private")
    PRIVATE("Private")
}

// User authentication data (inner data from API response)
data class AuthUserData(
    val user: User,
    val token: String,
    @SerializedName("refresh_token")
    val refreshToken: String?
)

// API response wrapper for authentication
data class AuthResponse(
    val success: Boolean,
    val data: AuthUserData?,
    val error: ApiError?
)

// API error response
data class ApiError(
    val code: String?,
    val message: String?,
    val details: List<ApiErrorDetail>?
)

data class ApiErrorDetail(
    val field: String?,
    val message: String?
)

// User profile update data
data class UserProfileUpdate(
    @SerializedName("display_name")
    val displayName: String? = null,
    @SerializedName("first_name")
    val firstName: String? = null,
    @SerializedName("last_name")
    val lastName: String? = null,
    val timezone: String? = null,
    val language: String? = null,
    @SerializedName("profile_visibility")
    val profileVisibility: String? = null,
    @SerializedName("activity_visibility")
    val activityVisibility: String? = null
)

// Notification preferences data
data class NotificationPreferences(
    @SerializedName("push_notifications_enabled")
    val pushNotificationsEnabled: Boolean = true,
    @SerializedName("email_notifications_enabled")
    val emailNotificationsEnabled: Boolean = true,
    @SerializedName("button_notifications")
    val buttonNotifications: Boolean = true,
    @SerializedName("friend_notifications")
    val friendNotifications: Boolean = true,
    @SerializedName("system_notifications")
    val systemNotifications: Boolean = true,
    @SerializedName("quiet_hours_enabled")
    val quietHoursEnabled: Boolean = false,
    @SerializedName("quiet_hours_start")
    val quietHoursStart: String? = null,
    @SerializedName("quiet_hours_end")
    val quietHoursEnd: String? = null
)

// Notification preferences update data
data class NotificationPreferencesUpdate(
    @SerializedName("push_notifications_enabled")
    val pushNotificationsEnabled: Boolean? = null,
    @SerializedName("email_notifications_enabled")
    val emailNotificationsEnabled: Boolean? = null,
    @SerializedName("button_notifications")
    val buttonNotifications: Boolean? = null,
    @SerializedName("friend_notifications")
    val friendNotifications: Boolean? = null,
    @SerializedName("system_notifications")
    val systemNotifications: Boolean? = null,
    @SerializedName("quiet_hours_enabled")
    val quietHoursEnabled: Boolean? = null,
    @SerializedName("quiet_hours_start")
    val quietHoursStart: String? = null,
    @SerializedName("quiet_hours_end")
    val quietHoursEnd: String? = null
)

// Password change request data
data class PasswordChangeRequest(
    @SerializedName("current_password")
    val currentPassword: String,
    @SerializedName("new_password")
    val newPassword: String,
    @SerializedName("confirm_password")
    val confirmPassword: String
)

// Password change response data
data class PasswordChangeResponse(
    val success: Boolean,
    val data: PasswordChangeData?,
    val error: ApiError?
)

data class PasswordChangeData(
    val message: String
)

// Webhook settings models
data class WebhookSettings(
    @SerializedName("default_webhook_url")
    val defaultWebhookUrl: String?,
    @SerializedName("default_webhook_enabled")
    val defaultWebhookEnabled: Boolean,
    @SerializedName("webhook_secret")
    val webhookSecret: String?,
    @SerializedName("retry_failed")
    val retryFailed: Boolean,
    @SerializedName("max_retries")
    val maxRetries: Int
)

data class WebhookSettingsResponse(
    val success: Boolean,
    val data: WebhookSettings?,
    val error: ApiError?
)

data class WebhookSettingsUpdate(
    @SerializedName("default_webhook_url")
    val defaultWebhookUrl: String?,
    @SerializedName("default_webhook_enabled")
    val defaultWebhookEnabled: Boolean,
    @SerializedName("webhook_secret")
    val webhookSecret: String?,
    @SerializedName("retry_failed")
    val retryFailed: Boolean,
    @SerializedName("max_retries")
    val maxRetries: Int
)

data class WebhookTestResponse(
    val success: Boolean,
    val data: Any?,
    val error: ApiError?
)

