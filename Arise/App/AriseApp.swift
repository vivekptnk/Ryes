import SwiftUI

@main
struct AriseApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var alarmManager = AlarmPersistenceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(alarmManager)
        }
    }
}