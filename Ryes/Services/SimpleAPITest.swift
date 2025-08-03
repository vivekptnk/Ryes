import Foundation

/// Simple test to verify API client initialization works
class SimpleAPITest {
    static func testInit() {
        print("🧪 Testing ElevenLabsAPIClient initialization...")
        
        // Test 1: Create client
        let client = ElevenLabsAPIClient()
        print("✅ API client created successfully")
        
        // Test 2: Create VoiceSynthesisService
        let service = VoiceSynthesisService.shared
        print("✅ VoiceSynthesisService created successfully")
        
        // Test 3: Check configuration
        let isConfigured = service.isConfigured
        print("✅ Configuration check: \(isConfigured ? "Configured" : "Not configured")")
        
        print("✅ All initialization tests passed!")
    }
}