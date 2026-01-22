package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.model.CreateTeamRequest
import com.buttonlog.app.data.model.Team
import com.buttonlog.app.data.model.TeamsResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TeamsRepository @Inject constructor(
    private val apiService: APIService
) {
    suspend fun getTeams(): TeamsResponse {
        val response = apiService.getTeams()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get teams")
        }
    }

    suspend fun getTeam(id: String): Team {
        val response = apiService.getTeam(id)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get team")
        }
    }

    suspend fun createTeam(request: CreateTeamRequest): Team {
        val response = apiService.createTeam(request)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to create team")
        }
    }

    suspend fun updateTeam(id: String, request: CreateTeamRequest): Team {
        val response = apiService.updateTeam(id, request)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to update team")
        }
    }

    suspend fun deleteTeam(id: String) {
        val response = apiService.deleteTeam(id)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to delete team")
        }
    }

    suspend fun acceptInvitation(invitationId: String): Team {
        val response = apiService.acceptTeamInvitation(invitationId)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to accept invitation")
        }
    }

    suspend fun declineInvitation(invitationId: String) {
        val response = apiService.declineTeamInvitation(invitationId)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to decline invitation")
        }
    }

    suspend fun inviteMember(teamId: String, username: String, role: String) {
        val response = apiService.inviteTeamMember(teamId, mapOf(
            "username" to username,
            "role" to role
        ))
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to invite member")
        }
    }

    suspend fun leaveTeam(teamId: String) {
        val response = apiService.leaveTeam(teamId)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to leave team")
        }
    }
}
