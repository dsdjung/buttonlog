package com.buttonlog.app.data.model

import androidx.compose.ui.graphics.Color
import com.google.gson.annotations.SerializedName

// MARK: - Support Ticket

data class SupportTicket(
    val id: String,
    val subject: String,
    val category: TicketCategory,
    val priority: TicketPriority,
    val status: TicketStatus,
    @SerializedName("unread_count")
    val unreadCount: Int?,
    @SerializedName("assigned_admin")
    val assignedAdmin: SupportAdmin?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    val messages: List<TicketMessage>?
)

// MARK: - Ticket Message

data class TicketMessage(
    val id: String,
    val content: String,
    @SerializedName("sender_id")
    val senderId: String,
    @SerializedName("sender_name")
    val senderName: String?,
    @SerializedName("is_from_support")
    val isFromSupport: Boolean,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("read_at")
    val readAt: String?
)

// MARK: - Support Admin

data class SupportAdmin(
    val id: String,
    val name: String?
)

// MARK: - Enums

enum class TicketCategory(val displayName: String, val icon: String) {
    @SerializedName("bug")
    BUG("Bug Report", "bug_report"),

    @SerializedName("feature_request")
    FEATURE_REQUEST("Feature Request", "lightbulb"),

    @SerializedName("question")
    QUESTION("Question", "help"),

    @SerializedName("other")
    OTHER("Other", "more_horiz")
}

enum class TicketPriority(val displayName: String) {
    @SerializedName("low")
    LOW("Low"),

    @SerializedName("normal")
    NORMAL("Normal"),

    @SerializedName("high")
    HIGH("High"),

    @SerializedName("urgent")
    URGENT("Urgent")
}

enum class TicketStatus(val displayName: String, val color: Color) {
    @SerializedName("open")
    OPEN("Open", Color(0xFFFF9800)),

    @SerializedName("in_progress")
    IN_PROGRESS("In Progress", Color(0xFF2196F3)),

    @SerializedName("resolved")
    RESOLVED("Resolved", Color(0xFF4CAF50)),

    @SerializedName("closed")
    CLOSED("Closed", Color(0xFF9E9E9E));

    val isActive: Boolean
        get() = this == OPEN || this == IN_PROGRESS
}

// MARK: - Form Data

data class TicketFormData(
    var subject: String = "",
    var category: TicketCategory = TicketCategory.QUESTION,
    var priority: TicketPriority = TicketPriority.NORMAL,
    var message: String = ""
) {
    val isValid: Boolean
        get() = subject.trim().isNotEmpty() && message.trim().isNotEmpty()
}

// MARK: - API Request/Response

data class CreateTicketRequest(
    val ticket: TicketData
)

data class TicketData(
    val subject: String,
    val category: String,
    val priority: String,
    val message: String
)

data class SendMessageRequest(
    val message: MessageData
)

data class MessageData(
    val content: String
)

// API response wrappers
data class SupportTicketsResponse(
    val success: Boolean,
    val data: List<SupportTicket>?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class SupportTicketResponse(
    val success: Boolean,
    val data: SupportTicket?,
    val error: ApiError?,
    val meta: ApiMeta?
)

data class TicketMessageResponse(
    val success: Boolean,
    val data: TicketMessage?,
    val error: ApiError?,
    val meta: ApiMeta?
)
