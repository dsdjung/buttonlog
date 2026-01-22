import SwiftUI

struct ButtonHistoryView: View {
    let button: ButtonModel
    @Environment(\.dismiss) private var dismiss
    @State private var clicks: [ButtonClick] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let apiService = APIService.shared

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading history...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        SwiftUI.Button("Retry") {
                            Task {
                                await loadHistory()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if clicks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No activity yet")
                            .font(.headline)
                        Text("Click the button to start recording activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(clicks) { click in
                            ClickRow(click: click, buttonType: button.type)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SwiftUI.Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            clicks = try await apiService.getButtonHistory(id: button.id)
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct ClickRow: View {
    let click: ButtonClick
    let buttonType: ButtonType

    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            ZStack {
                Circle()
                    .fill(actionColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: actionIcon)
                    .foregroundColor(actionColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(actionText)
                    .font(.headline)

                Text(click.clickedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                +
                Text(" at ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                +
                Text(click.clickedAt, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let duration = click.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Platform badge
            Text(click.platform.capitalized)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    private var actionText: String {
        guard let action = click.action else {
            return "Clicked"
        }

        switch action {
        case "start":
            return "Started"
        case "end":
            return "Stopped"
        case "click":
            return "Clicked"
        default:
            return action.capitalized
        }
    }

    private var actionIcon: String {
        guard let action = click.action else {
            return "hand.tap"
        }

        switch action {
        case "start":
            return "play.fill"
        case "end":
            return "stop.fill"
        case "click":
            return "hand.tap"
        default:
            return "circle.fill"
        }
    }

    private var actionColor: Color {
        guard let action = click.action else {
            return .blue
        }

        switch action {
        case "start":
            return .green
        case "end":
            return .red
        case "click":
            return .blue
        default:
            return .secondary
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min"
            }
            return "\(minutes) min \(remainingSeconds) sec"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if minutes == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(minutes) min"
        }
    }
}

#Preview {
    ButtonHistoryView(button: ButtonModel(
        id: "1",
        name: "Test Button",
        description: "A test button",
        type: .instant,
        icon: "star.fill",
        color: "#007AFF",
        isActive: true,
        currentState: .idle,
        stateChangedAt: nil,
        alertsEnabled: true,
        autoStopEnabled: false,
        calendarSyncEnabled: false,
        userId: "user1",
        createdAt: Date(),
        updatedAt: Date()
    ))
}
