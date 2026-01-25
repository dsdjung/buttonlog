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
import com.buttonlog.app.ui.viewmodels.NotificationSettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationSettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: NotificationSettingsViewModel = hiltViewModel()
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notification Settings") },
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
                // Push Notifications Section
                Text(
                    text = "Push Notifications",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                SwitchSettingItem(
                    title = "Push Notifications",
                    description = "Receive push notifications on your device",
                    checked = viewModel.pushNotificationsEnabled,
                    enabled = !viewModel.isSaving,
                    onCheckedChange = { viewModel.setPushNotificationsEnabled(it) }
                )

                SwitchSettingItem(
                    title = "Button Activity",
                    description = "Get notified about button clicks and updates",
                    checked = viewModel.buttonNotifications,
                    enabled = !viewModel.isSaving && viewModel.pushNotificationsEnabled,
                    onCheckedChange = { viewModel.setButtonNotifications(it) }
                )

                SwitchSettingItem(
                    title = "Friend Updates",
                    description = "Get notified about friend requests and activity",
                    checked = viewModel.friendNotifications,
                    enabled = !viewModel.isSaving && viewModel.pushNotificationsEnabled,
                    onCheckedChange = { viewModel.setFriendNotifications(it) }
                )

                SwitchSettingItem(
                    title = "System Updates",
                    description = "Get notified about system updates and announcements",
                    checked = viewModel.systemNotifications,
                    enabled = !viewModel.isSaving && viewModel.pushNotificationsEnabled,
                    onCheckedChange = { viewModel.setSystemNotifications(it) }
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Email Notifications Section
                Text(
                    text = "Email Notifications",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                SwitchSettingItem(
                    title = "Email Notifications",
                    description = "Receive notifications via email",
                    checked = viewModel.emailNotificationsEnabled,
                    enabled = !viewModel.isSaving,
                    onCheckedChange = { viewModel.setEmailNotificationsEnabled(it) }
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Quiet Hours Section
                Text(
                    text = "Quiet Hours",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                SwitchSettingItem(
                    title = "Enable Quiet Hours",
                    description = "Pause notifications during specific hours",
                    checked = viewModel.quietHoursEnabled,
                    enabled = !viewModel.isSaving,
                    onCheckedChange = { viewModel.setQuietHoursEnabled(it) }
                )

                if (viewModel.quietHoursEnabled) {
                    Spacer(modifier = Modifier.height(8.dp))

                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "Quiet hours: ${viewModel.quietHoursStart ?: "22:00"} - ${viewModel.quietHoursEnd ?: "07:00"}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = "Configure quiet hours in your device's system settings",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                if (viewModel.isSaving) {
                    Spacer(modifier = Modifier.height(16.dp))
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                }
            }
        }
    }
}

@Composable
private fun SwitchSettingItem(
    title: String,
    description: String,
    checked: Boolean,
    enabled: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (enabled) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled
            )
        }
    }
}
