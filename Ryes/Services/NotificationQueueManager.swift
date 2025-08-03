import Foundation
import UserNotifications
import CoreData

/// Manages the notification queue to ensure we stay within iOS's 64 notification limit
final class NotificationQueueManager {
    
    // MARK: - Constants
    
    /// Maximum number of notifications iOS allows
    static let maxNotifications = 64
    
    /// Number of notifications to reserve for immediate/snooze alarms
    static let reservedSlots = 4
    
    /// Maximum notifications we'll schedule for alarms
    static let maxScheduledAlarms = maxNotifications - reservedSlots
    
    // MARK: - Properties
    
    private let notificationManager = NotificationManager.shared
    private let alarmManager: AlarmPersistenceManager
    
    /// Track notification identifiers mapped to alarm IDs
    private var scheduledNotifications: [String: String] = [:] // [notificationId: alarmId]
    
    // MARK: - Initialization
    
    init(alarmManager: AlarmPersistenceManager = AlarmPersistenceManager()) {
        self.alarmManager = alarmManager
    }
    
    // MARK: - Queue Management
    
    /// Schedule all enabled alarms while respecting the notification limit
    func scheduleAllAlarmsWithLimit(completion: @escaping (Result<SchedulingReport, Error>) -> Void) {
        // First, get all currently scheduled notifications
        notificationManager.getPendingNotifications { [weak self] pendingRequests in
            guard let self = self else { return }
            
            // Clear existing alarm notifications (preserve non-alarm notifications)
            let alarmNotificationIds = pendingRequests
                .filter { $0.content.categoryIdentifier == "ALARM_CATEGORY" }
                .map { $0.identifier }
            
            self.notificationManager.cancelNotifications(identifiers: alarmNotificationIds) { _ in
                // Now schedule alarms based on priority
                self.scheduleAlarmsBasedOnPriority(completion: completion)
            }
        }
    }
    
    /// Add a single alarm to the queue
    func addAlarmToQueue(_ alarm: Alarm, completion: @escaping (Result<Void, Error>) -> Void) {
        notificationManager.getPendingNotifications { [weak self] pendingRequests in
            guard self != nil else { return }
            
            let alarmNotificationCount = pendingRequests
                .filter { $0.content.categoryIdentifier == "ALARM_CATEGORY" }
                .count
            
            // Check if we have room
            if alarmNotificationCount < Self.maxScheduledAlarms {
                // We have room, schedule it
                AlarmScheduler.shared.scheduleAlarm(alarm)
                completion(.success(()))
            } else {
                // No room, need to make space or reject
                completion(.failure(QueueError.queueFull))
            }
        }
    }
    
    /// Remove an alarm from the queue
    func removeAlarmFromQueue(_ alarm: Alarm, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let alarmId = alarm.id else {
            completion(.failure(QueueError.invalidAlarm))
            return
        }
        
        notificationManager.cancelAlarmNotifications(alarmId: alarmId.uuidString, completion: completion)
    }
    
    /// Get current queue status
    func getQueueStatus(completion: @escaping (QueueStatus) -> Void) {
        notificationManager.getPendingNotifications { pendingRequests in
            let alarmNotifications = pendingRequests.filter { $0.content.categoryIdentifier == "ALARM_CATEGORY" }
            let otherNotifications = pendingRequests.filter { $0.content.categoryIdentifier != "ALARM_CATEGORY" }
            
            let status = QueueStatus(
                totalNotifications: pendingRequests.count,
                alarmNotifications: alarmNotifications.count,
                otherNotifications: otherNotifications.count,
                availableSlots: Self.maxNotifications - pendingRequests.count,
                availableAlarmSlots: Self.maxScheduledAlarms - alarmNotifications.count
            )
            
            completion(status)
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleAlarmsBasedOnPriority(completion: @escaping (Result<SchedulingReport, Error>) -> Void) {
        let enabledAlarms = alarmManager.fetchEnabledAlarms()
        
        // Sort alarms by priority (next trigger time)
        let sortedAlarms = enabledAlarms.sorted { alarm1, alarm2 in
            alarm1.nextAlarmDate < alarm2.nextAlarmDate
        }
        
        var scheduled = 0
        var skipped = 0
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for (index, alarm) in sortedAlarms.enumerated() {
            // Check if we've reached the limit
            if index >= Self.maxScheduledAlarms {
                skipped += sortedAlarms.count - index
                break
            }
            
            group.enter()
            
            // Schedule based on alarm type
            if alarm.isRepeating {
                scheduleRecurringAlarmWithLimit(alarm, maxNotifications: calculateMaxNotificationsForAlarm(index: index, totalAlarms: sortedAlarms.count)) { result in
                    switch result {
                    case .success:
                        scheduled += 1
                    case .failure(let error):
                        errors.append(error)
                    }
                    group.leave()
                }
            } else {
                // Schedule single alarm
                AlarmScheduler.shared.scheduleAlarm(alarm)
                scheduled += 1
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let report = SchedulingReport(
                totalAlarms: enabledAlarms.count,
                scheduledAlarms: scheduled,
                skippedAlarms: skipped,
                errors: errors
            )
            completion(.success(report))
        }
    }
    
    private func scheduleRecurringAlarmWithLimit(_ alarm: Alarm, maxNotifications: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let alarmId = alarm.id,
              let time = alarm.time else {
            completion(.failure(QueueError.invalidAlarm))
            return
        }
        
        let repeatDays = alarm.repeatDaysSet
        var weekdaysToSchedule: Set<Int> = []
        
        // Determine which days to schedule based on priority
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        
        // First, add days in order from today
        for dayOffset in 0..<7 {
            let targetWeekday = ((today - 1 + dayOffset) % 7) + 1 // 1-7 range
            
            if repeatDays.contains(weekdayForInt(targetWeekday)) {
                weekdaysToSchedule.insert(targetWeekday)
                if weekdaysToSchedule.count >= maxNotifications {
                    break
                }
            }
        }
        
        // Schedule only the selected days
        notificationManager.scheduleRecurringAlarmNotifications(
            alarmId: alarmId.uuidString,
            time: time,
            label: alarm.label ?? "Alarm",
            repeatDays: weekdaysToSchedule,
            sound: nil,
            completion: { result in
                completion(result.map { _ in () })
            }
        )
    }
    
    private func calculateMaxNotificationsForAlarm(index: Int, totalAlarms: Int) -> Int {
        // Distribute available slots fairly among alarms
        let remainingSlots = Self.maxScheduledAlarms - index
        let remainingAlarms = totalAlarms - index
        
        // For recurring alarms, limit to ensure fair distribution
        let maxPerAlarm = max(1, remainingSlots / remainingAlarms)
        return min(maxPerAlarm, 7) // Max 7 for weekly recurring
    }
    
    private func weekdayForInt(_ weekday: Int) -> Alarm.RepeatDay {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}

// MARK: - Supporting Types

extension NotificationQueueManager {
    
    struct QueueStatus {
        let totalNotifications: Int
        let alarmNotifications: Int
        let otherNotifications: Int
        let availableSlots: Int
        let availableAlarmSlots: Int
        
        var isFull: Bool {
            availableSlots <= 0
        }
        
        var isAlarmQueueFull: Bool {
            availableAlarmSlots <= 0
        }
    }
    
    struct SchedulingReport {
        let totalAlarms: Int
        let scheduledAlarms: Int
        let skippedAlarms: Int
        let errors: [Error]
        
        var successRate: Double {
            guard totalAlarms > 0 else { return 0 }
            return Double(scheduledAlarms) / Double(totalAlarms)
        }
    }
    
    enum QueueError: LocalizedError {
        case queueFull
        case invalidAlarm
        case schedulingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .queueFull:
                return "Notification queue is full. Please disable some alarms."
            case .invalidAlarm:
                return "Invalid alarm data"
            case .schedulingFailed(let reason):
                return "Failed to schedule alarm: \(reason)"
            }
        }
    }
}