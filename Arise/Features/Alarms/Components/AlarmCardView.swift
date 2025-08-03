import SwiftUI
import CoreData

struct AlarmCardView: View {
    @ObservedObject var alarm: Alarm
    @EnvironmentObject private var alarmManager: AlarmPersistenceManager
    
    var onTap: () -> Void
    var onDelete: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: AriseSpacing.medium) {
            // Time Display
            VStack(alignment: .leading, spacing: AriseSpacing.xSmall) {
                Text(timeFormatter.string(from: alarm.time ?? Date()))
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                    .foregroundColor(alarm.isEnabled ? .primary : .secondary)
                    .lineLimit(1)
                
                // Label and Repeat Info
                HStack(spacing: AriseSpacing.xSmall) {
                    if let label = alarm.label, !label.isEmpty {
                        Text(label)
                            .ariseCaptionFont()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if alarm.repeatDays > 0 {
                        if alarm.label != nil && !alarm.label!.isEmpty {
                            Text("•")
                                .ariseCaptionFont()
                                .foregroundColor(.secondary)
                        }
                        
                        Text(alarm.repeatDaysDisplayString)
                            .ariseCaptionFont()
                            .foregroundColor(.ariseSecondaryFallback)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        alarm.isEnabled = newValue
                        alarmManager.updateAlarmWithScheduling(alarm)
                    }
                }
            ))
            .labelsHidden()
            .tint(.arisePrimaryFallback)
            .scaleEffect(0.9)
        }
        .padding(.horizontal, AriseSpacing.medium)
        .padding(.vertical, AriseSpacing.small + 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to edit. Swipe to reveal delete option.")
        .accessibilityAddTraits(alarm.isEnabled ? [] : .isButton)
    }
    
    private var accessibilityLabel: String {
        var components: [String] = []
        
        // Time
        components.append("Alarm at \(timeFormatter.string(from: alarm.time ?? Date()))")
        
        // Label
        if let label = alarm.label, !label.isEmpty {
            components.append("labeled \(label)")
        }
        
        // Repeat
        if alarm.repeatDays > 0 {
            components.append("repeats \(alarm.repeatDaysDisplayString)")
        }
        
        // Enabled state
        components.append(alarm.isEnabled ? "enabled" : "disabled")
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Preview Provider
struct AlarmCardView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample alarms
        let alarm1 = Alarm.create(
            in: context,
            time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!,
            label: "Morning Workout",
            isEnabled: true,
            repeatDays: .weekdays
        )
        
        let alarm2 = Alarm.create(
            in: context,
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            label: nil,
            isEnabled: false,
            repeatDays: []
        )
        
        let alarm3 = Alarm.create(
            in: context,
            time: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!,
            label: "Bedtime",
            isEnabled: true,
            repeatDays: .everyday
        )
        
        return VStack(spacing: AriseSpacing.medium) {
            AlarmCardView(alarm: alarm1, onTap: {}, onDelete: {})
            AlarmCardView(alarm: alarm2, onTap: {}, onDelete: {})
            AlarmCardView(alarm: alarm3, onTap: {}, onDelete: {})
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(AlarmPersistenceManager())
    }
}