//
//  PersistenceController.swift
//  Ryes
//
//  Created on 2/8/25.
//

import CoreData

/// Main persistence controller for Core Data stack management
final class PersistenceController {
    
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    // MARK: - Properties
    
    let container: NSPersistentContainer
    
    /// View context for main thread operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        // Try to load the model from the main bundle first
        if let modelURL = Bundle.main.url(forResource: "RyesDataModel", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            container = NSPersistentContainer(name: "RyesDataModel", managedObjectModel: model)
        } else if let modelURL = Bundle.allBundles.compactMap({ $0.url(forResource: "RyesDataModel", withExtension: "momd") }).first,
                  let model = NSManagedObjectModel(contentsOf: modelURL) {
            // Fallback to searching in all bundles (useful for tests)
            container = NSPersistentContainer(name: "RyesDataModel", managedObjectModel: model)
        } else {
            // Last resort: try default initialization
            container = NSPersistentContainer(name: "RyesDataModel")
        }
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure for local storage (CloudKit will be added later)
        container.persistentStoreDescriptions.forEach { storeDescription in
            // Enable persistent history tracking for future CloudKit integration
            storeDescription.setOption(true as NSNumber,
                                      forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
            }
            
            self?.setupViewContext()
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Setup
    
    private func setupViewContext() {
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.undoManager = nil
        viewContext.shouldDeleteInaccessibleFaults = true
    }
    
    // MARK: - Core Data Operations
    
    /// Save the view context if there are changes
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Failed to save context: \(nsError), \(nsError.userInfo)")
            // In production, handle this error appropriately
        }
    }
    
    /// Create a background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Perform background task with automatic save
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T,
                                  completion: @escaping (Result<T, Error>) -> Void) {
        container.performBackgroundTask { context in
            do {
                let result = try block(context)
                if context.hasChanges {
                    try context.save()
                }
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Preview Support
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.viewContext
        
        // Create sample data for previews
        do {
            // Sample voice profiles
            let defaultVoice = VoiceProfile(context: viewContext)
            defaultVoice.id = UUID()
            defaultVoice.name = "Default Voice"
            defaultVoice.isShared = false
            
            let customVoice = VoiceProfile(context: viewContext)
            customVoice.id = UUID()
            customVoice.name = "Morning Motivation"
            customVoice.elevenLabsVoiceId = "sample-voice-id"
            customVoice.isShared = true
            
            // Sample alarms
            let alarm1 = Alarm(context: viewContext)
            alarm1.id = UUID()
            alarm1.time = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
            alarm1.label = "Morning Workout"
            alarm1.isEnabled = true
            alarm1.repeatDays = 62 // Weekdays (Mon-Fri)
            alarm1.dismissalType = "mathPuzzle"
            alarm1.voiceProfile = customVoice
            
            let alarm2 = Alarm(context: viewContext)
            alarm2.id = UUID()
            alarm2.time = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()) ?? Date()
            alarm2.label = "Work Meeting"
            alarm2.isEnabled = false
            alarm2.repeatDays = 0 // No repeat
            alarm2.dismissalType = "standard"
            alarm2.voiceProfile = defaultVoice
            
            try viewContext.save()
        } catch {
            // Failed to create sample data
            let nsError = error as NSError
            fatalError("Failed to create preview data: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
}

// MARK: - Error Types

enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}