import Testing
import AVFoundation
import UIKit
@testable import Ryes

@MainActor
struct BackgroundExecutionIntegrationTests {
    
    @Test func testBasicIntegration() async throws {
        // Given: Background audio service and alarm scheduler
        let backgroundAudioService = BackgroundAudioService.shared
        let alarmScheduler = AlarmScheduler.shared
        
        // When: Testing basic integration
        // Then: Both services should be accessible
        #expect(backgroundAudioService != nil)
        #expect(alarmScheduler != nil)
    }
    
    @Test func testAppLifecycleIntegration() async throws {
        // Given: Background audio service
        let backgroundAudioService = BackgroundAudioService.shared
        
        // When: Simulating app lifecycle events
        backgroundAudioService.handleAppDidEnterBackground()
        backgroundAudioService.handleAppWillEnterForeground()
        
        // Then: Should not crash
        // Note: We can't easily test the exact behavior without mocking UIApplication.shared.applicationState
    }
    
    @Test func testAlarmSchedulerIntegration() async throws {
        // Given: Alarm scheduler and background audio service
        let alarmScheduler = AlarmScheduler.shared
        let backgroundAudioService = BackgroundAudioService.shared
        
        // When: Testing integration points
        alarmScheduler.scheduleAllAlarms()
        
        // Wait briefly for any async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should not crash
        // Note: The exact behavior depends on whether there are alarms in the test database
    }
    
    @Test func testAudioSessionConfiguration() async throws {
        // Given: Background audio service
        let audioService = BackgroundAudioService.shared
        
        // When: Starting audio service
        audioService.startBackgroundAudio()
        
        // Then: Should configure audio session properly
        let audioSession = AVAudioSession.sharedInstance()
        #expect(audioSession.category == .playback)
        
        // Cleanup
        audioService.stopBackgroundAudio()
    }
}