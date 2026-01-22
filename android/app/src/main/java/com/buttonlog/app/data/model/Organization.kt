package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName

data class Organization(
    val id: String,
    val name: String,
    val slug: String,
    val description: String? = null,
    @SerializedName("logo_url")
    val logoUrl: String? = null,
    val website: String? = null,
    val domain: String? = null,
    @SerializedName("sso_enabled")
    val ssoEnabled: Boolean = false,
    @SerializedName("require_sso")
    val requireSso: Boolean = false,
    @SerializedName("allow_personal_teams")
    val allowPersonalTeams: Boolean = true,
    @SerializedName("default_team_role")
    val defaultTeamRole: String = "member",
    @SerializedName("billing_email")
    val billingEmail: String? = null,
    @SerializedName("billing_address")
    val billingAddress: Map<String, String>? = null,
    @SerializedName("tax_id")
    val taxId: String? = null,
    @SerializedName("max_seats")
    val maxSeats: Int? = null,
    @SerializedName("max_teams")
    val maxTeams: Int? = null,
    val status: String = "active",
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    @SerializedName("my_role")
    val myRole: String? = null,
    @SerializedName("can_manage")
    val canManage: Boolean? = null,
    @SerializedName("can_manage_billing")
    val canManageBilling: Boolean? = null,
    @SerializedName("member_count")
    val memberCount: Int? = null,
    @SerializedName("team_count")
    val teamCount: Int? = null,
    val members: List<OrganizationMember>? = null,
    val teams: List<Team>? = null,
    val subscription: OrganizationSubscription? = null
)

data class OrganizationMember(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("organization_id")
    val organizationId: String,
    val role: String,
    @SerializedName("joined_at")
    val joinedAt: String,
    @SerializedName("invited_by_id")
    val invitedById: String? = null,
    val user: PublicUser? = null,
    @SerializedName("invited_by")
    val invitedBy: PublicUser? = null
)

data class OrganizationSubscription(
    val id: String,
    @SerializedName("organization_id")
    val organizationId: String,
    @SerializedName("plan_id")
    val planId: String,
    val status: String,
    @SerializedName("seats_purchased")
    val seatsPurchased: Int,
    @SerializedName("seats_used")
    val seatsUsed: Int,
    @SerializedName("price_per_seat")
    val pricePerSeat: Int,
    @SerializedName("billing_cycle")
    val billingCycle: String,
    @SerializedName("period_start")
    val periodStart: String,
    @SerializedName("period_end")
    val periodEnd: String,
    @SerializedName("cancelled_at")
    val cancelledAt: String? = null,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    val seatsAvailable: Int
        get() = seatsPurchased - seatsUsed
}

data class OrganizationInvitation(
    val id: String,
    @SerializedName("organization_id")
    val organizationId: String,
    @SerializedName("inviter_id")
    val inviterId: String,
    @SerializedName("invitee_id")
    val inviteeId: String? = null,
    val email: String? = null,
    val role: String,
    val token: String,
    @SerializedName("expires_at")
    val expiresAt: String,
    @SerializedName("accepted_at")
    val acceptedAt: String? = null,
    @SerializedName("declined_at")
    val declinedAt: String? = null,
    @SerializedName("created_at")
    val createdAt: String,
    val organization: OrganizationSummary? = null,
    val inviter: PublicUser? = null,
    val invitee: PublicUser? = null
)

data class OrganizationSummary(
    val id: String,
    val name: String,
    val slug: String,
    val description: String? = null,
    @SerializedName("logo_url")
    val logoUrl: String? = null
)

data class OrganizationsResponse(
    val organizations: List<Organization>,
    @SerializedName("pending_invitations")
    val pendingInvitations: List<OrganizationInvitation>
)

data class CreateOrganizationRequest(
    val name: String,
    val slug: String? = null,
    val description: String? = null,
    val domain: String? = null,
    @SerializedName("billing_email")
    val billingEmail: String? = null
)
