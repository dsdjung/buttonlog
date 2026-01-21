package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.ui.viewmodels.FriendsUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendDetailScreen(
    friend: Friend,
    uiState: FriendsUiState,
    onNavigateBack: () -> Unit,
    onRemoveFriend: (String) -> Unit,
    onUpdatePermissions: (String, FriendPermissionUpdate) -> Unit
) {
    var showRemoveDialog by remember { mutableStateOf(false) }
    var canSeeButtons by remember { mutableStateOf(friend.permissions.canSeeButtons) }
    var canSeeActivity by remember { mutableStateOf(friend.permissions.canSeeActivity) }
    var receiveNotifications by remember { mutableStateOf(friend.permissions.receiveNotifications) }
    var canComment by remember { mutableStateOf(friend.permissions.canComment) }

    // Update local state when permissions are loaded
    LaunchedEffect(uiState.selectedFriendPermissions) {
        uiState.selectedFriendPermissions?.let { permissions ->
            canSeeButtons = permissions.canSeeButtons
            canSeeActivity = permissions.canSeeActivity
            receiveNotifications = permissions.receiveNotifications
            canComment = permissions.canComment
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Friend Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Friend info card
            item {
                FriendInfoCard(friend = friend)
            }

            // Friend's buttons section
            item {
                Text(
                    text = "Buttons",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            when {
                uiState.isLoadingFriendButtons -> {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(100.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                }

                uiState.friendButtons.isEmpty() -> {
                    item {
                        EmptyButtonsCard()
                    }
                }

                else -> {
                    items(uiState.friendButtons) { button ->
                        FriendButtonCard(button = button)
                    }
                }
            }

            // Permissions section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Permissions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        PermissionToggle(
                            label = "Can see your buttons",
                            checked = canSeeButtons,
                            onCheckedChange = {
                                canSeeButtons = it
                                onUpdatePermissions(
                                    friend.friendId,
                                    FriendPermissionUpdate(
                                        canSeeButtons = it,
                                        canSeeActivity = canSeeActivity,
                                        receiveNotifications = receiveNotifications,
                                        canComment = canComment
                                    )
                                )
                            }
                        )

                        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                        PermissionToggle(
                            label = "Can see your activity",
                            checked = canSeeActivity,
                            onCheckedChange = {
                                canSeeActivity = it
                                onUpdatePermissions(
                                    friend.friendId,
                                    FriendPermissionUpdate(
                                        canSeeButtons = canSeeButtons,
                                        canSeeActivity = it,
                                        receiveNotifications = receiveNotifications,
                                        canComment = canComment
                                    )
                                )
                            }
                        )

                        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                        PermissionToggle(
                            label = "Receive notifications",
                            checked = receiveNotifications,
                            onCheckedChange = {
                                receiveNotifications = it
                                onUpdatePermissions(
                                    friend.friendId,
                                    FriendPermissionUpdate(
                                        canSeeButtons = canSeeButtons,
                                        canSeeActivity = canSeeActivity,
                                        receiveNotifications = it,
                                        canComment = canComment
                                    )
                                )
                            }
                        )

                        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                        PermissionToggle(
                            label = "Can comment",
                            checked = canComment,
                            onCheckedChange = {
                                canComment = it
                                onUpdatePermissions(
                                    friend.friendId,
                                    FriendPermissionUpdate(
                                        canSeeButtons = canSeeButtons,
                                        canSeeActivity = canSeeActivity,
                                        receiveNotifications = receiveNotifications,
                                        canComment = it
                                    )
                                )
                            }
                        )
                    }
                }
            }

            // Remove friend button
            item {
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedButton(
                    onClick = { showRemoveDialog = true },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.PersonRemove,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Remove Friend")
                }
            }
        }
    }

    // Remove friend confirmation dialog
    if (showRemoveDialog) {
        AlertDialog(
            onDismissRequest = { showRemoveDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Default.PersonRemove,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = { Text("Remove Friend") },
            text = {
                Text("Are you sure you want to remove ${friend.friendUser.displayNameOrUsername} as a friend?")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onRemoveFriend(friend.id)
                        showRemoveDialog = false
                        onNavigateBack()
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Remove")
                }
            },
            dismissButton = {
                TextButton(onClick = { showRemoveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun FriendInfoCard(friend: Friend) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Avatar
            Surface(
                modifier = Modifier.size(72.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primaryContainer
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = friend.friendUser.displayNameOrUsername.take(1).uppercase(),
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = friend.friendUser.fullName,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold
            )

            friend.friendUser.username?.let { username ->
                Text(
                    text = "@$username",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Friends since ${friend.createdAt.take(10)}", // Simple date extraction
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun FriendButtonCard(button: Button) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Button icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(button.uiColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIconForButton(button.icon),
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Button info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = button.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = button.type.displayName,
                            style = MaterialTheme.typography.labelSmall,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }

                }
            }

            // State indicator for state/timed buttons
            if (button.type != com.buttonlog.app.data.model.ButtonType.INSTANT) {
                Surface(
                    color = if (button.currentState == ButtonState.ACTIVE)
                        Color(0xFF34C759).copy(alpha = 0.2f)
                    else
                        MaterialTheme.colorScheme.surfaceVariant,
                    shape = RoundedCornerShape(6.dp)
                ) {
                    Text(
                        text = if (button.currentState == ButtonState.ACTIVE) "Active" else "Idle",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Medium,
                        color = if (button.currentState == ButtonState.ACTIVE)
                            Color(0xFF34C759)
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun EmptyButtonsCard() {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.ViewModule,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "No buttons yet",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Text(
                text = "This friend hasn't created any buttons",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun PermissionToggle(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

private fun getIconForButton(iconName: String): ImageVector {
    return when (iconName) {
        "star" -> Icons.Default.Star
        "heart" -> Icons.Default.Favorite
        "bolt" -> Icons.Default.Bolt
        "flame" -> Icons.Default.LocalFireDepartment
        "leaf" -> Icons.Default.Eco
        "drop" -> Icons.Default.Opacity
        "sun" -> Icons.Default.WbSunny
        "moon" -> Icons.Default.DarkMode
        "car" -> Icons.Default.DirectionsCar
        "book" -> Icons.Default.Book
        "pencil" -> Icons.Default.Edit
        "gear" -> Icons.Default.Settings
        else -> Icons.Default.Star
    }
}
