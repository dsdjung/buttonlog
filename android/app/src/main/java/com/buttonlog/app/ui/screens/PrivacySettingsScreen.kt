package com.buttonlog.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.ui.viewmodels.PrivacySettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacySettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: PrivacySettingsViewModel = hiltViewModel()
) {
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.loadSettings()
    }

    LaunchedEffect(viewModel.errorMessage) {
        viewModel.errorMessage?.let { message ->
            snackbarHostState.showSnackbar(message)
            viewModel.clearError()
        }
    }

    LaunchedEffect(viewModel.saveSuccess) {
        if (viewModel.saveSuccess) {
            snackbarHostState.showSnackbar("Privacy settings saved")
            viewModel.clearSaveSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Privacy Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        if (viewModel.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp)
            ) {
                // Profile Visibility Section
                Text(
                    text = "Profile Visibility",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Who can see your profile",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                VisibilityOption(
                    title = "Public",
                    description = "Anyone can see your profile",
                    selected = viewModel.profileVisibility == "public",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateProfileVisibility("public") }
                )

                VisibilityOption(
                    title = "Friends Only",
                    description = "Only friends can see your profile",
                    selected = viewModel.profileVisibility == "friends",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateProfileVisibility("friends") }
                )

                VisibilityOption(
                    title = "Private",
                    description = "Only you can see your profile",
                    selected = viewModel.profileVisibility == "private",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateProfileVisibility("private") }
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Activity Visibility Section
                Text(
                    text = "Activity Visibility",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Who can see your button activity",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                VisibilityOption(
                    title = "Public",
                    description = "Anyone can see your button activities",
                    selected = viewModel.activityVisibility == "public",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateActivityVisibility("public") }
                )

                VisibilityOption(
                    title = "Friends Only",
                    description = "Only friends can see your button activities",
                    selected = viewModel.activityVisibility == "friends",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateActivityVisibility("friends") }
                )

                VisibilityOption(
                    title = "Private",
                    description = "Only you can see your button activities",
                    selected = viewModel.activityVisibility == "private",
                    enabled = !viewModel.isSaving,
                    onClick = { viewModel.updateActivityVisibility("private") }
                )

                if (viewModel.isSaving) {
                    Spacer(modifier = Modifier.height(16.dp))
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                }
            }
        }
    }
}

@Composable
private fun VisibilityOption(
    title: String,
    description: String,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
        border = if (selected) null else androidx.compose.foundation.BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = selected,
                onClick = null,
                enabled = enabled
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
    Spacer(modifier = Modifier.height(8.dp))
}
