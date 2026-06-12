import AppKit
import Carbon.HIToolbox

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var dragOffset: CGPoint = .zero

    func show() {
        if window == nil { buildWindow() }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildWindow() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 478),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Settings"
        win.isReleasedWhenClosed = false
        win.delegate = self

        let root = SettingsRootView()
        root.translatesAutoresizingMaskIntoConstraints = false
        win.contentView = root

        if let cv = win.contentView {
            NSLayoutConstraint.activate([
                root.topAnchor.constraint(equalTo: cv.topAnchor),
                root.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                root.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
                root.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            ])
        }

        window = win
    }
}

// MARK: - SettingsRootView

private final class SettingsRootView: NSView {
    private let sidebar  = SettingsSidebar()
    private let divider  = NSView()
    private var paneView: NSView?
    private var section: String = "general"

    private let panes: [String: () -> NSView] = [:]

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        sidebar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sidebar)

        divider.wantsLayer = true
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)

        NSLayoutConstraint.activate([
            sidebar.topAnchor.constraint(equalTo: topAnchor),
            sidebar.leadingAnchor.constraint(equalTo: leadingAnchor),
            sidebar.bottomAnchor.constraint(equalTo: bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 192),

            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 0.5),
        ])

        sidebar.onSelect = { [weak self] section in self?.showSection(section) }
        showSection("general")
        updateColors()
    }

    private func updateColors() {
        applyLayerColor(Theme.Color.winBackground, to: layer)
        applyLayerColor(Theme.Color.divider, to: divider.layer)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func showSection(_ key: String) {
        section = key
        sidebar.activeSection = key
        paneView?.removeFromSuperview()

        let pane: NSView
        switch key {
        case "general":   pane = GeneralPane()
        case "shortcuts": pane = ShortcutsPane()
        case "history":   pane = HistoryPane()
        case "privacy":   pane = PrivacyPane()
        default:          pane = GeneralPane()
        }

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers  = true
        scroll.translatesAutoresizingMaskIntoConstraints = false

        pane.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = pane

        let cv = scroll.contentView
        NSLayoutConstraint.activate([
            pane.topAnchor.constraint(equalTo: cv.topAnchor),
            pane.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            pane.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            pane.bottomAnchor.constraint(greaterThanOrEqualTo: cv.bottomAnchor),
        ])

        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            scroll.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        paneView = scroll

        // title bar area
        subviews.filter { $0 is SectionTitleBar }.forEach { $0.removeFromSuperview() }
        let titleBar = SectionTitleBar(title: sectionTitle(key))
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleBar)
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func sectionTitle(_ key: String) -> String {
        switch key {
        case "general":   return "General"
        case "shortcuts": return "Shortcuts"
        case "history":   return "History"
        case "privacy":   return "Privacy"
        default:          return key.capitalized
        }
    }
}

// MARK: - SectionTitleBar

private final class SectionTitleBar: NSView {
    init(title: String) {
        super.init(frame: .zero)
        wantsLayer = true

        let border = NSView()
        border.wantsLayer = true
        border.layer?.backgroundColor = Theme.Color.divider.cgColor
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)

        let lbl = NSTextField(labelWithString: title)
        lbl.font      = NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        lbl.textColor = Theme.Color.text
        lbl.alignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lbl)

        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: centerYAnchor),
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - SettingsSidebar

private final class SettingsSidebar: NSView {
    var onSelect: ((String) -> Void)?
    var activeSection: String = "general" { didSet { updateButtons() } }

    private var navButtons: [(String, NSButton)] = []

    private let sections: [(key: String, label: String, symbol: String, color: String)] = [
        ("general",   "General",   "gearshape.fill",      "8e8e93"),
        ("shortcuts", "Shortcuts", "command",              "e5484d"),
        ("history",   "History",   "clock.arrow.circlepath", "1f8bff"),
        ("privacy",   "Privacy",   "lock.fill",            "28a745"),
    ]

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        let navStack = NSStackView()
        navStack.orientation = .vertical
        navStack.spacing     = 2
        navStack.alignment   = .leading
        navStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(navStack)

        for s in sections {
            let btn = makeNavButton(label: s.label, symbol: s.symbol, color: s.color, key: s.key)
            navStack.addArrangedSubview(btn.1)
            btn.1.widthAnchor.constraint(equalTo: navStack.widthAnchor).isActive = true
            navButtons.append(btn)
        }

        let versionLbl = NSTextField(labelWithString: "Shelf 1.0 · build 2026.6")
        versionLbl.font      = NSFont.systemFont(ofSize: 10.5, weight: .regular)
        versionLbl.textColor = Theme.Color.textFaint
        versionLbl.isEditable   = false
        versionLbl.isBordered   = false
        versionLbl.drawsBackground = false
        versionLbl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(versionLbl)

        NSLayoutConstraint.activate([
            navStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            navStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            navStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            versionLbl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            versionLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
        ])

        updateButtons()
        applyLayerColor(Theme.Color.winSidebar, to: layer)
    }

    private func makeNavButton(label: String, symbol: String, color: String, key: String) -> (String, NSButton) {
        let btn = NavButton(key: key, label: label, symbol: symbol, glyphColor: NSColor(hex: color))
        btn.target = self
        btn.action = #selector(navTapped(_:))
        return (key, btn)
    }

    @objc private func navTapped(_ sender: NavButton) {
        onSelect?(sender.sectionKey)
    }

    private func updateButtons() {
        for (key, btn) in navButtons {
            (btn as? NavButton)?.isActiveSection = (key == activeSection)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyLayerColor(Theme.Color.winSidebar, to: layer)
    }
}

// MARK: - NavButton

private final class NavButton: NSButton {
    let sectionKey: String
    var isActiveSection: Bool = false { didSet { updateAppearance() } }

    private let iconView   = NSImageView()
    private let labelView  = NSTextField(labelWithString: "")
    private let glyphBg    = NSView()
    private let glyphColor: NSColor
    private let symbolName: String

    init(key: String, label: String, symbol: String, glyphColor: NSColor) {
        self.sectionKey = key
        self.glyphColor = glyphColor
        self.symbolName = symbol
        super.init(frame: .zero)
        title      = ""
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 8

        glyphBg.wantsLayer = true
        glyphBg.layer?.cornerRadius = 6
        glyphBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glyphBg)

        let cfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        iconView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        iconView.contentTintColor = .white
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        labelView.stringValue = label
        labelView.font        = NSFont.systemFont(ofSize: 13, weight: .medium)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 34),

            glyphBg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            glyphBg.centerYAnchor.constraint(equalTo: centerYAnchor),
            glyphBg.widthAnchor.constraint(equalToConstant: 22),
            glyphBg.heightAnchor.constraint(equalToConstant: 22),

            iconView.centerXAnchor.constraint(equalTo: glyphBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: glyphBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            labelView.leadingAnchor.constraint(equalTo: glyphBg.trailingAnchor, constant: 10),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateAppearance() {
        if isActiveSection {
            applyLayerColor(Theme.Color.accent, to: layer)
            applyLayerColor(.white.withAlphaComponent(0.22), to: glyphBg.layer)
            labelView.textColor = .white
        } else {
            applyLayerColor(.clear, to: layer)
            applyLayerColor(glyphColor, to: glyphBg.layer)
            labelView.textColor = Theme.Color.text
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }
}

// MARK: - Shared Controls

final class SettingsGroup: NSView {
    private var rows: [SettingsRow] = []
    private var lastBottomConstraint: NSLayoutConstraint?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.borderWidth  = 0.5
        updateColors()
    }
    required init?(coder: NSCoder) { fatalError() }

    func addRow(_ row: SettingsRow) {
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        lastBottomConstraint?.isActive = false

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: rows.last?.bottomAnchor ?? topAnchor),
        ])

        lastBottomConstraint = row.bottomAnchor.constraint(equalTo: bottomAnchor)
        lastBottomConstraint?.isActive = true
        rows.append(row)
    }

    func addPlainRow(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        lastBottomConstraint?.isActive = false

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: rows.last?.bottomAnchor ?? topAnchor),
        ])

        lastBottomConstraint = view.bottomAnchor.constraint(equalTo: bottomAnchor)
        lastBottomConstraint?.isActive = true
    }

    private func updateColors() {
        applyLayerColor(Theme.Color.winCard, to: layer)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = Theme.Color.cardBorder.cgColor
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        updateColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
}

final class SettingsRow: NSView {
    init(label: String, sub: String? = nil, control: NSView, isLast: Bool = false) {
        super.init(frame: .zero)

        let labelStack = NSStackView()
        labelStack.orientation = .vertical
        labelStack.spacing     = 2
        labelStack.alignment   = .leading

        let lbl = NSTextField(labelWithString: label)
        lbl.font      = NSFont.systemFont(ofSize: 13.5, weight: .medium)
        lbl.textColor = Theme.Color.text
        labelStack.addArrangedSubview(lbl)

        if let sub = sub {
            let subLbl = NSTextField(labelWithString: sub)
            subLbl.font           = NSFont.systemFont(ofSize: 11.5, weight: .regular)
            subLbl.textColor      = Theme.Color.textFaint
            subLbl.maximumNumberOfLines = 2
            subLbl.lineBreakMode  = .byWordWrapping
            labelStack.addArrangedSubview(subLbl)
        }

        labelStack.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints    = false
        addSubview(labelStack)
        addSubview(control)

        if !isLast {
            let sep = NSView()
            sep.wantsLayer = true
            sep.layer?.backgroundColor = Theme.Color.divider.cgColor
            sep.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sep)
            NSLayoutConstraint.activate([
                sep.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                sep.trailingAnchor.constraint(equalTo: trailingAnchor),
                sep.bottomAnchor.constraint(equalTo: bottomAnchor),
                sep.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }

        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            labelStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            labelStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -16),
            control.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            control.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    // NSView label variant
    init(labelView: NSView, control: NSView, isLast: Bool = false) {
        super.init(frame: .zero)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints  = false
        addSubview(labelView)
        addSubview(control)

        if !isLast {
            let sep = NSView()
            sep.wantsLayer = true
            sep.layer?.backgroundColor = Theme.Color.divider.cgColor
            sep.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sep)
            NSLayoutConstraint.activate([
                sep.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                sep.trailingAnchor.constraint(equalTo: trailingAnchor),
                sep.bottomAnchor.constraint(equalTo: bottomAnchor),
                sep.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            labelView.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -16),
            control.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            control.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError() }
}

// Toggle switch
final class ToggleSwitch: NSButton {
    var onToggle: ((Bool) -> Void)?
    var isOn: Bool = false { didSet { updateKnob(animated: animateNextUpdate) } }

    private var animateNextUpdate = false
    private let knob = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        isBordered = false
        title = ""
        layer?.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 40).isActive = true
        heightAnchor.constraint(equalToConstant: 24).isActive = true

        knob.wantsLayer = true
        knob.layer?.cornerRadius = 10
        knob.layer?.backgroundColor = NSColor.white.cgColor
        knob.layer?.shadowOpacity = 0.3
        knob.layer?.shadowRadius  = 2
        knob.layer?.shadowOffset  = CGSize(width: 0, height: -1)
        knob.translatesAutoresizingMaskIntoConstraints = false
        addSubview(knob)
        NSLayoutConstraint.activate([
            knob.widthAnchor.constraint(equalToConstant: 20),
            knob.heightAnchor.constraint(equalToConstant: 20),
            knob.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateKnob(animated: false)
        target = self
        action = #selector(tapped)
    }
    required init?(coder: NSCoder) { fatalError() }

    private var knobLeading: NSLayoutConstraint?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        knobLeading?.isActive = false
        knobLeading = knob.leadingAnchor.constraint(equalTo: leadingAnchor, constant: isOn ? 18 : 2)
        knobLeading?.isActive = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        updateKnob(animated: false)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateKnob(animated: false)
    }

    private func updateKnob(animated: Bool) {
        let x: CGFloat = isOn ? 18 : 2
        applyLayerColor(isOn ? Theme.Color.accent : Theme.Color.field, to: layer)
        knobLeading?.constant = x
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.22
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                knob.animator().frame = CGRect(x: x, y: 2, width: 20, height: 20)
            }
        } else {
            knob.frame = CGRect(x: x, y: 2, width: 20, height: 20)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    @objc private func tapped() {
        animateNextUpdate = true
        isOn.toggle()
        animateNextUpdate = false
        onToggle?(isOn)
    }
}

// Segmented control
private final class ActionButton: NSButton {
    var onTap: (() -> Void)?

    init(title: String) {
        super.init(frame: .zero)
        self.title = title
        target = self
        action = #selector(tapped)
    }

    init(systemSymbol: String) {
        super.init(frame: .zero)
        image = NSImage(systemSymbolName: systemSymbol, accessibilityDescription: nil)
        target = self
        action = #selector(tapped)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        var s = super.intrinsicContentSize
        s.width += 40
        return s
    }
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
    @objc private func tapped() { onTap?() }
}

private final class SegPill: NSView {
    var onTap: ((String) -> Void)?
    private let value: String
    private let tf: NSTextField

    init(label: String, value: String) {
        self.value = value
        self.tf = NSTextField(labelWithString: label)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 7
        layer?.shadowColor  = NSColor.black.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: -1)
        layer?.shadowRadius = 1.5
        translatesAutoresizingMaskIntoConstraints = false

        tf.font        = NSFont.systemFont(ofSize: 12.5, weight: .medium)
        tf.alignment   = .center
        tf.drawsBackground = false
        tf.isBordered  = false
        tf.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tf)
        NSLayoutConstraint.activate([
            tf.centerXAnchor.constraint(equalTo: centerXAnchor),
            tf.centerYAnchor.constraint(equalTo: centerYAnchor),
            tf.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            tf.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
        ])

        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(width: tf.intrinsicContentSize.width + 28, height: 26)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    private var _isSelected = false

    func setSelected(_ isSelected: Bool) {
        _isSelected = isSelected
        applyLayerColor(isSelected ? Theme.Color.accent : .clear, to: layer)
        layer?.shadowOpacity = isSelected ? 0.2 : 0
        tf.textColor = isSelected ? .white : Theme.Color.textDim
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        setSelected(_isSelected)
    }

    @objc private func tapped() { onTap?(value) }
}

final class SegmentedRow: NSView {
    var onChange: ((String) -> Void)?
    private var pills: [(String, SegPill)] = []
    private var selected: String = ""

    init(options: [(label: String, value: String)], selected: String) {
        self.selected = selected
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.backgroundColor = Theme.Color.field.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 32).isActive = true

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing     = 2
        stack.edgeInsets  = NSEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for opt in options {
            let pill = SegPill(label: opt.label, value: opt.value)
            pill.onTap = { [weak self] value in
                self?.selected = value
                self?.updateSelection()
                self?.onChange?(value)
            }
            stack.addArrangedSubview(pill)
            pills.append((opt.value, pill))
        }
        updateSelection()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let total = pills.reduce(0) { $0 + $1.1.intrinsicContentSize.width }
        let spacing = 2 * CGFloat(max(0, pills.count - 1))
        return NSSize(width: total + spacing + 6, height: 32)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        applyLayerColor(Theme.Color.field, to: layer)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyLayerColor(Theme.Color.field, to: layer)
    }

    private func updateSelection() {
        for (value, pill) in pills { pill.setSelected(value == selected) }
    }
}

// Section title
final class SectionHeader: NSTextField {
    init(_ text: String) {
        super.init(frame: .zero)
        stringValue = text.uppercased()
        font        = NSFont.systemFont(ofSize: 12, weight: .bold)
        textColor   = Theme.Color.textFaint
        isBezeled   = false
        isBordered  = false
        isEditable  = false
        drawsBackground = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }
}

// Hotkey display
final class HotkeyBadge: NSStackView {
    init(keys: [String]) {
        super.init(frame: .zero)
        orientation = .horizontal
        spacing     = 6
        translatesAutoresizingMaskIntoConstraints = false
        for k in keys {
            let container = KeyBadge(key: k)
            addArrangedSubview(container)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Shortcut helpers

private extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var f: UInt32 = 0
        if contains(.command) { f |= UInt32(cmdKey) }
        if contains(.option)  { f |= UInt32(optionKey) }
        if contains(.control) { f |= UInt32(controlKey) }
        if contains(.shift)   { f |= UInt32(shiftKey) }
        return f
    }
}

private func modifierSymbols(_ mods: UInt32) -> [String] {
    var s: [String] = []
    if mods & UInt32(controlKey) != 0 { s.append("⌃") }
    if mods & UInt32(optionKey)  != 0 { s.append("⌥") }
    if mods & UInt32(shiftKey)   != 0 { s.append("⇧") }
    if mods & UInt32(cmdKey)     != 0 { s.append("⌘") }
    return s
}

private func keyCodeString(_ code: UInt32) -> String {
    let map: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_Return: "↵", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋", kVK_Space: "Space", kVK_Tab: "⇥",
        kVK_UpArrow: "↑", kVK_DownArrow: "↓", kVK_LeftArrow: "←", kVK_RightArrow: "→",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
        kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
        kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
        kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".", kVK_ANSI_Slash: "/",
    ]
    return map[Int(code)] ?? "?"
}

// MARK: - ShortcutField

final class ShortcutField: NSView {
    var onSave: ((UInt32, UInt32) -> Void)?
    var onRecordingChanged: ((Bool) -> Void)?
    private(set) var keyCode: UInt32
    private(set) var modifiers: UInt32

    private let recordingBorder = NSView()
    private let box             = NSView()
    private let pillStack       = NSStackView()
    private let recordingLbl    = NSTextField(labelWithString: "Recording")
    private var isRecording     = false

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode   = keyCode
        self.modifiers = modifiers
        super.init(frame: .zero)
        setup()
        refreshPills()
    }
    required init?(coder: NSCoder) { fatalError() }

    private static let borderThickness: CGFloat = 1.5

    private func setup() {
        wantsLayer = true

        recordingBorder.wantsLayer = true
        recordingBorder.layer?.cornerRadius = 7
        recordingBorder.isHidden = true
        addSubview(recordingBorder)

        box.wantsLayer = true
        box.layer?.cornerRadius = 7 - Self.borderThickness
        addSubview(box)

        pillStack.orientation = .horizontal
        pillStack.spacing     = 4
        box.addSubview(pillStack)

        recordingLbl.font      = Theme.Font.hint
        recordingLbl.textColor = Theme.Color.textFaint
        recordingLbl.isHidden  = true
        recordingLbl.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(recordingLbl)
        NSLayoutConstraint.activate([
            recordingLbl.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            recordingLbl.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])
    }

    private static let pad: CGFloat = 7

    override func layout() {
        super.layout()
        let pad = Self.pad
        let h = bounds.height

        let t = Self.borderThickness
        if isRecording {
            recordingBorder.frame = NSRect(x: 0, y: 0, width: bounds.width, height: h)
            box.frame = NSRect(x: t, y: t, width: bounds.width - t * 2, height: h - t * 2)
        } else {
            recordingBorder.frame = .zero
            var pillsW: CGFloat = 0
            for (i, v) in pillStack.arrangedSubviews.enumerated() {
                if i > 0 { pillsW += pillStack.spacing }
                pillsW += v.intrinsicContentSize.width
            }
            pillsW = ceil(pillsW)
            let pillsH = pillStack.arrangedSubviews.map { $0.intrinsicContentSize.height }.max().map { ceil($0) } ?? 0
            let boxH = pillsH + pad * 2
            box.frame = NSRect(x: 0, y: (h - boxH) / 2, width: bounds.width, height: boxH)
            pillStack.frame = NSRect(x: pad, y: pad, width: pillsW, height: pillsH)
        }
    }

    private func refreshPills() {
        pillStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        (modifierSymbols(modifiers) + [keyCodeString(keyCode)]).forEach {
            pillStack.addArrangedSubview(KeyBadge(key: $0))
        }
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        var pillsW: CGFloat = 0
        for (i, v) in pillStack.arrangedSubviews.enumerated() {
            if i > 0 { pillsW += pillStack.spacing }
            pillsW += v.intrinsicContentSize.width
        }
        return NSSize(width: ceil(pillsW) + Self.pad * 2, height: 32)
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        startRecording()
    }

    @objc private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        pillStack.isHidden    = true
        recordingLbl.isHidden = false
        updateColors()
        onRecordingChanged?(true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }
        if event.keyCode == UInt16(kVK_Escape) { stopRecording(); return }
        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !mods.isEmpty else { return }
        keyCode   = UInt32(event.keyCode)
        modifiers = mods.carbonFlags
        onSave?(keyCode, modifiers)
        stopRecording()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return super.performKeyEquivalent(with: event) }
        keyDown(with: event)
        return true
    }

    private func stopRecording() {
        isRecording = false
        pillStack.isHidden    = false
        recordingLbl.isHidden = true
        refreshPills()
        updateColors()
        onRecordingChanged?(false)
        window?.makeFirstResponder(nil)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        updateColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateColors() {
        if isRecording {
            applyLayerColor(Theme.Color.accent, to: recordingBorder.layer)
            applyLayerColor(Theme.Color.accent, to: box.layer)
            recordingBorder.isHidden = false
            recordingLbl.textColor = .white
        } else {
            recordingBorder.isHidden = true
            applyLayerColor(Theme.Color.field, to: box.layer)
            recordingLbl.textColor = Theme.Color.textFaint
        }
    }
}

private final class KeyBadge: NSView {
    private let tf: NSTextField

    init(key: String) {
        tf = NSTextField(labelWithString: key)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth  = 0.5
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 18).isActive = true
        updateColors()

        tf.font        = Theme.Font.hint
        tf.textColor   = Theme.Color.textDim
        tf.alignment   = .center
        tf.drawsBackground = false
        tf.isBordered  = false
        tf.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tf)
        NSLayoutConstraint.activate([
            tf.centerXAnchor.constraint(equalTo: centerXAnchor),
            tf.centerYAnchor.constraint(equalTo: centerYAnchor),
            tf.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            tf.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let textW = tf.intrinsicContentSize.width
        return NSSize(width: max(18, textW + 8), height: 18)
    }

    private func updateColors() {
        applyLayerColor(Theme.Color.field, to: layer)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = Theme.Color.cardBorder.cgColor
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        updateColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
}

// MARK: - Panes

private func paneContainer() -> NSView {
    let v = NSView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
}

private final class GeneralPane: NSView {
    private let prefs = PreferencesStore.shared

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let startupHeader = SectionHeader("Startup")

        let launchToggle = ToggleSwitch()
        launchToggle.isOn = prefs.launchAtLogin
        launchToggle.onToggle = { [weak self] v in
            self?.prefs.launchAtLogin = v
            NotificationCenter.default.post(name: .shelfLaunchAtLogin, object: nil)
        }
        let launchRow = SettingsRow(label: "Launch Shelf at login",
                                   sub: "Shelf opens automatically and lives in the menu bar.",
                                   control: launchToggle)

        let menuBarToggle = ToggleSwitch()
        menuBarToggle.isOn = prefs.menuBarIcon
        menuBarToggle.onToggle = { [weak self] v in
            self?.prefs.menuBarIcon = v
            NotificationCenter.default.post(name: .shelfMenuBarIconChanged, object: nil)
        }
        let menuBarRow = SettingsRow(label: "Show icon in menu bar",
                                    control: menuBarToggle, isLast: true)

        let startupGroup = SettingsGroup()
        startupGroup.addRow(launchRow)
        startupGroup.addRow(menuBarRow)

        let appearanceHeader = SectionHeader("Appearance")

        let themeSeg = SegmentedRow(
            options: [("Light","light"),("Dark","dark"),("Auto","auto")],
            selected: prefs.theme
        )
        themeSeg.onChange = { [weak self] v in
            self?.prefs.theme = v
            NotificationCenter.default.post(name: .shelfThemeChanged, object: nil)
        }
        let themeRow = SettingsRow(label: "Theme",
                                   sub: "Match the system or pick a fixed appearance.",
                                   control: themeSeg)

        let soundToggle = ToggleSwitch()
        soundToggle.isOn = prefs.playSoundOnCopy
        soundToggle.onToggle = { [weak self] v in self?.prefs.playSoundOnCopy = v }
        let soundRow = SettingsRow(label: "Play sound on copy",
                                  control: soundToggle, isLast: true)

        let appearanceGroup = SettingsGroup()
        appearanceGroup.addRow(themeRow)
        appearanceGroup.addRow(soundRow)

        let stack = NSStackView()
        for v in [startupHeader, startupGroup, appearanceHeader, appearanceGroup] as [NSView] {
            stack.addView(v, in: .top)
        }
        stack.orientation = .vertical
        stack.spacing     = 6
        stack.alignment   = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(20, after: startupGroup)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18),
            startupGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            appearanceGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }
}

private final class ShortcutsPane: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let prefs = PreferencesStore.shared

        typealias Entry = (label: String, sub: String, keyCode: UInt32, modifiers: UInt32, onSave: (UInt32, UInt32) -> Void)
        let entries: [Entry] = [
            ("Open the Shelf",  "Bring up clipboard history anywhere.",
             prefs.hotkeyKeyCode, prefs.hotkeyModifiers,
             { code, mods in
                 prefs.hotkeyKeyCode = code; prefs.hotkeyModifiers = mods
                 NotificationCenter.default.post(name: .shelfHotkeyChanged, object: nil)
             }),
            ("Paste latest",    "Paste the most recent clip directly.",
             prefs.pasteLatestKeyCode, prefs.pasteLatestModifiers,
             { code, mods in prefs.pasteLatestKeyCode = code; prefs.pasteLatestModifiers = mods }),
            ("Pin selected",    "Star the highlighted card.",
             prefs.pinSelectedKeyCode, prefs.pinSelectedModifiers,
             { code, mods in prefs.pinSelectedKeyCode = code; prefs.pinSelectedModifiers = mods }),
            ("Clear the Shelf", "Wipe unpinned history.",
             prefs.clearShelfKeyCode, prefs.clearShelfModifiers,
             { code, mods in prefs.clearShelfKeyCode = code; prefs.clearShelfModifiers = mods }),
        ]

        let header = SectionHeader("Keyboard Shortcuts")
        let group  = SettingsGroup()

        for (i, entry) in entries.enumerated() {
            let field = ShortcutField(keyCode: entry.keyCode, modifiers: entry.modifiers)
            field.onSave = entry.onSave
            group.addRow(SettingsRow(
                label: entry.label, sub: entry.sub,
                control: field,
                isLast: i == entries.count - 1
            ))
        }

        let note = NSTextField(labelWithString: "Click a shortcut to record a new combination. Global shortcuts work even when Shelf is hidden.")
        note.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        note.textColor = Theme.Color.textFaint
        note.maximumNumberOfLines = 3
        note.lineBreakMode = .byWordWrapping
        note.isEditable   = false
        note.isBordered   = false
        note.drawsBackground = false
        note.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        for v in [header, group, note] as [NSView] {
            stack.addView(v, in: .top)
        }
        stack.orientation = .vertical
        stack.spacing     = 9
        stack.alignment   = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18),
            group.widthAnchor.constraint(equalTo: stack.widthAnchor),
            note.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }
}

private final class HistoryPane: NSView {
    private let prefs = PreferencesStore.shared

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let retentionHeader = SectionHeader("Retention")

        let limitSeg = SegmentedRow(
            options: [("100","100"),("500","500"),("1,000","1000")],
            selected: String(prefs.maxHistory)
        )
        limitSeg.onChange = { [weak self] v in self?.prefs.maxHistory = Int(v) ?? 500 }
        let limitRow = SettingsRow(label: "Keep history",
                                  sub: "Older clips are dropped once the limit is reached.",
                                  control: limitSeg)

        let imagesToggle = ToggleSwitch()
        imagesToggle.isOn = prefs.storeImages
        imagesToggle.onToggle = { [weak self] v in self?.prefs.storeImages = v }
        let imagesRow = SettingsRow(label: "Store copied images",
                                   sub: "Image clips can use significant disk space.",
                                   control: imagesToggle)

        let pinnedToggle = ToggleSwitch()
        pinnedToggle.isOn = prefs.keepPinned
        pinnedToggle.onToggle = { [weak self] v in self?.prefs.keepPinned = v }
        let pinnedRow = SettingsRow(label: "Keep pinned items forever",
                                   control: pinnedToggle, isLast: true)

        let retentionGroup = SettingsGroup()
        retentionGroup.addRow(limitRow)
        retentionGroup.addRow(imagesRow)
        retentionGroup.addRow(pinnedRow)

        let maintenanceHeader = SectionHeader("Maintenance")

        let clearBtn = ActionButton(title: "Clear")
        clearBtn.onTap = { NotificationCenter.default.post(name: .shelfClearHistory, object: nil) }
        clearBtn.isBordered = false
        clearBtn.wantsLayer = true
        clearBtn.layer?.cornerRadius = 9
        clearBtn.layer?.backgroundColor = Theme.Color.accentSoft.cgColor
        clearBtn.contentTintColor = Theme.Color.accent
        clearBtn.font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        clearBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let clearRow = SettingsRow(label: "Clear history now",
                                  sub: "Removes all unpinned clips immediately.",
                                  control: clearBtn, isLast: true)
        let maintenanceGroup = SettingsGroup()
        maintenanceGroup.addRow(clearRow)

        let stack = NSStackView()
        for v in [retentionHeader, retentionGroup, maintenanceHeader, maintenanceGroup] as [NSView] {
            stack.addView(v, in: .top)
        }
        stack.orientation = .vertical
        stack.spacing     = 6
        stack.alignment   = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(20, after: retentionGroup)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18),
            retentionGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            maintenanceGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

}

private final class PrivacyPane: NSView {
    private let prefs = PreferencesStore.shared
    private let appsContainer = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let privacyHeader = SectionHeader("Privacy")

        let passwordToggle = ToggleSwitch()
        passwordToggle.isOn = prefs.ignorePasswords
        passwordToggle.onToggle = { [weak self] v in self?.prefs.ignorePasswords = v }
        let passwordRow = SettingsRow(label: "Ignore password fields",
                                     sub: "Never capture content marked as a secure entry.",
                                     control: passwordToggle)

        let pauseToggle = ToggleSwitch()
        pauseToggle.isOn = prefs.isMonitoringPaused
        pauseToggle.onToggle = { [weak self] v in
            self?.prefs.isMonitoringPaused = v
            NotificationCenter.default.post(name: .shelfSetPaused, object: nil)
        }
        let pauseRow = SettingsRow(label: "Pause Shelf",
                                  sub: "Temporarily stop recording new clips.",
                                  control: pauseToggle, isLast: true)

        let privacyGroup = SettingsGroup()
        privacyGroup.addRow(passwordRow)
        privacyGroup.addRow(pauseRow)

        let ignoredHeader = SectionHeader("Ignored Apps")

        let addAppBtn = ActionButton(title: "+ Add Application")
        addAppBtn.isBordered = false
        addAppBtn.contentTintColor = Theme.Color.accent
        addAppBtn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        addAppBtn.translatesAutoresizingMaskIntoConstraints = false
        addAppBtn.onTap = { [weak self] in self?.pickApp() }

        let ignoredHeaderRow = NSStackView(views: [ignoredHeader, addAppBtn])
        ignoredHeaderRow.orientation = .horizontal
        ignoredHeaderRow.alignment = .centerY
        ignoredHeaderRow.distribution = .fill
        ignoredHeaderRow.translatesAutoresizingMaskIntoConstraints = false

        let note = NSTextField(labelWithString: "Shelf will not capture anything copied from these apps.")
        note.font = NSFont.systemFont(ofSize: 11.5)
        note.textColor = Theme.Color.textFaint
        note.maximumNumberOfLines = 2
        note.lineBreakMode = .byWordWrapping
        note.isEditable = false; note.isBordered = false; note.drawsBackground = false
        note.translatesAutoresizingMaskIntoConstraints = false

        appsContainer.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for v in [privacyHeader, privacyGroup, ignoredHeaderRow, appsContainer, note] as [NSView] {
            stack.addView(v, in: .top)
        }
        stack.setCustomSpacing(20, after: privacyGroup)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18),
            privacyGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            ignoredHeaderRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            appsContainer.widthAnchor.constraint(equalTo: stack.widthAnchor),
            note.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        rebuildApps()
    }

    private func rebuildApps() {
        appsContainer.subviews.forEach { $0.removeFromSuperview() }

        if prefs.ignoredBundleIds.isEmpty {
            let icon = NSImageView(image: NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)!)
            icon.contentTintColor = Theme.Color.textFaint
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

            let label = NSTextField(labelWithString: "No ignored apps")
            label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = Theme.Color.textFaint

            let emptyStack = NSStackView(views: [icon, label])
            emptyStack.orientation = .horizontal
            emptyStack.spacing = 7
            emptyStack.alignment = .centerY
            emptyStack.translatesAutoresizingMaskIntoConstraints = false

            let emptyRow = NSView()
            emptyRow.translatesAutoresizingMaskIntoConstraints = false
            emptyRow.addSubview(emptyStack)
            NSLayoutConstraint.activate([
                emptyStack.centerXAnchor.constraint(equalTo: emptyRow.centerXAnchor),
                emptyStack.centerYAnchor.constraint(equalTo: emptyRow.centerYAnchor),
                emptyRow.heightAnchor.constraint(equalToConstant: 52),
            ])

            let group = SettingsGroup()
            group.translatesAutoresizingMaskIntoConstraints = false
            group.addPlainRow(emptyRow)
            appsContainer.addSubview(group)
            NSLayoutConstraint.activate([
                group.topAnchor.constraint(equalTo: appsContainer.topAnchor),
                group.leadingAnchor.constraint(equalTo: appsContainer.leadingAnchor),
                group.trailingAnchor.constraint(equalTo: appsContainer.trailingAnchor),
                group.bottomAnchor.constraint(equalTo: appsContainer.bottomAnchor),
            ])
        } else {
            let group = SettingsGroup()
            group.translatesAutoresizingMaskIntoConstraints = false

            for (i, bundleId) in prefs.ignoredBundleIds.enumerated() {
                group.addRow(makeAppRow(bundleId: bundleId, isLast: i == prefs.ignoredBundleIds.count - 1))
            }

            appsContainer.addSubview(group)
            NSLayoutConstraint.activate([
                group.topAnchor.constraint(equalTo: appsContainer.topAnchor),
                group.leadingAnchor.constraint(equalTo: appsContainer.leadingAnchor),
                group.trailingAnchor.constraint(equalTo: appsContainer.trailingAnchor),
                group.bottomAnchor.constraint(equalTo: appsContainer.bottomAnchor),
            ])
        }
    }

    private func makeAppRow(bundleId: String, isLast: Bool) -> SettingsRow {
        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        let name = appURL.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String }
            ?? appURL.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleName") as? String }
            ?? bundleId

        let lv = NSStackView()
        lv.orientation = .horizontal
        lv.spacing = 9
        lv.alignment = .centerY
        if let url = appURL {
            let icon = NSImageView()
            icon.image = NSWorkspace.shared.icon(forFile: url.path)
            icon.imageScaling = .scaleProportionallyUpOrDown
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
            lv.addArrangedSubview(icon)
        }
        let lbl = NSTextField(labelWithString: name)
        lbl.font = NSFont.systemFont(ofSize: 13.5, weight: .medium)
        lbl.textColor = Theme.Color.text
        lv.addArrangedSubview(lbl)

        let removeBtn = ActionButton(systemSymbol: "trash")
        removeBtn.onTap = { [weak self] in
            PreferencesStore.shared.removeIgnoredApp(bundleId)
            self?.rebuildApps()
        }
        removeBtn.isBordered = false
        removeBtn.contentTintColor = Theme.Color.accent
        removeBtn.translatesAutoresizingMaskIntoConstraints = false
        removeBtn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        removeBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return SettingsRow(labelView: lv, control: removeBtn, isLast: isLast)
    }

    @objc private func pickApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Ignore"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundleId = Bundle(url: url)?.bundleIdentifier else { return }
        prefs.addIgnoredApp(bundleId)
        rebuildApps()
    }
}
