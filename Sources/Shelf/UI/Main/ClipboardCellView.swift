import AppKit

// MARK: - CardView

final class CardView: NSView {
    var item: ClipboardItem? { didSet { configure() } }
    var onSelect:    (() -> Void)?
    var onDelete:    (() -> Void)?
    var onTogglePin: (() -> Void)?

    var isCardSelected: Bool = false { didSet { updateStyle() } }
    private var isHovering: Bool    = false { didSet { updateActionVisibility() } }

    // header
    private let appTile      = AppTileView()
    private let appNameLabel = NSTextField(labelWithString: "")
    private let actionsStack = NSStackView()
    private let pinButton    = NSButton()
    private let deleteButton = NSButton()

    // body placeholder
    private var bodyView: NSView?

    // footer
    private let metaLabel  = NSTextField(labelWithString: "")
    private let timeLabel  = NSTextField(labelWithString: "")

    private var trackingArea: NSTrackingArea?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = Theme.Radius.large
        layer?.borderWidth  = 0.5

        // app tile
        appTile.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appTile)

        // app name
        appNameLabel.font            = Theme.Font.captionBold
        appNameLabel.textColor       = Theme.Color.textDim
        appNameLabel.maximumNumberOfLines = 1
        appNameLabel.lineBreakMode   = .byTruncatingTail
        appNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appNameLabel)

        // action buttons
        configureActionButton(pinButton,    symbol: "star",  action: #selector(pinTapped))
        configureActionButton(deleteButton, symbol: "trash", action: #selector(deleteTapped))
        deleteButton.contentTintColor = NSColor(hex: "e5484d").withAlphaComponent(0.7)

        actionsStack.orientation = .horizontal
        actionsStack.spacing     = 2
        actionsStack.addArrangedSubview(pinButton)
        actionsStack.addArrangedSubview(deleteButton)
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.heightAnchor.constraint(equalToConstant: 28).isActive = true
        actionsStack.alphaValue = 0
        addSubview(actionsStack)

        // footer labels
        metaLabel.font      = Theme.Font.badgeBold
        metaLabel.textColor = Theme.Color.textFaint
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metaLabel)

        timeLabel.font      = Theme.Font.badge
        timeLabel.textColor = Theme.Color.textFaint
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        let p = Theme.Spacing.l  // 12pt padding

        NSLayoutConstraint.activate([
            // app tile — top-left
            appTile.leadingAnchor.constraint(equalTo: leadingAnchor,   constant: p),
            appTile.topAnchor.constraint(equalTo: topAnchor,           constant: p),
            appTile.widthAnchor.constraint(equalToConstant: 16),
            appTile.heightAnchor.constraint(equalToConstant: 16),

            // app name — beside tile
            appNameLabel.leadingAnchor.constraint(equalTo: appTile.trailingAnchor,  constant: 6),
            appNameLabel.centerYAnchor.constraint(equalTo: appTile.centerYAnchor),
            appNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -4),

            // actions — top-right
            actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            actionsStack.centerYAnchor.constraint(equalTo: appTile.centerYAnchor),

            // footer
            metaLabel.leadingAnchor.constraint(equalTo: leadingAnchor,   constant: p),
            metaLabel.bottomAnchor.constraint(equalTo: bottomAnchor,     constant: -p),

            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            timeLabel.centerYAnchor.constraint(equalTo: metaLabel.centerYAnchor),
        ])

        updateStyle()

    }

    private func configureActionButton(_ btn: NSButton, symbol: String, action: Selector) {
        btn.isBordered          = false
        btn.image               = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        btn.symbolConfiguration = .init(pointSize: 11, weight: .medium)
        btn.contentTintColor    = Theme.Color.textDim
        btn.target  = self
        btn.action  = action
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
    }

    private func configure() {
        guard let item = item else { return }

        appTile.configure(appName: item.sourceAppName, bundleId: item.sourceBundleId)
        appNameLabel.stringValue = item.sourceAppName ?? "Unknown"

        let pinSymbol = item.isPinned ? "star.fill" : "star"
        pinButton.image         = NSImage(systemSymbolName: pinSymbol, accessibilityDescription: nil)
        pinButton.contentTintColor = item.isPinned ? Theme.Color.accent : Theme.Color.textDim

        bodyView?.removeFromSuperview()
        let body = makeBody(for: item)
        body.translatesAutoresizingMaskIntoConstraints = false
        addSubview(body)

        let p = Theme.Spacing.l
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: appTile.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: leadingAnchor,    constant: p),
            body.trailingAnchor.constraint(equalTo: trailingAnchor,  constant: -p),
            body.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -8),
        ])
        bodyView = body

        metaLabel.stringValue = metaText(for: item)
        timeLabel.stringValue = relativeTime(item.createdAt)

        updateStyle()
        updateActionVisibility()
    }

    private func makeBody(for item: ClipboardItem) -> NSView {
        switch item.type {
        case .link:  let v = LinkCardBody();  v.configure(item: item); return v
        case .image: let v = ImageCardBody(); v.configure(item: item); return v
        case .color: let v = ColorCardBody(); v.configure(item: item); return v
        default:     let v = TextCardBody();  v.configure(item: item); return v
        }
    }

    private func updateStyle() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.backgroundColor = Theme.Color.card.cgColor
            self.layer?.borderColor = self.isCardSelected
                ? Theme.Color.accent.withAlphaComponent(0.5).cgColor
                : Theme.Color.cardBorder.cgColor
        }
        layer?.borderWidth = isCardSelected ? 2 : 0.5

        let s = NSShadow()
        s.shadowColor      = NSColor.black.withAlphaComponent(0.08)
        s.shadowBlurRadius = 6
        s.shadowOffset     = NSSize(width: 0, height: -2)
        shadow = s
    }

    private func updateActionVisibility() {
        let show = isHovering || isCardSelected
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            actionsStack.animator().alphaValue = show ? 1 : 0
        }
        if item?.isPinned == true {
            pinButton.alphaValue = 1
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(t)
        trackingArea = t
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseEntered(with event: NSEvent) { isHovering = true }
    override func mouseExited(with event: NSEvent)  { isHovering = false }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard !actionsStack.frame.contains(point) else { return }
        onSelect?()
    }

    @objc private func pinTapped()    { onTogglePin?() }
    @objc private func deleteTapped() { onDelete?() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateStyle()
    }

    private func metaText(for item: ClipboardItem) -> String {
        switch item.type {
        case .text:  return "TEXT"
        case .link:  return "LINK"
        case .image: return "IMAGE"
        case .color: return "COLOR"
        case .file:  return "FILE"
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AppTileView

final class AppTileView: NSView {
    private let label     = NSTextField(labelWithString: "")
    private let iconView  = NSImageView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.masksToBounds = true

        label.font      = NSFont.boldSystemFont(ofSize: 7)
        label.textColor = .white
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isHidden = true
        addSubview(iconView)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(appName: String?, bundleId: String?) {
        if let bundleId,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            iconView.image = icon
            iconView.isHidden = false
            label.isHidden = true
            layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            iconView.isHidden = true
            label.isHidden = false
            let name = appName ?? "?"
            label.stringValue = String(name.prefix(1)).uppercased()
            layer?.backgroundColor = tileColor(for: name).cgColor
        }
    }

    private func tileColor(for name: String) -> NSColor {
        let palette: [NSColor] = [
            NSColor(hex: "1f8bff"), NSColor(hex: "ff6a8b"), NSColor(hex: "b06bff"),
            NSColor(hex: "5b3a9e"), NSColor(hex: "ffc033"), NSColor(hex: "3a7bd5"),
            NSColor(hex: "5b6ad0"), NSColor(hex: "e5484d"), NSColor(hex: "28a745"),
        ]
        return palette[abs(name.hashValue) % palette.count]
    }
}
