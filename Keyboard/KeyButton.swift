import UIKit

/// A keyboard key that remembers its base character and any long-press
/// alternates, so the controller can insert the right thing.
final class KeyButton: UIButton {
    let base: String
    let popups: [String]?

    init(base: String, popups: [String]?) {
        self.base = base
        self.popups = popups
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
