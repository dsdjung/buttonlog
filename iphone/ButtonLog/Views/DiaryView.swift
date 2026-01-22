import SwiftUI

struct DiaryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    // For this implementation, we'll show a simulated diary view
    // In a real app, this would fetch diary data from the API
    
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
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Daily summary card
                    DailySummaryCard(date: selectedDate, buttons: appState.buttons)
                    
                    // Button activities for the day
                    ForEach(getButtonsWithActivity(for: selectedDate)) { button in
                        ButtonActivityCard(button: button, date: selectedDate)
                    }
                    
                    if getButtonsWithActivity(for: selectedDate).isEmpty {
                        EmptyDayView(date: selectedDate)
                    }
                }
                .padding()
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
            await appState.loadButtons()
        }
    }
    
    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        guard !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func getButtonsWithActivity(for date: Date) -> [ButtonLog.Button] {
        // In a real app, this would filter buttons based on actual activity data
        // For now, we'll simulate some activity
        return appState.buttons.prefix(3).map { $0 }
    }
}

struct DailySummaryCard: View {
    let date: Date
    let buttons: [ButtonLog.Button]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                SummaryItem(
                    title: "Total Clicks",
                    value: "12", // Simulated data
                    icon: "hand.tap.fill",
                    color: .blue
                )
                
                Spacer()
                
                SummaryItem(
                    title: "Active Buttons",
                    value: "\(buttons.filter { $0.currentState == .active }.count)",
                    icon: "power",
                    color: .green
                )
                
                Spacer()
                
                SummaryItem(
                    title: "Streak",
                    value: "7 days", // Simulated data
                    icon: "flame.fill",
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
    let button: ButtonLog.Button
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Button header
            HStack {
                ZStack {
                    Circle()
                        .fill(button.uiColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: iconForButton(button.icon))
                        .foregroundColor(.white)
                        .font(.callout)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(button.name)
                        .font(.headline)
                    
                    Text("\(simulatedClickCount()) clicks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(button.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Activity timeline
            VStack(alignment: .leading, spacing: 8) {
                ForEach(generateSimulatedActivity(), id: \.time) { activity in
                    ActivityTimelineItem(activity: activity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func simulatedClickCount() -> Int {
        return Int.random(in: 1...8)
    }
    
    private func generateSimulatedActivity() -> [ActivityItem] {
        let times = ["9:15 AM", "12:30 PM", "3:45 PM", "7:20 PM"]
        return times.prefix(min(simulatedClickCount(), 4)).map { time in
            ActivityItem(time: time, action: simulatedAction())
        }
    }
    
    private func simulatedAction() -> String {
        switch button.type {
        case .instant:
            return "Clicked"
        case .timed:
            return ["Started", "Stopped"].randomElement() ?? "Clicked"
        case .state:
            return ["Activated", "Deactivated"].randomElement() ?? "Toggled"
        case .oneTime:
            return "Completed"
        }
    }
    
    private func iconForButton(_ icon: String) -> String {
        let iconMap: [String: String] = [
            "star": "star.fill",
            "heart": "heart.fill",
            "bolt": "bolt.fill"
            // ... add more mappings as needed
        ]
        return iconMap[icon] ?? "star.fill"
    }
}

struct ActivityItem {
    let time: String
    let action: String
}

struct ActivityTimelineItem: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            Text(activity.time)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(activity.action)
                .font(.subheadline)
            
            Spacer()
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