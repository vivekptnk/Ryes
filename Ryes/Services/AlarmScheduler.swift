import Foundation
import UserNotifications
import CoreData

/// Service responsible for scheduling alarm notifications
final class AlarmScheduler: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = AlarmScheduler()
    private let notificationManager = NotificationManager.shared
    private let alarmManager: AlarmPersistenceManager
    private let queueManager: NotificationQueueManager
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    
    private init(alarmManager: AlarmPersistenceManager = AlarmPersistenceManager()) {
        self.alarmManager = alarmManager
        self.queueManager = NotificationQueueManager(alarmManager: alarmManager)
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationManager.requestAuthorization { [weak self] granted, error in
            if let error = error {
                print("Failed to request notification authorization: \(error)")
            }
            self?.checkAuthorizationStatus()
            completion(granted)
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationManager.checkAuthorizationStatus { [weak self] status in
            self?.authorizationStatus = status
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule all enabled alarms with queue management
    func scheduleAllAlarms() {
        queueManager.scheduleAllAlarmsWithLimit { [weak self] result in
            switch result {
            case .success(let report):
                print("Scheduled \(report.scheduledAlarms) of \(report.totalAlarms) alarms")
                if report.skippedAlarms > 0 {
                    print("Warning: \(report.skippedAlarms) alarms were skipped due to notification limit")
                }
                
                // Notify background audio service about alarm state change
                if report.scheduledAlarms > 0 {
                    BackgroundAudioService.shared.handleAlarmsEnabled()
                } else {
                    BackgroundAudioService.shared.handleAlarmsDisabled()
                }
                
            case .failure(let error):
                print("Failed to schedule alarms: \(error)")
                self?.scheduleAllAlarmsLegacy() // Fallback to legacy method
            }
        }
    }
    
    /// Legacy scheduling method without queue management
    private func scheduleAllAlarmsLegacy() {
        // Cancel all existing notifications
        cancelAllScheduledAlarms()
        
        // Get all enabled alarms
        let enabledAlarms = alarmManager.fetchEnabledAlarms()
        
        // Schedule each alarm
        for alarm in enabledAlarms {
            scheduleAlarm(alarm)
        }
    }
    
    /// Schedule a single alarm
    func scheduleAlarm(_ alarm: Alarm) {
        guard alarm.isEnabled,
              let alarmId = alarm.id,
              let time = alarm.time else { return }
        
        let label = alarm.label ?? "Alarm"
        let sound = createNotificationSound(for: alarm)
        
        if alarm.isRepeating {
            // Schedule repeating alarms
            scheduleRepeatingAlarm(alarm)
        } else {
            // Schedule one-time alarm
            notificationManager.scheduleAlarmNotification(
                alarmId: alarmId.uuidString,
                time: time,
                label: label,
                sound: sound
            ) { result in
                switch result {
                case .success:
                    print("Scheduled one-time alarm for \(time)")
                case .failure(let error):
                    print("Failed to schedule alarm: \(error)")
                }
            }
        }
    }
    
    /// Reschedule a specific alarm
    func rescheduleAlarm(_ alarm: Alarm) {
        // Cancel existing notifications for this alarm
        cancelScheduledAlarm(alarm)
        
        // Schedule if enabled
        if alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }
    
    /// Cancel all scheduled alarms
    func cancelAllScheduledAlarms() {
        notificationManager.getPendingNotifications { requests in
            let identifiers = requests.map { $0.identifier }
            self.notificationManager.cancelNotifications(identifiers: identifiers)
            
            // Notify background audio service that all alarms are cancelled
            BackgroundAudioService.shared.handleAlarmsDisabled()
        }
    }
    
    /// Cancel a specific alarm
    func cancelScheduledAlarm(_ alarm: Alarm) {
        guard let alarmId = alarm.id else { return }
        
        notificationManager.cancelAlarmNotifications(alarmId: alarmId.uuidString) { result in
            switch result {
            case .success:
                print("Cancelled notifications for alarm \(alarmId.uuidString)")
            case .failure(let error):
                print("Failed to cancel notifications: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createNotificationSound(for alarm: Alarm) -> UNNotificationSound {
        // TODO: Add custom sound support based on alarm settings
        return .defaultCritical
    }
    
    private func scheduleRepeatingAlarm(_ alarm: Alarm) {
        guard let alarmId = alarm.id,
              let time = alarm.time else { return }
        
        let label = alarm.label ?? "Alarm"
        let sound = createNotificationSound(for: alarm)
        let repeatDays = weekdaysFromRepeatDaySet(alarm.repeatDaysSet)
        
        notificationManager.scheduleRecurringAlarmNotifications(
            alarmId: alarmId.uuidString,
            time: time,
            label: label,
            repeatDays: Set(repeatDays),
            sound: sound
        ) { result in
            switch result {
            case .success(let identifiers):
                print("Scheduled recurring alarm with \(identifiers.count) notifications")
            case .failure(let error):
                print("Failed to schedule recurring alarm: \(error)")
            }
        }
    }
    
    private func weekdaysFromRepeatDaySet(_ repeatDaySet: Alarm.RepeatDay) -> Set<Int> {
        var weekdays = Set<Int>()
        
        if repeatDaySet.contains(.sunday) { weekdays.insert(1) }
        if repeatDaySet.contains(.monday) { weekdays.insert(2) }
        if repeatDaySet.contains(.tuesday) { weekdays.insert(3) }
        if repeatDaySet.contains(.wednesday) { weekdays.insert(4) }
        if repeatDaySet.contains(.thursday) { weekdays.insert(5) }
        if repeatDaySet.contains(.friday) { weekdays.insert(6) }
        if repeatDaySet.contains(.saturday) { weekdays.insert(7) }
        
        return weekdays
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
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Debug Methods
    
    /// Get all pending notifications (for debugging)
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationManager.getPendingNotifications(completion: completion)
    }
    
    /// Print all scheduled alarms (for debugging)
    func printScheduledAlarms() {
        getPendingNotifications { requests in
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
    
    /// Get current notification queue status
    func getQueueStatus(completion: @escaping (NotificationQueueManager.QueueStatus) -> Void) {
        queueManager.getQueueStatus(completion: completion)
    }
    
    /// Check if we can schedule more alarms
    func canScheduleMoreAlarms(completion: @escaping (Bool) -> Void) {
        queueManager.getQueueStatus { status in
            completion(!status.isAlarmQueueFull)
        }
    }
}

// MARK: - AlarmPersistenceManager Extension

extension AlarmPersistenceManager {
    /// Update alarm and reschedule notifications
    func updateAlarmWithScheduling(_ alarm: Alarm) {
        updateAlarm(alarm)
        AlarmScheduler.shared.rescheduleAlarm(alarm)
    }
    
    /// Delete alarm and cancel notifications
    func deleteAlarmWithScheduling(_ alarm: Alarm) {
        AlarmScheduler.shared.cancelScheduledAlarm(alarm)
        deleteAlarm(alarm)
    }
    
    /// Toggle alarm and update scheduling
    func toggleAlarmWithScheduling(_ alarm: Alarm) {
        toggleAlarm(alarm)
        AlarmScheduler.shared.rescheduleAlarm(alarm)
    }
}