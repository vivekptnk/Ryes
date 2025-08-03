import SwiftUI

struct SettingsView: View {
    @State private var showAPIKeyTest = false
    @State private var testAPIKey = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Notification Queue Status
                Section {
                    NotificationQueueStatusView()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                
                Section("General") {
                    NavigationLink(destination: Text("Notifications Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: Text("Sleep Tracking Settings")) {
                        Label("Sleep Tracking", systemImage: "bed.double")
                    }
                    
                    NavigationLink(destination: Text("Voice Synthesis Settings - Coming Soon")) {
                        Label("Voice Synthesis", systemImage: "speaker.wave.2")
                    }
                    
                    NavigationLink(destination: ElevenLabsTestView()) {
                        Label("Test ElevenLabs Integration", systemImage: "waveform")
                    }
                }
                
                Section("Account") {
                    NavigationLink(destination: Text("Subscription")) {
                        Label("Subscription", systemImage: "crown")
                    }
                    
                    NavigationLink(destination: Text("Privacy Settings")) {
                        Label("Privacy", systemImage: "lock")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Support")) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}