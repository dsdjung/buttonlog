import Foundation

// MARK: - Team Model

struct Team: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let icon: String
    let color: String
    let ownerId: String
    let organizationId: String?
    let memberCount: Int?
    let buttonCount: Int?
    let createdAt: Date
    let updatedAt: Date

    // Optional associations
    var owner: PublicUser?
    var myRole: TeamRole?
    var canManage: Bool?
    var members: [TeamMember]?
    var buttons: [TeamButton]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color
        case ownerId = "owner_id"
        case organizationId = "organization_id"
        case memberCount = "member_count"
        case buttonCount = "button_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case owner
        case myRole = "my_role"
        case canManage = "can_manage"
        case members, buttons
    }
}

// MARK: - Team Role

enum TeamRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var isAdmin: Bool {
        self == .owner || self == .admin
    }
}

// MARK: - Team Member

struct TeamMember: Identifiable, Codable {
    let id: String
    let userId: String
    let teamId: String
    let role: TeamRole
    let joinedAt: Date
    let invitedById: String?
    var user: PublicUser?
    var invitedBy: PublicUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case role
        case joinedAt = "joined_at"
        case invitedById = "invited_by_id"
        case user
        case invitedBy = "invited_by"
    }
}

// MARK: - Team Button

struct TeamButton: Identifiable, Codable {
    let id: String
    let teamId: String
    let buttonId: String
    let permission: TeamButtonPermission
    let addedById: String?
    let addedAt: Date
    var button: TeamButtonInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case buttonId = "button_id"
        case permission
        case addedById = "added_by_id"
        case addedAt = "added_at"
        case button
    }
}

struct TeamButtonInfo: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let icon: String
    let color: String
}

enum TeamButtonPermission: String, Codable, CaseIterable {
    case view = "view"
    case click = "click"
    case admin = "admin"

    var displayName: String {
        switch self {
        case .view: return "View Only"
        case .click: return "Can Click"
        case .admin: return "Full Access"
        }
    }
}

// MARK: - Team Invitation

struct TeamInvitation: Identifiable, Codable {
    let id: String
    let teamId: String
    let inviterId: String
    let inviteeId: String
    let role: TeamRole
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date?
    var team: TeamSummary?
    var inviter: PublicUser?
    var invitee: PublicUser?

    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case role, status
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case team, inviter, invitee
    }

    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return expiresAt < Date()
        }
        return false
    }
}

struct TeamSummary: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let icon: String
    let color: String
}

enum InvitationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case cancelled = "cancelled"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Create Team Request

struct CreateTeamRequest {
    var name: String = ""
    var description: String = ""
    var icon: String = "people"
    var color: String = "#3B82F6"

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toRequestBody() -> [String: Any] {
        var body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "icon": icon,
            "color": color
        ]

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDescription.isEmpty {
            body["description"] = trimmedDescription
        }

        return body
    }
}
