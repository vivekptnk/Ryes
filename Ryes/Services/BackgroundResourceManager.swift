import Foundation
import UIKit

/// Monitors and manages resource usage for background execution
final class BackgroundResourceManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = BackgroundResourceManager()
    
    // MARK: - Properties
    
    @Published var currentMetrics = ResourceMetrics()
    @Published var isOptimizedForBackground = false
    
    private var metricsTimer: Timer?
    private var isMonitoring = false
    
    // Configuration
    private let metricsUpdateInterval: TimeInterval = 30.0 // 30 seconds
    private let batteryThreshold: Float = 0.2 // 20%
    private let memoryThreshold: UInt64 = 100 * 1024 * 1024 // 100MB
    
    // Historical data for trending
    private var metricsHistory: [ResourceMetrics] = []
    private let maxHistoryCount = 100
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// Start monitoring resource usage
    func startMonitoring() {
        guard !isMonitoring else {
            print("📊 Resource monitoring already active")
            return
        }
        
        isMonitoring = true
        scheduleMetricsUpdate()
        updateCurrentMetrics()
        
        print("📊 Background resource monitoring started")
    }
    
    /// Stop monitoring resource usage
    func stopMonitoring() {
        guard isMonitoring else {
            print("📊 Resource monitoring already stopped")
            return
        }
        
        isMonitoring = false
        metricsTimer?.invalidate()
        metricsTimer = nil
        
        print("📊 Background resource monitoring stopped")
    }
    
    /// Get current resource metrics
    func getCurrentMetrics() -> ResourceMetrics {
        updateCurrentMetrics()
        return currentMetrics
    }
    
    /// Get resource usage trends
    func getUsageTrends() -> ResourceTrends {
        guard metricsHistory.count >= 2 else {
            return ResourceTrends()
        }
        
        let recent = Array(metricsHistory.suffix(10))
        let batteryTrend = calculateTrend(recent.map { $0.batteryLevel })
        let memoryTrend = calculateTrend(recent.map { Double($0.memoryUsage) })
        let cpuTrend = calculateTrend(recent.map { $0.cpuUsage })
        
        return ResourceTrends(
            batteryTrend: batteryTrend,
            memoryTrend: memoryTrend,
            cpuTrend: cpuTrend,
            dataPoints: recent.count
        )
    }
    
    /// Check if device is under resource pressure
    func isUnderResourcePressure() -> Bool {
        let metrics = getCurrentMetrics()
        
        return metrics.batteryLevel < batteryThreshold ||
               metrics.memoryUsage > memoryThreshold ||
               metrics.cpuUsage > 50.0 || // 50% CPU usage
               metrics.thermalState == .critical ||
               metrics.isLowPowerModeEnabled
    }
    
    /// Optimize for background execution
    func optimizeForBackground() {
        guard !isOptimizedForBackground else { return }
        
        isOptimizedForBackground = true
        
        // Reduce metrics update frequency
        metricsTimer?.invalidate()
        scheduleMetricsUpdate(interval: metricsUpdateInterval * 2)
        
        print("📊 Optimized for background execution")
    }
    
    /// Restore normal resource monitoring
    func restoreNormalMode() {
        guard isOptimizedForBackground else { return }
        
        isOptimizedForBackground = false
        
        // Restore normal metrics update frequency
        if isMonitoring {
            metricsTimer?.invalidate()
            scheduleMetricsUpdate()
        }
        
        print("📊 Restored normal resource monitoring")
    }
    
    /// Get resource recommendations
    func getRecommendations() -> [ResourceRecommendation] {
        let metrics = getCurrentMetrics()
        var recommendations: [ResourceRecommendation] = []
        
        if metrics.batteryLevel < batteryThreshold {
            recommendations.append(.reduceBatteryUsage)
        }
        
        if metrics.memoryUsage > memoryThreshold {
            recommendations.append(.reduceMemoryUsage)
        }
        
        if metrics.cpuUsage > 80.0 {
            recommendations.append(.reduceCPUUsage)
        }
        
        if metrics.isLowPowerModeEnabled {
            recommendations.append(.lowPowerModeActive)
        }
        
        if metrics.thermalState == .critical {
            recommendations.append(.criticalThermalState)
        }
        
        return recommendations
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarningReceived),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func scheduleMetricsUpdate(interval: TimeInterval? = nil) {
        let updateInterval = interval ?? metricsUpdateInterval
        
        metricsTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateCurrentMetrics()
        }
    }
    
    private func updateCurrentMetrics() {
        let newMetrics = ResourceMetrics(
            timestamp: Date(),
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            batteryLevel: getBatteryLevel(),
            thermalState: getThermalState(),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentMetrics = newMetrics
            self?.addToHistory(newMetrics)
        }
    }
    
    private func addToHistory(_ metrics: ResourceMetrics) {
        metricsHistory.append(metrics)
        
        // Trim history if needed
        if metricsHistory.count > maxHistoryCount {
            metricsHistory.removeFirst(metricsHistory.count - maxHistoryCount)
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? UInt64(taskInfo.phys_footprint) : 0
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        guard result == KERN_SUCCESS else {
            return 0.0
        }
        
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo * MemoryLayout<natural_t>.size))
        }
        
        var totalUsage: Double = 0
        
        for i in 0..<Int(numCpus) {
            let cpuLoadInfo = cpuInfo.advanced(by: i * Int(CPU_STATE_MAX)).pointee
            let user = Double(cpuLoadInfo)
            let system = Double(cpuInfo.advanced(by: i * Int(CPU_STATE_MAX) + Int(CPU_STATE_SYSTEM)).pointee)
            let idle = Double(cpuInfo.advanced(by: i * Int(CPU_STATE_MAX) + Int(CPU_STATE_IDLE)).pointee)
            let nice = Double(cpuInfo.advanced(by: i * Int(CPU_STATE_MAX) + Int(CPU_STATE_NICE)).pointee)
            
            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += (user + system) / total
            }
        }
        
        return totalUsage / Double(numCpus) * 100.0
    }
    
    private func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return level >= 0 ? level : 1.0 // Return 1.0 if unknown
    }
    
    private func getThermalState() -> ProcessInfo.ThermalState {
        return ProcessInfo.processInfo.thermalState
    }
    
    private func calculateTrend(_ values: [Double]) -> ResourceTrend {
        guard values.count >= 2 else { return .stable }
        
        let first = values.first!
        let last = values.last!
        let change = (last - first) / first
        
        if abs(change) < 0.05 { // 5% threshold
            return .stable
        } else if change > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func lowPowerModeChanged() {
        updateCurrentMetrics()
        
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            optimizeForBackground()
            print("📊 Low power mode enabled - optimizing resource usage")
        } else {
            restoreNormalMode()
            print("📊 Low power mode disabled - restored normal monitoring")
        }
    }
    
    @objc private func memoryWarningReceived() {
        updateCurrentMetrics()
        print("📊⚠️ Memory warning received - current usage: \(formatBytes(currentMetrics.memoryUsage))")
    }
    
    @objc private func appDidEnterBackground() {
        optimizeForBackground()
    }
    
    @objc private func appWillEnterForeground() {
        restoreNormalMode()
    }
    
    // MARK: - Helper Methods
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Types

struct ResourceMetrics {
    let timestamp: Date
    let memoryUsage: UInt64
    let cpuUsage: Double
    let batteryLevel: Float
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerModeEnabled: Bool
    
    init(
        timestamp: Date = Date(),
        memoryUsage: UInt64 = 0,
        cpuUsage: Double = 0.0,
        batteryLevel: Float = 1.0,
        thermalState: ProcessInfo.ThermalState = .nominal,
        isLowPowerModeEnabled: Bool = false
    ) {
        self.timestamp = timestamp
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.batteryLevel = batteryLevel
        self.thermalState = thermalState
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
    }
    
    var description: String {
        let memoryMB = Double(memoryUsage) / (1024 * 1024)
        let batteryPercent = Int(batteryLevel * 100)
        
        return """
        Resource Metrics (\(timestamp)):
        - Memory: \(String(format: "%.1f", memoryMB)) MB
        - CPU: \(String(format: "%.1f", cpuUsage))%
        - Battery: \(batteryPercent)%
        - Thermal: \(thermalState.description)
        - Low Power Mode: \(isLowPowerModeEnabled ? "ON" : "OFF")
        """
    }
}

enum ResourceTrend {
    case increasing
    case decreasing
    case stable
}

struct ResourceTrends {
    let batteryTrend: ResourceTrend
    let memoryTrend: ResourceTrend
    let cpuTrend: ResourceTrend
    let dataPoints: Int
    
    init(
        batteryTrend: ResourceTrend = .stable,
        memoryTrend: ResourceTrend = .stable,
        cpuTrend: ResourceTrend = .stable,
        dataPoints: Int = 0
    ) {
        self.batteryTrend = batteryTrend
        self.memoryTrend = memoryTrend
        self.cpuTrend = cpuTrend
        self.dataPoints = dataPoints
    }
}

enum ResourceRecommendation {
    case reduceBatteryUsage
    case reduceMemoryUsage
    case reduceCPUUsage
    case lowPowerModeActive
    case criticalThermalState
    
    var description: String {
        switch self {
        case .reduceBatteryUsage:
            return "Battery level is low. Consider reducing background activity."
        case .reduceMemoryUsage:
            return "Memory usage is high. Consider optimizing memory allocation."
        case .reduceCPUUsage:
            return "CPU usage is high. Consider reducing computational intensity."
        case .lowPowerModeActive:
            return "Low Power Mode is active. System performance is reduced."
        case .criticalThermalState:
            return "Device is overheating. System may throttle performance."
        }
    }
}

// MARK: - Extensions

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal:
            return "Normal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
}