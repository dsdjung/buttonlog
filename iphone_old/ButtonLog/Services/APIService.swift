import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:4000/api"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    private func authHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    // MARK: - Generic Request Method
    
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil
    ) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = authHeaders()
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.decodingError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication Endpoints
    
    func login(credentials: LoginCredentials) -> AnyPublisher<AuthUser, APIError> {
        let body = try? JSONEncoder().encode(credentials)
        return request(endpoint: "/auth/login", method: .POST, body: body)
    }
    
    func register(data: RegistrationData) -> AnyPublisher<AuthUser, APIError> {
        let body = try? JSONEncoder().encode(data)
        return request(endpoint: "/auth/register", method: .POST, body: body)
    }
    
    func logout() -> AnyPublisher<Void, APIError> {
        return request(endpoint: "/auth/logout", method: .DELETE)
    }
    
    // MARK: - Button Endpoints
    
    func getButtons() -> AnyPublisher<[Button], APIError> {
        return request(endpoint: "/buttons")
    }
    
    func createButton(_ button: ButtonFormData) -> AnyPublisher<Button, APIError> {
        let buttonData = [
            "name": button.name,
            "description": button.description,
            "type": button.type.rawValue,
            "icon": button.icon,
            "color": button.color,
            "notifications_enabled": button.notificationsEnabled,
            "auto_stop_enabled": button.autoStopEnabled,
            "calendar_sync_enabled": button.calendarSyncEnabled
        ] as [String: Any]
        
        let body = try? JSONSerialization.data(withJSONObject: buttonData)
        return request(endpoint: "/buttons", method: .POST, body: body)
    }
    
    func updateButton(_ button: Button) -> AnyPublisher<Button, APIError> {
        let buttonData = [
            "name": button.name,
            "description": button.description,
            "type": button.type.rawValue,
            "icon": button.icon,
            "color": button.color,
            "notifications_enabled": button.notificationsEnabled,
            "auto_stop_enabled": button.autoStopEnabled,
            "calendar_sync_enabled": button.calendarSyncEnabled
        ] as [String: Any]
        
        let body = try? JSONSerialization.data(withJSONObject: buttonData)
        return request(endpoint: "/buttons/\(button.id)", method: .PUT, body: body)
    }
    
    func deleteButton(_ buttonId: String) -> AnyPublisher<Void, APIError> {
        return request(endpoint: "/buttons/\(buttonId)", method: .DELETE)
    }
    
    func clickButton(_ buttonId: String) -> AnyPublisher<ButtonClick, APIError> {
        let clickData = [
            "platform": "iphone",
            "device": UIDevice.current.name
        ] as [String: Any]
        
        let body = try? JSONSerialization.data(withJSONObject: clickData)
        return request(endpoint: "/buttons/\(buttonId)/click", method: .POST, body: body)
    }
    
    // MARK: - User Endpoints
    
    func getUserProfile() -> AnyPublisher<User, APIError> {
        return request(endpoint: "/users/profile")
    }
    
    func updateUserProfile(_ user: User) -> AnyPublisher<User, APIError> {
        let userData = [
            "display_name": user.displayName,
            "timezone": user.timezone,
            "language": user.language,
            "profile_visibility": user.profileVisibility.rawValue,
            "activity_visibility": user.activityVisibility.rawValue
        ] as [String: Any]
        
        let body = try? JSONSerialization.data(withJSONObject: userData)
        return request(endpoint: "/users/profile", method: .PUT, body: body)
    }
    
    // MARK: - Social Endpoints
    
    func getFriends() -> AnyPublisher<[User], APIError> {
        return request(endpoint: "/friends")
    }
    
    func sendFriendRequest(username: String) -> AnyPublisher<Void, APIError> {
        let requestData = ["username": username]
        let body = try? JSONSerialization.data(withJSONObject: requestData)
        return request(endpoint: "/friends/request", method: .POST, body: body)
    }
    
    func acceptFriendRequest(_ requestId: String) -> AnyPublisher<Void, APIError> {
        return request(endpoint: "/friends/\(requestId)/accept", method: .PUT)
    }
    
    // MARK: - Notification Endpoints
    
    func getNotifications() -> AnyPublisher<[Notification], APIError> {
        return request(endpoint: "/notifications")
    }
    
    func markNotificationAsRead(_ notificationId: String) -> AnyPublisher<Void, APIError> {
        return request(endpoint: "/notifications/\(notificationId)/read", method: .PUT)
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
    case unauthorized
    case serverError(Int)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - JSON Decoder Configuration

extension JSONDecoder {
    static let phoenixDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
}
