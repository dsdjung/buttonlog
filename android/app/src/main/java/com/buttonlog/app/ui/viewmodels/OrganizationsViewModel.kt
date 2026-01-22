package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.model.CreateOrganizationRequest
import com.buttonlog.app.data.model.Organization
import com.buttonlog.app.data.model.OrganizationInvitation
import com.buttonlog.app.data.repository.OrganizationsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OrganizationsViewModel @Inject constructor(
    private val repository: OrganizationsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(OrganizationsUiState())
    val uiState: StateFlow<OrganizationsUiState> = _uiState.asStateFlow()

    fun loadOrganizations() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val response = repository.getOrganizations()
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        organizations = response.organizations,
                        pendingInvitations = response.pendingInvitations
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load organizations"
                    )
                }
            }
        }
    }

    fun createOrganization(name: String, description: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val request = CreateOrganizationRequest(
                    name = name,
                    description = description.ifBlank { null }
                )
                val organization = repository.createOrganization(request)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        organizations = listOf(organization) + it.organizations,
                        showCreateOrganizationDialog = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to create organization"
                    )
                }
            }
        }
    }

    fun acceptInvitation(invitationId: String) {
        viewModelScope.launch {
            try {
                val organization = repository.acceptInvitation(invitationId)
                _uiState.update {
                    it.copy(
                        organizations = listOf(organization) + it.organizations,
                        pendingInvitations = it.pendingInvitations.filter { inv -> inv.id != invitationId }
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message ?: "Failed to accept invitation")
                }
            }
        }
    }

    fun declineInvitation(invitationId: String) {
        viewModelScope.launch {
            try {
                repository.declineInvitation(invitationId)
                _uiState.update {
                    it.copy(
                        pendingInvitations = it.pendingInvitations.filter { inv -> inv.id != invitationId }
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = e.message ?: "Failed to decline invitation")
                }
            }
        }
    }

    fun showCreateOrganizationDialog() {
        _uiState.update { it.copy(showCreateOrganizationDialog = true) }
    }

    fun hideCreateOrganizationDialog() {
        _uiState.update { it.copy(showCreateOrganizationDialog = false) }
    }
}

data class OrganizationsUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val organizations: List<Organization> = emptyList(),
    val pendingInvitations: List<OrganizationInvitation> = emptyList(),
    val showCreateOrganizationDialog: Boolean = false
)
