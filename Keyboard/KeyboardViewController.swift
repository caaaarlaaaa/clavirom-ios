import UIKit

final class KeyboardViewController: UIInputViewController {

    // MARK: - Layout data

    /// Long-press alternates, taken verbatim from ClaviRom's Vallader key texts
    /// (locale_key_texts/rm-VA.txt). First entry is the base character.
    private static let popups: [String: [String]] = [
        "a": ["a", "à", "ä", "â"],
        "e": ["e", "è", "ê", "é"],
        "i": ["i", "ì"],
        "o": ["o", "ô", "ò", "ö"],
        "u": ["u", "ü", "ù"],
        "'": ["'", "’", "‚", "‘", "›", "‹"],
    ]

    private let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l", "'"],
        ["y", "x", "c", "v", "b", "n", "m"],
    ]

    // MARK: - State

    private let engine = SuggestionEngine()
    private var currentWord = ""
    private var shifted = false
    private var letterButtons: [KeyButton] = []
    private var suggestionButtons: [UIButton] = []

    private var popupView: KeyPopup?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        engine.load()
        buildUI()
        updateSuggestions()
    }

    // MARK: - UI construction

    private func buildUI() {
        view.backgroundColor = UIColor(white: 0.82, alpha: 1)

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 6
        root.layoutMargins = UIEdgeInsets(top: 6, left: 3, bottom: 6, right: 3)
        root.isLayoutMarginsRelativeArrangement = true
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        root.addArrangedSubview(buildSuggestionBar())

        for (index, keys) in rows.enumerated() {
            let rowStack = makeRow()
            if index == 2 { rowStack.addArrangedSubview(makeShiftKey()) }
            for k in keys {
                let b = makeLetterKey(k)
                letterButtons.append(b)
                rowStack.addArrangedSubview(b)
            }
            if index == 2 { rowStack.addArrangedSubview(makeDeleteKey()) }
            root.addArrangedSubview(rowStack)
        }

        root.addArrangedSubview(buildBottomRow())

        let height = view.heightAnchor.constraint(equalToConstant: 264)
        height.priority = .init(999)
        height.isActive = true
    }

    private func makeRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 5
        s.distribution = .fillEqually
        return s
    }

    private func buildSuggestionBar() -> UIView {
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.spacing = 1
        bar.distribution = .fillEqually
        for i in 0..<3 {
            let b = UIButton(type: .system)
            b.titleLabel?.font = .systemFont(ofSize: 17)
            b.setTitleColor(.label, for: .normal)
            b.tag = i
            b.addTarget(self, action: #selector(pickSuggestion(_:)), for: .touchUpInside)
            suggestionButtons.append(b)
            bar.addArrangedSubview(b)
        }
        bar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return bar
    }

    private func buildBottomRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 5
        s.distribution = .fill

        let globe = makeSpecialKey("🌐")
        globe.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        globe.widthAnchor.constraint(equalToConstant: 46).isActive = true

        let space = makeSpecialKey("space")
        space.backgroundColor = .white
        space.addTarget(self, action: #selector(handleSpace), for: .touchUpInside)
        space.setContentHuggingPriority(.init(1), for: .horizontal)

        let ret = makeSpecialKey("return")
        ret.addTarget(self, action: #selector(handleReturn), for: .touchUpInside)
        ret.widthAnchor.constraint(equalToConstant: 92).isActive = true

        s.addArrangedSubview(globe)
        s.addArrangedSubview(space)
        s.addArrangedSubview(ret)
        return s
    }

    // MARK: - Key factories

    private func makeLetterKey(_ base: String) -> KeyButton {
        let b = KeyButton(base: base, popups: Self.popups[base])
        style(b, background: .white)
        b.setTitle(base, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 22)
        b.addTarget(self, action: #selector(tapLetter(_:)), for: .touchUpInside)
        if b.popups != nil {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.minimumPressDuration = 0.25
            b.addGestureRecognizer(lp)
        }
        return b
    }

    private func makeShiftKey() -> KeyButton {
        let b = KeyButton(base: "⇧", popups: nil)
        style(b, background: UIColor(white: 0.65, alpha: 1))
        b.setTitle("⇧", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 20)
        b.addTarget(self, action: #selector(toggleShift), for: .touchUpInside)
        return b
    }

    private func makeDeleteKey() -> KeyButton {
        let b = KeyButton(base: "⌫", popups: nil)
        style(b, background: UIColor(white: 0.65, alpha: 1))
        b.setTitle("⌫", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 20)
        b.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        return b
    }

    private func makeSpecialKey(_ title: String) -> KeyButton {
        let b = KeyButton(base: title, popups: nil)
        style(b, background: UIColor(white: 0.65, alpha: 1))
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17)
        return b
    }

    private func style(_ b: UIButton, background: UIColor) {
        b.backgroundColor = background
        b.setTitleColor(.label, for: .normal)
        b.layer.cornerRadius = 5
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    // MARK: - Actions

    @objc private func tapLetter(_ sender: KeyButton) {
        insert(shifted ? sender.base.uppercased() : sender.base)
        autoUnshift()
    }

    @objc private func handleSpace() { insertBreak(" ") }
    @objc private func handleReturn() { insertBreak("\n") }

    @objc private func handleDelete() {
        textDocumentProxy.deleteBackward()
        if !currentWord.isEmpty { currentWord.removeLast() }
        updateSuggestions()
    }

    @objc private func handleNextKeyboard() { advanceToNextInputMode() }

    @objc private func toggleShift() {
        shifted.toggle()
        applyShiftTitles()
    }

    @objc private func pickSuggestion(_ sender: UIButton) {
        guard let word = sender.title(for: .normal), !word.isEmpty else { return }
        for _ in 0..<currentWord.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(word + " ")
        currentWord = ""
        updateSuggestions()
    }

    // MARK: - Long-press accent popup

    @objc private func handleLongPress(_ g: UILongPressGestureRecognizer) {
        guard let key = g.view as? KeyButton, let options = key.popups else { return }
        let cased = shifted ? options.map { $0.uppercased() } : options
        switch g.state {
        case .began:
            let p = KeyPopup(options: cased)
            p.present(over: key, in: view)
            popupView = p
        case .changed:
            popupView?.updateSelection(at: g.location(in: view))
        case .ended:
            if let chosen = popupView?.selectedOption() {
                insert(chosen)
                autoUnshift()
            }
            popupView?.dismiss()
            popupView = nil
        default:
            popupView?.dismiss()
            popupView = nil
        }
    }

    // MARK: - Text helpers

    private func insert(_ s: String) {
        textDocumentProxy.insertText(s)
        currentWord += s
        updateSuggestions()
    }

    private func insertBreak(_ s: String) {
        textDocumentProxy.insertText(s)
        currentWord = ""
        updateSuggestions()
    }

    private func autoUnshift() {
        if shifted { shifted = false; applyShiftTitles() }
    }

    private func applyShiftTitles() {
        for b in letterButtons {
            b.setTitle(shifted ? b.base.uppercased() : b.base, for: .normal)
        }
    }

    private func updateSuggestions() {
        let results = engine.suggestions(for: currentWord)
        for (i, b) in suggestionButtons.enumerated() {
            let title = i < results.count ? results[i] : nil
            b.setTitle(title, for: .normal)
            b.isHidden = title == nil && currentWord.isEmpty
        }
    }
}
