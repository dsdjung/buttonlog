package com.buttonlog.app.ui.theme

import androidx.compose.animation.core.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer

// =============================================================================
// ButtonLog Unified Design System - Animation Helpers
// Uses BLAnimation constants defined in Spacing.kt
// =============================================================================

/**
 * Composable that animates items with a staggered fade-in and slide-up effect.
 * Used for list items appearing on screen.
 *
 * @param index The index of the item in the list (for calculating stagger delay)
 * @param content The content to animate
 */
@Composable
fun StaggeredFadeIn(
    index: Int,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    var visible by remember { mutableStateOf(false) }

    val alpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = tween(
            durationMillis = BLAnimation.normal,
            delayMillis = index * BLAnimation.staggerDelay,
            easing = FastOutSlowInEasing
        ),
        label = "staggered_alpha"
    )

    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else BLAnimation.slideOffset,
        animationSpec = tween(
            durationMillis = BLAnimation.normal,
            delayMillis = index * BLAnimation.staggerDelay,
            easing = FastOutSlowInEasing
        ),
        label = "staggered_offset"
    )

    LaunchedEffect(Unit) {
        visible = true
    }

    androidx.compose.foundation.layout.Box(
        modifier = modifier.graphicsLayer {
            this.alpha = alpha
            this.translationY = offsetY
        }
    ) {
        content()
    }
}

/**
 * Modifier extension for press scale animation.
 * Scales down the element when pressed for tactile feedback.
 */
fun Modifier.pressScale(isPressed: Boolean): Modifier = composed {
    val scale by animateFloatAsState(
        targetValue = if (isPressed) BLAnimation.pressScale else 1f,
        animationSpec = spring(
            dampingRatio = BLAnimation.springDamping,
            stiffness = BLAnimation.springStiffness
        ),
        label = "press_scale"
    )
    this.scale(scale)
}
