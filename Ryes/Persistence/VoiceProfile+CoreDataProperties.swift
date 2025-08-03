//
//  VoiceProfile+CoreDataProperties.swift
//  Ryes
//
//  Created on 2/8/25.
//

import Foundation
import CoreData

extension VoiceProfile {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceProfile> {
        return NSFetchRequest<VoiceProfile>(entityName: "VoiceProfile")
    }
    
    @NSManaged public var elevenLabsVoiceId: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isShared: Bool
    @NSManaged public var name: String?
    @NSManaged public var recordingPath: String?
    @NSManaged public var alarms: NSSet?
    
}

// MARK: - Generated accessors for alarms

extension VoiceProfile {
    
    @objc(addAlarmsObject:)
    @NSManaged public func addToAlarms(_ value: Alarm)
    
    @objc(removeAlarmsObject:)
    @NSManaged public func removeFromAlarms(_ value: Alarm)
    
    @objc(addAlarms:)
    @NSManaged public func addToAlarms(_ values: NSSet)
    
    @objc(removeAlarms:)
    @NSManaged public func removeFromAlarms(_ values: NSSet)
    
}

// MARK: - Fetch Requests

extension VoiceProfile {
    
    /// Fetch all voice profiles sorted by name
    static func allProfilesFetchRequest() -> NSFetchRequest<VoiceProfile> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceProfile.name, ascending: true)]
        return request
    }
    
    /// Fetch only shared voice profiles
    static func sharedProfilesFetchRequest() -> NSFetchRequest<VoiceProfile> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isShared == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceProfile.name, ascending: true)]
        return request
    }
    
    /// Fetch voice profiles that have been synced with ElevenLabs
    static func syncedProfilesFetchRequest() -> NSFetchRequest<VoiceProfile> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "elevenLabsVoiceId != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceProfile.name, ascending: true)]
        return request
    }
    
    /// Fetch voice profiles with recordings
    static func profilesWithRecordingsFetchRequest() -> NSFetchRequest<VoiceProfile> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "recordingPath != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceProfile.name, ascending: true)]
        return request
    }
}

// MARK: - Convenience Properties

extension VoiceProfile {
    
    /// Get alarms as an array
    var alarmsArray: [Alarm] {
        let set = alarms as? Set<Alarm> ?? []
        return set.sorted { ($0.time ?? Date()) < ($1.time ?? Date()) }
    }
    
    /// Get count of alarms using this voice profile
    var alarmCount: Int {
        alarms?.count ?? 0
    }
    
    /// Check if this voice profile can be deleted (no active alarms)
    var canBeDeleted: Bool {
        alarmCount == 0
    }
}

extension VoiceProfile: Identifiable {}