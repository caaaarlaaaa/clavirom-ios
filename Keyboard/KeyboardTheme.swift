import UIKit

/// Colors and metrics tuned to match the iOS system keyboard, in light and dark.
struct KeyboardTheme {
    let background: UIColor
    let letterFill: UIColor
    let specialFill: UIColor
    let letterPressed: UIColor
    let specialPressed: UIColor
    let text: UIColor
    let calloutFill: UIColor

    static let light = KeyboardTheme(
        background: UIColor(red: 209/255, green: 211/255, blue: 217/255, alpha: 1),
        letterFill: .white,
        specialFill: UIColor(red: 172/255, green: 178/255, blue: 189/255, alpha: 1),
        letterPressed: UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1),
        specialPressed: .white,
        text: .black,
        calloutFill: .white
    )

    static let dark = KeyboardTheme(
        background: UIColor(red: 34/255, green: 34/255, blue: 36/255, alpha: 1),
        // iOS uses translucent light keys over the blurred host in dark mode.
        letterFill: UIColor(white: 1, alpha: 0.30),
        specialFill: UIColor(white: 1, alpha: 0.14),
        letterPressed: UIColor(white: 1, alpha: 0.45),
        specialPressed: UIColor(white: 1, alpha: 0.30),
        text: .white,
        calloutFill: UIColor(white: 0.36, alpha: 1)
    )

    static func resolve(_ style: UIUserInterfaceStyle) -> KeyboardTheme {
        style == .dark ? .dark : .light
    }

    // Shared metrics (portrait iPhone).
    static let keyCornerRadius: CGFloat = 5
    static let keyHeight: CGFloat = 42
    static let rowSpacing: CGFloat = 11
    static let keySpacing: CGFloat = 6
    static let sideMargin: CGFloat = 3
    static let suggestionHeight: CGFloat = 44
}
