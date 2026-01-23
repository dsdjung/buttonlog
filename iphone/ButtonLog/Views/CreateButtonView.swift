import SwiftUI

struct CreateButtonView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    
    @State private var formData = ButtonFormData()
    @State private var isLoading = false
    @State private var showingColorPicker = false
    
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
        NavigationView {
            Form {
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
                    .onChange(of: formData.type) { newType in
                        // Initialize choices with 2 empty strings when switching to one-time
                        if newType == .oneTime && formData.choices.isEmpty {
                            formData.choices = ["", ""]
                        }
                    }
                }

                // Choices Section (only for one-time buttons)
                if formData.type == .oneTime {
                    Section(header: Text("Choices (Optional)"), footer: Text("Add multiple choice options for this button (minimum 2, maximum 10)")) {
                        ForEach(formData.choices.indices, id: \.self) { index in
                            HStack {
                                TextField("Choice \(index + 1)", text: $formData.choices[index])

                                if formData.choices.count > 2 {
                                    SwiftUI.Button(action: {
                                        formData.choices.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if formData.choices.count < 10 {
                            SwiftUI.Button(action: {
                                formData.choices.append("")
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
                    // Preview
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
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
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
        .disabled(isLoading)
    }
    
    private func createButton() {
        isLoading = true
        
        Task {
            let success = await appState.createButton(formData)
            
            await MainActor.run {
                isLoading = false
                if success {
                    presentationMode.wrappedValue.dismiss()
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
                        ForEach(formData.choices.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { choice in
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
    @Environment(\.presentationMode) var presentationMode
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
        NavigationView {
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
                        presentationMode.wrappedValue.dismiss()
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
                    presentationMode.wrappedValue.dismiss()
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
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct CreateGiftButtonView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState

    let friend: Friend

    @State private var formData: ButtonFormData = {
        var data = ButtonFormData(type: .oneTime)
        data.choices = ["", ""]  // Initialize with 2 empty choices for one-time buttons
        return data
    }()
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
        NavigationView {
            Form {
                Section(header: Text("Creating Button for \(friend.friendUser.displayNameOrUsername)")) {
                    Text("This button will appear in \(friend.friendUser.displayNameOrUsername)'s button list. You'll be notified when they use it.")
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
                    .onChange(of: formData.type) { newType in
                        // Initialize choices with 2 empty strings when switching to one-time
                        if newType == .oneTime && formData.choices.isEmpty {
                            formData.choices = ["", ""]
                        }
                    }
                }

                // Choices Section (only for one-time buttons)
                if formData.type == .oneTime {
                    Section(header: Text("Choices (Optional)"), footer: Text("Add multiple choice options for this button (minimum 2, maximum 10)")) {
                        ForEach(formData.choices.indices, id: \.self) { index in
                            HStack {
                                TextField("Choice \(index + 1)", text: $formData.choices[index])

                                if formData.choices.count > 2 {
                                    SwiftUI.Button(action: {
                                        formData.choices.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if formData.choices.count < 10 {
                            SwiftUI.Button(action: {
                                formData.choices.append("")
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
                        presentationMode.wrappedValue.dismiss()
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
                    presentationMode.wrappedValue.dismiss()
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
                        ForEach(formData.choices.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { choice in
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

#Preview {
    CreateButtonView()
        .environmentObject(AppState())
}
