import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let username: String
    let displayName: String
    let avatar: String?
    let timezone: String
    let language: String
    let subscriptionTier: SubscriptionTier
    let subscriptionExpiresAt: Date?
    let defaultHistorySharing: Bool
    let allowFriendRequests: Bool
    let profileVisibility: ProfileVisibility
    let activityVisibility: ActivityVisibility
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, username, avatar, timezone, language
        case displayName = "display_name"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case defaultHistorySharing = "default_history_sharing"
        case allowFriendRequests = "allow_friend_requests"
        case profileVisibility = "profile_visibility"
        case activityVisibility = "activity_visibility"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .enterprise: return "Enterprise"
        }
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .friends: return "Friends Only"
        case .private: return "Private"
        }
    }
}

enum ActivityVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .friends: return "Friends Only"
        case .private: return "Private"
        }
    }
}

// User authentication data
struct AuthUser: Codable {
    let user: User
    let token: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case user, token
        case refreshToken = "refresh_token"
    }
}

// Login credentials
struct LoginCredentials: Codable {
    let email: String
    let password: String
}

// Registration data
struct RegistrationData: Codable {
    let email: String
    let username: String
    let displayName: String
    let password: String
    let passwordConfirmation: String
    
    enum CodingKeys: String, CodingKey {
        case email, username, displayName = "display_name", password
        case passwordConfirmation = "password_confirmation"
    }
    
    var isValid: Bool {
        !email.isEmpty && !username.isEmpty && !displayName.isEmpty && 
        password.count >= 8 && password == passwordConfirmation
    }
}
