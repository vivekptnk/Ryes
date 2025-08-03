//
//  Alarm+CoreDataClass.swift
//  Ryes
//
//  Created on 2/8/25.
//

import Foundation
import CoreData

@objc(Alarm)
public class Alarm: NSManagedObject {
    
    // MARK: - Repeat Days
    
    /// Days of the week represented as bit flags
    struct RepeatDay: OptionSet {
        let rawValue: Int16
        
        static let sunday    = RepeatDay(rawValue: 1 << 0)  // 1
        static let monday    = RepeatDay(rawValue: 1 << 1)  // 2
        static let tuesday   = RepeatDay(rawValue: 1 << 2)  // 4
        static let wednesday = RepeatDay(rawValue: 1 << 3)  // 8
        static let thursday  = RepeatDay(rawValue: 1 << 4)  // 16
        static let friday    = RepeatDay(rawValue: 1 << 5)  // 32
        static let saturday  = RepeatDay(rawValue: 1 << 6)  // 64
        
        static let weekdays: RepeatDay = [.monday, .tuesday, .wednesday, .thursday, .friday]
        static let weekend: RepeatDay = [.saturday, .sunday]
        static let everyday: RepeatDay = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    }
    
    /// Dismissal types available for alarms
    enum DismissalType: String, CaseIterable {
        case standard = "standard"
        case mathPuzzle = "mathPuzzle"
        case photoChallenge = "photoChallenge"
        case qrCode = "qrCode"
        case shake = "shake"
        
        var displayName: String {
            switch self {
            case .standard:
                return "Standard"
            case .mathPuzzle:
                return "Math Puzzle"
            case .photoChallenge:
                return "Photo Challenge"
            case .qrCode:
                return "QR Code Scan"
            case .shake:
                return "Shake Phone"
            }
        }
        
        var description: String {
            switch self {
            case .standard:
                return "Swipe to dismiss"
            case .mathPuzzle:
                return "Solve a math problem to dismiss"
            case .photoChallenge:
                return "Take a specific photo to dismiss"
            case .qrCode:
                return "Scan a QR code to dismiss"
            case .shake:
                return "Shake your phone vigorously to dismiss"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get/set repeat days as RepeatDay option set
    var repeatDaysSet: RepeatDay {
        get { RepeatDay(rawValue: repeatDays) }
        set { repeatDays = newValue.rawValue }
    }
    
    /// Check if alarm repeats
    var isRepeating: Bool {
        repeatDays > 0
    }
    
    /// Get dismissal type enum
    var dismissalTypeEnum: DismissalType {
        get { DismissalType(rawValue: dismissalType ?? "standard") ?? .standard }
        set { dismissalType = newValue.rawValue }
    }
    
    /// Get next alarm date from now
    var nextAlarmDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get alarm time components
        let alarmComponents = calendar.dateComponents([.hour, .minute], from: time ?? now)
        
        // If not repeating, find next occurrence
        if !isRepeating {
            var nextDate = calendar.date(bySettingHour: alarmComponents.hour ?? 0,
                                       minute: alarmComponents.minute ?? 0,
                                       second: 0,
                                       of: now) ?? now
            
            // If time has passed today, set for tomorrow
            if nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
            
            return nextDate
        }
        
        // For repeating alarms, find next matching day
        let repeatDaysSet = self.repeatDaysSet
        var daysToAdd = 0
        var foundDay = false
        
        for i in 0..<8 { // Check up to 7 days ahead + today
            let checkDate = calendar.date(byAdding: .day, value: i, to: now) ?? now
            let weekday = calendar.component(.weekday, from: checkDate)
            
            let dayFlag: RepeatDay
            switch weekday {
            case 1: dayFlag = .sunday
            case 2: dayFlag = .monday
            case 3: dayFlag = .tuesday
            case 4: dayFlag = .wednesday
            case 5: dayFlag = .thursday
            case 6: dayFlag = .friday
            case 7: dayFlag = .saturday
            default: continue
            }
            
            if repeatDaysSet.contains(dayFlag) {
                let alarmTime = calendar.date(bySettingHour: alarmComponents.hour ?? 0,
                                            minute: alarmComponents.minute ?? 0,
                                            second: 0,
                                            of: checkDate) ?? checkDate
                
                // If it's today and time hasn't passed, or it's a future day
                if i > 0 || alarmTime > now {
                    daysToAdd = i
                    foundDay = true
                    break
                }
            }
        }
        
        if !foundDay {
            // This shouldn't happen with valid repeat days, but fallback to tomorrow
            daysToAdd = 1
        }
        
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
        return calendar.date(bySettingHour: alarmComponents.hour ?? 0,
                           minute: alarmComponents.minute ?? 0,
                           second: 0,
                           of: targetDate) ?? targetDate
    }
    
    // MARK: - Helper Methods
    
    /// Get display string for repeat days
    var repeatDaysDisplayString: String {
        let repeatDaysSet = self.repeatDaysSet
        
        if repeatDaysSet.isEmpty {
            return "Never"
        } else if repeatDaysSet == .everyday {
            return "Every day"
        } else if repeatDaysSet == .weekdays {
            return "Weekdays"
        } else if repeatDaysSet == .weekend {
            return "Weekends"
        } else {
            // Custom selection
            var days: [String] = []
            if repeatDaysSet.contains(.sunday) { days.append("Sun") }
            if repeatDaysSet.contains(.monday) { days.append("Mon") }
            if repeatDaysSet.contains(.tuesday) { days.append("Tue") }
            if repeatDaysSet.contains(.wednesday) { days.append("Wed") }
            if repeatDaysSet.contains(.thursday) { days.append("Thu") }
            if repeatDaysSet.contains(.friday) { days.append("Fri") }
            if repeatDaysSet.contains(.saturday) { days.append("Sat") }
            return days.joined(separator: " ")
        }
    }
    
    /// Create a new alarm with default values
    static func create(in context: NSManagedObjectContext,
                      time: Date = Date(),
                      label: String? = nil,
                      isEnabled: Bool = true,
                      repeatDays: RepeatDay = [],
                      dismissalType: DismissalType = .standard,
                      voiceProfile: VoiceProfile? = nil) -> Alarm {
        let alarm = Alarm(context: context)
        alarm.id = UUID()
        alarm.time = time
        alarm.label = label
        alarm.isEnabled = isEnabled
        alarm.repeatDaysSet = repeatDays
        alarm.dismissalTypeEnum = dismissalType
        alarm.voiceProfile = voiceProfile
        return alarm
    }
}