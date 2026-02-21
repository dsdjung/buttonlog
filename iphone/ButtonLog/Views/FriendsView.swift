import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAddFriend = false
    @State private var selectedFriend: Friend?
    @State private var showingCreatedGiftButtons = false
    @State private var showingShareSheet = false

    private var acceptedFriends: [Friend] {
        appState.friends.filter { $0.status == .accepted }
    }

    var body: some View {
        Group {
            if acceptedFriends.isEmpty && appState.pendingFriendRequests.isEmpty {
                // Empty state - no friends yet
                EmptyFriendsStateView(
                    onInviteByEmail: { showingAddFriend = true },
                    onShareLink: { showingShareSheet = true }
                )
            } else {
                List {
                    // Created Gift Buttons Section
                    Section {
                        NavigationLink(destination: CreatedGiftButtonsView()) {
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text("Buttons I Created for Friends")
                                        .font(.body)
                                    if !appState.createdGiftButtons.isEmpty {
                                        Text("\(appState.createdGiftButtons.count) gift button\(appState.createdGiftButtons.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }

                    // Pending Friend Requests Section
                    if !appState.pendingFriendRequests.isEmpty {
                        Section("Pending Requests") {
                            ForEach(appState.pendingFriendRequests) { friend in
                                PendingFriendRequestRow(friend: friend) {
                                    Task {
                                        await appState.acceptFriendRequest(friendId: friend.id)
                                    }
                                }
                            }
                        }
                    }

                    // Friends Section
                    Section("Friends") {
                        if acceptedFriends.isEmpty {
                            Text("No friends yet")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(acceptedFriends) { friend in
                                FriendRow(friend: friend) {
                                    selectedFriend = friend
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button("Invite") {
                    showingAddFriend = true
                }
            }
        }
        .refreshable {
            await appState.loadFriends()
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
        .sheet(item: $selectedFriend) { friend in
            FriendDetailView(friend: friend)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [
                "Join me on ButtonLog! Let's keep each other accountable. Download the app: https://buttonlog.com/download"
            ])
        }
    }
}

// MARK: - Empty Friends State View

struct EmptyFriendsStateView: View {
    let onInviteByEmail: () -> Void
    let onShareLink: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: BLSpacing.xl) {
                Spacer()
                    .frame(height: BLSpacing.xxxl)

                // Icon illustration
                ZStack {
                    Circle()
                        .fill(Color.blPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blPrimary)
                }

                // Headline
                VStack(spacing: BLSpacing.sm) {
                    Text("Better Together")
                        .font(BLTypography.headlineLarge)
                        .foregroundColor(.blTextPrimary)

                    Text("Invite your accountability partner to track habits together and keep each other on track")
                        .font(BLTypography.bodyLarge)
                        .foregroundColor(.blTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BLSpacing.xl)
                }

                // Feature highlights
                VStack(spacing: BLSpacing.md) {
                    EmptyStateBenefitRow(
                        icon: "gift.fill",
                        color: .purple,
                        text: "Create buttons for friends"
                    )

                    EmptyStateBenefitRow(
                        icon: "bell.badge.fill",
                        color: .blPrimary,
                        text: "Get notified when they complete"
                    )

                    EmptyStateBenefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blSecondary,
                        text: "Celebrate progress together"
                    )
                }
                .padding(.horizontal, BLSpacing.xl)

                Spacer()
                    .frame(height: BLSpacing.lg)

                // CTA buttons
                VStack(spacing: BLSpacing.md) {
                    SwiftUI.Button(action: onInviteByEmail) {
                        HStack(spacing: BLSpacing.sm) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                            Text("Invite by Email")
                                .font(BLTypography.labelLarge)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: BLRadius.lg)
                                .fill(Color.blPrimary)
                        )
                    }

                    SwiftUI.Button(action: onShareLink) {
                        HStack(spacing: BLSpacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text("Share Invite Link")
                                .font(BLTypography.labelLarge)
                        }
                        .foregroundColor(.blPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: BLRadius.lg)
                                .stroke(Color.blPrimary, lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, BLSpacing.xl)

                Spacer()
            }
        }
        .background(Color.blBackground)
    }
}

struct EmptyStateBenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: BLSpacing.md) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            Text(text)
                .font(BLTypography.bodyMedium)
                .foregroundColor(.blTextPrimary)

            Spacer()
        }
        .padding(BLSpacing.md)
        .background(Color.blSurface)
        .cornerRadius(BLRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BLRadius.lg)
                .stroke(Color.blBorder, lineWidth: 1)
        )
    }
}

struct PendingFriendRequestRow: View {
    let friend: Friend
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(friend.friendUser.displayNameOrUsername)
                        .font(.headline)
                    
                    if let username = friend.friendUser.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    SwiftUI.Button("Accept") {
                        onAccept()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    SwiftUI.Button("Decline") {
                        // Handle decline
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct FriendRow: View {
    let friend: Friend
    let onTap: () -> Void
    
    var body: some View {
        SwiftUI.Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(friend.friendUser.fullName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let username = friend.friendUser.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Invite by Email")) {
                    TextField("Enter email address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }

                Section {
                    Text("We'll send an invite to this email address. If they're already on ButtonLog, they'll get a friend request. If not, they'll receive an invitation to join.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Invite Friend")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Send Invite") {
                        sendInvite()
                    }
                    .disabled(!isValidEmail || isLoading)
                }
            }
        }
        .disabled(isLoading)
    }

    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func sendInvite() {
        isLoading = true

        Task {
            let request = FriendRequest(email: email)
            let success = await appState.sendFriendRequest(request)

            await MainActor.run {
                isLoading = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct FriendDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState

    let friend: Friend
    @State private var permissions = FriendPermissionUpdate(
        canSeeButtons: false,
        canSeeActivity: false,
        receiveNotifications: false,
        canComment: false
    )
    @State private var isLoading = false
    @State private var showingRemoveAlert = false
    @State private var showingFriendButtons = false
    @State private var showingCreateGiftButton = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(friend.friendUser.fullName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if let username = friend.friendUser.username {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("Friends since \(friend.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Actions") {
                    SwiftUI.Button(action: {
                        showingCreateGiftButton = true
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.purple)
                            Text("Create Button for \(friend.friendUser.displayNameOrUsername)")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Activity") {
                    NavigationLink(destination: FriendButtonsView(friend: friend)) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(.blue)
                            Text("View Buttons")
                        }
                    }

                    NavigationLink(destination: FriendActivityView(friend: friend)) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("View Activity History")
                        }
                    }
                }

                Section("Permissions") {
                    Toggle("Can see your buttons", isOn: $permissions.canSeeButtons)
                    Toggle("Can see your activity", isOn: $permissions.canSeeActivity)
                    Toggle("Receive notifications", isOn: $permissions.receiveNotifications)
                    Toggle("Can comment", isOn: $permissions.canComment)
                }

                Section {
                    SwiftUI.Button("Remove Friend", role: .destructive) {
                        showingRemoveAlert = true
                    }
                }
            }
            .navigationTitle("Friend Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Save") {
                        savePermissions()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadPermissions()
        }
        .alert("Remove Friend", isPresented: $showingRemoveAlert) {
            SwiftUI.Button("Cancel", role: .cancel) { }
            SwiftUI.Button("Remove", role: .destructive) {
                removeFriend()
            }
        } message: {
            Text("Are you sure you want to remove \(friend.friendUser.displayNameOrUsername) as a friend?")
        }
        .sheet(isPresented: $showingCreateGiftButton) {
            CreateGiftButtonView(friend: friend)
        }
        .disabled(isLoading)
    }
    
    private func loadPermissions() {
        permissions.canSeeButtons = friend.permissions.canSeeButtons
        permissions.canSeeActivity = friend.permissions.canSeeActivity
        permissions.receiveNotifications = friend.permissions.receiveNotifications
        permissions.canComment = friend.permissions.canComment
    }
    
    private func savePermissions() {
        isLoading = true
        
        Task {
            // Update permissions via API
            do {
                try await APIService.shared.updateFriendPermissions(
                    friendId: friend.friendId,
                    permissions: permissions
                )
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    appState.errorMessage = "Failed to update permissions: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func removeFriend() {
        isLoading = true
        
        Task {
            let success = await appState.removeFriend(friendId: friend.friendId)
            
            await MainActor.run {
                isLoading = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        FriendsView()
            .environmentObject(AppState())
    }
}