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
    /** 8dp - Medium radius for inputs */
    val md: Dp = 8.dp,
    /** 12dp - Large radius for buttons */
    val lg: Dp = 12.dp,
    /** 16dp - Extra large radius for cards (softer corners) */
    val xl: Dp = 16.dp,
    /** 20dp - Extra extra large for sheets, modals */
    val xxl: Dp = 20.dp,
    /** 24dp - Full round for pills, FABs */
    val full: Dp = 24.dp
)

/**
 * Shadow/elevation values for consistent depth.
 * Minimal design uses subtle or no elevation.
 */
data class BLElevation(
    /** No elevation - use borders instead */
    val none: Dp = 0.dp,
    /** Subtle elevation for floating elements */
    val subtle: Dp = 1.dp,
    /** Small elevation for elevated cards */
    val sm: Dp = 2.dp,
    /** Medium elevation for modals */
    val md: Dp = 4.dp,
    /** Large elevation for sheets */
    val lg: Dp = 8.dp
)

/**
 * Animation constants for consistent motion.
 * Matches iOS BLAnimation and Web CSS transition durations.
 */
object BLAnimation {
    // Duration constants
    /** 150ms - Fast animations */
    const val fast: Int = 150
    /** 250ms - Normal animations */
    const val normal: Int = 250
    /** 350ms - Slow animations */
    const val slow: Int = 350

    // Spring animation specs (matches iOS)
    /** Damping ratio for spring animations */
    const val springDamping: Float = 0.7f
    /** Stiffness for spring animations */
    const val springStiffness: Float = 300f
    /** Bouncy spring damping */
    const val springBouncyDamping: Float = 0.6f
    /** Stiff spring stiffness */
    const val springStiffStiffness: Float = 500f

    // Press scale for interactive elements
    /** Scale effect for pressed state */
    const val pressScale: Float = 0.98f
    /** Background tint opacity for pressed state */
    const val pressTintOpacity: Float = 0.04f

    // Staggered animation constants
    /** Delay between items in staggered animations (ms) */
    const val staggerDelay: Int = 50
    /** Initial offset for slide-in animations (dp) */
    const val slideOffset: Float = 12f
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
