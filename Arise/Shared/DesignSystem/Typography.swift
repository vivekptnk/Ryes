import SwiftUI

struct AriseTypography {
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
    func ariseFont(_ size: AriseTypography.Size, weight: AriseTypography.Weight = .regular) -> some View {
        self.font(.system(size: size.rawValue, weight: weight.swiftUIWeight, design: .default))
    }
    
    func ariseDisplayFont() -> some View {
        self.ariseFont(.xxxLarge, weight: .bold)
    }
    
    func ariseLargeTitleFont() -> some View {
        self.ariseFont(.xxLarge, weight: .bold)
    }
    
    func ariseTitleFont() -> some View {
        self.ariseFont(.xLarge, weight: .semibold)
    }
    
    func ariseTitle2Font() -> some View {
        self.ariseFont(.large, weight: .semibold)
    }
    
    func ariseTitle3Font() -> some View {
        self.ariseFont(.medium, weight: .semibold)
    }
    
    func ariseBodyFont() -> some View {
        self.ariseFont(.medium, weight: .regular)
    }
    
    func ariseCalloutFont() -> some View {
        self.ariseFont(.small, weight: .regular)
    }
    
    func ariseFootnoteFont() -> some View {
        self.ariseFont(.xSmall, weight: .regular)
    }
    
    func ariseCaptionFont() -> some View {
        self.ariseFont(.xxSmall, weight: .regular)
    }
    
    func ariseCaption2Font() -> some View {
        self.ariseFont(.xxxSmall, weight: .regular)
    }
}

// MARK: - Text Styles
struct AriseTextStyle: ViewModifier {
    let size: AriseTypography.Size
    let weight: AriseTypography.Weight
    let color: Color
    let lineSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .ariseFont(size, weight: weight)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func ariseTextStyle(
        size: AriseTypography.Size,
        weight: AriseTypography.Weight = .regular,
        color: Color = .ariseForeground,
        lineSpacing: CGFloat = 2
    ) -> some View {
        self.modifier(AriseTextStyle(size: size, weight: weight, color: color, lineSpacing: lineSpacing))
    }
}