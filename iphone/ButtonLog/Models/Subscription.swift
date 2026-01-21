import Foundation

struct SubscriptionPlan: Identifiable, Codable {
    let id: String
    let name: String
    let slug: String
    let description: String
    let monthlyPrice: Double
    let yearlyPrice: Double
    let features: SubscriptionFeatures
    let limits: SubscriptionLimits
    let trialDays: Int?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var formattedMonthlyPrice: String {
        return String(format: "$%.2f", monthlyPrice)
    }
    
    var formattedYearlyPrice: String {
        return String(format: "$%.2f", yearlyPrice)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case monthlyPrice = "monthly_price"
        case yearlyPrice = "yearly_price"
        case features, limits
        case trialDays = "trial_days"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SubscriptionFeatures: Codable {
    let analytics: Bool
    let calendarSync: Bool
    let apiAccess: Bool
    let customThemes: Bool
    let prioritySupport: Bool
    let teamFeatures: Bool
    let whiteLabelOptions: Bool
    
    enum CodingKeys: String, CodingKey {
        case analytics
        case calendarSync = "calendar_sync"
        case apiAccess = "api_access"
        case customThemes = "custom_themes"
        case prioritySupport = "priority_support"
        case teamFeatures = "team_features"
        case whiteLabelOptions = "white_label_options"
    }
}

struct SubscriptionLimits: Codable {
    let maxButtons: Int?
    let maxFriends: Int?
    let maxClicksPerMonth: Int?
    let analyticsHistoryDays: Int?
    let exportHistoryDays: Int?
    
    enum CodingKeys: String, CodingKey {
        case maxButtons = "max_buttons"
        case maxFriends = "max_friends"
        case maxClicksPerMonth = "max_clicks_per_month"
        case analyticsHistoryDays = "analytics_history_days"
        case exportHistoryDays = "export_history_days"
    }
}

struct UserSubscription: Identifiable, Codable {
    let id: String
    let userId: String
    let subscriptionPlanId: String
    let status: SubscriptionStatus
    let billingCycle: BillingCycle
    let amount: Double
    let currency: String
    let periodStart: Date
    let periodEnd: Date
    let trialStart: Date?
    let trialEnd: Date?
    let paymentProvider: String?
    let providerSubscriptionId: String?
    let usage: SubscriptionUsage
    let createdAt: Date
    let updatedAt: Date
    
    var isActive: Bool {
        return status == .active
    }
    
    var isInTrial: Bool {
        guard let trialEnd = trialEnd else { return false }
        return Date() <= trialEnd
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case subscriptionPlanId = "subscription_plan_id"
        case status
        case billingCycle = "billing_cycle"
        case amount, currency
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case trialStart = "trial_start"
        case trialEnd = "trial_end"
        case paymentProvider = "payment_provider"
        case providerSubscriptionId = "provider_subscription_id"
        case usage
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case pastDue = "past_due"
    case cancelled = "cancelled"
    case paused = "paused"
    case trialing = "trialing"
    case incomplete = "incomplete"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .pastDue: return "Past Due"
        case .cancelled: return "Cancelled"
        case .paused: return "Paused"
        case .trialing: return "Trial"
        case .incomplete: return "Incomplete"
        }
    }
}

enum BillingCycle: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

struct SubscriptionUsage: Codable {
    let buttonsUsed: Int
    let friendsUsed: Int
    let clicksThisMonth: Int
    let lastResetAt: Date
    
    enum CodingKeys: String, CodingKey {
        case buttonsUsed = "buttons_used"
        case friendsUsed = "friends_used"
        case clicksThisMonth = "clicks_this_month"
        case lastResetAt = "last_reset_at"
    }
}

struct SubscriptionStats: Codable {
    let totalButtons: Int
    let totalFriends: Int
    let totalClicks: Int
    let clicksThisMonth: Int
    let clicksThisWeek: Int
    let clicksToday: Int
    let averageClicksPerDay: Double
    let mostActiveButton: String?
    let streakDays: Int
    
    enum CodingKeys: String, CodingKey {
        case totalButtons = "total_buttons"
        case totalFriends = "total_friends"
        case totalClicks = "total_clicks"
        case clicksThisMonth = "clicks_this_month"
        case clicksThisWeek = "clicks_this_week"
        case clicksToday = "clicks_today"
        case averageClicksPerDay = "average_clicks_per_day"
        case mostActiveButton = "most_active_button"
        case streakDays = "streak_days"
    }
}