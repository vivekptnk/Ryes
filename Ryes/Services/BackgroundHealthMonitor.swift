import Foundation
import UIKit

/// Monitors background audio health and provides automatic recovery
final class BackgroundHealthMonitor {
    
    // MARK: - Properties
    
    private weak var audioService: BackgroundAudioService?
    private var healthCheckTimer: Timer?
    private var circuitBreaker: CircuitBreaker
    
    // Configuration
    private let healthCheckInterval: TimeInterval = 300 // 5 minutes
    private let maxConsecutiveFailures = 3
    private let recoveryTimeout: TimeInterval = 60 // 1 minute
    
    // State tracking
    private var consecutiveFailures = 0
    private var lastSuccessfulCheck = Date()
    private var isMonitoring = false
    
    // Metrics
    private var totalHealthChecks = 0
    private var totalFailures = 0
    private var totalRecoveries = 0
    
    // MARK: - Initialization
    
    init(audioService: BackgroundAudioService) {
        self.audioService = audioService
        self.circuitBreaker = CircuitBreaker(
            failureThreshold: maxConsecutiveFailures,
            recoveryTimeout: recoveryTimeout
        )
    }
    
    // MARK: - Public Interface
    
    /// Start health monitoring
    func startMonitoring() {
        guard !isMonitoring else {
            print("💊 Health monitor already running")
            return
        }
        
        isMonitoring = true
        scheduleNextHealthCheck()
        print("💊 Background health monitoring started (interval: \(healthCheckInterval)s)")
    }
    
    /// Stop health monitoring
    func stopMonitoring() {
        guard isMonitoring else {
            print("💊 Health monitor already stopped")
            return
        }
        
        isMonitoring = false
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        circuitBreaker.reset()
        print("💊 Background health monitoring stopped")
    }
    
    /// Get current health metrics
    func getHealthMetrics() -> HealthMetrics {
        return HealthMetrics(
            totalChecks: totalHealthChecks,
            totalFailures: totalFailures,
            totalRecoveries: totalRecoveries,
            consecutiveFailures: consecutiveFailures,
            lastSuccessfulCheck: lastSuccessfulCheck,
            isCircuitBreakerOpen: circuitBreaker.state == .open,
            successRate: calculateSuccessRate()
        )
    }
    
    // MARK: - Private Methods
    
    private func scheduleNextHealthCheck() {
        guard isMonitoring else { return }
        
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: false) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    private func performHealthCheck() {
        guard isMonitoring else { return }
        
        totalHealthChecks += 1
        
        // Only perform health checks when app is in background
        guard UIApplication.shared.applicationState == .background else {
            print("💊 Skipping health check - app in foreground")
            scheduleNextHealthCheck()
            return
        }
        
        let isHealthy = checkAudioServiceHealth()
        
        if isHealthy {
            handleHealthCheckSuccess()
        } else {
            handleHealthCheckFailure()
        }
        
        scheduleNextHealthCheck()
    }
    
    private func checkAudioServiceHealth() -> Bool {
        guard let audioService = audioService else {
            print("💊❌ Audio service reference lost")
            return false
        }
        
        // Check if audio service should be active
        let shouldBeActive = audioService.shouldBeActive()
        let isActive = audioService.isActive
        let isPlaying = audioService.isAudioPlaying
        
        print("💊 Health check - Should be active: \(shouldBeActive), Is active: \(isActive), Is playing: \(isPlaying)")
        
        // Health check passes if:
        // 1. No alarms enabled and service is inactive, OR
        // 2. Alarms enabled, service is active, and audio is playing
        if !shouldBeActive {
            return !isActive // Should be inactive when no alarms
        } else {
            return isActive && isPlaying // Should be active and playing when alarms exist
        }
    }
    
    private func handleHealthCheckSuccess() {
        consecutiveFailures = 0
        lastSuccessfulCheck = Date()
        circuitBreaker.recordSuccess()
        print("💊✅ Health check passed")
    }
    
    private func handleHealthCheckFailure() {
        consecutiveFailures += 1
        totalFailures += 1
        
        print("💊❌ Health check failed (consecutive: \(consecutiveFailures)/\(maxConsecutiveFailures))")
        
        // Attempt recovery if circuit breaker allows
        if circuitBreaker.canAttemptOperation() {
            attemptRecovery()
        } else {
            print("💊🔒 Circuit breaker open - skipping recovery attempt")
        }
        
        circuitBreaker.recordFailure()
    }
    
    private func attemptRecovery() {
        guard let audioService = audioService else { return }
        
        print("💊🔄 Attempting recovery...")
        
        // Strategy: Restart the audio service
        audioService.restartAudioPlayback()
        totalRecoveries += 1
        
        // Verify recovery after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.verifyRecovery()
        }
    }
    
    private func verifyRecovery() {
        let isHealthy = checkAudioServiceHealth()
        
        if isHealthy {
            print("💊✅ Recovery successful")
            consecutiveFailures = 0
            lastSuccessfulCheck = Date()
            circuitBreaker.recordSuccess()
        } else {
            print("💊❌ Recovery failed")
        }
    }
    
    private func calculateSuccessRate() -> Double {
        guard totalHealthChecks > 0 else { return 0.0 }
        let successfulChecks = totalHealthChecks - totalFailures
        return Double(successfulChecks) / Double(totalHealthChecks)
    }
}

// MARK: - Circuit Breaker Implementation

private class CircuitBreaker {
    
    enum State {
        case closed    // Normal operation
        case open      // Blocking operations due to failures
        case halfOpen  // Testing if service has recovered
    }
    
    private(set) var state: State = .closed
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    
    private var failureCount = 0
    private var lastFailureTime: Date?
    private var nextAttemptTime: Date?
    
    init(failureThreshold: Int, recoveryTimeout: TimeInterval) {
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
    }
    
    func canAttemptOperation() -> Bool {
        switch state {
        case .closed:
            return true
        case .halfOpen:
            return true
        case .open:
            // Check if enough time has passed to attempt recovery
            if let nextAttempt = nextAttemptTime, Date() >= nextAttempt {
                state = .halfOpen
                return true
            }
            return false
        }
    }
    
    func recordSuccess() {
        failureCount = 0
        lastFailureTime = nil
        nextAttemptTime = nil
        state = .closed
    }
    
    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= failureThreshold {
            state = .open
            nextAttemptTime = Date().addingTimeInterval(recoveryTimeout)
        }
    }
    
    func reset() {
        failureCount = 0
        lastFailureTime = nil
        nextAttemptTime = nil
        state = .closed
    }
}

// MARK: - Health Metrics

struct HealthMetrics {
    let totalChecks: Int
    let totalFailures: Int
    let totalRecoveries: Int
    let consecutiveFailures: Int
    let lastSuccessfulCheck: Date
    let isCircuitBreakerOpen: Bool
    let successRate: Double
    
    var description: String {
        return """
        Health Metrics:
        - Total checks: \(totalChecks)
        - Success rate: \(String(format: "%.1f", successRate * 100))%
        - Total failures: \(totalFailures)
        - Consecutive failures: \(consecutiveFailures)
        - Total recoveries: \(totalRecoveries)
        - Last successful check: \(lastSuccessfulCheck)
        - Circuit breaker open: \(isCircuitBreakerOpen)
        """
    }
}