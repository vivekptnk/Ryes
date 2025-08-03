import SwiftUI

/// 8pt Grid System for consistent spacing throughout the app
struct RyesSpacing {
    // MARK: - Base Unit
    private static let baseUnit: CGFloat = 8
    
    // MARK: - Spacing Values
    static let xxSmall: CGFloat = baseUnit * 0.5  // 4pt
    static let xSmall: CGFloat = baseUnit * 1     // 8pt
    static let small: CGFloat = baseUnit * 1.5    // 12pt
    static let medium: CGFloat = baseUnit * 2     // 16pt
    static let large: CGFloat = baseUnit * 3      // 24pt
    static let xLarge: CGFloat = baseUnit * 4     // 32pt
    static let xxLarge: CGFloat = baseUnit * 5    // 40pt
    static let xxxLarge: CGFloat = baseUnit * 6   // 48pt
    
    // MARK: - Component Specific Spacing
    static let buttonPadding: CGFloat = medium
    static let cardPadding: CGFloat = medium
    static let listItemSpacing: CGFloat = small
    static let sectionSpacing: CGFloat = large
    static let screenPadding: CGFloat = medium
}

// MARK: - Padding Extensions
extension View {
    func ryesPadding(_ edges: Edge.Set = .all, _ size: CGFloat = RyesSpacing.medium) -> some View {
        self.padding(edges, size)
    }
    
    func ryesScreenPadding() -> some View {
        self.padding(RyesSpacing.screenPadding)
    }
    
    func ryesCardPadding() -> some View {
        self.padding(RyesSpacing.cardPadding)
    }
    
    func ryesButtonPadding() -> some View {
        self.padding(.horizontal, RyesSpacing.buttonPadding)
            .padding(.vertical, RyesSpacing.small)
    }
}

// MARK: - Spacing View
struct RyesSpace: View {
    let height: CGFloat
    let width: CGFloat
    
    init(height: CGFloat = 0, width: CGFloat = 0) {
        self.height = height
        self.width = width
    }
    
    init(_ size: CGFloat) {
        self.height = size
        self.width = size
    }
    
    var body: some View {
        Spacer()
            .frame(width: width, height: height)
    }
}

// MARK: - Corner Radius
struct RyesCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xLarge: CGFloat = 16
    static let round: CGFloat = 9999
}

extension View {
    func ryesCornerRadius(_ radius: CGFloat = RyesCornerRadius.medium) -> some View {
        self.cornerRadius(radius)
    }
}