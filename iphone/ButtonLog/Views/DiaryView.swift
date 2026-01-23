import SwiftUI

struct DiaryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false

    var body: some View {
        VStack {
            // Date selector
            HStack {
                SwiftUI.Button(action: { showingDatePicker = true }) {
                    HStack {
                        Text(selectedDate, style: .date)
                            .font(.headline)

                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                HStack(spacing: 16) {
                    SwiftUI.Button(action: previousDay) {
                        Image(systemName: "chevron.left")
                    }

                    SwiftUI.Button(action: nextDay) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.bottom)

            // Content based on loading/error/data state
            if appState.isLoadingDiary {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let error = appState.diaryError {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    SwiftUI.Button("Retry") {
                        Task {
                            await appState.fetchDiary(for: selectedDate)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Daily summary card
                        DailySummaryCard(summary: appState.diaryData?.summary)

                        // Button activities for the day
                        if let activities = appState.diaryData?.activities, !activities.isEmpty {
                            ForEach(activities) { activity in
                                ButtonActivityCard(activity: activity)
                            }
                        } else {
                            EmptyDayView(date: selectedDate)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Diary")
        .sheet(isPresented: $showingDatePicker) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .presentationDetents([.medium])
        }
        .refreshable {
            await appState.fetchDiary(for: selectedDate)
        }
        .task {
            // Fetch diary data when view appears
            await appState.fetchDiary(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            // Fetch diary data when date changes
            Task {
                await appState.fetchDiary(for: newDate)
            }
        }
    }

    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    private func nextDay() {
        guard !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct DailySummaryCard: View {
    let summary: DiarySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Summary")
                .font(.headline)
                .fontWeight(.semibold)

            HStack {
                SummaryItem(
                    title: "Total Clicks",
                    value: "\(summary?.totalClicks ?? 0)",
                    icon: "hand.tap.fill",
                    color: .blue
                )

                Spacer()

                SummaryItem(
                    title: "Buttons Used",
                    value: "\(summary?.totalButtonsUsed ?? 0)",
                    icon: "square.grid.2x2.fill",
                    color: .green
                )

                Spacer()

                SummaryItem(
                    title: "In Progress",
                    value: "\(summary?.inProgressCount ?? 0)",
                    icon: "play.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ButtonActivityCard: View {
    let activity: DiaryActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Button header
            HStack {
                ZStack {
                    Circle()
                        .fill(activity.button.uiColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: iconForButton(activity.button.icon))
                        .foregroundColor(.white)
                        .font(.callout)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.button.name)
                        .font(.headline)

                    Text("\(activity.totalClicks) \(activity.totalClicks == 1 ? "click" : "clicks")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatButtonType(activity.button.type))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            // Activity timeline
            VStack(alignment: .leading, spacing: 8) {
                ForEach(activity.clicks.prefix(5)) { click in
                    ActivityTimelineItem(click: click, buttonType: activity.button.type)
                }

                if activity.clicks.count > 5 {
                    Text("... and \(activity.clicks.count - 5) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formatButtonType(_ type: String) -> String {
        switch type {
        case "instant": return "Instant"
        case "toggle": return "Toggle"
        case "one-time": return "One-Time"
        case "workflow": return "Workflow"
        default: return type.capitalized
        }
    }

    private func iconForButton(_ icon: String) -> String {
        let iconMap: [String: String] = [
            "star": "star.fill",
            "heart": "heart.fill",
            "bolt": "bolt.fill",
            "flame": "flame.fill",
            "leaf": "leaf.fill",
            "drop": "drop.fill",
            "sun": "sun.max.fill",
            "moon": "moon.fill",
            "car": "car.fill",
            "book": "book.fill",
            "pencil": "pencil",
            "gear": "gearshape.fill"
        ]
        return iconMap[icon] ?? "star.fill"
    }
}

struct ActivityTimelineItem: View {
    let click: DiaryClick
    let buttonType: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)

            Text(click.formattedTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(formattedActionText)
                .font(.subheadline)

            Spacer()
        }
    }

    private var formattedActionText: String {
        let action = formatAction(click.action, buttonType: buttonType)
        if let choice = click.selectedChoice {
            return "\(action): \(choice)"
        }
        return action
    }

    private func formatAction(_ action: String?, buttonType: String) -> String {
        switch action {
        case "start": return "Started"
        case "end": return "Stopped"
        case "click" where buttonType == "one-time": return "Completed"
        case "click": return "Clicked"
        default: return "Clicked"
        }
    }
}

struct EmptyDayView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No activity on this day")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Start clicking buttons to see your daily activity here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        DiaryView()
            .environmentObject(AppState())
    }
}
