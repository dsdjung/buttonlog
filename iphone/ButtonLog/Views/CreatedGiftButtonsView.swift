import SwiftUI

/// View showing all gift buttons the current user has created for their friends
struct CreatedGiftButtonsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var buttonToEdit: CreatedGiftButton?
    @State private var buttonToDelete: CreatedGiftButton?

    var body: some View {
        Group {
            if appState.isLoadingCreatedGiftButtons && appState.createdGiftButtons.isEmpty {
                VStack(spacing: BLSpacing.md) {
                    ProgressView()
                        .tint(.blPrimary)
                    Text("Loading gift buttons...")
                        .font(BLTypography.bodyMedium)
                        .foregroundColor(.blTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.createdGiftButtons.isEmpty {
                EmptyGiftButtonsView()
            } else {
                List {
                    ForEach(appState.createdGiftButtons) { button in
                        CreatedGiftButtonRow(
                            button: button,
                            onEdit: { buttonToEdit = button },
                            onDelete: { buttonToDelete = button }
                        )
                    }
                }
            }
        }
        .navigationTitle("Gift Buttons")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await appState.loadCreatedGiftButtons()
        }
        .onAppear {
            Task {
                await appState.loadCreatedGiftButtons()
            }
        }
        .sheet(item: $buttonToEdit) { button in
            EditGiftButtonView(button: button)
        }
        .alert("Delete Gift Button", isPresented: .init(
            get: { buttonToDelete != nil },
            set: { if !$0 { buttonToDelete = nil } }
        )) {
            SwiftUI.Button("Cancel", role: .cancel) {
                buttonToDelete = nil
            }
            SwiftUI.Button("Delete", role: .destructive) {
                if let button = buttonToDelete {
                    Task {
                        _ = await appState.deleteCreatedGiftButton(id: button.id)
                        buttonToDelete = nil
                    }
                }
            }
        } message: {
            if let button = buttonToDelete {
                Text("Are you sure you want to delete \"\(button.name)\"? This will also remove it from \(button.recipientName ?? "your friend")'s buttons.")
            }
        }
    }
}

struct CreatedGiftButtonRow: View {
    let button: CreatedGiftButton
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.sm) {
            HStack {
                // Icon and color
                ZStack {
                    Circle()
                        .fill(button.uiColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForButton(button.icon))
                        .foregroundColor(.white)
                        .font(.body)
                }

                VStack(alignment: .leading, spacing: BLSpacing.xs) {
                    Text(button.name)
                        .font(BLTypography.titleSmall)
                        .foregroundColor(.blTextPrimary)

                    if let description = button.description, !description.isEmpty {
                        Text(description)
                            .font(BLTypography.bodySmall)
                            .foregroundColor(.blTextSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: BLSpacing.sm) {
                        // Type badge
                        Text(button.type.displayName)
                            .font(BLTypography.labelSmall)
                            .padding(.horizontal, BLSpacing.sm)
                            .padding(.vertical, BLSpacing.xs)
                            .background(Color.blSurfaceElevated)
                            .foregroundColor(.blTextSecondary)
                            .cornerRadius(BLRadius.sm)

                        // Recipient badge
                        if let recipientName = button.recipientName {
                            HStack(spacing: BLSpacing.xs) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                Text("For \(recipientName)")
                                    .font(BLTypography.labelSmall)
                            }
                            .padding(.horizontal, BLSpacing.sm)
                            .padding(.vertical, BLSpacing.xs)
                            .background(Color.blButtonPurple.opacity(0.2))
                            .foregroundColor(.blButtonPurple)
                            .cornerRadius(BLRadius.sm)
                        }
                    }
                }

                Spacer()

                // Menu
                Menu {
                    SwiftUI.Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    SwiftUI.Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blTextSecondary)
                        .font(.title3)
                }
            }

            // Gift message if present
            if let message = button.giftMessage, !message.isEmpty {
                HStack(spacing: BLSpacing.xs) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundColor(.blTextTertiary)
                    Text(message)
                        .font(BLTypography.bodySmall)
                        .foregroundColor(.blTextSecondary)
                        .italic()
                        .lineLimit(2)
                }
                .padding(.leading, 48)
            }
        }
        .padding(.vertical, BLSpacing.xs)
    }

    private func iconForButton(_ icon: String) -> String {
        let iconMap: [String: String] = [
            "star": "star.fill",
            "heart": "heart.fill",
            "bolt": "bolt.fill",
            "flame": "flame.fill",
            "leaf": "leaf.fill",
            "drop": "drop.fill",
            "sun": "sun.max.fill",
            "moon": "moon.fill",
            "cloud": "cloud.fill",
            "snowflake": "snowflake",
            "car": "car.fill",
            "airplane": "airplane",
            "gamecontroller": "gamecontroller.fill",
            "book": "book.fill",
            "pencil": "pencil",
            "scissors": "scissors",
            "wrench": "wrench.fill",
            "hammer": "hammer.fill",
            "gear": "gear",
            "lock": "lock.fill"
        ]
        return iconMap[icon] ?? "star.fill"
    }
}

struct EmptyGiftButtonsView: View {
    var body: some View {
        VStack(spacing: BLSpacing.xl) {
            Image(systemName: "gift")
                .font(.system(size: 64))
                .foregroundColor(.blTextTertiary)

            Text("No Gift Buttons Yet")
                .font(BLTypography.headlineSmall)
                .foregroundColor(.blTextPrimary)

            Text("When you create buttons for your friends,\nthey'll appear here so you can manage them.")
                .font(BLTypography.bodyMedium)
                .foregroundColor(.blTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(BLSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EditGiftButtonView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState

    let button: CreatedGiftButton

    @State private var formData: ButtonFormData
    @State private var isSaving = false

    init(button: CreatedGiftButton) {
        self.button = button
        _formData = State(initialValue: ButtonFormData(
            name: button.name,
            description: button.description ?? "",
            type: button.type,
            icon: button.icon,
            color: button.color,
            alertsEnabled: button.alertsEnabled,
            autoStopEnabled: button.autoStopEnabled,
            autoStopMinutes: button.autoStopMinutes,
            calendarSyncEnabled: button.calendarSyncEnabled,
            choices: button.choices ?? []
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Button Details")) {
                    TextField("Name", text: $formData.name)

                    TextField("Description (optional)", text: $formData.description)
                }

                Section(header: Text("Appearance")) {
                    // Icon picker
                    HStack {
                        Text("Icon")
                        Spacer()
                        IconPicker(selectedIcon: $formData.icon)
                    }

                    // Color picker
                    HStack {
                        Text("Color")
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: formData.color) },
                            set: { formData.color = $0.hexString }
                        ))
                        .labelsHidden()
                    }
                }

                if formData.type == .oneTime {
                    Section(header: Text("Choices (Optional)")) {
                        ForEach($formData.choices) { $choice in
                            HStack {
                                TextField("Choice", text: $choice.text)
                                SwiftUI.Button(action: {
                                    formData.choices.removeAll { $0.id == choice.id }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        if formData.choices.count < 4 {
                            SwiftUI.Button(action: {
                                formData.choices.append(IdentifiedChoice())
                            }) {
                                Label("Add Choice", systemImage: "plus.circle")
                            }
                        }
                    }
                }

                Section(header: Text("Recipient")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blButtonPurple)
                        Text(button.recipientName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Gift Button")
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
                        saveChanges()
                    }
                    .disabled(!formData.isValid || isSaving)
                }
            }
        }
        .disabled(isSaving)
    }

    private func saveChanges() {
        isSaving = true

        Task {
            let success = await appState.updateCreatedGiftButton(id: button.id, formData: formData)

            await MainActor.run {
                isSaving = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

/// Simple icon picker for editing buttons
struct IconPicker: View {
    @Binding var selectedIcon: String

    private let icons = [
        "star", "heart", "bolt", "flame", "leaf",
        "drop", "sun", "moon", "cloud", "snowflake",
        "car", "airplane", "gamecontroller", "book", "pencil",
        "scissors", "wrench", "hammer", "gear", "lock"
    ]

    private let iconMap: [String: String] = [
        "star": "star.fill",
        "heart": "heart.fill",
        "bolt": "bolt.fill",
        "flame": "flame.fill",
        "leaf": "leaf.fill",
        "drop": "drop.fill",
        "sun": "sun.max.fill",
        "moon": "moon.fill",
        "cloud": "cloud.fill",
        "snowflake": "snowflake",
        "car": "car.fill",
        "airplane": "airplane",
        "gamecontroller": "gamecontroller.fill",
        "book": "book.fill",
        "pencil": "pencil",
        "scissors": "scissors",
        "wrench": "wrench.fill",
        "hammer": "hammer.fill",
        "gear": "gear",
        "lock": "lock.fill"
    ]

    var body: some View {
        Menu {
            ForEach(icons, id: \.self) { icon in
                SwiftUI.Button(action: { selectedIcon = icon }) {
                    Label(icon.capitalized, systemImage: iconMap[icon] ?? "star.fill")
                }
            }
        } label: {
            Image(systemName: iconMap[selectedIcon] ?? "star.fill")
                .foregroundColor(.blPrimary)
        }
    }
}

#Preview {
    NavigationView {
        CreatedGiftButtonsView()
            .environmentObject(AppState())
    }
}
