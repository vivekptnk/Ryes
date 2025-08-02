//
//  AlarmPersistenceManager.swift
//  Arise
//
//  Created on 2/8/25.
//

import Foundation
import CoreData
import Combine

/// Manager class for handling all alarm and voice profile persistence operations
final class AlarmPersistenceManager: ObservableObject {
    
    // MARK: - Properties
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    // MARK: - Published Properties
    
    @Published var alarms: [Alarm] = []
    @Published var voiceProfiles: [VoiceProfile] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.viewContext
        
        fetchAlarms()
        fetchVoiceProfiles()
    }
    
    // MARK: - Alarm Operations
    
    /// Create a new alarm
    func createAlarm(time: Date,
                    label: String? = nil,
                    isEnabled: Bool = true,
                    repeatDays: Alarm.RepeatDay = [],
                    dismissalType: Alarm.DismissalType = .standard,
                    voiceProfile: VoiceProfile? = nil) -> Alarm {
        let alarm = Alarm.create(
            in: context,
            time: time,
            label: label,
            isEnabled: isEnabled,
            repeatDays: repeatDays,
            dismissalType: dismissalType,
            voiceProfile: voiceProfile
        )
        
        saveContext()
        fetchAlarms()
        
        return alarm
    }
    
    /// Update an existing alarm
    func updateAlarm(_ alarm: Alarm) {
        saveContext()
        fetchAlarms()
    }
    
    /// Delete an alarm
    func deleteAlarm(_ alarm: Alarm) {
        context.delete(alarm)
        saveContext()
        fetchAlarms()
    }
    
    /// Delete multiple alarms
    func deleteAlarms(_ alarms: [Alarm]) {
        alarms.forEach { context.delete($0) }
        saveContext()
        fetchAlarms()
    }
    
    /// Toggle alarm enabled state
    func toggleAlarm(_ alarm: Alarm) {
        alarm.isEnabled.toggle()
        saveContext()
        fetchAlarms()
    }
    
    /// Fetch all alarms
    func fetchAlarms() {
        let request = Alarm.allAlarmsFetchRequest()
        
        do {
            alarms = try context.fetch(request)
        } catch {
            self.error = error
            print("Failed to fetch alarms: \(error)")
        }
    }
    
    /// Fetch enabled alarms only
    func fetchEnabledAlarms() -> [Alarm] {
        let request = Alarm.enabledAlarmsFetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            self.error = error
            print("Failed to fetch enabled alarms: \(error)")
            return []
        }
    }
    
    /// Get next scheduled alarm
    func getNextScheduledAlarm() -> Alarm? {
        let enabledAlarms = fetchEnabledAlarms()
        let now = Date()
        
        return enabledAlarms
            .map { alarm in (alarm: alarm, nextDate: alarm.nextAlarmDate) }
            .filter { $0.nextDate > now }
            .sorted { $0.nextDate < $1.nextDate }
            .first?.alarm
    }
    
    // MARK: - Voice Profile Operations
    
    /// Create a new voice profile
    func createVoiceProfile(name: String,
                           recordingPath: String? = nil,
                           elevenLabsVoiceId: String? = nil,
                           isShared: Bool = false) -> VoiceProfile {
        let profile = VoiceProfile.create(
            in: context,
            name: name,
            recordingPath: recordingPath,
            elevenLabsVoiceId: elevenLabsVoiceId,
            isShared: isShared
        )
        
        saveContext()
        fetchVoiceProfiles()
        
        return profile
    }
    
    /// Update a voice profile
    func updateVoiceProfile(_ profile: VoiceProfile) {
        do {
            try profile.validate()
            saveContext()
            fetchVoiceProfiles()
        } catch {
            self.error = error
            print("Failed to update voice profile: \(error)")
        }
    }
    
    /// Delete a voice profile
    func deleteVoiceProfile(_ profile: VoiceProfile) {
        // Delete associated recording file
        profile.deleteRecording()
        
        // Delete from Core Data
        context.delete(profile)
        saveContext()
        fetchVoiceProfiles()
    }
    
    /// Fetch all voice profiles
    func fetchVoiceProfiles() {
        let request = VoiceProfile.allProfilesFetchRequest()
        
        do {
            voiceProfiles = try context.fetch(request)
        } catch {
            self.error = error
            print("Failed to fetch voice profiles: \(error)")
        }
    }
    
    /// Fetch shared voice profiles
    func fetchSharedVoiceProfiles() -> [VoiceProfile] {
        let request = VoiceProfile.sharedProfilesFetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            self.error = error
            print("Failed to fetch shared voice profiles: \(error)")
            return []
        }
    }
    
    /// Get or create default voice profile
    func getDefaultVoiceProfile() -> VoiceProfile {
        // Check if default profile exists
        let request = VoiceProfile.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Default Voice")
        request.fetchLimit = 1
        
        do {
            if let existingProfile = try context.fetch(request).first {
                return existingProfile
            }
        } catch {
            print("Failed to fetch default voice profile: \(error)")
        }
        
        // Create default profile if it doesn't exist
        return createVoiceProfile(name: "Default Voice", isShared: false)
    }
    
    // MARK: - Relationship Operations
    
    /// Assign a voice profile to multiple alarms
    func assignVoiceProfile(_ profile: VoiceProfile, to alarms: [Alarm]) {
        alarms.forEach { $0.voiceProfile = profile }
        saveContext()
        fetchAlarms()
    }
    
    /// Remove voice profile from alarms
    func removeVoiceProfileFromAlarms(_ alarms: [Alarm]) {
        alarms.forEach { $0.voiceProfile = nil }
        saveContext()
        fetchAlarms()
    }
    
    /// Get alarms for a specific voice profile
    func getAlarms(for profile: VoiceProfile) -> [Alarm] {
        let request = Alarm.alarmsForVoiceProfile(profile)
        
        do {
            return try context.fetch(request)
        } catch {
            self.error = error
            print("Failed to fetch alarms for voice profile: \(error)")
            return []
        }
    }
    
    // MARK: - Batch Operations
    
    /// Import multiple alarms
    func importAlarms(_ alarmData: [(time: Date, label: String?, repeatDays: Alarm.RepeatDay, dismissalType: Alarm.DismissalType)],
                     with voiceProfile: VoiceProfile? = nil) {
        persistenceController.performBackgroundTask({ context in
            for data in alarmData {
                _ = Alarm.create(
                    in: context,
                    time: data.time,
                    label: data.label,
                    isEnabled: true,
                    repeatDays: data.repeatDays,
                    dismissalType: data.dismissalType,
                    voiceProfile: voiceProfile
                )
            }
        }) { [weak self] result in
            switch result {
            case .success:
                self?.fetchAlarms()
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
    /// Export alarms data
    func exportAlarmsData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let alarmData = alarms.map { alarm in
                [
                    "id": alarm.id?.uuidString ?? "",
                    "time": ISO8601DateFormatter().string(from: alarm.time ?? Date()),
                    "label": alarm.label ?? "",
                    "isEnabled": alarm.isEnabled,
                    "repeatDays": alarm.repeatDays,
                    "dismissalType": alarm.dismissalType ?? "standard",
                    "voiceProfileId": alarm.voiceProfile?.id?.uuidString ?? ""
                ] as [String : Any]
            }
            
            return try JSONSerialization.data(withJSONObject: alarmData)
        } catch {
            self.error = error
            return nil
        }
    }
    
    // MARK: - Statistics
    
    /// Get alarm statistics
    func getAlarmStatistics() -> AlarmStatistics {
        let enabledCount = alarms.filter { $0.isEnabled }.count
        let totalCount = alarms.count
        let repeatingCount = alarms.filter { $0.isRepeating }.count
        
        let dismissalTypeCounts = Dictionary(grouping: alarms) { $0.dismissalTypeEnum }
            .mapValues { $0.count }
        
        return AlarmStatistics(
            totalAlarms: totalCount,
            enabledAlarms: enabledCount,
            repeatingAlarms: repeatingCount,
            dismissalTypeCounts: dismissalTypeCounts
        )
    }
    
    // MARK: - Private Methods
    
    private func saveContext() {
        persistenceController.save()
    }
    
    // MARK: - Types
    
    struct AlarmStatistics {
        let totalAlarms: Int
        let enabledAlarms: Int
        let repeatingAlarms: Int
        let dismissalTypeCounts: [Alarm.DismissalType: Int]
    }
}

// MARK: - Preview Support

extension AlarmPersistenceManager {
    static var preview: AlarmPersistenceManager {
        AlarmPersistenceManager(persistenceController: .preview)
    }
}