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
    private var theme = KeyboardTheme.light

    private var letterButtons: [KeyButton] = []
    private var specialButtons: [KeyButton] = []
    private var shiftButton: KeyButton?
    private var returnButton: KeyButton?
    private var suggestionButtons: [UIButton] = []
    private var suggestionSeparators: [UIView] = []

    private var popupView: KeyPopup?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        engine.load()
        buildUI()
        applyTheme()
        updateSuggestions()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if traitCollection.userInterfaceStyle != previous?.userInterfaceStyle {
            applyTheme()
        }
    }

    // MARK: - UI construction

    private func buildUI() {
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = KeyboardTheme.rowSpacing
        root.layoutMargins = UIEdgeInsets(
            top: 6, left: KeyboardTheme.sideMargin,
            bottom: 4, right: KeyboardTheme.sideMargin
        )
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

        var referenceKey: KeyButton?
        var deleteKey: KeyButton?
        for (index, keys) in rows.enumerated() {
            // Row 3 hosts shift + a letter group + delete at their own widths,
            // so it fills rather than distributing equally.
            let rowStack = index == 2 ? makeFillRow() : makeRow()
            if index == 2 { rowStack.addArrangedSubview(makeShiftKey()) }

            let letterStack = index == 2 ? makeRow() : rowStack
            for k in keys {
                let b = makeLetterKey(k)
                letterButtons.append(b)
                letterStack.addArrangedSubview(b)
                if referenceKey == nil { referenceKey = b }
            }
            if index == 2 {
                letterStack.setContentHuggingPriority(.init(1), for: .horizontal)
                rowStack.addArrangedSubview(letterStack)
                deleteKey = makeDeleteKey()
                rowStack.addArrangedSubview(deleteKey!)
            }
            root.addArrangedSubview(rowStack)
        }

        root.addArrangedSubview(buildBottomRow())

        // Shift and delete take 1.5 letter-widths so the middle 7 keys line up
        // under the grid of the rows above. Activate only once the whole
        // hierarchy is assembled, so the keys share a common ancestor.
        if let ref = referenceKey, let shift = shiftButton, let del = deleteKey {
            NSLayoutConstraint.activate([
                shift.widthAnchor.constraint(equalTo: ref.widthAnchor, multiplier: 1.5),
                del.widthAnchor.constraint(equalTo: ref.widthAnchor, multiplier: 1.5),
            ])
        }

        let height = view.heightAnchor.constraint(equalToConstant: 258)
        height.priority = .init(999)
        height.isActive = true
    }

    private func makeRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = KeyboardTheme.keySpacing
        s.distribution = .fillEqually
        return s
    }

    /// A row whose children keep their own widths (used by row 3, where shift
    /// and delete are wider and the letter group fills the remaining space).
    private func makeFillRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = KeyboardTheme.keySpacing
        s.distribution = .fill
        return s
    }

    private func buildSuggestionBar() -> UIView {
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.spacing = 0
        bar.distribution = .fill
        for i in 0..<3 {
            if i > 0 {
                let sep = UIView()
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
                // Wrap the separator so it doesn't get equal-width treatment.
                let wrap = UIView()
                wrap.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
                    sep.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 10),
                    sep.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -10),
                    sep.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
                    sep.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
                    wrap.widthAnchor.constraint(equalToConstant: 1),
                ])
                suggestionSeparators.append(sep)
                bar.addArrangedSubview(wrap)
            }
            let b = UIButton(type: .system)
            b.titleLabel?.font = .systemFont(ofSize: 17)
            b.tag = i
            b.addTarget(self, action: #selector(pickSuggestion(_:)), for: .touchUpInside)
            suggestionButtons.append(b)
            bar.addArrangedSubview(b)
        }
        // Equal-width suggestion slots (separators stay 1pt via their wrappers).
        for b in suggestionButtons.dropFirst() {
            b.widthAnchor.constraint(equalTo: suggestionButtons[0].widthAnchor).isActive = true
        }
        bar.heightAnchor.constraint(equalToConstant: KeyboardTheme.suggestionHeight).isActive = true
        return bar
    }

    private func buildBottomRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = KeyboardTheme.keySpacing
        s.distribution = .fill

        let globe = makeSymbolKey("globe")
        globe.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        globe.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let space = makeSpecialKey("space")
        space.addTarget(self, action: #selector(handleSpace), for: .touchUpInside)
        space.setContentHuggingPriority(.init(1), for: .horizontal)

        let ret = makeSpecialKey(returnLabel())
        ret.addTarget(self, action: #selector(handleReturn), for: .touchUpInside)
        ret.widthAnchor.constraint(equalToConstant: 92).isActive = true
        returnButton = ret

        s.addArrangedSubview(globe)
        s.addArrangedSubview(space)
        s.addArrangedSubview(ret)
        // Space uses the letter fill, like the system keyboard.
        letterButtons.append(space)
        specialButtons.removeAll { $0 === space }
        return s
    }

    // MARK: - Key factories

    private func makeLetterKey(_ base: String) -> KeyButton {
        let b = KeyButton(base: base, popups: Self.popups[base])
        b.setTitle(base, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 22)
        b.addTarget(self, action: #selector(tapLetter(_:)), for: .touchUpInside)
        if b.popups != nil {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.minimumPressDuration = 0.3
            b.addGestureRecognizer(lp)
        }
        return b
    }

    private func makeShiftKey() -> KeyButton {
        let b = makeSymbolKey("shift")
        b.addTarget(self, action: #selector(toggleShift), for: .touchUpInside)
        shiftButton = b
        return b
    }

    private func makeDeleteKey() -> KeyButton {
        let b = makeSymbolKey("delete.left")
        b.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        return b
    }

    private func makeSpecialKey(_ title: String) -> KeyButton {
        let b = KeyButton(base: title, popups: nil)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        specialButtons.append(b)
        return b
    }

    private func makeSymbolKey(_ systemName: String) -> KeyButton {
        let b = KeyButton(base: systemName, popups: nil)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        b.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        specialButtons.append(b)
        return b
    }

    // MARK: - Theme

    private func applyTheme() {
        theme = KeyboardTheme.resolve(traitCollection.userInterfaceStyle)
        view.backgroundColor = theme.background
        for b in letterButtons {
            b.fill = theme.letterFill
            b.pressedFill = theme.letterPressed
            b.setTitleColor(theme.text, for: .normal)
            b.backgroundColor = theme.letterFill
        }
        for b in specialButtons {
            b.fill = theme.specialFill
            b.pressedFill = theme.specialPressed
            b.setTitleColor(theme.text, for: .normal)
            b.tintColor = theme.text
            b.backgroundColor = theme.specialFill
        }
        for b in suggestionButtons { b.setTitleColor(theme.text, for: .normal) }
        for s in suggestionSeparators { s.backgroundColor = theme.text.withAlphaComponent(0.2) }
        refreshShiftAppearance()
        styleReturnKey()
    }

    private func refreshShiftAppearance() {
        guard let shiftButton else { return }
        // Highlight the shift key and fill the arrow while it is armed.
        shiftButton.fill = shifted ? theme.specialPressed : theme.specialFill
        shiftButton.backgroundColor = shiftButton.fill
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        shiftButton.setImage(
            UIImage(systemName: shifted ? "shift.fill" : "shift", withConfiguration: config),
            for: .normal
        )
    }

    private func returnLabel() -> String {
        switch textDocumentProxy.returnKeyType ?? .default {
        case .go: return "go"
        case .google, .search, .yahoo: return "Search"
        case .send: return "Send"
        case .done: return "Done"
        case .next: return "next"
        default: return "return"
        }
    }

    private func styleReturnKey() {
        guard let returnButton else { return }
        let isAction: Bool
        switch textDocumentProxy.returnKeyType ?? .default {
        case .default, .next: isAction = false
        default: isAction = true
        }
        if isAction {
            returnButton.fill = .systemBlue
            returnButton.pressedFill = UIColor.systemBlue.withAlphaComponent(0.8)
            returnButton.setTitleColor(.white, for: .normal)
        } else {
            returnButton.fill = theme.specialFill
            returnButton.pressedFill = theme.specialPressed
            returnButton.setTitleColor(theme.text, for: .normal)
        }
        returnButton.setTitle(returnLabel(), for: .normal)
        returnButton.backgroundColor = returnButton.fill
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
        refreshShiftAppearance()
    }

    @objc private func pickSuggestion(_ sender: UIButton) {
        guard let word = sender.title(for: .normal), !word.isEmpty else { return }
        for _ in 0..<currentWord.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(word + " ")
        currentWord = ""
        updateSuggestions()
    }

    // MARK: - Long-press accent callout

    @objc private func handleLongPress(_ g: UILongPressGestureRecognizer) {
        guard let key = g.view as? KeyButton, let options = key.popups else { return }
        let cased = shifted ? options.map { $0.uppercased() } : options
        switch g.state {
        case .began:
            let p = KeyPopup(options: cased, theme: theme)
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
        if shifted { shifted = false; applyShiftTitles(); refreshShiftAppearance() }
    }

    private func applyShiftTitles() {
        for b in letterButtons where b.base.count == 1 && b.base != " " {
            b.setTitle(shifted ? b.base.uppercased() : b.base, for: .normal)
        }
    }

    private func updateSuggestions() {
        let results = engine.suggestions(for: currentWord)
        for (i, b) in suggestionButtons.enumerated() {
            b.setTitle(i < results.count ? results[i] : nil, for: .normal)
        }
    }
}
