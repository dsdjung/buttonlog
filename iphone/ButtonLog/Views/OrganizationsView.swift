import SwiftUI

struct OrganizationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var organizations: [Organization] = []
    @State private var pendingInvitations: [OrganizationInvitation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateOrganization = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading organizations...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    SwiftUI.Button("Retry") {
                        Task {
                            await loadOrganizations()
                        }
                    }
                }
            } else {
                organizationsList
            }
        }
        .navigationTitle("Organizations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button {
                    showingCreateOrganization = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateOrganization) {
            CreateOrganizationView { newOrg in
                organizations.insert(newOrg, at: 0)
            }
        }
        .refreshable {
            await loadOrganizations()
        }
        .task {
            await loadOrganizations()
        }
    }

    private var organizationsList: some View {
        List {
            // Pending Invitations Section
            if !pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(pendingInvitations) { invitation in
                        OrganizationInvitationRow(invitation: invitation) {
                            await handleInvitationResponse(invitation, accept: true)
                        } onDecline: {
                            await handleInvitationResponse(invitation, accept: false)
                        }
                    }
                }
            }

            // My Organizations Section
            Section("My Organizations") {
                if organizations.isEmpty {
                    ContentUnavailableView {
                        Label("No Organizations", systemImage: "building.2")
                    } description: {
                        Text("Create an organization for enterprise features")
                    } actions: {
                        SwiftUI.Button("Create Organization") {
                            showingCreateOrganization = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(organizations) { org in
                        NavigationLink(destination: OrganizationDetailView(organization: org)) {
                            OrganizationRow(organization: org)
                        }
                    }
                }
            }
        }
    }

    private func loadOrganizations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.getOrganizations()
            organizations = response.organizations
            pendingInvitations = response.pendingInvitations
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleInvitationResponse(_ invitation: OrganizationInvitation, accept: Bool) async {
        do {
            if accept {
                let org = try await APIService.shared.acceptOrganizationInvitation(invitationId: invitation.id)
                organizations.insert(org, at: 0)
            } else {
                try await APIService.shared.declineOrganizationInvitation(invitationId: invitation.id)
            }
            pendingInvitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Organization Row

struct OrganizationRow: View {
    let organization: Organization

    var body: some View {
        HStack(spacing: 12) {
            // Organization Logo/Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.indigo.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(organization.name.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(organization.name)
                        .font(.headline)

                    if let role = organization.myRole {
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
                    if let memberCount = organization.memberCount {
                        Label("\(memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let teamCount = organization.teamCount {
                        Label("\(teamCount)", systemImage: "person.3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(organization.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func roleColor(_ role: OrganizationRole) -> Color {
        switch role {
        case .owner: return .purple
        case .admin: return .blue
        case .billingAdmin: return .green
        case .member: return .gray
        }
    }

    private var statusColor: Color {
        switch organization.status {
        case .active: return .green
        case .suspended: return .orange
        case .cancelled: return .red
        }
    }
}

// MARK: - Organization Invitation Row

struct OrganizationInvitationRow: View {
    let invitation: OrganizationInvitation
    let onAccept: () async -> Void
    let onDecline: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let org = invitation.organization {
                Text(org.name)
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

// MARK: - Create Organization View

struct CreateOrganizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var request = CreateOrganizationRequest()
    @State private var isCreating = false
    @State private var errorMessage: String?

    let onCreate: (Organization) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Organization Details") {
                    TextField("Organization Name", text: $request.name)

                    TextField("Slug (optional)", text: $request.slug)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if request.slug.isEmpty && !request.name.isEmpty {
                        Text("Will use: \(request.generatedSlug)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextField("Description (optional)", text: $request.description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Enterprise Settings") {
                    TextField("Company Domain (optional)", text: $request.domain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("Billing Email (optional)", text: $request.billingEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Organization")
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
                            await createOrganization()
                        }
                    }
                    .disabled(!request.isValid || isCreating)
                }
            }
        }
    }

    private func createOrganization() async {
        isCreating = true
        errorMessage = nil

        do {
            let org = try await APIService.shared.createOrganization(request)
            onCreate(org)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

// MARK: - Organization Detail View

struct OrganizationDetailView: View {
    let organization: Organization

    @Environment(\.dismiss) private var dismiss
    @State private var orgDetail: Organization?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingInviteMember = false
    @State private var showingLeaveConfirmation = false
    @State private var isLeaving = false

    private var isOwner: Bool {
        orgDetail?.myRole == .owner
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading organization...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if let detail = orgDetail {
                organizationDetailContent(detail)
            }
        }
        .navigationTitle(organization.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if orgDetail?.canManage == true {
                        SwiftUI.Button {
                            showingInviteMember = true
                        } label: {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }

                        SwiftUI.Button {
                            // TODO: Create team
                        } label: {
                            Label("Create Team", systemImage: "person.3.fill")
                        }

                        Divider()
                    }

                    if !isOwner {
                        SwiftUI.Button(role: .destructive) {
                            showingLeaveConfirmation = true
                        } label: {
                            Label("Leave Organization", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingInviteMember) {
            InviteOrganizationMemberView(organizationId: organization.id)
        }
        .alert("Leave Organization?", isPresented: $showingLeaveConfirmation) {
            SwiftUI.Button("Cancel", role: .cancel) { }
            SwiftUI.Button("Leave", role: .destructive) {
                Task {
                    await leaveOrganization()
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(organization.name)\"? You will need to be invited again to rejoin.")
        }
        .task {
            await loadOrganizationDetail()
        }
    }

    private func leaveOrganization() async {
        isLeaving = true
        do {
            try await APIService.shared.leaveOrganization(organizationId: organization.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLeaving = false
    }

    private func organizationDetailContent(_ org: Organization) -> some View {
        List {
            // Organization Info Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.indigo.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(org.name.prefix(1).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(org.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(org.slug)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let description = org.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let domain = org.domain {
                        Label(domain, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Subscription Section
            if let subscription = org.subscription {
                Section("Subscription") {
                    HStack {
                        Text("Plan")
                        Spacer()
                        Text(subscription.billingCycle.displayName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Seats")
                        Spacer()
                        Text("\(subscription.seatsUsed) / \(subscription.seatsPurchased)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscription.status.displayName)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(subscriptionStatusColor(subscription.status).opacity(0.2))
                            .foregroundColor(subscriptionStatusColor(subscription.status))
                            .cornerRadius(4)
                    }
                }
            }

            // Members Section
            Section("Members (\(org.members?.count ?? 0))") {
                if let members = org.members {
                    ForEach(members) { member in
                        OrganizationMemberRow(member: member)
                    }
                }
            }

            // Teams Section
            Section("Teams (\(org.teams?.count ?? 0))") {
                if let teams = org.teams, !teams.isEmpty {
                    ForEach(teams) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRow(team: team)
                        }
                    }
                } else {
                    Text("No teams in this organization yet")
                        .foregroundColor(.secondary)
                }
            }

            // Enterprise Features Section
            if org.ssoEnabled || org.domain != nil {
                Section("Enterprise Features") {
                    if org.ssoEnabled {
                        HStack {
                            Label("SSO Enabled", systemImage: "lock.shield")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    if org.requireSso {
                        HStack {
                            Label("SSO Required", systemImage: "exclamationmark.lock")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }

    private func subscriptionStatusColor(_ status: OrganizationSubscriptionStatus) -> Color {
        switch status {
        case .active: return .green
        case .pastDue: return .orange
        case .cancelled: return .red
        case .trialing: return .blue
        }
    }

    private func loadOrganizationDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            orgDetail = try await APIService.shared.getOrganization(id: organization.id)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Organization Member Row

struct OrganizationMemberRow: View {
    let member: OrganizationMember

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.indigo.gradient)
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
                    .foregroundColor(roleColor)
            }
        }
    }

    private var roleColor: Color {
        switch member.role {
        case .owner: return .purple
        case .admin: return .blue
        case .billingAdmin: return .green
        case .member: return .secondary
        }
    }
}

// MARK: - Invite Organization Member View

struct InviteOrganizationMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let organizationId: String

    @State private var username = ""
    @State private var email = ""
    @State private var selectedRole: OrganizationRole = .member
    @State private var isInviting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Find User") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Or Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach([OrganizationRole.member, OrganizationRole.admin, OrganizationRole.billingAdmin], id: \.self) { role in
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
                    .disabled((username.isEmpty && email.isEmpty) || isInviting)
                }
            }
        }
    }

    private func inviteMember() async {
        isInviting = true
        errorMessage = nil

        do {
            try await APIService.shared.inviteOrganizationMember(
                organizationId: organizationId,
                username: username.isEmpty ? nil : username,
                email: email.isEmpty ? nil : email,
                role: selectedRole.rawValue
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isInviting = false
    }
}

// MARK: - API Response Types

struct OrganizationsResponse: Codable {
    let organizations: [Organization]
    let pendingInvitations: [OrganizationInvitation]

    enum CodingKeys: String, CodingKey {
        case organizations
        case pendingInvitations = "pending_invitations"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        OrganizationsView()
            .environmentObject(AppState())
    }
}
