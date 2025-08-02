import SwiftUI

struct AriseButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
        case ghost
    }
    
    enum Size {
        case small
        case medium
        case large
    }
    
    let title: String
    let style: Style
    let size: Size
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        style: Style = .primary,
        size: Size = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .ariseFont(fontSize, weight: .semibold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(backgroundColor)
                .ariseCornerRadius()
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
    
    // MARK: - Computed Properties
    private var fontSize: AriseTypography.Size {
        switch size {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return AriseSpacing.small
        case .medium: return AriseSpacing.medium
        case .large: return AriseSpacing.large
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return AriseSpacing.xSmall
        case .medium: return AriseSpacing.small
        case .large: return AriseSpacing.medium
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .arisePrimaryFallback
        case .destructive: return .white
        case .ghost: return .arisePrimaryFallback
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .arisePrimaryFallback
        case .secondary: return .arisePrimaryFallback.opacity(0.1)
        case .destructive: return .red
        case .ghost: return .clear
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AriseSpacing.medium) {
        AriseButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }
        
        AriseButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        AriseButton("Destructive Button", style: .destructive) {
            print("Destructive tapped")
        }
        
        AriseButton("Ghost Button", style: .ghost) {
            print("Ghost tapped")
        }
        
        HStack(spacing: AriseSpacing.small) {
            AriseButton("Small", size: .small) {
                print("Small tapped")
            }
            
            AriseButton("Large", size: .large) {
                print("Large tapped")
            }
        }
    }
    .ariseScreenPadding()
}