import SwiftUI

// Lune Typography
// Bundled fonts: CormorantGaramond-Light, CormorantGaramond-LightItalic, Geist-Regular, Geist-Medium,
//                GeistMono-Regular, GeistMono-Medium
// iOS fallbacks: New York (display) · SF Pro (body) · SF Mono (eyebrow)

struct LFont {
    // MARK: Display — Cormorant Garamond light, generous tracking
    static func display(_ size: CGFloat, italic: Bool = false) -> Font {
        let name = italic ? "CormorantGaramond-LightItalic" : "CormorantGaramond-Light"
        if let f = UIFont(name: name, size: size) {
            return Font(f)
        }
        return Font.custom("Georgia", size: size).weight(.light)
    }

    static func displayRegular(_ size: CGFloat) -> Font {
        let name = "CormorantGaramond-Regular"
        if let f = UIFont(name: name, size: size) { return Font(f) }
        return Font.custom("Georgia", size: size)
    }

    // MARK: Body — Geist
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "Geist-Medium"
        case .semibold, .bold, .heavy, .black: name = "Geist-SemiBold"
        default: name = "Geist-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        return Font.system(size: size, weight: weight, design: .default)
    }

    // MARK: Mono — Geist Mono
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = weight == .medium ? "GeistMono-Medium" : "GeistMono-Regular"
        if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
}
