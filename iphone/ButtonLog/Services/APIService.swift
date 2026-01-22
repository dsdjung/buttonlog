import Foundation
import Combine
import UIKit

class APIService {
    static let shared = APIService()

    private let baseURL = "http://localhost:14015/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Generic Request Method
    
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if required
        if requiresAuth, let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if provided
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
                return apiResponse.data
            } else {
                throw APIError.serverError(apiResponse.error?.message ?? "Unknown error")
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
    
    // MARK: - Authentication
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password
        ]
        
        return try await makeRequest<AuthResponse>(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            requiresAuth: false
        )
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
        
        return try await makeRequest<TokenResponse>(
            endpoint: "/auth/refresh",
            method: .POST,
            body: body,
            requiresAuth: false
        )
    }
    
    func logout() async throws {
        try await makeVoidRequest(endpoint: "/auth/logout", method: .DELETE)
    }

    // OAuth callback - exchange code for token
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

    // Get OAuth URL for provider
    var oauthBaseURL: String {
        return baseURL.replacingOccurrences(of: "/api", with: "")
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
    
    func getPublicProfile(userId: String) async throws -> PublicUser {
        return try await makeRequest(endpoint: "/users/\(userId)/public-profile")
    }
    
    // MARK: - Buttons
    
    func getButtons() async throws -> [Button] {
        return try await makeRequest(endpoint: "/buttons")
    }
    
    func getButton(id: String) async throws -> Button {
        return try await makeRequest(endpoint: "/buttons/\(id)")
    }
    
    func createButton(_ formData: ButtonFormData) async throws -> Button {
        return try await makeRequest(
            endpoint: "/buttons",
            method: .POST,
            body: ["button": formData.toRequestBody()]
        )
    }

    /// Create a button for a friend (gift button)
    func createButtonForFriend(friendId: String, formData: ButtonFormData, message: String? = nil) async throws -> Button {
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

    func updateButton(id: String, formData: ButtonFormData) async throws -> Button {
        return try await makeRequest(
            endpoint: "/buttons/\(id)",
            method: .PUT,
            body: ["button": formData.toRequestBody()]
        )
    }
    
    func deleteButton(id: String) async throws {
        try await makeVoidRequest(endpoint: "/buttons/\(id)", method: .DELETE)
    }
    
    func clickButton(id: String) async throws -> ButtonClick {
        return try await makeRequest(endpoint: "/buttons/\(id)/click", method: .POST)
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

    func deleteNotification(id: String) async throws {
        try await makeVoidRequest(endpoint: "/notifications/\(id)", method: .DELETE)
    }

    // MARK: - Device Registration (Push Notifications)

    func registerDevice(deviceToken: String, platform: String = "iphone") async throws -> DeviceRegistration {
        let body: [String: Any] = [
            "device_token": deviceToken,
            "platform": platform,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "os_version": UIDevice.current.systemVersion
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
    
    // MARK: - Subscriptions
    
    func getSubscriptionPlans() async throws -> [SubscriptionPlan] {
        return try await makeRequest(
            endpoint: "/subscriptions",
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
        }
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

