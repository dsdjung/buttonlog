import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Request Permission

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted

                if granted {
                    print("Push notification permission granted")
                    self.registerForRemoteNotifications()
                } else if let error = error {
                    print("Push notification permission error: \(error.localizedDescription)")
                } else {
                    print("Push notification permission denied")
                }
            }
        }
    }

    // MARK: - Register for Remote Notifications

    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        print("Device Token: \(token)")

        // Register with backend
        Task {
            await registerDeviceWithBackend(token: token)
        }
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Register with Backend

    func registerDeviceWithBackend(token: String) async {
        do {
            let registration = try await APIService.shared.registerDevice(deviceToken: token)
            print("Device registered with backend: \(registration.id)")
        } catch {
            print("Failed to register device with backend: \(error.localizedDescription)")
        }
    }

    // MARK: - Unregister Device

    func unregisterDevice() async {
        guard let token = deviceToken else { return }

        do {
            try await APIService.shared.unregisterDevice(deviceToken: token)
            print("Device unregistered from backend")
        } catch {
            print("Failed to unregister device: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Incoming Notifications

    func handleNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        // Parse notification data
        if let data = userInfo["data"] as? [String: Any] {
            let notificationType = data["type"] as? String ?? "unknown"
            let action = data["action"] as? String

            print("Received notification type: \(notificationType), action: \(action ?? "none")")

            // Handle different notification types
            switch notificationType {
            case "button_click":
                if let buttonId = data["button_id"] as? String {
                    handleButtonClickNotification(buttonId: buttonId)
                }
            case "friend_request":
                handleFriendRequestNotification()
            case "friend_accepted":
                handleFriendAcceptedNotification()
            default:
                break
            }
        }

        completionHandler()
    }

    // MARK: - Notification Handlers

    private func handleButtonClickNotification(buttonId: String) {
        // Navigate to button or refresh data
        NotificationCenter.default.post(
            name: .buttonClickNotificationReceived,
            object: nil,
            userInfo: ["buttonId": buttonId]
        )
    }

    private func handleFriendRequestNotification() {
        NotificationCenter.default.post(
            name: .friendRequestNotificationReceived,
            object: nil
        )
    }

    private func handleFriendAcceptedNotification() {
        NotificationCenter.default.post(
            name: .friendAcceptedNotificationReceived,
            object: nil
        )
    }

    // MARK: - Badge Management

    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func setBadge(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo, completionHandler: completionHandler)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let buttonClickNotificationReceived = Notification.Name("buttonClickNotificationReceived")
    static let friendRequestNotificationReceived = Notification.Name("friendRequestNotificationReceived")
    static let friendAcceptedNotificationReceived = Notification.Name("friendAcceptedNotificationReceived")
}
