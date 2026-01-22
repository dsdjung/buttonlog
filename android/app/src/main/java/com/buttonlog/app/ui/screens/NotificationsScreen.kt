package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.api.Notification
import com.buttonlog.app.ui.viewmodels.NotificationsViewModel
import java.text.SimpleDateFormat
import java.util.*

// Navigation destination types for notifications
sealed class NotificationNavigation {
    data class Button(val buttonId: String) : NotificationNavigation()
    data class Friend(val friendId: String) : NotificationNavigation()  // Navigate to specific friend's page
    object Friends : NotificationNavigation()  // Navigate to friends list
    object Support : NotificationNavigation()
    data class SupportTicket(val ticketId: String) : NotificationNavigation()
    object None : NotificationNavigation()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(
    viewModel: NotificationsViewModel = hiltViewModel(),
    onNavigate: (NotificationNavigation) -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    var showMenu by remember { mutableStateOf(false) }

    val filteredNotifications = if (uiState.showUnreadOnly) {
        uiState.notifications.filter { !it.isRead }
    } else {
        uiState.notifications
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notifications") },
                actions = {
                    IconButton(onClick = { showMenu = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "Menu")
                    }
                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = {
                                Text(if (uiState.showUnreadOnly) "Show All" else "Show Unread Only")
                            },
                            onClick = {
                                viewModel.toggleShowUnreadOnly()
                                showMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Mark All as Read") },
                            onClick = {
                                viewModel.markAllAsRead()
                                showMenu = false
                            },
                            enabled = uiState.notifications.any { !it.isRead }
                        )
                        DropdownMenuItem(
                            text = { Text("Refresh") },
                            onClick = {
                                viewModel.loadNotifications()
                                showMenu = false
                            }
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading && uiState.notifications.isEmpty() -> {
                    // Loading state
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "Loading notifications...",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                uiState.error != null && uiState.notifications.isEmpty() -> {
                    // Error state
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.ErrorOutline,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            uiState.error ?: "An error occurred",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadNotifications() }) {
                            Text("Retry")
                        }
                    }
                }

                filteredNotifications.isEmpty() -> {
                    // Empty state
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            Icons.Default.NotificationsOff,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            if (uiState.showUnreadOnly) "No unread notifications" else "No notifications yet",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            if (uiState.showUnreadOnly) "All caught up!" else "You'll see notifications here when you have activity from friends",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                else -> {
                    // Notifications list
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 8.dp)
                    ) {
                        items(
                            items = filteredNotifications,
                            key = { it.id }
                        ) { notification ->
                            NotificationItem(
                                notification = notification,
                                onMarkRead = { viewModel.markAsRead(notification.id) },
                                onDelete = { viewModel.deleteNotification(notification.id) },
                                onNavigate = { destination ->
                                    // Mark as read when navigating
                                    if (!notification.isRead) {
                                        viewModel.markAsRead(notification.id)
                                    }
                                    onNavigate(destination)
                                }
                            )
                        }
                    }
                }
            }

            // Pull to refresh indicator
            if (uiState.isLoading && uiState.notifications.isNotEmpty()) {
                LinearProgressIndicator(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.TopCenter)
                )
            }
        }
    }

    // Error snackbar
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Auto-dismiss error after showing
            kotlinx.coroutines.delay(3000)
            viewModel.clearError()
        }
    }
}

@Composable
fun NotificationItem(
    notification: Notification,
    onMarkRead: () -> Unit,
    onDelete: () -> Unit,
    onNavigate: (NotificationNavigation) -> Unit = {}
) {
    val backgroundColor = if (!notification.isRead) {
        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.1f)
    } else {
        MaterialTheme.colorScheme.surface
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(backgroundColor)
            .clickable {
                if (!notification.isRead) {
                    onMarkRead()
                }
                // Navigate based on notification type
                val destination = getNavigationDestination(notification)
                onNavigate(destination)
            }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Icon
        Icon(
            imageVector = getNotificationIcon(notification.type),
            contentDescription = null,
            tint = if (!notification.isRead) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant
            },
            modifier = Modifier.size(24.dp)
        )

        // Content
        Column(
            modifier = Modifier.weight(1f)
        ) {
            // Type badge and time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = getNotificationTypeDisplayName(notification.type),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                    )
                }
                Text(
                    text = formatRelativeTime(notification.insertedAt),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Title
            Text(
                text = notification.title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (!notification.isRead) FontWeight.SemiBold else FontWeight.Normal,
                color = if (!notification.isRead) {
                    MaterialTheme.colorScheme.onSurface
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
            )

            // Body
            Text(
                text = notification.body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Action buttons for unread
            if (!notification.isRead) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    TextButton(
                        onClick = onMarkRead,
                        contentPadding = PaddingValues(horizontal = 0.dp)
                    ) {
                        Text("Mark as Read", style = MaterialTheme.typography.labelMedium)
                    }
                    TextButton(
                        onClick = onDelete,
                        contentPadding = PaddingValues(horizontal = 0.dp),
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text("Delete", style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }

        // Unread indicator
        if (!notification.isRead) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(
                        MaterialTheme.colorScheme.primary,
                        shape = MaterialTheme.shapes.small
                    )
            )
        }
    }

    HorizontalDivider(
        modifier = Modifier.padding(start = 52.dp),
        color = MaterialTheme.colorScheme.outlineVariant
    )
}

fun getNotificationIcon(type: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (type) {
        "button_click" -> Icons.Default.TouchApp
        "friend_request" -> Icons.Default.PersonAdd
        "friend_accepted" -> Icons.Default.HowToReg
        "button_shared" -> Icons.Default.Share
        "system_announcement" -> Icons.Default.Campaign
        "subscription_expiring", "subscription_renewed" -> Icons.Default.CreditCard
        "support_ticket_reply", "support_ticket_status_update" -> Icons.Default.HelpOutline
        "gift_button_received", "gift_button_clicked", "gift_button_sent", "gift_button_deleted" -> Icons.Default.CardGiftcard
        else -> Icons.Default.Notifications
    }
}

fun getNotificationTypeDisplayName(type: String): String {
    return when (type) {
        "button_click" -> "Button Activity"
        "friend_request" -> "Friend Request"
        "friend_accepted" -> "Friend Accepted"
        "button_shared" -> "Button Shared"
        "system_announcement" -> "Announcement"
        "subscription_expiring" -> "Subscription"
        "subscription_renewed" -> "Subscription"
        "support_ticket_reply" -> "Support Reply"
        "support_ticket_status_update" -> "Ticket Status"
        "gift_button_received" -> "Gift Received"
        "gift_button_clicked" -> "Gift Button"
        "gift_button_sent" -> "Gift Sent"
        "gift_button_deleted" -> "Gift Deleted"
        "general" -> "Notification"
        else -> "Notification"
    }
}

fun getNavigationDestination(notification: Notification): NotificationNavigation {
    return when (notification.type) {
        "button_click", "button_shared", "gift_button_received" -> {
            // Try to get button_id from the data map
            val buttonId = notification.data?.get("button_id")?.toString()
            if (buttonId != null) {
                NotificationNavigation.Button(buttonId)
            } else {
                NotificationNavigation.None
            }
        }
        "gift_button_sent", "gift_button_clicked" -> {
            // Navigate to friend page when clicking on gift button notifications
            val friendId = notification.data?.get("friend_id")?.toString()
            if (friendId != null) {
                NotificationNavigation.Friend(friendId)
            } else {
                NotificationNavigation.Friends
            }
        }
        "gift_button_deleted" -> {
            // Button no longer exists
            NotificationNavigation.None
        }
        "friend_request", "friend_accepted" -> {
            NotificationNavigation.Friends
        }
        "support_ticket_reply", "support_ticket_status_update" -> {
            val ticketId = notification.data?.get("ticket_id")?.toString()
            if (ticketId != null) {
                NotificationNavigation.SupportTicket(ticketId)
            } else {
                NotificationNavigation.Support
            }
        }
        else -> NotificationNavigation.None
    }
}

fun formatRelativeTime(dateString: String): String {
    return try {
        val formats = listOf(
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.getDefault())
        )

        var date: Date? = null
        for (format in formats) {
            format.timeZone = TimeZone.getTimeZone("UTC")
            try {
                date = format.parse(dateString)
                if (date != null) break
            } catch (e: Exception) {
                continue
            }
        }

        if (date == null) return dateString

        val now = Date()
        val diffMs = now.time - date.time
        val diffSeconds = diffMs / 1000
        val diffMinutes = diffSeconds / 60
        val diffHours = diffMinutes / 60
        val diffDays = diffHours / 24

        when {
            diffSeconds < 60 -> "Just now"
            diffMinutes < 60 -> "${diffMinutes}m ago"
            diffHours < 24 -> "${diffHours}h ago"
            diffDays < 7 -> "${diffDays}d ago"
            else -> SimpleDateFormat("MMM d", Locale.getDefault()).format(date)
        }
    } catch (e: Exception) {
        dateString
    }
}
