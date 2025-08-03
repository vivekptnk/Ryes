import SwiftUI

/// Settings view for ElevenLabs API configuration
/// Allows users to configure their API key and test voice synthesis
struct ElevenLabsSettingsView: View {
    
    @StateObject private var voiceService = VoiceSynthesisService.shared
    @State private var apiKey: String = ""
    @State private var isShowingAPIKeyInput = false
    @State private var testVoiceId: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTestingVoice = false
    
    var body: some View {
        NavigationStack {
            Form {
                // API Configuration Section
                Section("API Configuration") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ElevenLabs API Key")
                                .font(.headline)
                            Text(voiceService.isConfigured ? "✓ Configured" : "Not configured")
                                .font(.caption)
                                .foregroundColor(voiceService.isConfigured ? .green : .orange)
                        }
                        
                        Spacer()
                        
                        Button(voiceService.isConfigured ? "Update" : "Configure") {
                            isShowingAPIKeyInput = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if voiceService.isConfigured {
                        Button("Remove API Key", role: .destructive) {
                            voiceService.removeAPIKey()
                        }
                    }
                }
                
                // Account Information Section
                if voiceService.isConfigured {
                    Section("Account Information") {
                        if let userInfo = voiceService.userInfo {
                            AccountInfoView(userInfo: userInfo)
                        } else {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading account information...")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Voice Testing Section
                    Section("Voice Testing") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test voice synthesis with available voices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !voiceService.availableVoices.isEmpty {
                                Picker("Test Voice", selection: $testVoiceId) {
                                    ForEach(voiceService.availableVoices) { voice in
                                        Text(voice.name).tag(voice.voiceId)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Button(action: testSelectedVoice) {
                                    HStack {
                                        if isTestingVoice {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "speaker.wave.2")
                                        }
                                        Text("Test Voice")
                                    }
                                }
                                .disabled(testVoiceId.isEmpty || isTestingVoice)
                                .buttonStyle(.borderedProminent)
                            } else {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading available voices...")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Error Display
                if let error = voiceService.lastError {
                    Section("Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Error", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.headline)
                            
                            Text(error.localizedDescription)
                                .font(.body)
                            
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Clear Error") {
                                voiceService.clearError()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Voice Synthesis")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingAPIKeyInput) {
                APIKeyInputView(
                    apiKey: $apiKey,
                    isPresented: $isShowingAPIKeyInput,
                    onSave: { key in
                        let success = voiceService.setupAPIKey(key)
                        if success {
                            alertMessage = "API key configured successfully!"
                        } else {
                            alertMessage = "Failed to store API key. Please try again."
                        }
                        showingAlert = true
                    }
                )
            }
            .alert("API Key Configuration", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                if voiceService.isConfigured {
                    await voiceService.loadVoices()
                    await voiceService.loadUserInfo()
                    
                    // Set default test voice
                    if testVoiceId.isEmpty && !voiceService.availableVoices.isEmpty {
                        testVoiceId = voiceService.availableVoices.first?.voiceId ?? ""
                    }
                }
            }
        }
    }
    
    private func testSelectedVoice() {
        guard !testVoiceId.isEmpty else { return }
        
        isTestingVoice = true
        
        Task {
            let success = await voiceService.testVoice(testVoiceId)
            
            await MainActor.run {
                isTestingVoice = false
                if !success {
                    alertMessage = "Voice test failed. Please check your network connection and try again."
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Binding var apiKey: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    
    @State private var inputText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enter your ElevenLabs API key to enable voice synthesis features.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        SecureField("API Key", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textContentType(.password)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to get your API key:")
                                .font(.headline)
                            
                            Text("1. Visit elevenlabs.io and create an account")
                            Text("2. Go to Profile Settings")
                            Text("3. Copy your API key from the API section")
                            Text("4. Paste it above")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("API Key Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(inputText)
                        isPresented = false
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            inputText = apiKey
        }
    }
}

// MARK: - Account Info View

struct AccountInfoView: View {
    let userInfo: UserResponse
    
    var body: some View {
        VStack(spacing: 12) {
            // Subscription Tier
            HStack {
                Text("Subscription Tier")
                    .font(.headline)
                Spacer()
                Text(userInfo.subscription.tier.capitalized)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Character Usage
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Character Usage")
                        .font(.headline)
                    Spacer()
                    Text("\(userInfo.subscription.characterCount) / \(userInfo.subscription.characterLimit)")
                        .font(.body)
                        .foregroundColor(userInfo.subscription.isNearQuotaLimit ? .orange : .secondary)
                }
                
                ProgressView(value: userInfo.subscription.usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                
                HStack {
                    Text("\(userInfo.subscription.remainingCharacters) characters remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Resets \(userInfo.subscription.resetDate, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quota Warning
            if userInfo.subscription.isNearQuotaLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Approaching character limit")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var progressColor: Color {
        let usage = userInfo.subscription.usagePercentage
        if usage > 0.9 {
            return .red
        } else if usage > 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    ElevenLabsSettingsView()
}