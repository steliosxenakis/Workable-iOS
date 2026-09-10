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
    static let dashboardCardFill = Color(light: "F2F2F2", dark: "2C2C2E")  // Redesign — metric card / icon fill
    static let fontSecondary    = Color(light: "8A8986", dark: "9E9D9C")   // Neutral ☀️600 ☽500
    static let fontDefault      = Color(light: "323234", dark: "FFFFFF")   // Neutral ☀️700 ☽0

    // Brand — Primary / Teal
    static let primary          = Color(light: "00756A", dark: "4DD4AF")   // Primary ☀️500 ☽300
    static let primaryDark      = Color(light: "00665B", dark: "00B386")   // Primary ☀️500 ☽300
    /// Lock Screen Live Activity card (Figma Primary/700 — 15862:458975).
    static let primary700       = Color(light: "0A2824", dark: "0A2824")
    /// Home-screen widget header / chip fill (Figma Primary/600 — 15870:541009).
    static let primary600       = Color(light: "093732", dark: "093732")
    /// Attendance-issues chip on the dark widget (Figma Warning/700).
    static let warning700       = Color(light: "462E1D", dark: "462E1D")
    /// Chip count/icon on the dark widget (Figma success-default ☀️400).
    static let widgetChipAccent = Color(light: "009E6A", dark: "009E6A")
    /// Today widget V2 (Figma Neutral/800).
    static let widgetV2Background = Color(light: "040404", dark: "040404")
    /// Mint glow ellipse on the V2 widget (Figma Ellipse 33).
    static let widgetV2MintGlow = Color(light: "67D7A1", dark: "67D7A1")
    /// Purple glow ellipse on the V2 widget (Figma Ellipse 32 / AI 200).
    static let widgetV2PurpleGlow = Color(light: "D8ADFF", dark: "D8ADFF")
    /// Widget timer seconds (Figma icon-inactive ☀️400 — 15871:545205).
    static let widgetTimerSeconds = Color(light: "C8C7C7", dark: "C8C7C7")

    /// Always-light tokens for the dark Live Activity card (does not follow system dark mode).
    static let liveActivityProgressTrack = Color(light: "D3F7E3", dark: "D3F7E3") // active-background ☀️100
    static let liveActivityProgressFill  = Color(light: "00665B", dark: "00665B") // Primary ☀️500
    static let liveActivityWarning       = Color(light: "FFB420", dark: "FFB420") // warning-text ☀️300
    static let liveActivityButtonInk     = Color(light: "323234", dark: "323234") // font-default ☀️700

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
    static let danger100         = Color(light: "FFD2CF", dark: "5E1A10")  // Danger ☀️100 ☽600

    // Warning
    static let warningDefault    = Color(light: "BD5B01", dark: "FFD666")  // Warning ☀️500 ☽50
    static let warningIcon       = Color(light: "F07C0F", dark: "FFB420")  // Warning ☀️400 ☽300
    static let warningText       = Color(light: "FFB420", dark: "BD5B01")  // Warning ☀️300 ☽500
    static let warningBadge      = Color(light: "FFF0B8", dark: "5C3200")  // Warning ☀️100 ☽600
    static let warningBackground = Color(light: "FFFADF", dark: "4A2400")  // Warning ☀️50  ☽700

    // Informative
    static let informativeDefault    = Color(light: "226BD1", dark: "6BA8EC") // Informative ☀️500 ☽200
    /// Calendar break segments (Figma Informative/200 — 15786:77791).
    static let informative200        = Color(light: "75ACFF", dark: "3A6FBF") // Informative ☀️200
    static let informativeBackground = Color(light: "EEF8FF", dark: "152D4F") // Informative ☀️50  ☽700

    // AI
    static let aiDefault    = Color(light: "8736DC", dark: "C096ED")   // AI ☀️500 ☽200
    static let aiBackground = Color(light: "FBF4FF", dark: "2E1054")   // AI ☀️50  ☽700
    /// Score pill on candidate fit summary (Figma ai/100 + ai/600 on `23609:132236`).
    static let aiFitPillFill = Color(light: "EDD5FF", dark: "4A2780")
    static let aiFitPillText = Color(light: "6509BF", dark: "E8D4FF")

    // Beta
    static let betaDefault         = Color(light: "107191", dark: "80D6E8") // BETA ☀️500 ☽100
    static let betaBackground      = Color(light: "C5F5F5", dark: "103844") // BETA ☀️100 ☽700
    static let betaLightBackground = Color(light: "E3FBFB", dark: "E3FBFB") // BETA ☀️50  ☽50
}

// MARK: - Shadows (Figma)

extension View {
    /// Figma “Light shadow” — home dashboard cards (Today, To-dos, Time off, Jobs, Candidates).
    /// `#00000012`, offset (0, 4), blur 14.
    func appLightCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
    }

    /// Time tracking home card — `#333E49` @ 4%, offset (0, 6), blur 5.
    func appTimeTrackingCardShadow() -> some View {
        shadow(color: Color(hex: "333E49").opacity(0.04), radius: 5, x: 0, y: 6)
    }
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
    /// Live Activity elapsed minutes (Figma iOS/Chunky Title).
    static func chunkyTitle() -> Font { .system(size: 34, weight: .bold) }
    /// Home-screen widget timer (Figma iOS/Title2 strong).
    static func title2Strong() -> Font { .system(size: 22, weight: .semibold) }
    /// Live Activity elapsed seconds (Figma iOS/Title3).
    static func title3() -> Font { .system(size: 20, weight: .regular) }
    /// “You’re back at work” Live Activity (Figma iOS/Title3 strong — 15864:462099).
    static func title3Strong() -> Font { .system(size: 20, weight: .semibold) }
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

// MARK: - Emoji text

/// Renders color emoji as a bitmap so SwiftUI `Button` / `foregroundStyle` / `Menu`
/// tint cannot collapse glyphs to “?” tofu.
struct EmojiText: View {
    let emoji: String
    var size: CGFloat = 24

    var body: some View {
        let resolved = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let glyph = resolved.isEmpty ? "☕" : resolved
        Image(uiImage: EmojiImageCache.image(for: glyph, pointSize: size))
            .renderingMode(.original)
            .resizable()
            .interpolation(.medium)
            .scaledToFit()
            .frame(width: size, height: size)
            .fixedSize()
            .accessibilityLabel(glyph)
    }
}

/// Rasterizes Apple Color Emoji once per (glyph, size) so tint never reaches text layout.
enum EmojiImageCache {
    private static let cache = NSCache<NSString, UIImage>()
    /// Bitmap strikes actually present in Apple Color Emoji. Other sizes scale
    /// a nearby strike and look like grey/blurry squares (especially < 20pt).
    private static let strikeSizes: [CGFloat] = [20, 32, 40, 48, 64, 96, 160]

    static func image(for emoji: String, pointSize: CGFloat) -> UIImage {
        let key = "\(emoji)|\(Int(pointSize * 100))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let strike = nearestStrike(for: max(pointSize, 32))
        let font = colorEmojiFont(ofSize: strike)
        let attributed = NSAttributedString(string: emoji, attributes: [.font: font])
        let textSize = attributed.size()
        let canvas = CGSize(
            width: max(ceil(textSize.width), strike),
            height: max(ceil(textSize.height), strike)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = max(UITraitCollection.current.displayScale, 2)
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let image = renderer.image { _ in
            let origin = CGPoint(
                x: (canvas.width - textSize.width) / 2,
                y: (canvas.height - textSize.height) / 2
            )
            attributed.draw(at: origin)
        }

        cache.setObject(image, forKey: key)
        return image
    }

    static func colorEmojiFont(ofSize pointSize: CGFloat) -> UIFont {
        let strike = nearestStrike(for: pointSize)
        if let font = UIFont(name: "AppleColorEmoji", size: strike) {
            return font
        }
        return .systemFont(ofSize: strike)
    }

    private static func nearestStrike(for pointSize: CGFloat) -> CGFloat {
        strikeSizes.first { $0 >= pointSize } ?? strikeSizes.last ?? 64
    }
}

/// Button style that does not apply a foreground/tint to its label (keeps color emoji).
struct UntintedPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

/// Invisible text field that opens the system emoji keyboard when `isFocused` is true.
struct EmojiKeyboardField: UIViewRepresentable {
    @Binding var emoji: String
    @Binding var isFocused: Bool
    var onEmojiPicked: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> EmojiPreferringTextField {
        let field = EmojiPreferringTextField()
        field.delegate = context.coordinator
        field.textAlignment = .center
        field.font = EmojiImageCache.colorEmojiFont(ofSize: 28)
        field.backgroundColor = .clear
        field.tintColor = .clear
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .done
        // Keep hit-testable for first responder, but visually invisible in-layout.
        field.textColor = .clear
        return field
    }

    func updateUIView(_ field: EmojiPreferringTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != emoji {
            field.text = emoji
        }
        DispatchQueue.main.async {
            if isFocused, !field.isFirstResponder {
                field.becomeFirstResponder()
            } else if !isFocused, field.isFirstResponder {
                field.resignFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiKeyboardField

        init(_ parent: EmojiKeyboardField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard !string.isEmpty else { return true }
            // Prefer first grapheme cluster from the emoji keyboard (may include ZWJ sequences).
            if let picked = string.firstEmojiScalarCluster ?? string.first.map({ String($0) }) {
                parent.emoji = picked
                parent.onEmojiPicked?(picked)
                textField.text = picked
                textField.resignFirstResponder()
                return false
            }
            return false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

/// UITextField that reports the emoji input mode when available.
final class EmojiPreferringTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
            ?? super.textInputMode
    }

    override var textInputContextIdentifier: String? {
        // Helps iOS restore the emoji keyboard for this field.
        "com.workable.ios.emojiKeyboard"
    }
}

private extension String {
    /// First extended grapheme cluster that looks like an emoji.
    var firstEmojiScalarCluster: String? {
        for cluster in self {
            let value = String(cluster)
            if value.containsEmoji {
                return value
            }
        }
        return nil
    }

    var containsEmoji: Bool {
        unicodeScalars.contains { scalar in
            scalar.properties.isEmoji
                || scalar.properties.isEmojiPresentation
                || scalar.properties.isEmojiModifier
                || scalar.properties.isEmojiModifierBase
        }
    }
}
