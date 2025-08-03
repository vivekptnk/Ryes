import SwiftUI

struct RyesTypography {
    // MARK: - Font Sizes
    enum Size: CGFloat {
        case xxxLarge = 34   // Display
        case xxLarge = 28    // Large Title
        case xLarge = 22     // Title 1
        case large = 20      // Title 2
        case medium = 17     // Title 3 / Body
        case small = 15      // Callout
        case xSmall = 13     // Footnote
        case xxSmall = 11    // Caption 1
        case xxxSmall = 10   // Caption 2
    }
    
    // MARK: - Font Weights
    enum Weight {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black
        
        var swiftUIWeight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            }
        }
    }
}

// MARK: - Font Modifiers
extension View {
    func ryesFont(_ size: RyesTypography.Size, weight: RyesTypography.Weight = .regular) -> some View {
        self.font(.system(size: size.rawValue, weight: weight.swiftUIWeight, design: .default))
    }
    
    func ryesDisplayFont() -> some View {
        self.ryesFont(.xxxLarge, weight: .bold)
    }
    
    func ryesLargeTitleFont() -> some View {
        self.ryesFont(.xxLarge, weight: .bold)
    }
    
    func ryesTitleFont() -> some View {
        self.ryesFont(.xLarge, weight: .semibold)
    }
    
    func ryesTitle2Font() -> some View {
        self.ryesFont(.large, weight: .semibold)
    }
    
    func ryesTitle3Font() -> some View {
        self.ryesFont(.medium, weight: .semibold)
    }
    
    func ryesBodyFont() -> some View {
        self.ryesFont(.medium, weight: .regular)
    }
    
    func ryesCalloutFont() -> some View {
        self.ryesFont(.small, weight: .regular)
    }
    
    func ryesFootnoteFont() -> some View {
        self.ryesFont(.xSmall, weight: .regular)
    }
    
    func ryesCaptionFont() -> some View {
        self.ryesFont(.xxSmall, weight: .regular)
    }
    
    func ryesCaption2Font() -> some View {
        self.ryesFont(.xxxSmall, weight: .regular)
    }
}

// MARK: - Text Styles
struct RyesTextStyle: ViewModifier {
    let size: RyesTypography.Size
    let weight: RyesTypography.Weight
    let color: Color
    let lineSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .ryesFont(size, weight: weight)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func ryesTextStyle(
        size: RyesTypography.Size,
        weight: RyesTypography.Weight = .regular,
        color: Color = .ryesForeground,
        lineSpacing: CGFloat = 2
    ) -> some View {
        self.modifier(RyesTextStyle(size: size, weight: weight, color: color, lineSpacing: lineSpacing))
    }
}