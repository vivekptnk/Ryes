import Foundation
import AVFoundation
import UIKit

/// Service responsible for maintaining background execution through silent audio playback
final class BackgroundAudioService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = BackgroundAudioService()
    
    // MARK: - Properties
    
    private var silentPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession
    private var isPlayingInBackground = false
    private var healthMonitor: BackgroundHealthMonitor?
    
    @Published var isActive = false
    @Published var lastError: BackgroundAudioError?
    
    // Configuration
    private let silentAudioFileName = "silent_1s"
    private let silentAudioFileExtension = "mp3"
    
    // MARK: - Initialization
    
    private override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
        setupHealthMonitor()
    }
    
    // MARK: - Public Interface
    
    /// Start background audio playback for alarm persistence
    func startBackgroundAudio() {
        guard !isActive else {
            print("🔊 Background audio already active")
            return
        }
        
        do {
            try configureAudioSession()
            try setupSilentAudioPlayer()
            
            silentPlayer?.play()
            isActive = true
            isPlayingInBackground = true
            lastError = nil
            
            print("🔊 Background audio started successfully")
            startHealthMonitoring()
            
        } catch {
            let audioError = BackgroundAudioError.setupFailed(error)
            lastError = audioError
            print("❌ Failed to start background audio: \(audioError.localizedDescription)")
        }
    }
    
    /// Stop background audio playback
    func stopBackgroundAudio() {
        guard isActive else {
            print("🔊 Background audio already inactive")
            return
        }
        
        silentPlayer?.stop()
        silentPlayer = nil
        isActive = false
        isPlayingInBackground = false
        
        stopHealthMonitoring()
        
        print("🔊 Background audio stopped")
    }
    
    /// Check if background audio should be active based on alarm state
    func shouldBeActive() -> Bool {
        // Check if there are any enabled alarms
        let alarmManager = AlarmPersistenceManager()
        let enabledAlarms = alarmManager.fetchEnabledAlarms()
        return !enabledAlarms.isEmpty
    }
    
    /// Restart audio playback (for recovery scenarios)
    func restartAudioPlayback() {
        print("🔄 Restarting background audio playback")
        stopBackgroundAudio()
        
        // Small delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startBackgroundAudio()
        }
    }
    
    // MARK: - Private Setup Methods
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowBluetoothA2DP, .allowAirPlay]
            )
            print("🔊 Audio session category configured")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func configureAudioSession() throws {
        try audioSession.setActive(true)
        print("🔊 Audio session activated")
    }
    
    private func setupSilentAudioPlayer() throws {
        // Try to find the audio file in bundle
        if let silentAudioURL = Bundle.main.url(
            forResource: silentAudioFileName,
            withExtension: silentAudioFileExtension
        ) {
            silentPlayer = try AVAudioPlayer(contentsOf: silentAudioURL)
        } else {
            // Fallback: Create a minimal silent audio programmatically
            silentPlayer = try createSilentAudioPlayer()
        }
        
        silentPlayer?.delegate = self
        silentPlayer?.numberOfLoops = -1 // Infinite loop
        silentPlayer?.volume = 0.0 // Silent
        silentPlayer?.prepareToPlay()
        
        print("🔊 Silent audio player configured")
    }
    
    private func createSilentAudioPlayer() throws -> AVAudioPlayer {
        // Create a minimal silent audio data (1 second of silence at 8kHz, mono)
        let sampleRate: Double = 8000
        let duration: Double = 1.0
        let frameCount = Int(sampleRate * duration)
        
        // Create PCM format
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Create silent PCM buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = buffer.frameCapacity
        
        // Buffer is already zeroed, which means silence
        
        // Convert to Data for AVAudioPlayer
        // For simplicity, we'll create a very basic WAV format data
        let silentData = createWAVData(frameCount: frameCount, sampleRate: Int(sampleRate))
        
        return try AVAudioPlayer(data: silentData)
    }
    
    private func createWAVData(frameCount: Int, sampleRate: Int) -> Data {
        var data = Data()
        
        // WAV header (44 bytes)
        data.append("RIFF".data(using: .ascii)!) // ChunkID
        
        // File size
        let fileSize = UInt32(36 + frameCount * 2).littleEndian
        withUnsafeBytes(of: fileSize) { data.append(contentsOf: $0) }
        
        data.append("WAVE".data(using: .ascii)!) // Format
        data.append("fmt ".data(using: .ascii)!) // Subchunk1ID
        
        // Subchunk1 size
        let subchunk1Size = UInt32(16).littleEndian
        withUnsafeBytes(of: subchunk1Size) { data.append(contentsOf: $0) }
        
        // Audio format (PCM)
        let audioFormat = UInt16(1).littleEndian
        withUnsafeBytes(of: audioFormat) { data.append(contentsOf: $0) }
        
        // Number of channels (Mono)
        let numChannels = UInt16(1).littleEndian
        withUnsafeBytes(of: numChannels) { data.append(contentsOf: $0) }
        
        // Sample rate
        let sampleRateValue = UInt32(sampleRate).littleEndian
        withUnsafeBytes(of: sampleRateValue) { data.append(contentsOf: $0) }
        
        // Byte rate
        let byteRate = UInt32(sampleRate * 2).littleEndian
        withUnsafeBytes(of: byteRate) { data.append(contentsOf: $0) }
        
        // Block align
        let blockAlign = UInt16(2).littleEndian
        withUnsafeBytes(of: blockAlign) { data.append(contentsOf: $0) }
        
        // Bits per sample
        let bitsPerSample = UInt16(16).littleEndian
        withUnsafeBytes(of: bitsPerSample) { data.append(contentsOf: $0) }
        
        data.append("data".data(using: .ascii)!) // Subchunk2ID
        
        // Subchunk2 size
        let subchunk2Size = UInt32(frameCount * 2).littleEndian
        withUnsafeBytes(of: subchunk2Size) { data.append(contentsOf: $0) }
        
        // Silent PCM data (zeros)
        let silentBytes = Data(count: frameCount * 2)
        data.append(silentBytes)
        
        return data
    }
    
    private func setupHealthMonitor() {
        healthMonitor = BackgroundHealthMonitor(audioService: self)
    }
    
    private func startHealthMonitoring() {
        healthMonitor?.startMonitoring()
    }
    
    private func stopHealthMonitoring() {
        healthMonitor?.stopMonitoring()
    }
    
    // MARK: - App Lifecycle Integration
    
    /// Handle app entering background
    func handleAppDidEnterBackground() {
        guard shouldBeActive() else {
            print("🔊 No active alarms, skipping background audio")
            return
        }
        
        if !isActive {
            startBackgroundAudio()
        }
        
        print("🔊 App entered background with audio: \(isActive ? "ACTIVE" : "INACTIVE")")
    }
    
    /// Handle app entering foreground
    func handleAppWillEnterForeground() {
        // Keep audio active if alarms are still enabled
        // This allows seamless background/foreground transitions
        print("🔊 App entering foreground with audio: \(isActive ? "ACTIVE" : "INACTIVE")")
        
        if isActive && !shouldBeActive() {
            stopBackgroundAudio()
            print("🔊 Stopped background audio - no active alarms")
        }
    }
    
    /// Handle when all alarms are disabled
    func handleAlarmsDisabled() {
        if isActive {
            stopBackgroundAudio()
            print("🔊 Stopped background audio - all alarms disabled")
        }
    }
    
    /// Handle when alarms are enabled
    func handleAlarmsEnabled() {
        if !isActive && UIApplication.shared.applicationState == .background {
            startBackgroundAudio()
            print("🔊 Started background audio - alarms enabled")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension BackgroundAudioService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag && isPlayingInBackground {
            print("❌ Background audio finished unexpectedly, attempting restart")
            restartAudioPlayback()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Background audio decode error: \(error)")
            lastError = .playbackFailed(error)
            restartAudioPlayback()
        }
    }
}

// MARK: - Health Check Interface

extension BackgroundAudioService {
    
    /// Check if audio is playing (for health monitoring)
    var isAudioPlaying: Bool {
        return silentPlayer?.isPlaying ?? false
    }
    
    /// Get current audio player state for debugging
    var debugInfo: String {
        guard let player = silentPlayer else {
            return "No audio player"
        }
        
        return """
        Playing: \(player.isPlaying)
        Volume: \(player.volume)
        Current Time: \(player.currentTime)
        Duration: \(player.duration)
        Loops: \(player.numberOfLoops)
        """
    }
}

// MARK: - Error Types

enum BackgroundAudioError: LocalizedError {
    case audioFileNotFound
    case setupFailed(Error)
    case playbackFailed(Error)
    case sessionConfigurationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .audioFileNotFound:
            return "Silent audio file not found in bundle"
        case .setupFailed(let error):
            return "Failed to setup background audio: \(error.localizedDescription)"
        case .playbackFailed(let error):
            return "Audio playback failed: \(error.localizedDescription)"
        case .sessionConfigurationFailed(let error):
            return "Audio session configuration failed: \(error.localizedDescription)"
        }
    }
}