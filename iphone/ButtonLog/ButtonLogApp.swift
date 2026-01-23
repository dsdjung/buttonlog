import SwiftUI
import UserNotifications
import GoogleSignIn

@main
struct ButtonLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isCheckingAuth {
                    // Show splash/loading screen while checking authentication
                    SplashView()
                } else if authManager.isAuthenticated {
                    if authManager.onboardingCompleted {
                        MainTabView()
                            .environmentObject(appState)
                            .environmentObject(authManager)
                            .onAppear {
                                // Request push notification permission when user is authenticated
                                PushNotificationManager.shared.requestAuthorization()
                            }
                    } else {
                        OnboardingView()
                            .environmentObject(authManager)
                    }
                } else {
                    AuthenticationView()
                        .environmentObject(authManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.isCheckingAuth)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: authManager.onboardingCompleted)
        }
    }
}

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set push notification delegate
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared

        // Configure Google Sign-In with client ID from Info.plist
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            print("DEBUG: Found GIDClientID: \(clientID)")
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            print("DEBUG: Google Sign-In configured successfully")
        } else {
            print("DEBUG: GIDClientID not found in Info.plist!")
        }

        return true
    }

    // Handle Google Sign-In URL callback
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }

    // Handle remote notification when app is in background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        PushNotificationManager.shared.handleNotification(userInfo: userInfo) {
            completionHandler(.newData)
        }
    }
}