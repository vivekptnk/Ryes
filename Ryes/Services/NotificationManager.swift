import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request authorization for notifications including critical alerts
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [
            .alert,
            .sound,
            .badge,
            .criticalAlert // Requires special entitlement from Apple
        ]
        
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.authorizationStatus = .authorized
                } else {
                    self?.authorizationStatus = .denied
                }
                completion(granted, error)
            }
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                completion?(settings.authorizationStatus)
            }
        }
    }
    
    /// Check if notifications are authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    /// Check if critical alerts are authorized
    func checkCriticalAlertAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.criticalAlertSetting == .enabled)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule a notification for a single alarm
    func scheduleAlarmNotification(
        alarmId: String,
        time: Date,
        label: String,
        sound: UNNotificationSound? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let content = createNotificationContent(label: label, sound: sound)
        let trigger = createCalendarTrigger(from: time, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alarmId,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Schedule notifications for a recurring alarm
    func scheduleRecurringAlarmNotifications(
        alarmId: String,
        time: Date,
        label: String,
        repeatDays: Set<Int>, // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        sound: UNNotificationSound? = nil,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        var scheduledIdentifiers: [String] = []
        let group = DispatchGroup()
        var firstError: Error?
        
        for weekday in repeatDays {
            let identifier = "\(alarmId)-\(weekday)"
            group.enter()
            
            let content = createNotificationContent(label: label, sound: sound)
            let trigger = createWeekdayTrigger(from: time, weekday: weekday)
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    firstError = firstError ?? error
                } else {
                    scheduledIdentifiers.append(identifier)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = firstError {
                // If any notification failed to schedule, remove the ones that succeeded
                self.cancelNotifications(identifiers: scheduledIdentifiers) { _ in
                    completion(.failure(error))
                }
            } else {
                completion(.success(scheduledIdentifiers))
            }
        }
    }
    
    /// Cancel notifications for specific identifiers
    func cancelNotifications(identifiers: [String], completion: ((Result<Void, Error>) -> Void)? = nil) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        DispatchQueue.main.async {
            completion?(.success(()))
        }
    }
    
    /// Cancel all notifications for an alarm
    func cancelAlarmNotifications(alarmId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let identifiersToRemove = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(alarmId) }
            
            self?.cancelNotifications(identifiers: identifiersToRemove, completion: completion)
        }
    }
    
    /// Get all pending notification requests
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create notification content
    private func createNotificationContent(label: String, sound: UNNotificationSound?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = label.isEmpty ? "Time to wake up!" : label
        content.sound = sound ?? .defaultCritical // Use critical sound for alarms
        content.interruptionLevel = .critical // For critical alerts when available
        content.relevanceScore = 1.0 // Highest relevance for alarms
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        return content
    }
    
    /// Create critical alert notification content specifically for urgent alarms
    func createCriticalAlarmNotification(
        alarmId: String,
        label: String,
        time: Date,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let identifier = "\(alarmId)-critical"
        let content = UNMutableNotificationContent()
        
        content.title = "🚨 ALARM"
        content.body = label.isEmpty ? "WAKE UP! Critical alarm activated!" : "WAKE UP! \(label)"
        content.sound = .defaultCritical // Critical alert sound that bypasses Do Not Disturb
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Create trigger for immediate delivery or specific time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(identifier))
                }
            }
        }
    }
    
    /// Create a calendar-based trigger for a specific time
    private func createCalendarTrigger(from date: Date, repeats: Bool) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    }
    
    /// Create a weekday-based trigger for recurring alarms
    private func createWeekdayTrigger(from date: Date, weekday: Int) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: date)
        components.weekday = weekday
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }
    
    /// Handle authorization denied state by guiding user to settings
    func handleAuthorizationDenied() {
        // This method can be called to show an alert guiding users to settings
        // The actual UI implementation will be in the view layer
    }
    
    /// Get detailed notification settings
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // For alarms, we want to show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification actions here (will be implemented in Task 4.5)
        completionHandler()
    }
}