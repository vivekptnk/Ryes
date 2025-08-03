import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                    hapticFeedback.impactOccurred()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: AriseSpacing.xSmall) {
                        Text(title)
                            .ariseBodyFont()
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .ariseCaptionFont()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, AriseSpacing.medium)
                .padding(.vertical, AriseSpacing.small + 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                VStack(spacing: AriseSpacing.medium) {
                    content()
                }
                .padding(.top, AriseSpacing.medium)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }
}

// MARK: - Preview
struct CollapsibleSection_Previews: PreviewProvider {
    @State static var isExpanded1 = false
    @State static var isExpanded2 = true
    
    static var previews: some View {
        VStack(spacing: AriseSpacing.large) {
            CollapsibleSection(
                title: "Repeat",
                subtitle: "Weekdays",
                isExpanded: $isExpanded1
            ) {
                Text("Content for repeat section")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            CollapsibleSection(
                title: "Advanced Options",
                subtitle: "Dismissal type, voice profile",
                isExpanded: $isExpanded2
            ) {
                VStack(spacing: AriseSpacing.medium) {
                    Text("Option 1")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("Option 2")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}