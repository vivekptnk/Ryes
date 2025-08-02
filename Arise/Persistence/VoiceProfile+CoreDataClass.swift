//
//  VoiceProfile+CoreDataClass.swift
//  Arise
//
//  Created on 2/8/25.
//

import Foundation
import CoreData

@objc(VoiceProfile)
public class VoiceProfile: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Check if this voice profile has a recording
    var hasRecording: Bool {
        recordingPath != nil && !recordingPath!.isEmpty
    }
    
    /// Check if this voice profile is synced with ElevenLabs
    var isSyncedWithElevenLabs: Bool {
        elevenLabsVoiceId != nil && !elevenLabsVoiceId!.isEmpty
    }
    
    /// Get the URL for the voice recording if it exists
    var recordingURL: URL? {
        guard let path = recordingPath else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    /// Get display name with sharing status
    var displayName: String {
        let sharingIndicator = isShared ? " 🌐" : ""
        return (name ?? "Unnamed Voice") + sharingIndicator
    }
    
    /// Get status description
    var statusDescription: String {
        if isSyncedWithElevenLabs {
            return "Synced with ElevenLabs"
        } else if hasRecording {
            return "Local recording available"
        } else {
            return "No recording"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create a new voice profile with default values
    static func create(in context: NSManagedObjectContext,
                      name: String,
                      recordingPath: String? = nil,
                      elevenLabsVoiceId: String? = nil,
                      isShared: Bool = false) -> VoiceProfile {
        let profile = VoiceProfile(context: context)
        profile.id = UUID()
        profile.name = name
        profile.recordingPath = recordingPath
        profile.elevenLabsVoiceId = elevenLabsVoiceId
        profile.isShared = isShared
        return profile
    }
    
    /// Get the file path for storing voice recordings
    static func recordingFilePath(for profileId: UUID) -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first!
        let voiceRecordingsPath = documentsPath.appendingPathComponent("VoiceRecordings")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: voiceRecordingsPath,
                                               withIntermediateDirectories: true)
        
        return voiceRecordingsPath
            .appendingPathComponent("\(profileId.uuidString).m4a")
            .path
    }
    
    /// Delete the voice recording file
    func deleteRecording() {
        guard let url = recordingURL else { return }
        try? FileManager.default.removeItem(at: url)
        recordingPath = nil
    }
    
    /// Validate voice profile data
    func validate() throws {
        guard let name = name, !name.isEmpty else {
            throw ValidationError.missingName
        }
        
        if name.count > 50 {
            throw ValidationError.nameTooLong
        }
        
        if let voiceId = elevenLabsVoiceId, !voiceId.isEmpty {
            // Basic validation for ElevenLabs voice ID format
            let voiceIdRegex = "^[a-zA-Z0-9_-]+$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", voiceIdRegex)
            if !predicate.evaluate(with: voiceId) {
                throw ValidationError.invalidVoiceId
            }
        }
    }
    
    // MARK: - Error Types
    
    enum ValidationError: LocalizedError {
        case missingName
        case nameTooLong
        case invalidVoiceId
        
        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Voice profile name is required"
            case .nameTooLong:
                return "Voice profile name must be 50 characters or less"
            case .invalidVoiceId:
                return "Invalid ElevenLabs voice ID format"
            }
        }
    }
}