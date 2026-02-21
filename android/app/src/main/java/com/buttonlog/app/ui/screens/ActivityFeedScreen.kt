package com.buttonlog.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.model.FeedActivity
import com.buttonlog.app.ui.theme.*
import com.buttonlog.app.ui.viewmodels.ActivityFeedViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActivityFeedScreen(
    onBackClick: () -> Unit = {},
    viewModel: ActivityFeedViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()

    // Load more when reaching the end
    LaunchedEffect(listState) {
        snapshotFlow {
            val layoutInfo = listState.layoutInfo
            val totalItemsNumber = layoutInfo.totalItemsCount
            val lastVisibleItemIndex = (layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0) + 1
            lastVisibleItemIndex > (totalItemsNumber - 3)
        }.collect { shouldLoadMore ->
            if (shouldLoadMore && uiState.hasMore && !uiState.isLoadingMore) {
                viewModel.loadMore()
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.loadActivityFeed()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Friend Activity") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (!uiState.isLoading) {
                        IconButton(onClick = { viewModel.refresh() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(BLBackground)
        ) {
            when {
                uiState.isLoading && uiState.activities.isEmpty() -> {
                    LoadingFeedView()
                }
                uiState.error != null && uiState.activities.isEmpty() -> {
                    FeedErrorView(
                        message = uiState.error ?: "Unknown error",
                        onRetry = { viewModel.loadActivityFeed() }
                    )
                }
                uiState.activities.isEmpty() -> {
                    EmptyFeedView()
                }
                else -> {
                    LazyColumn(
                        state = listState,
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(uiState.activities, key = { it.id }) { activity ->
                            FeedActivityCard(activity = activity)
                        }

                        if (uiState.isLoadingMore) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    CircularProgressIndicator(modifier = Modifier.size(24.dp))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun FeedActivityCard(activity: FeedActivity) {
    val buttonColor = try {
        Color(android.graphics.Color.parseColor(activity.buttonColor ?: "#26A69A"))
    } catch (e: Exception) {
        BLPrimary
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = BLSurface)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header: User name and time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = activity.displayUserName,
                    style = MaterialTheme.typography.labelMedium,
                    color = BLTextSecondary
                )

                Text(
                    text = formatRelativeTime(activity.clickedAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = BLTextTertiary
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Main content
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Button icon
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(buttonColor.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = getIconEmoji(activity.buttonIcon),
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = activity.buttonName,
                        style = MaterialTheme.typography.titleMedium,
                        color = BLTextPrimary
                    )

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        FeedActionBadge(action = activity.displayAction)

                        if ((activity.duration ?: 0) > 0) {
                            Text(
                                text = "•",
                                color = BLTextTertiary
                            )
                            Text(
                                text = formatDuration(activity.duration!!),
                                style = MaterialTheme.typography.bodySmall,
                                color = BLTextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun FeedActionBadge(action: String) {
    val (backgroundColor, textColor) = when (action.lowercase()) {
        "started" -> BLSuccess.copy(alpha = 0.15f) to BLSuccess
        "stopped" -> BLSecondary.copy(alpha = 0.15f) to BLSecondary
        "completed" -> BLPrimary.copy(alpha = 0.15f) to BLPrimary
        else -> BLPrimary.copy(alpha = 0.15f) to BLPrimary
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = backgroundColor
    ) {
        Text(
            text = action,
            style = MaterialTheme.typography.labelSmall,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
        )
    }
}

@Composable
private fun LoadingFeedView() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CircularProgressIndicator()
            Text(
                text = "Loading activity...",
                style = MaterialTheme.typography.bodyMedium,
                color = BLTextSecondary
            )
        }
    }
}

@Composable
private fun EmptyFeedView() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(CircleShape)
                    .background(BLPrimary.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "👋",
                    style = MaterialTheme.typography.displaySmall
                )
            }

            Text(
                text = "No Activity Yet",
                style = MaterialTheme.typography.headlineSmall,
                color = BLTextPrimary
            )

            Text(
                text = "When your friends complete buttons, you'll see their activity here",
                style = MaterialTheme.typography.bodyMedium,
                color = BLTextSecondary,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun FeedErrorView(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Text(
                text = "⚠️",
                style = MaterialTheme.typography.displaySmall
            )

            Text(
                text = "Couldn't Load Activity",
                style = MaterialTheme.typography.headlineSmall,
                color = BLTextPrimary
            )

            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = BLTextSecondary,
                textAlign = TextAlign.Center
            )

            Button(
                onClick = onRetry,
                colors = ButtonDefaults.buttonColors(containerColor = BLPrimary)
            ) {
                Text("Try Again")
            }
        }
    }
}

private fun getIconEmoji(icon: String?): String {
    return when (icon) {
        "star.fill" -> "⭐"
        "heart.fill" -> "❤️"
        "bolt.fill" -> "⚡"
        "flame.fill" -> "🔥"
        "moon.fill" -> "🌙"
        "sun.max.fill" -> "☀️"
        "drop.fill" -> "💧"
        "leaf.fill" -> "🍃"
        "book.fill" -> "📚"
        "pencil" -> "✏️"
        "checkmark.circle.fill" -> "✅"
        "bell.fill" -> "🔔"
        "clock.fill" -> "⏰"
        else -> "📱"
    }
}

private fun formatDuration(seconds: Int): String {
    return when {
        seconds < 60 -> "${seconds}s"
        seconds < 3600 -> "${seconds / 60}m"
        else -> {
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            if (minutes > 0) "${hours}h ${minutes}m" else "${hours}h"
        }
    }
}

// Uses formatRelativeTime from NotificationsScreen.kt
