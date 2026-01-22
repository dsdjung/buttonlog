package com.buttonlog.app.ui.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.*
import com.buttonlog.app.data.repository.SupportRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SupportViewModel @Inject constructor(private val repository: SupportRepository) : ViewModel() {

    // Tickets list state
    var tickets by mutableStateOf<List<SupportTicket>>(emptyList())
        private set

    var isLoadingTickets by mutableStateOf(false)
        private set

    var ticketsError by mutableStateOf<String?>(null)
        private set

    // Single ticket state
    var currentTicket by mutableStateOf<SupportTicket?>(null)
        private set

    var isLoadingTicket by mutableStateOf(false)
        private set

    var ticketError by mutableStateOf<String?>(null)
        private set

    // Message sending state
    var isSendingMessage by mutableStateOf(false)
        private set

    // Create ticket state
    var isCreatingTicket by mutableStateOf(false)
        private set

    var createTicketError by mutableStateOf<String?>(null)
        private set

    fun loadTickets() {
        viewModelScope.launch {
            isLoadingTickets = true
            ticketsError = null

            when (val result = repository.getSupportTickets()) {
                is ApiResult.Success -> {
                    tickets = result.data
                }
                is ApiResult.Error -> {
                    ticketsError = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoadingTickets = false
        }
    }

    fun loadTicket(id: String) {
        viewModelScope.launch {
            isLoadingTicket = true
            ticketError = null

            when (val result = repository.getSupportTicket(id)) {
                is ApiResult.Success -> {
                    currentTicket = result.data
                }
                is ApiResult.Error -> {
                    ticketError = result.message
                }
                is ApiResult.Loading -> {}
            }

            isLoadingTicket = false
        }
    }

    fun createTicket(formData: TicketFormData, onSuccess: (SupportTicket) -> Unit) {
        viewModelScope.launch {
            isCreatingTicket = true
            createTicketError = null

            when (val result = repository.createSupportTicket(formData)) {
                is ApiResult.Success -> {
                    tickets = listOf(result.data) + tickets
                    onSuccess(result.data)
                }
                is ApiResult.Error -> {
                    createTicketError = result.message
                }
                is ApiResult.Loading -> {}
            }

            isCreatingTicket = false
        }
    }

    fun sendMessage(content: String, onSuccess: () -> Unit = {}) {
        val ticketId = currentTicket?.id ?: return

        viewModelScope.launch {
            isSendingMessage = true

            when (val result = repository.sendTicketMessage(ticketId, content)) {
                is ApiResult.Success -> {
                    // Add message to current ticket
                    currentTicket?.let { ticket ->
                        val messages = (ticket.messages ?: emptyList()) + result.data
                        currentTicket = ticket.copy(messages = messages)
                    }
                    onSuccess()
                }
                is ApiResult.Error -> {
                    // Handle error (could add error state)
                }
                is ApiResult.Loading -> {}
            }

            isSendingMessage = false
        }
    }

    fun clearCurrentTicket() {
        currentTicket = null
        ticketError = null
    }
}
