package com.buttonlog.app.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.data.model.*
import com.buttonlog.app.ui.viewmodels.FaqItem
import java.util.Locale
import com.buttonlog.app.ui.viewmodels.SubscriptionUiState
import com.buttonlog.app.ui.viewmodels.SubscriptionViewModel
import com.buttonlog.app.ui.viewmodels.subscriptionFaqs

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubscriptionScreen(
    viewModel: SubscriptionViewModel = hiltViewModel(),
    onBackClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.loadSubscriptionData()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Subscription") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorContent(
                        error = uiState.error!!,
                        onRetry = { viewModel.loadSubscriptionData() },
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    SubscriptionContent(
                        uiState = uiState,
                        viewModel = viewModel,
                        onOpenUrl = { url ->
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        }
                    )
                }
            }
        }
    }

    // Cancel Subscription Dialog
    if (uiState.showCancelDialog) {
        CancelSubscriptionDialog(
            isLoading = uiState.isCancelling,
            onConfirm = {
                viewModel.cancelSubscription {
                    // Success - dialog will close automatically
                }
            },
            onDismiss = { viewModel.hideCancelDialog() }
        )
    }
}

@Composable
private fun ErrorContent(
    error: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = error,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onRetry) {
            Text("Retry")
        }
    }
}

@Composable
private fun SubscriptionContent(
    uiState: SubscriptionUiState,
    viewModel: SubscriptionViewModel,
    onOpenUrl: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Current Subscription Card
        item {
            CurrentSubscriptionCard(
                subscription = uiState.currentSubscription,
                plans = uiState.plans,
                stats = uiState.stats,
                isOpeningPortal = uiState.isOpeningPortal,
                onManageClick = {
                    viewModel.openCustomerPortal { url ->
                        onOpenUrl(url)
                    }
                },
                onCancelClick = { viewModel.showCancelDialog() }
            )
        }

        // Billing Cycle Selector
        item {
            BillingCycleSelector(
                selectedCycle = uiState.selectedBillingCycle,
                yearlyDiscount = uiState.yearlyDiscount,
                onCycleSelected = { viewModel.selectBillingCycle(it) }
            )
        }

        // Plans Section
        item {
            Text(
                text = "Choose Your Plan",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        }

        items(uiState.sortedPlans) { plan ->
            PlanCard(
                plan = plan,
                billingCycle = uiState.selectedBillingCycle,
                isCurrentPlan = plan.id == uiState.currentSubscription?.subscriptionPlanId,
                isCheckingOut = uiState.isCheckingOut,
                onSubscribe = {
                    viewModel.createCheckoutSession(plan) { url ->
                        onOpenUrl(url)
                    }
                }
            )
        }

        // Coupon Section
        item {
            CouponSection(
                couponCode = uiState.couponCode,
                appliedCoupon = uiState.appliedCoupon,
                isApplying = uiState.isApplyingCoupon,
                error = uiState.couponError,
                onCodeChange = { viewModel.updateCouponCode(it) },
                onApply = { viewModel.applyCoupon() },
                onRemove = { viewModel.removeCoupon() }
            )
        }

        // Feature Comparison Section
        item {
            FeatureComparisonSection(
                plans = uiState.sortedPlans,
                isExpanded = uiState.showFeatureComparison,
                onToggle = { viewModel.toggleFeatureComparison() }
            )
        }

        // FAQ Section
        item {
            Text(
                text = "Frequently Asked Questions",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        subscriptionFaqs.forEachIndexed { index, faq ->
            item {
                FaqCard(
                    faq = faq,
                    isExpanded = uiState.expandedFaqItems.contains(index),
                    onToggle = { viewModel.toggleFaqItem(index) }
                )
            }
        }

        // Bottom spacing
        item {
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun CurrentSubscriptionCard(
    subscription: UserSubscription?,
    plans: List<SubscriptionPlan>,
    stats: SubscriptionStats?,
    isOpeningPortal: Boolean,
    onManageClick: () -> Unit,
    onCancelClick: () -> Unit
) {
    val currentPlan = plans.find { it.id == subscription?.subscriptionPlanId }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (subscription != null) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            if (subscription != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = currentPlan?.name ?: "Current Plan",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        SubscriptionStatusBadge(status = subscription.status)
                    }
                    Text(
                        text = "${subscription.formattedAmount}/${subscription.billingCycle.displayName.lowercase()}",
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Usage Stats
                stats?.let { s ->
                    Text(
                        text = "Usage This Month",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        UsageChip(
                            label = "Buttons",
                            value = s.totalButtons.toString(),
                            limit = currentPlan?.limits?.maxButtons
                        )
                        UsageChip(
                            label = "Friends",
                            value = s.totalFriends.toString(),
                            limit = currentPlan?.limits?.maxFriends
                        )
                        UsageChip(
                            label = "Clicks",
                            value = s.clicksThisMonth.toString(),
                            limit = currentPlan?.limits?.maxClicksPerMonth
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = onManageClick,
                        modifier = Modifier.weight(1f),
                        enabled = !isOpeningPortal
                    ) {
                        if (isOpeningPortal) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Icon(Icons.Default.Settings, null, Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Manage")
                        }
                    }
                    OutlinedButton(
                        onClick = onCancelClick,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text("Cancel")
                    }
                }
            } else {
                // No subscription - Free tier
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "Free Plan",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Upgrade to unlock more features",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun UsageChip(
    label: String,
    value: String,
    limit: Int?
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = if (limit != null) "$value/$limit" else value,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
        )
    }
}

@Composable
private fun SubscriptionStatusBadge(status: SubscriptionStatus) {
    val (backgroundColor, textColor) = when (status) {
        SubscriptionStatus.ACTIVE -> Pair(Color(0xFF4CAF50), Color.White)
        SubscriptionStatus.TRIALING -> Pair(Color(0xFF2196F3), Color.White)
        SubscriptionStatus.PAST_DUE -> Pair(Color(0xFFFF9800), Color.White)
        SubscriptionStatus.CANCELLED -> Pair(Color(0xFF9E9E9E), Color.White)
        SubscriptionStatus.PAUSED -> Pair(Color(0xFF607D8B), Color.White)
        SubscriptionStatus.INCOMPLETE -> Pair(Color(0xFFF44336), Color.White)
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = backgroundColor,
        modifier = Modifier.padding(top = 4.dp)
    ) {
        Text(
            text = status.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
        )
    }
}

@Composable
private fun BillingCycleSelector(
    selectedCycle: BillingCycle,
    yearlyDiscount: Int,
    onCycleSelected: (BillingCycle) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            BillingCycle.entries.forEach { cycle ->
                val isSelected = cycle == selectedCycle
                FilterChip(
                    selected = isSelected,
                    onClick = { onCycleSelected(cycle) },
                    label = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(cycle.displayName)
                            if (cycle == BillingCycle.YEARLY && yearlyDiscount > 0) {
                                Spacer(modifier = Modifier.width(4.dp))
                                Surface(
                                    shape = RoundedCornerShape(4.dp),
                                    color = MaterialTheme.colorScheme.tertiary
                                ) {
                                    Text(
                                        text = "Save $yearlyDiscount%",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onTertiary,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }
                    },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun PlanCard(
    plan: SubscriptionPlan,
    billingCycle: BillingCycle,
    isCurrentPlan: Boolean,
    isCheckingOut: Boolean,
    onSubscribe: () -> Unit
) {
    val price = if (billingCycle == BillingCycle.MONTHLY) plan.monthlyPrice else plan.yearlyPrice
    val formattedPrice = String.format(Locale.US, "$%.2f", price)
    val isFreePlan = plan.monthlyPrice == 0.0

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (isCurrentPlan) {
                    Modifier.border(
                        2.dp,
                        MaterialTheme.colorScheme.primary,
                        RoundedCornerShape(12.dp)
                    )
                } else {
                    Modifier
                }
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = plan.name,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        if (isCurrentPlan) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = MaterialTheme.colorScheme.primary
                            ) {
                                Text(
                                    text = "Current",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                    Text(
                        text = plan.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column(horizontalAlignment = Alignment.End) {
                    if (isFreePlan) {
                        Text(
                            text = "Free",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                            maxLines = 1
                        )
                    } else {
                        Text(
                            text = formattedPrice,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1
                        )
                        Text(
                            text = "/${billingCycle.displayName.lowercase()}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Features list - only show implemented features
            PlanFeatureRow(
                text = "Up to ${plan.limits.maxButtons ?: "Unlimited"} buttons",
                included = true
            )
            PlanFeatureRow(
                text = "Up to ${plan.limits.maxFriends ?: "Unlimited"} friends",
                included = true
            )
            PlanFeatureRow(
                text = "${plan.limits.maxClicksPerMonth ?: "Unlimited"} clicks/month",
                included = true
            )

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = onSubscribe,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isCurrentPlan && !isCheckingOut && !isFreePlan
            ) {
                if (isCheckingOut) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Text(
                        text = when {
                            isCurrentPlan -> "Current Plan"
                            isFreePlan -> "Free Plan"
                            else -> "Subscribe"
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun PlanFeatureRow(
    text: String,
    included: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (included) Icons.Default.Check else Icons.Default.Close,
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = if (included) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            }
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = if (included) {
                MaterialTheme.colorScheme.onSurface
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            },
            textDecoration = if (!included) TextDecoration.LineThrough else null
        )
    }
}

@Composable
private fun CouponSection(
    couponCode: String,
    appliedCoupon: CouponCode?,
    isApplying: Boolean,
    error: String?,
    onCodeChange: (String) -> Unit,
    onApply: () -> Unit,
    onRemove: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Have a coupon code?",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(12.dp))

            if (appliedCoupon != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.primaryContainer)
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = appliedCoupon.code,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = appliedCoupon.discountDisplay,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    IconButton(onClick = onRemove) {
                        Icon(Icons.Default.Close, "Remove coupon")
                    }
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = couponCode,
                        onValueChange = onCodeChange,
                        label = { Text("Coupon code") },
                        singleLine = true,
                        isError = error != null,
                        modifier = Modifier.weight(1f)
                    )
                    Button(
                        onClick = onApply,
                        enabled = couponCode.isNotBlank() && !isApplying,
                        modifier = Modifier.align(Alignment.CenterVertically)
                    ) {
                        if (isApplying) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text("Apply")
                        }
                    }
                }

                if (error != null) {
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun FeatureComparisonSection(
    plans: List<SubscriptionPlan>,
    isExpanded: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
            Surface(
                onClick = onToggle,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Compare All Features",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Icon(
                        imageVector = if (isExpanded) {
                            Icons.Default.ExpandLess
                        } else {
                            Icons.Default.ExpandMore
                        },
                        contentDescription = null
                    )
                }
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = expandVertically(),
                exit = shrinkVertically()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 16.dp)
                ) {
                    // Header row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Feature",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f)
                        )
                        plans.forEach { plan ->
                            Text(
                                text = plan.name,
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.width(70.dp)
                            )
                        }
                    }

                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                    // Feature rows - only show implemented features
                    FeatureComparisonRow("Max Buttons", plans) { plan ->
                        plan.limits.maxButtons?.toString() ?: "Unlimited"
                    }
                    FeatureComparisonRow("Max Friends", plans) { plan ->
                        plan.limits.maxFriends?.toString() ?: "Unlimited"
                    }
                    FeatureComparisonRow("Clicks/Month", plans) { plan ->
                        plan.limits.maxClicksPerMonth?.toString() ?: "Unlimited"
                    }
                }
            }
        }
    }
}

@Composable
private fun FeatureComparisonRow(
    label: String,
    plans: List<SubscriptionPlan>,
    valueProvider: (SubscriptionPlan) -> String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        plans.forEach { plan ->
            Text(
                text = valueProvider(plan),
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                modifier = Modifier.width(70.dp)
            )
        }
    }
}

@Composable
private fun FeatureComparisonRowBoolean(
    label: String,
    plans: List<SubscriptionPlan>,
    valueProvider: (SubscriptionPlan) -> Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        plans.forEach { plan ->
            val included = valueProvider(plan)
            Icon(
                imageVector = if (included) Icons.Default.Check else Icons.Default.Close,
                contentDescription = null,
                modifier = Modifier.width(70.dp),
                tint = if (included) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.3f)
                }
            )
        }
    }
}

@Composable
private fun FaqCard(
    faq: FaqItem,
    isExpanded: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Surface(
                onClick = onToggle,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = faq.question,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(1f)
                    )
                    Icon(
                        imageVector = if (isExpanded) {
                            Icons.Default.ExpandLess
                        } else {
                            Icons.Default.ExpandMore
                        },
                        contentDescription = null
                    )
                }
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = expandVertically(),
                exit = shrinkVertically()
            ) {
                Text(
                    text = faq.answer,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, bottom = 16.dp)
                )
            }
        }
    }
}

@Composable
private fun CancelSubscriptionDialog(
    isLoading: Boolean,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = { if (!isLoading) onDismiss() },
        icon = {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error
            )
        },
        title = { Text("Cancel Subscription") },
        text = {
            Text(
                "Are you sure you want to cancel your subscription? You'll lose access to premium features at the end of your current billing period."
            )
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                enabled = !isLoading,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Cancel Subscription")
                }
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                enabled = !isLoading
            ) {
                Text("Keep Subscription")
            }
        }
    )
}
