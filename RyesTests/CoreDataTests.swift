//
//  CoreDataTests.swift
//  AriseTests
//
//  Created on 2/8/25.
//

import Testing
@testable import Ryes 
import CoreData

@MainActor
struct CoreDataTests {
    
    // Create a new controller for each test to avoid conflicts
    private func createTestController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }
    
    @Test func testAlarmCreation() async throws {
        let testController = createTestController()
        let context = testController.viewContext
        
        // Create test alarm
        let alarm = Alarm.create(
            in: context,
            time: Date(),
            label: "Test Alarm",
            isEnabled: true,
            repeatDays: .weekdays,
            dismissalType: .mathPuzzle
        )
        
        // Verify properties
        #expect(alarm.id != nil)
        #expect(alarm.label == "Test Alarm")
        #expect(alarm.isEnabled == true)
        #expect(alarm.repeatDaysSet == .weekdays)
        #expect(alarm.dismissalTypeEnum == .mathPuzzle)
        
        // Save and verify
        try context.save()
        
        let fetchRequest = Alarm.fetchRequest()
        let alarms = try context.fetch(fetchRequest)
        #expect(alarms.count == 1)
    }
    
    @Test func testVoiceProfileCreation() async throws {
        let testController = createTestController()
        let context = testController.viewContext
        
        // Create test voice profile
        let profile = VoiceProfile.create(
            in: context,
            name: "Test Voice",
            isShared: true
        )
        
        // Verify properties
        #expect(profile.id != nil)
        #expect(profile.name == "Test Voice")
        #expect(profile.isShared == true)
        #expect(profile.hasRecording == false)
        #expect(profile.isSyncedWithElevenLabs == false)
        
        // Save and verify
        try context.save()
        
        let fetchRequest = VoiceProfile.fetchRequest()
        let profiles = try context.fetch(fetchRequest)
        #expect(profiles.count == 1)
    }
    
    @Test func testAlarmVoiceProfileRelationship() async throws {
        let testController = createTestController()
        let context = testController.viewContext
        
        // Create voice profile
        let profile = VoiceProfile.create(
            in: context,
            name: "Morning Voice"
        )
        
        // Save the profile first to ensure it's properly persisted
        try context.save()
        
        // Create alarms with this profile
        let alarm1 = Alarm.create(
            in: context,
            time: Date(),
            label: "Alarm 1",
            voiceProfile: profile
        )
        
        let alarm2 = Alarm.create(
            in: context,
            time: Date().addingTimeInterval(3600),
            label: "Alarm 2",
            voiceProfile: profile
        )
        
        try context.save()
        
        // Verify relationships
        #expect(alarm1.voiceProfile == profile)
        #expect(alarm2.voiceProfile == profile)
        #expect(profile.alarmCount == 2)
        #expect(profile.alarmsArray.count == 2)
    }
    
    @Test func testAlarmNextDateCalculation() async throws {
        let testController = createTestController()
        let context = testController.viewContext
        let calendar = Calendar.current
        let now = Date()
        
        // Test non-repeating alarm
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowAt7AM = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow)!
        
        let alarm = Alarm.create(
            in: context,
            time: tomorrowAt7AM,
            repeatDays: []
        )
        
        let nextDate = alarm.nextAlarmDate
        let components = calendar.dateComponents([.hour, .minute], from: nextDate)
        #expect(components.hour == 7)
        #expect(components.minute == 0)
        
        // Test repeating alarm for weekdays
        let weekdayAlarm = Alarm.create(
            in: context,
            time: Date(),
            repeatDays: .weekdays
        )
        
        let nextWeekdayDate = weekdayAlarm.nextAlarmDate
        let weekday = calendar.component(.weekday, from: nextWeekdayDate)
        #expect(weekday >= 2 && weekday <= 6) // Monday through Friday
    }
    
    @Test func testPersistenceManager() async throws {
        let testController = createTestController()
        let manager = AlarmPersistenceManager(persistenceController: testController)
        
        // Create voice profile
        let profile = manager.createVoiceProfile(
            name: "Test Profile",
            isShared: false
        )
        
        #expect(profile.name == "Test Profile")
        #expect(manager.voiceProfiles.count == 1)
        
        // Fetch the profile from the context to ensure it's properly managed
        manager.fetchVoiceProfiles()
        guard let fetchedProfile = manager.voiceProfiles.first else {
            #expect(Bool(false), "Failed to fetch voice profile")
            return
        }
        
        // Create alarm with the fetched profile
        let alarm = manager.createAlarm(
            time: Date(),
            label: "Manager Test",
            repeatDays: .everyday,
            dismissalType: .shake,
            voiceProfile: fetchedProfile
        )
        
        #expect(alarm.label == "Manager Test")
        #expect(alarm.voiceProfile?.id == fetchedProfile.id)
        #expect(manager.alarms.count == 1)
        
        // Test statistics
        let stats = manager.getAlarmStatistics()
        #expect(stats.totalAlarms == 1)
        #expect(stats.enabledAlarms == 1)
        #expect(stats.repeatingAlarms == 1)
    }
}
