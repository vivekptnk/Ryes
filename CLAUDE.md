# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arise is an AI-powered iOS alarm application built with SwiftUI that transforms the wake-up experience through:
- AI voice synthesis using ElevenLabs for personalized wake-up messages
- Mission-based dismissal mechanisms (math puzzles, photo challenges, QR scanning)
- Deep iOS ecosystem integration (HealthKit, Calendar, Apple Watch)
- Privacy-first encrypted voice data handling

## Development Setup

### Build and Run
```bash
# Build the project
xcodebuild -project Arise.xcodeproj -scheme Arise -configuration Debug build

# Run on simulator
xcrun simctl boot "iPhone 15 Pro"
xcodebuild -project Arise.xcodeproj -scheme Arise -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug

# Run on device (requires provisioning profile)
xcodebuild -project Arise.xcodeproj -scheme Arise -destination 'platform=iOS,name=Your Device Name' -configuration Debug
```

### Testing
```bash
# Run all tests
xcodebuild test -project Arise.xcodeproj -scheme Arise -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test
xcodebuild test -project Arise.xcodeproj -scheme Arise -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AriseTests/AriseTests/example
```

### Code Quality
```bash
# Format Swift code (install SwiftFormat if needed)
swiftformat .

# Lint code (install SwiftLint if needed)
swiftlint
```

## Architecture

### Project Structure
- **Arise/**: Main iOS app target containing SwiftUI views and app logic
- **AriseTests/**: Unit tests using Swift Testing framework
- **AriseUITests/**: UI automation tests
- **docs/**: Technical documentation including the comprehensive PRD

### Key Technical Components

#### Background Execution Strategy
The app requires persistent background execution for reliable alarm triggering. Implement using:
- Silent audio playback with AVAudioPlayer
- Local notification scheduling (max 64 notifications)
- Critical alerts (requires Apple approval)

#### Data Architecture
Core Data entities needed:
- **Alarm**: UUID, time, label, isEnabled, repeatDays, voiceProfileId, dismissalType
- **VoiceProfile**: UUID, name, elevenLabsVoiceId, isShared

#### Third-Party Integrations
- **ElevenLabs API**: Voice synthesis and cloning
  - Model: eleven_flash_v2_5 for low latency
  - Endpoints: /v1/text-to-speech/{voice_id}, /v1/voices/add
  - Rate limits: 10,000 characters/month (free tier)

#### Security Requirements
- AES-256 encryption for voice recordings
- Keychain storage for API keys
- Certificate pinning for API calls
- Biometric authentication for sensitive settings

### Platform Requirements
- Minimum iOS 16.0
- iPhone 11 and newer
- watchOS 9.0+ for Apple Watch app
- Universal app with iPad support

## Common Development Tasks

### Adding New Dismissal Mechanisms
1. Create new dismissal type in Core Data model
2. Implement dismissal view in SwiftUI
3. Add validation logic
4. Update alarm configuration UI
5. Test accessibility compliance

### Implementing Voice Features
1. Set up ElevenLabs API client with proper error handling
2. Implement voice recording workflow with quality validation
3. Cache synthesized audio locally
4. Handle offline fallback scenarios

### Apple Watch Integration
1. Create Watch app target
2. Implement WatchConnectivity for data sync
3. Design custom complications
4. Ensure independent alarm functionality

## Testing Strategy
- Unit test coverage target: 80% for business logic
- Focus areas: alarm scheduling, time zone calculations, dismissal challenges
- UI tests for complete user flows
- Performance testing for background execution and battery usage

## Task Management

### Task Master MCP Integration
This project uses Task Master MCP (Model Context Protocol) for task tracking and management. Tasks are stored in `.taskmaster/tasks/tasks.json`.

To view and update tasks:
```bash
# Tasks are stored in .taskmaster/tasks/tasks.json
# Use Task Master MCP to:
- Create new tasks for features/bugs
- Update task status as you progress
- Track dependencies between tasks
- Manage sprint planning
```

### Development Workflow
When working on this project:
1. Check existing tasks using Task Master MCP before starting new work
2. Create tasks for any new features or significant changes
3. Update task status as you complete work
4. Link commits to task IDs for traceability

### Commit Strategy for Subtasks
**Important**: After completing each subtask from tasks.json:
1. Verify with the user that the implementation works correctly
2. Once verified, create a commit with a clear message referencing the subtask ID
3. Commit message format: `feat: [Task X.Y] Description of what was implemented`
4. Example: `feat: [Task 1.4] Implement design system colors and typography`

This ensures:
- Clear project history and traceability
- Easy rollback if issues arise
- Better collaboration and code review