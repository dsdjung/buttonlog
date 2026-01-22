import SwiftUI

// Navigation destination enum for notifications
enum NotificationDestination {
    case button(String)
    case friend(String)  // Navigate to specific friend's page
    case friends         // Navigate to friends list
    case support
    case supportTicket(String)
    case none
}

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingUnreadOnly = false
    @State private var selectedButtonId: String?
    @State private var selectedTicketId: String?
    @State private var selectedFriendId: String?
    @State private var navigateToFriends = false
    @State private var navigateToSupport = false

    var filteredNotifications: [AppNotification] {
        if showingUnreadOnly {
            return appState.notifications.filter { !$0.isRead }
        } else {
            return appState.notifications
        }
    }

    var body: some View {
        Group {
            if appState.isLoadingNotifications && appState.notifications.isEmpty {
                // Loading state
                VStack {
                    ProgressView()
                    Text("Loading notifications...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if filteredNotifications.isEmpty {
                // Empty state - wrapped in ScrollView for pull-to-refresh
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 100)

                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text(showingUnreadOnly ? "No unread notifications" : "No notifications yet")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(showingUnreadOnly ? "All caught up!" : "You'll see notifications here when you have activity from friends or system updates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                }
                .refreshable {
                    await appState.loadNotifications()
                }

            } else {
                // Notifications list
                List {
                    ForEach(filteredNotifications) { notification in
                        NotificationRow(
                            notification: notification,
                            onMarkRead: {
                                Task {
                                    await appState.markNotificationAsRead(id: notification.id)
                                }
                            },
                            onDelete: {
                                Task {
                                    await appState.deleteNotification(id: notification.id)
                                }
                            },
                            onNavigate: { destination in
                                handleNavigation(destination)
                            }
                        )
                    }
                    .onDelete(perform: deleteNotifications)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await appState.loadNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    SwiftUI.Button(showingUnreadOnly ? "Show All" : "Show Unread Only") {
                        showingUnreadOnly.toggle()
                    }

                    Divider()

                    SwiftUI.Button("Mark All as Read") {
                        markAllAsRead()
                    }
                    .disabled(appState.notifications.filter { !$0.isRead }.isEmpty)

                    Divider()

                    SwiftUI.Button {
                        Task {
                            await appState.loadNotifications()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .background(
            Group {
                NavigationLink(destination: FriendsView(), isActive: $navigateToFriends) {
                    EmptyView()
                }
                NavigationLink(destination: SupportView(), isActive: $navigateToSupport) {
                    EmptyView()
                }
                if let buttonId = selectedButtonId,
                   let button = appState.buttons.first(where: { $0.id == buttonId }) {
                    NavigationLink(
                        destination: ButtonHistoryView(button: button),
                        isActive: Binding(
                            get: { selectedButtonId != nil },
                            set: { if !$0 { selectedButtonId = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
                if let ticketId = selectedTicketId {
                    NavigationLink(
                        destination: SupportTicketView(ticketId: ticketId),
                        isActive: Binding(
                            get: { selectedTicketId != nil },
                            set: { if !$0 { selectedTicketId = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
                if let friendId = selectedFriendId,
                   let friend = appState.friends.first(where: { $0.friendId == friendId }) {
                    NavigationLink(
                        destination: FriendDetailView(friend: friend),
                        isActive: Binding(
                            get: { selectedFriendId != nil },
                            set: { if !$0 { selectedFriendId = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
        )
    }

    private func handleNavigation(_ destination: NotificationDestination) {
        switch destination {
        case .button(let buttonId):
            selectedButtonId = buttonId
        case .friend(let friendId):
            selectedFriendId = friendId
        case .friends:
            navigateToFriends = true
        case .support:
            navigateToSupport = true
        case .supportTicket(let ticketId):
            selectedTicketId = ticketId
        case .none:
            break
        }
    }

    private func deleteNotifications(offsets: IndexSet) {
        Task {
            for index in offsets {
                let notification = filteredNotifications[index]
                await appState.deleteNotification(id: notification.id)
            }
        }
    }

    private func markAllAsRead() {
        Task {
            for notification in appState.notifications.filter({ !$0.isRead }) {
                await appState.markNotificationAsRead(id: notification.id)
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onMarkRead: () -> Void
    let onDelete: () -> Void
    let onNavigate: (NotificationDestination) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Notification icon
            Image(systemName: notification.type.systemIcon)
                .font(.title3)
                .foregroundColor(notification.isRead ? .secondary : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                // Title and category
                HStack {
                    Text(notification.type.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()

                    Text(notification.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Title
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .foregroundColor(notification.isRead ? .secondary : .primary)

                // Message
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                // Action buttons (if unread)
                if !notification.isRead {
                    HStack(spacing: 12) {
                        SwiftUI.Button("Mark as Read") {
                            onMarkRead()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)

                        SwiftUI.Button("Delete") {
                            onDelete()
                        }
                        .font(.caption)
                        .foregroundColor(.red)

                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }

            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !notification.isRead {
                onMarkRead()
            }

            // Handle notification tap action based on type
            let destination = getNavigationDestination()
            onNavigate(destination)
        }
        .swipeActions(edge: .trailing) {
            SwiftUI.Button("Delete", role: .destructive) {
                onDelete()
            }

            if !notification.isRead {
                SwiftUI.Button("Mark Read") {
                    onMarkRead()
                }
                .tint(.blue)
            }
        }
    }

    private func getNavigationDestination() -> NotificationDestination {
        switch notification.type {
        case .buttonClick, .buttonShared, .giftButtonReceived:
            if let buttonId = notification.buttonId {
                return .button(buttonId)
            }
            return .none
        case .giftButtonSent, .giftButtonClicked:
            // Navigate to friend page when clicking on gift button notifications
            // Use friend_id from data, or fall back to sender.id (the friend who clicked/received)
            if let friendId = notification.friendId ?? notification.sender?.id {
                return .friend(friendId)
            }
            return .friends
        case .giftButtonDeleted:
            return .none  // Button no longer exists
        case .friendRequest, .friendAccepted:
            return .friends
        case .supportTicketReply, .supportTicketStatusUpdate:
            if let ticketId = notification.ticketId {
                return .supportTicket(ticketId)
            }
            return .support
        case .systemAnnouncement, .subscriptionExpiring, .subscriptionRenewed, .general:
            return .none
        }
    }
}

#Preview {
    NavigationView {
        NotificationsView()
            .environmentObject(AppState())
    }
}
