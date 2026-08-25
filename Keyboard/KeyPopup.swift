import UIKit

/// A floating row of accent alternates shown above a key during a long press,
/// styled like the iOS character callout. The finger position selects which
/// option commits on release.
final class KeyPopup: UIView {
    private let options: [String]
    private let theme: KeyboardTheme
    private var optionLabels: [UILabel] = []
    private var selectedIndex = 0

    init(options: [String], theme: KeyboardTheme) {
        self.options = options
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor = theme.calloutFill
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(over key: UIView, in container: UIView) {
        let itemW: CGFloat = 40
        let itemH: CGFloat = 48
        let inset: CGFloat = 5
        let width = itemW * CGFloat(options.count) + inset * 2
        let keyFrame = key.convert(key.bounds, to: container)

        var x = keyFrame.midX - width / 2
        x = max(4, min(x, container.bounds.width - width - 4))
        let y = keyFrame.minY - itemH - 8
        frame = CGRect(x: x, y: y, width: width, height: itemH)
        container.addSubview(self)

        for (i, opt) in options.enumerated() {
            let label = UILabel(frame: CGRect(x: inset + itemW * CGFloat(i), y: 0, width: itemW, height: itemH))
            label.text = opt
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 24)
            label.textColor = theme.text
            label.layer.cornerRadius = 7
            label.layer.cornerCurve = .continuous
            label.layer.masksToBounds = true
            addSubview(label)
            optionLabels.append(label)
        }
        highlight(0)
    }

    func updateSelection(at point: CGPoint) {
        let local = convert(point, from: superview)
        let usable = bounds.width - 10
        let idx = Int((local.x - 5) / (usable / CGFloat(max(options.count, 1))))
        highlight(min(max(idx, 0), options.count - 1))
    }

    func selectedOption() -> String? {
        options.indices.contains(selectedIndex) ? options[selectedIndex] : nil
    }

    func dismiss() { removeFromSuperview() }

    private func highlight(_ index: Int) {
        selectedIndex = index
        for (i, label) in optionLabels.enumerated() {
            let on = i == index
            label.backgroundColor = on ? .systemBlue : .clear
            label.textColor = on ? .white : theme.text
        }
    }
}
