import XCTest
import CoreData
@testable import Ryes

final class NotificationQueueTests: XCTestCase {
    
    var sut: NotificationQueueManager!
    var testController: PersistenceController!
    var alarmManager: AlarmPersistenceManager!
    
    override func setUp() {
        super.setUp()
        testController = PersistenceController(inMemory: true)
        alarmManager = AlarmPersistenceManager(persistenceController: testController)
        sut = NotificationQueueManager(alarmManager: alarmManager)
    }
    
    override func tearDown() {
        // Clean up any scheduled notifications
        NotificationManager.shared.getPendingNotifications { requests in
            let identifiers = requests.map { $0.identifier }
            NotificationManager.shared.cancelNotifications(identifiers: identifiers)
        }
        sut = nil
        alarmManager = nil
        testController = nil
        super.tearDown()
    }
    
    // MARK: - Queue Status Tests
    
    func testGetQueueStatus() {
        let expectation = expectation(description: "Get queue status")
        
        sut.getQueueStatus { status in
            XCTAssertNotNil(status)
            XCTAssertGreaterThanOrEqual(status.availableSlots, 0)
            XCTAssertLessThanOrEqual(status.totalNotifications, NotificationQueueManager.maxNotifications)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testQueueStatusCalculations() {
        let expectation = expectation(description: "Queue status calculations")
        
        // Create some test alarms
        let alarm1 = alarmManager.createAlarm(
            time: Date().addingTimeInterval(3600),
            label: "Test Alarm 1",
            isEnabled: true
        )
        
        let alarm2 = alarmManager.createAlarm(
            time: Date().addingTimeInterval(7200),
            label: "Test Alarm 2",
            isEnabled: true,
            repeatDays: .weekdays
        )
        
        // Schedule alarms
        sut.scheduleAllAlarmsWithLimit { result in
            switch result {
            case .success(let report):
                XCTAssertEqual(report.totalAlarms, 2)
                XCTAssertGreaterThan(report.scheduledAlarms, 0)
                
                // Check queue status
                self.sut.getQueueStatus { status in
                    XCTAssertGreaterThan(status.alarmNotifications, 0)
                    XCTAssertLessThan(status.availableAlarmSlots, NotificationQueueManager.maxScheduledAlarms)
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to schedule alarms: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleAllAlarmsWithLimit() {
        let expectation = expectation(description: "Schedule alarms with limit")
        
        // Create multiple alarms
        for i in 0..<10 {
            _ = alarmManager.createAlarm(
                time: Date().addingTimeInterval(Double(i * 3600)),
                label: "Test Alarm \(i)",
                isEnabled: true
            )
        }
        
        sut.scheduleAllAlarmsWithLimit { result in
            switch result {
            case .success(let report):
                XCTAssertEqual(report.totalAlarms, 10)
                XCTAssertGreaterThan(report.scheduledAlarms, 0)
                XCTAssertLessThanOrEqual(report.scheduledAlarms, NotificationQueueManager.maxScheduledAlarms)
                XCTAssertEqual(report.successRate, Double(report.scheduledAlarms) / Double(report.totalAlarms), accuracy: 0.01)
                
            case .failure(let error):
                XCTFail("Failed to schedule alarms: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testRecurringAlarmLimitHandling() {
        let expectation = expectation(description: "Recurring alarm limit handling")
        
        // Create a recurring alarm that would generate 7 notifications
        let recurringAlarm = alarmManager.createAlarm(
            time: Date().addingTimeInterval(3600),
            label: "Daily Alarm",
            isEnabled: true,
            repeatDays: .everyday
        )
        
        // Add enough single alarms to approach the limit
        for i in 0..<55 {
            _ = alarmManager.createAlarm(
                time: Date().addingTimeInterval(Double((i + 2) * 3600)),
                label: "Single Alarm \(i)",
                isEnabled: true
            )
        }
        
        sut.scheduleAllAlarmsWithLimit { result in
            switch result {
            case .success(let report):
                // Should have limited the total scheduled alarms
                XCTAssertLessThanOrEqual(report.scheduledAlarms, NotificationQueueManager.maxScheduledAlarms)
                
                if report.skippedAlarms > 0 {
                    print("Correctly skipped \(report.skippedAlarms) alarms due to limit")
                }
                
            case .failure(let error):
                XCTFail("Failed to schedule alarms: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Add/Remove Tests
    
    func testAddAlarmToQueue() {
        let expectation = expectation(description: "Add alarm to queue")
        
        let alarm = alarmManager.createAlarm(
            time: Date().addingTimeInterval(3600),
            label: "New Alarm",
            isEnabled: true
        )
        
        sut.addAlarmToQueue(alarm) { result in
            switch result {
            case .success:
                // Verify it was scheduled
                self.sut.getQueueStatus { status in
                    XCTAssertGreaterThan(status.alarmNotifications, 0)
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to add alarm to queue: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testRemoveAlarmFromQueue() {
        let expectation = expectation(description: "Remove alarm from queue")
        
        let alarm = alarmManager.createAlarm(
            time: Date().addingTimeInterval(3600),
            label: "Alarm to Remove",
            isEnabled: true
        )
        
        // First add it
        sut.addAlarmToQueue(alarm) { _ in
            // Then remove it
            self.sut.removeAlarmFromQueue(alarm) { result in
                switch result {
                case .success:
                    // Verify it was removed
                    NotificationManager.shared.getPendingNotifications { requests in
                        let alarmNotifications = requests.filter { $0.identifier.contains(alarm.id?.uuidString ?? "") }
                        XCTAssertEqual(alarmNotifications.count, 0)
                        expectation.fulfill()
                    }
                    
                case .failure(let error):
                    XCTFail("Failed to remove alarm from queue: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - Priority Tests
    
    func testAlarmPriorityScheduling() {
        let expectation = expectation(description: "Priority-based scheduling")
        
        let now = Date()
        
        // Create alarms with different times (priority)
        let urgentAlarm = alarmManager.createAlarm(
            time: now.addingTimeInterval(300), // 5 minutes
            label: "Urgent",
            isEnabled: true
        )
        
        let laterAlarm = alarmManager.createAlarm(
            time: now.addingTimeInterval(86400), // 24 hours
            label: "Later",
            isEnabled: true
        )
        
        let soonAlarm = alarmManager.createAlarm(
            time: now.addingTimeInterval(3600), // 1 hour
            label: "Soon",
            isEnabled: true
        )
        
        sut.scheduleAllAlarmsWithLimit { result in
            switch result {
            case .success(let report):
                XCTAssertEqual(report.scheduledAlarms, 3)
                
                // Verify urgent alarm was scheduled
                NotificationManager.shared.getPendingNotifications { requests in
                    let urgentScheduled = requests.contains { $0.identifier == urgentAlarm.id?.uuidString }
                    XCTAssertTrue(urgentScheduled, "Urgent alarm should be scheduled")
                    expectation.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to schedule alarms: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
}