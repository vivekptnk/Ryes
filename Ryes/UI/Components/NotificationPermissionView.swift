import SwiftUI

struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: RyesSpacing.large) {
            // Icon
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.ryesPrimary)
                .padding(.top, RyesSpacing.xLarge)
            
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
                .padding(.horizontal, RyesSpacing.medium)
            
            Spacer()
            
            // Buttons
            VStack(spacing: RyesSpacing.medium) {
                RyesButton(
                    "Open Settings",
                    style: .primary
                ) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                
                RyesButton(
                    "Cancel",
                    style: .secondary
                ) {
                    dismiss()
                }
            }
            .padding(.horizontal, RyesSpacing.large)
            .padding(.bottom, RyesSpacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ryesBackground)
    }
}