import Foundation
import CoreData
import Combine
import SwiftUI

/// ViewModel for managing alarm list state and operations
@MainActor
final class AlarmListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchText = ""
    @Published var sortOption: SortOption = .time
    @Published var filterOption: FilterOption = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private let alarmManager: AlarmPersistenceManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredAlarms: [Alarm] {
        let alarms = alarmManager.alarms
        
        // Apply filter
        let filtered: [Alarm]
        switch filterOption {
        case .all:
            filtered = alarms
        case .enabled:
            filtered = alarms.filter { $0.isEnabled }
        case .disabled:
            filtered = alarms.filter { !$0.isEnabled }
        case .repeating:
            filtered = alarms.filter { $0.isRepeating }
        case .oneTime:
            filtered = alarms.filter { !$0.isRepeating }
        }
        
        // Apply search
        let searched: [Alarm]
        if searchText.isEmpty {
            searched = filtered
        } else {
            searched = filtered.filter { alarm in
                if let label = alarm.label, label.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Search in time
                let timeString = timeFormatter.string(from: alarm.time ?? Date())
                if timeString.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Search in repeat days
                if alarm.repeatDaysDisplayString.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                return false
            }
        }
        
        // Apply sort
        let sorted: [Alarm]
        switch sortOption {
        case .time:
            sorted = searched.sorted { ($0.time ?? Date()) < ($1.time ?? Date()) }
        case .label:
            sorted = searched.sorted { 
                let label1 = $0.label ?? ""
                let label2 = $1.label ?? ""
                return label1.localizedCaseInsensitiveCompare(label2) == .orderedAscending
            }
        case .enabled:
            sorted = searched.sorted { alarm1, alarm2 in
                if alarm1.isEnabled == alarm2.isEnabled {
                    return (alarm1.time ?? Date()) < (alarm2.time ?? Date())
                }
                return alarm1.isEnabled && !alarm2.isEnabled
            }
        }
        
        return sorted
    }
    
    var upcomingAlarm: Alarm? {
        alarmManager.getNextScheduledAlarm()
    }
    
    var statistics: AlarmPersistenceManager.AlarmStatistics {
        alarmManager.getAlarmStatistics()
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // MARK: - Initialization
    
    init(alarmManager: AlarmPersistenceManager = AlarmPersistenceManager()) {
        self.alarmManager = alarmManager
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe alarm manager changes
        alarmManager.$alarms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe error changes
        alarmManager.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func refresh() {
        isLoading = true
        alarmManager.fetchAlarms()
        alarmManager.fetchVoiceProfiles()
        
        // Schedule all alarms
        Task {
            await AlarmScheduler.shared.scheduleAllAlarms()
            isLoading = false
        }
    }
    
    func deleteAlarms(_ alarms: IndexSet) {
        let alarmsToDelete = alarms.map { filteredAlarms[$0] }
        
        withAnimation {
            for alarm in alarmsToDelete {
                alarmManager.deleteAlarmWithScheduling(alarm)
            }
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        withAnimation {
            alarmManager.deleteAlarmWithScheduling(alarm)
        }
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        withAnimation(.easeInOut(duration: 0.2)) {
            alarmManager.toggleAlarmWithScheduling(alarm)
        }
    }
    
    func duplicateAlarm(_ alarm: Alarm) {
        let newAlarm = alarmManager.createAlarm(
            time: alarm.time ?? Date(),
            label: (alarm.label ?? "") + " (Copy)",
            isEnabled: false,
            repeatDays: alarm.repeatDaysSet,
            dismissalType: alarm.dismissalTypeEnum,
            voiceProfile: alarm.voiceProfile
        )
        
        // Don't schedule duplicate alarms by default (they're created disabled)
    }
    
    func snoozeAlarm(_ alarm: Alarm, minutes: Int = 9) {
        guard let currentTime = alarm.time else { return }
        
        let snoozeTime = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
        
        // Create a one-time snooze alarm
        let snoozeAlarm = alarmManager.createAlarm(
            time: snoozeTime,
            label: (alarm.label ?? "Alarm") + " (Snoozed)",
            isEnabled: true,
            repeatDays: [],
            dismissalType: alarm.dismissalTypeEnum,
            voiceProfile: alarm.voiceProfile
        )
        
        Task {
            await AlarmScheduler.shared.scheduleAlarm(snoozeAlarm)
        }
    }
    
    // MARK: - Enums
    
    enum SortOption: String, CaseIterable {
        case time = "Time"
        case label = "Label"
        case enabled = "Status"
        
        var systemImage: String {
            switch self {
            case .time: return "clock"
            case .label: return "textformat"
            case .enabled: return "power"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case enabled = "Enabled"
        case disabled = "Disabled"
        case repeating = "Repeating"
        case oneTime = "One-time"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .enabled: return "checkmark.circle"
            case .disabled: return "xmark.circle"
            case .repeating: return "repeat"
            case .oneTime: return "1.circle"
            }
        }
    }
}

// MARK: - Preview Support

extension AlarmListViewModel {
    static var preview: AlarmListViewModel {
        AlarmListViewModel(alarmManager: .preview)
    }
}