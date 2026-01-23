package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.model.ButtonFormData
import com.buttonlog.app.data.model.ButtonType
import com.buttonlog.app.data.model.CreatedGiftButton
import com.buttonlog.app.ui.viewmodels.CreatedGiftButtonsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatedGiftButtonsScreen(
    onNavigateBack: () -> Unit = {},
    viewModel: CreatedGiftButtonsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var buttonToEdit by remember { mutableStateOf<CreatedGiftButton?>(null) }
    var buttonToDelete by remember { mutableStateOf<CreatedGiftButton?>(null) }

    LaunchedEffect(Unit) {
        viewModel.fetchCreatedGiftButtons()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Gift Buttons") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refreshCreatedGiftButtons() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading && !uiState.isRefreshing -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                uiState.giftButtons.isEmpty() && !uiState.isRefreshing -> {
                    EmptyGiftButtonsView()
                }

                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(uiState.giftButtons) { button ->
                            CreatedGiftButtonCard(
                                button = button,
                                onEdit = { buttonToEdit = button },
                                onDelete = { buttonToDelete = button }
                            )
                        }
                    }
                }
            }
        }
    }

    // Edit dialog
    buttonToEdit?.let { button ->
        EditGiftButtonDialog(
            button = button,
            onDismiss = { buttonToEdit = null },
            onSave = { formData ->
                viewModel.updateGiftButton(button.id, formData)
                buttonToEdit = null
            }
        )
    }

    // Delete confirmation dialog
    buttonToDelete?.let { button ->
        AlertDialog(
            onDismissRequest = { buttonToDelete = null },
            icon = {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = { Text("Delete Gift Button") },
            text = {
                Text("Are you sure you want to delete \"${button.name}\"? This will also remove it from ${button.recipientName ?: "your friend"}'s buttons.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteGiftButton(button.id)
                        buttonToDelete = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { buttonToDelete = null }) {
                    Text("Cancel")
                }
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

@Composable
private fun EmptyGiftButtonsView() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.CardGiftcard,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "No Gift Buttons Yet",
            style = MaterialTheme.typography.headlineMedium,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "When you create buttons for your friends,\nthey'll appear here so you can manage them.",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun CreatedGiftButtonCard(
    button: CreatedGiftButton,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Icon and color
                Box(
                    modifier = Modifier
                        .size(40.dp)
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

                Spacer(modifier = Modifier.width(12.dp))

                // Button info
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = button.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    button.description?.let { description ->
                        if (description.isNotEmpty()) {
                            Text(
                                text = description,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 1
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Tags row
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ButtonTypeTag(button.type)

                        button.recipientName?.let { recipientName ->
                            RecipientBadge(recipientName = recipientName)
                        }
                    }
                }

                // Menu button
                Box {
                    IconButton(onClick = { showMenu = true }) {
                        Icon(
                            imageVector = Icons.Default.MoreVert,
                            contentDescription = "Button options",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Edit") },
                            onClick = {
                                showMenu = false
                                onEdit()
                            },
                            leadingIcon = {
                                Icon(Icons.Default.Edit, contentDescription = null)
                            }
                        )

                        HorizontalDivider()

                        DropdownMenuItem(
                            text = { Text("Delete", color = MaterialTheme.colorScheme.error) },
                            onClick = {
                                showMenu = false
                                onDelete()
                            },
                            leadingIcon = {
                                Icon(
                                    Icons.Default.Delete,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        )
                    }
                }
            }

            // Gift message if present
            button.giftMessage?.let { message ->
                if (message.isNotEmpty()) {
                    Row(
                        modifier = Modifier.padding(start = 52.dp),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Icon(
                            imageVector = Icons.Default.FormatQuote,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = message,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            fontStyle = FontStyle.Italic,
                            maxLines = 2
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ButtonTypeTag(buttonType: ButtonType) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            text = buttonType.displayName,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Composable
private fun RecipientBadge(recipientName: String) {
    val purple = Color(0xFF9C27B0)
    Surface(
        color = purple.copy(alpha = 0.2f),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = purple,
                modifier = Modifier.size(12.dp)
            )
            Text(
                text = "For $recipientName",
                style = MaterialTheme.typography.labelSmall,
                color = purple
            )
        }
    }
}

@Composable
private fun EditGiftButtonDialog(
    button: CreatedGiftButton,
    onDismiss: () -> Unit,
    onSave: (ButtonFormData) -> Unit
) {
    var name by remember { mutableStateOf(button.name) }
    var description by remember { mutableStateOf(button.description ?: "") }
    var selectedIcon by remember { mutableStateOf(button.icon) }
    var selectedColor by remember { mutableStateOf(button.color) }
    var choices by remember { mutableStateOf(button.choices?.toMutableList() ?: mutableListOf()) }
    var showIconPicker by remember { mutableStateOf(false) }
    var showColorPicker by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Gift Button") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.verticalScroll(rememberScrollState())
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description (optional)") },
                    modifier = Modifier.fillMaxWidth()
                )

                // Icon selection
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Icon",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    IconButton(onClick = { showIconPicker = true }) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(parseColor(selectedColor)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = getIconForButton(selectedIcon),
                                contentDescription = "Selected icon",
                                tint = Color.White,
                                modifier = Modifier.size(24.dp)
                            )
                        }
                    }
                }

                // Color selection
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Color",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    IconButton(onClick = { showColorPicker = true }) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(parseColor(selectedColor))
                        )
                    }
                }

                // Choices section for one-time buttons
                if (button.type == ButtonType.ONE_TIME) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = "Choices (Optional)",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
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
                                        choices = choices.toMutableList().apply {
                                            this[index] = newValue
                                        }
                                    },
                                    label = { Text("Choice ${index + 1}") },
                                    singleLine = true,
                                    modifier = Modifier.weight(1f)
                                )
                                IconButton(
                                    onClick = {
                                        choices = choices.toMutableList().apply {
                                            removeAt(index)
                                        }
                                    }
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.RemoveCircle,
                                        contentDescription = "Remove choice",
                                        tint = MaterialTheme.colorScheme.error
                                    )
                                }
                            }
                        }

                        if (choices.size < 4) {
                            TextButton(
                                onClick = {
                                    choices = choices.toMutableList().apply {
                                        add("")
                                    }
                                }
                            ) {
                                Icon(
                                    imageVector = Icons.Default.AddCircle,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Add Choice")
                            }
                        }
                    }
                }

                // Show recipient info (read-only)
                button.recipientName?.let { recipientName ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp)
                        )
                        Text(
                            text = "For: $recipientName",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val formData = ButtonFormData(
                        name = name,
                        description = description,
                        type = button.type,
                        icon = selectedIcon,
                        color = selectedColor,
                        alertsEnabled = button.alertsEnabled,
                        autoStopEnabled = button.autoStopEnabled,
                        autoStopMinutes = button.autoStopMinutes,
                        calendarSyncEnabled = button.calendarSyncEnabled,
                        choices = choices.filter { it.isNotBlank() }.toMutableList()
                    )
                    onSave(formData)
                },
                enabled = name.isNotBlank()
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )

    // Icon picker dialog
    if (showIconPicker) {
        IconPickerDialog(
            selectedIcon = selectedIcon,
            onIconSelected = { icon ->
                selectedIcon = icon
                showIconPicker = false
            },
            onDismiss = { showIconPicker = false }
        )
    }

    // Color picker dialog
    if (showColorPicker) {
        ColorPickerDialog(
            selectedColor = selectedColor,
            onColorSelected = { color ->
                selectedColor = color
                showColorPicker = false
            },
            onDismiss = { showColorPicker = false }
        )
    }
}

@Composable
private fun IconPickerDialog(
    selectedIcon: String,
    onIconSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val icons = listOf(
        "star", "heart", "bolt", "flame", "leaf",
        "drop", "sun", "moon", "cloud", "snowflake",
        "car", "airplane", "gamecontroller", "book", "pencil",
        "scissors", "wrench", "hammer", "gear", "lock"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Icon") },
        text = {
            Column {
                for (row in icons.chunked(5)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        for (icon in row) {
                            IconButton(
                                onClick = { onIconSelected(icon) },
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (icon == selectedIcon)
                                            MaterialTheme.colorScheme.primaryContainer
                                        else
                                            Color.Transparent
                                    )
                            ) {
                                Icon(
                                    imageVector = getIconForButton(icon),
                                    contentDescription = icon,
                                    tint = if (icon == selectedIcon)
                                        MaterialTheme.colorScheme.onPrimaryContainer
                                    else
                                        MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
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

@Composable
private fun ColorPickerDialog(
    selectedColor: String,
    onColorSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val colors = listOf(
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9",
        "#F8B500", "#00CED1", "#FF69B4", "#32CD32", "#FF7F50",
        "#9370DB", "#20B2AA", "#FFD700", "#DC143C", "#4169E1"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Color") },
        text = {
            Column {
                for (row in colors.chunked(5)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        for (color in row) {
                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(parseColor(color))
                                    .clickable { onColorSelected(color) }
                                    .then(
                                        if (color.equals(selectedColor, ignoreCase = true))
                                            Modifier.border(3.dp, Color.White, CircleShape)
                                        else
                                            Modifier
                                    )
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
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

private fun parseColor(colorString: String): Color {
    return try {
        val hex = if (colorString.startsWith("#")) colorString else "#$colorString"
        Color(android.graphics.Color.parseColor(hex))
    } catch (e: Exception) {
        Color(0xFF007AFF)
    }
}

@Composable
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
        "cloud" -> Icons.Default.Cloud
        "snowflake" -> Icons.Default.AcUnit
        "car" -> Icons.Default.DirectionsCar
        "airplane" -> Icons.Default.Flight
        "gamecontroller" -> Icons.Default.SportsEsports
        "book" -> Icons.Default.Book
        "pencil" -> Icons.Default.Edit
        "scissors" -> Icons.Default.ContentCut
        "wrench" -> Icons.Default.Build
        "hammer" -> Icons.Default.Handyman
        "gear" -> Icons.Default.Settings
        "lock" -> Icons.Default.Lock
        else -> Icons.Default.Star
    }
}
