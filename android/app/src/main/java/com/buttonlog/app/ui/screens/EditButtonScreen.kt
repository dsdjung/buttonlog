package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.ui.theme.*
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonSharingSetting
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.Friend
import com.buttonlog.app.data.model.FriendAlertMode

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
    var alertsEnabled by remember { mutableStateOf(button.alertsEnabled) }
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
                                alertsEnabled = alertsEnabled
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
                        Text("Alerts")
                        Text(
                            text = "Send alerts when clicked",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = alertsEnabled,
                        onCheckedChange = { alertsEnabled = it }
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
fun CreateButtonScreen(
    isLoading: Boolean,
    error: String?,
    friends: List<Friend> = emptyList(),
    showSuccess: Boolean = false,
    createdButtonName: String = "",
    onCreateButton: (ButtonFormData) -> Unit,
    onNavigateBack: () -> Unit,
    onSuccessInviteFriend: () -> Unit = {},
    onSuccessDone: () -> Unit = {}
) {
    var name by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(ButtonType.INSTANT) }
    var selectedIcon by remember { mutableStateOf("star") }
    var selectedColor by remember { mutableStateOf("#007AFF") }
    var alertsEnabled by remember { mutableStateOf(true) }
    var autoStopEnabled by remember { mutableStateOf(false) }
    var autoStopMinutes by remember { mutableStateOf<Int?>(null) }
    var choices by remember { mutableStateOf(mutableListOf("", "")) }
    var friendAlertMode by remember { mutableStateOf(FriendAlertMode.NONE) }
    var selectedFriendIds by remember { mutableStateOf(mutableSetOf<String>()) }

    val scrollState = rememberScrollState()

    // Reset choices when type changes
    LaunchedEffect(selectedType) {
        if (selectedType != ButtonType.ONE_TIME) {
            choices = mutableListOf("", "")
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Button") },
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
                                alertsEnabled = alertsEnabled,
                                autoStopEnabled = autoStopEnabled,
                                autoStopMinutes = autoStopMinutes,
                                calendarSyncEnabled = false,
                                choices = if (selectedType == ButtonType.ONE_TIME) {
                                    choices.filter { it.trim().isNotEmpty() }.toMutableList()
                                } else {
                                    mutableListOf()
                                },
                                friendAlertMode = friendAlertMode,
                                selectedFriendIds = selectedFriendIds.toMutableList()
                            )
                            onCreateButton(formData)
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

            // Quick Templates
            QuickTemplatesSection(
                onTemplateSelected = { templateType, templateChoices ->
                    selectedType = templateType
                    choices = templateChoices.toMutableList()
                }
            )

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

            // Choices section (only for one-time buttons)
            if (selectedType == ButtonType.ONE_TIME) {
                ChoicesSection(
                    choices = choices,
                    onChoicesChange = { choices = it.toMutableList() }
                )
            }

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
                Column {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Alerts")
                            Text(
                                text = "Send alerts when clicked",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Switch(
                            checked = alertsEnabled,
                            onCheckedChange = { alertsEnabled = it }
                        )
                    }

                    // Auto-stop toggle (only for toggle type)
                    if (selectedType == ButtonType.TOGGLE) {
                        HorizontalDivider()
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Auto-Stop")
                                Text(
                                    text = "Automatically stop after duration",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Switch(
                                checked = autoStopEnabled,
                                onCheckedChange = { autoStopEnabled = it }
                            )
                        }

                        // Auto-stop duration selector
                        if (autoStopEnabled) {
                            AutoStopDurationSelector(
                                selectedMinutes = autoStopMinutes,
                                onMinutesSelected = { autoStopMinutes = it }
                            )
                        }
                    }
                }
            }

            // Friend Notifications Section (only if user has friends)
            if (friends.isNotEmpty()) {
                FriendNotificationsSection(
                    friends = friends,
                    friendAlertMode = friendAlertMode,
                    selectedFriendIds = selectedFriendIds,
                    onModeChange = { friendAlertMode = it },
                    onFriendToggle = { friendId, isSelected ->
                        selectedFriendIds = if (isSelected) {
                            (selectedFriendIds + friendId).toMutableSet()
                        } else {
                            (selectedFriendIds - friendId).toMutableSet()
                        }
                    }
                )
            }
        }
    }

    // Success dialog
    if (showSuccess) {
        ButtonCreatedSuccessDialog(
            buttonName = createdButtonName,
            onInviteFriend = onSuccessInviteFriend,
            onDone = onSuccessDone
        )
    }
}

@Composable
private fun ChoicesSection(
    choices: List<String>,
    onChoicesChange: (List<String>) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Choices (Optional)",
                style = MaterialTheme.typography.titleMedium
            )
            if (choices.size < 10) {
                TextButton(onClick = {
                    onChoicesChange(choices + "")
                }) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Add Choice")
                }
            }
        }

        Text(
            text = "Add 2 or more choices to create a multiple choice button",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        choices.forEachIndexed { index, choice ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = choice,
                    onValueChange = { newValue ->
                        val newChoices = choices.toMutableList()
                        newChoices[index] = newValue
                        onChoicesChange(newChoices)
                    },
                    label = { Text("Choice ${index + 1}") },
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
                if (choices.size > 2) {
                    IconButton(onClick = {
                        val newChoices = choices.toMutableList()
                        newChoices.removeAt(index)
                        onChoicesChange(newChoices)
                    }) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Remove choice",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun AutoStopDurationSelector(
    selectedMinutes: Int?,
    onMinutesSelected: (Int?) -> Unit
) {
    val options = Button.AUTO_STOP_OPTIONS

    Column(
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "Duration",
            style = MaterialTheme.typography.bodyMedium
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            options.take(3).forEach { (minutes, label) ->
                FilterChip(
                    selected = selectedMinutes == minutes,
                    onClick = { onMinutesSelected(minutes) },
                    label = { Text(label) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            options.drop(3).forEach { (minutes, label) ->
                FilterChip(
                    selected = selectedMinutes == minutes,
                    onClick = { onMinutesSelected(minutes) },
                    label = { Text(label) },
                    modifier = Modifier.weight(1f)
                )
            }
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
    var choices by remember { mutableStateOf(mutableListOf("", "")) }

    val scrollState = rememberScrollState()

    // Reset choices when type changes
    LaunchedEffect(selectedType) {
        if (selectedType != ButtonType.ONE_TIME) {
            choices = mutableListOf("", "")
        }
    }

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
                                alertsEnabled = true,
                                autoStopEnabled = false,
                                calendarSyncEnabled = false,
                                choices = if (selectedType == ButtonType.ONE_TIME) {
                                    choices.filter { it.trim().isNotEmpty() }.toMutableList()
                                } else {
                                    mutableListOf()
                                }
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

            // Quick Templates
            QuickTemplatesSection(
                onTemplateSelected = { templateType, templateChoices ->
                    selectedType = templateType
                    choices = templateChoices.toMutableList()
                }
            )

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

            // Choices section (only for one-time buttons)
            if (selectedType == ButtonType.ONE_TIME) {
                ChoicesSection(
                    choices = choices,
                    onChoicesChange = { choices = it.toMutableList() }
                )
            }

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
                                ButtonType.TOGGLE -> "Start/stop with duration tracking"
                                ButtonType.ONE_TIME -> "Complete once, then automatically archived"
                                ButtonType.WORKFLOW -> "Predefined sequence of states"
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

@Composable
private fun QuickTemplatesSection(
    onTemplateSelected: (ButtonType, List<String>) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Quick Templates",
            style = MaterialTheme.typography.titleMedium
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            TemplateChip(
                title = "Yes/No",
                icon = Icons.Default.HelpOutline,
                color = Color(0xFF9C27B0),
                onClick = { onTemplateSelected(ButtonType.ONE_TIME, listOf("Yes", "No")) },
                modifier = Modifier.weight(1f)
            )

            TemplateChip(
                title = "Done/Skip",
                icon = Icons.Default.CheckCircleOutline,
                color = Color(0xFF4CAF50),
                onClick = { onTemplateSelected(ButtonType.ONE_TIME, listOf("Done", "Skip")) },
                modifier = Modifier.weight(1f)
            )

            TemplateChip(
                title = "Rating",
                icon = Icons.Default.Star,
                color = Color(0xFF2196F3),
                onClick = { onTemplateSelected(ButtonType.ONE_TIME, listOf("Good", "Okay", "Bad")) },
                modifier = Modifier.weight(1f)
            )
        }

        Text(
            text = "Or create a custom button below",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TemplateChip(
    title: String,
    icon: ImageVector,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .clickable(onClick = onClick),
        shape = MaterialTheme.shapes.medium,
        color = color.copy(alpha = 0.1f),
        border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.3f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = color
            )
        }
    }
}

@Composable
private fun FriendNotificationsSection(
    friends: List<Friend>,
    friendAlertMode: FriendAlertMode,
    selectedFriendIds: Set<String>,
    onModeChange: (FriendAlertMode) -> Unit,
    onFriendToggle: (String, Boolean) -> Unit
) {
    var isExpanded by remember { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // Collapsible header
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { isExpanded = !isExpanded }
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
                    Icon(
                        imageVector = Icons.Default.Notifications,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Column {
                        Text(
                            text = "Friend Notifications (Optional)",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            text = "Notify friends when you click this button",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Icon(
                    imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = if (isExpanded) "Collapse" else "Expand"
                )
            }
        }

        // Expandable content
        if (isExpanded) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Mode selection
                    FriendAlertMode.values().forEach { mode ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onModeChange(mode) }
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = mode.displayName,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Text(
                                    text = mode.description,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            RadioButton(
                                selected = friendAlertMode == mode,
                                onClick = { onModeChange(mode) }
                            )
                        }
                    }

                    // Friend selection (only when SELECT_SPECIFIC is chosen)
                    if (friendAlertMode == FriendAlertMode.SELECT_SPECIFIC) {
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))
                        Text(
                            text = "Select Friends",
                            style = MaterialTheme.typography.titleSmall,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )

                        friends.forEach { friend ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        onFriendToggle(
                                            friend.friendId,
                                            !selectedFriendIds.contains(friend.friendId)
                                        )
                                    }
                                    .padding(vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Person,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        text = friend.friendUser.displayNameOrUsername,
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                }
                                Checkbox(
                                    checked = selectedFriendIds.contains(friend.friendId),
                                    onCheckedChange = { isChecked ->
                                        onFriendToggle(friend.friendId, isChecked)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Post-Create Success Dialog

@Composable
fun ButtonCreatedSuccessDialog(
    buttonName: String,
    onInviteFriend: () -> Unit,
    onDone: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDone,
        confirmButton = {
            Button(
                onClick = onInviteFriend,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = BLPrimary)
            ) {
                Icon(
                    imageVector = Icons.Default.PersonAdd,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Invite a Friend")
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDone,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    "Maybe Later",
                    color = BLTextSecondary
                )
            }
        },
        title = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Success icon
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(BLSuccess.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(40.dp),
                        tint = BLSuccess
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Button Created!",
                    style = MaterialTheme.typography.headlineSmall,
                    color = BLTextPrimary,
                    textAlign = TextAlign.Center
                )
            }
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "\"$buttonName\" is ready to track",
                    style = MaterialTheme.typography.bodyMedium,
                    color = BLTextSecondary,
                    textAlign = TextAlign.Center
                )

                // Social prompt card
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    color = BLSurface,
                    border = androidx.compose.foundation.BorderStroke(1.dp, BLBorder)
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(BLPrimary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.People,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp),
                                tint = BLPrimary
                            )
                        }

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Better with a Friend",
                                style = MaterialTheme.typography.titleSmall,
                                color = BLTextPrimary
                            )
                            Text(
                                text = "Invite someone to keep you accountable",
                                style = MaterialTheme.typography.bodySmall,
                                color = BLTextSecondary
                            )
                        }
                    }
                }
            }
        }
    )
}
