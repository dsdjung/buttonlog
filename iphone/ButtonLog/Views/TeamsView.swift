import SwiftUI

struct TeamsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var teams: [Team] = []
    @State private var pendingInvitations: [TeamInvitation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateTeam = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading teams...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    SwiftUI.Button("Retry") {
                        Task {
                            await loadTeams()
                        }
                    }
                }
            } else {
                teamsList
            }
        }
        .navigationTitle("Teams")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button {
                    showingCreateTeam = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateTeam) {
            CreateTeamView { newTeam in
                teams.insert(newTeam, at: 0)
            }
        }
        .refreshable {
            await loadTeams()
        }
        .task {
            await loadTeams()
        }
    }

    private var teamsList: some View {
        List {
            // Pending Invitations Section
            if !pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(pendingInvitations) { invitation in
                        TeamInvitationRow(invitation: invitation) {
                            await handleInvitationResponse(invitation, accept: true)
                        } onDecline: {
                            await handleInvitationResponse(invitation, accept: false)
                        }
                    }
                }
            }

            // My Teams Section
            Section("My Teams") {
                if teams.isEmpty {
                    ContentUnavailableView {
                        Label("No Teams", systemImage: "person.3")
                    } description: {
                        Text("Create a team to collaborate with others")
                    } actions: {
                        SwiftUI.Button("Create Team") {
                            showingCreateTeam = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(teams) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRow(team: team)
                        }
                    }
                }
            }
        }
    }

    private func loadTeams() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.getTeams()
            teams = response.teams
            pendingInvitations = response.pendingInvitations
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleInvitationResponse(_ invitation: TeamInvitation, accept: Bool) async {
        do {
            if accept {
                let team = try await APIService.shared.acceptTeamInvitation(invitationId: invitation.id)
                teams.insert(team, at: 0)
            } else {
                try await APIService.shared.declineTeamInvitation(invitationId: invitation.id)
            }
            pendingInvitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Team Row

struct TeamRow: View {
    let team: Team

    var body: some View {
        HStack(spacing: 12) {
            // Team Icon
            Circle()
                .fill(Color(hex: team.color))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(teamIcon)
                        .font(.title2)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(team.name)
                        .font(.headline)

                    if let role = team.myRole {
                        Text(role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(roleColor(role).opacity(0.2))
                            .foregroundColor(roleColor(role))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    if let memberCount = team.memberCount {
                        Label("\(memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let buttonCount = team.buttonCount {
                        Label("\(buttonCount)", systemImage: "square.grid.2x2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var teamIcon: String {
        switch team.icon {
        case "people": return "👥"
        case "star": return "⭐"
        case "heart": return "❤️"
        case "bolt": return "⚡"
        case "flame": return "🔥"
        case "briefcase": return "💼"
        case "code": return "💻"
        default: return "👥"
        }
    }

    private func roleColor(_ role: TeamRole) -> Color {
        switch role {
        case .owner: return .purple
        case .admin: return .blue
        case .member: return .gray
        }
    }
}

// MARK: - Team Invitation Row

struct TeamInvitationRow: View {
    let invitation: TeamInvitation
    let onAccept: () async -> Void
    let onDecline: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let team = invitation.team {
                Text(team.name)
                    .font(.headline)
            }

            if let inviter = invitation.inviter {
                Text("Invited by \(inviter.displayNameOrUsername)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Role: \(invitation.role.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                SwiftUI.Button {
                    Task {
                        isProcessing = true
                        await onAccept()
                        isProcessing = false
                    }
                } label: {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)

                SwiftUI.Button(role: .destructive) {
                    Task {
                        isProcessing = true
                        await onDecline()
                        isProcessing = false
                    }
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Team View

struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var request = CreateTeamRequest()
    @State private var isCreating = false
    @State private var errorMessage: String?

    let onCreate: (Team) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Team Details") {
                    TextField("Team Name", text: $request.name)

                    TextField("Description (optional)", text: $request.description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Appearance") {
                    Picker("Icon", selection: $request.icon) {
                        Text("👥 People").tag("people")
                        Text("⭐ Star").tag("star")
                        Text("❤️ Heart").tag("heart")
                        Text("⚡ Bolt").tag("bolt")
                        Text("🔥 Flame").tag("flame")
                        Text("💼 Briefcase").tag("briefcase")
                        Text("💻 Code").tag("code")
                    }

                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: request.color) },
                        set: { request.color = $0.hexString }
                    ))
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    SwiftUI.Button("Create") {
                        Task {
                            await createTeam()
                        }
                    }
                    .disabled(!request.isValid || isCreating)
                }
            }
        }
    }

    private func createTeam() async {
        isCreating = true
        errorMessage = nil

        do {
            let team = try await APIService.shared.createTeam(request)
            onCreate(team)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

// MARK: - Team Detail View

struct TeamDetailView: View {
    let team: Team

    @State private var teamDetail: Team?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingInviteMember = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading team...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if let detail = teamDetail {
                teamDetailContent(detail)
            }
        }
        .navigationTitle(team.name)
        .toolbar {
            if teamDetail?.canManage == true {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        SwiftUI.Button {
                            showingInviteMember = true
                        } label: {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }

                        SwiftUI.Button {
                            // TODO: Add button to team
                        } label: {
                            Label("Add Button", systemImage: "plus.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteMember) {
            InviteTeamMemberView(teamId: team.id)
        }
        .task {
            await loadTeamDetail()
        }
    }

    private func teamDetailContent(_ team: Team) -> some View {
        List {
            // Team Info Section
            Section {
                HStack {
                    Circle()
                        .fill(Color(hex: team.color))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(teamIcon(team.icon))
                                .font(.title)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = team.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Members Section
            Section("Members (\(team.members?.count ?? 0))") {
                if let members = team.members {
                    ForEach(members) { member in
                        TeamMemberRow(member: member)
                    }
                }
            }

            // Buttons Section
            Section("Shared Buttons (\(team.buttons?.count ?? 0))") {
                if let buttons = team.buttons, !buttons.isEmpty {
                    ForEach(buttons) { teamButton in
                        if let button = teamButton.button {
                            TeamButtonRow(teamButton: teamButton, button: button)
                        }
                    }
                } else {
                    Text("No buttons shared with this team yet")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func teamIcon(_ icon: String) -> String {
        switch icon {
        case "people": return "👥"
        case "star": return "⭐"
        case "heart": return "❤️"
        case "bolt": return "⚡"
        case "flame": return "🔥"
        case "briefcase": return "💼"
        case "code": return "💻"
        default: return "👥"
        }
    }

    private func loadTeamDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            teamDetail = try await APIService.shared.getTeam(id: team.id)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Team Member Row

struct TeamMemberRow: View {
    let member: TeamMember

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Text((member.user?.displayNameOrUsername ?? "?").prefix(1).uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(member.user?.displayNameOrUsername ?? "Unknown")
                    .font(.subheadline)

                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Team Button Row

struct TeamButtonRow: View {
    let teamButton: TeamButton
    let button: TeamButtonInfo

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: button.color))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(buttonIcon)
                        .font(.subheadline)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(button.name)
                    .font(.subheadline)

                Text(teamButton.permission.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var buttonIcon: String {
        switch button.icon {
        case "star": return "⭐"
        case "heart": return "❤️"
        case "bolt": return "⚡"
        case "flame": return "🔥"
        default: return "📱"
        }
    }
}

// MARK: - Invite Team Member View

struct InviteTeamMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let teamId: String

    @State private var username = ""
    @State private var selectedRole: TeamRole = .member
    @State private var isInviting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Find User") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach([TeamRole.member, TeamRole.admin], id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    SwiftUI.Button("Invite") {
                        Task {
                            await inviteMember()
                        }
                    }
                    .disabled(username.isEmpty || isInviting)
                }
            }
        }
    }

    private func inviteMember() async {
        isInviting = true
        errorMessage = nil

        do {
            try await APIService.shared.inviteTeamMember(teamId: teamId, username: username, role: selectedRole.rawValue)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isInviting = false
    }
}

// MARK: - API Response Types

struct TeamsResponse: Codable {
    let teams: [Team]
    let pendingInvitations: [TeamInvitation]

    enum CodingKeys: String, CodingKey {
        case teams
        case pendingInvitations = "pending_invitations"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TeamsView()
            .environmentObject(AppState())
    }
}
