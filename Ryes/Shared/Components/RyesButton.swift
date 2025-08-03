import SwiftUI

struct RyesButton: View {
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
                .ryesFont(fontSize, weight: .semibold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(backgroundColor)
                .ryesCornerRadius()
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
    private var fontSize: RyesTypography.Size {
        switch size {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return RyesSpacing.small
        case .medium: return RyesSpacing.medium
        case .large: return RyesSpacing.large
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return RyesSpacing.xSmall
        case .medium: return RyesSpacing.small
        case .large: return RyesSpacing.medium
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .ryesPrimaryFallback
        case .destructive: return .white
        case .ghost: return .ryesPrimaryFallback
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .ryesPrimaryFallback
        case .secondary: return .ryesPrimaryFallback.opacity(0.1)
        case .destructive: return .red
        case .ghost: return .clear
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: RyesSpacing.medium) {
        RyesButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }
        
        RyesButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        RyesButton("Destructive Button", style: .destructive) {
            print("Destructive tapped")
        }
        
        RyesButton("Ghost Button", style: .ghost) {
            print("Ghost tapped")
        }
        
        HStack(spacing: RyesSpacing.small) {
            RyesButton("Small", size: .small) {
                print("Small tapped")
            }
            
            RyesButton("Large", size: .large) {
                print("Large tapped")
            }
        }
    }
    .ryesScreenPadding()
}