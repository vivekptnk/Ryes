import SwiftUI
import CoreData

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var alarmManager: AlarmPersistenceManager
    
    @State private var selectedTime = Date()
    @State private var alarmLabel = ""
    @State private var isEnabled = true
    @State private var showingDiscardAlert = false
    @State private var hasChanges = false
    
    // Collapsible sections
    @State private var isRepeatExpanded = false
    @State private var isAdvancedExpanded = false
    
    // Repeat days
    @State private var selectedRepeatDays: Set<Int> = []
    
    // Advanced options
    @State private var selectedDismissalType: Alarm.DismissalType = .standard
    @State private var selectedVoiceProfile: VoiceProfile?
    
    // Haptic feedback generator
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // For edit mode
    let alarm: Alarm?
    
    init(alarm: Alarm? = nil) {
        self.alarm = alarm
        
        // Initialize state with existing alarm data
        if let alarm = alarm {
            _selectedTime = State(initialValue: alarm.time ?? Date())
            _alarmLabel = State(initialValue: alarm.label ?? "")
            _isEnabled = State(initialValue: alarm.isEnabled)
            _selectedDismissalType = State(initialValue: alarm.dismissalTypeEnum)
            _selectedVoiceProfile = State(initialValue: alarm.voiceProfile)
            
            // Convert repeat days to set
            var repeatSet = Set<Int>()
            let repeatDaysSet = alarm.repeatDaysSet
            if repeatDaysSet.contains(.sunday) { repeatSet.insert(1) }
            if repeatDaysSet.contains(.monday) { repeatSet.insert(2) }
            if repeatDaysSet.contains(.tuesday) { repeatSet.insert(3) }
            if repeatDaysSet.contains(.wednesday) { repeatSet.insert(4) }
            if repeatDaysSet.contains(.thursday) { repeatSet.insert(5) }
            if repeatDaysSet.contains(.friday) { repeatSet.insert(6) }
            if repeatDaysSet.contains(.saturday) { repeatSet.insert(7) }
            _selectedRepeatDays = State(initialValue: repeatSet)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RyesSpacing.large) {
                        // Time Picker Section
                        VStack(spacing: RyesSpacing.medium) {
                            Text("Set Alarm Time")
                                .ryesTitleFont()
                                .fontWeight(.semibold)
                            
                            DatePicker(
                                "",
                                selection: $selectedTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 216)
                            .onChange(of: selectedTime) { _ in
                                // Trigger haptic feedback on time change
                                hapticFeedback.impactOccurred()
                                hasChanges = true
                            }
                            .padding(.horizontal, RyesSpacing.medium)
                            
                            // Display formatted time
                            Text(timeFormatter.string(from: selectedTime))
                                .font(.system(size: 48, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.top, RyesSpacing.small)
                        }
                        .padding(.vertical, RyesSpacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, RyesSpacing.medium)
                        
                        // Label Section
                        VStack(alignment: .leading, spacing: RyesSpacing.small) {
                            Text("Label")
                                .ryesCaptionFont()
                                .foregroundColor(.secondary)
                                .padding(.horizontal, RyesSpacing.medium)
                            
                            TextField("Alarm Label", text: $alarmLabel)
                                .textFieldStyle(.plain)
                                .ryesBodyFont()
                                .padding(.horizontal, RyesSpacing.medium)
                                .padding(.vertical, RyesSpacing.small + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                                .onChange(of: alarmLabel) { _ in
                                    hasChanges = true
                                }
                        }
                        .padding(.horizontal, RyesSpacing.medium)
                        
                        // Enable/Disable Toggle
                        HStack {
                            Text("Enable Alarm")
                                .ryesBodyFont()
                            
                            Spacer()
                            
                            Toggle("", isOn: $isEnabled)
                                .labelsHidden()
                                .tint(.ryesPrimaryFallback)
                                .onChange(of: isEnabled) { _ in
                                    selectionFeedback.selectionChanged()
                                    hasChanges = true
                                }
                        }
                        .padding(.horizontal, RyesSpacing.medium)
                        .padding(.vertical, RyesSpacing.small + 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, RyesSpacing.medium)
                        
                        // Repeat Days Section
                        CollapsibleSection(
                            title: "Repeat",
                            subtitle: repeatDaysSubtitle,
                            isExpanded: $isRepeatExpanded
                        ) {
                            RepeatDaysSelector(selectedDays: $selectedRepeatDays)
                                .onChange(of: selectedRepeatDays) { _ in
                                    hasChanges = true
                                    selectionFeedback.selectionChanged()
                                }
                        }
                        .padding(.horizontal, RyesSpacing.medium)
                        
                        // Advanced Options Section
                        CollapsibleSection(
                            title: "Advanced Options",
                            subtitle: "Dismissal type, voice profile",
                            isExpanded: $isAdvancedExpanded
                        ) {
                            VStack(spacing: RyesSpacing.medium) {
                                // Dismissal Type Picker
                                VStack(alignment: .leading, spacing: RyesSpacing.small) {
                                    Text("Dismissal Type")
                                        .ryesCaptionFont()
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Dismissal Type", selection: $selectedDismissalType) {
                                        ForEach(Alarm.DismissalType.allCases, id: \.self) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: selectedDismissalType) { _ in
                                        hasChanges = true
                                        selectionFeedback.selectionChanged()
                                    }
                                }
                                
                                // Voice Profile (placeholder for now)
                                VStack(alignment: .leading, spacing: RyesSpacing.small) {
                                    Text("Voice Profile")
                                        .ryesCaptionFont()
                                        .foregroundColor(.secondary)
                                    
                                    Text("Coming Soon")
                                        .ryesBodyFont()
                                        .foregroundColor(Color(.tertiaryLabel))
                                }
                            }
                        }
                        .padding(.horizontal, RyesSpacing.medium)
                    }
                    .padding(.vertical, RyesSpacing.medium)
                }
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.ryesPrimaryFallback)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.ryesPrimaryFallback)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
        }
        .onAppear {
            // Prepare haptic generators
            hapticFeedback.prepare()
            selectionFeedback.prepare()
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var repeatDaysSubtitle: String {
        if selectedRepeatDays.isEmpty {
            return "Never"
        } else if selectedRepeatDays == Set([2, 3, 4, 5, 6]) {
            return "Weekdays"
        } else if selectedRepeatDays == Set([1, 7]) {
            return "Weekends"
        } else if selectedRepeatDays.count == 7 {
            return "Every day"
        } else {
            let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let selectedDayNames = selectedRepeatDays.sorted().map { day in
                dayAbbreviations[max(0, min(6, day - 1))]
            }
            return selectedDayNames.joined(separator: " ")
        }
    }
    
    private func saveAlarm() {
        // Convert selected days to RepeatDay
        var repeatDays = Alarm.RepeatDay()
        if selectedRepeatDays.contains(1) { repeatDays.insert(.sunday) }
        if selectedRepeatDays.contains(2) { repeatDays.insert(.monday) }
        if selectedRepeatDays.contains(3) { repeatDays.insert(.tuesday) }
        if selectedRepeatDays.contains(4) { repeatDays.insert(.wednesday) }
        if selectedRepeatDays.contains(5) { repeatDays.insert(.thursday) }
        if selectedRepeatDays.contains(6) { repeatDays.insert(.friday) }
        if selectedRepeatDays.contains(7) { repeatDays.insert(.saturday) }
        
        if let existingAlarm = alarm {
            // Update existing alarm
            existingAlarm.time = selectedTime
            existingAlarm.label = alarmLabel.isEmpty ? nil : alarmLabel
            existingAlarm.isEnabled = isEnabled
            existingAlarm.repeatDaysSet = repeatDays
            existingAlarm.dismissalTypeEnum = selectedDismissalType
            existingAlarm.voiceProfile = selectedVoiceProfile
            alarmManager.updateAlarmWithScheduling(existingAlarm)
        } else {
            // Create new alarm using the convenience initializer
            let context = viewContext
            let newAlarm = Alarm.create(
                in: context,
                time: selectedTime,
                label: alarmLabel.isEmpty ? nil : alarmLabel,
                isEnabled: isEnabled,
                repeatDays: repeatDays,
                dismissalType: selectedDismissalType,
                voiceProfile: selectedVoiceProfile
            )
            alarmManager.updateAlarmWithScheduling(newAlarm)
        }
        
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Preview
struct AlarmEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // New alarm preview
            AlarmEditView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(AlarmPersistenceManager())
            
            // Edit alarm preview
            AlarmEditView(alarm: createSampleAlarm())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(AlarmPersistenceManager())
        }
    }
    
    static func createSampleAlarm() -> Alarm {
        let context = PersistenceController.preview.container.viewContext
        return Alarm.create(
            in: context,
            time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!,
            label: "Morning Workout",
            isEnabled: true
        )
    }
}