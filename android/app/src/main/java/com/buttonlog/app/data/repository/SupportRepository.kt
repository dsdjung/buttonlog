package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.model.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SupportRepository @Inject constructor(private val apiService: APIService) {

    suspend fun getSupportTickets(): ApiResult<List<SupportTicket>> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getSupportTickets()
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to load tickets")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend fun getSupportTicket(id: String): ApiResult<SupportTicket> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getSupportTicket(id)
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to load ticket")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend fun createSupportTicket(formData: TicketFormData): ApiResult<SupportTicket> = withContext(Dispatchers.IO) {
        try {
            val request = CreateTicketRequest(
                ticket = TicketData(
                    subject = formData.subject.trim(),
                    category = formData.category.name.lowercase(),
                    priority = formData.priority.name.lowercase(),
                    message = formData.message.trim()
                )
            )
            val response = apiService.createSupportTicket(request)
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to create ticket")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend fun sendTicketMessage(ticketId: String, content: String): ApiResult<TicketMessage> = withContext(Dispatchers.IO) {
        try {
            val request = SendMessageRequest(
                message = MessageData(content = content.trim())
            )
            val response = apiService.sendTicketMessage(ticketId, request)
            if (response.success && response.data != null) {
                ApiResult.Success(response.data)
            } else {
                ApiResult.Error(response.error?.message ?: "Failed to send message")
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }
}
