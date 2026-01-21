package com.buttonlog.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.buttonlog.app.data.model.Button
import com.buttonlog.app.data.model.ButtonState
import com.buttonlog.app.data.model.ButtonType
import kotlinx.coroutines.delay

@Composable
fun ButtonCard(
    button: Button,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isPressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = tween(durationMillis = 100),
        label = "scale"
    )

    // Reset pressed state after animation
    LaunchedEffect(isPressed) {
        if (isPressed) {
            delay(100)
            isPressed = false
        }
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header section
            ButtonHeader(button = button)

            // Action button
            ButtonActionButton(
                button = button,
                onClick = {
                    isPressed = true
                    onClick()
                }
            )
        }
    }
}

@Composable
private fun ButtonHeader(button: Button) {
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
        Column(
            modifier = Modifier.weight(1f)
        ) {
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
                        maxLines = 2
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Tags
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ButtonTypeTag(button.type)
                if (button.currentState == ButtonState.ACTIVE) {
                    ButtonStateTag(button.currentState)
                }
            }
        }
        
        // Settings button
        IconButton(
            onClick = { /* Show button settings */ }
        ) {
            Icon(
                imageVector = Icons.Default.MoreVert,
                contentDescription = "Button settings",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ButtonActionButton(
    button: Button,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(
            containerColor = button.uiColor,
            contentColor = Color.White
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.TouchApp,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
            
            Text(
                text = "Click!",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
        }
        
        Spacer(modifier = Modifier.height(12.dp))
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
private fun ButtonStateTag(buttonState: ButtonState) {
    Surface(
        color = buttonState.color.copy(alpha = 0.2f),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            text = buttonState.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = buttonState.color,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
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

