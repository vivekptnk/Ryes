import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let arisePrimary = Color("ArisePrimary", bundle: .main)
    static let ariseSecondary = Color("AriseSecondary", bundle: .main)
    
    // MARK: - Semantic Colors
    static let ariseBackground = Color("AriseBackground", bundle: .main)
    static let ariseBackgroundSecondary = Color("AriseBackgroundSecondary", bundle: .main)
    static let ariseForeground = Color("AriseForeground", bundle: .main)
    static let ariseForegroundSecondary = Color("AriseForegroundSecondary", bundle: .main)
    
    // MARK: - Accent Colors
    static let ariseSuccess = Color("AriseSuccess", bundle: .main)
    static let ariseWarning = Color("AriseWarning", bundle: .main)
    static let ariseError = Color("AriseError", bundle: .main)
    static let ariseInfo = Color("AriseInfo", bundle: .main)
    
    // MARK: - Mission Colors
    static let ariseMissionMath = Color("AriseMissionMath", bundle: .main)
    static let ariseMissionPhoto = Color("AriseMissionPhoto", bundle: .main)
    static let ariseMissionQR = Color("AriseMissionQR", bundle: .main)
    static let ariseMissionShake = Color("AriseMissionShake", bundle: .main)
}

// MARK: - Fallback Colors for Preview
extension Color {
    static var arisePrimaryFallback: Color {
        #if DEBUG
        return Color(red: 0.25, green: 0.47, blue: 0.85) // Royal Blue
        #else
        return arisePrimary
        #endif
    }
    
    static var ariseSecondaryFallback: Color {
        #if DEBUG
        return Color(red: 0.95, green: 0.77, blue: 0.06) // Gold
        #else
        return ariseSecondary
        #endif
    }
}