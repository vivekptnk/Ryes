import Foundation
import Security

/// Secure storage manager for API keys and sensitive data using iOS Keychain
/// Implements TR-006 requirements for secure credential storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.ryes.elevenlabs"
    private let elevenLabsAPIKeyAccount = "elevenlabs-api-key"
    
    private init() {}
    
    // MARK: - ElevenLabs API Key Management
    
    /// Stores the ElevenLabs API key securely in the keychain
    /// - Parameter apiKey: The API key to store
    /// - Returns: True if storage was successful, false otherwise
    func storeElevenLabsAPIKey(_ apiKey: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: elevenLabsAPIKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Remove any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves the ElevenLabs API key from the keychain
    /// - Returns: The API key if found, nil otherwise
    func retrieveElevenLabsAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: elevenLabsAPIKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    /// Deletes the ElevenLabs API key from the keychain
    /// - Returns: True if deletion was successful, false otherwise
    func deleteElevenLabsAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: elevenLabsAPIKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Checks if an ElevenLabs API key is stored in the keychain
    /// - Returns: True if a key exists, false otherwise
    func hasElevenLabsAPIKey() -> Bool {
        return retrieveElevenLabsAPIKey() != nil
    }
    
    // MARK: - Generic Keychain Operations
    
    /// Stores a generic string value in the keychain
    /// - Parameters:
    ///   - value: The string value to store
    ///   - account: The account identifier for the stored item
    /// - Returns: True if storage was successful, false otherwise
    func store(value: String, for account: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Remove any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves a generic string value from the keychain
    /// - Parameter account: The account identifier for the stored item
    /// - Returns: The stored value if found, nil otherwise
    func retrieve(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Deletes a generic value from the keychain
    /// - Parameter account: The account identifier for the stored item
    /// - Returns: True if deletion was successful, false otherwise
    func delete(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Keychain Error Handling

extension KeychainManager {
    enum KeychainError: Error, LocalizedError {
        case invalidData
        case itemNotFound
        case duplicateItem
        case unexpectedError(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "Invalid data provided to keychain operation"
            case .itemNotFound:
                return "Requested item not found in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .unexpectedError(let status):
                return "Unexpected keychain error: \(status)"
            }
        }
    }
    
    /// Converts OSStatus to KeychainError
    /// - Parameter status: The OSStatus returned from keychain operations
    /// - Returns: Corresponding KeychainError or nil if successful
    private func keychainError(from status: OSStatus) -> KeychainError? {
        switch status {
        case errSecSuccess:
            return nil
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        default:
            return .unexpectedError(status)
        }
    }
}