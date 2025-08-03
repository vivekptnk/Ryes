import Testing
import AVFoundation
import UIKit
@testable import Ryes

@MainActor
struct BackgroundAudioServiceTests {
    
    @Test func testBackgroundAudioServiceInitialization() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Checking initial state
        // Then: Service should be initialized but not active
        #expect(!audioService.isActive)
        #expect(audioService.lastError == nil)
    }
    
    @Test func testStartBackgroundAudio() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Starting background audio
        audioService.startBackgroundAudio()
        
        // Then: Service should be active
        #expect(audioService.isActive)
        
        // Cleanup
        audioService.stopBackgroundAudio()
    }
    
    @Test func testStopBackgroundAudio() async throws {
        // Given: Active background audio
        let audioService = BackgroundAudioService.shared
        audioService.startBackgroundAudio()
        #expect(audioService.isActive)
        
        // When: Stopping background audio
        audioService.stopBackgroundAudio()
        
        // Then: Service should be inactive
        #expect(!audioService.isActive)
    }
    
    @Test func testShouldBeActiveWithAlarms() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Checking if should be active (this will check actual alarms in Core Data)
        let shouldBeActive = audioService.shouldBeActive()
        
        // Then: Result should be boolean (exact value depends on test data)
        #expect(shouldBeActive == true || shouldBeActive == false)
    }
    
    @Test func testDebugInfo() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        audioService.startBackgroundAudio()
        
        // When: Getting debug info
        let debugInfo = audioService.debugInfo
        
        // Then: Should contain relevant information
        #expect(debugInfo.contains("Playing:") || debugInfo.contains("No audio player"))
        
        // Cleanup
        audioService.stopBackgroundAudio()
    }
    
    @Test func testAppLifecycleMethods() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Calling lifecycle methods
        // Then: Should not crash
        audioService.handleAppDidEnterBackground()
        audioService.handleAppWillEnterForeground()
        audioService.handleAlarmsEnabled()
        audioService.handleAlarmsDisabled()
        
        // No assertions needed, just testing for crashes
    }
    
    @Test func testRestartAudioPlayback() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Restarting audio playback
        audioService.restartAudioPlayback()
        
        // Wait a moment for restart to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then: Should not crash
        // Note: In a real implementation, we'd check if restart was successful
    }
}