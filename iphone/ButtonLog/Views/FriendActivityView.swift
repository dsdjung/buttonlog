import SwiftUI

struct FriendActivityView: View {
    let friend: Friend
    @State private var activities: [FriendActivity] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var hasPermission = true
    @State private var hasMore = false
    @State private var nextCursor: ActivityCursor?

    var body: some View {
        Group {
            if isLoading && activities.isEmpty {
                ProgressView("Loading activity...")
            } else if !hasPermission {
                NoPermissionView(friendName: friend.friendUser.displayNameOrUsername)
            } else if let error = errorMessage, activities.isEmpty {
                ErrorView(message: error) {
                    Task { await loadActivity(refresh: true) }
                }
            } else if activities.isEmpty {
                EmptyActivityView(friendName: friend.friendUser.displayNameOrUsername)
            } else {
                ActivityListView(
                    activities: activities,
                    hasMore: hasMore,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: {
                        Task { await loadMore() }
                    }
                )
            }
        }
        .navigationTitle("\(friend.friendUser.displayNameOrUsername)'s Activity")
        .navigationBarTitleDisplayMode(.inline)
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
            print("[FriendActivityView] Loading activity for friend: \(friend.friendId), refresh: \(refresh)")
            let page = try await APIService.shared.getFriendActivity(friendId: friend.friendId, cursor: refresh ? nil : nextCursor)
            print("[FriendActivityView] Received \(page.activities.count) activities, hasMore: \(page.hasMore)")
            await MainActor.run {
                if refresh {
                    activities = page.activities
                } else {
                    activities.append(contentsOf: page.activities)
                }
                print("[FriendActivityView] Total activities now: \(activities.count)")
                hasMore = page.hasMore
                nextCursor = page.nextCursor
                hasPermission = true
                isLoading = false
                isLoadingMore = false
            }
        } catch let error as APIError {
            await MainActor.run {
                if case .serverError(let message) = error,
                   message.contains("permission") || message.contains("PERMISSION_DENIED") {
                    hasPermission = false
                } else {
                    errorMessage = error.localizedDescription
                }
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

struct ActivityListView: View {
    let activities: [FriendActivity]
    let hasMore: Bool
    let isLoadingMore: Bool
    let onLoadMore: () -> Void

    var body: some View {
        List {
            ForEach(activities) { activity in
                ActivityRow(activity: activity)
                    .onAppear {
                        // Load more when approaching the end
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
                .listRowSeparator(.hidden)
            } else if hasMore {
                SwiftUI.Button(action: onLoadMore) {
                    HStack {
                        Spacer()
                        Text("Load More")
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}

struct ActivityRow: View {
    let activity: FriendActivity

    var body: some View {
        HStack(spacing: 12) {
            // Button icon circle
            ZStack {
                Circle()
                    .fill(Color(hex: activity.buttonColor ?? "#007AFF"))
                    .frame(width: 44, height: 44)

                Text(activity.buttonTypeEmoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.buttonName)
                        .font(.headline)

                    Spacer()

                    ActionBadge(action: activity.displayAction)
                }

                HStack {
                    if let clickedAt = activity.clickedAt {
                        Text(clickedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unknown time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let duration = activity.duration {
                        Text("\u{2022}")
                            .foregroundColor(.secondary)
                        Text("\(duration)s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActionBadge: View {
    let action: String

    var backgroundColor: Color {
        switch action {
        case "start": return .green.opacity(0.2)
        case "end": return .red.opacity(0.2)
        default: return .blue.opacity(0.2)
        }
    }

    var textColor: Color {
        switch action {
        case "start": return .green
        case "end": return .red
        default: return .blue
        }
    }

    var body: some View {
        Text(action)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
}

struct NoPermissionView: View {
    let friendName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Activity History Private")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(friendName) has not granted you permission to view their activity history.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct EmptyActivityView: View {
    let friendName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Activity Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(friendName) hasn't recorded any button activity yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error Loading Activity")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            SwiftUI.Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    NavigationView {
        FriendActivityView(friend: Friend(
            id: "1",
            friendId: "2",
            friendUser: PublicUser(
                id: "2",
                username: "testuser",
                displayName: "Test User",
                firstName: "Test",
                lastName: "User",
                profileVisibility: .publicProfile
            ),
            status: .accepted,
            permissions: FriendPermissions(
                canSeeButtons: true,
                canSeeActivity: true,
                receiveNotifications: true,
                canComment: true
            ),
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
