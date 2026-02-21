import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Subtle gradient background matching design system
            LinearGradient(
                gradient: Gradient(colors: [Color.blPrimary.opacity(0.05), Color.blSecondary.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 3 {
                        SwiftUI.Button(action: { withAnimation { currentPage = 3 } }) {
                            Text("Skip")
                                .font(BLTypography.labelLarge)
                                .foregroundColor(.blTextSecondary)
                        }
                        .padding(.trailing, BLSpacing.lg)
                        .padding(.top, BLSpacing.md)
                    }
                }
                .frame(height: 44)

                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage(onNext: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { currentPage = 1 } })
                        .tag(0)
                    SocialValuePage(onNext: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { currentPage = 2 } })
                        .tag(1)
                    HowItWorksPage(onNext: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { currentPage = 3 } })
                        .tag(2)
                    GetStartedPage(onComplete: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: BLSpacing.sm) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blPrimary : Color.blTextTertiary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(BLAnimation.spring, value: currentPage)
                    }
                }
                .padding(.bottom, BLSpacing.xxl)
            }
        }
    }

    private func completeOnboarding() {
        Task {
            await authManager.completeOnboarding()
        }
    }
}

// MARK: - Welcome Page (Social-First Messaging)

struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            // Two people icon to emphasize social
            ZStack {
                Circle()
                    .fill(Color.blPrimary.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blPrimary)
            }

            VStack(spacing: BLSpacing.md) {
                Text("Track Anything.")
                    .font(BLTypography.displaySmall)
                    .foregroundColor(.blTextPrimary)

                Text("Hold Each Other Accountable.")
                    .font(BLTypography.headlineMedium)
                    .foregroundColor(.blPrimary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, BLSpacing.xl)

            Text("Create buttons for the things you want to track. Share with friends who keep you on track.")
                .font(BLTypography.bodyLarge)
                .foregroundColor(.blTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BLSpacing.xxl)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Get Started")
                    .font(BLTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(Color.blPrimary)
                    )
            }
            .padding(.horizontal, BLSpacing.xl)
            .padding(.bottom, BLSpacing.lg)
        }
    }
}

// MARK: - Social Value Page

struct SocialValuePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            Text("Accountability That Works")
                .font(BLTypography.headlineLarge)
                .foregroundColor(.blTextPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: BLSpacing.lg) {
                SocialFeatureRow(
                    icon: "gift.fill",
                    color: .purple,
                    title: "Gift Buttons to Friends",
                    description: "Create a button for someone else — like \"Drink water\" for your partner"
                )

                SocialFeatureRow(
                    icon: "bell.badge.fill",
                    color: .blPrimary,
                    title: "See When They Complete It",
                    description: "Get notified when your friend taps their button"
                )

                SocialFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    color: .blSecondary,
                    title: "They See Yours Too",
                    description: "Mutual accountability keeps both of you on track"
                )
            }
            .padding(.horizontal, BLSpacing.lg)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Continue")
                    .font(BLTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(Color.blPrimary)
                    )
            }
            .padding(.horizontal, BLSpacing.xl)
            .padding(.bottom, BLSpacing.lg)
        }
    }
}

struct SocialFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: BLSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: BLSpacing.xs) {
                Text(title)
                    .font(BLTypography.titleMedium)
                    .foregroundColor(.blTextPrimary)

                Text(description)
                    .font(BLTypography.bodyMedium)
                    .foregroundColor(.blTextSecondary)
            }

            Spacer()
        }
        .padding(BLSpacing.lg)
        .background(Color.blSurface)
        .cornerRadius(BLRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BLRadius.xl)
                .stroke(Color.blBorder, lineWidth: 1)
        )
    }
}

// MARK: - How It Works Page

struct HowItWorksPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            Text("How It Works")
                .font(BLTypography.headlineLarge)
                .foregroundColor(.blTextPrimary)

            // Visual flow
            VStack(spacing: BLSpacing.xl) {
                OnboardingStepCard(
                    number: "1",
                    title: "Create a Button",
                    description: "Pick what you want to track — exercise, water, medication, anything",
                    icon: "plus.circle.fill"
                )

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.blTextTertiary)

                OnboardingStepCard(
                    number: "2",
                    title: "Invite Your Partner",
                    description: "Share with someone who will keep you accountable",
                    icon: "person.badge.plus"
                )

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.blTextTertiary)

                OnboardingStepCard(
                    number: "3",
                    title: "Tap & Track Together",
                    description: "You both see progress — celebrating wins, staying on track",
                    icon: "hand.tap.fill"
                )
            }
            .padding(.horizontal, BLSpacing.lg)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Continue")
                    .font(BLTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(Color.blPrimary)
                    )
            }
            .padding(.horizontal, BLSpacing.xl)
            .padding(.bottom, BLSpacing.lg)
        }
    }
}

struct OnboardingStepCard: View {
    let number: String
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: BLSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.blPrimary)
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(BLTypography.labelLarge)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: BLSpacing.xs) {
                Text(title)
                    .font(BLTypography.titleMedium)
                    .foregroundColor(.blTextPrimary)

                Text(description)
                    .font(BLTypography.bodySmall)
                    .foregroundColor(.blTextSecondary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blPrimary.opacity(0.5))
        }
        .padding(BLSpacing.md)
        .background(Color.blSurfaceElevated)
        .cornerRadius(BLRadius.lg)
    }
}

// MARK: - Get Started Page

struct GetStartedPage: View {
    let onComplete: () -> Void
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            VStack(spacing: BLSpacing.sm) {
                Text("You're Ready!")
                    .font(BLTypography.headlineLarge)
                    .foregroundColor(.blTextPrimary)

                Text("Create your first button and invite a friend to get started")
                    .font(BLTypography.bodyLarge)
                    .foregroundColor(.blTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BLSpacing.xl)
            }

            // Preview of what they'll see
            NotificationPreviewCard()
                .padding(.horizontal, BLSpacing.lg)

            Spacer()

            VStack(spacing: BLSpacing.md) {
                SwiftUI.Button(action: {
                    onComplete()
                }) {
                    HStack(spacing: BLSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Create My First Button")
                            .font(BLTypography.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(Color.blPrimary)
                    )
                }

                SwiftUI.Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: BLSpacing.sm) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                        Text("Invite a Friend First")
                            .font(BLTypography.labelLarge)
                    }
                    .foregroundColor(.blPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .stroke(Color.blPrimary, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, BLSpacing.xl)
            .padding(.bottom, BLSpacing.lg)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "Join me on ButtonLog! Let's keep each other accountable. Download the app: https://buttonlog.com/download"
            ])
        }
    }
}

// MARK: - Notification Preview Card

struct NotificationPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.sm) {
            Text("What you'll see:")
                .font(BLTypography.labelMedium)
                .foregroundColor(.blTextTertiary)

            HStack(spacing: BLSpacing.md) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.blPrimary.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sarah completed \"Drink water\"")
                        .font(BLTypography.titleSmall)
                        .foregroundColor(.blTextPrimary)

                    Text("Just now")
                        .font(BLTypography.bodySmall)
                        .foregroundColor(.blTextTertiary)
                }

                Spacer()
            }
            .padding(BLSpacing.md)
            .background(Color.blSurface)
            .cornerRadius(BLRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BLRadius.lg)
                    .stroke(Color.blBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}
