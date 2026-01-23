import Foundation
import Combine
import AuthenticationServices
import GoogleSignIn

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var onboardingCompleted = false
    @Published var isCheckingAuth = true  // True until initial auth check completes

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    // UserDefaults key for persisting onboarding state
    private let onboardingCompletedKey = "buttonlog_onboarding_completed"

    override init() {
        super.init()
        // Load persisted onboarding state immediately to avoid flash
        onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        // Check if we have a stored token
        if KeychainManager.shared.getToken() != nil {
            isAuthenticated = true
            // Verify token with server and get latest user data
            Task {
                await loadCurrentUser()
                isCheckingAuth = false
            }
        } else {
            isCheckingAuth = false
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
            setOnboardingCompleted(response.user.onboardingCompleted)

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
            setOnboardingCompleted(response.user.onboardingCompleted)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // Use native Google Sign-In SDK (same approach as Android)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            isLoading = false
            return
        }

        // Ensure Google Sign-In is configured
        if GIDSignIn.sharedInstance.configuration == nil {
            guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
                errorMessage = "Google Sign-In not configured: Missing GIDClientID in Info.plist"
                isLoading = false
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        do {
            // Use the Google Sign-In SDK to authenticate natively
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token from Google"
                isLoading = false
                return
            }

            let user = result.user
            let email = user.profile?.email ?? ""
            let uid = user.userID ?? email
            let name = user.profile?.name
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            let imageURL = user.profile?.imageURL(withDimension: 200)?.absoluteString

            // Build user info dictionary, filtering out nil values
            var userInfo: [String: Any] = [
                "email": email,
                "uid": uid,
                "access_token": idToken
            ]
            if let name = name { userInfo["name"] = name }
            if let givenName = givenName { userInfo["first_name"] = givenName }
            if let familyName = familyName { userInfo["last_name"] = familyName }
            if let imageURL = imageURL { userInfo["image"] = imageURL }

            // Send user info to backend (same as Android does)
            let response = try await apiService.authenticateWithOAuth(
                provider: "google",
                userInfo: userInfo
            )

            KeychainManager.shared.saveToken(response.token)
            isAuthenticated = true
            currentUser = response.user
            setOnboardingCompleted(response.user.onboardingCompleted)

        } catch let error as GIDSignInError {
            if error.code == .canceled {
                // User cancelled, no error message needed
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() async {
        // Clear stored token
        KeychainManager.shared.deleteToken()

        // Clear user data
        currentUser = nil
        isAuthenticated = false
        setOnboardingCompleted(false)

        // Optionally notify server of logout
        try? await apiService.logout()
    }

    func loadCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            currentUser = user
            setOnboardingCompleted(user.onboardingCompleted)
        } catch let error as APIError {
            // Only logout on authentication errors (401), not network issues
            if case .serverError(let message) = error,
               message.lowercased().contains("401") ||
               message.lowercased().contains("unauthorized") ||
               message.lowercased().contains("invalid token") {
                await logout()
            }
            // For other errors (network, server down, etc.), keep the user logged in
        } catch {
            // For unexpected errors, keep user logged in to avoid losing session on network issues
        }
    }

    /// Sets onboarding completed state and persists to UserDefaults
    private func setOnboardingCompleted(_ completed: Bool) {
        onboardingCompleted = completed
        UserDefaults.standard.set(completed, forKey: onboardingCompletedKey)
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

    func completeOnboarding() async {
        do {
            try await apiService.completeOnboarding()
            setOnboardingCompleted(true)
        } catch {
            print("Failed to complete onboarding: \(error)")
            // Still mark as completed locally to not block the user
            setOnboardingCompleted(true)
        }
    }
}

