import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showingCreateButton = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Buttons
            NavigationView {
                ButtonsView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Friends Tab
            NavigationView {
                FriendsView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Friends")
            }
            .badge(appState.pendingFriendRequests.count)
            .tag(1)
            
            // Diary Tab
            NavigationView {
                DiaryView()
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("Diary")
            }
            .tag(2)
            
            // Notifications Tab
            NavigationView {
                NotificationsView()
            }
            .tabItem {
                Image(systemName: "bell.fill")
                Text("Notifications")
            }
            .badge(appState.unreadNotificationCount)
            .tag(3)
            
            // Account Tab
            NavigationView {
                AccountView()
            }
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("Account")
            }
            .tag(4)
        }
        .overlay(
            // Floating Create Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    SwiftUI.Button(action: {
                        showingCreateButton = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 100) // Above tab bar
            }
        )
        .sheet(isPresented: $showingCreateButton) {
            CreateButtonView()
        }
        .task {
            await appState.loadInitialData()
        }
        .refreshable {
            await appState.refreshData()
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            SwiftUI.Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationManager())
}