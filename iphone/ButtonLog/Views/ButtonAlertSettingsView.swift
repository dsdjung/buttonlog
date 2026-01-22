import SwiftUI

struct ButtonAlertSettingsView: View {
    let button: ButtonModel
    @State private var alertPreferences: [ButtonAlertPreference] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if alertPreferences.isEmpty {
                    emptyStateView
                } else {
                    alertPreferencesList
                }
            }
            .navigationTitle("Alert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Done") {
                        dismiss()
                    }
                }

                if !alertPreferences.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            SwiftUI.Button {
                                selectAll()
                            } label: {
                                Label("Select All", systemImage: "checkmark.circle.fill")
                            }

                            SwiftUI.Button {
                                deselectAll()
                            } label: {
                                Label("Deselect All", systemImage: "circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                SwiftUI.Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .task {
                await loadAlertPreferences()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Friends")
                .font(.headline)

            Text("Add friends to configure who receives alerts when you click this button.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var alertPreferencesList: some View {
        List {
            Section {
                ForEach($alertPreferences) { $preference in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preference.displayName)
                                .font(.headline)

                            Text("@\(preference.friendUsername)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $preference.enabled)
                            .labelsHidden()
                            .onChange(of: preference.enabled) { _, newValue in
                                togglePreference(for: preference.friendId, enabled: newValue)
                            }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Friends to Alert")
            } footer: {
                Text("Selected friends will receive a notification when you click the \"\(button.name)\" button.")
            }

            Section {
                HStack {
                    Text("Enabled Friends")
                    Spacer()
                    Text("\(alertPreferences.filter { $0.enabled }.count)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Total Friends")
                    Spacer()
                    Text("\(alertPreferences.count)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Summary")
            }
        }
    }

    private func loadAlertPreferences() async {
        isLoading = true
        do {
            alertPreferences = try await APIService.shared.getButtonAlertPreferences(buttonId: button.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func togglePreference(for friendId: String, enabled: Bool) {
        Task {
            do {
                let _ = try await APIService.shared.setButtonAlertPreference(
                    buttonId: button.id,
                    friendId: friendId,
                    enabled: enabled
                )
            } catch {
                // Revert the toggle on error
                if let index = alertPreferences.firstIndex(where: { $0.friendId == friendId }) {
                    alertPreferences[index].enabled = !enabled
                }
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func selectAll() {
        Task {
            do {
                try await APIService.shared.selectAllButtonAlerts(buttonId: button.id)
                // Update local state
                for index in alertPreferences.indices {
                    alertPreferences[index].enabled = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func deselectAll() {
        Task {
            do {
                try await APIService.shared.deselectAllButtonAlerts(buttonId: button.id)
                // Update local state
                for index in alertPreferences.indices {
                    alertPreferences[index].enabled = false
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    ButtonAlertSettingsView(button: ButtonModel(
        id: "1",
        name: "Test Button",
        description: nil,
        type: .instant,
        icon: "star",
        color: "#007AFF",
        isActive: true,
        currentState: .idle,
        stateChangedAt: nil,
        alertsEnabled: true,
        autoStopEnabled: false,
        calendarSyncEnabled: false,
        userId: "user1",
        createdAt: Date(),
        updatedAt: Date()
    ))
}
