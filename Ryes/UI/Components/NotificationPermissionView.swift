import SwiftUI

struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Icon
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.ryesPrimary)
                .padding(.top, Spacing.extraLarge)
            
            // Title
            Text("Notifications Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ryesForeground)
            
            // Description
            Text("To wake you up, Ryes needs permission to send notifications. Please enable notifications in Settings.")
                .font(.body)
                .foregroundColor(.ryesForegroundSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.medium)
            
            Spacer()
            
            // Buttons
            VStack(spacing: Spacing.medium) {
                RyesButton(
                    title: "Open Settings",
                    style: .primary,
                    fullWidth: true
                ) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                
                RyesButton(
                    title: "Cancel",
                    style: .secondary,
                    fullWidth: true
                ) {
                    dismiss()
                }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.bottom, Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ryesBackground)
    }
}