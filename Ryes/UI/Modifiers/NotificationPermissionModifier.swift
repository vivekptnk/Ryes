import SwiftUI

struct NotificationPermissionModifier: ViewModifier {
    @State private var showPermissionAlert = false
    @State private var showSettingsAlert = false
    @State private var hasRequestedPermission = UserDefaults.standard.bool(forKey: "hasRequestedNotificationPermission")
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                checkNotificationPermission()
            }
            .alert("Enable Notifications", isPresented: $showPermissionAlert) {
                Button("Enable") {
                    requestNotificationPermission()
                }
                Button("Not Now", role: .cancel) {
                    UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
                }
            } message: {
                Text("Ryes needs notification permissions to wake you up with alarms. You can always change this in Settings.")
            }
            .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To use alarms, please enable notifications for Ryes in Settings.")
            }
    }
    
    private func checkNotificationPermission() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
            case .notDetermined:
                if !hasRequestedPermission {
                    showPermissionAlert = true
                }
            case .denied:
                // Don't show immediately on appear, only when user tries to create alarm
                break
            case .authorized, .provisional, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted, error in
            UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
            
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            
            if !granted {
                // User denied permission
                showSettingsAlert = true
            }
        }
    }
}

extension View {
    func notificationPermission() -> some View {
        modifier(NotificationPermissionModifier())
    }
}