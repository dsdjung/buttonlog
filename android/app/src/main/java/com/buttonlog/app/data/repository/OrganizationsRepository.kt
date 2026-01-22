package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.model.CreateOrganizationRequest
import com.buttonlog.app.data.model.Organization
import com.buttonlog.app.data.model.OrganizationsResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OrganizationsRepository @Inject constructor(
    private val apiService: APIService
) {
    suspend fun getOrganizations(): OrganizationsResponse {
        val response = apiService.getOrganizations()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get organizations")
        }
    }

    suspend fun getOrganization(id: String): Organization {
        val response = apiService.getOrganization(id)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get organization")
        }
    }

    suspend fun createOrganization(request: CreateOrganizationRequest): Organization {
        val response = apiService.createOrganization(request)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to create organization")
        }
    }

    suspend fun updateOrganization(id: String, request: CreateOrganizationRequest): Organization {
        val response = apiService.updateOrganization(id, request)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to update organization")
        }
    }

    suspend fun deleteOrganization(id: String) {
        val response = apiService.deleteOrganization(id)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to delete organization")
        }
    }

    suspend fun acceptInvitation(invitationId: String): Organization {
        val response = apiService.acceptOrganizationInvitation(invitationId)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to accept invitation")
        }
    }

    suspend fun declineInvitation(invitationId: String) {
        val response = apiService.declineOrganizationInvitation(invitationId)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to decline invitation")
        }
    }

    suspend fun inviteMember(organizationId: String, username: String?, email: String?, role: String) {
        val body = mutableMapOf<String, String>("role" to role)
        username?.let { body["username"] = it }
        email?.let { body["email"] = it }

        val response = apiService.inviteOrganizationMember(organizationId, body)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to invite member")
        }
    }

    suspend fun leaveOrganization(organizationId: String) {
        val response = apiService.leaveOrganization(organizationId)
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to leave organization")
        }
    }
}
