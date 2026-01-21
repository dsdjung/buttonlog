import SwiftUI

struct CreateButtonView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var buttonManager: ButtonManager
    
    @State private var formData = ButtonFormData()
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    @State private var isCreating = false
    
    private let iconOptions = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill",
        "drop.fill", "sun.fill", "moon.fill", "cloud.fill", "snowflake",
        "car.fill", "airplane", "gamecontroller.fill", "book.fill", "pencil",
        "scissors", "wrench.fill", "hammer.fill", "gear", "lock.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("Button Name", text: $formData.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $formData.description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Button Type
                Section("Button Type") {
                    Picker("Type", selection: $formData.type) {
                        ForEach(ButtonType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Type-specific help text
                    typeHelpText
                }
                
                // Appearance
                Section("Appearance") {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Button(action: {
                            showingIconPicker = true
                        }) {
                            Image(systemName: formData.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: formData.color))
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Button(action: {
                            showingColorPicker = true
                        }) {
                            Circle()
                                .fill(Color(hex: formData.color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2)
                                )
                        }
                    }
                }
                
                // Settings
                Section("Settings") {
                    Toggle("Enable Notifications", isOn: $formData.notificationsEnabled)
                    
                    if formData.type == .timed || formData.type == .state {
                        Toggle("Auto Stop", isOn: $formData.autoStopEnabled)
                    }
                    
                    Toggle("Calendar Sync", isOn: $formData.calendarSyncEnabled)
                }
                
                // Preview
                Section("Preview") {
                    ButtonPreviewCard(buttonData: formData)
                }
            }
            .navigationTitle("New Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createButton()
                        }
                    }
                    .disabled(!formData.isValid || isCreating)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $formData.icon, iconOptions: iconOptions)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $formData.color)
            }
        }
    }
    
    private var typeHelpText: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch formData.type {
            case .instant:
                Text("Instant buttons record a single click event each time they're pressed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .timed:
                Text("Timed buttons track duration from press to release.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .state:
                Text("State buttons toggle between active and idle states.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
    
    private func createButton() async {
        isCreating = true
        
        let success = await buttonManager.createButton(formData)
        
        if success {
            dismiss()
        }
        
        isCreating = false
    }
}

struct ButtonPreviewCard: View {
    let buttonData: ButtonFormData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: buttonData.color))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: buttonData.icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(buttonData.name.isEmpty ? "Button Name" : buttonData.name)
                        .font(.headline)
                        .foregroundColor(buttonData.name.isEmpty ? .secondary : .primary)
                    
                    if !buttonData.description.isEmpty {
                        Text(buttonData.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Text(buttonData.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.headline)
                    
                    Text("Click!")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: buttonData.color))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(buttonData.name.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    CreateButtonView()
        .environmentObject(ButtonManager())
}
