import SwiftUI

// MARK: - ButtonLog Design System
// Unified design tokens for consistent UI across all platforms

// MARK: - Colors

extension Color {

    // MARK: Primary Colors
    /// Main brand color - Vibrant Teal
    static let blPrimary = Color(hex: "00BFA5")
    /// Darker variant for pressed states
    static let blPrimaryDark = Color(hex: "00897B")
    /// Lighter variant for backgrounds
    static let blPrimaryLight = Color(hex: "B2DFDB")

    // MARK: Secondary Colors
    /// Accent color - Coral Orange
    static let blSecondary = Color(hex: "FF6B6B")
    /// Darker variant
    static let blSecondaryDark = Color(hex: "E55555")
    /// Lighter variant
    static let blSecondaryLight = Color(hex: "FFCDD2")

    // MARK: Neutral Colors
    static let blBackground = Color(hex: "FAFAFA")
    static let blBackgroundDark = Color(hex: "121212")
    static let blSurface = Color(hex: "FFFFFF")
    static let blSurfaceDark = Color(hex: "1E1E1E")
    static let blSurfaceElevated = Color(hex: "F5F5F5")
    static let blSurfaceElevatedDark = Color(hex: "2C2C2C")

    // MARK: Text Colors
    static let blTextPrimary = Color(hex: "1A1A1A")
    static let blTextPrimaryDark = Color(hex: "FFFFFF")
    static let blTextSecondary = Color(hex: "666666")
    static let blTextSecondaryDark = Color(hex: "B3B3B3")
    static let blTextTertiary = Color(hex: "999999")
    static let blTextTertiaryDark = Color(hex: "808080")

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
    static let blButtonTeal = Color(hex: "00BFA5")
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
    // MARK: Display
    static let displayLarge = Font.system(size: 57, weight: .regular)
    static let displayMedium = Font.system(size: 45, weight: .regular)
    static let displaySmall = Font.system(size: 36, weight: .regular)

    // MARK: Headlines
    static let headlineLarge = Font.system(size: 32, weight: .semibold)
    static let headlineMedium = Font.system(size: 28, weight: .semibold)
    static let headlineSmall = Font.system(size: 24, weight: .semibold)

    // MARK: Titles
    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 16, weight: .semibold)
    static let titleSmall = Font.system(size: 14, weight: .semibold)

    // MARK: Body
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)

    // MARK: Labels
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
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
    /// 8pt - Medium radius for inputs, small cards
    static let md: CGFloat = 8
    /// 12pt - Large radius for cards
    static let lg: CGFloat = 12
    /// 16pt - Extra large radius for sheets, modals
    static let xl: CGFloat = 16
    /// 24pt - Full round for pills, FABs
    static let full: CGFloat = 24
}

// MARK: - Shadows

struct BLShadow {
    static let small = BLShadowStyle(color: Color.black.opacity(0.08), radius: 4, y: 2)
    static let medium = BLShadowStyle(color: Color.black.opacity(0.12), radius: 8, y: 4)
    static let large = BLShadowStyle(color: Color.black.opacity(0.16), radius: 16, y: 8)
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

    func blCard() -> some View {
        self
            .background(Color.blSurface)
            .cornerRadius(BLRadius.lg)
            .blShadow(BLShadow.small)
    }

    func blCardElevated() -> some View {
        self
            .background(Color.blSurface)
            .cornerRadius(BLRadius.lg)
            .blShadow(BLShadow.medium)
    }
}

// MARK: - Button Styles

struct BLPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(.white)
            .padding(.horizontal, BLSpacing.lg)
            .padding(.vertical, BLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BLRadius.md)
                    .fill(isEnabled ? Color.blPrimary : Color.blTextTertiary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BLSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(isEnabled ? .blPrimary : .blTextTertiary)
            .padding(.horizontal, BLSpacing.lg)
            .padding(.vertical, BLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BLRadius.md)
                    .stroke(isEnabled ? Color.blPrimary : Color.blTextTertiary, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BLTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BLTypography.labelLarge)
            .foregroundColor(.blPrimary)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
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
    static let fast = Animation.easeInOut(duration: 0.15)
    static let normal = Animation.easeInOut(duration: 0.25)
    static let slow = Animation.easeInOut(duration: 0.35)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
