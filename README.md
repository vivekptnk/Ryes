# Ryes - AI-Powered Alarm App

Ryes is an innovative iOS alarm application that transforms the wake-up experience through AI voice synthesis, mission-based dismissal mechanisms, and deep iOS ecosystem integration.

## Features

- 🎙️ **AI Voice Synthesis**: Personalized wake-up messages using ElevenLabs voice cloning
- 🧩 **Mission-Based Dismissal**: Math puzzles, photo challenges, QR scanning, and more
- 📱 **iOS Integration**: HealthKit sleep tracking, Calendar awareness, Apple Watch support
- 🔒 **Privacy-First**: Encrypted voice data handling with local storage options
- ⏰ **Smart Wake Windows**: Optimal wake times based on sleep cycles

## Requirements

- iOS 16.0+
- iPhone 11 or newer
- Xcode 16.0+
- Swift 5.0+

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/vivekptnk/ryes.git
cd ryes
```

2. Open the project in Xcode:
```bash
open Ryes.xcodeproj
```

3. Build and run the project (⌘+R)

## Project Structure

```
Ryes/
├── Ryes/                 # Main iOS app
│   ├── App/              # App lifecycle and configuration
│   ├── Core/             # Core data models and services
│   ├── Features/         # Feature modules
│   ├── Resources/        # Assets and resources
│   └── Shared/           # Shared utilities and extensions
├── RyesTests/           # Unit tests
├── RyesUITests/         # UI tests
└── docs/                 # Technical documentation
```

## Development

### Building

```bash
xcodebuild -project Ryes.xcodeproj -scheme Ryes -configuration Debug build
```

### Testing

```bash
xcodebuild test -project Ryes.xcodeproj -scheme Ryes -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Code Quality

This project uses SwiftLint for code quality. Run it locally:

```bash
swiftlint
```

## CI/CD

The project uses GitHub Actions for continuous integration. Every push and pull request triggers:

- Build verification
- Unit and UI test execution
- SwiftLint code quality checks

## Contributing

Please read our contributing guidelines before submitting pull requests.

## License

This project is proprietary software. All rights reserved.