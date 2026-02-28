import SwiftUI

struct DawnColor {
    static let gold50 = Color(hex: "#fffbe5")
    static let gold100 = Color(hex: "#fff7cc")
    static let gold200 = Color(hex: "#fff099")
    static let gold300 = Color(hex: "#ffe866")
    static let gold400 = Color(hex: "#ffe033")
    static let gold500 = Color(hex: "#ffd900")
    static let gold600 = Color(hex: "#ccad00")
    static let gold700 = Color(hex: "#998200")
    static let gold800 = Color(hex: "#665700")
    static let gold900 = Color(hex: "#332b00")
    static let gold950 = Color(hex: "#241e00")

    static let lightApricot50 = Color(hex: "#fff6e5")
    static let lightApricot100 = Color(hex: "#ffeccc")
    static let lightApricot200 = Color(hex: "#ffda99")
    static let lightApricot300 = Color(hex: "#ffc766")
    static let lightApricot400 = Color(hex: "#ffb433")
    static let lightApricot500 = Color(hex: "#ffa200")
    static let lightApricot600 = Color(hex: "#cc8100")
    static let lightApricot700 = Color(hex: "#996100")
    static let lightApricot800 = Color(hex: "#664100")
    static let lightApricot900 = Color(hex: "#332000")
    static let lightApricot950 = Color(hex: "#241700")

    static let lightGold50 = Color(hex: "#fcfae8")
    static let lightGold100 = Color(hex: "#f9f5d2")
    static let lightGold200 = Color(hex: "#f3eba5")
    static let lightGold300 = Color(hex: "#ede278")
    static let lightGold400 = Color(hex: "#e8d84a")
    static let lightGold500 = Color(hex: "#e2ce1d")
    static let lightGold600 = Color(hex: "#b5a517")
    static let lightGold700 = Color(hex: "#877c12")
    static let lightGold800 = Color(hex: "#5a520c")
    static let lightGold900 = Color(hex: "#2d2906")
    static let lightGold950 = Color(hex: "#201d04")

    static let salmon500 = Color(hex: "#f62109")
    static let softBlush200 = Color(hex: "#ffa399")

    static let accent = lightApricot500
    static let accentPressed = lightApricot600
    static let highlight = gold500
    static let highlightSoft = gold400
    static let bgWarmTop = lightApricot50
    static let bgWarmBottom = gold50
    static let danger = salmon500

    static let glassWarmOverlay = bgWarmTop
}

enum DesignTokens {
    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 14
    static let spacingL: CGFloat = 18
    static let spacingXL: CGFloat = 24

    static let glassCardRadius: CGFloat = 28
    static let innerCardRadius: CGFloat = 22
    static let pillRadius: CGFloat = 999

    static let cardCornerRadius: CGFloat = glassCardRadius
    static let cardPadding: CGFloat = spacingL

    static let chipCornerRadius: CGFloat = 18
    static let chipHorizontalPadding: CGFloat = 16
    static let chipVerticalPadding: CGFloat = 10

    static let timeFontSize: CGFloat = 38
    static let tabBarHeight: CGFloat = 72
    static let headerMaxHeight: CGFloat = 96
    static let headerMinHeight: CGFloat = 52

    static let shadowAmbient = ShadowStyle(y: 8, blur: 24, opacity: 0.10)
    static let shadowContact = ShadowStyle(y: 2, blur: 8, opacity: 0.08)

    static let screenTitleFont: Font = .title2.weight(.semibold)
    static let sectionHeaderFont: Font = .headline.weight(.semibold)
    static let rowTitleFont: Font = .headline.weight(.semibold)
    static let primaryTimeFont: Font = .title3.weight(.semibold)
    static let rowSubtitleFont: Font = .subheadline
    static let badgeFont: Font = .caption.weight(.semibold)
}

struct ShadowStyle {
    let y: CGFloat
    let blur: CGFloat
    let opacity: Double
}

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexString.count == 6 { hexString.append("FF") }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r = Double((int >> 24) & 0xFF) / 255.0
        let g = Double((int >> 16) & 0xFF) / 255.0
        let b = Double((int >> 8) & 0xFF) / 255.0
        let a = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
