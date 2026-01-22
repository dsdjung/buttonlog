import SwiftUI

struct SupportView: View {
    @State private var tickets: [SupportTicket] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateTicket = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading tickets...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadTickets() }
                        }
                    }
                    .padding()
                } else if tickets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Support Tickets")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Have a question or found a bug?\nCreate a ticket to get help.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button(action: { showingCreateTicket = true }) {
                            Label("Create Ticket", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(tickets) { ticket in
                            NavigationLink(destination: SupportTicketView(ticketId: ticket.id)) {
                                TicketRowView(ticket: ticket)
                            }
                        }
                    }
                    .refreshable {
                        await loadTickets()
                    }
                }
            }
            .navigationTitle("Help & Support")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTicket = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTicket) {
                CreateTicketView { ticket in
                    tickets.insert(ticket, at: 0)
                }
            }
            .task {
                await loadTickets()
            }
        }
    }

    private func loadTickets() async {
        isLoading = true
        errorMessage = nil

        do {
            tickets = try await APIService.shared.getSupportTickets()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct TicketRowView: View {
    let ticket: SupportTicket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ticket.category.icon)
                    .foregroundColor(.blue)
                Text(ticket.subject)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let unread = ticket.unreadCount, unread > 0 {
                    Text("\(unread)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }

            HStack {
                StatusBadge(status: ticket.status)
                Spacer()
                Text(ticket.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: TicketStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .open: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

#Preview {
    SupportView()
}
