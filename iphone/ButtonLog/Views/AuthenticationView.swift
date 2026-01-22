import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false

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

                    // Form
                    VStack(spacing: BLSpacing.lg) {
                        // Email Field
                        VStack(alignment: .leading, spacing: BLSpacing.sm) {
                            Text("Email")
                                .font(BLTypography.labelLarge)
                                .foregroundColor(.blTextPrimary)

                            TextField("Enter your email", text: $email)
                                .font(BLTypography.bodyLarge)
                                .padding(BLSpacing.md)
                                .background(Color.blSurfaceElevated)
                                .cornerRadius(BLRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BLRadius.md)
                                        .stroke(Color.blTextTertiary.opacity(0.3), lineWidth: 1)
                                )
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(authManager.isLoading)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: BLSpacing.sm) {
                            Text("Password")
                                .font(BLTypography.labelLarge)
                                .foregroundColor(.blTextPrimary)

                            SecureField("Enter your password", text: $password)
                                .font(BLTypography.bodyLarge)
                                .padding(BLSpacing.md)
                                .background(Color.blSurfaceElevated)
                                .cornerRadius(BLRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BLRadius.md)
                                        .stroke(Color.blTextTertiary.opacity(0.3), lineWidth: 1)
                                )
                                .disabled(authManager.isLoading)
                        }

                        // Confirm Password Field (Register only)
                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: BLSpacing.sm) {
                                Text("Confirm Password")
                                    .font(BLTypography.labelLarge)
                                    .foregroundColor(.blTextPrimary)

                                SecureField("Confirm your password", text: $confirmPassword)
                                    .font(BLTypography.bodyLarge)
                                    .padding(BLSpacing.md)
                                    .background(Color.blSurfaceElevated)
                                    .cornerRadius(BLRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BLRadius.md)
                                            .stroke(Color.blTextTertiary.opacity(0.3), lineWidth: 1)
                                    )
                                    .disabled(authManager.isLoading)
                            }
                        }
                    }
                    .padding(.horizontal, BLSpacing.xl)

                    // Action Button
                    SwiftUI.Button(action: handleAuthAction) {
                        HStack(spacing: BLSpacing.sm) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }

                            Text(isLoginMode ? "Login" : "Create Account")
                                .font(BLTypography.labelLarge)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(BLSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: BLRadius.md)
                                .fill((authManager.isLoading || !isFormValid) ? Color.blTextTertiary : Color.blPrimary)
                        )
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                    .padding(.horizontal, BLSpacing.xl)

                    // Toggle Mode
                    SwiftUI.Button(action: {
                        withAnimation(BLAnimation.normal) {
                            isLoginMode.toggle()
                            clearForm()
                        }
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Login")
                            .font(BLTypography.bodyMedium)
                            .foregroundColor(.blPrimary)
                    }
                    .disabled(authManager.isLoading)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.blTextTertiary.opacity(0.3))
                            .frame(height: 1)

                        Text("Or continue with")
                            .font(BLTypography.labelMedium)
                            .foregroundColor(.blTextSecondary)

                        Rectangle()
                            .fill(Color.blTextTertiary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, BLSpacing.xl)
                    .padding(.top, BLSpacing.lg)

                    // Google Login Button
                    GoogleSignInButton(authManager: authManager)
                        .padding(.horizontal, BLSpacing.xl)

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

    private var isFormValid: Bool {
        let emailValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let passwordValid = password.count >= 6

        if isLoginMode {
            return emailValid && passwordValid
        } else {
            return emailValid && passwordValid && password == confirmPassword
        }
    }

    private func handleAuthAction() {
        Task {
            if isLoginMode {
                await authManager.login(email: email, password: password)
            } else {
                await authManager.register(
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            }
        }
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
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
