import UIKit

/// A keyboard key that remembers its base character and any long-press
/// alternates, and swaps fill on press to mimic the iOS key highlight.
final class KeyButton: UIButton {
    let base: String
    let popups: [String]?

    var fill: UIColor = .white {
        didSet { if !isHighlighted { backgroundColor = fill } }
    }
    var pressedFill: UIColor = .white

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? pressedFill : fill }
    }

    init(base: String, popups: [String]?) {
        self.base = base
        self.popups = popups
        super.init(frame: .zero)
        layer.cornerRadius = KeyboardTheme.keyCornerRadius
        layer.cornerCurve = .continuous
        // Subtle 1pt bottom shadow, like the system keys.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: KeyboardTheme.keyCornerRadius
        ).cgPath
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
