package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName
import java.util.*

data class User(
    val id: String,
    val email: String,
    val username: String,
    @SerializedName("display_name")
    val displayName: String,
    val avatar: String?,
    val timezone: String,
    val language: String,
    @SerializedName("subscription_tier")
    val subscriptionTier: SubscriptionTier,
    @SerializedName("subscription_expires_at")
    val subscriptionExpiresAt: Date?,
    @SerializedName("default_history_sharing")
    val defaultHistorySharing: Boolean,
    @SerializedName("allow_friend_requests")
    val allowFriendRequests: Boolean,
    @SerializedName("profile_visibility")
    val profileVisibility: ProfileVisibility,
    @SerializedName("activity_visibility")
    val activityVisibility: ActivityVisibility,
    @SerializedName("created_at")
    val createdAt: Date,
    @SerializedName("updated_at")
    val updatedAt: Date
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

// User authentication data
data class AuthUser(
    val user: User,
    val token: String,
    @SerializedName("refresh_token")
    val refreshToken: String?
)

// User profile update data
data class UserProfileUpdate(
    @SerializedName("display_name")
    val displayName: String,
    val timezone: String,
    val language: String,
    @SerializedName("profile_visibility")
    val profileVisibility: ProfileVisibility,
    @SerializedName("activity_visibility")
    val activityVisibility: ActivityVisibility
)

