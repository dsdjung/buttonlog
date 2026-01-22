package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName

data class Team(
    val id: String,
    val name: String,
    val description: String? = null,
    val icon: String = "people",
    val color: String = "#3B82F6",
    @SerializedName("owner_id")
    val ownerId: String,
    @SerializedName("organization_id")
    val organizationId: String? = null,
    @SerializedName("member_count")
    val memberCount: Int? = null,
    @SerializedName("button_count")
    val buttonCount: Int? = null,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    val owner: PublicUser? = null,
    @SerializedName("my_role")
    val myRole: String? = null,
    @SerializedName("can_manage")
    val canManage: Boolean? = null,
    val members: List<TeamMember>? = null,
    val buttons: List<TeamButton>? = null
)

data class TeamMember(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("team_id")
    val teamId: String,
    val role: String,
    @SerializedName("joined_at")
    val joinedAt: String,
    @SerializedName("invited_by_id")
    val invitedById: String? = null,
    val user: PublicUser? = null,
    @SerializedName("invited_by")
    val invitedBy: PublicUser? = null
)

data class TeamButton(
    val id: String,
    @SerializedName("team_id")
    val teamId: String,
    @SerializedName("button_id")
    val buttonId: String,
    val permission: String,
    @SerializedName("added_by_id")
    val addedById: String? = null,
    @SerializedName("added_at")
    val addedAt: String,
    val button: TeamButtonInfo? = null
)

data class TeamButtonInfo(
    val id: String,
    val name: String,
    val type: String,
    val icon: String,
    val color: String
)

data class TeamInvitation(
    val id: String,
    @SerializedName("team_id")
    val teamId: String,
    @SerializedName("inviter_id")
    val inviterId: String,
    @SerializedName("invitee_id")
    val inviteeId: String,
    val role: String,
    val status: String,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("expires_at")
    val expiresAt: String? = null,
    val team: TeamSummary? = null,
    val inviter: PublicUser? = null,
    val invitee: PublicUser? = null
)

data class TeamSummary(
    val id: String,
    val name: String,
    val description: String? = null,
    val icon: String,
    val color: String
)

data class TeamsResponse(
    val teams: List<Team>,
    @SerializedName("pending_invitations")
    val pendingInvitations: List<TeamInvitation>
)

data class CreateTeamRequest(
    val name: String,
    val description: String? = null,
    val icon: String = "people",
    val color: String = "#3B82F6"
)
