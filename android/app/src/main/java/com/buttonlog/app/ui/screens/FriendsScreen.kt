package com.buttonlog.app.ui.screens

import android.content.Intent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.ui.theme.*
import com.buttonlog.app.ui.viewmodels.FriendsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendsScreen(
    onFriendSelected: (Friend) -> Unit = {},
    onCreatedGiftButtonsClick: () -> Unit = {},
    onActivityFeedClick: () -> Unit = {},
    viewModel: FriendsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showAddFriendDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.fetchFriends()
    }

    PullToRefreshBox(
        isRefreshing = uiState.isRefreshing,
        onRefresh = { viewModel.refreshFriends() },
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Header with Add Friend button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Friends",
                    style = MaterialTheme.typography.headlineMedium
                )

                FilledTonalButton(onClick = { showAddFriendDialog = true }) {
                    Icon(
                        imageVector = Icons.Default.PersonAdd,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Invite")
                }
            }

            when {
                uiState.isLoading && !uiState.isRefreshing -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            uiState.friends.isEmpty() -> {
                EmptyFriendsView(
                    onAddFriend = { showAddFriendDialog = true },
                    inviteLinkData = uiState.inviteLinkData,
                    isLoadingInviteLink = uiState.isLoadingInviteLink,
                    onLoadInviteLink = { viewModel.loadInviteLink() }
                )
            }

            else -> {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Activity feed link
                    item {
                        ActivityFeedCard(onClick = onActivityFeedClick)
                    }

                    // Created gift buttons link
                    item {
                        CreatedGiftButtonsCard(onClick = onCreatedGiftButtonsClick)
                    }

                    // Pending requests section
                    if (uiState.pendingRequests.isNotEmpty()) {
                        item {
                            Text(
                                text = "Pending Requests",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }

                        items(uiState.pendingRequests) { friend ->
                            PendingFriendRequestCard(
                                friend = friend,
                                onAccept = { viewModel.acceptFriendRequest(friend.id) }
                            )
                        }

                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                    }

                    // Accepted friends section
                    if (uiState.acceptedFriends.isNotEmpty()) {
                        item {
                            Text(
                                text = "Friends",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }

                        items(uiState.acceptedFriends) { friend ->
                            FriendCard(
                                friend = friend,
                                onClick = { onFriendSelected(friend) }
                            )
                        }
                    }
                }
            }
        }
        }
    }

    // Add Friend Dialog
    if (showAddFriendDialog) {
        AddFriendDialog(
            onDismiss = { showAddFriendDialog = false },
            onSendRequest = { email, username ->
                viewModel.sendFriendRequest(
                    email = email.takeIf { it.isNotBlank() },
                    username = username.takeIf { it.isNotBlank() }
                )
                showAddFriendDialog = false
            }
        )
    }

    // Error handling
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Could show snackbar here
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ActivityFeedCard(onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = MaterialTheme.shapes.medium,
                    color = BLPrimary.copy(alpha = 0.2f)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Timeline,
                            contentDescription = null,
                            tint = BLPrimary,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }

                Column {
                    Text(
                        text = "Friend Activity",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "See what your friends are up to",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreatedGiftButtonsCard(onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = MaterialTheme.shapes.medium,
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.CardGiftcard,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }

                Column {
                    Text(
                        text = "Buttons I Created for Friends",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Manage gift buttons you've created",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun EmptyFriendsView(
    onAddFriend: () -> Unit,
    inviteLinkData: com.buttonlog.app.data.api.InviteLinkData? = null,
    isLoadingInviteLink: Boolean = false,
    onLoadInviteLink: () -> Unit = {}
) {
    val context = LocalContext.current
    var pendingShare by remember { mutableStateOf(false) }

    // Auto-share when invite link is loaded after user clicked share
    LaunchedEffect(inviteLinkData) {
        if (pendingShare && inviteLinkData != null) {
            pendingShare = false
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, inviteLinkData.shareMessage)
            }
            context.startActivity(Intent.createChooser(shareIntent, "Invite a friend"))
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BLBackground)
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(48.dp))

        // Icon illustration
        Box(
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(BLPrimary.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.People,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = BLPrimary
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Headline
        Text(
            text = "Better Together",
            style = MaterialTheme.typography.headlineMedium,
            color = BLTextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Invite your accountability partner to track habits together and keep each other on track",
            style = MaterialTheme.typography.bodyLarge,
            color = BLTextSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Feature highlights
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            EmptyStateBenefitRow(
                icon = Icons.Default.CardGiftcard,
                color = BLButtonPurple,
                text = "Create buttons for friends"
            )
            EmptyStateBenefitRow(
                icon = Icons.Default.NotificationsActive,
                color = BLPrimary,
                text = "Get notified when they complete"
            )
            EmptyStateBenefitRow(
                icon = Icons.Default.TrendingUp,
                color = BLSecondary,
                text = "Celebrate progress together"
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // CTA buttons
        Button(
            onClick = onAddFriend,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = BLPrimary)
        ) {
            Icon(
                imageVector = Icons.Default.Email,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("Invite by Email")
        }

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedButton(
            onClick = {
                if (inviteLinkData != null) {
                    // Use the fetched invite link
                    val shareIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, inviteLinkData.shareMessage)
                    }
                    context.startActivity(Intent.createChooser(shareIntent, "Invite a friend"))
                } else {
                    // Load the invite link first, then share when loaded
                    pendingShare = true
                    onLoadInviteLink()
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.5.dp, BLPrimary),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = BLPrimary),
            enabled = !isLoadingInviteLink
        ) {
            if (isLoadingInviteLink) {
                CircularProgressIndicator(
                    modifier = Modifier.size(18.dp),
                    strokeWidth = 2.dp,
                    color = BLPrimary
                )
            } else {
                Icon(
                    imageVector = Icons.Default.Share,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(if (isLoadingInviteLink) "Loading..." else "Share Invite Link")
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun EmptyStateBenefitRow(
    icon: ImageVector,
    color: androidx.compose.ui.graphics.Color,
    text: String
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = BLSurface,
        border = BorderStroke(1.dp, BLBorder)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(color.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = color
                )
            }

            Text(
                text = text,
                style = MaterialTheme.typography.bodyMedium,
                color = BLTextPrimary
            )
        }
    }
}

@Composable
private fun PendingFriendRequestCard(
    friend: Friend,
    onAccept: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = friend.friendUser.displayNameOrUsername,
                    style = MaterialTheme.typography.titleMedium
                )

                friend.friendUser.username?.let { username ->
                    Text(
                        text = "@$username",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = onAccept,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BLButtonGreen,
                        contentColor = androidx.compose.ui.graphics.Color.White
                    )
                ) {
                    Text("Accept")
                }

                OutlinedButton(
                    onClick = { /* Decline */ },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                ) {
                    Text("Decline")
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FriendCard(
    friend: Friend,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar placeholder
                Surface(
                    modifier = Modifier.size(48.dp),
                    shape = MaterialTheme.shapes.medium,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = friend.friendUser.displayNameOrUsername.take(1).uppercase(),
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }

                Column {
                    Text(
                        text = friend.friendUser.fullName,
                        style = MaterialTheme.typography.titleMedium
                    )

                    friend.friendUser.username?.let { username ->
                        Text(
                            text = "@$username",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View friend",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun AddFriendDialog(
    onDismiss: () -> Unit,
    onSendRequest: (email: String, username: String) -> Unit
) {
    var email by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.PersonAdd,
                contentDescription = null
            )
        },
        title = { Text("Invite Friend") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email address") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Text(
                    text = "We'll send an invite to this email. If they're already on ButtonLog, they'll get a friend request. If not, they'll receive an invitation to join.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onSendRequest(email, "") },
                enabled = email.isNotBlank() && email.contains("@")
            ) {
                Text("Send Invite")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
