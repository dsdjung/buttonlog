import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: BLSpacing.xl) {
                    // Logo and Title
                    VStack(spacing: BLSpacing.lg) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)

                        Text("ButtonLog")
                            .font(BLTypography.displaySmall)
                            .foregroundColor(.blTextPrimary)

                        Text("Track your activities with the tap of a button")
                            .font(BLTypography.bodyMedium)
                            .foregroundColor(.blTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, BLSpacing.xxxl)

                    Spacer(minLength: BLSpacing.xxxl)

                    // OAuth Login Buttons
                    VStack(spacing: BLSpacing.md) {
                        // Apple Sign-In Button
                        AppleSignInButton(authManager: authManager)
                            .padding(.horizontal, BLSpacing.xl)

                        // Google Sign-In Button
                        GoogleSignInButton(authManager: authManager)
                            .padding(.horizontal, BLSpacing.xl)
                    }

                    // Loading indicator
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.top, BLSpacing.lg)
                    }

                    // Terms and Privacy
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(BLTypography.labelSmall)
                        .foregroundColor(.blTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BLSpacing.xl)
                        .padding(.top, BLSpacing.lg)

                    Spacer(minLength: BLSpacing.xxxl)
                }
            }
            .background(Color.blBackground)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(authManager.errorMessage != nil)) {
            SwiftUI.Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
}

struct AppleSignInButton: View {
    let authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    Task {
                        await authManager.loginWithApple(authorization: authorization)
                    }
                case .failure(let error):
                    // User cancelled or other error
                    if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                        authManager.errorMessage = error.localizedDescription
                    }
                }
            }
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(BLRadius.md)
        .disabled(authManager.isLoading)
    }
}

struct GoogleSignInButton: View {
    let authManager: AuthenticationManager

    var body: some View {
        SwiftUI.Button(action: {
            Task {
                await authManager.loginWithGoogle()
            }
        }) {
            HStack(spacing: BLSpacing.md) {
                // Google "G" logo
                Image(systemName: "globe")
                    .font(.title3)

                Text("Continue with Google")
                    .font(BLTypography.labelLarge)

                Spacer()
            }
            .foregroundColor(.blTextPrimary)
            .padding(BLSpacing.lg)
            .background(Color.blSurface)
            .cornerRadius(BLRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BLRadius.md)
                    .stroke(Color.blTextTertiary.opacity(0.3), lineWidth: 1)
            )
            .blShadow(BLShadow.small)
        }
        .disabled(authManager.isLoading)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
