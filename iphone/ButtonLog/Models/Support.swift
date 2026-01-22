import Foundation

// MARK: - Support Ticket

struct SupportTicket: Identifiable, Codable {
    let id: String
    let subject: String
    let category: TicketCategory
    let priority: TicketPriority
    let status: TicketStatus
    let unreadCount: Int?
    let assignedAdmin: SupportAdmin?
    let createdAt: Date
    let updatedAt: Date
    var messages: [TicketMessage]?

    enum CodingKeys: String, CodingKey {
        case id, subject, category, priority, status, messages
        case unreadCount = "unread_count"
        case assignedAdmin = "assigned_admin"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Ticket Message

struct TicketMessage: Identifiable, Codable {
    let id: String
    let content: String
    let senderId: String
    let senderName: String?
    let isFromSupport: Bool
    let createdAt: Date
    let readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, content
        case senderId = "sender_id"
        case senderName = "sender_name"
        case isFromSupport = "is_from_support"
        case createdAt = "created_at"
        case readAt = "read_at"
    }
}

// MARK: - Support Admin

struct SupportAdmin: Codable {
    let id: String
    let name: String?
}

// MARK: - Enums

enum TicketCategory: String, Codable, CaseIterable {
    case bug = "bug"
    case featureRequest = "feature_request"
    case question = "question"
    case other = "other"

    var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .featureRequest: return "Feature Request"
        case .question: return "Question"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .featureRequest: return "lightbulb"
        case .question: return "questionmark.circle"
        case .other: return "ellipsis.circle"
        }
    }
}

enum TicketPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

enum TicketStatus: String, Codable, CaseIterable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case closed = "closed"

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }

    var color: String {
        switch self {
        case .open: return "yellow"
        case .inProgress: return "blue"
        case .resolved: return "green"
        case .closed: return "gray"
        }
    }

    var isActive: Bool {
        switch self {
        case .open, .inProgress: return true
        case .resolved, .closed: return false
        }
    }
}

// MARK: - Form Data

struct TicketFormData {
    var subject: String = ""
    var category: TicketCategory = .question
    var priority: TicketPriority = .normal
    var message: String = ""

    var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toRequestBody() -> [String: Any] {
        return [
            "ticket": [
                "subject": subject.trimmingCharacters(in: .whitespacesAndNewlines),
                "category": category.rawValue,
                "priority": priority.rawValue,
                "message": message.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        ]
    }
}

struct MessageFormData {
    var content: String = ""

    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toRequestBody() -> [String: Any] {
        return [
            "message": [
                "content": content.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        ]
    }
}
