import Foundation

/// Comprehensive error types for ElevenLabs API integration
/// Handles network, API, and application-specific error scenarios
enum ElevenLabsError: Error, LocalizedError {
    
    // MARK: - Network Errors
    case invalidURL
    case networkUnavailable
    case requestTimeout
    case noData
    case invalidResponse
    
    // MARK: - API Errors
    case invalidAPIKey
    case quotaExceeded
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case badRequest(message: String?)
    case voiceNotFound
    case textTooLong(maxLength: Int)
    case serverError(code: Int, message: String?)
    
    // MARK: - Authentication Errors
    case unauthorized
    case forbidden
    case apiKeyNotConfigured
    
    // MARK: - Audio Processing Errors
    case invalidAudioFormat
    case audioProcessingFailed
    case unsupportedAudioType
    
    // MARK: - General Errors
    case unknownError(underlying: Error?)
    case serviceUnavailable
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for ElevenLabs API endpoint"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .noData:
            return "No data received from ElevenLabs API"
        case .invalidResponse:
            return "Invalid response format from ElevenLabs API"
            
        case .invalidAPIKey:
            return "Invalid ElevenLabs API key. Please check your credentials."
        case .quotaExceeded:
            return "ElevenLabs API quota exceeded. Please upgrade your plan or wait for reset."
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Please retry after \(Int(retryAfter)) seconds."
            } else {
                return "Rate limit exceeded. Please try again later."
            }
        case .badRequest(let message):
            return message ?? "Bad request to ElevenLabs API"
        case .voiceNotFound:
            return "The requested voice was not found"
        case .textTooLong(let maxLength):
            return "Text is too long. Maximum length is \(maxLength) characters."
        case .serverError(let code, let message):
            return message ?? "Server error (code \(code))"
            
        case .unauthorized:
            return "Unauthorized access to ElevenLabs API"
        case .forbidden:
            return "Access forbidden. Please check your API permissions."
        case .apiKeyNotConfigured:
            return "ElevenLabs API key is not configured. Please add your API key in settings."
            
        case .invalidAudioFormat:
            return "Invalid audio format received from ElevenLabs"
        case .audioProcessingFailed:
            return "Failed to process audio data"
        case .unsupportedAudioType:
            return "Unsupported audio type"
            
        case .unknownError(let underlying):
            if let underlying = underlying {
                return "Unknown error: \(underlying.localizedDescription)"
            } else {
                return "An unknown error occurred"
            }
        case .serviceUnavailable:
            return "ElevenLabs service is temporarily unavailable"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidAPIKey:
            return "The provided API key is invalid or expired"
        case .quotaExceeded:
            return "Monthly character limit has been reached"
        case .rateLimitExceeded:
            return "Too many requests made in a short time"
        case .networkUnavailable:
            return "Device is not connected to the internet"
        case .textTooLong:
            return "Input text exceeds the maximum allowed length"
        default:
            return errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Please verify your API key in the app settings"
        case .quotaExceeded:
            return "Upgrade your ElevenLabs plan or wait for the monthly reset"
        case .rateLimitExceeded:
            return "Wait a few moments before making another request"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .textTooLong(let maxLength):
            return "Reduce the text to \(maxLength) characters or less"
        case .apiKeyNotConfigured:
            return "Add your ElevenLabs API key in the app settings"
        case .voiceNotFound:
            return "Select a different voice or create a new voice profile"
        default:
            return "Please try again later"
        }
    }
    
    // MARK: - HTTP Status Code Mapping
    
    /// Creates an ElevenLabsError from an HTTP status code and response data
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - data: Response data (optional)
    ///   - response: HTTP URL response (optional)
    /// - Returns: Appropriate ElevenLabsError
    static func from(statusCode: Int, data: Data? = nil, response: HTTPURLResponse? = nil) -> ElevenLabsError {
        // Try to parse error message from response data
        var errorMessage: String?
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            errorMessage = json["detail"] as? String ?? json["message"] as? String
        }
        
        switch statusCode {
        case 400:
            return .badRequest(message: errorMessage)
        case 401:
            return .invalidAPIKey
        case 403:
            return .forbidden
        case 404:
            return .voiceNotFound
        case 422:
            // Check if it's a text length error
            if let message = errorMessage, message.contains("too long") {
                // Extract max length if possible (default to 5000)
                let maxLength = extractMaxLength(from: message) ?? 5000
                return .textTooLong(maxLength: maxLength)
            }
            return .badRequest(message: errorMessage)
        case 429:
            let retryAfter = response?.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init)
            return .rateLimitExceeded(retryAfter: retryAfter)
        case 500...599:
            return .serverError(code: statusCode, message: errorMessage)
        default:
            return .unknownError(underlying: nil)
        }
    }
    
    /// Extracts maximum character length from error message
    private static func extractMaxLength(from message: String) -> Int? {
        let pattern = #"(\d+)\s*characters?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: message.utf16.count)
        
        if let match = regex?.firstMatch(in: message, options: [], range: range) {
            let numberRange = Range(match.range(at: 1), in: message)
            if let numberRange = numberRange {
                return Int(String(message[numberRange]))
            }
        }
        
        return nil
    }
    
    // MARK: - Retry Logic Support
    
    /// Indicates whether this error is retryable
    var isRetryable: Bool {
        switch self {
        case .rateLimitExceeded, .requestTimeout, .networkUnavailable, .serverError:
            return true
        case .serviceUnavailable:
            return true
        default:
            return false
        }
    }
    
    /// Suggested retry delay in seconds
    var retryDelay: TimeInterval {
        switch self {
        case .rateLimitExceeded(let retryAfter):
            return retryAfter ?? 5.0
        case .requestTimeout:
            return 2.0
        case .networkUnavailable:
            return 3.0
        case .serverError:
            return 5.0
        case .serviceUnavailable:
            return 10.0
        default:
            return 1.0
        }
    }
}

// MARK: - Network Error Utilities

extension ElevenLabsError {
    /// Creates an ElevenLabsError from a URLError
    /// - Parameter urlError: The URLError to convert
    /// - Returns: Appropriate ElevenLabsError
    static func from(_ urlError: URLError) -> ElevenLabsError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .requestTimeout
        case .badURL:
            return .invalidURL
        case .cannotFindHost, .cannotConnectToHost:
            return .serviceUnavailable
        default:
            return .unknownError(underlying: urlError)
        }
    }
}

// MARK: - Equatable Implementation

extension ElevenLabsError: Equatable {
    static func == (lhs: ElevenLabsError, rhs: ElevenLabsError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.networkUnavailable, .networkUnavailable),
             (.requestTimeout, .requestTimeout),
             (.noData, .noData),
             (.invalidResponse, .invalidResponse),
             (.invalidAPIKey, .invalidAPIKey),
             (.quotaExceeded, .quotaExceeded),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.apiKeyNotConfigured, .apiKeyNotConfigured),
             (.voiceNotFound, .voiceNotFound),
             (.invalidAudioFormat, .invalidAudioFormat),
             (.audioProcessingFailed, .audioProcessingFailed),
             (.unsupportedAudioType, .unsupportedAudioType),
             (.serviceUnavailable, .serviceUnavailable):
            return true
            
        case (.rateLimitExceeded(let lhsRetry), .rateLimitExceeded(let rhsRetry)):
            return lhsRetry == rhsRetry
            
        case (.badRequest(let lhsMessage), .badRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
            
        case (.textTooLong(let lhsMax), .textTooLong(let rhsMax)):
            return lhsMax == rhsMax
            
        case (.serverError(let lhsCode, let lhsMessage), .serverError(let rhsCode, let rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
            
        case (.unknownError(let lhsUnderlying), .unknownError(let rhsUnderlying)):
            // Compare underlying errors by their localized descriptions
            // since Error doesn't conform to Equatable
            return lhsUnderlying?.localizedDescription == rhsUnderlying?.localizedDescription
            
        default:
            return false
        }
    }
}