import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showingCreateButton = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainAppView
            } else {
                AuthView()
            }
        }
        .sheet(isPresented: $showingCreateButton) {
            CreateButtonView()
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home/Buttons Tab
                NavigationView {
                    ButtonsView()
                        .navigationTitle("ButtonLog")
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                
                // Friends Tab
                NavigationView {
                    FriendsView()
                        .navigationTitle("Friends")
                }
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(1)
                
                // Notifications Tab
                NavigationView {
                    NotificationsView()
                        .navigationTitle("Notifications")
                }
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
                .tag(2)
                
                // Account Tab
                NavigationView {
                    AccountView()
                        .navigationTitle("Account")
                }
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Account")
                }
                .tag(3)
            }
            
            // Floating + Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingCreateButton = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 100) // Position above tab bar
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ButtonManager())
        .environmentObject(NotificationManager())
}
