import UIKit

/// A floating row of accent alternates shown above a key during a long press.
/// The finger position selects which option commits on release.
final class KeyPopup: UIView {
    private let options: [String]
    private var optionLabels: [UILabel] = []
    private var selectedIndex = 0

    init(options: [String]) {
        self.options = options
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.98, alpha: 1)
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(over key: UIView, in container: UIView) {
        let itemW: CGFloat = 42
        let itemH: CGFloat = 46
        let width = itemW * CGFloat(options.count)
        let keyFrame = key.convert(key.bounds, to: container)

        var x = keyFrame.midX - width / 2
        x = max(4, min(x, container.bounds.width - width - 4))
        let y = keyFrame.minY - itemH - 6
        frame = CGRect(x: x, y: y, width: width, height: itemH)
        container.addSubview(self)

        for (i, opt) in options.enumerated() {
            let label = UILabel(frame: CGRect(x: itemW * CGFloat(i), y: 0, width: itemW, height: itemH))
            label.text = opt
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22)
            label.textColor = .label
            addSubview(label)
            optionLabels.append(label)
        }
        highlight(0)
    }

    func updateSelection(at point: CGPoint) {
        let local = convert(point, from: superview)
        let idx = Int(local.x / (bounds.width / CGFloat(max(options.count, 1))))
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
            label.backgroundColor = on ? .tintColor : .clear
            label.textColor = on ? .white : .label
            label.layer.cornerRadius = 6
            label.layer.masksToBounds = true
        }
    }
}
