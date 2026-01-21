import Foundation
import Combine
import AuthenticationServices

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        // Check if we have a stored token
        if KeychainManager.shared.getToken() != nil {
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
        isLoading = true
        errorMessage = nil

        let baseURL = apiService.oauthBaseURL

        // Build OAuth URL based on provider
        let authURL: URL?
        let callbackURLScheme = "buttonlog"

        switch provider {
        case .google:
            authURL = URL(string: "\(baseURL)/auth/google?mobile=true")
        case .facebook:
            authURL = URL(string: "\(baseURL)/auth/facebook?mobile=true")
        case .apple:
            // Sign in with Apple uses native API
            await loginWithApple()
            return
        }

        guard let url = authURL else {
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
                    await self?.handleOAuthCallback(callbackURL, provider: provider)
                }
            }

            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            webAuthSession?.start()
        }
    }

    private func handleOAuthCallback(_ url: URL, provider: OAuthProvider) async {
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
                    provider: provider.apiName,
                    code: code,
                    state: state
                )

                KeychainManager.shared.saveToken(response.token)
                isAuthenticated = true
                currentUser = response.user
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

    private func loginWithApple() async {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let delegate = AppleSignInDelegate { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let credential):
                        await self?.handleAppleSignIn(credential)
                    case .failure(let error):
                        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                            self?.errorMessage = nil
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                    self?.isLoading = false
                    continuation.resume()
                }
            }

            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()

            // Keep delegate alive during the request
            objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private func handleAppleSignIn(_ credential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Failed to get Apple ID token"
            return
        }

        do {
            let response = try await apiService.exchangeOAuthCode(
                provider: "apple",
                code: tokenString,
                state: nil
            )

            KeychainManager.shared.saveToken(response.token)
            isAuthenticated = true
            currentUser = response.user
        } catch {
            errorMessage = error.localizedDescription
        }
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

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

// MARK: - OAuthProvider

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

    var apiName: String {
        switch self {
        case .google: return "google"
        case .facebook: return "facebook"
        case .apple: return "apple"
        }
    }
}
