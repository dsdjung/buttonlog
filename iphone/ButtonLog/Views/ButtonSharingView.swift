import SwiftUI

struct ButtonSharingView: View {
    let button: Button
    @Environment(\.dismiss) private var dismiss

    @State private var sharingMode: SharingMode
    @State private var collaborators: [ButtonCollaborator] = []
    @State private var friends: [Friend] = []
    @State private var shareToken: String?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showAddCollaborator = false
    @State private var showCopiedToast = false

    init(button: Button) {
        self.button = button
        _sharingMode = State(initialValue: button.sharingMode ?? .private)
        _shareToken = State(initialValue: button.shareToken)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Sharing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        SwiftUI.Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        SwiftUI.Button("Done") {
                            dismiss()
                        }
                        .disabled(isSaving)
                    }
                }
                .task {
                    await loadData()
                }
                .overlay {
                    if showCopiedToast {
                        VStack {
                            Spacer()
                            Text("Link copied!")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.bottom, 50)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: showCopiedToast)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading...")
        } else {
            Form {
                sharingModeSection

                if sharingMode == .inviteOnly {
                    collaboratorsSection
                }

                if sharingMode == .public {
                    shareLinkSection
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    private var sharingModeSection: some View {
        Section {
            ForEach(SharingMode.allCases, id: \.self) { mode in
                SwiftUI.Button {
                    Task { await updateSharingMode(mode) }
                } label: {
                    HStack {
                        Image(systemName: mode.systemIcon)
                            .foregroundColor(sharingMode == mode ? .blue : .gray)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .foregroundColor(.primary)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if sharingMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .disabled(isSaving)
            }
        } header: {
            Text("Who can click this button?")
        }
    }

    private var collaboratorsSection: some View {
        Section {
            if collaborators.isEmpty {
                Text("No collaborators added yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(collaborators) { collaborator in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(collaborator.displayName)
                                .font(.body)
                        }

                        Spacer()

                        SwiftUI.Button {
                            Task { await removeCollaborator(collaborator) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            SwiftUI.Button {
                showAddCollaborator = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Collaborator")
                }
            }
            .sheet(isPresented: $showAddCollaborator) {
                AddCollaboratorView(
                    friends: friends,
                    existingCollaboratorIds: Set(collaborators.map { $0.userId }),
                    onSelect: { friend in
                        Task { await addCollaborator(friend) }
                    }
                )
            }
        } header: {
            Text("Collaborators")
        } footer: {
            Text("Collaborators can click this button. Only your friends can be added.")
        }
    }

    private var shareLinkSection: some View {
        Section {
            if let token = shareToken {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text("Share link active")
                            .font(.headline)
                    }

                    Text(shareURL(for: token))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        SwiftUI.Button {
                            copyShareLink(token)
                        } label: {
                            Label("Copy Link", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        SwiftUI.Button(role: .destructive) {
                            Task { await revokeShareLink() }
                        } label: {
                            Label("Revoke", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.vertical, 4)
            } else {
                SwiftUI.Button {
                    Task { await generateShareLink() }
                } label: {
                    HStack {
                        Image(systemName: "link.badge.plus")
                        Text("Generate Share Link")
                    }
                }
                .disabled(isSaving)
            }
        } header: {
            Text("Public Link")
        } footer: {
            Text("Anyone with the link can click this button, even if they don't have an account.")
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let collaboratorsTask = APIService.shared.getCollaborators(buttonId: button.id)
            async let friendsTask = APIService.shared.getFriends()

            collaborators = try await collaboratorsTask
            friends = try await friendsTask.filter { $0.status == .accepted }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Actions

    private func updateSharingMode(_ mode: SharingMode) async {
        guard mode != sharingMode else { return }

        isSaving = true
        errorMessage = nil

        do {
            let updatedButton = try await APIService.shared.updateSharingMode(buttonId: button.id, mode: mode)
            sharingMode = updatedButton.sharingMode ?? .private
            shareToken = updatedButton.shareToken
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func addCollaborator(_ friend: Friend) async {
        isSaving = true
        errorMessage = nil

        do {
            let collaborator = try await APIService.shared.addCollaborator(buttonId: button.id, userId: friend.friendId)
            collaborators.append(collaborator)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func removeCollaborator(_ collaborator: ButtonCollaborator) async {
        isSaving = true
        errorMessage = nil

        do {
            try await APIService.shared.removeCollaborator(buttonId: button.id, userId: collaborator.userId)
            collaborators.removeAll { $0.id == collaborator.id }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func generateShareLink() async {
        isSaving = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.generateShareLink(buttonId: button.id)
            shareToken = response.shareToken
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func revokeShareLink() async {
        isSaving = true
        errorMessage = nil

        do {
            let updatedButton = try await APIService.shared.revokeShareLink(buttonId: button.id)
            shareToken = updatedButton.shareToken
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func copyShareLink(_ token: String) {
        UIPasteboard.general.string = shareURL(for: token)
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }

    private func shareURL(for token: String) -> String {
        // This would be your app's deep link or web URL
        return "https://buttonlog.app/join/\(token)"
    }
}

// MARK: - Add Collaborator View

struct AddCollaboratorView: View {
    let friends: [Friend]
    let existingCollaboratorIds: Set<String>
    let onSelect: (Friend) -> Void
    @Environment(\.dismiss) private var dismiss

    var availableFriends: [Friend] {
        friends.filter { !existingCollaboratorIds.contains($0.friendId) }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableFriends.isEmpty {
                    Text("No friends available to add")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(availableFriends) { friend in
                        SwiftUI.Button {
                            onSelect(friend)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(friend.friendUser.displayName ?? friend.friendUser.username ?? "User")
                                        .foregroundColor(.primary)
                                    if friend.friendUser.displayName != nil, let username = friend.friendUser.username {
                                        Text("@\(username)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Collaborator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ButtonSharingView(button: Button(
        id: "test-id",
        name: "Test Button",
        description: nil,
        type: .instant,
        icon: "star.fill",
        color: "#007AFF",
        isActive: true,
        currentState: .idle,
        stateChangedAt: nil,
        notificationsEnabled: true,
        autoStopEnabled: false,
        calendarSyncEnabled: false,
        userId: "user-id",
        createdAt: Date(),
        updatedAt: Date()
    ))
}
