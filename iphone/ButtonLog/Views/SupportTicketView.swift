import SwiftUI

struct SupportTicketView: View {
    let ticketId: String

    @State private var ticket: SupportTicket?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var newMessage = ""
    @State private var isSending = false
    @FocusState private var isMessageFieldFocused: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading ticket...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await loadTicket() }
                    }
                }
                .padding()
            } else if let ticket = ticket {
                VStack(spacing: 0) {
                    // Ticket header
                    TicketHeaderView(ticket: ticket)

                    Divider()

                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(ticket.messages ?? []) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: ticket.messages?.count) { _, _ in
                            if let lastMessage = ticket.messages?.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()

                    // Message input
                    if ticket.status.isActive {
                        MessageInputView(
                            message: $newMessage,
                            isSending: isSending,
                            isFocused: _isMessageFieldFocused,
                            onSend: sendMessage
                        )
                    } else {
                        Text("This ticket is \(ticket.status.displayName.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Ticket")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTicket()
        }
    }

    private func loadTicket() async {
        isLoading = true
        errorMessage = nil

        do {
            ticket = try await APIService.shared.getSupportTicket(id: ticketId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let content = newMessage
        newMessage = ""
        isSending = true

        Task {
            do {
                let message = try await APIService.shared.sendTicketMessage(ticketId: ticketId, content: content)
                if var currentTicket = ticket {
                    var messages = currentTicket.messages ?? []
                    messages.append(message)
                    currentTicket.messages = messages
                    ticket = currentTicket
                }
                isSending = false
            } catch {
                newMessage = content
                isSending = false
                // Show error (could add alert here)
            }
        }
    }
}

struct TicketHeaderView: View {
    let ticket: SupportTicket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ticket.category.icon)
                    .foregroundColor(.blue)
                Text(ticket.subject)
                    .font(.headline)
            }

            HStack {
                StatusBadge(status: ticket.status)

                Text(ticket.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let admin = ticket.assignedAdmin, let name = admin.name {
                    Text("Assigned: \(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Created \(ticket.createdAt, style: .relative) ago")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MessageBubbleView: View {
    let message: TicketMessage

    var body: some View {
        HStack {
            if !message.isFromSupport {
                Spacer()
            }

            VStack(alignment: message.isFromSupport ? .leading : .trailing, spacing: 4) {
                if message.isFromSupport, let name = message.senderName {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromSupport ? Color(.systemGray5) : Color.blue)
                    .foregroundColor(message.isFromSupport ? .primary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isFromSupport ? .leading : .trailing)

            if message.isFromSupport {
                Spacer()
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var message: String
    let isSending: Bool
    @FocusState var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isFocused)
                .disabled(isSending)

            Button(action: onSend) {
                if isSending {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        SupportTicketView(ticketId: "test-id")
    }
}
