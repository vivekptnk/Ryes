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
    
    // MARK: - Helper Methods
    
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