import XCTest
@testable import Ryes

/// Comprehensive test suite for ElevenLabs API integration
/// Tests all components with mocked responses to avoid live API calls
final class ElevenLabsIntegrationTests: XCTestCase {
    
    var keychainManager: KeychainManager!
    var synthesisService: VoiceSynthesisService!
    
    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager.shared
        synthesisService = MainActor.assumeIsolated {
            VoiceSynthesisService.shared
        }
        
        // Clean up any existing test data
        _ = keychainManager.deleteElevenLabsAPIKey()
    }
    
    override func tearDown() {
        // Clean up after tests
        _ = keychainManager.deleteElevenLabsAPIKey()
        super.tearDown()
    }
    
    // MARK: - Keychain Manager Tests
    
    func testKeychainAPIKeyStorage() {
        let testAPIKey = "sk-test123456789"
        
        // Test storing API key
        let storeResult = keychainManager.storeElevenLabsAPIKey(testAPIKey)
        XCTAssertTrue(storeResult, "Should successfully store API key")
        
        // Test checking if key exists
        XCTAssertTrue(keychainManager.hasElevenLabsAPIKey(), "Should detect stored API key")
        
        // Test retrieving API key
        let retrievedKey = keychainManager.retrieveElevenLabsAPIKey()
        XCTAssertEqual(retrievedKey, testAPIKey, "Retrieved key should match stored key")
        
        // Test deleting API key
        let deleteResult = keychainManager.deleteElevenLabsAPIKey()
        XCTAssertTrue(deleteResult, "Should successfully delete API key")
        
        // Test key no longer exists
        XCTAssertFalse(keychainManager.hasElevenLabsAPIKey(), "Should not detect key after deletion")
        XCTAssertNil(keychainManager.retrieveElevenLabsAPIKey(), "Should not retrieve deleted key")
    }
    
    func testKeychainGenericStorage() {
        let testAccount = "test-account"
        let testValue = "test-value-123"
        
        // Test storing generic value
        let storeResult = keychainManager.store(value: testValue, for: testAccount)
        XCTAssertTrue(storeResult, "Should successfully store generic value")
        
        // Test retrieving generic value
        let retrievedValue = keychainManager.retrieve(for: testAccount)
        XCTAssertEqual(retrievedValue, testValue, "Retrieved value should match stored value")
        
        // Test deleting generic value
        let deleteResult = keychainManager.delete(for: testAccount)
        XCTAssertTrue(deleteResult, "Should successfully delete generic value")
        
        // Test value no longer exists
        XCTAssertNil(keychainManager.retrieve(for: testAccount), "Should not retrieve deleted value")
    }
    
    // MARK: - Error Handling Tests
    
    func testElevenLabsErrorMapping() {
        // Test HTTP status code mapping
        let invalidKeyError = ElevenLabsError.from(statusCode: 401)
        XCTAssertEqual(invalidKeyError, .invalidAPIKey)
        
        let rateLimitError = ElevenLabsError.from(statusCode: 429)
        if case .rateLimitExceeded = rateLimitError {
            XCTAssertTrue(true, "Should map to rate limit error")
        } else {
            XCTFail("Should map 429 to rate limit error")
        }
        
        let serverError = ElevenLabsError.from(statusCode: 500)
        if case .serverError(let code, _) = serverError {
            XCTAssertEqual(code, 500)
        } else {
            XCTFail("Should map 500 to server error")
        }
    }
    
    func testElevenLabsErrorRetryLogic() {
        // Test retryable errors
        XCTAssertTrue(ElevenLabsError.rateLimitExceeded(retryAfter: nil).isRetryable)
        XCTAssertTrue(ElevenLabsError.requestTimeout.isRetryable)
        XCTAssertTrue(ElevenLabsError.networkUnavailable.isRetryable)
        XCTAssertTrue(ElevenLabsError.serverError(code: 500, message: nil).isRetryable)
        
        // Test non-retryable errors
        XCTAssertFalse(ElevenLabsError.invalidAPIKey.isRetryable)
        XCTAssertFalse(ElevenLabsError.textTooLong(maxLength: 5000).isRetryable)
        XCTAssertFalse(ElevenLabsError.voiceNotFound.isRetryable)
    }
    
    func testErrorDescriptions() {
        let invalidKeyError = ElevenLabsError.invalidAPIKey
        XCTAssertNotNil(invalidKeyError.errorDescription)
        XCTAssertNotNil(invalidKeyError.recoverySuggestion)
        
        let quotaError = ElevenLabsError.quotaExceeded
        XCTAssertNotNil(quotaError.errorDescription)
        XCTAssertNotNil(quotaError.recoverySuggestion)
        
        let textTooLongError = ElevenLabsError.textTooLong(maxLength: 5000)
        XCTAssertTrue(textTooLongError.errorDescription?.contains("5000") == true)
    }
    
    // MARK: - Model Validation Tests
    
    func testTextToSpeechRequestValidation() {
        // Test valid request
        let validRequest = TextToSpeechRequest(
            text: "Hello world",
            modelId: TextToSpeechRequest.ModelID.flash,
            voiceSettings: .alarmOptimized
        )
        
        XCTAssertNoThrow(try validRequest.validate())
        
        // Test empty text
        let emptyTextRequest = TextToSpeechRequest(
            text: "",
            modelId: TextToSpeechRequest.ModelID.flash,
            voiceSettings: .alarmOptimized
        )
        
        XCTAssertThrowsError(try emptyTextRequest.validate()) { error in
            if case ElevenLabsError.badRequest = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Should throw bad request error for empty text")
            }
        }
        
        // Test text too long
        let longText = String(repeating: "a", count: 5001)
        let longTextRequest = TextToSpeechRequest(
            text: longText,
            modelId: TextToSpeechRequest.ModelID.flash,
            voiceSettings: .alarmOptimized
        )
        
        XCTAssertThrowsError(try longTextRequest.validate()) { error in
            if case ElevenLabsError.textTooLong = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Should throw text too long error")
            }
        }
    }
    
    func testVoiceSettingsValidation() {
        // Test valid settings
        let validSettings = VoiceSettings.alarmOptimized
        XCTAssertNoThrow(try validSettings.validate())
        
        // Test invalid stability
        let invalidStability = VoiceSettings(
            stability: 1.5,
            similarityBoost: 0.5,
            style: 0.0,
            useSpeakerBoost: true
        )
        
        XCTAssertThrowsError(try invalidStability.validate())
        
        // Test invalid similarity boost
        let invalidSimilarity = VoiceSettings(
            stability: 0.5,
            similarityBoost: -0.1,
            style: 0.0,
            useSpeakerBoost: true
        )
        
        XCTAssertThrowsError(try invalidSimilarity.validate())
    }
    
    // MARK: - Voice Model Tests
    
    func testVoiceAvailabilityForTiers() {
        let freeVoice = Voice(
            voiceId: "test-free",
            name: "Free Voice",
            category: "premade",
            description: "Test voice",
            previewUrl: nil,
            availableForTiers: ["free", "starter", "creator"],
            settings: nil
        )
        
        XCTAssertTrue(freeVoice.isAvailable(for: .free))
        XCTAssertTrue(freeVoice.isAvailable(for: .starter))
        XCTAssertTrue(freeVoice.isAvailable(for: .creator))
        XCTAssertFalse(freeVoice.isAvailable(for: .pro))
        
        let premiumVoice = Voice(
            voiceId: "test-premium",
            name: "Premium Voice",
            category: "cloned",
            description: "Premium test voice",
            previewUrl: nil,
            availableForTiers: ["pro", "scale"],
            settings: nil
        )
        
        XCTAssertFalse(premiumVoice.isAvailable(for: .free))
        XCTAssertTrue(premiumVoice.isAvailable(for: .pro))
        XCTAssertTrue(premiumVoice.isAvailable(for: .scale))
    }
    
    func testSubscriptionInfoCalculations() {
        let subscription = SubscriptionInfo(
            tier: "free",
            characterCount: 9000,
            characterLimit: 10000,
            canExtendCharacterLimit: false,
            allowedToExtendCharacterLimit: false,
            nextCharacterCountResetUnix: Int(Date().timeIntervalSince1970) + 3600
        )
        
        XCTAssertEqual(subscription.remainingCharacters, 1000)
        XCTAssertEqual(subscription.usagePercentage, 0.9, accuracy: 0.01)
        XCTAssertTrue(subscription.isNearQuotaLimit)
        
        let resetDate = subscription.resetDate
        XCTAssertTrue(resetDate > Date())
    }
    
    // MARK: - Mock Data Tests
    
    func testJSONDecodingWithMockData() {
        // Test VoicesResponse decoding
        let voicesJSON = """
        {
            "voices": [
                {
                    "voice_id": "21m00Tcm4TlvDq8ikWAM",
                    "name": "Rachel",
                    "category": "premade",
                    "description": "Professional female voice",
                    "available_for_tiers": ["free", "starter", "creator", "pro"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        XCTAssertNoThrow(try JSONDecoder().decode(VoicesResponse.self, from: voicesJSON))
        
        // Test AddVoiceResponse decoding
        let addVoiceJSON = """
        {
            "voice_id": "new-voice-123",
            "name": "Custom Voice",
            "status": "ok"
        }
        """.data(using: .utf8)!
        
        let response = try? JSONDecoder().decode(AddVoiceResponse.self, from: addVoiceJSON)
        XCTAssertNotNil(response)
        XCTAssertTrue(response?.isSuccessful == true)
        
        // Test UserResponse decoding
        let userJSON = """
        {
            "subscription": {
                "tier": "free",
                "character_count": 5000,
                "character_limit": 10000,
                "can_extend_character_limit": false,
                "allowed_to_extend_character_limit": false,
                "next_character_count_reset_unix": 1704067200
            },
            "is_new_user": false,
            "xi_api_key": "sk-test123"
        }
        """.data(using: .utf8)!
        
        XCTAssertNoThrow(try JSONDecoder().decode(UserResponse.self, from: userJSON))
    }
    
    // MARK: - Integration Tests with Mocked Network
    
    @MainActor
    func testVoiceSynthesisServiceConfiguration() async {
        // Test initial state
        XCTAssertFalse(synthesisService.isConfigured)
        XCTAssertTrue(synthesisService.availableVoices.isEmpty)
        
        // Test API key setup
        let testAPIKey = "sk-test123456789"
        let setupResult = synthesisService.setupAPIKey(testAPIKey)
        XCTAssertTrue(setupResult)
        XCTAssertTrue(synthesisService.isConfigured)
        
        // Test API key removal
        synthesisService.removeAPIKey()
        XCTAssertFalse(synthesisService.isConfigured)
        XCTAssertTrue(synthesisService.availableVoices.isEmpty)
        XCTAssertNil(synthesisService.userInfo)
    }
    
    @MainActor
    func testDefaultVoices() {
        let defaultVoices = VoiceSynthesisService.defaultVoices
        
        XCTAssertFalse(defaultVoices.professionalMale.isEmpty)
        XCTAssertFalse(defaultVoices.professionalFemale.isEmpty)
        XCTAssertFalse(defaultVoices.calmSoothing.isEmpty)
        XCTAssertFalse(defaultVoices.energetic.isEmpty)
        XCTAssertFalse(defaultVoices.alarm.isEmpty)
        
        XCTAssertEqual(defaultVoices.all.count, 4)
        XCTAssertTrue(defaultVoices.all.contains(defaultVoices.professionalMale))
        XCTAssertTrue(defaultVoices.all.contains(defaultVoices.professionalFemale))
    }
    
    @MainActor
    func testCharacterQuotaChecking() async {
        // Setup service with mock user info
        let testAPIKey = "sk-test123"
        _ = synthesisService.setupAPIKey(testAPIKey)
        
        // Mock user info with limited quota
        let mockSubscription = SubscriptionInfo(
            tier: "free",
            characterCount: 9500,
            characterLimit: 10000,
            canExtendCharacterLimit: false,
            allowedToExtendCharacterLimit: false,
            nextCharacterCountResetUnix: Int(Date().timeIntervalSince1970) + 3600
        )
        
        let mockUserInfo = UserResponse(
            subscription: mockSubscription,
            isNewUser: false,
            xiApiKey: testAPIKey
        )
        
        synthesisService.userInfo = mockUserInfo
        
        // Test quota checking
        XCTAssertEqual(synthesisService.remainingCharacters, 500)
        XCTAssertTrue(synthesisService.isNearQuotaLimit)
        
        // Test text length checking
        let shortText = "Hello"
        let longText = String(repeating: "a", count: 600)
        
        XCTAssertTrue(synthesisService.hasCharactersAvailable(for: shortText))
        XCTAssertFalse(synthesisService.hasCharactersAvailable(for: longText))
    }
    
    // MARK: - Performance Tests
    
    func testKeychainPerformance() {
        let testAPIKey = "sk-performance-test-123456789"
        
        measure {
            // Test keychain operations performance
            for i in 0..<100 {
                let key = "\(testAPIKey)-\(i)"
                _ = keychainManager.store(value: key, for: "perf-test-\(i)")
                _ = keychainManager.retrieve(for: "perf-test-\(i)")
                _ = keychainManager.delete(for: "perf-test-\(i)")
            }
        }
    }
    
    func testModelValidationPerformance() {
        let longText = String(repeating: "Hello world! ", count: 100)
        let request = TextToSpeechRequest(
            text: longText,
            modelId: TextToSpeechRequest.ModelID.flash,
            voiceSettings: .alarmOptimized
        )
        
        measure {
            for _ in 0..<1000 {
                _ = try? request.validate()
            }
        }
    }
}

// MARK: - Mock URL Protocol for Network Testing

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // No-op
    }
    
    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
    }
}