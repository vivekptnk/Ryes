import XCTest
import UserNotifications
@testable import Ryes

final class NotificationManagerTests: XCTestCase {
    
    var sut: NotificationManager!
    
    override func setUp() {
        super.setUp()
        // NotificationManager uses singleton, so we test the shared instance
        sut = NotificationManager.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testNotificationManagerSingleton() {
        // Given
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "NotificationManager should be a singleton")
    }
    
    func testCheckAuthorizationStatus() {
        // Given
        let expectation = expectation(description: "Authorization status check")
        
        // When
        sut.checkAuthorizationStatus { status in
            // Then
            XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
            XCTAssertNotNil(status, "Status should not be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testGetNotificationSettings() {
        // Given
        let expectation = expectation(description: "Get notification settings")
        
        // When
        sut.getNotificationSettings { settings in
            // Then
            XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
            XCTAssertNotNil(settings, "Settings should not be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testCheckCriticalAlertAuthorization() {
        // Given
        let expectation = expectation(description: "Critical alert authorization check")
        
        // When
        sut.checkCriticalAlertAuthorization { isAuthorized in
            // Then
            XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
            // Note: This will likely be false in tests unless critical alerts are enabled
            XCTAssertNotNil(isAuthorized, "Authorization status should not be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}