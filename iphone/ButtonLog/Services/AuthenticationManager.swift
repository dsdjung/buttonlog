import Foundation
import Combine
import AuthenticationServices

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
    private var webAuthSession: ASWebAuthenticationSession?

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

        let baseURL = apiService.oauthBaseURL
        let callbackURLScheme = "buttonlog"

        guard let url = URL(string: "\(baseURL)/auth/google?mobile=true") else {
            errorMessage = "Failed to create OAuth URL"
            isLoading = false
            return
        }

        // Use ASWebAuthenticationSession for OAuth flow
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            webAuthSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    defer { continuation.resume() }

                    if let error = error {
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            self?.errorMessage = nil // User cancelled, no error
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                        self?.isLoading = false
                        return
                    }

                    guard let callbackURL = callbackURL else {
                        self?.errorMessage = "No callback URL received"
                        self?.isLoading = false
                        return
                    }

                    // Parse the callback URL for token or code
                    await self?.handleOAuthCallback(callbackURL)
                }
            }

            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            webAuthSession?.start()
        }
    }

    private func handleOAuthCallback(_ url: URL) async {
        // Parse URL components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            errorMessage = "Failed to parse callback URL"
            isLoading = false
            return
        }

        let queryItems = components.queryItems ?? []

        // Check for direct token (if server returns token directly)
        if let token = queryItems.first(where: { $0.name == "token" })?.value {
            KeychainManager.shared.saveToken(token)
            isAuthenticated = true
            await loadCurrentUser()
            isLoading = false
            return
        }

        // Check for authorization code (if server uses code flow)
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            let state = queryItems.first(where: { $0.name == "state" })?.value

            do {
                let response = try await apiService.exchangeOAuthCode(
                    provider: "google",
                    code: code,
                    state: state
                )

                KeychainManager.shared.saveToken(response.token)
                isAuthenticated = true
                currentUser = response.user
                setOnboardingCompleted(response.user.onboardingCompleted)
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
            return
        }

        // Check for error
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value
            errorMessage = errorDescription ?? error
            isLoading = false
            return
        }

        errorMessage = "Invalid OAuth callback"
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

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthenticationManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

