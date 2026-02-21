import SwiftUI

struct ActivityFeedView: View {
    @State private var activities: [FeedActivity] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var hasMore = false
    @State private var nextCursor: ActivityCursor?

    var body: some View {
        Group {
            if isLoading && activities.isEmpty {
                LoadingFeedView()
            } else if let error = errorMessage, activities.isEmpty {
                FeedErrorView(message: error) {
                    Task { await loadActivity(refresh: true) }
                }
            } else if activities.isEmpty {
                EmptyFeedView()
            } else {
                FeedListView(
                    activities: activities,
                    hasMore: hasMore,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: {
                        Task { await loadMore() }
                    }
                )
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadActivity(refresh: true)
        }
        .refreshable {
            await loadActivity(refresh: true)
        }
    }

    private func loadActivity(refresh: Bool) async {
        if refresh {
            isLoading = true
            errorMessage = nil
            nextCursor = nil
        }

        do {
            let page = try await APIService.shared.getActivityFeed(cursor: refresh ? nil : nextCursor)
            await MainActor.run {
                if refresh {
                    activities = page.activities
                } else {
                    activities.append(contentsOf: page.activities)
                }
                hasMore = page.hasMore
                nextCursor = page.nextCursor
                isLoading = false
                isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                isLoadingMore = false
            }
        }
    }

    private func loadMore() async {
        guard hasMore, !isLoadingMore, nextCursor != nil else { return }
        isLoadingMore = true
        await loadActivity(refresh: false)
    }
}

// MARK: - Feed List View

struct FeedListView: View {
    let activities: [FeedActivity]
    let hasMore: Bool
    let isLoadingMore: Bool
    let onLoadMore: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: BLSpacing.md) {
                ForEach(activities) { activity in
                    FeedActivityCard(activity: activity)
                        .onAppear {
                            if activity.id == activities.last?.id && hasMore && !isLoadingMore {
                                onLoadMore()
                            }
                        }
                }

                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if hasMore {
                    SwiftUI.Button(action: onLoadMore) {
                        Text("Load More")
                            .font(BLTypography.labelLarge)
                            .foregroundColor(.blPrimary)
                            .padding()
                    }
                }
            }
            .padding(.horizontal, BLSpacing.lg)
            .padding(.vertical, BLSpacing.md)
        }
        .background(Color.blBackground)
    }
}

// MARK: - Feed Activity Card

struct FeedActivityCard: View {
    let activity: FeedActivity

    var body: some View {
        HStack(spacing: BLSpacing.md) {
            // Button icon
            ZStack {
                Circle()
                    .fill(Color(hex: activity.buttonColor ?? "#26A69A"))
                    .frame(width: 48, height: 48)

                if let icon = activity.buttonIcon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: BLSpacing.xs) {
                // User name and action
                HStack(spacing: BLSpacing.xs) {
                    Text(activity.displayUserName)
                        .font(BLTypography.titleSmall)
                        .foregroundColor(.blTextPrimary)

                    FeedActionBadge(action: activity.displayAction)
                }

                // Button name
                Text(activity.buttonName)
                    .font(BLTypography.bodyMedium)
                    .foregroundColor(.blTextSecondary)

                // Time and duration
                HStack(spacing: BLSpacing.xs) {
                    if let clickedAt = activity.clickedAt {
                        Text(clickedAt, style: .relative)
                            .font(BLTypography.caption)
                            .foregroundColor(.blTextTertiary)
                    }

                    if let duration = activity.duration, duration > 0 {
                        Text("\u{2022}")
                            .foregroundColor(.blTextTertiary)
                        Text(formatDuration(duration))
                            .font(BLTypography.caption)
                            .foregroundColor(.blTextTertiary)
                    }
                }
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

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

struct FeedActionBadge: View {
    let action: String

    var backgroundColor: Color {
        switch action {
        case "start": return Color.blSuccess.opacity(0.15)
        case "end", "stop": return Color.blSecondary.opacity(0.15)
        default: return Color.blPrimary.opacity(0.15)
        }
    }

    var textColor: Color {
        switch action {
        case "start": return .blSuccess
        case "end", "stop": return .blSecondary
        default: return .blPrimary
        }
    }

    var displayText: String {
        switch action {
        case "start": return "started"
        case "end", "stop": return "stopped"
        case "click": return "completed"
        default: return action
        }
    }

    var body: some View {
        Text(displayText)
            .font(BLTypography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, BLSpacing.sm)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(BLRadius.sm)
    }
}

// MARK: - Empty and Loading States

struct LoadingFeedView: View {
    var body: some View {
        VStack(spacing: BLSpacing.lg) {
            ProgressView()
            Text("Loading activity...")
                .font(BLTypography.bodyMedium)
                .foregroundColor(.blTextSecondary)
        }
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.badge")
                    .font(.system(size: 40))
                    .foregroundColor(.blPrimary)
            }

            VStack(spacing: BLSpacing.sm) {
                Text("No Activity Yet")
                    .font(BLTypography.headlineMedium)
                    .foregroundColor(.blTextPrimary)

                Text("When your friends complete buttons, you'll see their activity here")
                    .font(BLTypography.bodyLarge)
                    .foregroundColor(.blTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BLSpacing.xxl)
            }

            Spacer()
        }
        .background(Color.blBackground)
    }
}

struct FeedErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.blWarning)

            VStack(spacing: BLSpacing.sm) {
                Text("Couldn't Load Activity")
                    .font(BLTypography.headlineMedium)
                    .foregroundColor(.blTextPrimary)

                Text(message)
                    .font(BLTypography.bodyMedium)
                    .foregroundColor(.blTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BLSpacing.xxl)
            }

            SwiftUI.Button(action: onRetry) {
                Text("Try Again")
                    .font(BLTypography.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, BLSpacing.xl)
                    .padding(.vertical, BLSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BLRadius.lg)
                            .fill(Color.blPrimary)
                    )
            }

            Spacer()
        }
        .background(Color.blBackground)
    }
}

#Preview {
    NavigationView {
        ActivityFeedView()
    }
}
