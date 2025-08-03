import SwiftUI

struct RepeatDaysSelector: View {
    @Binding var selectedDays: Set<Int>
    
    private let days = [
        (1, "S", "Sunday"),
        (2, "M", "Monday"),
        (3, "T", "Tuesday"),
        (4, "W", "Wednesday"),
        (5, "T", "Thursday"),
        (6, "F", "Friday"),
        (7, "S", "Saturday")
    ]
    
    private let hapticFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: RyesSpacing.medium) {
            // Quick select buttons
            HStack(spacing: RyesSpacing.small) {
                QuickSelectButton(title: "Everyday", isSelected: selectedDays.count == 7) {
                    if selectedDays.count == 7 {
                        selectedDays.removeAll()
                    } else {
                        selectedDays = Set(1...7)
                    }
                }
                
                QuickSelectButton(title: "Weekdays", isSelected: selectedDays == Set([2, 3, 4, 5, 6])) {
                    if selectedDays == Set([2, 3, 4, 5, 6]) {
                        selectedDays.removeAll()
                    } else {
                        selectedDays = Set([2, 3, 4, 5, 6])
                    }
                }
                
                QuickSelectButton(title: "Weekends", isSelected: selectedDays == Set([1, 7])) {
                    if selectedDays == Set([1, 7]) {
                        selectedDays.removeAll()
                    } else {
                        selectedDays = Set([1, 7])
                    }
                }
            }
            
            // Individual day buttons
            HStack(spacing: RyesSpacing.xSmall) {
                ForEach(days, id: \.0) { day, letter, fullName in
                    DayButton(
                        letter: letter,
                        fullName: fullName,
                        isSelected: selectedDays.contains(day)
                    ) {
                        hapticFeedback.selectionChanged()
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }
}

// MARK: - Quick Select Button
private struct QuickSelectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .ryesCaptionFont()
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, RyesSpacing.small)
                .padding(.vertical, RyesSpacing.xSmall)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.ryesPrimaryFallback : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day Button
private struct DayButton: View {
    let letter: String
    let fullName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.ryesPrimaryFallback : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(fullName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview
struct RepeatDaysSelector_Previews: PreviewProvider {
    @State static var selectedDays1: Set<Int> = []
    @State static var selectedDays2: Set<Int> = [2, 3, 4, 5, 6]
    @State static var selectedDays3: Set<Int> = Set(1...7)
    
    static var previews: some View {
        VStack(spacing: RyesSpacing.xLarge) {
            VStack(alignment: .leading, spacing: RyesSpacing.small) {
                Text("No days selected")
                    .ryesCaptionFont()
                    .foregroundColor(.secondary)
                RepeatDaysSelector(selectedDays: $selectedDays1)
            }
            
            VStack(alignment: .leading, spacing: RyesSpacing.small) {
                Text("Weekdays selected")
                    .ryesCaptionFont()
                    .foregroundColor(.secondary)
                RepeatDaysSelector(selectedDays: $selectedDays2)
            }
            
            VStack(alignment: .leading, spacing: RyesSpacing.small) {
                Text("All days selected")
                    .ryesCaptionFont()
                    .foregroundColor(.secondary)
                RepeatDaysSelector(selectedDays: $selectedDays3)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}