import XCTest
import UserNotifications
@testable import Ryes

// Helper extension for Result
extension Result {
    var failureValue: Failure? {
        switch self {
        case .failure(let error):
            return error
        case .success:
            return nil
        }
    }
}

@MainActor
final class NotificationSchedulingTests: XCTestCase {
    
    var sut: NotificationManager!
    
    override func setUp() {
        super.setUp()
        sut = NotificationManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up is handled in each test
        sut = nil
    }
    
    // MARK: - Single Alarm Tests
    
    func testScheduleSingleAlarmNotification() {
        // Given
        let expectation = expectation(description: "Schedule single alarm")
        let alarmId = UUID().uuidString
        let alarmTime = Date().addingTimeInterval(3600) // 1 hour from now
        let label = "Test Alarm"
        
        // When
        sut.scheduleAlarmNotification(
            alarmId: alarmId,
            time: alarmTime,
            label: label,
            sound: nil
        ) { result in
            // Then
            switch result {
            case .success:
                // Verify the notification was scheduled
                self.sut.getPendingNotifications { requests in
                    let scheduledAlarm = requests.first { $0.identifier == alarmId }
                    XCTAssertNotNil(scheduledAlarm, "Alarm should be scheduled")
                    
                    if let content = scheduledAlarm?.content {
                        XCTAssertEqual(content.title, "Alarm")
                        XCTAssertEqual(content.body, label)
                    }
                    
                    if let trigger = scheduledAlarm?.trigger as? UNCalendarNotificationTrigger {
                        XCTAssertFalse(trigger.repeats, "Single alarm should not repeat")
                    }
                    
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed to schedule alarm: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Recurring Alarm Tests
    
    func testScheduleRecurringAlarmNotifications() {
        // Given
        let expectation = expectation(description: "Schedule recurring alarm")
        let alarmId = UUID().uuidString
        let alarmTime = Date()
        let label = "Recurring Test Alarm"
        let repeatDays: Set<Int> = [2, 4, 6] // Monday, Wednesday, Friday
        
        // When
        sut.scheduleRecurringAlarmNotifications(
            alarmId: alarmId,
            time: alarmTime,
            label: label,
            repeatDays: repeatDays,
            sound: nil
        ) { result in
            // Then
            switch result {
            case .success(let identifiers):
                XCTAssertEqual(identifiers.count, repeatDays.count, "Should schedule one notification per day")
                
                // Verify each day was scheduled
                self.sut.getPendingNotifications { requests in
                    for weekday in repeatDays {
                        let expectedId = "\(alarmId)-\(weekday)"
                        let notification = requests.first { $0.identifier == expectedId }
                        XCTAssertNotNil(notification, "Notification for weekday \(weekday) should exist")
                        
                        if let trigger = notification?.trigger as? UNCalendarNotificationTrigger {
                            XCTAssertTrue(trigger.repeats, "Recurring alarm should repeat")
                            XCTAssertEqual(trigger.dateComponents.weekday, weekday)
                        }
                    }
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to schedule recurring alarm: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Cancellation Tests
    
    func testCancelSpecificNotifications() {
        // Given
        let expectation = expectation(description: "Cancel specific notifications")
        let alarmId1 = UUID().uuidString
        let alarmId2 = UUID().uuidString
        let alarmTime = Date().addingTimeInterval(3600)
        
        // Use a serial approach to avoid race conditions
        var testError: Error?
        
        // Schedule first alarm
        sut.scheduleAlarmNotification(alarmId: alarmId1, time: alarmTime, label: "Alarm 1", sound: nil) { result1 in
            guard case .success = result1 else {
                testError = result1.failureValue
                expectation.fulfill()
                return
            }
            
            // Schedule second alarm
            self.sut.scheduleAlarmNotification(alarmId: alarmId2, time: alarmTime, label: "Alarm 2", sound: nil) { result2 in
                guard case .success = result2 else {
                    testError = result2.failureValue
                    expectation.fulfill()
                    return
                }
                
                // Cancel first alarm
                self.sut.cancelNotifications(identifiers: [alarmId1]) { cancelResult in
                    guard case .success = cancelResult else {
                        testError = cancelResult.failureValue
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify results
                    self.sut.getPendingNotifications { requests in
                        let alarm1Exists = requests.contains { $0.identifier == alarmId1 }
                        let alarm2Exists = requests.contains { $0.identifier == alarmId2 }
                        
                        XCTAssertFalse(alarm1Exists, "Alarm 1 should be cancelled")
                        XCTAssertTrue(alarm2Exists, "Alarm 2 should still exist")
                        
                        // Clean up
                        self.sut.cancelNotifications(identifiers: [alarmId2])
                        
                        expectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5.0)
        
        if let error = testError {
            XCTFail("Test failed with error: \(error)")
        }
    }
    
    func testCancelAllAlarmNotifications() {
        // Given
        let expectation = expectation(description: "Cancel all alarm notifications")
        let alarmId = UUID().uuidString
        let repeatDays: Set<Int> = [1, 3, 5] // Sunday, Tuesday, Thursday
        
        // Schedule a recurring alarm
        sut.scheduleRecurringAlarmNotifications(
            alarmId: alarmId,
            time: Date(),
            label: "Test",
            repeatDays: repeatDays,
            sound: nil
        ) { _ in
            // When - Cancel all notifications for this alarm
            self.sut.cancelAlarmNotifications(alarmId: alarmId) { result in
                // Then
                switch result {
                case .success:
                    self.sut.getPendingNotifications { requests in
                        let alarmNotifications = requests.filter { $0.identifier.hasPrefix(alarmId) }
                        XCTAssertTrue(alarmNotifications.isEmpty, "All alarm notifications should be cancelled")
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail("Failed to cancel alarm notifications: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - Sound Tests
    
    func testScheduleAlarmWithCustomSound() {
        // Given
        let expectation = expectation(description: "Schedule alarm with custom sound")
        let alarmId = UUID().uuidString
        let customSound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName("alarm.wav"))
        
        // When
        sut.scheduleAlarmNotification(
            alarmId: alarmId,
            time: Date().addingTimeInterval(3600),
            label: "Custom Sound Alarm",
            sound: customSound
        ) { result in
            // Then
            switch result {
            case .success:
                self.sut.getPendingNotifications { requests in
                    let notification = requests.first { $0.identifier == alarmId }
                    XCTAssertNotNil(notification?.content.sound, "Notification should have a sound")
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed to schedule alarm with custom sound: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
}