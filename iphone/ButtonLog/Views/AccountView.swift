import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var appState: AppState
    @State private var showingEditProfile = false
    @State private var showingSubscription = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        List {
            // Profile Section
            Section {
                if let user = authManager.currentUser {
                    ProfileHeaderView(user: user) {
                        showingEditProfile = true
                    }
                }
            }
            
            // Subscription Section
            Section("Subscription") {
                if let subscription = appState.currentSubscription {
                    ActiveSubscriptionRow(subscription: subscription) {
                        showingSubscription = true
                    }
                } else {
                    SwiftUI.Button("View Subscription Plans") {
                        showingSubscription = true
                    }
                }
            }
            
            // Statistics Section
            if let stats = appState.subscriptionStats {
                Section("Your Stats") {
                    StatsGrid(stats: stats)
                }
            }
            
            // Teams & Organizations Section
            Section("Teams & Organizations") {
                NavigationLink(destination: TeamsView()) {
                    Label("Teams", systemImage: "person.3.fill")
                }

                NavigationLink(destination: OrganizationsView()) {
                    Label("Organizations", systemImage: "building.2.fill")
                }
            }

            // Settings Section
            Section("Settings") {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell")
                }

                NavigationLink(destination: PrivacySettingsView()) {
                    Label("Privacy", systemImage: "lock")
                }

                NavigationLink(destination: DataExportView()) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
            
            // Support Section
            Section("Support") {
                NavigationLink(destination: SupportView()) {
                    Label("Help & Support", systemImage: "bubble.left.and.bubble.right")
                }

                Link(destination: URL(string: "https://buttonlog.com/help")!) {
                    Label("Help Center", systemImage: "questionmark.circle")
                }

                Link(destination: URL(string: "mailto:support@buttonlog.com")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }
            
            // Account Actions
            Section {
                SwiftUI.Button("Sign Out") {
                    showingLogoutAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Account")
        .refreshable {
            await appState.loadSubscriptionData()
            await authManager.loadCurrentUser()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            SwiftUI.Button("Cancel", role: .cancel) { }
            SwiftUI.Button("Sign Out", role: .destructive) {
                Task {
                    await authManager.logout()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile picture placeholder
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(user.fullName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(user.subscriptionTier.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(subscriptionColor(user.subscriptionTier).opacity(0.2))
                    .foregroundColor(subscriptionColor(user.subscriptionTier))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            SwiftUI.Button("Edit") {
                onEdit()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
    
    private func subscriptionColor(_ tier: SubscriptionTier) -> Color {
        switch tier {
        case .free: return .gray
        case .premium: return .blue
        case .enterprise: return .purple
        }
    }
}

struct ActiveSubscriptionRow: View {
    let subscription: UserSubscription
    let onTap: () -> Void
    
    var body: some View {
        SwiftUI.Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(subscriptionDisplayName())
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(subscription.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor().opacity(0.2))
                        .foregroundColor(statusColor())
                        .cornerRadius(4)
                }
                
                Text("Next billing: \(subscription.periodEnd, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if subscription.isInTrial, let trialEnd = subscription.trialEnd {
                    Text("Trial ends: \(trialEnd, style: .date)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func subscriptionDisplayName() -> String {
        // You'd typically fetch the plan name from the subscription plans
        return subscription.billingCycle.displayName + " Plan"
    }
    
    private func statusColor() -> Color {
        switch subscription.status {
        case .active: return .green
        case .pastDue: return .orange
        case .cancelled: return .red
        case .paused: return .yellow
        case .trialing: return .blue
        case .incomplete: return .gray
        }
    }
}

struct StatsGrid: View {
    let stats: SubscriptionStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatItem(title: "Total Buttons", value: "\(stats.totalButtons)", color: .blue)
                Spacer()
                StatItem(title: "Total Friends", value: "\(stats.totalFriends)", color: .green)
                Spacer()
                StatItem(title: "Total Clicks", value: "\(stats.totalClicks)", color: .orange)
            }
            
            HStack {
                StatItem(title: "This Month", value: "\(stats.clicksThisMonth)", color: .purple)
                Spacer()
                StatItem(title: "Streak Days", value: "\(stats.streakDays)", color: .red)
                Spacer()
                StatItem(title: "Daily Average", value: String(format: "%.1f", stats.averageClicksPerDay), color: .teal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Settings Views

struct NotificationSettingsView: View {
    @State private var buttonNotifications = true
    @State private var friendNotifications = true
    @State private var systemNotifications = true
    @State private var emailNotifications = false
    @State private var quietHours = false
    @State private var quietStart = Date()
    @State private var quietEnd = Date()
    
    var body: some View {
        Form {
            Section("Push Notifications") {
                Toggle("Button Activity", isOn: $buttonNotifications)
                Toggle("Friend Updates", isOn: $friendNotifications)
                Toggle("System Updates", isOn: $systemNotifications)
            }
            
            Section("Email Notifications") {
                Toggle("Email Updates", isOn: $emailNotifications)
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHours)
                
                if quietHours {
                    DatePicker("Start", selection: $quietStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $quietEnd, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @State private var profileVisibility: ProfileVisibility = .friends
    @State private var activityVisibility: ActivityVisibility = .friends
    
    var body: some View {
        Form {
            Section("Profile Visibility") {
                Picker("Who can see your profile", selection: $profileVisibility) {
                    ForEach(ProfileVisibility.allCases, id: \.self) { visibility in
                        VStack(alignment: .leading) {
                            Text(visibility.displayName)
                            Text(visibility.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(visibility)
                    }
                }
            }
            
            Section("Activity Visibility") {
                Picker("Who can see your button activity", selection: $activityVisibility) {
                    ForEach(ActivityVisibility.allCases, id: \.self) { visibility in
                        VStack(alignment: .leading) {
                            Text(visibility.displayName)
                            Text(visibility.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(visibility)
                    }
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @State private var isExporting = false
    @State private var exportFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    var body: some View {
        Form {
            Section("Export Format") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Data to Export") {
                Text("• All your buttons and settings")
                Text("• Button click history")
                Text("• Friend connections")
                Text("• Account information")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Section {
                SwiftUI.Button("Export My Data") {
                    exportData()
                }
                .disabled(isExporting)
                
                if isExporting {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Preparing export...")
                    }
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            // In a real app, this would trigger the actual export
        }
    }
}

// Additional stub views for editing profile and subscription
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Edit Profile - Coming Soon")
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        SwiftUI.Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Subscription View

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var selectedBillingCycle: BillingCycle = .monthly
    @State private var isLoading = false
    @State private var showingManageSubscription = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var couponCode = ""
    @State private var showingCouponField = false

    private let apiService = APIService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Plan Status (for free users without subscription record)
                    if appState.currentSubscription == nil {
                        CurrentPlanCard(
                            userTier: authManager.currentUser?.subscriptionTier ?? .free,
                            onUpgrade: { }
                        )
                    }

                    // Current Subscription Status (for paid users)
                    if let subscription = appState.currentSubscription {
                        CurrentSubscriptionCard(
                            subscription: subscription,
                            onManage: { showingManageSubscription = true }
                        )
                    }

                    // Billing Cycle Toggle
                    BillingCycleSelector(selectedCycle: $selectedBillingCycle)

                    // Loading state
                    if appState.isLoadingSubscription && appState.subscriptionPlans.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading plans...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if appState.subscriptionPlans.isEmpty {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Unable to load subscription plans")
                                .font(.headline)
                            Text("Pull down to refresh")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Plans Comparison
                        PlansSection(
                            plans: appState.subscriptionPlans,
                            currentSubscription: appState.currentSubscription,
                            userSubscriptionTier: authManager.currentUser?.subscriptionTier,
                            selectedCycle: selectedBillingCycle,
                            isLoading: isLoading,
                            onSelectPlan: { plan in
                                Task {
                                    await subscribeToPlan(plan)
                                }
                            }
                        )
                    }

                    // Coupon Code Section
                    CouponSection(
                        couponCode: $couponCode,
                        showingField: $showingCouponField
                    )

                    // Feature Comparison Table (only show if plans loaded)
                    if !appState.subscriptionPlans.isEmpty {
                        FeatureComparisonSection(plans: appState.subscriptionPlans)
                    }

                    // FAQ Section
                    FAQSection()
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await appState.loadSubscriptionData()
            }
            .alert("Error", isPresented: $showingError) {
                SwiftUI.Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingManageSubscription) {
                ManageSubscriptionView()
            }
        }
        .task {
            // Always load subscription data when view appears
            await appState.loadSubscriptionData()
        }
    }

    private func subscribeToPlan(_ plan: SubscriptionPlan) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await apiService.createCheckoutSession(
                planId: plan.id,
                billingCycle: selectedBillingCycle,
                couponCode: couponCode.isEmpty ? nil : couponCode
            )

            // Open Stripe Checkout in Safari
            if let url = URL(string: session.checkoutUrl) {
                await MainActor.run {
                    openURL(url)
                }
            }
        } catch {
            errorMessage = "Failed to start checkout: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Current Plan Card (for free users)

struct CurrentPlanCard: View {
    let userTier: SubscriptionTier
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(userTier.displayName) Plan")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("Free")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            Divider()

            // Plan limits
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.blue)
                    Text("Up to \(userTier.maxButtons) buttons")
                        .font(.subheadline)
                }
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.green)
                    Text("Up to \(userTier.maxFriends) friends")
                        .font(.subheadline)
                }
                if !userTier.hasAnalytics {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundColor(.gray)
                        Text("Basic analytics only")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Current Subscription Card

struct CurrentSubscriptionCard: View {
    let subscription: UserSubscription
    let onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(subscription.billingCycle.displayName + " Plan")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                SubscriptionStatusBadge(status: subscription.status)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next billing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subscription.periodEnd, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subscription.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if subscription.isInTrial, let trialEnd = subscription.trialEnd {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text("Trial ends \(trialEnd, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            SwiftUI.Button("Manage Subscription") {
                onManage()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SubscriptionStatusBadge: View {
    let status: SubscriptionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(6)
    }

    private var backgroundColor: Color {
        switch status {
        case .active: return .green
        case .pastDue: return .orange
        case .cancelled: return .red
        case .paused: return .yellow
        case .trialing: return .blue
        case .incomplete: return .gray
        }
    }
}

// MARK: - Billing Cycle Selector

struct BillingCycleSelector: View {
    @Binding var selectedCycle: BillingCycle

    var body: some View {
        VStack(spacing: 8) {
            Picker("Billing Cycle", selection: $selectedCycle) {
                Text("Monthly").tag(BillingCycle.monthly)
                Text("Yearly (Save 17%)").tag(BillingCycle.yearly)
            }
            .pickerStyle(.segmented)

            if selectedCycle == .yearly {
                Text("Get 2 months free with annual billing")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Plans Section

struct PlansSection: View {
    let plans: [SubscriptionPlan]
    let currentSubscription: UserSubscription?
    let userSubscriptionTier: SubscriptionTier?
    let selectedCycle: BillingCycle
    let isLoading: Bool
    let onSelectPlan: (SubscriptionPlan) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ForEach(sortedPlans, id: \.id) { plan in
                PlanCard(
                    plan: plan,
                    selectedCycle: selectedCycle,
                    isCurrentPlan: isCurrentPlan(plan),
                    isLoading: isLoading,
                    onSelect: { onSelectPlan(plan) }
                )
            }
        }
    }

    private var sortedPlans: [SubscriptionPlan] {
        plans.sorted { $0.monthlyPrice < $1.monthlyPrice }
    }

    private func isCurrentPlan(_ plan: SubscriptionPlan) -> Bool {
        // Check if user has an active subscription for this plan
        if let subscriptionPlanId = currentSubscription?.subscriptionPlanId {
            return subscriptionPlanId == plan.id
        }
        // For free users without a subscription, check if this is the free plan
        if let tier = userSubscriptionTier, tier == .free, plan.slug == "free" {
            return true
        }
        return false
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let selectedCycle: BillingCycle
    let isCurrentPlan: Bool
    let isLoading: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        if plan.slug == "premium" {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    if !plan.description.isEmpty {
                        Text(plan.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(priceForCycle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(billingLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Key Features
            VStack(alignment: .leading, spacing: 6) {
                PlanFeatureRow(text: "Up to \(plan.limits.maxButtons ?? 999) buttons", included: true)
                PlanFeatureRow(text: "Up to \(plan.limits.maxFriends ?? 999) friends", included: true)
                PlanFeatureRow(text: "\(plan.limits.analyticsHistoryDays ?? 7) days analytics history", included: true)
                PlanFeatureRow(text: "Calendar sync", included: plan.features.calendarSync)
                PlanFeatureRow(text: "API access", included: plan.features.apiAccess)
                PlanFeatureRow(text: "Priority support", included: plan.features.prioritySupport)
            }

            // Action Button
            if isCurrentPlan {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Current Plan")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else if plan.monthlyPrice == 0 {
                // Free plan - no action needed
                Text("Free Forever")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                SwiftUI.Button {
                    onSelect()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Subscribe")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(plan.slug == "premium" ? Color.blue : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    plan.slug == "premium" ? Color.blue : Color.gray.opacity(0.3),
                    lineWidth: plan.slug == "premium" ? 2 : 1
                )
        )
    }

    private var priceForCycle: String {
        let price = selectedCycle == .monthly ? plan.monthlyPrice : plan.yearlyPrice
        if price == 0 {
            return "Free"
        }
        return String(format: "$%.2f", price)
    }

    private var billingLabel: String {
        if plan.monthlyPrice == 0 {
            return "forever"
        }
        return selectedCycle == .monthly ? "/month" : "/year"
    }
}

struct PlanFeatureRow: View {
    let text: String
    let included: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(included ? .green : .gray)
                .font(.caption)

            Text(text)
                .font(.subheadline)
                .foregroundColor(included ? .primary : .secondary)
        }
    }
}

// MARK: - Coupon Section

struct CouponSection: View {
    @Binding var couponCode: String
    @Binding var showingField: Bool

    var body: some View {
        VStack(spacing: 8) {
            if showingField {
                HStack {
                    TextField("Enter coupon code", text: $couponCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)

                    SwiftUI.Button("Apply") {
                        // Coupon will be applied during checkout
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                SwiftUI.Button("Have a coupon code?") {
                    showingField = true
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Feature Comparison Section

struct FeatureComparisonSection: View {
    let plans: [SubscriptionPlan]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUI.Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Compare All Features")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(spacing: 0) {
                    FeatureComparisonRow(feature: "Buttons", values: plans.map { "\($0.limits.maxButtons ?? 999)" })
                    FeatureComparisonRow(feature: "Friends", values: plans.map { "\($0.limits.maxFriends ?? 999)" })
                    FeatureComparisonRow(feature: "Clicks/month", values: plans.map { formatLimit($0.limits.maxClicksPerMonth) })
                    FeatureComparisonRow(feature: "Analytics history", values: plans.map { "\($0.limits.analyticsHistoryDays ?? 7) days" })
                    FeatureComparisonRow(feature: "Calendar sync", values: plans.map { $0.features.calendarSync ? "Yes" : "No" })
                    FeatureComparisonRow(feature: "API access", values: plans.map { $0.features.apiAccess ? "Yes" : "No" })
                    FeatureComparisonRow(feature: "Custom themes", values: plans.map { $0.features.customThemes ? "Yes" : "No" })
                    FeatureComparisonRow(feature: "Team features", values: plans.map { $0.features.teamFeatures ? "Yes" : "No" })
                    FeatureComparisonRow(feature: "Priority support", values: plans.map { $0.features.prioritySupport ? "Yes" : "No" })
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func formatLimit(_ limit: Int?) -> String {
        guard let limit = limit else { return "Unlimited" }
        if limit >= 999999 { return "Unlimited" }
        return "\(limit)"
    }
}

struct FeatureComparisonRow: View {
    let feature: String
    let values: [String]

    var body: some View {
        HStack {
            Text(feature)
                .font(.caption)
                .frame(width: 100, alignment: .leading)

            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(value == "Yes" ? .green : (value == "No" ? .secondary : .primary))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - FAQ Section

struct FAQSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.headline)

            SubscriptionFAQItem(
                question: "Can I cancel anytime?",
                answer: "Yes, you can cancel your subscription at any time. You'll continue to have access until the end of your billing period."
            )

            SubscriptionFAQItem(
                question: "How do I manage my subscription?",
                answer: "Tap 'Manage Subscription' to update your payment method, change plans, or cancel. You'll be directed to our secure payment portal."
            )

            SubscriptionFAQItem(
                question: "What happens to my data if I downgrade?",
                answer: "Your data is always safe. If you exceed the limits of your new plan, you won't be able to create new items until you're within limits, but existing data is preserved."
            )

            SubscriptionFAQItem(
                question: "Do you offer refunds?",
                answer: "We offer a 14-day money-back guarantee for first-time subscribers. Contact support for assistance."
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SubscriptionFAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                        .foregroundColor(.blue)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Manage Subscription View

struct ManageSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppState

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private let apiService = APIService.shared

    var body: some View {
        NavigationView {
            List {
                // Current Plan Section
                if let subscription = appState.currentSubscription {
                    Section("Current Plan") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(subscription.billingCycle.displayName + " Plan")
                                    .font(.headline)
                                Spacer()
                                SubscriptionStatusBadge(status: subscription.status)
                            }

                            Text("Next billing: \(subscription.periodEnd, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(subscription.formattedAmount + " / " + subscription.billingCycle.rawValue)
                                .font(.subheadline)
                        }
                    }
                }

                // Payment Management
                Section("Payment") {
                    SwiftUI.Button {
                        Task { await openCustomerPortal() }
                    } label: {
                        HStack {
                            Label("Update Payment Method", systemImage: "creditcard")
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isLoading)

                    SwiftUI.Button {
                        Task { await openCustomerPortal() }
                    } label: {
                        HStack {
                            Label("View Billing History", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(isLoading)
                }

                // Plan Changes
                Section("Plan") {
                    SwiftUI.Button {
                        Task { await openCustomerPortal() }
                    } label: {
                        Label("Change Plan", systemImage: "arrow.up.arrow.down")
                    }
                    .disabled(isLoading)
                }

                // Danger Zone
                if appState.currentSubscription != nil {
                    Section {
                        SwiftUI.Button(role: .destructive) {
                            Task { await openCustomerPortal() }
                        } label: {
                            Label("Cancel Subscription", systemImage: "xmark.circle")
                        }
                        .disabled(isLoading)
                    } footer: {
                        Text("You'll continue to have access until the end of your current billing period.")
                    }
                }
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                SwiftUI.Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func openCustomerPortal() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await apiService.createPortalSession()

            if let url = URL(string: session.portalUrl) {
                await MainActor.run {
                    openURL(url)
                }
            }
        } catch {
            errorMessage = "Failed to open payment portal: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        AccountView()
            .environmentObject(AuthenticationManager())
            .environmentObject(AppState())
    }
}