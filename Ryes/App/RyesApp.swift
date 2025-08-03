import SwiftUI

@main
struct RyesApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var alarmManager = AlarmPersistenceManager()
    @StateObject private var alarmScheduler = AlarmScheduler.shared
    @StateObject private var backgroundAudioService = BackgroundAudioService.shared
    
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
        
        // Setup app lifecycle notifications for background audio
        setupBackgroundAudioLifecycle()
    }
    
    private func setupBackgroundAudioLifecycle() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            BackgroundAudioService.shared.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            BackgroundAudioService.shared.handleAppWillEnterForeground()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(alarmManager)
                .environmentObject(alarmScheduler)
                .environmentObject(backgroundAudioService)
                .onAppear {
                    // Request notification permission on first launch
                    alarmScheduler.requestAuthorization { granted in
                        if granted {
                            alarmScheduler.scheduleAllAlarms()
                        }
                    }
                }
        }
    }
}