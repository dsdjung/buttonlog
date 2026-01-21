import SwiftUI

struct FriendButtonsView: View {
    let friend: Friend

    @State private var buttons: [ButtonLog.Button] = []
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
    }

    private func loadButtons() {
        isLoading = true
        errorMessage = nil

        Task {
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
}

struct FriendButtonCard: View {
    let button: ButtonLog.Button

    var body: some View {
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
