import SwiftUI
import UIKit

// MARK: - Colors (from Figma key colours — ☀️ light / ☽ dark)
enum AppColors {

    // Neutrals
    static let background       = Color(light: "F8F5F2", dark: "040404")   // Neutral ☀️200 ☽800
    static let surface          = Color(light: "FFFFFF", dark: "1C1C1E")   // Neutral ☀️0   ☽750
    static let surfaceDarker    = Color(light: "FCF9F7", dark: "323234")   // Neutral ☀️50  ☽700
    static let lightBackground  = Color(light: "FBF9F6", dark: "323234")   // Neutral ☀️100 ☽700
    static let separator        = Color(light: "EEEDEC", dark: "38383A")   // Neutral ☀️300 ☽700
    static let iconInactive     = Color(light: "C8C7C7", dark: "8A8986")   // Neutral ☀️400 ☽600
    static let iconDefault      = Color(light: "9E9D9C", dark: "C8C7C7")   // Neutral ☀️500 ☽400
    static let fontSecondary    = Color(light: "8A8986", dark: "9E9D9C")   // Neutral ☀️600 ☽500
    static let fontDefault      = Color(light: "323234", dark: "FFFFFF")   // Neutral ☀️700 ☽0

    // Brand — Primary / Teal
    static let primary          = Color(light: "00756A", dark: "4DD4AF")   // Primary ☀️500 ☽300
    static let primaryDark      = Color(light: "00665B", dark: "00B386")   // Primary ☀️500 ☽300

    // Supplementary neutrals (non-Figma)
    static let volcanicAsh      = Color(light: "636D77", dark: "A0A8B0")
    static let oxfordBlue       = Color(light: "333E49", dark: "8891A0")

    // Success — Primary palette
    static let successDefault    = Color(light: "009E6A", dark: "5CD9B5")   // Primary ☀️400 ☽200
    static let activeBackground  = Color(light: "D3F7E3", dark: "0D3D38")  // Primary ☀️100 ☽600
    static let successBackground = Color(light: "E9FCF4", dark: "0D2E2A")  // Primary ☀️50  ☽700

    // Danger
    static let dangerDefault     = Color(light: "CC2C11", dark: "FF6B59")  // Danger ☀️500 ☽200
    static let dangerBadge       = Color(light: "FFD2CF", dark: "5A1A0F")  // Danger ☀️100 ☽600
    static let dangerBackground  = Color(light: "FFF1F1", dark: "4A100A")  // Danger ☀️50  ☽700

    // Warning
    static let warningDefault    = Color(light: "BD5B01", dark: "FFD666")  // Warning ☀️500 ☽50
    static let warningIcon       = Color(light: "F07C0F", dark: "FFB420")  // Warning ☀️400 ☽300
    static let warningText       = Color(light: "FFB420", dark: "BD5B01")  // Warning ☀️300 ☽500
    static let warningBadge      = Color(light: "FFF0B8", dark: "5C3200")  // Warning ☀️100 ☽600
    static let warningBackground = Color(light: "FFFADF", dark: "4A2400")  // Warning ☀️50  ☽700

    // Informative
    static let informativeDefault    = Color(light: "226BD1", dark: "6BA8EC") // Informative ☀️500 ☽200
    static let informativeBackground = Color(light: "EEF8FF", dark: "152D4F") // Informative ☀️50  ☽700

    // AI
    static let aiDefault    = Color(light: "8736DC", dark: "C096ED")   // AI ☀️500 ☽200
    static let aiBackground = Color(light: "FBF4FF", dark: "2E1054")   // AI ☀️50  ☽700

    // Beta
    static let betaDefault         = Color(light: "107191", dark: "80D6E8") // BETA ☀️500 ☽100
    static let betaBackground      = Color(light: "C5F5F5", dark: "103844") // BETA ☀️100 ☽700
    static let betaLightBackground = Color(light: "E3FBFB", dark: "E3FBFB") // BETA ☀️50  ☽50
}

// MARK: - Adaptive Color (light + dark hex)

extension Color {
    init(light: String, dark: String) {
        self.init(UIColor(light: light, dark: dark))
    }

    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(light: String, dark: String) {
        self.init { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        }
    }

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Typography (SF Pro Text equivalents)
enum AppFonts {
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 17, weight: .regular) }
    static func callout() -> Font { .system(size: 16, weight: .regular) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular) }
    static func subheadlineBold() -> Font { .system(size: 15, weight: .semibold) }
    static func footnote() -> Font { .system(size: 13, weight: .regular) }
    static func caption1() -> Font { .system(size: 12, weight: .regular) }
    static func caption1Strong() -> Font { .system(size: 12, weight: .semibold) }
    static func subheadStrong() -> Font { .system(size: 14, weight: .semibold) }
    static func tabBar() -> Font { .system(size: 10, weight: .regular) }
}
