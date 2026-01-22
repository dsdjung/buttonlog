import SwiftUI

struct ButtonsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var showingCreateButton = false
    @State private var selectedButton: Button?
    @State private var historyButton: Button?
    @State private var sharingButton: Button?
    @State private var alertSettingsButton: Button?
    
    var filteredButtons: [Button] {
        if searchText.isEmpty {
            return appState.buttons
        } else {
            return appState.buttons.filter { button in
                button.name.localizedCaseInsensitiveContains(searchText) ||
                (button.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if appState.isLoadingButtons && appState.buttons.isEmpty {
                // Loading state
                VStack {
                    ProgressView()
                    Text("Loading buttons...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if filteredButtons.isEmpty {
                // Empty state
                EmptyStateView {
                    showingCreateButton = true
                }
                
            } else {
                // Buttons list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredButtons) { button in
                            ButtonCard(
                                button: button,
                                onTap: {
                                    Task {
                                        await appState.clickButton(id: button.id)
                                    }
                                },
                                onEdit: {
                                    selectedButton = button
                                },
                                onHistory: {
                                    historyButton = button
                                },
                                onSharing: {
                                    sharingButton = button
                                },
                                onAlertSettings: {
                                    alertSettingsButton = button
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // Space for floating button
                }
                .refreshable {
                    await appState.loadButtons()
                }
            }
        }
        .navigationTitle("ButtonLog")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button("Add") {
                    showingCreateButton = true
                }
            }
        }
        .sheet(isPresented: $showingCreateButton) {
            CreateButtonView()
        }
        .sheet(item: $selectedButton) { button in
            EditButtonView(button: button)
        }
        .sheet(item: $historyButton) { button in
            ButtonHistoryView(button: button)
        }
        .sheet(item: $sharingButton) { button in
            ButtonSharingView(button: button)
        }
        .sheet(item: $alertSettingsButton) { button in
            ButtonAlertSettingsView(button: button)
        }
    }
}

struct ButtonCard: View {
    let button: Button
    let onTap: () -> Void
    let onEdit: () -> Void
    let onHistory: () -> Void
    var onSharing: (() -> Void)? = nil
    var onAlertSettings: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon and color
                ZStack {
                    Circle()
                        .fill(button.uiColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: iconForButton(button.icon))
                        .foregroundColor(.white)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(button.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let description = button.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        ButtonTypeTag(type: button.type)

                        if button.currentState == .active {
                            ButtonStateTag(state: button.currentState)
                        }

                        if button.isGift, let fromName = button.giftFromName {
                            GiftBadge(fromName: fromName)
                        }

                        if button.isShared, let ownerName = button.ownerName {
                            SharedWithMeBadge(ownerName: ownerName)
                        }
                    }
                }

                Spacer()

                // Settings menu - different options for owned vs shared buttons
                Menu {
                    SwiftUI.Button(action: onHistory) {
                        Label("History", systemImage: "clock")
                    }

                    if button.isOwner {
                        SwiftUI.Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        if let onSharing = onSharing {
                            SwiftUI.Button(action: onSharing) {
                                Label("Sharing", systemImage: "person.2")
                            }
                        }

                        if let onAlertSettings = onAlertSettings {
                            SwiftUI.Button(action: onAlertSettings) {
                                Label("Alert Settings", systemImage: "bell")
                            }
                        }

                        Divider()

                        SwiftUI.Button(role: .destructive) {
                            Task {
                                await AppState().deleteButton(id: button.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Click Button
            SwiftUI.Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                onTap()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }) {
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.headline)
                    
                    Text(buttonActionText(for: button))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(button.uiColor)
                        .scaleEffect(isPressed ? 0.96 : 1.0)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            "gear": "gear"
        ]
        
        return iconMap[icon] ?? "star.fill"
    }
    
    private func buttonActionText(for button: Button) -> String {
        switch button.type {
        case .instant:
            return "Click!"
        case .toggle:
            return button.currentState == .idle ? "Start" : "Stop"
        case .oneTime:
            return "Complete"
        case .workflow:
            return "Next"
        }
    }
}

struct ButtonTypeTag: View {
    let type: ButtonType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(8)
    }
}

struct ButtonStateTag: View {
    let state: ButtonState

    var body: some View {
        Text(state.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(state.color.opacity(0.2))
            .foregroundColor(state.color)
            .cornerRadius(8)
    }
}

struct GiftBadge: View {
    let fromName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.caption2)
            Text("From \(fromName)")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.2))
        .foregroundColor(.purple)
        .cornerRadius(8)
    }
}

struct SharedWithMeBadge: View {
    let ownerName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
            Text("Shared by \(ownerName)")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let onCreateButton: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No buttons yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first button to start tracking activities")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            SwiftUI.Button("Create Button") {
                onCreateButton()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search buttons...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                SwiftUI.Button("Clear") {
                    text = ""
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        ButtonsView()
            .environmentObject(AppState())
    }
}
