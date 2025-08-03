import SwiftUI
import AVFoundation

/// Test view for verifying ElevenLabs API integration
struct ElevenLabsTestView: View {
    @StateObject private var voiceService = VoiceSynthesisService.shared
    @State private var apiKey = ""
    @State private var testText = "Hello! This is a test of the ElevenLabs voice synthesis. The time is now \(Date().formatted(date: .omitted, time: .shortened))."
    @State private var selectedVoiceId = ""
    @State private var isLoading = false
    @State private var statusMessage = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section("API Configuration") {
                    if !voiceService.isConfigured {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter your ElevenLabs API key to test the integration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Save API Key") {
                                saveAPIKey()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(apiKey.isEmpty)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key Configured")
                            Spacer()
                            Button("Remove") {
                                voiceService.removeAPIKey()
                                apiKey = ""
                                selectedVoiceId = ""
                                statusMessage = "API key removed"
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Account Info Section
                if let userInfo = voiceService.userInfo {
                    Section("Account Status") {
                        LabeledContent("Tier", value: userInfo.subscription.tier.capitalized)
                        LabeledContent("Characters Used", value: "\(userInfo.subscription.characterCount) / \(userInfo.subscription.characterLimit)")
                        LabeledContent("Characters Remaining", value: "\(userInfo.subscription.remainingCharacters)")
                        
                        if userInfo.subscription.isNearQuotaLimit {
                            Label("Near quota limit", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Voice Selection Section
                if voiceService.isConfigured && !voiceService.availableVoices.isEmpty {
                    Section("Voice Selection") {
                        Picker("Select Voice", selection: $selectedVoiceId) {
                            Text("Select a voice").tag("")
                            ForEach(voiceService.availableVoices) { voice in
                                Text(voice.name).tag(voice.voiceId)
                            }
                        }
                        
                        if !selectedVoiceId.isEmpty {
                            if let voice = voiceService.getVoice(by: selectedVoiceId) {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let category = voice.category {
                                        Text("Category: \(category)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let description = voice.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Test Text Section
                if voiceService.isConfigured {
                    Section("Test Text") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter text to synthesize (max 5000 characters)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $testText)
                                .frame(minHeight: 100)
                            
                            Text("\(testText.count) / 5000 characters")
                                .font(.caption)
                                .foregroundColor(testText.count > 5000 ? .red : .secondary)
                        }
                    }
                }
                
                // Test Actions Section
                if voiceService.isConfigured {
                    Section("Test Actions") {
                        Button(action: loadVoices) {
                            Label("Load Available Voices", systemImage: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                        
                        Button(action: testSynthesis) {
                            Label("Test Voice Synthesis", systemImage: "speaker.wave.2")
                        }
                        .disabled(selectedVoiceId.isEmpty || testText.isEmpty || isLoading || testText.count > 5000)
                        
                        Button(action: testDefaultVoice) {
                            Label("Test Default Alarm Voice", systemImage: "alarm")
                        }
                        .disabled(isLoading || testText.isEmpty || testText.count > 5000)
                    }
                }
                
                // Status Section
                if !statusMessage.isEmpty {
                    Section("Status") {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(statusMessage)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Error Display
                if let error = voiceService.lastError {
                    Section("Error") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                            
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ElevenLabs Test")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if voiceService.isConfigured {
                    loadInitialData()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isLoading = true
        statusMessage = "Saving API key..."
        
        let success = voiceService.setupAPIKey(apiKey)
        
        if success {
            statusMessage = "API key saved successfully!"
            loadInitialData()
        } else {
            statusMessage = "Failed to save API key"
            alertTitle = "Error"
            alertMessage = "Failed to save API key to keychain"
            showingAlert = true
        }
        
        isLoading = false
    }
    
    private func loadInitialData() {
        Task {
            isLoading = true
            statusMessage = "Loading account info and voices..."
            
            await voiceService.loadUserInfo()
            await voiceService.loadVoices()
            
            if !voiceService.availableVoices.isEmpty && selectedVoiceId.isEmpty {
                selectedVoiceId = voiceService.availableVoices.first?.voiceId ?? ""
            }
            
            isLoading = false
            statusMessage = "Loaded \(voiceService.availableVoices.count) voices"
        }
    }
    
    private func loadVoices() {
        Task {
            isLoading = true
            statusMessage = "Loading voices..."
            
            await voiceService.loadVoices()
            
            isLoading = false
            statusMessage = "Loaded \(voiceService.availableVoices.count) voices"
            
            if voiceService.availableVoices.isEmpty {
                alertTitle = "No Voices"
                alertMessage = "No voices were found. Please check your API key and subscription."
                showingAlert = true
            }
        }
    }
    
    private func testSynthesis() {
        guard !selectedVoiceId.isEmpty else { return }
        
        Task {
            isLoading = true
            statusMessage = "Synthesizing speech..."
            
            let success = await voiceService.synthesizeAndPlay(
                text: testText,
                voiceId: selectedVoiceId
            )
            
            isLoading = false
            
            if success {
                statusMessage = "✓ Audio playing successfully!"
            } else {
                statusMessage = "✗ Failed to synthesize or play audio"
                
                if let error = voiceService.lastError {
                    alertTitle = "Synthesis Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func testDefaultVoice() {
        Task {
            isLoading = true
            statusMessage = "Testing default alarm voice..."
            
            let defaultVoiceId = VoiceSynthesisService.defaultVoices.alarm
            
            let success = await voiceService.synthesizeAndPlay(
                text: testText,
                voiceId: defaultVoiceId,
                voiceSettings: .alarmOptimized
            )
            
            isLoading = false
            
            if success {
                statusMessage = "✓ Default alarm voice working!"
            } else {
                statusMessage = "✗ Default voice test failed"
                
                if let error = voiceService.lastError {
                    alertTitle = "Default Voice Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ElevenLabsTestView()
}