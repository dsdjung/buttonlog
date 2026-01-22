package com.buttonlog.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// =============================================================================
// ButtonLog Unified Theme
// =============================================================================

private val DarkColorScheme = darkColorScheme(
    primary = BLPrimary,
    onPrimary = Color.White,
    primaryContainer = BLPrimaryDark,
    onPrimaryContainer = BLPrimaryLight,
    secondary = BLSecondary,
    onSecondary = Color.White,
    secondaryContainer = BLSecondaryDark,
    onSecondaryContainer = BLSecondaryLight,
    tertiary = BLButtonTeal,
    onTertiary = Color.White,
    background = BLBackgroundDark,
    onBackground = BLTextPrimaryDark,
    surface = BLSurfaceDark,
    onSurface = BLTextPrimaryDark,
    surfaceVariant = BLSurfaceElevatedDark,
    onSurfaceVariant = BLTextSecondaryDark,
    error = BLError,
    onError = Color.White,
    errorContainer = BLErrorLight,
    outline = BLTextTertiaryDark
)

private val LightColorScheme = lightColorScheme(
    primary = BLPrimary,
    onPrimary = Color.White,
    primaryContainer = BLPrimaryLight,
    onPrimaryContainer = BLPrimaryDark,
    secondary = BLSecondary,
    onSecondary = Color.White,
    secondaryContainer = BLSecondaryLight,
    onSecondaryContainer = BLSecondaryDark,
    tertiary = BLButtonTeal,
    onTertiary = Color.White,
    background = BLBackground,
    onBackground = BLTextPrimary,
    surface = BLSurface,
    onSurface = BLTextPrimary,
    surfaceVariant = BLSurfaceElevated,
    onSurfaceVariant = BLTextSecondary,
    error = BLError,
    onError = Color.White,
    errorContainer = BLErrorLight,
    outline = BLTextTertiary
)

@Composable
fun ButtonLogTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    // Set to false by default to maintain brand consistency
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // Use surface color for status bar for a cleaner look
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    CompositionLocalProvider(
        LocalBLSpacing provides BLSpacing(),
        LocalBLRadius provides BLRadius(),
        LocalBLElevation provides BLElevation()
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            content = content
        )
    }
}
