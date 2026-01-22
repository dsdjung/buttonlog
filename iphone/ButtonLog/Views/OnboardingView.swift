import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage(onNext: { withAnimation { currentPage = 1 } })
                        .tag(0)
                    FeaturesPage(onNext: { withAnimation { currentPage = 2 } })
                        .tag(1)
                    ButtonTypesPage(onNext: { withAnimation { currentPage = 3 } })
                        .tag(2)
                    GetStartedPage(onComplete: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        Task {
            await authManager.completeOnboarding()
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 12) {
                Text("Welcome to ButtonLog")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Track anything with the tap of a button")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Features Page

struct FeaturesPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What You Can Do")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 24) {
                FeatureRow(
                    icon: "plus.circle.fill",
                    title: "Track Anything",
                    description: "Create custom buttons for habits, activities, or events"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "See Your Progress",
                    description: "View history and analytics of your clicks"
                )

                FeatureRow(
                    icon: "person.2.fill",
                    title: "Connect with Friends",
                    description: "Share buttons and see friend activity"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Button Types Page

struct ButtonTypesPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Button Types")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                ButtonTypeCard(
                    icon: "bolt.fill",
                    color: .orange,
                    title: "Instant",
                    description: "Single click actions for quick tracking"
                )

                ButtonTypeCard(
                    icon: "power",
                    color: .green,
                    title: "Toggle",
                    description: "Start/stop with duration tracking"
                )

                ButtonTypeCard(
                    icon: "1.circle.fill",
                    color: .blue,
                    title: "One-Time",
                    description: "Use once, then archived"
                )

                ButtonTypeCard(
                    icon: "list.bullet",
                    color: .purple,
                    title: "Workflow",
                    description: "Predefined sequence of states"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct ButtonTypeCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Get Started Page

struct GetStartedPage: View {
    let onComplete: () -> Void
    @State private var selectedAction: GetStartedAction?

    enum GetStartedAction {
        case createButton
        case explore
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Ready to start tracking?")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                SwiftUI.Button(action: {
                    selectedAction = .createButton
                    onComplete()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your First Button")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                SwiftUI.Button(action: {
                    selectedAction = .explore
                    onComplete()
                }) {
                    Text("Explore First")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}
