package com.buttonlog.app.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.SupportTicket
import com.buttonlog.app.data.model.TicketCategory
import com.buttonlog.app.data.model.TicketStatus
import com.buttonlog.app.ui.viewmodels.SupportViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SupportScreen(
    viewModel: SupportViewModel,
    onTicketClick: (String) -> Unit,
    onCreateTicket: () -> Unit,
    onBackClick: () -> Unit
) {
    val tickets = viewModel.tickets
    val isLoading = viewModel.isLoadingTickets
    val error = viewModel.ticketsError

    LaunchedEffect(Unit) {
        viewModel.loadTickets()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Help & Support") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onCreateTicket) {
                        Icon(Icons.Default.Add, contentDescription = "Create Ticket")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onCreateTicket) {
                Icon(Icons.Default.Add, contentDescription = "Create Ticket")
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                error != null -> {
                    Column(
                        modifier = Modifier
                            .align(Alignment.Center)
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.Warning,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(error, color = MaterialTheme.colorScheme.error)
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadTickets() }) {
                            Text("Retry")
                        }
                    }
                }
                tickets.isEmpty() -> {
                    Column(
                        modifier = Modifier
                            .align(Alignment.Center)
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.Chat,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "No Support Tickets",
                            style = MaterialTheme.typography.titleLarge
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "Have a question or found a bug?\nCreate a ticket to get help.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 32.dp)
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(onClick = onCreateTicket) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Create Ticket")
                        }
                    }
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(tickets) { ticket ->
                            TicketCard(
                                ticket = ticket,
                                onClick = { onTicketClick(ticket.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TicketCard(
    ticket: SupportTicket,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = getCategoryIcon(ticket.category),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = ticket.subject,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                ticket.unreadCount?.let { count ->
                    if (count > 0) {
                        Badge(
                            containerColor = MaterialTheme.colorScheme.primary
                        ) {
                            Text(count.toString())
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                StatusChip(status = ticket.status)

                Text(
                    text = formatRelativeTime(ticket.updatedAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun StatusChip(status: TicketStatus) {
    Surface(
        shape = MaterialTheme.shapes.small,
        color = status.color.copy(alpha = 0.2f)
    ) {
        Text(
            text = status.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = status.color,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

fun getCategoryIcon(category: TicketCategory) = when (category) {
    TicketCategory.BUG -> Icons.Default.BugReport
    TicketCategory.FEATURE_REQUEST -> Icons.Default.Lightbulb
    TicketCategory.QUESTION -> Icons.Default.Help
    TicketCategory.OTHER -> Icons.Default.MoreHoriz
}

fun formatRelativeTime(dateString: String): String {
    return try {
        // Try parsing ISO 8601 format from Phoenix/Elixir
        val formats = listOf(
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
        )

        var date: Date? = null
        for (format in formats) {
            format.timeZone = TimeZone.getTimeZone("UTC")
            try {
                date = format.parse(dateString)
                if (date != null) break
            } catch (e: Exception) {
                // Try next format
            }
        }

        if (date == null) return dateString

        val now = System.currentTimeMillis()
        val diff = now - date.time

        when {
            diff < 60_000 -> "Just now"
            diff < 3_600_000 -> "${diff / 60_000}m ago"
            diff < 86_400_000 -> "${diff / 3_600_000}h ago"
            diff < 604_800_000 -> "${diff / 86_400_000}d ago"
            else -> SimpleDateFormat("MMM d", Locale.getDefault()).format(date)
        }
    } catch (e: Exception) {
        dateString
    }
}
