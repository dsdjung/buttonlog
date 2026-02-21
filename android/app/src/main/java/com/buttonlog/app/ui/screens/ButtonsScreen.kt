package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.ui.components.ButtonCard
import com.buttonlog.app.ui.components.UpgradePromptDialog
import com.buttonlog.app.ui.theme.BLSurfaceElevated
import com.buttonlog.app.ui.theme.BLTextTertiary
import com.buttonlog.app.ui.theme.StaggeredFadeIn
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ButtonsScreen(
    onCreateButton: () -> Unit,
    onEditButton: (com.buttonlog.app.data.model.Button) -> Unit = {},
    onViewHistory: (com.buttonlog.app.data.model.Button) -> Unit = {},
    onNavigateToAccount: () -> Unit = {},
    viewModel: ButtonsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var buttonToDelete by remember { mutableStateOf<com.buttonlog.app.data.model.Button?>(null) }
    var buttonForAlertSettings by remember { mutableStateOf<com.buttonlog.app.data.model.Button?>(null) }

    LaunchedEffect(Unit) {
        viewModel.fetchButtons()
    }

    // Load alert preferences when a button is selected for alert settings
    LaunchedEffect(buttonForAlertSettings) {
        buttonForAlertSettings?.let { button ->
            viewModel.loadButtonAlertPreferences(button.id)
        }
    }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Search bar
        SearchBar(
            query = uiState.searchQuery,
            onQueryChange = { viewModel.updateSearchQuery(it) },
            modifier = Modifier.padding(16.dp)
        )

        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refreshButtons() },
            modifier = Modifier.fillMaxSize()
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

                uiState.buttons.isEmpty() && !uiState.isRefreshing -> {
                    EmptyStateView(onCreateButton = onCreateButton)
                }

                else -> {
                    ButtonsList(
                        buttons = uiState.filteredButtons,
                        clickingButtonIds = uiState.clickingButtonIds,
                        streakData = uiState.streakData,
                        onButtonClick = { buttonId ->
                            viewModel.clickButton(buttonId)
                        },
                        onButtonClickWithChoice = { buttonId, choice ->
                            viewModel.clickButton(buttonId, choice)
                        },
                        onEditClick = { button ->
                            onEditButton(button)
                        },
                        onHistoryClick = { button ->
                            onViewHistory(button)
                        },
                        onAlertSettingsClick = { button ->
                            buttonForAlertSettings = button
                        },
                        onDeleteClick = { button ->
                            buttonToDelete = button
                        }
                    )
                }
            }
        }
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
            title = { Text("Delete Button") },
            text = { Text("Are you sure you want to delete \"${button.name}\"? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteButton(button.id)
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
            // Show error message (could be a snackbar or toast)
        }
    }

    // Alert settings dialog
    buttonForAlertSettings?.let { button ->
        AlertDialog(
            onDismissRequest = {
                buttonForAlertSettings = null
                viewModel.clearAlertPreferences()
            }
        ) {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.large
            ) {
                ButtonAlertSettingsScreen(
                    button = button,
                    alertPreferences = uiState.buttonAlertPreferences,
                    isLoading = uiState.isLoadingAlertPreferences,
                    error = uiState.alertPreferencesError,
                    onTogglePreference = { friendId, enabled ->
                        viewModel.toggleAlertPreference(button.id, friendId, enabled)
                    },
                    onSelectAll = {
                        viewModel.selectAllAlerts(button.id)
                    },
                    onDeselectAll = {
                        viewModel.deselectAllAlerts(button.id)
                    },
                    onDismiss = {
                        buttonForAlertSettings = null
                        viewModel.clearAlertPreferences()
                    }
                )
            }
        }
    }

    // Upgrade prompt dialog
    uiState.upgradeRequired?.let { upgradeInfo ->
        UpgradePromptDialog(
            upgradeInfo = upgradeInfo,
            onUpgrade = {
                viewModel.clearUpgradeRequired()
                onNavigateToAccount()
            },
            onDismiss = {
                viewModel.clearUpgradeRequired()
            }
        )
    }
}

@Composable
private fun EmptyStateView(onCreateButton: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Large outlined icon for minimal aesthetic
        Icon(
            imageVector = Icons.Outlined.AddCircleOutline,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = BLTextTertiary
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "No buttons yet",
            style = MaterialTheme.typography.displaySmall,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = "Create your first button to start tracking activities",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(32.dp))

        Button(
            onClick = onCreateButton,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            shape = RoundedCornerShape(12.dp)
        ) {
            Text(
                "Create Button",
                style = MaterialTheme.typography.labelLarge
            )
        }
    }
}

@Composable
private fun ButtonsList(
    buttons: List<com.buttonlog.app.data.model.Button>,
    clickingButtonIds: Set<String> = emptySet(),
    streakData: com.buttonlog.app.data.model.StreakData? = null,
    onButtonClick: (String) -> Unit,
    onButtonClickWithChoice: (String, String) -> Unit,
    onEditClick: (com.buttonlog.app.data.model.Button) -> Unit,
    onHistoryClick: (com.buttonlog.app.data.model.Button) -> Unit,
    onAlertSettingsClick: (com.buttonlog.app.data.model.Button) -> Unit,
    onDeleteClick: (com.buttonlog.app.data.model.Button) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Streak card at the top
        if (streakData != null && streakData.totalActiveDays > 0) {
            item {
                StreakCard(streakData = streakData)
            }
        }

        itemsIndexed(buttons) { index, button ->
            // Staggered fade-in animation for polished appearance
            StaggeredFadeIn(index = index) {
                ButtonCard(
                    button = button,
                    onClick = { onButtonClick(button.id) },
                    onClickWithChoice = { choice -> onButtonClickWithChoice(button.id, choice) },
                    onEditClick = { onEditClick(button) },
                    onHistoryClick = { onHistoryClick(button) },
                    onAlertSettingsClick = if (button.isOwner) {{ onAlertSettingsClick(button) }} else null,
                    onDeleteClick = { onDeleteClick(button) },
                    isClicking = clickingButtonIds.contains(button.id)
                )
            }
        }
    }
}

@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    // Pill-shaped minimal search bar
    TextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = {
            Text(
                "Search buttons...",
                style = MaterialTheme.typography.bodyMedium,
                color = BLTextTertiary
            )
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "Search",
                modifier = Modifier.size(18.dp),
                tint = BLTextTertiary
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(
                        imageVector = Icons.Default.Clear,
                        contentDescription = "Clear search",
                        modifier = Modifier.size(18.dp),
                        tint = BLTextTertiary
                    )
                }
            }
        },
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp)),
        singleLine = true,
        textStyle = MaterialTheme.typography.bodyMedium,
        colors = TextFieldDefaults.colors(
            unfocusedContainerColor = BLSurfaceElevated,
            focusedContainerColor = BLSurfaceElevated,
            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent
        )
    )
}

@Composable
private fun StreakCard(streakData: com.buttonlog.app.data.model.StreakData) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Streak emoji and count
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.width(80.dp)
            ) {
                Text(
                    text = streakData.streakEmoji,
                    style = MaterialTheme.typography.headlineLarge
                )
                Text(
                    text = "${streakData.currentStreak}",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "day streak",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Divider(
                modifier = Modifier
                    .height(50.dp)
                    .width(1.dp),
                color = MaterialTheme.colorScheme.outline
            )

            // Stats
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.EmojiEvents,
                        contentDescription = null,
                        tint = androidx.compose.ui.graphics.Color(0xFFFFD700),
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "Longest: ${streakData.longestStreak} days",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.CalendarToday,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "Total: ${streakData.totalActiveDays} active days",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

