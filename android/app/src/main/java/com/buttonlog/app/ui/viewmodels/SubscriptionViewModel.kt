package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.model.*
import com.buttonlog.app.data.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SubscriptionViewModel @Inject constructor(
    private val repository: SubscriptionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SubscriptionUiState())
    val uiState: StateFlow<SubscriptionUiState> = _uiState.asStateFlow()

    fun loadSubscriptionData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                // Load plans, current subscription, and stats in parallel
                val plans = repository.getSubscriptionPlans()
                val currentSubscription = try {
                    repository.getCurrentSubscription()
                } catch (_: Exception) {
                    null
                }
                val stats = try {
                    repository.getSubscriptionStats()
                } catch (_: Exception) {
                    null
                }

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        plans = plans.filter { plan -> plan.isActive },
                        currentSubscription = currentSubscription,
                        stats = stats
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load subscription data"
                    )
                }
            }
        }
    }

    fun selectBillingCycle(cycle: BillingCycle) {
        _uiState.update { it.copy(selectedBillingCycle = cycle) }
    }

    fun updateCouponCode(code: String) {
        _uiState.update { it.copy(couponCode = code, appliedCoupon = null, couponError = null) }
    }

    fun applyCoupon() {
        val code = _uiState.value.couponCode
        if (code.isBlank()) return

        viewModelScope.launch {
            _uiState.update { it.copy(isApplyingCoupon = true, couponError = null) }
            try {
                val response = repository.applyCoupon(code)
                if (response.success && response.coupon != null) {
                    _uiState.update {
                        it.copy(
                            isApplyingCoupon = false,
                            appliedCoupon = response.coupon
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isApplyingCoupon = false,
                            couponError = response.message ?: "Invalid coupon code"
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isApplyingCoupon = false,
                        couponError = e.message ?: "Failed to apply coupon"
                    )
                }
            }
        }
    }

    fun removeCoupon() {
        _uiState.update { it.copy(couponCode = "", appliedCoupon = null, couponError = null) }
    }

    fun createCheckoutSession(
        plan: SubscriptionPlan,
        onSuccess: (String) -> Unit
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isCheckingOut = true, error = null) }
            try {
                val session = repository.createCheckoutSession(
                    planId = plan.id,
                    billingCycle = _uiState.value.selectedBillingCycle,
                    couponCode = _uiState.value.appliedCoupon?.code
                )
                _uiState.update { it.copy(isCheckingOut = false) }
                onSuccess(session.checkoutUrl)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isCheckingOut = false,
                        error = e.message ?: "Failed to start checkout"
                    )
                }
            }
        }
    }

    fun openCustomerPortal(onSuccess: (String) -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isOpeningPortal = true, error = null) }
            try {
                val session = repository.createPortalSession()
                _uiState.update { it.copy(isOpeningPortal = false) }
                onSuccess(session.portalUrl)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isOpeningPortal = false,
                        error = e.message ?: "Failed to open billing portal"
                    )
                }
            }
        }
    }

    fun cancelSubscription(onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isCancelling = true, error = null) }
            try {
                repository.cancelSubscription()
                _uiState.update {
                    it.copy(
                        isCancelling = false,
                        showCancelDialog = false
                    )
                }
                loadSubscriptionData()
                onSuccess()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isCancelling = false,
                        error = e.message ?: "Failed to cancel subscription"
                    )
                }
            }
        }
    }

    fun showCancelDialog() {
        _uiState.update { it.copy(showCancelDialog = true) }
    }

    fun hideCancelDialog() {
        _uiState.update { it.copy(showCancelDialog = false) }
    }

    fun toggleFaqItem(index: Int) {
        _uiState.update { state ->
            val expanded = state.expandedFaqItems.toMutableSet()
            if (expanded.contains(index)) {
                expanded.remove(index)
            } else {
                expanded.add(index)
            }
            state.copy(expandedFaqItems = expanded)
        }
    }

    fun toggleFeatureComparison() {
        _uiState.update { it.copy(showFeatureComparison = !it.showFeatureComparison) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class SubscriptionUiState(
    val isLoading: Boolean = false,
    val isCheckingOut: Boolean = false,
    val isOpeningPortal: Boolean = false,
    val isCancelling: Boolean = false,
    val isApplyingCoupon: Boolean = false,
    val error: String? = null,
    val couponError: String? = null,
    val plans: List<SubscriptionPlan> = emptyList(),
    val currentSubscription: UserSubscription? = null,
    val stats: SubscriptionStats? = null,
    val selectedBillingCycle: BillingCycle = BillingCycle.MONTHLY,
    val couponCode: String = "",
    val appliedCoupon: CouponCode? = null,
    val showCancelDialog: Boolean = false,
    val showFeatureComparison: Boolean = false,
    val expandedFaqItems: Set<Int> = emptySet()
) {
    val sortedPlans: List<SubscriptionPlan>
        get() = plans.sortedBy { it.monthlyPrice }

    val yearlyDiscount: Int
        get() {
            val plan = plans.firstOrNull { it.monthlyPrice > 0 } ?: return 0
            val monthlyTotal = plan.monthlyPrice * 12
            val yearlyTotal = plan.yearlyPrice
            return if (monthlyTotal > 0) {
                ((monthlyTotal - yearlyTotal) / monthlyTotal * 100).toInt()
            } else {
                0
            }
        }
}

// FAQ Data
data class FaqItem(
    val question: String,
    val answer: String
)

val subscriptionFaqs = listOf(
    FaqItem(
        question = "Can I cancel anytime?",
        answer = "Yes, you can cancel your subscription at any time. Your access will continue until the end of your current billing period."
    ),
    FaqItem(
        question = "What payment methods do you accept?",
        answer = "We accept all major credit cards including Visa, Mastercard, American Express, and Discover. Payments are securely processed through Stripe."
    ),
    FaqItem(
        question = "Can I switch plans?",
        answer = "Yes, you can upgrade or downgrade your plan at any time. When upgrading, you'll be charged the prorated difference. When downgrading, the new rate applies at your next billing cycle."
    ),
    FaqItem(
        question = "Is there a free trial?",
        answer = "Some plans include a free trial period. Check the plan details for specific trial information."
    ),
    FaqItem(
        question = "What happens when I reach my limits?",
        answer = "When you reach your plan's limits (buttons, friends, or monthly clicks), you'll be notified and can upgrade to continue. Your existing data is never deleted."
    )
)
