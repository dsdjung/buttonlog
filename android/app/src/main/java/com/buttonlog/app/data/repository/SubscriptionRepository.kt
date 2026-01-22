package com.buttonlog.app.data.repository

import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SubscriptionRepository @Inject constructor(
    private val apiService: APIService
) {
    suspend fun getSubscriptionPlans(): List<SubscriptionPlan> {
        val response = apiService.getSubscriptionPlans()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get subscription plans")
        }
    }

    suspend fun getCurrentSubscription(): UserSubscription? {
        val response = apiService.getCurrentSubscription()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get current subscription")
        }
    }

    suspend fun getSubscriptionStats(): SubscriptionStats {
        val response = apiService.getSubscriptionStats()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get subscription stats")
        }
    }

    suspend fun createCheckoutSession(
        planId: String,
        billingCycle: BillingCycle,
        couponCode: String? = null
    ): CheckoutSession {
        val request = CreateCheckoutSessionRequest(
            planId = planId,
            billingCycle = billingCycle.name.lowercase(),
            couponCode = couponCode
        )
        val response = apiService.createCheckoutSession(request)
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to create checkout session")
        }
    }

    suspend fun createPortalSession(): PortalSession {
        val response = apiService.createPortalSession()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to create portal session")
        }
    }

    suspend fun cancelSubscription() {
        val response = apiService.cancelSubscription()
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to cancel subscription")
        }
    }

    suspend fun pauseSubscription() {
        val response = apiService.pauseSubscription()
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to pause subscription")
        }
    }

    suspend fun resumeSubscription() {
        val response = apiService.resumeSubscription()
        if (!response.success) {
            throw Exception(response.error?.message ?: "Failed to resume subscription")
        }
    }

    suspend fun applyCoupon(code: String): ApplyCouponResponse {
        val request = ApplyCouponRequest(code = code)
        val response = apiService.applyCoupon(request)
        if (response.success && response.data != null) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to apply coupon")
        }
    }

    suspend fun getPaymentMethods(): List<PaymentMethod> {
        val response = apiService.getPaymentMethods()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get payment methods")
        }
    }

    suspend fun getInvoices(): List<Invoice> {
        val response = apiService.getInvoices()
        if (response.success) {
            return response.data
        } else {
            throw Exception(response.error?.message ?: "Failed to get invoices")
        }
    }
}
