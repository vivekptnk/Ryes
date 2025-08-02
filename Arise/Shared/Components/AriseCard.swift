import SwiftUI

struct AriseCard<Content: View>: View {
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
            .ariseCardPadding()
            .background(backgroundColor)
            .ariseCornerRadius(AriseCornerRadius.large)
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
    VStack(spacing: AriseSpacing.medium) {
        AriseCard {
            VStack(alignment: .leading, spacing: AriseSpacing.small) {
                Text("Card Title")
                    .ariseTitleFont()
                Text("This is a basic card component with default styling.")
                    .ariseBodyFont()
                    .foregroundColor(.secondary)
            }
        }
        
        AriseCard(backgroundColor: .arisePrimaryFallback.opacity(0.1)) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.arisePrimaryFallback)
                
                VStack(alignment: .leading, spacing: AriseSpacing.xxSmall) {
                    Text("Alarm Set")
                        .ariseCalloutFont()
                        .fontWeight(.semibold)
                    Text("Wake up at 7:00 AM")
                        .ariseCaptionFont()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    .ariseScreenPadding()
    .background(Color(.systemGray6))
}