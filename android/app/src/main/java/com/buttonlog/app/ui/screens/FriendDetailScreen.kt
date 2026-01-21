package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
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
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendButton
import com.buttonlog.app.data.model.FriendActivity
import com.buttonlog.app.data.model.FriendPermissionUpdate
import com.buttonlog.app.ui.viewmodels.FriendsUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendDetailScreen(
    friend: Friend,
    uiState: FriendsUiState,
    onNavigateBack: () -> Unit,
    onRemoveFriend: (String) -> Unit,
    onUpdatePermissions: (String, FriendPermissionUpdate) -> Unit,
    onLoadMoreActivity: () -> Unit = {}
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

            // Activity History section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Activity History",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            when {
                uiState.isLoadingFriendActivity && uiState.friendActivity.isEmpty() -> {
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

                uiState.activityPermissionDenied -> {
                    item {
                        ActivityPermissionDeniedCard(friendName = friend.friendUser.displayNameOrUsername)
                    }
                }

                uiState.friendActivity.isEmpty() -> {
                    item {
                        EmptyActivityCard(friendName = friend.friendUser.displayNameOrUsername)
                    }
                }

                else -> {
                    itemsIndexed(uiState.friendActivity) { index, activity ->
                        FriendActivityCard(activity = activity)

                        // Load more when reaching the end
                        if (index == uiState.friendActivity.lastIndex && uiState.activityHasMore && !uiState.isLoadingMoreActivity) {
                            LaunchedEffect(Unit) {
                                onLoadMoreActivity()
                            }
                        }
                    }

                    // Loading more indicator
                    if (uiState.isLoadingMoreActivity) {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(modifier = Modifier.size(24.dp))
                            }
                        }
                    } else if (uiState.activityHasMore) {
                        item {
                            TextButton(
                                onClick = onLoadMoreActivity,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Load More")
                            }
                        }
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
private fun FriendButtonCard(button: FriendButton) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Top row: Icon, name, type, and state
            Row(
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

                // State indicator for state/timed buttons
                if (button.type != ButtonType.INSTANT) {
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

            // Latest activity section
            HorizontalDivider()

            if (button.latestClickAt != null) {
                // Last activity time and action
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "Last activity:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = button.latestClickAt.take(16).replace("T", " "),
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium
                    )
                    button.latestClickAction?.let { action ->
                        Surface(
                            color = getActionBadgeColor(action),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = action,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Medium,
                                color = getActionTextColor(action),
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }

                // Location if available
                button.latestClickLocation?.let { location ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = formatCoordinates(location.lat, location.lng),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Device/platform info
                if (button.latestClickDevice != null || button.latestClickPlatform != null) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = getPlatformIcon(button.latestClickPlatform),
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        button.latestClickDevice?.let { device ->
                            Text(
                                text = device,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        button.latestClickPlatform?.let { platform ->
                            Text(
                                text = "($platform)",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            } else {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "No activity yet",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                    )
                }
            }
        }
    }
}

private fun formatCoordinates(lat: Double, lng: Double): String {
    val latDir = if (lat >= 0) "N" else "S"
    val lngDir = if (lng >= 0) "E" else "W"
    return String.format("%.4f°%s %.4f°%s", kotlin.math.abs(lat), latDir, kotlin.math.abs(lng), lngDir)
}

private fun getPlatformIcon(platform: String?): ImageVector {
    return when (platform) {
        "iphone" -> Icons.Default.PhoneIphone
        "android" -> Icons.Default.PhoneAndroid
        "web" -> Icons.Default.Language
        else -> Icons.Default.Devices
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

@Composable
private fun FriendActivityCard(activity: FriendActivity) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Button icon
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(parseColor(activity.buttonColor ?: "#007AFF")),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = activity.buttonTypeEmoji,
                    style = MaterialTheme.typography.titleMedium
                )
            }

            // Activity info
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = activity.buttonName,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold
                    )

                    // Action badge
                    Surface(
                        color = getActionBadgeColor(activity.displayAction),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = activity.displayAction,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Medium,
                            color = getActionTextColor(activity.displayAction),
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = activity.clickedAt.take(16).replace("T", " "),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    activity.duration?.let { duration ->
                        Text(
                            text = "•",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "${duration}s",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ActivityPermissionDeniedCard(friendName: String) {
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
                imageVector = Icons.Default.Lock,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Activity History Private",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Text(
                text = "$friendName has not granted you permission to view their activity history",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun EmptyActivityCard(friendName: String) {
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
                imageVector = Icons.Default.Schedule,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "No Activity Yet",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Text(
                text = "$friendName hasn't recorded any button activity yet",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

private fun parseColor(colorString: String): Color {
    return try {
        Color(android.graphics.Color.parseColor(colorString))
    } catch (e: Exception) {
        Color(0xFF007AFF)
    }
}

private fun getActionBadgeColor(action: String): Color {
    return when (action) {
        "start" -> Color(0xFF34C759).copy(alpha = 0.2f)
        "end" -> Color(0xFFFF3B30).copy(alpha = 0.2f)
        else -> Color(0xFF007AFF).copy(alpha = 0.2f)
    }
}

private fun getActionTextColor(action: String): Color {
    return when (action) {
        "start" -> Color(0xFF34C759)
        "end" -> Color(0xFFFF3B30)
        else -> Color(0xFF007AFF)
    }
}
