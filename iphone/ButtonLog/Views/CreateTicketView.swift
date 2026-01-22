import SwiftUI

struct CreateTicketView: View {
    @Environment(\.dismiss) private var dismiss

    let onTicketCreated: (SupportTicket) -> Void

    @State private var formData = TicketFormData()
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $formData.category) {
                        ForEach(TicketCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Subject")) {
                    TextField("Brief description of your issue", text: $formData.subject)
                        .textInputAutocapitalization(.sentences)
                }

                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $formData.priority) {
                        ForEach(TicketPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Message")) {
                    TextEditor(text: $formData.message)
                        .frame(minHeight: 100)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    SwiftUI.Button("Submit") {
                        submitTicket()
                    }
                    .disabled(!formData.isValid || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    private func submitTicket() {
        guard formData.isValid else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let ticket = try await APIService.shared.createSupportTicket(formData)
                await MainActor.run {
                    onTicketCreated(ticket)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    CreateTicketView { _ in }
}
