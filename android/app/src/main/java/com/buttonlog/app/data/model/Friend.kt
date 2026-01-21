package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName

data class Friend(
    val id: String,
    @SerializedName("friend_id")
    val friendId: String,
    @SerializedName("friend_user")
    val friendUser: PublicUser,
    val status: FriendshipStatus,
    val permissions: FriendPermissions,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
)

data class PublicUser(
    val id: String,
    val username: String?,
    @SerializedName("display_name")
    val displayName: String?,
    @SerializedName("first_name")
    val firstName: String?,
    @SerializedName("last_name")
    val lastName: String?,
    @SerializedName("profile_visibility")
    val profileVisibility: String?
) {
    val displayNameOrUsername: String
        get() = displayName ?: username ?: "Unknown"

    val fullName: String
        get() {
            return when {
                !firstName.isNullOrBlank() && !lastName.isNullOrBlank() -> "$firstName $lastName"
                !firstName.isNullOrBlank() -> firstName
                !lastName.isNullOrBlank() -> lastName
                !displayName.isNullOrBlank() -> displayName
                !username.isNullOrBlank() -> username
                else -> "Unknown"
            }
        }
}

enum class FriendshipStatus {
    @SerializedName("pending")
    PENDING,

    @SerializedName("accepted")
    ACCEPTED,

    @SerializedName("rejected")
    REJECTED,

    @SerializedName("blocked")
    BLOCKED
}

data class FriendPermissions(
    // For inline permissions in friends list
    @SerializedName("can_see_buttons")
    val canSeeButtons: Boolean = true,
    @SerializedName("can_see_activity")
    val canSeeActivity: Boolean = true,
    @SerializedName("receive_notifications")
    val receiveNotifications: Boolean = true,
    @SerializedName("can_comment")
    val canComment: Boolean = true,
    // For permissions endpoint (different field names from backend)
    @SerializedName("can_view_buttons")
    val canViewButtons: Boolean = true,
    @SerializedName("can_view_history")
    val canViewHistory: Boolean = false,
    @SerializedName("can_receive_notifications")
    val canReceiveNotifications: Boolean = true
)

data class FriendPermissionUpdate(
    @SerializedName("can_see_buttons")
    val canSeeButtons: Boolean,
    @SerializedName("can_see_activity")
    val canSeeActivity: Boolean,
    @SerializedName("receive_notifications")
    val receiveNotifications: Boolean,
    @SerializedName("can_comment")
    val canComment: Boolean
)

data class FriendRequest(
    val email: String? = null,
    val username: String? = null,
    @SerializedName("friend_id")
    val friendId: String? = null,
    val message: String? = null
)

// API response wrappers
data class FriendsResponse(
    val success: Boolean,
    val data: List<Friend> = emptyList(),
    val error: ApiError?
)

data class FriendPermissionsResponse(
    val success: Boolean,
    val data: FriendPermissions,
    val error: ApiError?
)

data class FriendActivity(
    val id: String,
    @SerializedName("button_id")
    val buttonId: String,
    @SerializedName("button_name")
    val buttonName: String,
    @SerializedName("button_type")
    val buttonType: String,
    @SerializedName("button_icon")
    val buttonIcon: String?,
    @SerializedName("button_color")
    val buttonColor: String?,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("clicked_at")
    val clickedAt: String,
    val duration: Int?,
    val action: String?,
    val device: String?,
    val platform: String?,
    @SerializedName("created_at")
    val createdAt: String
) {
    val displayAction: String
        get() = action ?: "click"

    val buttonTypeEmoji: String
        get() = when (buttonType) {
            "instant" -> "⚡"
            "timed" -> "⏱️"
            "state" -> "🔄"
            else -> "📱"
        }
}

data class FriendActivityResponse(
    val success: Boolean,
    val data: List<FriendActivity> = emptyList(),
    val error: ApiError?,
    val meta: ActivityMeta?
)

data class ActivityMeta(
    val count: Int,
    val limit: Int,
    @SerializedName("has_more")
    val hasMore: Boolean = false,
    @SerializedName("next_cursor")
    val nextCursor: ActivityCursor? = null
)

data class ActivityCursor(
    @SerializedName("clicked_at")
    val clickedAt: String,
    val id: String
)
