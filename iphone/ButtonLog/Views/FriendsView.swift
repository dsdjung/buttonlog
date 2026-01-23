import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAddFriend = false
    @State private var selectedFriend: Friend?
    @State private var showingCreatedGiftButtons = false

    var body: some View {
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
                                await appState.acceptFriendRequest(friendId: friend.friendId)
                            }
                        }
                    }
                }
            }
            
            // Friends Section
            Section("Friends") {
                if appState.friends.filter({ $0.status == .accepted }).isEmpty {
                    Text("No friends yet")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(appState.friends.filter { $0.status == .accepted }) { friend in
                        FriendRow(friend: friend) {
                            selectedFriend = friend
                        }
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button("Add Friend") {
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
    
    @State private var friendRequest = FriendRequest()
    @State private var isLoading = false
    @State private var searchBy: SearchBy = .email
    
    enum SearchBy: String, CaseIterable {
        case email = "Email"
        case username = "Username"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Find Friend")) {
                    Picker("Search by", selection: $searchBy) {
                        ForEach(SearchBy.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if searchBy == .email {
                        TextField("Enter email address", text: $friendRequest.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } else {
                        TextField("Enter username", text: $friendRequest.username)
                            .autocapitalization(.none)
                    }
                }
                
                Section(header: Text("Message (Optional)")) {
                    TextField("Add a personal message", text: $friendRequest.message, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Send Request") {
                        sendFriendRequest()
                    }
                    .disabled(!friendRequest.isValid || isLoading)
                }
            }
        }
        .disabled(isLoading)
    }
    
    private func sendFriendRequest() {
        isLoading = true
        
        Task {
            let success = await appState.sendFriendRequest(friendRequest)
            
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