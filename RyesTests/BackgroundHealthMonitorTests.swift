import Testing
import UIKit
@testable import Ryes

@MainActor
struct BackgroundHealthMonitorTests {
    
    @Test func testHealthMonitorInitialization() async throws {
        // Given: BackgroundAudioService
        let audioService = BackgroundAudioService.shared
        
        // When: Creating health monitor
        let healthMonitor = BackgroundHealthMonitor(audioService: audioService)
        
        // Then: Should be initialized
        #expect(healthMonitor != nil)
    }
    
    @Test func testHealthMetrics() async throws {
        // Given: BackgroundAudioService and health monitor
        let audioService = BackgroundAudioService.shared
        let healthMonitor = BackgroundHealthMonitor(audioService: audioService)
        
        // When: Getting health metrics
        let metrics = healthMonitor.getHealthMetrics()
        
        // Then: Should have valid metrics
        #expect(metrics.totalChecks >= 0)
        #expect(metrics.totalFailures >= 0)
        #expect(metrics.totalRecoveries >= 0)
        #expect(metrics.consecutiveFailures >= 0)
        #expect(metrics.successRate >= 0.0)
        #expect(metrics.successRate <= 1.0)
    }
    
    @Test func testStartStopMonitoring() async throws {
        // Given: Health monitor
        let audioService = BackgroundAudioService.shared
        let healthMonitor = BackgroundHealthMonitor(audioService: audioService)
        
        // When: Starting and stopping monitoring
        healthMonitor.startMonitoring()
        healthMonitor.stopMonitoring()
        
        // Then: Should not crash
        // Note: We can't easily test the internal monitoring state without exposing it
    }
}