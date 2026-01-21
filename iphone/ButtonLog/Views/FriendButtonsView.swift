import SwiftUI
import CoreLocation

struct FriendButtonsView: View {
    let friend: Friend

    @State private var buttons: [FriendButton] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading buttons...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    SwiftUI.Button("Retry") {
                        loadButtons()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if buttons.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.badge.minus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No Buttons")
                        .font(.headline)

                    Text("\(friend.friendUser.displayNameOrUsername) hasn't created any buttons yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(buttons) { button in
                            FriendButtonCard(button: button)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(friend.friendUser.displayNameOrUsername)'s Buttons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadButtons()
        }
        .refreshable {
            await refreshButtons()
        }
    }

    private func loadButtons() {
        isLoading = true
        errorMessage = nil

        Task {
            await refreshButtons()
        }
    }

    private func refreshButtons() async {
        do {
            let fetchedButtons = try await APIService.shared.getFriendButtons(friendId: friend.friendId)
            await MainActor.run {
                buttons = fetchedButtons
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct FriendButtonCard: View {
    let button: FriendButton

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Icon, name, type, and state
            HStack(spacing: 16) {
                // Button icon
                ZStack {
                    Circle()
                        .fill(button.uiColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: iconName(for: button.icon))
                        .font(.title3)
                        .foregroundColor(.white)
                }

                // Button info
                VStack(alignment: .leading, spacing: 4) {
                    Text(button.name)
                        .font(.headline)

                    Text(button.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }

                Spacer()

                // State indicator for state/timed buttons
                if button.type != .instant {
                    Text(button.currentState == .active ? "Active" : "Idle")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(button.currentState == .active ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .foregroundColor(button.currentState == .active ? .green : .secondary)
                        .cornerRadius(6)
                }
            }

            // Latest activity section
            if button.latestClickAt != nil {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    // Last activity time and action
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Last activity:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let clickAt = button.latestClickAt {
                            Text(clickAt, style: .relative)
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        if let action = button.latestClickAction {
                            ActionBadgeSmall(action: action)
                        }
                    }

                    // Location if available
                    if let location = button.latestClickLocation {
                        HStack(spacing: 8) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(formatCoordinates(lat: location.lat, lng: location.lng))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Device/platform info
                    if button.latestClickDevice != nil || button.latestClickPlatform != nil {
                        HStack(spacing: 8) {
                            Image(systemName: platformIcon(for: button.latestClickPlatform))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let device = button.latestClickDevice {
                                Text(device)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let platform = button.latestClickPlatform {
                                Text("(\(platform))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("No activity yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func iconName(for icon: String) -> String {
        let iconMap: [String: String] = [
            "star": "star.fill",
            "heart": "heart.fill",
            "bolt": "bolt.fill",
            "flame": "flame.fill",
            "leaf": "leaf.fill",
            "drop": "drop.fill",
            "sun": "sun.max.fill",
            "moon": "moon.fill",
            "car": "car.fill",
            "book": "book.fill",
            "pencil": "pencil",
            "gear": "gearshape.fill"
        ]
        return iconMap[icon] ?? "star.fill"
    }

    private func formatCoordinates(lat: Double, lng: Double) -> String {
        let latDir = lat >= 0 ? "N" : "S"
        let lngDir = lng >= 0 ? "E" : "W"
        return String(format: "%.4f°%@ %.4f°%@", abs(lat), latDir, abs(lng), lngDir)
    }

    private func platformIcon(for platform: String?) -> String {
        switch platform {
        case "iphone": return "iphone"
        case "android": return "candybarphone"
        case "web": return "globe"
        default: return "desktopcomputer"
        }
    }
}

struct ActionBadgeSmall: View {
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
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
}

#Preview {
    NavigationView {
        FriendButtonsView(
            friend: Friend(
                id: "1",
                friendId: "friend1",
                friendUser: PublicUser(
                    id: "friend1",
                    username: "john",
                    displayName: "John Doe",
                    firstName: "John",
                    lastName: "Doe",
                    profileVisibility: .friends
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
            )
        )
    }
}
