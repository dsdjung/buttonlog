import SwiftUI

struct CreateButtonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var formData = ButtonFormData()
    @State private var isLoading = false

    let buttonColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5AC8FA", "#AF52DE",
        "#FF2D92", "#8E8E93", "#000000", "#6D6D6D"
    ]

    let buttonIcons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "snowflake", "car.fill", "airplane",
        "gamecontroller.fill", "book.fill", "pencil", "scissors",
        "wrench.fill", "hammer.fill", "gear", "house.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Button name", text: $formData.name)
                    TextField("Description", text: $formData.description)
                }

                Section(header: Text("Button Type")) {
                    Picker("Type", selection: $formData.type) {
                        ForEach(ButtonType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: formData.type) { oldValue, newValue in
                        if newValue == .oneTime && formData.choices.isEmpty {
                            formData.choices = [IdentifiedChoice(), IdentifiedChoice()]
                        }
                    }
                }

                // Choices Section (only for one-time buttons)
                if formData.type == .oneTime {
                    ChoicesSection(choices: $formData.choices)
                }

                Section(header: Text("Appearance")) {
                    // Icon Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(buttonIcons, id: \.self) { icon in
                            SwiftUI.Button(action: {
                                formData.icon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(formData.icon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(formData.icon == icon ? Color(hex: formData.color) : Color(.systemGray5))
                                    )
                            }
                        }
                    }

                    // Color Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(buttonColors, id: \.self) { color in
                            SwiftUI.Button(action: {
                                formData.color = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .opacity(formData.color == color ? 1 : 0)
                                    )
                            }
                        }
                    }
                }

                Section(header: Text("Settings")) {
                    Toggle("Enable Alerts", isOn: $formData.alertsEnabled)

                    if formData.type == .toggle {
                        Toggle("Auto-stop", isOn: $formData.autoStopEnabled)
                    }

                    Toggle("Calendar Sync", isOn: $formData.calendarSyncEnabled)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ButtonPreview(formData: formData)
                    }
                }
            }
            .navigationTitle("Create Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Create") {
                        createButton()
                    }
                    .disabled(!formData.isValid || isLoading)
                }
            }
        }
    }

    private func createButton() {
        isLoading = true
        Task {
            let success = await appState.createButton(formData)
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

struct ButtonPreview: View {
    let formData: ButtonFormData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: formData.color))
                        .frame(width: 44, height: 44)

                    Image(systemName: formData.icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(formData.name.isEmpty ? "Button Name" : formData.name)
                        .font(.headline)

                    if !formData.description.isEmpty {
                        Text(formData.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text(formData.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }

            // Show choice buttons if valid choices exist, otherwise show single button
            if formData.type == .oneTime && formData.hasValidChoices {
                VStack(spacing: 8) {
                    Text("Select an option:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(formData.choiceStrings.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { choice in
                            SwiftUI.Button(choice) {
                                // Preview button - no action
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: formData.color))
                            )
                            .disabled(true)
                        }
                    }
                }
            } else {
                SwiftUI.Button("Click!") {
                    // Preview button - no action
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: formData.color))
                )
                .disabled(true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct EditButtonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState

    let button: ButtonModel
    @State private var formData = ButtonFormData()
    @State private var isLoading = false
    @State private var sharingSettings: [ButtonSharingSetting] = []
    @State private var isLoadingSharing = true
    @State private var sharingError: String?

    let buttonColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5AC8FA", "#AF52DE",
        "#FF2D92", "#8E8E93", "#000000", "#6D6D6D"
    ]

    let buttonIcons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "snowflake", "car.fill", "airplane",
        "gamecontroller.fill", "book.fill", "pencil", "scissors",
        "wrench.fill", "hammer.fill", "gear", "house.fill"
    ]

    var body: some View {
        // Use NavigationStack instead of NavigationView (iOS 16+)
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Button Name", text: $formData.name)

                    TextField("Description (optional)", text: $formData.description, axis: .vertical)
                        .lineLimit(3)
                }

                Section(header: Text("Appearance")) {
                    // Icon Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(buttonIcons, id: \.self) { icon in
                            SwiftUI.Button(action: {
                                formData.icon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(formData.icon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(formData.icon == icon ? Color(hex: formData.color) : Color(.systemGray5))
                                    )
                            }
                        }
                    }

                    // Color Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(buttonColors, id: \.self) { color in
                            SwiftUI.Button(action: {
                                formData.color = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .opacity(formData.color == color ? 1 : 0)
                                    )
                            }
                        }
                    }
                }

                Section(header: Text("Settings")) {
                    Toggle("Enable Alerts", isOn: $formData.alertsEnabled)

                    if formData.type == .toggle {
                        Toggle("Auto-stop", isOn: $formData.autoStopEnabled)
                    }

                    Toggle("Calendar Sync", isOn: $formData.calendarSyncEnabled)
                }

                // Friend Sharing Section
                Section(header: Text("Share with Friends")) {
                    if isLoadingSharing {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let error = sharingError {
                        Text(error)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if sharingSettings.isEmpty {
                        Text("No friends to share with")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach($sharingSettings) { $setting in
                            Toggle(isOn: $setting.isShared) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading) {
                                        Text(setting.friendDisplayName ?? setting.friendUsername)
                                            .font(.body)
                                        Text("@\(setting.friendUsername)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    SwiftUI.Button("Delete Button", role: .destructive) {
                        deleteButton()
                    }
                }
            }
            .navigationTitle("Edit Button")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Save") {
                        saveButton()
                    }
                    .disabled(!formData.isValid || isLoading)
                }
            }
        }
        .onAppear {
            populateForm()
            loadSharingSettings()
        }
        .disabled(isLoading)
    }

    private func populateForm() {
        formData.name = button.name
        formData.description = button.description ?? ""
        formData.type = button.type
        formData.icon = button.icon
        formData.color = button.color
        formData.alertsEnabled = button.alertsEnabled
        formData.autoStopEnabled = button.autoStopEnabled
        formData.calendarSyncEnabled = button.calendarSyncEnabled
    }

    private func loadSharingSettings() {
        isLoadingSharing = true
        sharingError = nil

        Task {
            do {
                let settings = try await APIService.shared.getButtonSharing(buttonId: button.id)
                await MainActor.run {
                    sharingSettings = settings
                    isLoadingSharing = false
                }
            } catch {
                await MainActor.run {
                    sharingError = "Failed to load sharing settings"
                    isLoadingSharing = false
                }
            }
        }
    }

    private func saveButton() {
        isLoading = true

        Task {
            // Save button updates
            let buttonSuccess = await appState.updateButton(id: button.id, formData: formData)

            // Save sharing settings if they've been loaded
            var sharingSuccess = true
            if !sharingSettings.isEmpty {
                do {
                    _ = try await APIService.shared.updateButtonSharing(buttonId: button.id, settings: sharingSettings)
                } catch {
                    sharingSuccess = false
                    print("Failed to save sharing settings: \(error)")
                }
            }

            await MainActor.run {
                isLoading = false
                if buttonSuccess && sharingSuccess {
                    dismiss()
                }
            }
        }
    }

    private func deleteButton() {
        isLoading = true

        Task {
            let success = await appState.deleteButton(id: button.id)

            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

struct CreateGiftButtonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState

    let friend: Friend

    @State private var formData = ButtonFormData(type: .oneTime)
    @State private var giftMessage: String = ""
    @State private var isLoading = false

    let buttonColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5AC8FA", "#AF52DE",
        "#FF2D92", "#8E8E93", "#000000", "#6D6D6D"
    ]

    let buttonIcons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "snowflake", "car.fill", "airplane",
        "gamecontroller.fill", "book.fill", "pencil", "scissors",
        "wrench.fill", "hammer.fill", "gear", "house.fill"
    ]

    var body: some View {
        // Use NavigationStack instead of NavigationView (iOS 16+)
        NavigationStack {
            Form {
                Section(header: Text("Creating Button for \(friend.friendUser.displayNameOrUsername)")) {
                    Text("This button will appear in \(friend.friendUser.displayNameOrUsername)'s button list. You'll be notified when they use it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quick Templates Section
                Section(header: Text("Quick Templates")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            TemplateButton(
                                title: "Yes/No Question",
                                icon: "questionmark.circle.fill",
                                color: .purple
                            ) {
                                formData.type = .oneTime
                                formData.choices = [IdentifiedChoice(text: "Yes"), IdentifiedChoice(text: "No")]
                            }

                            TemplateButton(
                                title: "Done/Skip Task",
                                icon: "checkmark.circle.fill",
                                color: .green
                            ) {
                                formData.type = .oneTime
                                formData.choices = [IdentifiedChoice(text: "Done"), IdentifiedChoice(text: "Skip")]
                            }

                            TemplateButton(
                                title: "Rating",
                                icon: "star.fill",
                                color: .blue
                            ) {
                                formData.type = .oneTime
                                formData.choices = [IdentifiedChoice(text: "Good"), IdentifiedChoice(text: "Okay"), IdentifiedChoice(text: "Bad")]
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Or create a custom button below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Basic Information")) {
                    TextField("Button Name", text: $formData.name)

                    TextField("Description (optional)", text: $formData.description, axis: .vertical)
                        .lineLimit(3)
                }

                Section(header: Text("Button Type")) {
                    Picker("Type", selection: $formData.type) {
                        ForEach(ButtonType.allCases, id: \.self) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                    .font(.headline)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: formData.type) { oldValue, newValue in
                        // Initialize choices with 2 empty choices when switching to one-time
                        if newValue == .oneTime && formData.choices.isEmpty {
                            formData.choices = [IdentifiedChoice(), IdentifiedChoice()]
                        }
                    }
                }

                // Choices Section (only for one-time buttons)
                if formData.type == .oneTime {
                    ChoicesSection(choices: $formData.choices)
                }

                Section(header: Text("Appearance")) {
                    // Icon Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(buttonIcons, id: \.self) { icon in
                            SwiftUI.Button(action: {
                                formData.icon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(formData.icon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(formData.icon == icon ? Color(hex: formData.color) : Color(.systemGray5))
                                    )
                            }
                        }
                    }

                    // Color Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(buttonColors, id: \.self) { color in
                            SwiftUI.Button(action: {
                                formData.color = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .opacity(formData.color == color ? 1 : 0)
                                    )
                            }
                        }
                    }
                }

                Section(header: Text("Gift Message (Optional)")) {
                    TextField("Add a message for your friend", text: $giftMessage, axis: .vertical)
                        .lineLimit(3)
                }

                Section {
                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        GiftButtonPreview(formData: formData, friendName: friend.friendUser.displayNameOrUsername)
                    }
                }
            }
            .navigationTitle("Create Gift Button")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Create") {
                        createGiftButton()
                    }
                    .disabled(!formData.isValid || isLoading)
                }
            }
        }
        .disabled(isLoading)
    }

    private func createGiftButton() {
        isLoading = true

        Task {
            do {
                let _ = try await APIService.shared.createButtonForFriend(
                    friendId: friend.friendId,
                    formData: formData,
                    message: giftMessage.isEmpty ? nil : giftMessage
                )

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch let error as APIError {
                await MainActor.run {
                    if case .upgradeRequired(let info) = error {
                        appState.pendingUpgradeInfo = info
                    } else {
                        appState.errorMessage = "Failed to create button: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    appState.errorMessage = "Failed to create button: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct GiftButtonPreview: View {
    let formData: ButtonFormData
    let friendName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: formData.color))
                        .frame(width: 44, height: 44)

                    Image(systemName: formData.icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(formData.name.isEmpty ? "Button Name" : formData.name)
                        .font(.headline)

                    if !formData.description.isEmpty {
                        Text(formData.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text(formData.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)

                        // Gift badge
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.caption2)
                            Text("Gift for \(friendName)")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    }
                }

                Spacer()
            }

            // Show choice buttons if valid choices exist, otherwise show single button
            if formData.type == .oneTime && formData.hasValidChoices {
                VStack(spacing: 8) {
                    Text("Select an option:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(formData.choiceStrings.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { choice in
                            SwiftUI.Button(choice) {
                                // Preview button - no action
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: formData.color))
                            )
                            .disabled(true)
                        }
                    }
                }
            } else {
                SwiftUI.Button("Click!") {
                    // Preview button - no action
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: formData.color))
                )
                .disabled(true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// Extracted choices section to avoid ForEach binding issues
struct ChoicesSection: View {
    @Binding var choices: [IdentifiedChoice]

    var body: some View {
        Section(header: Text("Choices (Optional)"), footer: Text("Add multiple choice options for this button (minimum 2, maximum 10)")) {
            ForEach(choices) { choice in
                ChoiceRow(choice: choice, choices: $choices)
            }

            if choices.count < 10 {
                SwiftUI.Button(action: {
                    choices.append(IdentifiedChoice())
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Choice")
                    }
                }
            }
        }
    }
}

struct ChoiceRow: View {
    let choice: IdentifiedChoice
    @Binding var choices: [IdentifiedChoice]

    var body: some View {
        HStack {
            TextField("Choice", text: Binding(
                get: {
                    choices.first { $0.id == choice.id }?.text ?? ""
                },
                set: { newValue in
                    if let index = choices.firstIndex(where: { $0.id == choice.id }) {
                        choices[index].text = newValue
                    }
                }
            ))

            if choices.count > 2 {
                SwiftUI.Button(action: {
                    choices.removeAll { $0.id == choice.id }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Template button component for quick button creation
struct TemplateButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateButtonView()
        .environmentObject(AppState())
}
