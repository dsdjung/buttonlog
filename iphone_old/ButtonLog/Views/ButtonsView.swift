import SwiftUI

struct ButtonsView: View {
    @EnvironmentObject var buttonManager: ButtonManager
    @State private var showingCreateButton = false
    @State private var searchText = ""
    
    var filteredButtons: [Button] {
        if searchText.isEmpty {
            return buttonManager.buttons
        } else {
            return buttonManager.buttons.filter { button in
                button.name.localizedCaseInsensitiveContains(searchText) ||
                (button.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
            
            if buttonManager.buttons.isEmpty {
                emptyStateView
            } else {
                buttonsList
            }
        }
        .navigationTitle("ButtonLog")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await buttonManager.fetchButtons()
        }
        .sheet(isPresented: $showingCreateButton) {
            CreateButtonView()
        }
        .onAppear {
            Task {
                await buttonManager.fetchButtons()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search buttons...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
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
            
            Button("Create Button") {
                showingCreateButton = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var buttonsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredButtons) { button in
                    ButtonCard(button: button)
                        .onTapGesture {
                            // Navigate to button detail or trigger action
                            Task {
                                await buttonManager.clickButton(button.id)
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct ButtonCard: View {
    let button: Button
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon and color
                ZStack {
                    Circle()
                        .fill(Color(hex: button.hexColor))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: button.icon)
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
                        Text(button.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        
                        if button.currentState == .active {
                            Text("Active")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: {
                    // Show button settings
                }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Action button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }) {
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
                        .fill(Color(hex: button.hexColor))
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationView {
        ButtonsView()
            .environmentObject(ButtonManager())
    }
}
