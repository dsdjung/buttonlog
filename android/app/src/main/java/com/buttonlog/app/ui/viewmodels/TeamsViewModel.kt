package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.model.CreateTeamRequest
import com.buttonlog.app.data.model.Team
import com.buttonlog.app.data.model.TeamInvitation
import com.buttonlog.app.data.repository.TeamsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TeamsViewModel @Inject constructor(
    private val repository: TeamsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TeamsUiState())
    val uiState: StateFlow<TeamsUiState> = _uiState.asStateFlow()

    fun loadTeams() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val response = repository.getTeams()
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        teams = response.teams,
                        pendingInvitations = response.pendingInvitations
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load teams"
                    )
                }
            }
        }
    }

    fun createTeam(name: String, description: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val request = CreateTeamRequest(
                    name = name,
                    description = description.ifBlank { null }
                )
                val team = repository.createTeam(request)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        teams = listOf(team) + it.teams,
                        showCreateTeamDialog = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to create team"
                    )
                }
            }
        }
    }

    fun acceptInvitation(invitationId: String) {
        viewModelScope.launch {
            try {
                val team = repository.acceptInvitation(invitationId)
                _uiState.update {
                    it.copy(
                        teams = listOf(team) + it.teams,
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

    fun showCreateTeamDialog() {
        _uiState.update { it.copy(showCreateTeamDialog = true) }
    }

    fun hideCreateTeamDialog() {
        _uiState.update { it.copy(showCreateTeamDialog = false) }
    }

    fun showLeaveTeamDialog(team: Team) {
        _uiState.update { it.copy(teamToLeave = team) }
    }

    fun hideLeaveTeamDialog() {
        _uiState.update { it.copy(teamToLeave = null) }
    }

    fun leaveTeam(teamId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLeaving = true) }
            try {
                repository.leaveTeam(teamId)
                _uiState.update {
                    it.copy(
                        isLeaving = false,
                        teams = it.teams.filter { team -> team.id != teamId },
                        teamToLeave = null
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLeaving = false,
                        error = e.message ?: "Failed to leave team"
                    )
                }
            }
        }
    }
}

data class TeamsUiState(
    val isLoading: Boolean = false,
    val isLeaving: Boolean = false,
    val error: String? = null,
    val teams: List<Team> = emptyList(),
    val pendingInvitations: List<TeamInvitation> = emptyList(),
    val showCreateTeamDialog: Boolean = false,
    val teamToLeave: Team? = null
)
