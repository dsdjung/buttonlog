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
    @SerializedName("notifications_enabled")
    val notificationsEnabled: Boolean,
    @SerializedName("auto_stop_enabled")
    val autoStopEnabled: Boolean,
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
    val giftMessage: String? = null
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

// Button creation form data
data class ButtonFormData(
    var name: String = "",
    var description: String = "",
    var type: ButtonType = ButtonType.INSTANT,
    var icon: String = "star",
    var color: String = "#007AFF",
    var notificationsEnabled: Boolean = true,
    var autoStopEnabled: Boolean = false,
    var calendarSyncEnabled: Boolean = false
) {
    val isValid: Boolean
        get() = name.trim().isNotEmpty()
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
    @SerializedName("notifications_enabled")
    val notificationsEnabled: Boolean,
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

