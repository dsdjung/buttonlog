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

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Subscription Management - Coming Soon")
                .navigationTitle("Subscription")
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

#Preview {
    NavigationView {
        AccountView()
            .environmentObject(AuthenticationManager())
            .environmentObject(AppState())
    }
}