import SwiftUI

struct NotificationQueueStatusView: View {
    @State private var queueStatus: NotificationQueueManager.QueueStatus?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: RyesSpacing.small) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.ryesPrimary)
                Text("Notification Queue")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let status = queueStatus {
                VStack(alignment: .leading, spacing: RyesSpacing.xSmall) {
                    StatusRow(
                        label: "Alarm Notifications",
                        value: "\(status.alarmNotifications)/\(NotificationQueueManager.maxScheduledAlarms)",
                        percentage: Double(status.alarmNotifications) / Double(NotificationQueueManager.maxScheduledAlarms)
                    )
                    
                    StatusRow(
                        label: "Total Notifications",
                        value: "\(status.totalNotifications)/\(NotificationQueueManager.maxNotifications)",
                        percentage: Double(status.totalNotifications) / Double(NotificationQueueManager.maxNotifications)
                    )
                    
                    if status.isAlarmQueueFull {
                        Label("Queue is full", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.ryesWarning)
                            .padding(.top, RyesSpacing.xxSmall)
                    }
                }
            }
        }
        .padding(RyesSpacing.medium)
        .background(Color.ryesBackgroundSecondary)
        .cornerRadius(RyesCornerRadius.medium)
        .onAppear {
            loadQueueStatus()
        }
    }
    
    private func loadQueueStatus() {
        isLoading = true
        AlarmScheduler.shared.getQueueStatus { status in
            self.queueStatus = status
            self.isLoading = false
        }
    }
}

private struct StatusRow: View {
    let label: String
    let value: String
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: RyesSpacing.xxSmall) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.ryesForegroundSecondary)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var color: Color {
        if percentage >= 0.9 {
            return .ryesError
        } else if percentage >= 0.75 {
            return .ryesWarning
        } else {
            return .ryesSuccess
        }
    }
}

#Preview {
    NotificationQueueStatusView()
        .padding()
        .background(Color.ryesBackground)
}