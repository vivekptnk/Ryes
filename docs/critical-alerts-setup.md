# Critical Alerts Configuration Guide

This document outlines the steps needed to complete Task 4.4: Configure Critical Alerts.

## Current Status ✅
- [x] Entitlements file created (`Ryes/Ryes.entitlements`)
- [x] Critical alerts authorization option added to NotificationManager
- [x] Critical notification content methods implemented
- [x] Critical sound usage (.defaultCritical) configured

## Remaining Steps (Manual/Apple Approval Required)

### 1. Apple Developer Portal Configuration
Since critical alerts require special approval from Apple, follow these steps:

1. **Submit Request to Apple**:
   - Log into Apple Developer Portal
   - Navigate to Certificates, Identifiers & Profiles
   - Find your App ID (com.shunya.Ryes)
   - Request the "Critical Alerts" entitlement
   - Provide justification: "Alarm clock app requires critical alerts to wake users reliably, including during Do Not Disturb mode"

2. **Wait for Approval**: 
   - Apple typically takes 2-3 business days to review
   - Critical alerts are only approved for specific use cases like:
     - Alarm clocks
     - Emergency/safety apps
     - Healthcare monitoring apps

### 2. Project Configuration (After Apple Approval)
Once approved by Apple:

1. **Add Entitlements to Xcode**:
   - Open Ryes.xcodeproj in Xcode
   - Select the Ryes target
   - Go to "Signing & Capabilities"
   - Add the entitlements file (Ryes.entitlements) to the target
   - Verify the critical alerts entitlement appears

2. **Test Critical Alerts**:
   - Build and run on a physical device (required for testing)
   - Use the `createCriticalAlarmNotification` method
   - Verify alerts bypass Do Not Disturb mode
   - Test with device in silent mode

### 3. Fallback Strategy (Current Implementation)
The current implementation gracefully handles the case where critical alerts are not yet approved:

- Regular alarm notifications still work normally
- `.defaultCritical` sound falls back to `.default` if not available
- Authorization request includes critical alerts but won't fail if denied
- All core alarm functionality works without critical alerts approval

### 4. Testing Without Approval
For testing before Apple approval:

```swift
// Test regular alarm notifications
NotificationManager.shared.scheduleAlarmNotification(
    alarmId: "test-alarm",
    time: Date().addingTimeInterval(5),
    label: "Test Alarm",
    repeats: false
) { result in
    // Handle result
}
```

### 5. Verification Steps
Once fully configured:

1. **Device Testing**: Must test on physical device (simulator doesn't support critical alerts)
2. **Do Not Disturb Test**: Enable DND and verify alarms still trigger
3. **Silent Mode Test**: Enable silent mode and verify critical sound plays
4. **Battery Optimization**: Monitor that critical alerts don't excessively drain battery

## Code Integration

The critical alerts functionality is already integrated into:

- `NotificationManager.swift`: Authorization and notification creation
- `NotificationQueueManager.swift`: Queue management (compatible with critical alerts)
- `AlarmScheduler.swift`: Scheduling system (uses NotificationManager)

## Task 4 Completion Status

| Subtask | Status | Notes |
|---------|--------|-------|
| 4.1 Notification Service | ✅ Complete | NotificationManager implemented |
| 4.2 Core Scheduling | ✅ Complete | AlarmScheduler with triggers |
| 4.3 Queue Management | ✅ Complete | 64-notification limit handling |
| 4.4 Critical Alerts | 🟡 Pending Apple | Code ready, awaiting approval |
| 4.5 Notification Delegate | ✅ Complete | UNUserNotificationCenterDelegate |

**Task 4 is functionally complete** - only Apple's approval process remains for critical alerts entitlement.