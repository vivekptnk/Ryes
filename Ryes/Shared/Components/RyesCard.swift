import SwiftUI

struct RyesCard<Content: View>: View {
    let content: () -> Content
    var backgroundColor: Color = Color(.systemBackground)
    var shadowRadius: CGFloat = 4
    
    init(
        backgroundColor: Color = Color(.systemBackground),
        shadowRadius: CGFloat = 4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .ryesCardPadding()
            .background(backgroundColor)
            .ryesCornerRadius(RyesCornerRadius.large)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: RyesSpacing.medium) {
        RyesCard {
            VStack(alignment: .leading, spacing: RyesSpacing.small) {
                Text("Card Title")
                    .ryesTitleFont()
                Text("This is a basic card component with default styling.")
                    .ryesBodyFont()
                    .foregroundColor(.secondary)
            }
        }
        
        RyesCard(backgroundColor: .ryesPrimaryFallback.opacity(0.1)) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.ryesPrimaryFallback)
                
                VStack(alignment: .leading, spacing: RyesSpacing.xxSmall) {
                    Text("Alarm Set")
                        .ryesCalloutFont()
                        .fontWeight(.semibold)
                    Text("Wake up at 7:00 AM")
                        .ryesCaptionFont()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    .ryesScreenPadding()
    .background(Color(.systemGray6))
}