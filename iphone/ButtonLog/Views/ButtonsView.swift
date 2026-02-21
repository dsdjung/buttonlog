import SwiftUI

struct ButtonsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var showingCreateButton = false
    @State private var selectedButton: ButtonModel?
    @State private var historyButton: ButtonModel?
    @State private var sharingButton: ButtonModel?
    @State private var alertSettingsButton: ButtonModel?
    @State private var streakData: StreakData?

    var filteredButtons: [ButtonModel] {
        if searchText.isEmpty {
            return appState.buttons
        } else {
            return appState.buttons.filter { button in
                button.name.localizedCaseInsensitiveContains(searchText) ||
                (button.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar with + button
            HStack(spacing: BLSpacing.md) {
                SearchBar(text: $searchText)

                SwiftUI.Button(action: {
                    showingCreateButton = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .stroke(Color.blPrimary, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, BLSpacing.lg)
            .padding(.top, BLSpacing.md)
            .padding(.bottom, BLSpacing.sm)

            // Main content with pull-to-refresh support
            ScrollView {
                if appState.isLoadingButtons && appState.buttons.isEmpty {
                    // Loading state
                    VStack(spacing: BLSpacing.md) {
                        ProgressView()
                            .tint(.blPrimary)
                        Text("Loading buttons...")
                            .font(BLTypography.bodyMedium)
                            .foregroundColor(.blTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .padding(.top, 100)

                } else if filteredButtons.isEmpty {
                    // Empty state
                    EmptyStateView {
                        showingCreateButton = true
                    }

                } else {
                    // Buttons list
                    LazyVStack(spacing: BLSpacing.lg) {
                        // Streak Card (if data available)
                        if let streak = streakData, streak.totalActiveDays > 0 {
                            StreakCard(streakData: streak)
                                .padding(.horizontal, BLSpacing.lg)
                        }

                        ForEach(filteredButtons) { button in
                            ButtonCard(
                                button: button,
                                isClicking: appState.clickingButtonIds.contains(button.id),
                                onTap: {
                                    Task {
                                        await appState.clickButton(id: button.id)
                                    }
                                },
                                onTapWithChoice: { choice in
                                    Task {
                                        await appState.clickButton(id: button.id, choice: choice)
                                    }
                                },
                                onEdit: {
                                    selectedButton = button
                                },
                                onHistory: {
                                    historyButton = button
                                },
                                onSharing: {
                                    sharingButton = button
                                },
                                onAlertSettings: {
                                    alertSettingsButton = button
                                }
                            )
                        }
                    }
                    .padding(BLSpacing.lg)
                    .padding(.bottom, 80) // Space for floating button
                }
            }
            .refreshable {
                await appState.loadButtons()
                await loadStreaks()
            }
        }
        .background(Color.blBackground)
        .navigationBarHidden(true)
        .task {
            await loadStreaks()
        }
        .sheet(isPresented: $showingCreateButton) {
            CreateButtonView()
        }
        .sheet(item: $selectedButton) { button in
            EditButtonView(button: button)
        }
        .sheet(item: $historyButton) { button in
            ButtonHistoryView(button: button)
        }
        .sheet(item: $sharingButton) { button in
            ButtonSharingView(button: button)
        }
        .sheet(item: $alertSettingsButton) { button in
            ButtonAlertSettingsView(button: button)
        }
    }

    private func loadStreaks() async {
        do {
            let data = try await APIService.shared.getStreaks()
            await MainActor.run {
                streakData = data
            }
        } catch {
            // Silently fail - streak is optional UI enhancement
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streakData: StreakData

    var body: some View {
        HStack(spacing: BLSpacing.lg) {
            // Streak emoji and count
            VStack(spacing: 4) {
                Text(streakData.streakEmoji)
                    .font(.system(size: 32))
                Text("\(streakData.currentStreak)")
                    .font(BLTypography.headlineLarge)
                    .foregroundColor(.blTextPrimary)
                Text("day streak")
                    .font(BLTypography.caption)
                    .foregroundColor(.blTextSecondary)
            }
            .frame(minWidth: 80)

            Divider()
                .frame(height: 50)

            // Stats
            VStack(alignment: .leading, spacing: BLSpacing.sm) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                    Text("Longest: \(streakData.longestStreak) days")
                        .font(BLTypography.bodySmall)
                        .foregroundColor(.blTextSecondary)
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blPrimary)
                        .font(.system(size: 14))
                    Text("Total: \(streakData.totalActiveDays) active days")
                        .font(BLTypography.bodySmall)
                        .foregroundColor(.blTextSecondary)
                }
            }

            Spacer()
        }
        .padding(BLSpacing.lg)
        .background(Color.blSurface)
        .cornerRadius(BLRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BLRadius.xl)
                .stroke(streakData.currentStreak > 0 ? Color.blPrimary.opacity(0.3) : Color.blBorder, lineWidth: 1)
        )
    }
}

struct ButtonCard: View {
    let button: ButtonModel
    var isClicking: Bool = false
    let onTap: () -> Void
    var onTapWithChoice: ((String) -> Void)? = nil
    let onEdit: () -> Void
    let onHistory: () -> Void
    var onSharing: (() -> Void)? = nil
    var onAlertSettings: (() -> Void)? = nil

    @State private var isPressed = false
    @State private var pressedChoice: String? = nil

    // One-time buttons should be disabled while clicking
    private var isButtonDisabled: Bool {
        isClicking && button.type == .oneTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.md) {
            // Header
            HStack {
                // Outlined icon circle - minimal aesthetic
                ZStack {
                    Circle()
                        .stroke(button.uiColor, lineWidth: 2)
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForButton(button.icon))
                        .foregroundColor(button.uiColor)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: BLSpacing.xs) {
                    Text(button.name)
                        .font(BLTypography.titleMedium)
                        .foregroundColor(.blTextPrimary)

                    if let description = button.description, !description.isEmpty {
                        Text(description)
                            .font(BLTypography.bodyMedium)
                            .foregroundColor(.blTextSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: BLSpacing.sm) {
                        ButtonTypeTag(type: button.type)

                        if button.currentState == .active {
                            ButtonStateTag(state: button.currentState)
                        }

                        if button.isGift, let fromName = button.giftFromName {
                            GiftBadge(fromName: fromName)
                        }

                        if button.isShared, let ownerName = button.ownerName {
                            SharedWithMeBadge(ownerName: ownerName)
                        }
                    }
                }

                Spacer()

                // Settings menu - different options for owned vs shared buttons
                Menu {
                    SwiftUI.Button(action: onHistory) {
                        Label("History", systemImage: "clock")
                    }

                    if button.isOwner {
                        SwiftUI.Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        if let onSharing = onSharing {
                            SwiftUI.Button(action: onSharing) {
                                Label("Sharing", systemImage: "person.2")
                            }
                        }

                        if let onAlertSettings = onAlertSettings {
                            SwiftUI.Button(action: onAlertSettings) {
                                Label("Alert Settings", systemImage: "bell")
                            }
                        }

                        Divider()

                        SwiftUI.Button(role: .destructive) {
                            Task {
                                await AppState().deleteButton(id: button.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blTextSecondary)
                        .font(.title3)
                }
            }

            // Click Button(s) - show choice buttons for one-time buttons with choices
            if button.hasChoices, let choices = button.choices {
                VStack(spacing: BLSpacing.sm) {
                    if isButtonDisabled {
                        // Show loading state when clicking
                        HStack(spacing: BLSpacing.sm) {
                            ProgressView()
                                .tint(.white)
                            Text("Completing...")
                                .font(BLTypography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BLSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: BLRadius.md)
                                .fill(button.uiColor.opacity(0.6))
                        )
                    } else {
                        Text("Select an option:")
                            .font(BLTypography.labelSmall)
                            .foregroundColor(.blTextSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BLSpacing.sm) {
                            ForEach(choices, id: \.self) { choice in
                                SwiftUI.Button(action: {
                                    withAnimation(BLAnimation.fast) {
                                        pressedChoice = choice
                                    }

                                    onTapWithChoice?(choice) ?? onTap()

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        pressedChoice = nil
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .font(BLTypography.bodyMedium)

                                        Text(choice)
                                            .font(BLTypography.bodyMedium)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, BLSpacing.md)
                                    .padding(.horizontal, BLSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: BLRadius.md)
                                            .fill(button.uiColor)
                                            .scaleEffect(pressedChoice == choice ? 0.96 : 1.0)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            } else {
                SwiftUI.Button(action: {
                    withAnimation(BLAnimation.spring) {
                        isPressed = true
                    }

                    onTap()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(BLAnimation.spring) {
                            isPressed = false
                        }
                    }
                }) {
                    HStack(spacing: BLSpacing.sm) {
                        if isButtonDisabled {
                            ProgressView()
                                .tint(.white)
                            Text("Completing...")
                                .font(BLTypography.labelLarge)
                        } else {
                            Image(systemName: buttonActionIcon(for: button))
                                .font(.system(size: 16, weight: .medium))

                            Text(buttonActionText(for: button))
                                .font(BLTypography.labelLarge)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(isButtonDisabled ? button.uiColor.opacity(0.6) : button.uiColor)
                    )
                    .scaleEffect(isPressed ? BLAnimation.pressScale : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isButtonDisabled)
            }
        }
        .padding(BLSpacing.xl)
        .background(Color.blSurface)
        .cornerRadius(BLRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BLRadius.xl)
                .stroke(Color.blBorder, lineWidth: 1)
        )
        .scaleEffect(isPressed ? BLAnimation.pressScale : 1.0)
        .animation(BLAnimation.spring, value: isPressed)
    }

    private func iconForButton(_ icon: String) -> String {
        // Icon mapping matches Android's Material Icons for consistency
        let iconMap: [String: String] = [
            "star": "star.fill",
            "heart": "heart.fill",
            "bolt": "bolt.fill",
            "flame": "flame.fill",
            "leaf": "leaf.fill",
            "drop": "drop.fill",
            "sun": "sun.max.fill",
            "moon": "moon.fill",
            "cloud": "cloud.fill",
            "snowflake": "snowflake",
            "car": "car.fill",
            "airplane": "airplane",
            "gamecontroller": "gamecontroller.fill",
            "book": "book.fill",
            "pencil": "pencil",
            "scissors": "scissors",
            "wrench": "wrench.fill",
            "hammer": "hammer.fill",
            "gear": "gear",
            "lock": "lock.fill"
        ]

        return iconMap[icon] ?? "star.fill"
    }

    private func buttonActionIcon(for button: ButtonModel) -> String {
        switch button.type {
        case .instant:
            return "hand.tap"
        case .toggle:
            return button.currentState == .idle ? "play.fill" : "stop.fill"
        case .oneTime:
            return "checkmark.circle"
        case .workflow:
            return "arrow.right"
        }
    }

    private func buttonActionText(for button: ButtonModel) -> String {
        switch button.type {
        case .instant:
            return "Click!"
        case .toggle:
            return button.currentState == .idle ? "Start" : "Stop"
        case .oneTime:
            return "Complete"
        case .workflow:
            return "Next"
        }
    }
}

struct ButtonTypeTag: View {
    let type: ButtonType

    var body: some View {
        Text(type.displayName)
            .font(BLTypography.labelSmall)
            .padding(.horizontal, BLSpacing.sm)
            .padding(.vertical, BLSpacing.xs)
            .background(Color.blSurfaceElevated)
            .foregroundColor(.blTextSecondary)
            .cornerRadius(BLRadius.sm)
    }
}

struct ButtonStateTag: View {
    let state: ButtonState

    var body: some View {
        Text(state.displayName)
            .font(BLTypography.labelSmall)
            .padding(.horizontal, BLSpacing.sm)
            .padding(.vertical, BLSpacing.xs)
            .background(state.color.opacity(0.2))
            .foregroundColor(state.color)
            .cornerRadius(BLRadius.sm)
    }
}

struct GiftBadge: View {
    let fromName: String

    var body: some View {
        HStack(spacing: BLSpacing.xs) {
            Image(systemName: "gift.fill")
                .font(.caption2)
            Text("From \(fromName)")
                .font(BLTypography.labelSmall)
        }
        .padding(.horizontal, BLSpacing.sm)
        .padding(.vertical, BLSpacing.xs)
        .background(Color.blButtonPurple.opacity(0.2))
        .foregroundColor(.blButtonPurple)
        .cornerRadius(BLRadius.sm)
    }
}

struct SharedWithMeBadge: View {
    let ownerName: String

    var body: some View {
        HStack(spacing: BLSpacing.xs) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
            Text("Shared by \(ownerName)")
                .font(BLTypography.labelSmall)
        }
        .padding(.horizontal, BLSpacing.sm)
        .padding(.vertical, BLSpacing.xs)
        .background(Color.blButtonBlue.opacity(0.2))
        .foregroundColor(.blButtonBlue)
        .cornerRadius(BLRadius.sm)
    }
}

struct EmptyStateView: View {
    let onCreateButton: () -> Void

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            // Large outlined icon
            Image(systemName: "plus.circle")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.blTextTertiary)

            VStack(spacing: BLSpacing.sm) {
                Text("No buttons yet")
                    .font(BLTypography.displaySmall)
                    .foregroundColor(.blTextPrimary)

                Text("Create your first button to start tracking activities")
                    .font(BLTypography.bodyLarge)
                    .foregroundColor(.blTextSecondary)
                    .multilineTextAlignment(.center)
            }

            SwiftUI.Button("Create Button") {
                onCreateButton()
            }
            .buttonStyle(.blPrimary)
        }
        .padding(BLSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: BLSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.blTextTertiary)

            TextField("Search buttons...", text: $text)
                .font(BLTypography.bodyMedium)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                SwiftUI.Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blTextTertiary)
                }
            }
        }
        .padding(.horizontal, BLSpacing.lg)
        .padding(.vertical, BLSpacing.md)
        .background(Color.blSurfaceElevated)
        .cornerRadius(BLRadius.full)  // Pill shape
    }
}

#Preview {
    NavigationView {
        ButtonsView()
            .environmentObject(AppState())
    }
}
