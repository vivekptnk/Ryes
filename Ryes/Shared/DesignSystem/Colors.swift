import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let ryesPrimary = Color("RyesPrimary", bundle: .main)
    static let ryesSecondary = Color("RyesSecondary", bundle: .main)
    
    // MARK: - Semantic Colors
    static let ryesBackground = Color("RyesBackground", bundle: .main)
    static let ryesBackgroundSecondary = Color("RyesBackgroundSecondary", bundle: .main)
    static let ryesForeground = Color("RyesForeground", bundle: .main)
    static let ryesForegroundSecondary = Color("RyesForegroundSecondary", bundle: .main)
    
    // MARK: - Accent Colors
    static let ryesSuccess = Color("RyesSuccess", bundle: .main)
    static let ryesWarning = Color("RyesWarning", bundle: .main)
    static let ryesError = Color("RyesError", bundle: .main)
    static let ryesInfo = Color("RyesInfo", bundle: .main)
    
    // MARK: - Mission Colors
    static let ryesMissionMath = Color("RyesMissionMath", bundle: .main)
    static let ryesMissionPhoto = Color("RyesMissionPhoto", bundle: .main)
    static let ryesMissionQR = Color("RyesMissionQR", bundle: .main)
    static let ryesMissionShake = Color("RyesMissionShake", bundle: .main)
}

// MARK: - Fallback Colors for Preview
extension Color {
    static var ryesPrimaryFallback: Color {
        #if DEBUG
        return Color(red: 0.25, green: 0.47, blue: 0.85) // Royal Blue
        #else
        return ryesPrimary
        #endif
    }
    
    static var ryesSecondaryFallback: Color {
        #if DEBUG
        return Color(red: 0.95, green: 0.77, blue: 0.06) // Gold
        #else
        return ryesSecondary
        #endif
    }
}