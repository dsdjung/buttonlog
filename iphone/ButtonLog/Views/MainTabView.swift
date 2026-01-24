import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showingCreateButton = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Buttons Tab
            NavigationView {
                ButtonsView()
            }
            .tabItem {
                Image(systemName: "square.grid.2x2.fill")
                Text("Buttons")
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
            
            // Logs Tab
            NavigationView {
                NotificationsView()
            }
            .tabItem {
                Image(systemName: "bell.fill")
                Text("Logs")
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
            // Floating Create Button - only show on Buttons tab
            Group {
                if selectedTab == 0 {
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
                                    .background(Color.blPrimary)
                                    .clipShape(Circle())
                                    .blShadow(BLShadow.medium)
                            }

                            Spacer()
                        }
                        .padding(.bottom, 100) // Above tab bar
                    }
                }
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
        .upgradePrompt(upgradeInfo: $appState.pendingUpgradeInfo) {
            // Navigate to subscription page
            selectedTab = 4 // Account tab
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationManager())
}