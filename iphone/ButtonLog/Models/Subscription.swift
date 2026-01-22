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

// MARK: - Stripe Integration Models

/// Response from creating a Stripe Checkout session
struct CheckoutSession: Codable {
    let checkoutUrl: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case checkoutUrl = "checkout_url"
        case sessionId = "session_id"
    }
}

/// Response from creating a Stripe Customer Portal session
struct PortalSession: Codable {
    let portalUrl: String

    enum CodingKeys: String, CodingKey {
        case portalUrl = "portal_url"
    }
}

/// Response from creating a Stripe Setup Intent (for adding payment methods)
struct SetupIntent: Codable {
    let clientSecret: String
    let setupIntentId: String

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case setupIntentId = "setup_intent_id"
    }
}

/// User's saved payment method
struct PaymentMethod: Identifiable, Codable {
    let id: String
    let userId: String
    let paymentProvider: String
    let cardBrand: String?
    let cardLastFour: String?
    let cardExpMonth: Int?
    let cardExpYear: Int?
    let isDefault: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    var displayString: String {
        guard let brand = cardBrand, let last4 = cardLastFour else {
            return "Unknown card"
        }
        return "\(brand.capitalized) •••• \(last4)"
    }

    var expirationString: String? {
        guard let month = cardExpMonth, let year = cardExpYear else { return nil }
        return String(format: "%02d/%02d", month, year % 100)
    }

    var isExpired: Bool {
        guard let month = cardExpMonth, let year = cardExpYear else { return false }
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        if year < currentYear {
            return true
        } else if year == currentYear && month < currentMonth {
            return true
        }
        return false
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case paymentProvider = "payment_provider"
        case cardBrand = "card_brand"
        case cardLastFour = "card_last_four"
        case cardExpMonth = "card_exp_month"
        case cardExpYear = "card_exp_year"
        case isDefault = "is_default"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Invoice for billing
struct Invoice: Identifiable, Codable {
    let id: String
    let userId: String
    let invoiceNumber: String?
    let status: InvoiceStatus
    let amountDue: Double
    let amountPaid: Double
    let currency: String
    let invoiceDate: Date
    let dueDate: Date?
    let paidAt: Date?
    let hostedInvoiceUrl: String?
    let pdfUrl: String?
    let createdAt: Date
    let updatedAt: Date

    var formattedAmountDue: String {
        return String(format: "$%.2f", amountDue)
    }

    var formattedAmountPaid: String {
        return String(format: "$%.2f", amountPaid)
    }

    var balance: Double {
        return amountDue - amountPaid
    }

    var isPaid: Bool {
        return status == .paid
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case invoiceNumber = "invoice_number"
        case status
        case amountDue = "amount_due"
        case amountPaid = "amount_paid"
        case currency
        case invoiceDate = "invoice_date"
        case dueDate = "due_date"
        case paidAt = "paid_at"
        case hostedInvoiceUrl = "hosted_invoice_url"
        case pdfUrl = "pdf_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum InvoiceStatus: String, Codable {
    case draft = "draft"
    case open = "open"
    case paid = "paid"
    case uncollectible = "uncollectible"
    case void = "void"

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .open: return "Open"
        case .paid: return "Paid"
        case .uncollectible: return "Uncollectible"
        case .void: return "Void"
        }
    }
}

/// Coupon code for discounts
struct CouponCode: Identifiable, Codable {
    let id: String
    let code: String
    let name: String?
    let description: String?
    let discountType: DiscountType
    let discountValue: Double
    let duration: CouponDuration
    let durationMonths: Int?
    let maxRedemptions: Int?
    let timesRedeemed: Int
    let validFrom: Date?
    let validUntil: Date?
    let isActive: Bool
    let createdAt: Date

    var discountDisplay: String {
        switch discountType {
        case .percentage:
            return "\(Int(discountValue))% off"
        case .fixedAmount:
            return String(format: "$%.2f off", discountValue)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, code, name, description
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case duration
        case durationMonths = "duration_months"
        case maxRedemptions = "max_redemptions"
        case timesRedeemed = "times_redeemed"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

enum DiscountType: String, Codable {
    case percentage = "percentage"
    case fixedAmount = "fixed_amount"
}

enum CouponDuration: String, Codable {
    case once = "once"
    case repeating = "repeating"
    case forever = "forever"

    var displayName: String {
        switch self {
        case .once: return "One time"
        case .repeating: return "Limited time"
        case .forever: return "Forever"
        }
    }
}

/// Response from applying a coupon
struct ApplyCouponResponse: Codable {
    let success: Bool
    let coupon: CouponCode?
    let message: String?
}