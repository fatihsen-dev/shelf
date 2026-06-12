import AppKit

final class ClipboardCellView: NSTableRowView {
    var item: ClipboardItem? { didSet { configure() } }
    var isHovering = false { didSet { needsDisplay = true } }

    private let iconContainer = NSView()
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let badgeLabel = NSTextField(labelWithString: "")
    private let pinIcon = NSImageView()
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = Theme.Radius.small
        iconContainer.layer?.backgroundColor = Theme.Color.iconBackground.cgColor
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconContainer)

        iconView.symbolConfiguration = .init(pointSize: 14, weight: .medium)
        iconView.contentTintColor = Theme.Color.secondaryText
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        titleLabel.font = Theme.Font.body
        titleLabel.textColor = Theme.Color.primaryText
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.font = Theme.Font.caption
        subtitleLabel.textColor = Theme.Color.tertiaryText
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        badgeLabel.font = Theme.Font.caption
        badgeLabel.textColor = Theme.Color.tertiaryText
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeLabel)

        pinIcon.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
        pinIcon.symbolConfiguration = .init(pointSize: 10, weight: .semibold)
        pinIcon.contentTintColor = Theme.Color.accent
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pinIcon)

        let iconSize: CGFloat = 36
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.m),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: iconSize),
            iconContainer.heightAnchor.constraint(equalToConstant: iconSize),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: Theme.Spacing.m),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeLabel.leadingAnchor, constant: -Theme.Spacing.s),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Theme.Spacing.m),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.m),
            badgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            pinIcon.trailingAnchor.constraint(equalTo: badgeLabel.leadingAnchor, constant: -Theme.Spacing.s),
            pinIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 10),
            pinIcon.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { isHovering = true }
    override func mouseExited(with event: NSEvent) { isHovering = false }

    override func drawBackground(in dirtyRect: NSRect) {
        let inset = bounds.insetBy(dx: 6, dy: 2)
        let path = NSBezierPath(roundedRect: inset, xRadius: Theme.Radius.medium, yRadius: Theme.Radius.medium)
        if isSelected {
            Theme.Color.selection.setFill()
            path.fill()
        } else if isHovering {
            Theme.Color.hover.setFill()
            path.fill()
        }
    }

    private func configure() {
        guard let item = item else { return }
        iconView.image = NSImage(systemSymbolName: item.type.iconName, accessibilityDescription: nil)
        titleLabel.stringValue = previewTitle(for: item)
        subtitleLabel.stringValue = subtitle(for: item)
        badgeLabel.stringValue = relativeTime(item.createdAt)
        pinIcon.isHidden = !item.isPinned
    }

    private func previewTitle(for item: ClipboardItem) -> String {
        let raw = item.previewText.replacingOccurrences(of: "\n", with: " ")
        return raw.trimmingCharacters(in: .whitespaces)
    }

    private func subtitle(for item: ClipboardItem) -> String {
        let app = item.sourceAppName ?? "Unknown"
        return "\(item.type.displayName) · \(app)"
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
