import Foundation
import Combine
import UIKit

class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session = URLSession.shared

    private init() {
        self.baseURL = AppConfiguration.shared.apiBaseURL
    }
    
    // MARK: - Generic Request Method
    
    // MARK: - Version Headers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func addCommonHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            request.setValue(deviceId, forHTTPHeaderField: "X-Device-Id")
        }
    }

    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30 // 30 second timeout
        addCommonHeaders(to: &request)

        // Add auth token if required
        if requiresAuth, let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("DEBUG API: Using token: \(token.prefix(20))...")
        } else if requiresAuth {
            print("DEBUG API: No token found in keychain!")
        }

        // Add body if provided
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("DEBUG API: Request body: \(body)")
        }

        print("DEBUG API: Making \(method.rawValue) request to \(url)")
        let (data, response) = try await session.data(for: request)
        print("DEBUG API: Got response")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let apiResponse = try JSONDecoder.iso8601.decode(APIResponse<T>.self, from: data)
            if apiResponse.success {
                return apiResponse.data
            } else {
                throw APIError.serverError(apiResponse.error?.message ?? "Unknown error")
            }
        } else if httpResponse.statusCode == 402 {
            // Payment Required - upgrade needed
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            if let upgradeInfo = errorResponse?.error?.upgradeInfo {
                throw APIError.upgradeRequired(upgradeInfo)
            } else {
                // Fallback if upgrade info not parsed correctly
                let info = UpgradeInfo(
                    reason: "limit_reached",
                    currentPlan: "Free",
                    currentUsage: nil,
                    limit: nil,
                    recommendedPlan: "premium",
                    upgradeBenefit: "Upgrade to access more features.",
                    message: errorResponse?.error?.message ?? "Upgrade required"
                )
                throw APIError.upgradeRequired(info)
            }
        } else {
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    // Returns both data and metadata (for paginated responses)
    private func makeRequestWithMeta<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> (data: T, meta: APIMetadata?) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        addCommonHeaders(to: &request)

        if requiresAuth, let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let apiResponse = try JSONDecoder.iso8601.decode(APIResponse<T>.self, from: data)
            if apiResponse.success {
                return (apiResponse.data, apiResponse.meta)
            } else {
                throw APIError.serverError(apiResponse.error?.message ?? "Unknown error")
            }
        } else if httpResponse.statusCode == 402 {
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            if let upgradeInfo = errorResponse?.error?.upgradeInfo {
                throw APIError.upgradeRequired(upgradeInfo)
            } else {
                let info = UpgradeInfo(
                    reason: "limit_reached",
                    currentPlan: "Free",
                    currentUsage: nil,
                    limit: nil,
                    recommendedPlan: "premium",
                    upgradeBenefit: "Upgrade to access more features.",
                    message: errorResponse?.error?.message ?? "Upgrade required"
                )
                throw APIError.upgradeRequired(info)
            }
        } else {
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    private func makeOptionalRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        addCommonHeaders(to: &request)

        if requiresAuth, let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            // Handle empty response (204 No Content) or null data
            if httpResponse.statusCode == 204 || data.isEmpty {
                return nil
            }
            
            do {
                let apiResponse = try JSONDecoder.iso8601.decode(APIResponse<T>.self, from: data)
                if apiResponse.success {
                    return apiResponse.data
                } else {
                    throw APIError.serverError(apiResponse.error?.message ?? "Unknown error")
                }
            } catch {
                // If decoding fails, it might be because data is null - return nil
                return nil
            }
        } else {
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func makeVoidRequest(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        addCommonHeaders(to: &request)

        if requiresAuth, let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if !(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            let errorResponse = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - App Configuration

    /// Fetch app configuration from server
    /// Returns version requirements, feature flags, and maintenance status
    func getConfig() async throws -> AppConfig {
        guard let url = URL(string: "\(baseURL)/config") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.GET.rawValue
        addCommonHeaders(to: &request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            // Config endpoint returns data directly, not wrapped in APIResponse
            return try JSONDecoder.iso8601.decode(AppConfig.self, from: data)
        } else {
            throw APIError.serverError("Failed to fetch config: HTTP \(httpResponse.statusCode)")
        }
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            requiresAuth: false
        )
        return response
    }
    
    func register(email: String, password: String, confirmPassword: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "user": [
                "email": email,
                "password": password,
                "password_confirmation": confirmPassword
            ]
        ]

        return try await makeRequest(
            endpoint: "/auth/register",
            method: .POST,
            body: body,
            requiresAuth: false
        )
    }
    
    func refreshToken(_ token: String) async throws -> TokenResponse {
        let body = ["token": token]
        
        let response: TokenResponse = try await makeRequest(
            endpoint: "/auth/refresh",
            method: .POST,
            body: body,
            requiresAuth: false
        )
        return response
    }
    
    func logout() async throws {
        try await makeVoidRequest(endpoint: "/auth/logout", method: .DELETE)
    }

    // OAuth callback - exchange user info for token
    func exchangeOAuthCode(provider: String, code: String, state: String?) async throws -> AuthResponse {
        var body: [String: Any] = [
            "provider": provider,
            "code": code
        ]
        if let state = state {
            body["state"] = state
        }

        return try await makeRequest(
            endpoint: "/auth/oauth/callback",
            method: .POST,
            body: body,
            requiresAuth: false
        )
    }

    /// Authenticate with OAuth using user info from the provider
    /// - Parameters:
    ///   - provider: The OAuth provider (e.g., "google", "apple")
    ///   - userInfo: Dictionary containing user info from the OAuth provider
    ///     - email: User's email (required)
    ///     - uid: Unique identifier from the provider (required)
    ///     - name: User's display name (optional)
    ///     - first_name: User's first name (optional)
    ///     - last_name: User's last name (optional)
    ///     - image: User's profile image URL (optional)
    func authenticateWithOAuth(provider: String, userInfo: [String: Any]) async throws -> AuthResponse {
        let body: [String: Any] = [
            "provider": provider,
            "user_info": userInfo
        ]

        return try await makeRequest(
            endpoint: "/auth/oauth/callback",
            method: .POST,
            body: body,
            requiresAuth: false
        )
    }

    // Get OAuth URL for provider
    var oauthBaseURL: String {
        return AppConfiguration.shared.webBaseURL
    }
    
    // MARK: - User Management
    
    func getCurrentUser() async throws -> User {
        return try await makeRequest(endpoint: "/users/profile")
    }
    
    func updateUserProfile(_ update: UserProfileUpdate) async throws -> User {
        return try await makeRequest(
            endpoint: "/users/profile",
            method: .PUT,
            body: update.toRequestBody()
        )
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) async throws {
        let body: [String: Any] = [
            "current_password": currentPassword,
            "new_password": newPassword,
            "confirm_password": confirmPassword
        ]
        try await makeVoidRequest(
            endpoint: "/users/password",
            method: .PUT,
            body: body
        )
    }

    func exportUserData(format: String) async throws -> (data: Data, filename: String, contentType: String) {
        guard let url = URL(string: "\(baseURL)/users/export?format=\(format)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.GET.rawValue
        addCommonHeaders(to: &request)

        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition") ?? ""
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"

            // Extract filename from Content-Disposition header
            var filename = "buttonlog_export.\(format)"
            if let filenameRange = contentDisposition.range(of: "filename=\""),
               let endRange = contentDisposition.range(of: "\"", range: filenameRange.upperBound..<contentDisposition.endIndex) {
                filename = String(contentDisposition[filenameRange.upperBound..<endRange.lowerBound])
            }

            return (data, filename, contentType)
        } else {
            throw APIError.serverError("Export failed: HTTP \(httpResponse.statusCode)")
        }
    }

    func getPublicProfile(userId: String) async throws -> PublicUser {
        return try await makeRequest(endpoint: "/users/\(userId)/public-profile")
    }

    // MARK: - Webhook Settings

    func getWebhookSettings() async throws -> WebhookSettings {
        return try await makeRequest(endpoint: "/notifications/settings")
    }

    func updateWebhookSettings(
        webhookUrl: String?,
        webhookEnabled: Bool,
        webhookSecret: String?,
        retryFailed: Bool,
        maxRetries: Int
    ) async throws {
        var body: [String: Any] = [
            "default_webhook_enabled": webhookEnabled,
            "retry_failed": retryFailed,
            "max_retries": maxRetries
        ]
        if let url = webhookUrl {
            body["default_webhook_url"] = url
        }
        if let secret = webhookSecret {
            body["webhook_secret"] = secret
        }
        try await makeVoidRequest(
            endpoint: "/notifications/settings",
            method: .PUT,
            body: body
        )
    }

    func testWebhook() async throws {
        try await makeVoidRequest(
            endpoint: "/notifications/test",
            method: .POST,
            body: nil
        )
    }

    func completeOnboarding() async throws {
        try await makeVoidRequest(endpoint: "/users/complete-onboarding", method: .POST)
    }

    // MARK: - Buttons
    
    func getButtons() async throws -> [ButtonModel] {
        return try await makeRequest(endpoint: "/buttons")
    }

    func getButton(id: String) async throws -> ButtonModel {
        return try await makeRequest(endpoint: "/buttons/\(id)")
    }

    func createButton(_ formData: ButtonFormData) async throws -> ButtonModel {
        return try await makeRequest(
            endpoint: "/buttons",
            method: .POST,
            body: ["button": formData.toRequestBody()]
        )
    }

    /// Get all gift buttons created by the current user for their friends
    func getCreatedGiftButtons() async throws -> [CreatedGiftButton] {
        return try await makeRequest(endpoint: "/buttons/created-gifts")
    }

    /// Create a button for a friend (gift button)
    func createButtonForFriend(friendId: String, formData: ButtonFormData, message: String? = nil) async throws -> ButtonModel {
        var body: [String: Any] = [
            "friend_id": friendId,
            "button": formData.toRequestBody()
        ]
        if let message = message, !message.isEmpty {
            body["message"] = message
        }

        return try await makeRequest(
            endpoint: "/buttons/gift",
            method: .POST,
            body: body
        )
    }

    func updateButton(id: String, formData: ButtonFormData) async throws -> ButtonModel {
        return try await makeRequest(
            endpoint: "/buttons/\(id)",
            method: .PUT,
            body: ["button": formData.toRequestBody()]
        )
    }
    
    func deleteButton(id: String) async throws {
        try await makeVoidRequest(endpoint: "/buttons/\(id)", method: .DELETE)
    }
    
    func clickButton(id: String, choice: String? = nil) async throws -> ButtonClick {
        var body: [String: Any] = [:]
        if let choice = choice {
            body["choice"] = choice
        }
        return try await makeRequest(endpoint: "/buttons/\(id)/click", method: .POST, body: body.isEmpty ? nil : body)
    }

    func getButtonHistory(id: String, limit: Int = 50) async throws -> [ButtonClick] {
        return try await makeRequest(endpoint: "/buttons/\(id)/history?limit=\(limit)")
    }

    // MARK: - Button Sharing

    func getButtonSharing(buttonId: String) async throws -> [ButtonSharingSetting] {
        return try await makeRequest(endpoint: "/buttons/\(buttonId)/sharing")
    }

    func updateButtonSharing(buttonId: String, settings: [ButtonSharingSetting]) async throws -> [ButtonSharingSetting] {
        let body: [String: Any] = [
            "sharing": settings.map { setting in
                [
                    "friend_id": setting.friendId,
                    "is_shared": setting.isShared
                ]
            }
        ]
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/sharing",
            method: .PUT,
            body: body
        )
    }

    /// Update button sharing mode
    func updateSharingMode(buttonId: String, mode: SharingMode) async throws -> ButtonModel {
        let body: [String: Any] = [
            "sharing_mode": mode.rawValue
        ]
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/sharing-mode",
            method: .PUT,
            body: body
        )
    }

    /// Generate a shareable link for a button
    func generateShareLink(buttonId: String) async throws -> ShareLinkResponse {
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/share-link",
            method: .POST
        )
    }

    /// Revoke the shareable link for a button
    func revokeShareLink(buttonId: String) async throws -> ButtonModel {
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/share-link",
            method: .DELETE
        )
    }

    /// Get collaborators for a button
    func getCollaborators(buttonId: String) async throws -> [ButtonCollaborator] {
        return try await makeRequest(endpoint: "/buttons/\(buttonId)/collaborators")
    }

    /// Add a collaborator to a button
    func addCollaborator(buttonId: String, userId: String) async throws -> ButtonCollaborator {
        let body: [String: Any] = [
            "user_id": userId
        ]
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/collaborators",
            method: .POST,
            body: body
        )
    }

    /// Remove a collaborator from a button
    func removeCollaborator(buttonId: String, userId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/buttons/\(buttonId)/collaborators/\(userId)",
            method: .DELETE
        )
    }

    /// Join a button via share token
    func joinByShareToken(_ token: String) async throws -> ButtonModel {
        return try await makeRequest(
            endpoint: "/buttons/join/\(token)",
            method: .POST
        )
    }

    // MARK: - Button Alert Preferences

    /// Get alert preferences for a button (which friends receive alerts)
    func getButtonAlertPreferences(buttonId: String) async throws -> [ButtonAlertPreference] {
        return try await makeRequest(endpoint: "/buttons/\(buttonId)/alerts")
    }

    /// Toggle alert preference for a specific friend on a button
    func toggleButtonAlertPreference(buttonId: String, friendId: String) async throws -> ButtonAlertPreferenceResponse {
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/alerts/\(friendId)/toggle",
            method: .POST
        )
    }

    /// Set alert preference for a specific friend on a button
    func setButtonAlertPreference(buttonId: String, friendId: String, enabled: Bool, alertType: String = "click") async throws -> ButtonAlertPreferenceResponse {
        let body: [String: Any] = [
            "enabled": enabled,
            "alert_type": alertType
        ]
        return try await makeRequest(
            endpoint: "/buttons/\(buttonId)/alerts/\(friendId)",
            method: .PUT,
            body: body
        )
    }

    /// Enable alerts for all friends on a button
    func selectAllButtonAlerts(buttonId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/buttons/\(buttonId)/alerts/select-all",
            method: .POST
        )
    }

    /// Disable alerts for all friends on a button
    func deselectAllButtonAlerts(buttonId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/buttons/\(buttonId)/alerts/deselect-all",
            method: .POST
        )
    }

    // MARK: - Friends & Social
    
    func getFriends() async throws -> [Friend] {
        return try await makeRequest(endpoint: "/friends")
    }
    
    func sendFriendRequest(_ request: FriendRequest) async throws {
        try await makeVoidRequest(
            endpoint: "/friends/request",
            method: .POST,
            body: request.toRequestBody()
        )
    }
    
    func acceptFriendRequest(friendId: String) async throws {
        try await makeVoidRequest(endpoint: "/friends/\(friendId)/accept", method: .PUT)
    }
    
    func removeFriend(friendId: String) async throws {
        try await makeVoidRequest(endpoint: "/friends/\(friendId)", method: .DELETE)
    }
    
    func getFriendPermissions(friendId: String) async throws -> FriendPermissions {
        return try await makeRequest(endpoint: "/friends/\(friendId)/permissions")
    }
    
    func updateFriendPermissions(friendId: String, permissions: FriendPermissionUpdate) async throws {
        try await makeVoidRequest(
            endpoint: "/friends/\(friendId)/permissions",
            method: .PUT,
            body: permissions.toRequestBody()
        )
    }

    func getFriendButtons(friendId: String) async throws -> [FriendButton] {
        return try await makeRequest(endpoint: "/friends/\(friendId)/buttons")
    }

    func getFriendActivity(friendId: String, limit: Int = 20, cursor: ActivityCursor? = nil) async throws -> ActivityPage {
        var endpoint = "/friends/\(friendId)/activity?limit=\(limit)"
        if let cursor = cursor {
            endpoint += "&cursor=\(cursor.clickedAt)&cursor_id=\(cursor.id)"
        }
        let result: (data: [FriendActivity], meta: APIMetadata?) = try await makeRequestWithMeta(endpoint: endpoint)
        return ActivityPage(
            activities: result.data,
            hasMore: result.meta?.hasMore ?? false,
            nextCursor: result.meta?.nextCursor
        )
    }

    // MARK: - Notifications

    func getNotifications() async throws -> [AppNotification] {
        return try await makeRequest(endpoint: "/notifications")
    }

    func markNotificationAsRead(id: String) async throws {
        try await makeVoidRequest(endpoint: "/notifications/\(id)/read", method: .PUT)
    }

    func markAllNotificationsAsRead() async throws {
        try await makeVoidRequest(endpoint: "/alerts/read-all", method: .PUT)
    }

    func deleteNotification(id: String) async throws {
        try await makeVoidRequest(endpoint: "/notifications/\(id)", method: .DELETE)
    }

    // MARK: - Device Registration (Push Notifications)

    func registerDevice(deviceToken: String, platform: String = "iphone") async throws -> DeviceRegistration {
        let osVersion = await MainActor.run { UIDevice.current.systemVersion }
        let body: [String: Any] = [
            "device_token": deviceToken,
            "platform": platform,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "os_version": osVersion
        ]

        return try await makeRequest(
            endpoint: "/devices/register",
            method: .POST,
            body: body
        )
    }

    func unregisterDevice(deviceToken: String) async throws {
        let body: [String: Any] = [
            "device_token": deviceToken
        ]

        try await makeVoidRequest(
            endpoint: "/devices/unregister",
            method: .DELETE,
            body: body
        )
    }

    func sendTestNotification(title: String? = nil, body: String? = nil) async throws -> TestNotificationResult {
        var requestBody: [String: Any] = [:]
        if let title = title {
            requestBody["title"] = title
        }
        if let body = body {
            requestBody["body"] = body
        }

        return try await makeRequest(
            endpoint: "/devices/test-notification",
            method: .POST,
            body: requestBody.isEmpty ? nil : requestBody
        )
    }

    // MARK: - Subscriptions
    
    func getSubscriptionPlans() async throws -> [SubscriptionPlan] {
        return try await makeRequest(
            endpoint: "/subscriptions/plans",
            requiresAuth: false
        )
    }
    
    func getCurrentSubscription() async throws -> UserSubscription? {
        return try await makeOptionalRequest(endpoint: "/subscriptions/current")
    }
    
    func createSubscription(planSlug: String, billingCycle: BillingCycle) async throws -> UserSubscription {
        let body = [
            "plan_slug": planSlug,
            "billing_cycle": billingCycle.rawValue
        ]
        
        return try await makeRequest(
            endpoint: "/subscriptions",
            method: .POST,
            body: body
        )
    }
    
    func cancelSubscription() async throws {
        try await makeVoidRequest(endpoint: "/subscriptions", method: .DELETE)
    }
    
    func pauseSubscription() async throws {
        try await makeVoidRequest(endpoint: "/subscriptions/pause", method: .POST)
    }
    
    func resumeSubscription() async throws {
        try await makeVoidRequest(endpoint: "/subscriptions/resume", method: .POST)
    }
    
    func getSubscriptionStats() async throws -> SubscriptionStats {
        return try await makeRequest(endpoint: "/subscriptions/stats")
    }
    
    func checkPermission(action: String, context: [String: Any] = [:]) async throws -> Bool {
        let body: [String: Any] = [
            "action": action,
            "context": context
        ]

        let response: PermissionCheckResponse = try await makeRequest(
            endpoint: "/subscriptions/check-permission",
            method: .POST,
            body: body
        )

        return response.allowed
    }

    // MARK: - Stripe Payment Integration

    /// Create a Stripe Checkout session to subscribe to a plan
    /// Returns a URL that should be opened in a browser/WebView
    func createCheckoutSession(planId: String, billingCycle: BillingCycle, couponCode: String? = nil) async throws -> CheckoutSession {
        var body: [String: Any] = [
            "plan_id": planId,
            "billing_cycle": billingCycle.rawValue
        ]
        if let coupon = couponCode {
            body["coupon_code"] = coupon
        }

        return try await makeRequest(
            endpoint: "/subscriptions/checkout",
            method: .POST,
            body: body
        )
    }

    /// Create a Stripe Customer Portal session to manage subscription
    /// Returns a URL that should be opened in a browser/WebView
    func createPortalSession() async throws -> PortalSession {
        return try await makeRequest(
            endpoint: "/subscriptions/portal",
            method: .POST
        )
    }

    /// Create a Setup Intent for adding a new payment method
    func createSetupIntent() async throws -> SetupIntent {
        return try await makeRequest(
            endpoint: "/subscriptions/setup-intent",
            method: .POST
        )
    }

    // MARK: - Payment Methods

    /// Get list of user's saved payment methods
    func getPaymentMethods() async throws -> [PaymentMethod] {
        return try await makeRequest(endpoint: "/payment-methods")
    }

    /// Add a new payment method using Stripe payment method ID
    func addPaymentMethod(paymentMethodId: String) async throws -> PaymentMethod {
        let body: [String: Any] = [
            "payment_method_id": paymentMethodId
        ]
        return try await makeRequest(
            endpoint: "/payment-methods",
            method: .POST,
            body: body
        )
    }

    /// Remove a payment method
    func removePaymentMethod(id: String) async throws {
        try await makeVoidRequest(endpoint: "/payment-methods/\(id)", method: .DELETE)
    }

    /// Set a payment method as the default
    func setDefaultPaymentMethod(id: String) async throws {
        try await makeVoidRequest(endpoint: "/payment-methods/\(id)/default", method: .PUT)
    }

    // MARK: - Invoices

    /// Get list of user's invoices
    func getInvoices() async throws -> [Invoice] {
        return try await makeRequest(endpoint: "/invoices")
    }

    /// Get a specific invoice
    func getInvoice(id: String) async throws -> Invoice {
        return try await makeRequest(endpoint: "/invoices/\(id)")
    }

    // MARK: - Coupons

    /// Apply a coupon code to the user's account
    func applyCoupon(code: String) async throws -> ApplyCouponResponse {
        let body: [String: Any] = [
            "code": code
        ]
        return try await makeRequest(
            endpoint: "/coupons/apply",
            method: .POST,
            body: body
        )
    }

    // MARK: - Support Tickets

    func getSupportTickets() async throws -> [SupportTicket] {
        return try await makeRequest(endpoint: "/support/tickets")
    }

    func getSupportTicket(id: String) async throws -> SupportTicket {
        return try await makeRequest(endpoint: "/support/tickets/\(id)")
    }

    func createSupportTicket(_ formData: TicketFormData) async throws -> SupportTicket {
        return try await makeRequest(
            endpoint: "/support/tickets",
            method: .POST,
            body: formData.toRequestBody()
        )
    }

    func sendTicketMessage(ticketId: String, content: String) async throws -> TicketMessage {
        let body: [String: Any] = [
            "message": [
                "content": content
            ]
        ]
        return try await makeRequest(
            endpoint: "/support/tickets/\(ticketId)/messages",
            method: .POST,
            body: body
        )
    }

    // MARK: - Teams

    func getTeams() async throws -> TeamsResponse {
        return try await makeRequest(endpoint: "/teams")
    }

    func getTeam(id: String) async throws -> Team {
        return try await makeRequest(endpoint: "/teams/\(id)")
    }

    func createTeam(_ request: CreateTeamRequest) async throws -> Team {
        return try await makeRequest(
            endpoint: "/teams",
            method: .POST,
            body: request.toRequestBody()
        )
    }

    func updateTeam(id: String, request: CreateTeamRequest) async throws -> Team {
        return try await makeRequest(
            endpoint: "/teams/\(id)",
            method: .PUT,
            body: request.toRequestBody()
        )
    }

    func deleteTeam(id: String) async throws {
        try await makeVoidRequest(endpoint: "/teams/\(id)", method: .DELETE)
    }

    func leaveTeam(teamId: String) async throws {
        try await makeVoidRequest(endpoint: "/teams/\(teamId)/leave", method: .POST)
    }

    func inviteTeamMember(teamId: String, username: String, role: String) async throws {
        let body: [String: Any] = [
            "username": username,
            "role": role
        ]
        try await makeVoidRequest(
            endpoint: "/teams/\(teamId)/invitations",
            method: .POST,
            body: body
        )
    }

    func acceptTeamInvitation(invitationId: String) async throws -> Team {
        return try await makeRequest(
            endpoint: "/teams/invitations/\(invitationId)/accept",
            method: .POST
        )
    }

    func declineTeamInvitation(invitationId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/teams/invitations/\(invitationId)/decline",
            method: .POST
        )
    }

    func addButtonToTeam(teamId: String, buttonId: String, permission: String) async throws {
        let body: [String: Any] = [
            "button_id": buttonId,
            "permission": permission
        ]
        try await makeVoidRequest(
            endpoint: "/teams/\(teamId)/buttons",
            method: .POST,
            body: body
        )
    }

    func removeButtonFromTeam(teamId: String, buttonId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/teams/\(teamId)/buttons/\(buttonId)",
            method: .DELETE
        )
    }

    // MARK: - Organizations

    func getOrganizations() async throws -> OrganizationsResponse {
        return try await makeRequest(endpoint: "/organizations")
    }

    func getOrganization(id: String) async throws -> Organization {
        return try await makeRequest(endpoint: "/organizations/\(id)")
    }

    func createOrganization(_ request: CreateOrganizationRequest) async throws -> Organization {
        return try await makeRequest(
            endpoint: "/organizations",
            method: .POST,
            body: request.toRequestBody()
        )
    }

    func updateOrganization(id: String, request: CreateOrganizationRequest) async throws -> Organization {
        return try await makeRequest(
            endpoint: "/organizations/\(id)",
            method: .PUT,
            body: request.toRequestBody()
        )
    }

    func deleteOrganization(id: String) async throws {
        try await makeVoidRequest(endpoint: "/organizations/\(id)", method: .DELETE)
    }

    func leaveOrganization(organizationId: String) async throws {
        try await makeVoidRequest(endpoint: "/organizations/\(organizationId)/leave", method: .POST)
    }

    func inviteOrganizationMember(organizationId: String, username: String?, email: String?, role: String) async throws {
        var body: [String: Any] = ["role": role]
        if let username = username {
            body["username"] = username
        }
        if let email = email {
            body["email"] = email
        }
        try await makeVoidRequest(
            endpoint: "/organizations/\(organizationId)/invitations",
            method: .POST,
            body: body
        )
    }

    func acceptOrganizationInvitation(invitationId: String) async throws -> Organization {
        return try await makeRequest(
            endpoint: "/organizations/invitations/\(invitationId)/accept",
            method: .POST
        )
    }

    func declineOrganizationInvitation(invitationId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/organizations/invitations/\(invitationId)/decline",
            method: .POST
        )
    }

    func addTeamToOrganization(organizationId: String, teamId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/organizations/\(organizationId)/teams/\(teamId)",
            method: .POST
        )
    }

    func removeTeamFromOrganization(organizationId: String, teamId: String) async throws {
        try await makeVoidRequest(
            endpoint: "/organizations/\(organizationId)/teams/\(teamId)",
            method: .DELETE
        )
    }

    // MARK: - Diary

    /// Fetch diary activity data for a specific date
    /// - Parameter date: Date in YYYY-MM-DD format, or nil for today
    func getDiary(date: String? = nil) async throws -> DiaryData {
        var endpoint = "/diary"
        if let date = date {
            endpoint += "?date=\(date)"
        }
        return try await makeRequest(endpoint: endpoint)
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError
    case decodingError
    case upgradeRequired(UpgradeInfo)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .upgradeRequired(let info):
            return info.message
        }
    }

    var isUpgradeRequired: Bool {
        if case .upgradeRequired = self { return true }
        return false
    }

    var upgradeInfo: UpgradeInfo? {
        if case .upgradeRequired(let info) = self { return info }
        return nil
    }
}

struct UpgradeInfo: Codable {
    let reason: String
    let currentPlan: String
    let currentUsage: Int?
    let limit: Int?
    let recommendedPlan: String
    let upgradeBenefit: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case reason
        case currentPlan = "current_plan"
        case currentUsage = "current_usage"
        case limit
        case recommendedPlan = "recommended_plan"
        case upgradeBenefit = "upgrade_benefit"
        case message
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let error: APIErrorDetail?
    let meta: APIMetadata?
}

struct APIErrorResponse: Codable {
    let success: Bool
    let error: APIErrorDetail?
    let meta: APIMetadata?
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let details: [ValidationError]?
    let upgradeInfo: UpgradeInfo?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
        case upgradeInfo = "upgrade_info"
    }
}

struct ValidationError: Codable {
    let field: String
    let message: String
}

struct APIMetadata: Codable {
    let timestamp: Date?
    let requestId: String?
    let count: Int?
    let limit: Int?
    let hasMore: Bool?
    let nextCursor: ActivityCursor?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case requestId = "request_id"
        case count
        case limit
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct TokenResponse: Codable {
    let token: String
}

struct PermissionCheckResponse: Codable {
    let allowed: Bool
}

struct WebhookSettings: Codable {
    let defaultWebhookUrl: String?
    let defaultWebhookEnabled: Bool
    let webhookSecret: String?
    let retryFailed: Bool
    let maxRetries: Int

    enum CodingKeys: String, CodingKey {
        case defaultWebhookUrl = "default_webhook_url"
        case defaultWebhookEnabled = "default_webhook_enabled"
        case webhookSecret = "webhook_secret"
        case retryFailed = "retry_failed"
        case maxRetries = "max_retries"
    }
}

// MARK: - JSON Decoder Extension

extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without timezone (backend sometimes sends dates without Z)
            // e.g., "2026-01-22T01:50:40"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Try with fractional seconds but no timezone
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }()
}

