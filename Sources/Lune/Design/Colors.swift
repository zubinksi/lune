import SwiftUI

extension Color {
    // Design token palette
    static let lCream        = Color(hex: "f4ede4")   // primary background
    static let lCream2       = Color(hex: "ece3d6")   // deeper cream, card tiles
    static let lPaper        = Color(hex: "faf5ec")   // lightest surface, cards
    static let lInk          = Color(hex: "2a2520")   // primary text
    static let lInk2         = Color(hex: "5a4f44")   // secondary text
    static let lInk3         = Color(hex: "8a7f72")   // tertiary / placeholder
    static let lRule         = Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.10)
    static let lTerracotta   = Color(hex: "c9856b")   // warm accent
    static let lTerracottaDeep = Color(hex: "a86a52")
    static let lSage         = Color(hex: "8a9a7a")   // cool accent
    static let lSageDeep     = Color(hex: "6e8262")
    static let lRed          = Color(hex: "9a4a3e")   // menstrual / error

    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: Double
        switch h.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }

    static func phase(named name: String) -> Color {
        switch name {
        case "Menstrual":  return Color(hex: "9a4a3e")
        case "Follicular": return Color(hex: "8a9a7a")
        case "Ovulatory":  return Color(hex: "c9856b")
        default:           return Color(hex: "b67a5e")   // Luteal
        }
    }
}
