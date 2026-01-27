package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.api.DiaryActivity
import com.buttonlog.app.data.api.DiaryData
import com.buttonlog.app.ui.viewmodels.ButtonsViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiaryScreen(
    viewModel: ButtonsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedDate by remember { mutableStateOf(Date()) }
    var showDatePicker by remember { mutableStateOf(false) }

    val dateFormat = remember { SimpleDateFormat("EEEE, MMMM d, yyyy", Locale.getDefault()) }
    val calendar = remember { Calendar.getInstance() }

    // Fetch diary data when screen loads or date changes
    LaunchedEffect(selectedDate) {
        viewModel.fetchDiary(selectedDate)
    }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Date selector header
        Surface(
            modifier = Modifier.fillMaxWidth(),
            tonalElevation = 2.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = { showDatePicker = true }) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = dateFormat.format(selectedDate),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Icon(
                            imageVector = Icons.Default.CalendarMonth,
                            contentDescription = "Select date",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(onClick = {
                        calendar.time = selectedDate
                        calendar.add(Calendar.DAY_OF_MONTH, -1)
                        selectedDate = calendar.time
                    }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                            contentDescription = "Previous day"
                        )
                    }

                    IconButton(
                        onClick = {
                            calendar.time = selectedDate
                            calendar.add(Calendar.DAY_OF_MONTH, 1)
                            selectedDate = calendar.time
                        },
                        enabled = !isSameDay(selectedDate, Date())
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = "Next day"
                        )
                    }
                }
            }
        }

        // Content
        when {
            uiState.isLoadingDiary -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            uiState.diaryError != null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Text(
                            text = uiState.diaryError ?: "Unknown error",
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center
                        )
                        Button(onClick = { viewModel.fetchDiary(selectedDate) }) {
                            Text("Retry")
                        }
                    }
                }
            }
            else -> {
                val diaryData = uiState.diaryData
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Daily summary card
                    item {
                        DailySummaryCard(diaryData = diaryData)
                    }

                    // Button activities
                    if (diaryData?.activities?.isNotEmpty() == true) {
                        items(diaryData.activities) { activity ->
                            ButtonActivityCard(activity = activity)
                        }
                    } else {
                        item {
                            EmptyDayView()
                        }
                    }
                }
            }
        }
    }

    // Date picker dialog
    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = selectedDate.time
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let {
                        selectedDate = Date(it)
                    }
                    showDatePicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(
                state = datePickerState,
                showModeToggle = false
            )
        }
    }
}

@Composable
private fun DailySummaryCard(diaryData: DiaryData?) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Daily Summary",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                SummaryItem(
                    title = "Total Clicks",
                    value = "${diaryData?.summary?.totalClicks ?: 0}",
                    icon = Icons.Default.TouchApp,
                    color = MaterialTheme.colorScheme.primary
                )

                SummaryItem(
                    title = "Buttons Used",
                    value = "${diaryData?.summary?.totalButtonsUsed ?: 0}",
                    icon = Icons.Default.SmartButton,
                    color = Color(0xFF34C759) // Green
                )

                SummaryItem(
                    title = "In Progress",
                    value = "${diaryData?.summary?.inProgressCount ?: 0}",
                    icon = Icons.Default.PlayCircle,
                    color = Color(0xFFFF9500) // Orange
                )
            }
        }
    }
}

@Composable
private fun SummaryItem(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(28.dp)
        )

        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold
        )

        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun ButtonActivityCard(activity: DiaryActivity) {
    val buttonColor = try {
        Color(android.graphics.Color.parseColor(activity.button.color))
    } catch (e: Exception) {
        MaterialTheme.colorScheme.primary
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Button header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(buttonColor),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = getIconForButton(activity.button.icon),
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(20.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = activity.button.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "${activity.totalClicks} ${if (activity.totalClicks == 1) "click" else "clicks"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Surface(
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = formatButtonType(activity.button.type),
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            // Activity timeline
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                activity.clicks.take(5).forEach { click ->
                    ActivityTimelineItem(
                        time = formatClickTime(click.clickedAt),
                        action = formatAction(click.action, activity.button.type),
                        choice = click.selectedChoice
                    )
                }
                if (activity.clicks.size > 5) {
                    Text(
                        text = "... and ${activity.clicks.size - 5} more",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = 20.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun ActivityTimelineItem(
    time: String,
    action: String,
    choice: String? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary)
        )

        Text(
            text = time,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.width(70.dp)
        )

        Text(
            text = if (choice != null) "$action: $choice" else action,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
private fun EmptyDayView() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.EventBusy,
                contentDescription = null,
                modifier = Modifier.size(56.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "No activity on this day",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Text(
                text = "Start clicking buttons to see your daily activity here",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

private fun formatButtonType(type: String): String {
    return when (type) {
        "instant" -> "Instant"
        "toggle" -> "Toggle"
        "one-time" -> "One-Time"
        "workflow" -> "Workflow"
        else -> type.replaceFirstChar { it.uppercase() }
    }
}

private fun formatAction(action: String?, type: String): String {
    return when {
        action == "start" -> "Started"
        action == "end" -> "Stopped"
        action == "click" && type == "one-time" -> "Completed"
        action == "click" -> "Clicked"
        else -> "Clicked"
    }
}

private fun formatClickTime(isoTime: String): String {
    return try {
        val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        inputFormat.timeZone = TimeZone.getTimeZone("UTC")
        val date = inputFormat.parse(isoTime)
        val outputFormat = SimpleDateFormat("h:mm a", Locale.getDefault()).apply {
            timeZone = TimeZone.getDefault()
        }
        outputFormat.format(date ?: Date())
    } catch (e: Exception) {
        isoTime.substringAfter("T").substringBefore(".")
    }
}

private fun isSameDay(date1: Date, date2: Date): Boolean {
    val cal1 = Calendar.getInstance().apply { time = date1 }
    val cal2 = Calendar.getInstance().apply { time = date2 }
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
            cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
}

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
        "car" -> Icons.Default.DirectionsCar
        "book" -> Icons.Default.Book
        "pencil" -> Icons.Default.Edit
        "gear" -> Icons.Default.Settings
        else -> Icons.Default.Star
    }
}
