package com.buttonlog.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.ui.viewmodels.WebhookSettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WebhookSettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: WebhookSettingsViewModel = hiltViewModel()
) {
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(viewModel.errorMessage) {
        viewModel.errorMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(viewModel.successMessage) {
        viewModel.successMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Webhook Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Webhook Configuration
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Webhook Configuration",
                            style = MaterialTheme.typography.titleMedium
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Enable Webhooks")
                            Switch(
                                checked = viewModel.webhookEnabled,
                                onCheckedChange = { viewModel.webhookEnabled = it }
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        OutlinedTextField(
                            value = viewModel.webhookUrl,
                            onValueChange = { viewModel.webhookUrl = it },
                            label = { Text("Webhook URL") },
                            placeholder = { Text("https://your-server.com/webhook") },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = viewModel.webhookEnabled,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                            singleLine = true
                        )

                        Text(
                            text = "When enabled, ButtonLog will send HTTP POST requests to your webhook URL whenever button events occur.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }

                // Security
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Security",
                            style = MaterialTheme.typography.titleMedium
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        OutlinedTextField(
                            value = viewModel.webhookSecret,
                            onValueChange = { viewModel.webhookSecret = it },
                            label = { Text("Webhook Secret (Optional)") },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = viewModel.webhookEnabled,
                            visualTransformation = PasswordVisualTransformation(),
                            singleLine = true
                        )

                        Text(
                            text = "If provided, webhook requests will include a signature header for verification.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }

                // Retry Settings
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Retry Settings",
                            style = MaterialTheme.typography.titleMedium
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Retry Failed Deliveries")
                            Switch(
                                checked = viewModel.retryFailed,
                                onCheckedChange = { viewModel.retryFailed = it },
                                enabled = viewModel.webhookEnabled
                            )
                        }

                        if (viewModel.retryFailed) {
                            Spacer(modifier = Modifier.height(16.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Max Retries: ${viewModel.maxRetries}")
                                Row {
                                    IconButton(
                                        onClick = { if (viewModel.maxRetries > 1) viewModel.maxRetries-- },
                                        enabled = viewModel.webhookEnabled && viewModel.maxRetries > 1
                                    ) {
                                        Text("-")
                                    }
                                    IconButton(
                                        onClick = { if (viewModel.maxRetries < 10) viewModel.maxRetries++ },
                                        enabled = viewModel.webhookEnabled && viewModel.maxRetries < 10
                                    ) {
                                        Text("+")
                                    }
                                }
                            }
                        }
                    }
                }

                // Save Button
                Button(
                    onClick = { viewModel.saveSettings() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !viewModel.isSaving && viewModel.isFormValid
                ) {
                    if (viewModel.isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text("Save Settings")
                }

                // Test Webhook Button
                OutlinedButton(
                    onClick = { viewModel.testWebhook() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = viewModel.webhookEnabled && viewModel.webhookUrl.isNotEmpty()
                ) {
                    Text("Test Webhook")
                }

                Text(
                    text = "Send a test payload to your webhook URL to verify the configuration.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
