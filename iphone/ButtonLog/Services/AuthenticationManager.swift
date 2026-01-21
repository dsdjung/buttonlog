import Foundation
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Check if we have a stored token
        if let token = KeychainManager.shared.getToken() {
            isAuthenticated = true
            // Optionally verify token with server
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.login(email: email, password: password)
            
            // Store token
            KeychainManager.shared.saveToken(response.token)
            
            // Update authentication state
            isAuthenticated = true
            currentUser = response.user
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, confirmPassword: String) async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.register(
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
            
            // Store token
            KeychainManager.shared.saveToken(response.token)
            
            // Update authentication state
            isAuthenticated = true
            currentUser = response.user
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loginWithOAuth(provider: OAuthProvider) async {
        // This would integrate with iOS OAuth SDKs
        // For now, we'll implement a placeholder
        errorMessage = "OAuth login not yet implemented"
    }
    
    func logout() async {
        // Clear stored token
        KeychainManager.shared.deleteToken()
        
        // Clear user data
        currentUser = nil
        isAuthenticated = false
        
        // Optionally notify server of logout
        try? await apiService.logout()
    }
    
    func loadCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            currentUser = user
        } catch {
            // Token might be invalid, logout
            await logout()
        }
    }
    
    func updateProfile(_ update: UserProfileUpdate) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedUser = try await apiService.updateUserProfile(update)
            currentUser = updatedUser
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshToken() async {
        guard let currentToken = KeychainManager.shared.getToken() else {
            await logout()
            return
        }
        
        do {
            let response = try await apiService.refreshToken(currentToken)
            KeychainManager.shared.saveToken(response.token)
        } catch {
            await logout()
        }
    }
}

enum OAuthProvider {
    case google
    case facebook
    case apple
    
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .facebook: return "Facebook"
        case .apple: return "Apple"
        }
    }
}