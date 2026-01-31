package com.buttonlog.app.ui.theme

import androidx.compose.ui.graphics.Color

// =============================================================================
// ButtonLog Unified Design System - Color Tokens
// =============================================================================

// MARK: - Primary Colors
/** Main brand color - Sophisticated Teal */
val BLPrimary = Color(0xFF26A69A)
/** Darker variant for pressed states */
val BLPrimaryDark = Color(0xFF00897B)
/** Lighter variant for backgrounds */
val BLPrimaryLight = Color(0xFF80CBC4)

// MARK: - Secondary Colors
/** Accent color - Warm Coral */
val BLSecondary = Color(0xFFEF8A76)
/** Darker variant */
val BLSecondaryDark = Color(0xFFD77A6A)
/** Lighter variant */
val BLSecondaryLight = Color(0xFFFFAB91)

// MARK: - Neutral Colors - Light Theme
val BLBackground = Color(0xFFFAFBFC)
val BLSurface = Color(0xFFFFFFFF)
val BLSurfaceElevated = Color(0xFFF5F5F5)

// MARK: - Neutral Colors - Dark Theme
val BLBackgroundDark = Color(0xFF121212)
val BLSurfaceDark = Color(0xFF1E1E1E)
val BLSurfaceElevatedDark = Color(0xFF2C2C2C)

// MARK: - Border Colors
val BLBorder = Color(0xFFE5E7EB)
val BLBorderDark = Color(0xFF374151)
val BLDivider = Color(0xFFF3F4F6)
val BLDividerDark = Color(0xFF1F2937)

// MARK: - Text Colors - Light Theme
val BLTextPrimary = Color(0xFF1A1A2E)
val BLTextSecondary = Color(0xFF6B7280)
val BLTextTertiary = Color(0xFF9CA3AF)

// MARK: - Text Colors - Dark Theme
val BLTextPrimaryDark = Color(0xFFFFFFFF)
val BLTextSecondaryDark = Color(0xFF9CA3AF)
val BLTextTertiaryDark = Color(0xFF6B7280)

// MARK: - Semantic Colors
val BLSuccess = Color(0xFF4CAF50)
val BLSuccessLight = Color(0xFFE8F5E9)
val BLWarning = Color(0xFFFF9800)
val BLWarningLight = Color(0xFFFFF3E0)
val BLError = Color(0xFFF44336)
val BLErrorLight = Color(0xFFFFEBEE)
val BLInfo = Color(0xFF2196F3)
val BLInfoLight = Color(0xFFE3F2FD)

// MARK: - Button Palette Colors
/** Preset colors for user buttons */
val BLButtonRed = Color(0xFFEF5350)
val BLButtonOrange = Color(0xFFFF9800)
val BLButtonYellow = Color(0xFFFFC107)
val BLButtonGreen = Color(0xFF4CAF50)
val BLButtonTeal = Color(0xFF26A69A)
val BLButtonBlue = Color(0xFF2196F3)
val BLButtonIndigo = Color(0xFF3F51B5)
val BLButtonPurple = Color(0xFF9C27B0)
val BLButtonPink = Color(0xFFE91E63)

// =============================================================================
// Material 3 Color Scheme Tokens (for Theme.kt)
// =============================================================================

// Light Theme - Material 3 adapted to ButtonLog brand
val Purple80 = BLPrimaryLight
val PurpleGrey80 = Color(0xFFCCC2DC)
val Pink80 = BLSecondaryLight

val Purple40 = BLPrimary
val PurpleGrey40 = Color(0xFF625B71)
val Pink40 = BLSecondary

// Preserved for Material 3 compatibility
val Primary = BLPrimary
val PrimaryVariant = BLPrimaryDark
val Secondary = BLSecondary
val SecondaryVariant = BLSecondaryDark

val Background = BLBackground
val Surface = BLSurface
val Error = BLError

val OnPrimary = Color(0xFFFFFFFF)
val OnSecondary = Color(0xFFFFFFFF)
val OnBackground = BLTextPrimary
val OnSurface = BLTextPrimary
val OnError = Color(0xFFFFFFFF)

// Legacy button colors (mapped to new system)
val ButtonRed = BLButtonRed
val ButtonOrange = BLButtonOrange
val ButtonYellow = BLButtonYellow
val ButtonGreen = BLButtonGreen
val ButtonBlue = BLButtonBlue
val ButtonPurple = BLButtonPurple
val ButtonPink = BLButtonPink
val ButtonTeal = BLButtonTeal

// Legacy status colors
val Success = BLSuccess
val Warning = BLWarning
val Info = BLInfo
