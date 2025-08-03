import Foundation
import AVFoundation
import Combine

/// High-level service for voice synthesis and management
/// Provides a clean API for text-to-speech conversion and voice profile management
class VoiceSynthesisService: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = VoiceSynthesisService()
    
    private var apiClient: ElevenLabsAPIClient?
    private let keychainManager = KeychainManager.shared
    
    /// Published properties for UI binding
    @Published var isConfigured: Bool = false
    @Published var availableVoices: [Voice] = []
    @Published var userInfo: UserResponse?
    @Published var isLoading: Bool = false
    @Published var lastError: ElevenLabsError?
    
    /// Audio player for immediate playback
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Initialization
    
    private init() {
        checkConfiguration()
        configureAudioSession()
    }
    
    /// Gets or creates the API client
    private func getAPIClient() -> ElevenLabsAPIClient {
        if let client = apiClient {
            return client
        }
        let client = ElevenLabsAPIClient()
        apiClient = client
        return client
    }
    
    // MARK: - Configuration
    
    /// Checks if the service is properly configured with an API key
    private func checkConfiguration() {
        isConfigured = keychainManager.hasElevenLabsAPIKey()
    }
    
    /// Configures the audio session for voice playback
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
            )
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    /// Sets up the ElevenLabs API key
    /// - Parameter apiKey: The API key to store
    /// - Returns: True if setup was successful
    func setupAPIKey(_ apiKey: String) -> Bool {
        let success = keychainManager.storeElevenLabsAPIKey(apiKey)
        if success {
            isConfigured = true
            // Don't load data immediately - let the UI trigger it
        }
        return success
    }
    
    /// Removes the API key and resets the service
    func removeAPIKey() {
        _ = keychainManager.deleteElevenLabsAPIKey()
        isConfigured = false
        availableVoices = []
        userInfo = nil
        lastError = nil
    }
    
    // MARK: - Text-to-Speech
    
    /// Converts text to speech and returns audio data
    /// - Parameters:
    ///   - text: Text to convert
    ///   - voiceId: ID of the voice to use
    ///   - voiceSettings: Voice configuration (optional)
    /// - Returns: Audio data on success
    func synthesizeSpeech(
        text: String,
        voiceId: String,
        voiceSettings: VoiceSettings = .alarmOptimized
    ) async -> Result<Data, ElevenLabsError> {
        guard isConfigured else {
            return .failure(.apiKeyNotConfigured)
        }
        
        return await withCheckedContinuation { continuation in
            getAPIClient().textToSpeech(
                text: text,
                voiceId: voiceId,
                voiceSettings: voiceSettings
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        self.lastError = nil
                        continuation.resume(returning: .success(data))
                    case .failure(let error):
                        self.lastError = error
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
    
    /// Converts text to speech and plays it immediately
    /// - Parameters:
    ///   - text: Text to convert and play
    ///   - voiceId: ID of the voice to use
    ///   - voiceSettings: Voice configuration (optional)
    /// - Returns: True if playback started successfully
    func synthesizeAndPlay(
        text: String,
        voiceId: String,
        voiceSettings: VoiceSettings = .alarmOptimized
    ) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = await synthesizeSpeech(
            text: text,
            voiceId: voiceId,
            voiceSettings: voiceSettings
        )
        
        switch result {
        case .success(let audioData):
            return playAudio(data: audioData)
        case .failure:
            return false
        }
    }
    
    /// Plays audio data using AVAudioPlayer
    /// - Parameter data: Audio data to play
    /// - Returns: True if playback started successfully
    func playAudio(data: Data) -> Bool {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            return audioPlayer?.play() ?? false
        } catch {
            print("Audio playback error: \(error)")
            return false
        }
    }
    
    /// Stops current audio playback
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Voice Management
    
    /// Loads available voices from ElevenLabs
    func loadVoices() async {
        guard isConfigured else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await withCheckedContinuation { continuation in
            getAPIClient().getVoices { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let voices):
                        self.availableVoices = voices
                        self.lastError = nil
                    case .failure(let error):
                        self.lastError = error
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Creates a new voice through voice cloning
    /// - Parameters:
    ///   - name: Name for the new voice
    ///   - description: Optional description
    ///   - audioFiles: Audio samples for training
    /// - Returns: Voice creation response on success
    func createVoice(
        name: String,
        description: String? = nil,
        audioFiles: [Data]
    ) async -> Result<AddVoiceResponse, ElevenLabsError> {
        guard isConfigured else {
            return .failure(.apiKeyNotConfigured)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = AddVoiceRequest(name: name, description: description)
        
        return await withCheckedContinuation { continuation in
            getAPIClient().addVoice(request: request, audioFiles: audioFiles) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.lastError = nil
                        // Reload voices to include the new one
                        Task {
                            await self.loadVoices()
                        }
                        continuation.resume(returning: .success(response))
                    case .failure(let error):
                        self.lastError = error
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
    
    /// Loads user account information
    func loadUserInfo() async {
        guard isConfigured else { return }
        
        await withCheckedContinuation { continuation in
            getAPIClient().getUserInfo { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let userResponse):
                        self.userInfo = userResponse
                        self.lastError = nil
                    case .failure(let error):
                        self.lastError = error
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Voice Utilities
    
    /// Gets a voice by ID
    /// - Parameter voiceId: The voice ID to find
    /// - Returns: Voice object if found
    func getVoice(by voiceId: String) -> Voice? {
        return availableVoices.first { $0.voiceId == voiceId }
    }
    
    /// Gets all voices available for a specific subscription tier
    /// - Parameter tier: Subscription tier to filter by
    /// - Returns: Array of available voices
    func getVoices(for tier: SubscriptionTier) -> [Voice] {
        return availableVoices.filter { $0.isAvailable(for: tier) }
    }
    
    /// Gets default voice IDs for common use cases
    static var defaultVoices: DefaultVoices {
        return DefaultVoices()
    }
    
    // MARK: - Character Quota Management
    
    /// Checks if there are enough characters remaining for the text
    /// - Parameter text: Text to check
    /// - Returns: True if enough characters are available
    func hasCharactersAvailable(for text: String) -> Bool {
        guard let userInfo = userInfo else { return true }
        return userInfo.subscription.remainingCharacters >= text.count
    }
    
    /// Gets remaining character count
    var remainingCharacters: Int {
        return userInfo?.subscription.remainingCharacters ?? 0
    }
    
    /// Checks if near quota limit (>90% usage)
    var isNearQuotaLimit: Bool {
        return userInfo?.subscription.isNearQuotaLimit ?? false
    }
    
    // MARK: - Error Handling
    
    /// Clears the last error
    func clearError() {
        lastError = nil
    }
    
    /// Gets a user-friendly error message
    var errorMessage: String? {
        return lastError?.localizedDescription
    }
    
    /// Gets error recovery suggestion
    var errorRecoverySuggestion: String? {
        return lastError?.recoverySuggestion
    }
}

// MARK: - Default Voice IDs

/// Container for default voice IDs
struct DefaultVoices {
    /// Professional male voice
    let professionalMale = "21m00Tcm4TlvDq8ikWAM"
    
    /// Professional female voice
    let professionalFemale = "AZnzlk1XvdvUeBnXmlld"
    
    /// Calm and soothing voice
    let calmSoothing = "EXAVITQu4vr4xnSDxMaL"
    
    /// Energetic and upbeat voice
    let energetic = "ErXwobaYiN019PkySvjV"
    
    /// Default alarm voice (professional female)
    var alarm: String { professionalFemale }
    
    /// Array of all default voices
    var all: [String] {
        return [professionalMale, professionalFemale, calmSoothing, energetic]
    }
}

// MARK: - Convenience Extensions

extension VoiceSynthesisService {
    
    /// Quick synthesis for alarm messages
    /// - Parameters:
    ///   - message: Alarm message text
    ///   - voiceId: Voice to use (defaults to alarm voice)
    /// - Returns: Audio data on success
    func synthesizeAlarmMessage(
        _ message: String,
        voiceId: String? = nil
    ) async -> Result<Data, ElevenLabsError> {
        let voice = voiceId ?? DefaultVoices().alarm
        return await synthesizeSpeech(
            text: message,
            voiceId: voice,
            voiceSettings: .alarmOptimized
        )
    }
    
    /// Tests voice synthesis with a sample message
    /// - Parameter voiceId: Voice to test
    /// - Returns: True if test was successful
    func testVoice(_ voiceId: String) async -> Bool {
        let testMessage = "Good morning! This is a test of your voice profile."
        return await synthesizeAndPlay(
            text: testMessage,
            voiceId: voiceId,
            voiceSettings: .alarmOptimized
        )
    }
}

// MARK: - Audio Session Management

extension VoiceSynthesisService {
    
    /// Activates audio session for playback
    func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    /// Deactivates audio session
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}