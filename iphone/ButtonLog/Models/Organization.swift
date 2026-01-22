import Foundation

// MARK: - Organization Model

struct Organization: Identifiable, Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let logoUrl: String?
    let website: String?

    // Enterprise features
    let domain: String?
    let ssoEnabled: Bool
    let requireSso: Bool

    // Settings
    let allowPersonalTeams: Bool
    let defaultTeamRole: String

    // Billing
    let billingEmail: String?
    let billingAddress: [String: String]?
    let taxId: String?

    // Limits
    let maxSeats: Int?
    let maxTeams: Int?

    // Status
    let status: OrganizationStatus

    let createdAt: Date
    let updatedAt: Date

    // Optional associations
    var myRole: OrganizationRole?
    var canManage: Bool?
    var canManageBilling: Bool?
    var memberCount: Int?
    var teamCount: Int?
    var members: [OrganizationMember]?
    var teams: [Team]?
    var subscription: OrganizationSubscription?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case logoUrl = "logo_url"
        case website, domain
        case ssoEnabled = "sso_enabled"
        case requireSso = "require_sso"
        case allowPersonalTeams = "allow_personal_teams"
        case defaultTeamRole = "default_team_role"
        case billingEmail = "billing_email"
        case billingAddress = "billing_address"
        case taxId = "tax_id"
        case maxSeats = "max_seats"
        case maxTeams = "max_teams"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case myRole = "my_role"
        case canManage = "can_manage"
        case canManageBilling = "can_manage_billing"
        case memberCount = "member_count"
        case teamCount = "team_count"
        case members, teams, subscription
    }
}

// MARK: - Organization Status

enum OrganizationStatus: String, Codable {
    case active = "active"
    case suspended = "suspended"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .suspended: return "Suspended"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Organization Role

enum OrganizationRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case billingAdmin = "billing_admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .billingAdmin: return "Billing Admin"
        case .member: return "Member"
        }
    }

    var isAdmin: Bool {
        self == .owner || self == .admin
    }

    var canManageBilling: Bool {
        self == .owner || self == .billingAdmin
    }
}

// MARK: - Organization Member

struct OrganizationMember: Identifiable, Codable {
    let id: String
    let userId: String
    let organizationId: String
    let role: OrganizationRole
    let joinedAt: Date
    let invitedById: String?
    var user: PublicUser?
    var invitedBy: PublicUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case organizationId = "organization_id"
        case role
        case joinedAt = "joined_at"
        case invitedById = "invited_by_id"
        case user
        case invitedBy = "invited_by"
    }
}

// MARK: - Organization Subscription

struct OrganizationSubscription: Identifiable, Codable {
    let id: String
    let organizationId: String
    let planId: String
    let status: OrganizationSubscriptionStatus
    let seatsPurchased: Int
    let seatsUsed: Int
    let pricePerSeat: Int
    let billingCycle: BillingCycle
    let periodStart: Date
    let periodEnd: Date
    let cancelledAt: Date?
    let createdAt: Date
    let updatedAt: Date

    var seatsAvailable: Int {
        seatsPurchased - seatsUsed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case planId = "plan_id"
        case status
        case seatsPurchased = "seats_purchased"
        case seatsUsed = "seats_used"
        case pricePerSeat = "price_per_seat"
        case billingCycle = "billing_cycle"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case cancelledAt = "cancelled_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum OrganizationSubscriptionStatus: String, Codable {
    case active = "active"
    case pastDue = "past_due"
    case cancelled = "cancelled"
    case trialing = "trialing"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .pastDue: return "Past Due"
        case .cancelled: return "Cancelled"
        case .trialing: return "Trial"
        }
    }
}

// Note: BillingCycle is defined in Subscription.swift

// MARK: - Organization Invitation

struct OrganizationInvitation: Identifiable, Codable {
    let id: String
    let organizationId: String
    let inviterId: String
    let inviteeId: String?
    let email: String?
    let role: OrganizationRole
    let token: String
    let expiresAt: Date
    let acceptedAt: Date?
    let declinedAt: Date?
    let createdAt: Date
    var organization: OrganizationSummary?
    var inviter: PublicUser?
    var invitee: PublicUser?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case email, role, token
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
        case declinedAt = "declined_at"
        case createdAt = "created_at"
        case organization, inviter, invitee
    }

    var status: InvitationStatus {
        if acceptedAt != nil {
            return .accepted
        }
        if declinedAt != nil {
            return .declined
        }
        if expiresAt < Date() {
            return .expired
        }
        return .pending
    }
}

struct OrganizationSummary: Identifiable, Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let logoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case logoUrl = "logo_url"
    }
}

// MARK: - Create Organization Request

struct CreateOrganizationRequest {
    var name: String = ""
    var slug: String = ""
    var description: String = ""
    var domain: String = ""
    var billingEmail: String = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var generatedSlug: String {
        name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    func toRequestBody() -> [String: Any] {
        var body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        let trimmedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSlug.isEmpty {
            body["slug"] = trimmedSlug
        }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDescription.isEmpty {
            body["description"] = trimmedDescription
        }

        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDomain.isEmpty {
            body["domain"] = trimmedDomain
        }

        let trimmedBillingEmail = billingEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBillingEmail.isEmpty {
            body["billing_email"] = trimmedBillingEmail
        }

        return body
    }
}

// MARK: - API Response Types

struct OrganizationsResponse: Codable {
    let owned: [Organization]
    let member: [Organization]
    let invitations: [OrganizationInvitation]
}
