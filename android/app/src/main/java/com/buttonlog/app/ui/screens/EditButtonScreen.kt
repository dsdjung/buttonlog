package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonSharingSetting
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.Friend

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditButtonScreen(
    button: Button,
    sharingSettings: List<ButtonSharingSetting>,
    isLoadingSharing: Boolean,
    onSave: (Button, List<ButtonSharingSetting>) -> Unit,
    onNavigateBack: () -> Unit
) {
    var name by remember { mutableStateOf(button.name) }
    var description by remember { mutableStateOf(button.description ?: "") }
    var selectedIcon by remember { mutableStateOf(button.icon) }
    var selectedColor by remember { mutableStateOf(button.color) }
    var notificationsEnabled by remember { mutableStateOf(button.notificationsEnabled) }
    var localSharingSettings by remember(sharingSettings) { mutableStateOf(sharingSettings) }

    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Button") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            val updatedButton = button.copy(
                                name = name,
                                description = description.ifEmpty { null },
                                icon = selectedIcon,
                                color = selectedColor,
                                notificationsEnabled = notificationsEnabled
                            )
                            onSave(updatedButton, localSharingSettings)
                        },
                        enabled = name.isNotBlank()
                    ) {
                        Text("Save")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Name field
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Button Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Description field
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description (optional)") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4
            )

            // Icon selector
            Text(
                text = "Icon",
                style = MaterialTheme.typography.titleMedium
            )
            IconSelector(
                selectedIcon = selectedIcon,
                onIconSelected = { selectedIcon = it }
            )

            // Color selector
            Text(
                text = "Color",
                style = MaterialTheme.typography.titleMedium
            )
            ColorSelector(
                selectedColor = selectedColor,
                onColorSelected = { selectedColor = it }
            )

            // Settings
            Text(
                text = "Settings",
                style = MaterialTheme.typography.titleMedium
            )
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text("Notifications")
                        Text(
                            text = "Get notified when clicked",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = notificationsEnabled,
                        onCheckedChange = { notificationsEnabled = it }
                    )
                }
            }

            // Friend Sharing Section
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Share with Friends",
                style = MaterialTheme.typography.titleMedium
            )
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    if (isLoadingSharing) {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(modifier = Modifier.size(24.dp))
                        }
                    } else if (localSharingSettings.isEmpty()) {
                        Text(
                            text = "No friends to share with",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        localSharingSettings.forEachIndexed { index, setting ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = Icons.Default.Person,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column {
                                        Text(
                                            text = setting.friendDisplayName ?: setting.friendUsername,
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                        Text(
                                            text = "@${setting.friendUsername}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                                Switch(
                                    checked = setting.isShared,
                                    onCheckedChange = { isShared ->
                                        localSharingSettings = localSharingSettings.toMutableList().apply {
                                            this[index] = setting.copy(isShared = isShared)
                                        }
                                    }
                                )
                            }
                            if (index < localSharingSettings.lastIndex) {
                                HorizontalDivider()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun IconSelector(
    selectedIcon: String,
    onIconSelected: (String) -> Unit
) {
    val icons = listOf(
        "star" to Icons.Default.Star,
        "heart" to Icons.Default.Favorite,
        "bolt" to Icons.Default.Bolt,
        "flame" to Icons.Default.LocalFireDepartment,
        "leaf" to Icons.Default.Eco,
        "drop" to Icons.Default.Opacity,
        "sun" to Icons.Default.WbSunny,
        "moon" to Icons.Default.DarkMode,
        "car" to Icons.Default.DirectionsCar,
        "book" to Icons.Default.Book,
        "pencil" to Icons.Default.Edit,
        "gear" to Icons.Default.Settings
    )

    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(icons) { (name, icon) ->
            IconOption(
                icon = icon,
                isSelected = selectedIcon == name,
                onClick = { onIconSelected(name) }
            )
        }
    }
}

@Composable
private fun IconOption(
    icon: ImageVector,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape)
            .background(
                if (isSelected) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surfaceVariant
            )
            .border(
                width = if (isSelected) 2.dp else 0.dp,
                color = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent,
                shape = CircleShape
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (isSelected) MaterialTheme.colorScheme.primary
            else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ColorSelector(
    selectedColor: String,
    onColorSelected: (String) -> Unit
) {
    val colors = listOf(
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#00C7BE"  // Teal
    )

    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(colors) { color ->
            ColorOption(
                color = color,
                isSelected = selectedColor == color,
                onClick = { onColorSelected(color) }
            )
        }
    }
}

@Composable
private fun ColorOption(
    color: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val parsedColor = try {
        Color(android.graphics.Color.parseColor(color))
    } catch (e: Exception) {
        Color.Gray
    }

    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape)
            .background(parsedColor)
            .border(
                width = if (isSelected) 3.dp else 0.dp,
                color = MaterialTheme.colorScheme.onSurface,
                shape = CircleShape
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = Color.White
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateGiftButtonScreen(
    friend: Friend,
    isLoading: Boolean,
    error: String?,
    onCreateButton: (ButtonFormData, String?) -> Unit,
    onNavigateBack: () -> Unit
) {
    var name by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(ButtonType.ONE_TIME) }
    var selectedIcon by remember { mutableStateOf("star") }
    var selectedColor by remember { mutableStateOf("#007AFF") }
    var giftMessage by remember { mutableStateOf("") }

    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Gift Button") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            val formData = ButtonFormData(
                                name = name,
                                description = description,
                                type = selectedType,
                                icon = selectedIcon,
                                color = selectedColor,
                                notificationsEnabled = true,
                                autoStopEnabled = false,
                                calendarSyncEnabled = false
                            )
                            onCreateButton(formData, giftMessage.ifEmpty { null })
                        },
                        enabled = name.isNotBlank() && !isLoading
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Create")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Info card about gift button
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xFF9C27B0).copy(alpha = 0.1f)
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.CardGiftcard,
                            contentDescription = null,
                            tint = Color(0xFF9C27B0)
                        )
                        Text(
                            text = "Creating button for ${friend.friendUser.displayNameOrUsername}",
                            style = MaterialTheme.typography.titleSmall,
                            color = Color(0xFF9C27B0)
                        )
                    }
                    Text(
                        text = "This button will appear in ${friend.friendUser.displayNameOrUsername}'s button list. You'll be notified when they use it.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Error message
            error?.let { errorMessage ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = errorMessage,
                        modifier = Modifier.padding(16.dp),
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            }

            // Name field
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Button Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Description field
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description (optional)") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4
            )

            // Button type selector
            Text(
                text = "Button Type",
                style = MaterialTheme.typography.titleMedium
            )
            ButtonTypeSelector(
                selectedType = selectedType,
                onTypeSelected = { selectedType = it }
            )

            // Icon selector
            Text(
                text = "Icon",
                style = MaterialTheme.typography.titleMedium
            )
            IconSelector(
                selectedIcon = selectedIcon,
                onIconSelected = { selectedIcon = it }
            )

            // Color selector
            Text(
                text = "Color",
                style = MaterialTheme.typography.titleMedium
            )
            ColorSelector(
                selectedColor = selectedColor,
                onColorSelected = { selectedColor = it }
            )

            // Gift message
            Text(
                text = "Gift Message (optional)",
                style = MaterialTheme.typography.titleMedium
            )
            OutlinedTextField(
                value = giftMessage,
                onValueChange = { giftMessage = it },
                label = { Text("Add a message for your friend") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4
            )
        }
    }
}

@Composable
private fun ButtonTypeSelector(
    selectedType: ButtonType,
    onTypeSelected: (ButtonType) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ButtonType.values().forEach { type ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onTypeSelected(type) },
                colors = CardDefaults.cardColors(
                    containerColor = if (selectedType == type)
                        MaterialTheme.colorScheme.primaryContainer
                    else
                        MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = type.displayName,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = when (type) {
                                ButtonType.INSTANT -> "Click once to record"
                                ButtonType.TIMED -> "Track duration with start/stop"
                                ButtonType.STATE -> "Toggle on/off state"
                                ButtonType.ONE_TIME -> "Complete once, then automatically archived"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (selectedType == type) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
    }
}
