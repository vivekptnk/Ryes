import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AlarmsListView()
                .tabItem {
                    Label("Alarms", systemImage: "alarm")
                }
            
            VoiceProfilesView()
                .tabItem {
                    Label("Voices", systemImage: "mic")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.ryesPrimary)
        .notificationPermission()
    }
}

#Preview {
    MainTabView()
}