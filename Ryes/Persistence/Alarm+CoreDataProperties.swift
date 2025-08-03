//
//  Alarm+CoreDataProperties.swift
//  Ryes
//
//  Created on 2/8/25.
//

import Foundation
import CoreData

extension Alarm {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Alarm> {
        return NSFetchRequest<Alarm>(entityName: "Alarm")
    }
    
    @NSManaged public var dismissalType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var label: String?
    @NSManaged public var repeatDays: Int16
    @NSManaged public var time: Date?
    @NSManaged public var voiceProfile: VoiceProfile?
    
}

// MARK: - Fetch Requests

extension Alarm {
    
    /// Fetch all alarms sorted by time
    static func allAlarmsFetchRequest() -> NSFetchRequest<Alarm> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Alarm.time, ascending: true)]
        return request
    }
    
    /// Fetch only enabled alarms
    static func enabledAlarmsFetchRequest() -> NSFetchRequest<Alarm> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isEnabled == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Alarm.time, ascending: true)]
        return request
    }
    
    /// Fetch alarms for a specific voice profile
    static func alarmsForVoiceProfile(_ voiceProfile: VoiceProfile) -> NSFetchRequest<Alarm> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "voiceProfile == %@", voiceProfile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Alarm.time, ascending: true)]
        return request
    }
    
    /// Fetch alarms that repeat on a specific day
    static func alarmsForDay(_ day: RepeatDay) -> NSFetchRequest<Alarm> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "(repeatDays & %d) != 0", day.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Alarm.time, ascending: true)]
        return request
    }
}

extension Alarm: Identifiable {}