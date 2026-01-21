import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let username: String?
    let displayName: String?
    let firstName: String?
    let lastName: String?
    let profileVisibility: ProfileVisibility
    let activityVisibility: ActivityVisibility
    let subscriptionTier: SubscriptionTier
    let isActive: Bool
    let emailVerified: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return displayName ?? username ?? email
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case profileVisibility = "profile_visibility"
        case activityVisibility = "activity_visibility"
        case subscriptionTier = "subscription_tier"
        case isActive = "is_active"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case publicProfile = "public"
    case friends = "friends"
    case privateProfile = "private"
    
    var displayName: String {
        switch self {
        case .publicProfile: return "Public"
        case .friends: return "Friends Only"
        case .privateProfile: return "Private"
        }
    }
    
    var description: String {
        switch self {
        case .publicProfile: return "Anyone can see your profile"
        case .friends: return "Only friends can see your profile"
        case .privateProfile: return "Only you can see your profile"
        }
    }
}

enum ActivityVisibility: String, Codable, CaseIterable {
    case publicActivity = "public"
    case friends = "friends"
    case privateActivity = "private"
    
    var displayName: String {
        switch self {
        case .publicActivity: return "Public"
        case .friends: return "Friends Only"
        case .privateActivity: return "Private"
        }
    }
    
    var description: String {
        switch self {
        case .publicActivity: return "Anyone can see your button activities"
        case .friends: return "Only friends can see your button activities"
        case .privateActivity: return "Only you can see your button activities"
        }
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
    
    var maxButtons: Int {
        switch self {
        case .free: return 5
        case .premium: return 50
        case .enterprise: return Int.max
        }
    }
    
    var maxFriends: Int {
        switch self {
        case .free: return 10
        case .premium: return 100
        case .enterprise: return Int.max
        }
    }
    
    var hasAnalytics: Bool {
        switch self {
        case .free: return false
        case .premium, .enterprise: return true
        }
    }
    
    var hasCalendarSync: Bool {
        switch self {
        case .free: return false
        case .premium, .enterprise: return true
        }
    }
}

// User profile update data
struct UserProfileUpdate {
    var displayName: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var profileVisibility: ProfileVisibility = .friends
    var activityVisibility: ActivityVisibility = .friends
    
    func toRequestBody() -> [String: Any] {
        return [
            "display_name": displayName.isEmpty ? nil : displayName,
            "first_name": firstName.isEmpty ? nil : firstName,
            "last_name": lastName.isEmpty ? nil : lastName,
            "profile_visibility": profileVisibility.rawValue,
            "activity_visibility": activityVisibility.rawValue
        ].compactMapValues { $0 }
    }
}
