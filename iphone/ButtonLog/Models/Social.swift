import Foundation

struct Friend: Identifiable, Codable {
    let id: String
    let friendId: String
    let friendUser: PublicUser
    let status: FriendshipStatus
    let permissions: FriendPermissions
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case friendId = "friend_id"
        case friendUser = "friend_user"
        case status, permissions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PublicUser: Identifiable, Codable {
    let id: String
    let username: String?
    let displayName: String?
    let firstName: String?
    let lastName: String?
    let profileVisibility: ProfileVisibility
    
    var displayNameOrUsername: String {
        return displayName ?? username ?? "User"
    }
    
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return displayNameOrUsername
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case profileVisibility = "profile_visibility"
    }
}

enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Friends"
        case .blocked: return "Blocked"
        }
    }
}

struct FriendPermissions: Codable {
    let canSeeButtons: Bool
    let canSeeActivity: Bool
    let receiveNotifications: Bool
    let canComment: Bool
    
    enum CodingKeys: String, CodingKey {
        case canSeeButtons = "can_see_buttons"
        case canSeeActivity = "can_see_activity"
        case receiveNotifications = "receive_notifications"
        case canComment = "can_comment"
    }
}

struct FriendRequest {
    var email: String = ""
    var username: String = ""
    var message: String = ""
    
    var isValid: Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func toRequestBody() -> [String: Any] {
        var body: [String: Any] = [:]
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedEmail.isEmpty {
            body["email"] = trimmedEmail
        }
        if !trimmedUsername.isEmpty {
            body["username"] = trimmedUsername
        }
        if !trimmedMessage.isEmpty {
            body["message"] = trimmedMessage
        }
        
        return body
    }
}

struct FriendPermissionUpdate {
    var canSeeButtons: Bool
    var canSeeActivity: Bool
    var receiveNotifications: Bool
    var canComment: Bool
    
    func toRequestBody() -> [String: Any] {
        return [
            "can_see_buttons": canSeeButtons,
            "can_see_activity": canSeeActivity,
            "receive_notifications": receiveNotifications,
            "can_comment": canComment
        ]
    }
}