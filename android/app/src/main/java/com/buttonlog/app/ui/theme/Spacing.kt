package com.buttonlog.app.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// =============================================================================
// ButtonLog Unified Design System - Spacing & Layout Tokens
// =============================================================================

/**
 * Spacing values following an 8-point grid system.
 * Matches iOS BLSpacing and Web Tailwind spacing tokens.
 */
data class BLSpacing(
    /** 4dp - Extra small spacing */
    val xs: Dp = 4.dp,
    /** 8dp - Small spacing */
    val sm: Dp = 8.dp,
    /** 12dp - Medium-small spacing */
    val md: Dp = 12.dp,
    /** 16dp - Medium spacing */
    val lg: Dp = 16.dp,
    /** 24dp - Large spacing */
    val xl: Dp = 24.dp,
    /** 32dp - Extra large spacing */
    val xxl: Dp = 32.dp,
    /** 48dp - Huge spacing */
    val xxxl: Dp = 48.dp
)

/**
 * Corner radius values for consistent rounded corners.
 * Matches iOS BLRadius and Web Tailwind border-radius tokens.
 */
data class BLRadius(
    /** 4dp - Small radius for chips, badges */
    val sm: Dp = 4.dp,
    /** 8dp - Medium radius for inputs, small cards */
    val md: Dp = 8.dp,
    /** 12dp - Large radius for cards */
    val lg: Dp = 12.dp,
    /** 16dp - Extra large radius for sheets, modals */
    val xl: Dp = 16.dp,
    /** 24dp - Full round for pills, FABs */
    val full: Dp = 24.dp
)

/**
 * Shadow/elevation values for consistent depth.
 */
data class BLElevation(
    /** Small elevation for cards */
    val sm: Dp = 2.dp,
    /** Medium elevation for elevated cards */
    val md: Dp = 4.dp,
    /** Large elevation for modals, sheets */
    val lg: Dp = 8.dp
)

/**
 * Animation durations for consistent motion.
 * Matches iOS BLAnimation and Web CSS transition durations.
 */
object BLAnimation {
    /** 150ms - Fast animations */
    const val fast: Int = 150
    /** 250ms - Normal animations */
    const val normal: Int = 250
    /** 350ms - Slow animations */
    const val slow: Int = 350
}

// CompositionLocal providers for theme access
val LocalBLSpacing = staticCompositionLocalOf { BLSpacing() }
val LocalBLRadius = staticCompositionLocalOf { BLRadius() }
val LocalBLElevation = staticCompositionLocalOf { BLElevation() }

// Convenient accessors
object BLTheme {
    val spacing: BLSpacing
        @Composable
        get() = LocalBLSpacing.current

    val radius: BLRadius
        @Composable
        get() = LocalBLRadius.current

    val elevation: BLElevation
        @Composable
        get() = LocalBLElevation.current
}
