package com.buttonlog.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.ui.components.ButtonCard
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ButtonsScreen(
    onCreateButton: () -> Unit,
    onEditButton: (com.buttonlog.app.data.model.Button) -> Unit = {},
    onViewHistory: (com.buttonlog.app.data.model.Button) -> Unit = {},
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

        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            uiState.buttons.isEmpty() -> {
                EmptyStateView(onCreateButton = onCreateButton)
            }

            else -> {
                ButtonsList(
                    buttons = uiState.filteredButtons,
                    onButtonClick = { buttonId ->
                        viewModel.clickButton(buttonId)
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
        Icon(
            imageVector = Icons.Default.AddCircle,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "No buttons yet",
            style = MaterialTheme.typography.headlineMedium,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Create your first button to start tracking activities",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onCreateButton,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Create Button")
        }
    }
}

@Composable
private fun ButtonsList(
    buttons: List<com.buttonlog.app.data.model.Button>,
    onButtonClick: (String) -> Unit,
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
        items(buttons) { button ->
            ButtonCard(
                button = button,
                onClick = { onButtonClick(button.id) },
                onEditClick = { onEditClick(button) },
                onHistoryClick = { onHistoryClick(button) },
                onAlertSettingsClick = if (button.isOwner) {{ onAlertSettingsClick(button) }} else null,
                onDeleteClick = { onDeleteClick(button) }
            )
        }
    }
}

@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text("Search buttons...") },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "Search"
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(
                        imageVector = Icons.Default.Clear,
                        contentDescription = "Clear search"
                    )
                }
            }
        },
        modifier = modifier.fillMaxWidth(),
        singleLine = true
    )
}

