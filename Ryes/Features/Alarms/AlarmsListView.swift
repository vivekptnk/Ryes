import SwiftUI
import CoreData

struct AlarmsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var alarmManager: AlarmPersistenceManager
    @State private var showingCreateAlarm = false
    @State private var alarmToEdit: Alarm?
    @State private var showingPermissionView = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Alarm.time, ascending: true)
        ],
        animation: .default
    ) private var alarms: FetchedResults<Alarm>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    if alarms.isEmpty {
                        EmptyAlarmsView()
                    } else {
                        AlarmsList(alarms: alarms, alarmToEdit: $alarmToEdit)
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            checkPermissionAndCreateAlarm()
                        }
                        .padding(.trailing, RyesSpacing.medium)
                        .padding(.bottom, RyesSpacing.medium)
                    }
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCreateAlarm) {
            AlarmEditView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(alarmManager)
        }
        .sheet(item: $alarmToEdit) { alarm in
            AlarmEditView(alarm: alarm)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(alarmManager)
        }
        .sheet(isPresented: $showingPermissionView) {
            NotificationPermissionView()
        }
    }
    
    // MARK: - Helper Methods
    private func checkPermissionAndCreateAlarm() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            switch status {
            case .authorized, .provisional, .ephemeral:
                showingCreateAlarm = true
            case .denied:
                showingPermissionView = true
            case .notDetermined:
                NotificationManager.shared.requestAuthorization { granted, _ in
                    if granted {
                        showingCreateAlarm = true
                    } else {
                        showingPermissionView = true
                    }
                }
            @unknown default:
                showingPermissionView = true
            }
        }
    }
}

// MARK: - Empty State View
private struct EmptyAlarmsView: View {
    var body: some View {
        VStack(spacing: RyesSpacing.large) {
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundColor(.ryesPrimary)
            
            VStack(spacing: RyesSpacing.small) {
                Text("No Alarms")
                    .ryesTitleFont()
                    .fontWeight(.semibold)
                
                Text("Tap the + button to create your first alarm")
                    .ryesBodyFont()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Alarms List
private struct AlarmsList: View {
    let alarms: FetchedResults<Alarm>
    @Binding var alarmToEdit: Alarm?
    @EnvironmentObject private var alarmManager: AlarmPersistenceManager
    @State private var alarmToDelete: Alarm?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: RyesSpacing.small) {
                ForEach(alarms) { alarm in
                    AlarmCardView(
                        alarm: alarm,
                        onTap: {
                            alarmToEdit = alarm
                        },
                        onDelete: {
                            alarmToDelete = alarm
                            showingDeleteAlert = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: AnyTransition.scale.combined(with: .opacity),
                        removal: AnyTransition.scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, RyesSpacing.medium)
            .padding(.vertical, RyesSpacing.small)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Delete Alarm?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                alarmToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let alarm = alarmToDelete {
                    alarmManager.deleteAlarmWithScheduling(alarm)
                    alarmToDelete = nil
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

#Preview {
    AlarmsListView()
}