package com.buttonlog.app.data.model

import com.google.gson.annotations.SerializedName

// MARK: - Subscription Plans

data class SubscriptionPlan(
    val id: String,
    val name: String,
    val slug: String,
    val description: String,
    @SerializedName("monthly_price")
    val monthlyPrice: Double,
    @SerializedName("yearly_price")
    val yearlyPrice: Double,
    val features: SubscriptionFeatures,
    val limits: SubscriptionLimits,
    @SerializedName("trial_days")
    val trialDays: Int?,
    @SerializedName("is_active")
    val isActive: Boolean,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    val formattedMonthlyPrice: String
        get() = String.format("$%.2f", monthlyPrice)

    val formattedYearlyPrice: String
        get() = String.format("$%.2f", yearlyPrice)
}

data class SubscriptionFeatures(
    val analytics: Boolean,
    @SerializedName("calendar_sync")
    val calendarSync: Boolean,
    @SerializedName("api_access")
    val apiAccess: Boolean,
    @SerializedName("custom_themes")
    val customThemes: Boolean,
    @SerializedName("priority_support")
    val prioritySupport: Boolean,
    @SerializedName("team_features")
    val teamFeatures: Boolean,
    @SerializedName("white_label_options")
    val whiteLabelOptions: Boolean
)

data class SubscriptionLimits(
    @SerializedName("max_buttons")
    val maxButtons: Int?,
    @SerializedName("max_friends")
    val maxFriends: Int?,
    @SerializedName("max_clicks_per_month")
    val maxClicksPerMonth: Int?,
    @SerializedName("analytics_history_days")
    val analyticsHistoryDays: Int?,
    @SerializedName("export_history_days")
    val exportHistoryDays: Int?
)

// MARK: - User Subscription

data class UserSubscription(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("subscription_plan_id")
    val subscriptionPlanId: String,
    val status: SubscriptionStatus,
    @SerializedName("billing_cycle")
    val billingCycle: BillingCycle,
    val amount: Double,
    val currency: String,
    @SerializedName("period_start")
    val periodStart: String,
    @SerializedName("period_end")
    val periodEnd: String,
    @SerializedName("trial_start")
    val trialStart: String?,
    @SerializedName("trial_end")
    val trialEnd: String?,
    @SerializedName("payment_provider")
    val paymentProvider: String?,
    @SerializedName("provider_subscription_id")
    val providerSubscriptionId: String?,
    val usage: SubscriptionUsage,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    val isActive: Boolean
        get() = status == SubscriptionStatus.ACTIVE

    val formattedAmount: String
        get() = String.format("$%.2f", amount)
}

enum class SubscriptionStatus(val displayName: String) {
    @SerializedName("active")
    ACTIVE("Active"),

    @SerializedName("past_due")
    PAST_DUE("Past Due"),

    @SerializedName("cancelled")
    CANCELLED("Cancelled"),

    @SerializedName("paused")
    PAUSED("Paused"),

    @SerializedName("trialing")
    TRIALING("Trial"),

    @SerializedName("incomplete")
    INCOMPLETE("Incomplete")
}

enum class BillingCycle(val displayName: String) {
    @SerializedName("monthly")
    MONTHLY("Monthly"),

    @SerializedName("yearly")
    YEARLY("Yearly")
}

data class SubscriptionUsage(
    @SerializedName("buttons_used")
    val buttonsUsed: Int,
    @SerializedName("friends_used")
    val friendsUsed: Int,
    @SerializedName("clicks_this_month")
    val clicksThisMonth: Int,
    @SerializedName("last_reset_at")
    val lastResetAt: String
)

data class SubscriptionStats(
    @SerializedName("total_buttons")
    val totalButtons: Int,
    @SerializedName("total_friends")
    val totalFriends: Int,
    @SerializedName("total_clicks")
    val totalClicks: Int,
    @SerializedName("clicks_this_month")
    val clicksThisMonth: Int,
    @SerializedName("clicks_this_week")
    val clicksThisWeek: Int,
    @SerializedName("clicks_today")
    val clicksToday: Int,
    @SerializedName("average_clicks_per_day")
    val averageClicksPerDay: Double,
    @SerializedName("most_active_button")
    val mostActiveButton: String?,
    @SerializedName("streak_days")
    val streakDays: Int
)

// MARK: - Stripe Integration Models

data class CheckoutSession(
    @SerializedName("checkout_url")
    val checkoutUrl: String,
    @SerializedName("session_id")
    val sessionId: String
)

data class PortalSession(
    @SerializedName("portal_url")
    val portalUrl: String
)

data class SetupIntent(
    @SerializedName("client_secret")
    val clientSecret: String,
    @SerializedName("setup_intent_id")
    val setupIntentId: String
)

// MARK: - Payment Method

data class PaymentMethod(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("payment_provider")
    val paymentProvider: String,
    @SerializedName("card_brand")
    val cardBrand: String?,
    @SerializedName("card_last_four")
    val cardLastFour: String?,
    @SerializedName("card_exp_month")
    val cardExpMonth: Int?,
    @SerializedName("card_exp_year")
    val cardExpYear: Int?,
    @SerializedName("is_default")
    val isDefault: Boolean,
    @SerializedName("is_active")
    val isActive: Boolean,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    val displayString: String
        get() {
            val brand = cardBrand ?: return "Unknown card"
            val last4 = cardLastFour ?: return "Unknown card"
            return "${brand.replaceFirstChar { it.uppercase() }} •••• $last4"
        }

    val expirationString: String?
        get() {
            val month = cardExpMonth ?: return null
            val year = cardExpYear ?: return null
            return String.format("%02d/%02d", month, year % 100)
        }

    val isExpired: Boolean
        get() {
            val month = cardExpMonth ?: return false
            val year = cardExpYear ?: return false
            val calendar = java.util.Calendar.getInstance()
            val currentYear = calendar.get(java.util.Calendar.YEAR)
            val currentMonth = calendar.get(java.util.Calendar.MONTH) + 1

            return when {
                year < currentYear -> true
                year == currentYear && month < currentMonth -> true
                else -> false
            }
        }
}

// MARK: - Invoice

data class Invoice(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("invoice_number")
    val invoiceNumber: String?,
    val status: InvoiceStatus,
    @SerializedName("amount_due")
    val amountDue: Double,
    @SerializedName("amount_paid")
    val amountPaid: Double,
    val currency: String,
    @SerializedName("invoice_date")
    val invoiceDate: String,
    @SerializedName("due_date")
    val dueDate: String?,
    @SerializedName("paid_at")
    val paidAt: String?,
    @SerializedName("hosted_invoice_url")
    val hostedInvoiceUrl: String?,
    @SerializedName("pdf_url")
    val pdfUrl: String?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    val formattedAmountDue: String
        get() = String.format("$%.2f", amountDue)

    val formattedAmountPaid: String
        get() = String.format("$%.2f", amountPaid)

    val balance: Double
        get() = amountDue - amountPaid

    val isPaid: Boolean
        get() = status == InvoiceStatus.PAID
}

enum class InvoiceStatus(val displayName: String) {
    @SerializedName("draft")
    DRAFT("Draft"),

    @SerializedName("open")
    OPEN("Open"),

    @SerializedName("paid")
    PAID("Paid"),

    @SerializedName("uncollectible")
    UNCOLLECTIBLE("Uncollectible"),

    @SerializedName("void")
    VOID("Void")
}

// MARK: - Coupon

data class CouponCode(
    val id: String,
    val code: String,
    val name: String?,
    val description: String?,
    @SerializedName("discount_type")
    val discountType: DiscountType,
    @SerializedName("discount_value")
    val discountValue: Double,
    val duration: CouponDuration,
    @SerializedName("duration_months")
    val durationMonths: Int?,
    @SerializedName("max_redemptions")
    val maxRedemptions: Int?,
    @SerializedName("times_redeemed")
    val timesRedeemed: Int,
    @SerializedName("valid_from")
    val validFrom: String?,
    @SerializedName("valid_until")
    val validUntil: String?,
    @SerializedName("is_active")
    val isActive: Boolean,
    @SerializedName("created_at")
    val createdAt: String
) {
    val discountDisplay: String
        get() = when (discountType) {
            DiscountType.PERCENTAGE -> "${discountValue.toInt()}% off"
            DiscountType.FIXED_AMOUNT -> String.format("$%.2f off", discountValue)
        }
}

enum class DiscountType {
    @SerializedName("percentage")
    PERCENTAGE,

    @SerializedName("fixed_amount")
    FIXED_AMOUNT
}

enum class CouponDuration(val displayName: String) {
    @SerializedName("once")
    ONCE("One time"),

    @SerializedName("repeating")
    REPEATING("Limited time"),

    @SerializedName("forever")
    FOREVER("Forever")
}

data class ApplyCouponResponse(
    val success: Boolean,
    val coupon: CouponCode?,
    val message: String?
)

// MARK: - API Response Wrappers

data class SubscriptionPlansResponse(
    val success: Boolean,
    val data: List<SubscriptionPlan>,
    val error: ApiError?
)

data class UserSubscriptionResponse(
    val success: Boolean,
    val data: UserSubscription?,
    val error: ApiError?
)

data class SubscriptionStatsResponse(
    val success: Boolean,
    val data: SubscriptionStats,
    val error: ApiError?
)

data class CheckoutSessionResponse(
    val success: Boolean,
    val data: CheckoutSession,
    val error: ApiError?
)

data class PortalSessionResponse(
    val success: Boolean,
    val data: PortalSession,
    val error: ApiError?
)

data class SetupIntentResponse(
    val success: Boolean,
    val data: SetupIntent,
    val error: ApiError?
)

data class PaymentMethodsResponse(
    val success: Boolean,
    val data: List<PaymentMethod>,
    val error: ApiError?
)

data class PaymentMethodResponse(
    val success: Boolean,
    val data: PaymentMethod,
    val error: ApiError?
)

data class InvoicesResponse(
    val success: Boolean,
    val data: List<Invoice>,
    val error: ApiError?
)

data class InvoiceResponse(
    val success: Boolean,
    val data: Invoice,
    val error: ApiError?
)

data class ApplyCouponApiResponse(
    val success: Boolean,
    val data: ApplyCouponResponse?,
    val error: ApiError?
)

data class PermissionCheckResponse(
    val success: Boolean,
    val data: PermissionCheckData,
    val error: ApiError?
)

data class PermissionCheckData(
    val allowed: Boolean
)

// MARK: - Request Models

data class CreateSubscriptionRequest(
    @SerializedName("plan_slug")
    val planSlug: String,
    @SerializedName("billing_cycle")
    val billingCycle: String
)

data class CreateCheckoutSessionRequest(
    @SerializedName("plan_id")
    val planId: String,
    @SerializedName("billing_cycle")
    val billingCycle: String,
    @SerializedName("coupon_code")
    val couponCode: String? = null
)

data class AddPaymentMethodRequest(
    @SerializedName("payment_method_id")
    val paymentMethodId: String
)

data class ApplyCouponRequest(
    val code: String
)

data class PermissionCheckRequest(
    val action: String,
    val context: Map<String, Any> = emptyMap()
)
