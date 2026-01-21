import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingUnreadOnly = false
    
    var filteredNotifications: [AppNotification] {
        if showingUnreadOnly {
            return appState.notifications.filter { !$0.isRead }
        } else {
            return appState.notifications
        }
    }
    
    var body: some View {
        VStack {
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
                // Empty state
                VStack(spacing: 20) {
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
                            }
                        )
                    }
                    .onDelete(perform: deleteNotifications)
                }
                .listStyle(PlainListStyle())
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await appState.loadNotifications()
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
            handleNotificationTap()
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
    
    private func handleNotificationTap() {
        // Handle different notification types
        switch notification.type {
        case .buttonClick:
            // Navigate to button or activity view
            break
        case .friendRequest, .friendAccepted:
            // Navigate to friends view
            break
        case .buttonShared:
            // Navigate to shared button
            break
        case .systemAnnouncement:
            // Show announcement detail
            break
        case .subscriptionExpiring, .subscriptionRenewed:
            // Navigate to subscription view
            break
        }
    }
}

#Preview {
    NavigationView {
        NotificationsView()
            .environmentObject(AppState())
    }
}