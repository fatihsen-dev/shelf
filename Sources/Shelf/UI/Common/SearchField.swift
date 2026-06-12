import AppKit

private let filterTypes: [(String, ClipboardType?)] = [
    ("All", nil),
    ("Text", .text),
    ("Links", .link),
    ("Images", .image),
    ("Colors", .color),
]

final class SearchBarView: NSView, NSTextFieldDelegate {
    var onQueryChange: ((String) -> Void)?
    var onFilterChange: ((ClipboardType?) -> Void)?
    var onSettings: (() -> Void)?

    private let fieldWrapper = NSView()
    private let searchIcon   = NSImageView()
    private let textField    = NSTextField()
    private let clearButton  = NSButton()
    private let filterStack  = NSStackView()
    private let countLabel   = NSTextField(labelWithString: "")
    private let settingsBtn  = NSButton()

    private var chips: [ChipButton] = []
    private var activeFilter: ClipboardType? = nil

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // field wrapper
        fieldWrapper.wantsLayer = true
        fieldWrapper.layer?.cornerRadius = Theme.Radius.medium
        fieldWrapper.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldWrapper)
        applyLayerColor(Theme.Color.field, to: fieldWrapper.layer)

        // search icon
        searchIcon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        searchIcon.symbolConfiguration = .init(pointSize: 14, weight: .medium)
        searchIcon.contentTintColor = Theme.Color.textFaint
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        fieldWrapper.addSubview(searchIcon)

        // text field
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = Theme.Font.search
        textField.placeholderAttributedString = NSAttributedString(
            string: "Search clipboard…",
            attributes: [.font: Theme.Font.search, .foregroundColor: Theme.Color.textFaint]
        )
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        fieldWrapper.addSubview(textField)

        // clear button
        clearButton.isBordered = false
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        clearButton.symbolConfiguration = .init(pointSize: 13, weight: .regular)
        clearButton.contentTintColor = Theme.Color.textFaint
        clearButton.isHidden = true
        clearButton.target = self
        clearButton.action = #selector(clearQuery)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        fieldWrapper.addSubview(clearButton)

        // filter chips
        filterStack.orientation = .horizontal
        filterStack.spacing = 5
        filterStack.alignment = .centerY
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(filterStack)

        for (label, type) in filterTypes {
            let chip = ChipButton(label: label, filterType: type)
            chip.target = self
            chip.action = #selector(chipTapped(_:))
            filterStack.addArrangedSubview(chip)
            chips.append(chip)
        }
        chips.first?.isActive = true

        // count label
        countLabel.font = Theme.Font.caption
        countLabel.textColor = Theme.Color.textFaint
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // settings button
        settingsBtn.isBordered = false
        settingsBtn.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")
        settingsBtn.symbolConfiguration = .init(pointSize: 15, weight: .regular)
        settingsBtn.contentTintColor = Theme.Color.textDim
        settingsBtn.target = self
        settingsBtn.action = #selector(openSettings)
        settingsBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(settingsBtn)

        NSLayoutConstraint.activate([
            fieldWrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),
            fieldWrapper.widthAnchor.constraint(equalToConstant: 260),
            fieldWrapper.heightAnchor.constraint(equalToConstant: Theme.Sizes.searchH),

            searchIcon.leadingAnchor.constraint(equalTo: fieldWrapper.leadingAnchor, constant: 10),
            searchIcon.centerYAnchor.constraint(equalTo: fieldWrapper.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 16),
            searchIcon.heightAnchor.constraint(equalToConstant: 16),

            textField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 7),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: fieldWrapper.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: fieldWrapper.trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: fieldWrapper.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalToConstant: 16),

            filterStack.leadingAnchor.constraint(equalTo: fieldWrapper.trailingAnchor, constant: 12),
            filterStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            countLabel.trailingAnchor.constraint(equalTo: settingsBtn.leadingAnchor, constant: -10),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            settingsBtn.trailingAnchor.constraint(equalTo: trailingAnchor),
            settingsBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsBtn.widthAnchor.constraint(equalToConstant: 34),
            settingsBtn.heightAnchor.constraint(equalToConstant: 34),
        ])
    }

    func focus() { window?.makeFirstResponder(textField) }

    func reset() {
        textField.stringValue = ""
        clearButton.isHidden = true
        onQueryChange?("")
    }

    func updateCount(visible: Int, total: Int) {
        countLabel.stringValue = "\(visible) of \(total)"
    }

    @objc private func clearQuery() {
        textField.stringValue = ""
        clearButton.isHidden = true
        onQueryChange?("")
    }

    @objc private func chipTapped(_ sender: ChipButton) {
        chips.forEach { $0.isActive = false }
        sender.isActive = true
        activeFilter = sender.filterType
        onFilterChange?(sender.filterType)
    }

    @objc private func openSettings() { onSettings?() }

    func controlTextDidChange(_ obj: Notification) {
        let q = textField.stringValue
        clearButton.isHidden = q.isEmpty
        onQueryChange?(q)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        switch sel {
        case #selector(NSResponder.cancelOperation(_:)):
            clearQuery(); return true
        default:
            return false
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(settingsBtn.frame, cursor: .pointingHand)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyLayerColor(Theme.Color.field, to: fieldWrapper.layer)
    }
}

// MARK: - ChipButton

final class ChipButton: NSButton {
    let filterType: ClipboardType?

    var isActive: Bool = false {
        didSet { updateAppearance() }
    }

    init(label: String, filterType: ClipboardType?) {
        self.filterType = filterType
        super.init(frame: .zero)
        title = label
        font = Theme.Font.chip
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 8
        contentTintColor = Theme.Color.chipText
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 28).isActive = true
        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateAppearance() {
        if isActive {
            applyLayerColor(Theme.Color.accent, to: layer)
            contentTintColor = .white
        } else {
            applyLayerColor(Theme.Color.chip, to: layer)
            contentTintColor = Theme.Color.chipText
        }
    }

    override var intrinsicContentSize: NSSize {
        var s = super.intrinsicContentSize
        s.width += 24
        return s
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }
}
