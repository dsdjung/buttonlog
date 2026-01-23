import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var buttons: [ButtonModel] = []
    @Published var friends: [Friend] = []
    @Published var notifications: [AppNotification] = []
    @Published var subscriptionPlans: [SubscriptionPlan] = []
    @Published var currentSubscription: UserSubscription?
    @Published var subscriptionStats: SubscriptionStats?

    @Published var isLoadingButtons = false
    @Published var isLoadingFriends = false
    @Published var isLoadingNotifications = false
    @Published var isLoadingSubscription = false

    // Diary state
    @Published var diaryData: DiaryData?
    @Published var isLoadingDiary = false
    @Published var diaryError: String?

    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Auto-refresh data periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task { @MainActor in
                    await self.refreshData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadButtons() }
            group.addTask { await self.loadFriends() }
            group.addTask { await self.loadNotifications() }
            group.addTask { await self.loadSubscriptionData() }
        }
    }
    
    func refreshData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadButtons() }
            group.addTask { await self.loadNotifications() }
        }
    }
    
    // MARK: - Buttons
    
    func loadButtons() async {
        isLoadingButtons = true
        errorMessage = nil

        do {
            let buttons = try await apiService.getButtons()
            self.buttons = buttons
        } catch is CancellationError {
            // Task was cancelled (e.g., pull-to-refresh released early), ignore silently
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession request was cancelled, ignore silently
        } catch {
            errorMessage = "Failed to load buttons: \(error.localizedDescription)"
        }

        isLoadingButtons = false
    }
    
    func createButton(_ formData: ButtonFormData) async -> Bool {
        do {
            let newButton = try await apiService.createButton(formData)
            buttons.append(newButton)
            return true
        } catch {
            errorMessage = "Failed to create button: \(error.localizedDescription)"
            return false
        }
    }
    
    func updateButton(id: String, formData: ButtonFormData) async -> Bool {
        do {
            let updatedButton = try await apiService.updateButton(id: id, formData: formData)
            if let index = buttons.firstIndex(where: { $0.id == id }) {
                buttons[index] = updatedButton
            }
            return true
        } catch {
            errorMessage = "Failed to update button: \(error.localizedDescription)"
            return false
        }
    }
    
    func deleteButton(id: String) async -> Bool {
        do {
            try await apiService.deleteButton(id: id)
            buttons.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to delete button: \(error.localizedDescription)"
            return false
        }
    }
    
    func clickButton(id: String, choice: String? = nil) async -> Bool {
        do {
            _ = try await apiService.clickButton(id: id, choice: choice)

            // Reload the specific button to get updated state from server
            // For one-time buttons with choices, they may be archived
            do {
                let updatedButton = try await apiService.getButton(id: id)
                if let index = buttons.firstIndex(where: { $0.id == id }) {
                    buttons[index] = updatedButton
                }
            } catch {
                // Button may have been archived (one-time), remove from list
                buttons.removeAll { $0.id == id }
            }

            return true
        } catch {
            errorMessage = "Failed to click button: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Friends
    
    func loadFriends() async {
        isLoadingFriends = true
        
        do {
            let friends = try await apiService.getFriends()
            self.friends = friends
        } catch {
            errorMessage = "Failed to load friends: \(error.localizedDescription)"
        }
        
        isLoadingFriends = false
    }
    
    func sendFriendRequest(_ request: FriendRequest) async -> Bool {
        do {
            try await apiService.sendFriendRequest(request)
            await loadFriends() // Refresh friends list
            return true
        } catch {
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
            return false
        }
    }
    
    func acceptFriendRequest(friendId: String) async -> Bool {
        do {
            try await apiService.acceptFriendRequest(friendId: friendId)
            await loadFriends() // Refresh friends list
            return true
        } catch {
            errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
            return false
        }
    }
    
    func removeFriend(friendId: String) async -> Bool {
        do {
            try await apiService.removeFriend(friendId: friendId)
            friends.removeAll { $0.friendId == friendId }
            return true
        } catch {
            errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Notifications
    
    func loadNotifications() async {
        isLoadingNotifications = true
        
        do {
            let notifications = try await apiService.getNotifications()
            self.notifications = notifications
        } catch {
            errorMessage = "Failed to load notifications: \(error.localizedDescription)"
        }
        
        isLoadingNotifications = false
    }
    
    func markNotificationAsRead(id: String) async -> Bool {
        do {
            try await apiService.markNotificationAsRead(id: id)
            
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let notification = notifications[index]
                let updatedNotification = AppNotification(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    message: notification.message,
                    data: notification.data,
                    isRead: true,
                    createdAt: notification.createdAt,
                    sender: notification.sender
                )
                notifications[index] = updatedNotification
            }
            
            return true
        } catch {
            errorMessage = "Failed to mark notification as read: \(error.localizedDescription)"
            return false
        }
    }
    
    func markAllNotificationsAsRead() async -> Bool {
        do {
            try await apiService.markAllNotificationsAsRead()

            // Update all notifications to read locally
            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    message: notification.message,
                    data: notification.data,
                    isRead: true,
                    createdAt: notification.createdAt,
                    sender: notification.sender
                )
            }

            return true
        } catch {
            errorMessage = "Failed to mark all notifications as read: \(error.localizedDescription)"
            return false
        }
    }

    func deleteNotification(id: String) async -> Bool {
        do {
            try await apiService.deleteNotification(id: id)
            notifications.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to delete notification: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Subscriptions

    func loadSubscriptionData() async {
        isLoadingSubscription = true

        // Load each subscription component independently to avoid one failure breaking everything
        // Plans endpoint is public and should always work
        do {
            subscriptionPlans = try await apiService.getSubscriptionPlans()
        } catch {
            // Plans are critical, but don't show error to user
        }

        // Current subscription - might be nil for free users
        do {
            currentSubscription = try await apiService.getCurrentSubscription()
        } catch {
            // User might not have a subscription, that's fine
            currentSubscription = nil
        }

        // Stats endpoint might not be implemented or available for all users
        do {
            subscriptionStats = try await apiService.getSubscriptionStats()
        } catch {
            // Stats are optional, don't show error
            subscriptionStats = nil
        }

        isLoadingSubscription = false
    }
    
    func createSubscription(planSlug: String, billingCycle: BillingCycle) async -> Bool {
        do {
            let subscription = try await apiService.createSubscription(
                planSlug: planSlug,
                billingCycle: billingCycle
            )
            currentSubscription = subscription
            await loadSubscriptionData() // Refresh all subscription data
            return true
        } catch {
            errorMessage = "Failed to create subscription: \(error.localizedDescription)"
            return false
        }
    }
    
    func cancelSubscription() async -> Bool {
        do {
            try await apiService.cancelSubscription()
            await loadSubscriptionData() // Refresh subscription data
            return true
        } catch {
            errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Diary

    func fetchDiary(for date: Date? = nil) async {
        isLoadingDiary = true
        diaryError = nil

        // Format date to YYYY-MM-DD if provided
        var dateString: String? = nil
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        }

        do {
            let data = try await apiService.getDiary(date: dateString)
            diaryData = data
        } catch {
            diaryError = "Failed to load diary: \(error.localizedDescription)"
        }

        isLoadingDiary = false
    }

    func clearDiaryError() {
        diaryError = nil
    }

    // MARK: - Utility

    func clearError() {
        errorMessage = nil
    }
    
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var pendingFriendRequests: [Friend] {
        friends.filter { $0.status == .pending }
    }
}