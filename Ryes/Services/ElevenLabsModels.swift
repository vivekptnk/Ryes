import Foundation

// MARK: - Text-to-Speech Request Models

/// Request model for ElevenLabs text-to-speech API
struct TextToSpeechRequest: Codable {
    let text: String
    let modelId: String
    let voiceSettings: VoiceSettings?
    
    enum CodingKeys: String, CodingKey {
        case text
        case modelId = "model_id"
        case voiceSettings = "voice_settings"
    }
}

/// Voice settings for text-to-speech requests
struct VoiceSettings: Codable {
    let stability: Double
    let similarityBoost: Double
    let style: Double?
    let useSpeakerBoost: Bool?
    
    enum CodingKeys: String, CodingKey {
        case stability
        case similarityBoost = "similarity_boost"
        case style
        case useSpeakerBoost = "use_speaker_boost"
    }
    
    /// Default voice settings optimized for alarm messages
    static let alarmOptimized = VoiceSettings(
        stability: 0.5,
        similarityBoost: 0.8,
        style: 0.0,
        useSpeakerBoost: true
    )
    
    /// High quality voice settings for premium users
    static let highQuality = VoiceSettings(
        stability: 0.7,
        similarityBoost: 0.9,
        style: 0.2,
        useSpeakerBoost: true
    )
    
    /// Fast processing settings for quick responses
    static let fastProcessing = VoiceSettings(
        stability: 0.3,
        similarityBoost: 0.6,
        style: 0.0,
        useSpeakerBoost: false
    )
}

// MARK: - Voice Management Models

/// Response model for voice listing
struct VoicesResponse: Codable {
    let voices: [Voice]
}

/// Individual voice model
struct Voice: Codable, Identifiable {
    let voiceId: String
    let name: String
    let category: String?
    let description: String?
    let previewUrl: String?
    let availableForTiers: [String]?
    let settings: VoiceSettings?
    
    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
        case category
        case description
        case previewUrl = "preview_url"
        case availableForTiers = "available_for_tiers"
        case settings
    }
    
    var id: String { voiceId }
    
    /// Check if voice is available for current user tier
    func isAvailable(for tier: SubscriptionTier) -> Bool {
        guard let availableForTiers = availableForTiers else { return true }
        return availableForTiers.contains(tier.rawValue)
    }
}

/// Subscription tiers for voice availability
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case starter = "starter"
    case creator = "creator"
    case pro = "pro"
    case scale = "scale"
    case enterprise = "enterprise"
}

// MARK: - Voice Cloning Models

/// Request model for adding a new voice
struct AddVoiceRequest: Codable {
    let name: String
    let description: String?
    let labels: [String: String]?
    
    /// Initialize with basic voice information
    init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
        self.labels = nil
    }
}

/// Response model for voice creation
struct AddVoiceResponse: Codable {
    let voiceId: String
    let name: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
        case status
    }
    
    /// Check if voice creation was successful
    var isSuccessful: Bool {
        return status.lowercased() == "ok" || status.lowercased() == "created"
    }
}

// MARK: - API Response Models

/// Generic API error response
struct APIErrorResponse: Codable {
    let detail: String?
    let message: String?
    let code: String?
    
    var errorMessage: String {
        return detail ?? message ?? "Unknown error occurred"
    }
}

/// User information response
struct UserResponse: Codable {
    let subscription: SubscriptionInfo
    let isNewUser: Bool
    let xiApiKey: String
    
    enum CodingKeys: String, CodingKey {
        case subscription
        case isNewUser = "is_new_user"
        case xiApiKey = "xi_api_key"
    }
}

/// Subscription information
struct SubscriptionInfo: Codable {
    let tier: String
    let characterCount: Int
    let characterLimit: Int
    let canExtendCharacterLimit: Bool
    let allowedToExtendCharacterLimit: Bool
    let nextCharacterCountResetUnix: Int
    
    enum CodingKeys: String, CodingKey {
        case tier
        case characterCount = "character_count"
        case characterLimit = "character_limit"
        case canExtendCharacterLimit = "can_extend_character_limit"
        case allowedToExtendCharacterLimit = "allowed_to_extend_character_limit"
        case nextCharacterCountResetUnix = "next_character_count_reset_unix"
    }
    
    /// Remaining character count
    var remainingCharacters: Int {
        return max(0, characterLimit - characterCount)
    }
    
    /// Usage percentage (0.0 to 1.0)
    var usagePercentage: Double {
        guard characterLimit > 0 else { return 0.0 }
        return Double(characterCount) / Double(characterLimit)
    }
    
    /// Date when character count resets
    var resetDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(nextCharacterCountResetUnix))
    }
    
    /// Check if near quota limit (>90% usage)
    var isNearQuotaLimit: Bool {
        return usagePercentage > 0.9
    }
}

// MARK: - Model Constants

extension TextToSpeechRequest {
    /// ElevenLabs model IDs
    enum ModelID {
        static let flash = "eleven_flash_v2_5"  // Primary model for low latency
        static let turbo = "eleven_turbo_v2_5"  // Alternative fast model
        static let multilingual = "eleven_multilingual_v2"  // For multiple languages
        static let monolingual = "eleven_monolingual_v1"  // English only, high quality
    }
}

// MARK: - Validation Helpers

extension TextToSpeechRequest {
    /// Validates the request before sending
    func validate() throws {
        if text.isEmpty {
            throw ElevenLabsError.badRequest(message: "Text cannot be empty")
        }
        
        if text.count > 5000 {
            throw ElevenLabsError.textTooLong(maxLength: 5000)
        }
        
        if modelId.isEmpty {
            throw ElevenLabsError.badRequest(message: "Model ID is required")
        }
    }
}

extension VoiceSettings {
    /// Validates voice settings
    func validate() throws {
        if stability < 0.0 || stability > 1.0 {
            throw ElevenLabsError.badRequest(message: "Stability must be between 0.0 and 1.0")
        }
        
        if similarityBoost < 0.0 || similarityBoost > 1.0 {
            throw ElevenLabsError.badRequest(message: "Similarity boost must be between 0.0 and 1.0")
        }
        
        if let style = style, (style < 0.0 || style > 1.0) {
            throw ElevenLabsError.badRequest(message: "Style must be between 0.0 and 1.0")
        }
    }
}