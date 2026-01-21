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
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("ButtonLog")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your activities with the tap of a button")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(authManager.isLoading)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(authManager.isLoading)
                        }
                        
                        // Confirm Password Field (Register only)
                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(authManager.isLoading)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Button
                    SwiftUI.Button(action: handleAuthAction) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isLoginMode ? "Login" : "Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                    .padding(.horizontal, 20)
                    
                    // Toggle Mode
                    SwiftUI.Button(action: {
                        withAnimation {
                            isLoginMode.toggle()
                            clearForm()
                        }
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Login")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(authManager.isLoading)
                    
                    // Google Login Button
                    VStack(spacing: 12) {
                        Text("Or continue with")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        GoogleSignInButton(authManager: authManager)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
            }
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
            HStack {
                Image(systemName: "globe")
                    .font(.title3)

                Text("Continue with Google")
                    .font(.headline)

                Spacer()
            }
            .foregroundColor(.black)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(authManager.isLoading)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}