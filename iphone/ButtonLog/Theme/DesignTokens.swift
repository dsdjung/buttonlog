import SwiftUI

// MARK: - ButtonLog Design System
// Unified design tokens for consistent UI across all platforms

// MARK: - Colors

extension Color {

    // MARK: Primary Colors
    /// Main brand color - Sophisticated Teal
    static let blPrimary = Color(hex: "26A69A")
    /// Darker variant for pressed states
    static let blPrimaryDark = Color(hex: "00897B")
    /// Lighter variant for backgrounds
    static let blPrimaryLight = Color(hex: "80CBC4")

    // MARK: Secondary Colors
    /// Accent color - Warm Coral
    static let blSecondary = Color(hex: "EF8A76")
    /// Darker variant
    static let blSecondaryDark = Color(hex: "D77A6A")
    /// Lighter variant
    static let blSecondaryLight = Color(hex: "FFAB91")

    // MARK: Neutral Colors
    static let blBackground = Color(hex: "FAFBFC")
    static let blBackgroundDark = Color(hex: "121212")
    static let blSurface = Color(hex: "FFFFFF")
    static let blSurfaceDark = Color(hex: "1E1E1E")
    static let blSurfaceElevated = Color(hex: "F5F5F5")
    static let blSurfaceElevatedDark = Color(hex: "2C2C2C")

    // MARK: Border Colors
    static let blBorder = Color(hex: "E5E7EB")
    static let blBorderDark = Color(hex: "374151")
    static let blDivider = Color(hex: "F3F4F6")
    static let blDividerDark = Color(hex: "1F2937")

    // MARK: Text Colors
    static let blTextPrimary = Color(hex: "1A1A2E")
    static let blTextPrimaryDark = Color(hex: "FFFFFF")
    static let blTextSecondary = Color(hex: "6B7280")
    static let blTextSecondaryDark = Color(hex: "9CA3AF")
    static let blTextTertiary = Color(hex: "9CA3AF")
    static let blTextTertiaryDark = Color(hex: "6B7280")

    // MARK: Semantic Colors
    static let blSuccess = Color(hex: "4CAF50")
    static let blSuccessLight = Color(hex: "E8F5E9")
    static let blWarning = Color(hex: "FF9800")
    static let blWarningLight = Color(hex: "FFF3E0")
    static let blError = Color(hex: "F44336")
    static let blErrorLight = Color(hex: "FFEBEE")
    static let blInfo = Color(hex: "2196F3")
    static let blInfoLight = Color(hex: "E3F2FD")

    // MARK: Button Palette Colors
    /// Preset colors for user buttons
    static let blButtonRed = Color(hex: "EF5350")
    static let blButtonOrange = Color(hex: "FF9800")
    static let blButtonYellow = Color(hex: "FFC107")
    static let blButtonGreen = Color(hex: "4CAF50")
    static let blButtonTeal = Color(hex: "26A69A")
    static let blButtonBlue = Color(hex: "2196F3")
    static let blButtonIndigo = Color(hex: "3F51B5")
    static let blButtonPurple = Color(hex: "9C27B0")
    static let blButtonPink = Color(hex: "E91E63")

    // MARK: Gradient Definitions
    static var blPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [blPrimary, blPrimaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var blSecondaryGradient: LinearGradient {
        LinearGradient(
            colors: [blSecondary, blSecondaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Note: init(hex:) is defined in Button.swift
}

// MARK: - Typography

struct BLTypography {
    // MARK: Display - Light weight for elegance
    static let displayLarge = Font.system(size: 32, weight: .light)
    static let displayMedium = Font.system(size: 28, weight: .light)
    static let displaySmall = Font.system(size: 24, weight: .light)

    // MARK: Headlines - Regular weight for readability
    static let headlineLarge = Font.system(size: 24, weight: .regular)
    static let headlineMedium = Font.system(size: 22, weight: .regular)
    static let headlineSmall = Font.system(size: 20, weight: .regular)

    // MARK: Titles - Medium weight for hierarchy
    static let titleLarge = Font.system(size: 20, weight: .medium)
    static let titleMedium = Font.system(size: 18, weight: .medium)
    static let titleSmall = Font.system(size: 16, weight: .medium)

    // MARK: Body - Regular weight with better tracking
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)

    // MARK: Labels - Medium weight for emphasis
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)

    // MARK: Caption
    static let caption = Font.system(size: 11, weight: .regular)
}

// MARK: - Spacing (8-point grid system)

struct BLSpacing {
    /// 4pt - Extra small spacing
    static let xs: CGFloat = 4
    /// 8pt - Small spacing
    static let sm: CGFloat = 8
    /// 12pt - Medium-small spacing
    static let md: CGFloat = 12
    /// 16pt - Medium spacing
    static let lg: CGFloat = 16
    /// 24pt - Large spacing
    static let xl: CGFloat = 24
    /// 32pt - Extra large spacing
    static let xxl: CGFloat = 32
    /// 48pt - Huge spacing
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

struct BLRadius {
    /// 4pt - Small radius for chips, badges
    static let sm: CGFloat = 4
    /// 8pt - Medium radius for inputs
    static let md: CGFloat = 8
    /// 12pt - Large radius for buttons
    static let lg: CGFloat = 12
    /// 16pt - Extra large radius for cards (softer corners)
    static let xl: CGFloat = 16
    /// 20pt - Full round for sheets, modals
    static let xxl: CGFloat = 20
    /// 24pt - Pill shape for FABs
    static let full: CGFloat = 24
}

// MARK: - Shadows

struct BLShadow {
    /// Subtle shadow for minimal elevation
    static let subtle = BLShadowStyle(color: Color.black.opacity(0.04), radius: 8, y: 2)
    /// Small shadow for cards
    static let small = BLShadowStyle(color: Color.black.opacity(0.06), radius: 4, y: 2)
    /// Medium shadow for elevated elements
    static let medium = BLShadowStyle(color: Color.black.opacity(0.08), radius: 8, y: 4)
    /// Large shadow for modals
    static let large = BLShadowStyle(color: Color.black.opacity(0.12), radius: 16, y: 8)
}

struct BLShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers

extension View {
    func blShadow(_ style: BLShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }

    /// Minimal card style with subtle border instead of shadow
    func blCard() -> some View {
        self
            .background(Color.blSurface)
            .cornerRadius(BLRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BLRadius.xl)
                    .stroke(Color.blBorder, lineWidth: 1)
            )
    }

    /// Elevated card with subtle shadow
    func blCardElevated() -> some View {
        self
            .background(Color.blSurface)
            .cornerRadius(BLRadius.xl)
            .blShadow(BLShadow.subtle)
    }

    /// Card with border and subtle shadow (hybrid)
    func blCardMinimal() -> some View {
        self
            .background(Color.blSurface)
            .cornerRadius(BLRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BLRadius.xl)
                    .stroke(Color.blBorder, lineWidth: 1)
            )
            .blShadow(BLShadow.subtle)
    }
}

// MARK: - Button Styles

struct BLPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(.white)
            .padding(.horizontal, BLSpacing.xl)
            .padding(.vertical, BLSpacing.md)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: BLRadius.lg)
                    .fill(isEnabled ? Color.blPrimary : Color.blTextTertiary)
            )
            .blShadow(BLShadow.subtle)
            .scaleEffect(configuration.isPressed ? BLAnimation.pressScale : 1.0)
            .animation(BLAnimation.spring, value: configuration.isPressed)
    }
}

struct BLSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(isEnabled ? .blPrimary : .blTextTertiary)
            .padding(.horizontal, BLSpacing.xl)
            .padding(.vertical, BLSpacing.md)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: BLRadius.lg)
                    .stroke(isEnabled ? Color.blPrimary : Color.blTextTertiary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? BLAnimation.pressScale : 1.0)
            .animation(BLAnimation.spring, value: configuration.isPressed)
    }
}

struct BLTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(.blPrimary)
            .scaleEffect(configuration.isPressed ? BLAnimation.pressScale : 1.0)
            .animation(BLAnimation.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BLPrimaryButtonStyle {
    static var blPrimary: BLPrimaryButtonStyle { BLPrimaryButtonStyle() }
}

extension ButtonStyle where Self == BLSecondaryButtonStyle {
    static var blSecondary: BLSecondaryButtonStyle { BLSecondaryButtonStyle() }
}

extension ButtonStyle where Self == BLTextButtonStyle {
    static var blText: BLTextButtonStyle { BLTextButtonStyle() }
}

// MARK: - Animation Constants

struct BLAnimation {
    /// Fast ease for micro-interactions
    static let fast = Animation.easeInOut(duration: 0.15)
    /// Normal ease for transitions
    static let normal = Animation.easeInOut(duration: 0.25)
    /// Slow ease for emphasis
    static let slow = Animation.easeInOut(duration: 0.35)

    /// Primary spring animation for interactive elements
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    /// Bouncy spring for playful feedback
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    /// Stiff spring for quick snaps
    static let springStiff = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Scale effect for button presses
    static let pressScale: CGFloat = 0.98
    /// Background tint opacity for pressed state
    static let pressTintOpacity: Double = 0.04
}
