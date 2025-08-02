import SwiftUI

struct VoiceProfilesView: View {
    @State private var voiceProfiles: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                if voiceProfiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mic")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Voice Profiles")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create a voice profile to personalize your wake-up experience")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List(voiceProfiles, id: \.self) { profile in
                        Text(profile)
                    }
                }
            }
            .navigationTitle("Voice Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Navigate to voice profile creation
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    VoiceProfilesView()
}