import SwiftUI

struct WebhookSettingsView: View {
    @State private var webhookUrl: String = ""
    @State private var webhookEnabled: Bool = false
    @State private var webhookSecret: String = ""
    @State private var retryFailed: Bool = true
    @State private var maxRetries: Int = 3

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    private let apiService = APIService.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable Webhooks", isOn: $webhookEnabled)

                TextField("Webhook URL", text: $webhookUrl)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disabled(!webhookEnabled)
            } header: {
                Text("Webhook Configuration")
            } footer: {
                Text("When enabled, ButtonLog will send HTTP POST requests to your webhook URL whenever button events occur.")
            }

            Section {
                SecureField("Webhook Secret (Optional)", text: $webhookSecret)
                    .disabled(!webhookEnabled)
            } header: {
                Text("Security")
            } footer: {
                Text("If provided, webhook requests will include a signature header for verification.")
            }

            Section {
                Toggle("Retry Failed Deliveries", isOn: $retryFailed)
                    .disabled(!webhookEnabled)

                if retryFailed {
                    Stepper("Max Retries: \(maxRetries)", value: $maxRetries, in: 1...10)
                        .disabled(!webhookEnabled)
                }
            } header: {
                Text("Retry Settings")
            }

            Section {
                SwiftUI.Button {
                    Task { await saveSettings() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save Settings")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving || !isFormValid)
            }

            Section {
                SwiftUI.Button {
                    Task { await testWebhook() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Test Webhook")
                        Spacer()
                    }
                }
                .disabled(!webhookEnabled || webhookUrl.isEmpty)
            } footer: {
                Text("Send a test payload to your webhook URL to verify the configuration.")
            }
        }
        .navigationTitle("Webhook Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadSettings() }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: $showingError) {
            SwiftUI.Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $showingSuccess) {
            SwiftUI.Button("OK") {}
        } message: {
            Text("Webhook settings saved successfully")
        }
    }

    private var isFormValid: Bool {
        !webhookEnabled || !webhookUrl.isEmpty
    }

    @MainActor
    private func loadSettings() async {
        isLoading = true

        do {
            let settings = try await apiService.getWebhookSettings()
            webhookUrl = settings.defaultWebhookUrl ?? ""
            webhookEnabled = settings.defaultWebhookEnabled
            webhookSecret = settings.webhookSecret ?? ""
            retryFailed = settings.retryFailed
            maxRetries = settings.maxRetries
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isLoading = false
    }

    @MainActor
    private func saveSettings() async {
        isSaving = true

        do {
            try await apiService.updateWebhookSettings(
                webhookUrl: webhookUrl.isEmpty ? nil : webhookUrl,
                webhookEnabled: webhookEnabled,
                webhookSecret: webhookSecret.isEmpty ? nil : webhookSecret,
                retryFailed: retryFailed,
                maxRetries: maxRetries
            )
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSaving = false
    }

    @MainActor
    private func testWebhook() async {
        do {
            try await apiService.testWebhook()
            errorMessage = "Test webhook sent successfully!"
            showingError = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// WebhookSettings model is defined in APIService.swift

#Preview {
    NavigationStack {
        WebhookSettingsView()
    }
}
