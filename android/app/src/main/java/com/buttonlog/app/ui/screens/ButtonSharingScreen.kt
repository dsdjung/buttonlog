package com.buttonlog.app.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ButtonSharingScreen(
    button: Button,
    collaborators: List<ButtonCollaborator>,
    friends: List<Friend>,
    isLoading: Boolean,
    isSaving: Boolean,
    errorMessage: String?,
    shareToken: String?,
    onSharingModeChange: (SharingMode) -> Unit,
    onAddCollaborator: (Friend) -> Unit,
    onRemoveCollaborator: (ButtonCollaborator) -> Unit,
    onGenerateShareLink: () -> Unit,
    onRevokeShareLink: () -> Unit,
    onNavigateBack: () -> Unit
) {
    var selectedMode by remember { mutableStateOf(button.sharingMode ?: SharingMode.PRIVATE) }
    var showAddCollaboratorDialog by remember { mutableStateOf(false) }
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sharing") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Error message
                errorMessage?.let { error ->
                    item {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer
                            )
                        ) {
                            Text(
                                text = error,
                                modifier = Modifier.padding(16.dp),
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }

                // Sharing mode section
                item {
                    Text(
                        text = "Who can click this button?",
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                items(SharingMode.entries) { mode ->
                    SharingModeOption(
                        mode = mode,
                        isSelected = selectedMode == mode,
                        enabled = !isSaving,
                        onSelect = {
                            selectedMode = mode
                            onSharingModeChange(mode)
                        }
                    )
                }

                // Collaborators section (for invite_only mode)
                if (selectedMode == SharingMode.INVITE_ONLY) {
                    item {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Collaborators",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }

                    if (collaborators.isEmpty()) {
                        item {
                            Text(
                                text = "No collaborators added yet",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else {
                        items(collaborators) { collaborator ->
                            CollaboratorItem(
                                collaborator = collaborator,
                                onRemove = { onRemoveCollaborator(collaborator) },
                                enabled = !isSaving
                            )
                        }
                    }

                    item {
                        OutlinedButton(
                            onClick = { showAddCollaboratorDialog = true },
                            enabled = !isSaving
                        ) {
                            Icon(Icons.Default.PersonAdd, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Add Collaborator")
                        }
                    }

                    item {
                        Text(
                            text = "Collaborators can click this button. Only your friends can be added.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Public link section (for public mode)
                if (selectedMode == SharingMode.PUBLIC) {
                    item {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Public Link",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }

                    item {
                        ShareLinkSection(
                            shareToken = shareToken,
                            isSaving = isSaving,
                            onGenerateLink = onGenerateShareLink,
                            onRevokeLink = onRevokeShareLink,
                            onCopyLink = { token ->
                                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                val clip = ClipData.newPlainText("Share Link", "https://buttonlog.app/join/$token")
                                clipboard.setPrimaryClip(clip)
                                Toast.makeText(context, "Link copied!", Toast.LENGTH_SHORT).show()
                            }
                        )
                    }

                    item {
                        Text(
                            text = "Anyone with the link can click this button, even if they don't have an account.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }

    // Add collaborator dialog
    if (showAddCollaboratorDialog) {
        AddCollaboratorDialog(
            friends = friends,
            existingCollaboratorIds = collaborators.map { it.userId }.toSet(),
            onDismiss = { showAddCollaboratorDialog = false },
            onSelect = { friend ->
                onAddCollaborator(friend)
                showAddCollaboratorDialog = false
            }
        )
    }
}

@Composable
fun SharingModeOption(
    mode: SharingMode,
    isSelected: Boolean,
    enabled: Boolean,
    onSelect: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(
                selected = isSelected,
                enabled = enabled,
                role = Role.RadioButton,
                onClick = onSelect
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            }
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = when (mode) {
                    SharingMode.PRIVATE -> Icons.Default.Lock
                    SharingMode.FRIENDS -> Icons.Default.People
                    SharingMode.INVITE_ONLY -> Icons.Default.Email
                    SharingMode.PUBLIC -> Icons.Default.Link
                },
                contentDescription = null,
                tint = if (isSelected) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = mode.displayName,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = mode.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            RadioButton(
                selected = isSelected,
                onClick = null,
                enabled = enabled
            )
        }
    }
}

@Composable
fun CollaboratorItem(
    collaborator: ButtonCollaborator,
    onRemove: () -> Unit,
    enabled: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.width(12.dp))

            Text(
                text = collaborator.displayName,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.weight(1f)
            )

            IconButton(
                onClick = onRemove,
                enabled = enabled
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Remove",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}

@Composable
fun ShareLinkSection(
    shareToken: String?,
    isSaving: Boolean,
    onGenerateLink: () -> Unit,
    onRevokeLink: () -> Unit,
    onCopyLink: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (shareToken != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Link,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Share link active",
                        style = MaterialTheme.typography.titleSmall
                    )
                }

                Text(
                    text = "https://buttonlog.app/join/$shareToken",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = { onCopyLink(shareToken) },
                        enabled = !isSaving
                    ) {
                        Icon(Icons.Default.ContentCopy, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Copy Link")
                    }

                    OutlinedButton(
                        onClick = onRevokeLink,
                        enabled = !isSaving,
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Revoke")
                    }
                }
            } else {
                Button(
                    onClick = onGenerateLink,
                    enabled = !isSaving
                ) {
                    Icon(Icons.Default.AddLink, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Generate Share Link")
                }
            }
        }
    }
}

@Composable
fun AddCollaboratorDialog(
    friends: List<Friend>,
    existingCollaboratorIds: Set<String>,
    onDismiss: () -> Unit,
    onSelect: (Friend) -> Unit
) {
    val availableFriends = friends.filter { friend ->
        friend.status == FriendshipStatus.ACCEPTED && friend.friendId !in existingCollaboratorIds
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Collaborator") },
        text = {
            if (availableFriends.isEmpty()) {
                Text("No friends available to add")
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(availableFriends) { friend ->
                        Card(
                            onClick = { onSelect(friend) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Person,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary
                                )

                                Spacer(modifier = Modifier.width(12.dp))

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = friend.friendUser.displayName ?: friend.friendUser.username,
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    if (friend.friendUser.displayName != null) {
                                        Text(
                                            text = "@${friend.friendUser.username}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }

                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = "Add",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
