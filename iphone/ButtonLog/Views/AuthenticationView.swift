import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingError = false

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
                    VStack(spacing: 2) {
                        Text("By continuing, you agree to our")
                            .font(BLTypography.labelSmall)
                            .foregroundColor(.blTextTertiary)
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: URL(string: "https://buttonlog.com/terms")!)
                                .font(BLTypography.labelSmall)
                                .foregroundColor(.accentColor)
                            Text("and")
                                .font(BLTypography.labelSmall)
                                .foregroundColor(.blTextTertiary)
                            Link("Privacy Policy", destination: URL(string: "https://buttonlog.com/privacy")!)
                                .font(BLTypography.labelSmall)
                                .foregroundColor(.accentColor)
                        }
                    }
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
        .alert("Error", isPresented: $showingError) {
            SwiftUI.Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
        .onChange(of: authManager.errorMessage) { _, newValue in
            showingError = newValue != nil
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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SwiftUI.Button(action: {
            Task {
                await authManager.loginWithGoogle()
            }
        }) {
            HStack(spacing: BLSpacing.sm) {
                // Google "G" logo
                GoogleLogo()
                    .frame(width: 18, height: 18)

                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .background(colorScheme == .dark ? Color.white : Color.black)
            .cornerRadius(BLRadius.md)
        }
        .disabled(authManager.isLoading)
    }
}

/// Google "G" logo rendered using SwiftUI
struct GoogleLogo: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Blue arc (top-right)
                GoogleArc(startAngle: -45, endAngle: 45)
                    .fill(Color(red: 66/255, green: 133/255, blue: 244/255))

                // Green arc (bottom-right)
                GoogleArc(startAngle: 45, endAngle: 135)
                    .fill(Color(red: 52/255, green: 168/255, blue: 83/255))

                // Yellow arc (bottom-left)
                GoogleArc(startAngle: 135, endAngle: 225)
                    .fill(Color(red: 251/255, green: 188/255, blue: 5/255))

                // Red arc (top-left)
                GoogleArc(startAngle: 225, endAngle: 315)
                    .fill(Color(red: 234/255, green: 67/255, blue: 53/255))

                // Blue horizontal bar
                Rectangle()
                    .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
                    .frame(width: size * 0.45, height: size * 0.18)
                    .offset(x: size * 0.12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct GoogleArc: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.5

        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(endAngle), endAngle: .degrees(startAngle), clockwise: true)
        path.closeSubpath()
        return path
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
