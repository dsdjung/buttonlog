package com.buttonlog.app.data.model

import androidx.compose.ui.graphics.Color
import com.google.gson.annotations.SerializedName
import java.util.*

data class Button(
    val id: String,
    val name: String,
    val description: String?,
    val type: ButtonType,
    val icon: String,
    val color: String,
    @SerializedName("is_active")
    val isActive: Boolean,
    @SerializedName("current_state")
    val currentState: ButtonState,
    @SerializedName("state_changed_at")
    val stateChangedAt: Date?,
    @SerializedName("alerts_enabled")
    val alertsEnabled: Boolean,
    @SerializedName("auto_stop_enabled")
    val autoStopEnabled: Boolean,
    @SerializedName("auto_stop_minutes")
    val autoStopMinutes: Int? = null,  // Duration in minutes (15, 30, 60, 120, 240, 480)
    @SerializedName("scheduled_stop_at")
    val scheduledStopAt: Date? = null,  // When the button will auto-stop
    @SerializedName("calendar_sync_enabled")
    val calendarSyncEnabled: Boolean,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("created_at")
    val createdAt: Date,
    @SerializedName("updated_at")
    val updatedAt: Date,
    // Gift button fields
    @SerializedName("created_by_friend_id")
    val createdByFriendId: String? = null,
    @SerializedName("created_by_friend")
    val createdByFriend: GiftCreator? = null,
    @SerializedName("gift_message")
    val giftMessage: String? = null,
    // Sharing fields
    @SerializedName("sharing_mode")
    val sharingMode: SharingMode? = null,
    @SerializedName("share_token")
    val shareToken: String? = null,
    @SerializedName("share_token_expires_at")
    val shareTokenExpiresAt: Date? = null,
    @SerializedName("is_shared_with_me")
    val isSharedWithMe: Boolean? = null,
    @SerializedName("owner_id")
    val ownerId: String? = null,
    @SerializedName("owner_name")
    val ownerName: String? = null
) {
    val hexColor: String
        get() = if (color.startsWith("#")) color else "#$color"

    val uiColor: Color
        get() = Color(android.graphics.Color.parseColor(hexColor))

    /** True if this button was created by a friend as a gift */
    val isGift: Boolean
        get() = createdByFriendId != null

    /** Display name of the friend who created this button as a gift */
    val giftFromName: String?
        get() = createdByFriend?.displayName ?: createdByFriend?.username

    /** True if this is someone else's button shared with the current user */
    val isShared: Boolean
        get() = isSharedWithMe == true

    /** True if the current user is the owner of this button */
    val isOwner: Boolean
        get() = isSharedWithMe != true

    /** Formatted auto-stop duration (e.g., "1 hour", "30 minutes") */
    val autoStopDurationText: String?
        get() {
            val minutes = autoStopMinutes ?: return null
            return when {
                minutes < 60 -> "$minutes minutes"
                minutes == 60 -> "1 hour"
                minutes % 60 == 0 -> "${minutes / 60} hours"
                else -> "${minutes / 60} hr ${minutes % 60} min"
            }
        }

    /** Time remaining until auto-stop in milliseconds (null if not scheduled or already passed) */
    val timeUntilAutoStopMs: Long?
        get() {
            val stopAt = scheduledStopAt ?: return null
            val remaining = stopAt.time - System.currentTimeMillis()
            return if (remaining > 0) remaining else null
        }

    /** Formatted time remaining until auto-stop */
    val autoStopRemainingText: String?
        get() {
            val remainingMs = timeUntilAutoStopMs ?: return null
            val minutes = (remainingMs / 60000).toInt()
            return when {
                minutes < 1 -> "< 1 min"
                minutes < 60 -> "$minutes min"
                minutes % 60 == 0 -> "${minutes / 60} hr"
                else -> "${minutes / 60} hr ${minutes % 60} min"
            }
        }

    companion object {
        /** Available auto-stop duration options */
        val AUTO_STOP_OPTIONS = listOf(
            15 to "15 minutes",
            30 to "30 minutes",
            60 to "1 hour",
            120 to "2 hours",
            240 to "4 hours",
            480 to "8 hours"
        )
    }
}

/** Minimal user info for gift button creator */
data class GiftCreator(
    val id: String,
    val username: String?,
    @SerializedName("display_name")
    val displayName: String?
)

enum class ButtonType(val displayName: String, val icon: String, val description: String) {
    @SerializedName("instant")
    INSTANT("Instant", "bolt", "Single click actions"),

    @SerializedName("toggle")
    TOGGLE("Toggle", "toggle_on", "Start/stop with duration tracking"),

    @SerializedName("one-time")
    ONE_TIME("One-Time", "looks_one", "Use once, then archived"),

    @SerializedName("workflow")
    WORKFLOW("Workflow", "list", "Predefined sequence of states")
}

enum class ButtonState(val displayName: String, val color: Color) {
    @SerializedName("idle")
    IDLE("Idle", Color.Gray),

    @SerializedName("active")
    ACTIVE("Active", Color.Green)
}

enum class SharingMode(
    val displayName: String,
    val description: String,
    val iconName: String
) {
    @SerializedName("private")
    PRIVATE("Private", "Only you can click this button", "lock"),

    @SerializedName("friends")
    FRIENDS("Friends Only", "All your friends can click this button", "people"),

    @SerializedName("invite_only")
    INVITE_ONLY("Invite Only", "Only invited users can click this button", "mail"),

    @SerializedName("public")
    PUBLIC("Public Link", "Anyone with the link can click this button", "link")
}

/** Button collaborator - a user who can click a shared button */
data class ButtonCollaborator(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("user_name")
    val userName: String?,
    @SerializedName("user_display_name")
    val userDisplayName: String?,
    val permission: String,
    @SerializedName("accepted_at")
    val acceptedAt: Date?,
    @SerializedName("created_at")
    val createdAt: Date
) {
    val displayName: String
        get() = userDisplayName ?: userName ?: "Unknown"
}

/** Response when generating a share link */
data class ShareLinkResponse(
    @SerializedName("share_token")
    val shareToken: String,
    @SerializedName("share_url")
    val shareUrl: String
)

// Button creation form data
data class ButtonFormData(
    var name: String = "",
    var description: String = "",
    var type: ButtonType = ButtonType.INSTANT,
    var icon: String = "star",
    var color: String = "#00BFA5",
    var alertsEnabled: Boolean = true,
    var autoStopEnabled: Boolean = false,
    var autoStopMinutes: Int? = null,  // Duration in minutes (15, 30, 60, 120, 240, 480)
    var calendarSyncEnabled: Boolean = false
) {
    val isValid: Boolean
        get() = name.trim().isNotEmpty()

    /** Convert to request body map for API call */
    fun toRequestBody(): Map<String, Any?> {
        val body = mutableMapOf<String, Any?>(
            "name" to name.trim(),
            "description" to description.ifEmpty { null },
            "type" to type.name.lowercase().replace("_", "-"),
            "icon" to icon,
            "color" to color,
            "alerts_enabled" to alertsEnabled,
            "auto_stop_enabled" to autoStopEnabled,
            "calendar_sync_enabled" to calendarSyncEnabled
        )

        // Only include auto_stop_minutes if auto-stop is enabled
        if (autoStopEnabled && autoStopMinutes != null) {
            body["auto_stop_minutes"] = autoStopMinutes
        }

        return body.filterValues { it != null }
    }
}

// Button click data
data class ButtonClick(
    val id: String,
    @SerializedName("button_id")
    val buttonId: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("clicked_at")
    val clickedAt: Date,
    val duration: Int?,
    @SerializedName("location_lat")
    val locationLat: Double?,
    @SerializedName("location_lng")
    val locationLng: Double?,
    val device: String?,
    val platform: String?,
    val action: String?,
    @SerializedName("created_at")
    val createdAt: Date
)

// Friend's button with latest click info (status, time, location)
data class FriendButton(
    val id: String,
    val name: String,
    val description: String?,
    val type: ButtonType,
    val icon: String,
    val color: String,
    @SerializedName("is_active")
    val isActive: Boolean,
    @SerializedName("current_state")
    val currentState: ButtonState,
    @SerializedName("state_changed_at")
    val stateChangedAt: String?,
    @SerializedName("alerts_enabled")
    val alertsEnabled: Boolean,
    @SerializedName("auto_stop_enabled")
    val autoStopEnabled: Boolean,
    @SerializedName("calendar_sync_enabled")
    val calendarSyncEnabled: Boolean,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    // Latest click info
    @SerializedName("latest_click_at")
    val latestClickAt: String?,
    @SerializedName("latest_click_action")
    val latestClickAction: String?,
    @SerializedName("latest_click_location")
    val latestClickLocation: ClickLocation?,
    @SerializedName("latest_click_device")
    val latestClickDevice: String?,
    @SerializedName("latest_click_platform")
    val latestClickPlatform: String?
) {
    val hexColor: String
        get() = if (color.startsWith("#")) color else "#$color"

    val uiColor: Color
        get() = try {
            Color(android.graphics.Color.parseColor(hexColor))
        } catch (e: Exception) {
            Color(0xFF007AFF)
        }

    val displayAction: String
        get() = latestClickAction ?: "click"
}

data class ClickLocation(
    val lat: Double,
    val lng: Double
)

data class FriendButtonsResponse(
    val success: Boolean,
    val data: List<FriendButton> = emptyList(),
    val error: ApiError?
)

// Button sharing setting for a specific friend
data class ButtonSharingSetting(
    @SerializedName("friend_id")
    val friendId: String,
    @SerializedName("friend_username")
    val friendUsername: String,
    @SerializedName("friend_display_name")
    val friendDisplayName: String?,
    @SerializedName("is_shared")
    var isShared: Boolean
)

data class ButtonSharingResponse(
    val success: Boolean,
    val data: List<ButtonSharingSetting> = emptyList(),
    val error: ApiError?
)

data class ButtonSharingUpdateRequest(
    val sharing: List<ButtonSharingUpdate>
)

data class ButtonSharingUpdate(
    @SerializedName("friend_id")
    val friendId: String,
    @SerializedName("is_shared")
    val isShared: Boolean
)

// API response wrappers for buttons
data class ButtonsResponse(
    val success: Boolean,
    val data: List<Button>?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class ButtonResponse(
    val success: Boolean,
    val data: Button?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class ButtonClickResponse(
    val success: Boolean,
    val data: ButtonClick?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class ButtonHistoryResponse(
    val success: Boolean,
    val data: List<ButtonClick>?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class ApiMeta(
    val timestamp: String?,
    @SerializedName("request_id")
    val requestId: String?,
    val count: Int?
)

// Sharing API response wrappers
data class SharingModeUpdateRequest(
    @SerializedName("sharing_mode")
    val sharingMode: String
)

data class AddCollaboratorRequest(
    @SerializedName("user_id")
    val userId: String
)

data class CollaboratorsResponse(
    val success: Boolean,
    val data: List<ButtonCollaborator>?,
    val error: ApiError?
)

data class CollaboratorResponse(
    val success: Boolean,
    val data: ButtonCollaborator?,
    val error: ApiError?
)

data class ShareLinkApiResponse(
    val success: Boolean,
    val data: ShareLinkResponse?,
    val error: ApiError?
)

