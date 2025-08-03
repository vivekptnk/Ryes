import SwiftUI

@main
struct RyesApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var alarmManager = AlarmPersistenceManager()
    @StateObject private var alarmScheduler = AlarmScheduler.shared
    
    init() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        
        // Configure tab bar appearance  
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // Setup notification categories
        AlarmScheduler.shared.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(alarmManager)
                .environmentObject(alarmScheduler)
                .onAppear {
                    // Request notification permission on first launch
                    Task {
                        _ = await alarmScheduler.requestAuthorization()
                        await alarmScheduler.scheduleAllAlarms()
                    }
                }
        }
    }
}