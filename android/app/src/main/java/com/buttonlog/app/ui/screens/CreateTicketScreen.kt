package com.buttonlog.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.TicketCategory
import com.buttonlog.app.data.model.TicketFormData
import com.buttonlog.app.data.model.TicketPriority
import com.buttonlog.app.ui.viewmodels.SupportViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateTicketScreen(
    viewModel: SupportViewModel,
    onTicketCreated: () -> Unit,
    onBackClick: () -> Unit
) {
    var formData by remember { mutableStateOf(TicketFormData()) }
    val isCreating = viewModel.isCreatingTicket
    val error = viewModel.createTicketError

    var categoryExpanded by remember { mutableStateOf(false) }
    var priorityExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Ticket") },
                navigationIcon = {
                    IconButton(onClick = onBackClick, enabled = !isCreating) {
                        Icon(Icons.Default.Close, contentDescription = "Cancel")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.createTicket(formData) {
                                onTicketCreated()
                            }
                        },
                        enabled = formData.isValid && !isCreating
                    ) {
                        if (isCreating) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Submit")
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Category dropdown
            ExposedDropdownMenuBox(
                expanded = categoryExpanded,
                onExpandedChange = { categoryExpanded = it }
            ) {
                OutlinedTextField(
                    value = formData.category.displayName,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Category") },
                    leadingIcon = {
                        Icon(
                            getCategoryIcon(formData.category),
                            contentDescription = null
                        )
                    },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )

                ExposedDropdownMenu(
                    expanded = categoryExpanded,
                    onDismissRequest = { categoryExpanded = false }
                ) {
                    TicketCategory.values().forEach { category ->
                        DropdownMenuItem(
                            text = { Text(category.displayName) },
                            leadingIcon = { Icon(getCategoryIcon(category), contentDescription = null) },
                            onClick = {
                                formData = formData.copy(category = category)
                                categoryExpanded = false
                            }
                        )
                    }
                }
            }

            // Subject
            OutlinedTextField(
                value = formData.subject,
                onValueChange = { formData = formData.copy(subject = it) },
                label = { Text("Subject") },
                placeholder = { Text("Brief description of your issue") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                enabled = !isCreating
            )

            // Priority
            Text(
                "Priority",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TicketPriority.values().forEach { priority ->
                    FilterChip(
                        selected = formData.priority == priority,
                        onClick = { formData = formData.copy(priority = priority) },
                        label = { Text(priority.displayName) },
                        enabled = !isCreating,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Message
            OutlinedTextField(
                value = formData.message,
                onValueChange = { formData = formData.copy(message = it) },
                label = { Text("Message") },
                placeholder = { Text("Describe your issue or question in detail...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                enabled = !isCreating
            )

            // Error message
            error?.let { errorMessage ->
                Text(
                    text = errorMessage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}
