import Foundation
import UserNotifications
import CoreData

/// Service responsible for scheduling alarm notifications
final class AlarmScheduler: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = AlarmScheduler()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let alarmManager: AlarmPersistenceManager
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    
    private init(alarmManager: AlarmPersistenceManager = AlarmPersistenceManager()) {
        self.alarmManager = alarmManager
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    @MainActor
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule all enabled alarms
    func scheduleAllAlarms() async {
        // Cancel all existing notifications
        await cancelAllScheduledAlarms()
        
        // Get all enabled alarms
        let enabledAlarms = alarmManager.fetchEnabledAlarms()
        
        // Schedule each alarm
        for alarm in enabledAlarms {
            await scheduleAlarm(alarm)
        }
    }
    
    /// Schedule a single alarm
    func scheduleAlarm(_ alarm: Alarm) async {
        guard alarm.isEnabled else { return }
        
        // Create notification content
        let content = createNotificationContent(for: alarm)
        
        if alarm.isRepeating {
            // Schedule repeating alarms
            await scheduleRepeatingAlarm(alarm, content: content)
        } else {
            // Schedule one-time alarm
            await scheduleOneTimeAlarm(alarm, content: content)
        }
    }
    
    /// Reschedule a specific alarm
    func rescheduleAlarm(_ alarm: Alarm) async {
        // Cancel existing notifications for this alarm
        await cancelScheduledAlarm(alarm)
        
        // Schedule if enabled
        if alarm.isEnabled {
            await scheduleAlarm(alarm)
        }
    }
    
    /// Cancel all scheduled alarms
    func cancelAllScheduledAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Cancel a specific alarm
    func cancelScheduledAlarm(_ alarm: Alarm) async {
        guard let alarmId = alarm.id else { return }
        
        // For repeating alarms, we need to cancel all 7 possible notifications
        if alarm.isRepeating {
            for day in 1...7 {
                let identifier = "\(alarmId.uuidString)-\(day)"
                notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        } else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarmId.uuidString])
        }
    }
    
    // MARK: - Private Methods
    
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Title and body
        content.title = "Alarm"
        if let label = alarm.label, !label.isEmpty {
            content.subtitle = label
        }
        content.body = "Time to wake up!"
        
        // Sound
        content.sound = .defaultCritical
        
        // Badge
        content.badge = 1
        
        // User info for handling
        content.userInfo = [
            "alarmId": alarm.id?.uuidString ?? "",
            "dismissalType": alarm.dismissalType ?? "standard"
        ]
        
        // Category for actions
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Critical alert if available
        if authorizationStatus == .authorized {
            content.interruptionLevel = .critical
        }
        
        return content
    }
    
    private func scheduleOneTimeAlarm(_ alarm: Alarm, content: UNMutableNotificationContent) async {
        guard let alarmId = alarm.id,
              alarm.time != nil else { return }
        
        let nextDate = alarm.nextAlarmDate
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: alarmId.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled one-time alarm for \(nextDate)")
        } catch {
            print("Failed to schedule alarm: \(error)")
        }
    }
    
    private func scheduleRepeatingAlarm(_ alarm: Alarm, content: UNMutableNotificationContent) async {
        guard let alarmId = alarm.id,
              let alarmTime = alarm.time else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)
        
        // Schedule for each selected day
        let repeatDays = alarm.repeatDaysSet
        
        if repeatDays.contains(.sunday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 1, timeComponents: timeComponents)
        }
        if repeatDays.contains(.monday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 2, timeComponents: timeComponents)
        }
        if repeatDays.contains(.tuesday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 3, timeComponents: timeComponents)
        }
        if repeatDays.contains(.wednesday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 4, timeComponents: timeComponents)
        }
        if repeatDays.contains(.thursday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 5, timeComponents: timeComponents)
        }
        if repeatDays.contains(.friday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 6, timeComponents: timeComponents)
        }
        if repeatDays.contains(.saturday) {
            await scheduleDayAlarm(alarmId: alarmId, content: content, weekday: 7, timeComponents: timeComponents)
        }
    }
    
    private func scheduleDayAlarm(alarmId: UUID, content: UNMutableNotificationContent, weekday: Int, timeComponents: DateComponents) async {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let identifier = "\(alarmId.uuidString)-\(weekday)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled repeating alarm for weekday \(weekday)")
        } catch {
            print("Failed to schedule repeating alarm: \(error)")
        }
    }
    
    // MARK: - Notification Actions
    
    /// Setup notification categories and actions
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    // MARK: - Debug Methods
    
    /// Get all pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    /// Print all scheduled alarms (for debugging)
    func printScheduledAlarms() async {
        let requests = await getPendingNotifications()
        print("=== Scheduled Alarms ===")
        for request in requests {
            print("ID: \(request.identifier)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("Date: \(trigger.dateComponents)")
                print("Repeats: \(trigger.repeats)")
            }
            print("---")
        }
    }
}

// MARK: - AlarmPersistenceManager Extension

extension AlarmPersistenceManager {
    /// Update alarm and reschedule notifications
    func updateAlarmWithScheduling(_ alarm: Alarm) {
        updateAlarm(alarm)
        
        Task {
            await AlarmScheduler.shared.rescheduleAlarm(alarm)
        }
    }
    
    /// Delete alarm and cancel notifications
    func deleteAlarmWithScheduling(_ alarm: Alarm) {
        Task {
            await AlarmScheduler.shared.cancelScheduledAlarm(alarm)
        }
        
        deleteAlarm(alarm)
    }
    
    /// Toggle alarm and update scheduling
    func toggleAlarmWithScheduling(_ alarm: Alarm) {
        toggleAlarm(alarm)
        
        Task {
            await AlarmScheduler.shared.rescheduleAlarm(alarm)
        }
    }
}