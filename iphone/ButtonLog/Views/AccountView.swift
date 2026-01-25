import SwiftUI
import SafariServices

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

                NavigationLink(destination: PasswordChangeView()) {
                    Label("Change Password", systemImage: "key")
                }

                // Data Export - Hidden for now
                // NavigationLink(destination: DataExportView()) {
                //     Label("Export Data", systemImage: "square.and.arrow.up")
                // }

                NavigationLink(destination: WebhookSettingsView()) {
                    Label("Webhook Notifications", systemImage: "link")
                }

                NavigationLink(destination: AboutView()) {
                    Label("About", systemImage: "info.circle")
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
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var profileVisibility: ProfileVisibility = .friends
    @State private var activityVisibility: ActivityVisibility = .friends
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?

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
                .onChange(of: profileVisibility) { _, newValue in
                    Task { await savePrivacySettings() }
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
                .onChange(of: activityVisibility) { _, newValue in
                    Task { await savePrivacySettings() }
                }
            }

            if isSaving {
                Section {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Saving...")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Error", isPresented: $showingError) {
            SwiftUI.Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Failed to save privacy settings")
        }
    }

    private func loadCurrentSettings() {
        guard let user = authManager.currentUser else { return }
        profileVisibility = user.profileVisibility
        activityVisibility = user.activityVisibility
    }

    @MainActor
    private func savePrivacySettings() async {
        guard !isSaving else { return }
        isSaving = true

        var update = UserProfileUpdate()
        update.profileVisibility = profileVisibility
        update.activityVisibility = activityVisibility

        // Preserve other settings
        if let user = authManager.currentUser {
            update.displayName = user.displayName ?? ""
            update.firstName = user.firstName ?? ""
            update.lastName = user.lastName ?? ""
        }

        await authManager.updateProfile(update)

        isSaving = false

        if let error = authManager.errorMessage {
            errorMessage = error
            showingError = true
        }
    }
}

struct DataExportView: View {
    @State private var isExporting = false
    @State private var exportFormat: ExportFormat = .json
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?

    private let apiService = APIService.shared

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"

        var apiFormat: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
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
                Text("All your buttons and settings")
                Text("Button click history")
                Text("Friend connections")
                Text("Account information")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Section {
                SwiftUI.Button {
                    Task { await exportData() }
                } label: {
                    HStack {
                        Text("Export My Data")
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isExporting)
            } footer: {
                Text("Your data will be downloaded as a \(exportFormat.rawValue) file that you can save or share.")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Error", isPresented: $showingError) {
            SwiftUI.Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Failed to export data")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = exportedFileURL {
                ShareSheet(items: [fileURL])
            }
        }
    }

    @MainActor
    private func exportData() async {
        isExporting = true

        do {
            let (data, filename, _) = try await apiService.exportUserData(format: exportFormat.apiFormat)

            // Save to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)

            try data.write(to: fileURL)

            exportedFileURL = fileURL
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isExporting = false
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Password Change View
struct PasswordChangeView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    private let apiService = APIService.shared

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                    .textContentType(.password)
            } header: {
                Text("Current Password")
            } footer: {
                Text("Enter your current password to verify your identity")
            }

            Section {
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)

                SecureField("Confirm New Password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } header: {
                Text("New Password")
            } footer: {
                Text("Password must be at least 8 characters long")
            }

            Section {
                SwiftUI.Button {
                    Task { await changePassword() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Change Password")
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isSaving)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            SwiftUI.Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Failed to change password")
        }
        .alert("Password Changed", isPresented: $showingSuccess) {
            SwiftUI.Button("OK") {
                // Clear form
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }

    @MainActor
    private func changePassword() async {
        isSaving = true

        do {
            try await apiService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSaving = false
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var displayName: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section("Display Information") {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }

                Section {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }

                        if let username = user.username {
                            HStack {
                                Text("Username")
                                Spacer()
                                Text(username)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Account Information")
                } footer: {
                    Text("Email and username cannot be changed here. Contact support if you need to update these.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isSaving || !hasChanges)
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .alert("Error", isPresented: $showingError) {
                SwiftUI.Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An error occurred while saving your profile.")
            }
            .alert("Profile Updated", isPresented: $showingSuccess) {
                SwiftUI.Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your profile has been updated successfully.")
            }
        }
    }

    private var hasChanges: Bool {
        guard let user = authManager.currentUser else { return false }
        return displayName != (user.displayName ?? "") ||
               firstName != (user.firstName ?? "") ||
               lastName != (user.lastName ?? "")
    }

    private func loadCurrentValues() {
        guard let user = authManager.currentUser else { return }
        displayName = user.displayName ?? ""
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true

        var update = UserProfileUpdate()
        update.displayName = displayName
        update.firstName = firstName
        update.lastName = lastName

        // Preserve current visibility settings
        if let user = authManager.currentUser {
            update.profileVisibility = user.profileVisibility
            update.activityVisibility = user.activityVisibility
        }

        await authManager.updateProfile(update)

        isSaving = false

        if let error = authManager.errorMessage {
            errorMessage = error
            showingError = true
        } else {
            showingSuccess = true
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
    @State private var checkoutURL: URL?
    @State private var showingSafari = false

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
            .sheet(isPresented: $showingSafari) {
                if let url = checkoutURL {
                    SafariView(url: url)
                }
            }
        }
        .task {
            // Always load subscription data when view appears
            await appState.loadSubscriptionData()
        }
    }

    @MainActor
    private func subscribeToPlan(_ plan: SubscriptionPlan) async {
        print("DEBUG: subscribeToPlan called for plan: \(plan.id)")
        isLoading = true

        do {
            print("DEBUG: Calling createCheckoutSession...")
            let session = try await apiService.createCheckoutSession(
                planId: plan.id,
                billingCycle: selectedBillingCycle,
                couponCode: couponCode.isEmpty ? nil : couponCode
            )
            print("DEBUG: Got checkout session: \(session.checkoutUrl)")

            isLoading = false

            // Open Stripe Checkout in Safari View
            if let url = URL(string: session.checkoutUrl) {
                print("DEBUG: Opening URL in Safari View: \(url)")
                checkoutURL = url
                showingSafari = true
            }
        } catch {
            print("DEBUG: Error in subscribeToPlan: \(error)")
            isLoading = false
            errorMessage = "Failed to start checkout: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
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
                TrialCountdownBanner(trialEnd: trialEnd)
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

// MARK: - Trial Countdown Banner

struct TrialCountdownBanner: View {
    let trialEnd: Date

    private var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: now, to: trialEnd).day ?? 0
        return max(days, 0)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(daysRemaining == 1 ? "1 day left in trial" : "\(daysRemaining) days left in trial")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.9, green: 0.35, blue: 0))

                Text("Your subscription will start automatically")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.95, blue: 0.88))
        .cornerRadius(8)
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

            // Key Features - only show implemented features
            VStack(alignment: .leading, spacing: 6) {
                PlanFeatureRow(text: "Up to \(plan.limits.maxButtons ?? 999) buttons", included: true)
                PlanFeatureRow(text: "Up to \(plan.limits.maxFriends ?? 999) friends", included: true)
                PlanFeatureRow(text: "\(plan.limits.maxClicksPerMonth ?? 999) clicks/month", included: true)
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
                        Text(subscribeButtonText)
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

    private var subscribeButtonText: String {
        if let trialDays = plan.trialDays, trialDays > 0 {
            return "Start \(trialDays)-Day Free Trial"
        }
        return "Subscribe"
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
                    // Only show implemented features
                    FeatureComparisonRow(feature: "Buttons", values: plans.map { "\($0.limits.maxButtons ?? 999)" })
                    FeatureComparisonRow(feature: "Friends", values: plans.map { "\($0.limits.maxFriends ?? 999)" })
                    FeatureComparisonRow(feature: "Clicks/month", values: plans.map { formatLimit($0.limits.maxClicksPerMonth) })
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
    @EnvironmentObject private var appState: AppState

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var portalURL: URL?
    @State private var showingSafari = false

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
            .sheet(isPresented: $showingSafari) {
                if let url = portalURL {
                    SafariView(url: url)
                }
            }
        }
    }

    @MainActor
    private func openCustomerPortal() async {
        isLoading = true

        do {
            let session = try await apiService.createPortalSession()

            isLoading = false

            if let url = URL(string: session.portalUrl) {
                portalURL = url
                showingSafari = true
            }
        } catch {
            isLoading = false
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