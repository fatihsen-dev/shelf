import AppKit

// MARK: - TextBody

final class TextCardBody: NSView {
    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        label.font = Theme.Font.body
        label.textColor = Theme.Color.text
        label.maximumNumberOfLines = 5
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: ClipboardItem) {
        label.stringValue = item.textValue ?? ""
    }
}

// MARK: - LinkBody

final class LinkCardBody: NSView {
    private let linkIcon  = NSImageView()
    private let domainLbl = NSTextField(labelWithString: "")
    private let titleLbl  = NSTextField(labelWithString: "")
    private let urlLbl    = NSTextField(labelWithString: "")
    private let iconWrap  = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)

        iconWrap.wantsLayer = true
        iconWrap.layer?.cornerRadius = 5
        applyLayerColor(Theme.Color.field, to: iconWrap.layer)
        iconWrap.translatesAutoresizingMaskIntoConstraints = false

        linkIcon.image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
        linkIcon.symbolConfiguration = .init(pointSize: 9, weight: .medium)
        linkIcon.contentTintColor = Theme.Color.textDim
        linkIcon.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(linkIcon)

        domainLbl.font = Theme.Font.caption
        domainLbl.textColor = Theme.Color.textFaint
        domainLbl.maximumNumberOfLines = 1
        domainLbl.lineBreakMode = .byTruncatingTail
        domainLbl.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.font = Theme.Font.bodyBold
        titleLbl.textColor = Theme.Color.text
        titleLbl.maximumNumberOfLines = 3
        titleLbl.lineBreakMode = .byWordWrapping
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        urlLbl.font = Theme.Font.caption
        urlLbl.textColor = Theme.Color.accent
        urlLbl.maximumNumberOfLines = 1
        urlLbl.lineBreakMode = .byTruncatingTail
        urlLbl.translatesAutoresizingMaskIntoConstraints = false

        let domainRow = NSStackView(views: [iconWrap, domainLbl])
        domainRow.orientation = .horizontal
        domainRow.spacing = 6
        domainRow.alignment = .centerY
        domainRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [domainRow, titleLbl, urlLbl])
        stack.orientation = .vertical
        stack.spacing = 5
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconWrap.widthAnchor.constraint(equalToConstant: 18),
            iconWrap.heightAnchor.constraint(equalToConstant: 18),
            linkIcon.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            linkIcon.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: ClipboardItem) {
        guard let raw = item.textValue else { return }
        if let url = URL(string: raw) {
            domainLbl.stringValue = url.host ?? ""
            let clean = raw
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
            urlLbl.stringValue = clean
            // Show path as title if there's a meaningful path, otherwise hide
            let path = url.path
            if path.isEmpty || path == "/" {
                titleLbl.stringValue = ""
                titleLbl.isHidden = true
            } else {
                titleLbl.stringValue = clean
                titleLbl.isHidden = false
            }
        } else {
            domainLbl.stringValue = ""
            titleLbl.stringValue = raw
            titleLbl.isHidden = false
            urlLbl.stringValue = raw
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyLayerColor(Theme.Color.field, to: iconWrap.layer)
    }
}

// MARK: - ImageBody

final class ImageCardBody: NSView {
    private let imageView = NSImageView()
    private let imageStore = ImageStore()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = Theme.Radius.medium
        layer?.masksToBounds = true
        layer?.borderWidth = 0.5

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        updateBorderColor()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: ClipboardItem) {
        if let filename = item.imageFilename, let img = imageStore.loadImage(filename: filename) {
            imageView.image = img
        }
    }

    private func updateBorderColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = Theme.Color.cardBorder.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBorderColor()
    }
}

// MARK: - ColorBody

final class ColorCardBody: NSView {
    private let swatch = NSView()
    private let hexLbl  = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)

        swatch.wantsLayer = true
        swatch.layer?.cornerRadius = 9
        swatch.translatesAutoresizingMaskIntoConstraints = false

        hexLbl.font = Theme.Font.bodyBold
        hexLbl.textColor = Theme.Color.text
        hexLbl.translatesAutoresizingMaskIntoConstraints = false

        addSubview(swatch)
        addSubview(hexLbl)

        NSLayoutConstraint.activate([
            swatch.topAnchor.constraint(equalTo: topAnchor),
            swatch.leadingAnchor.constraint(equalTo: leadingAnchor),
            swatch.trailingAnchor.constraint(equalTo: trailingAnchor),
            swatch.bottomAnchor.constraint(equalTo: hexLbl.topAnchor, constant: -8),

            hexLbl.leadingAnchor.constraint(equalTo: leadingAnchor),
            hexLbl.trailingAnchor.constraint(equalTo: trailingAnchor),
            hexLbl.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: ClipboardItem) {
        guard let hex = item.textValue else { return }
        let color = NSColor(hex: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        swatch.layer?.backgroundColor = color.cgColor
        swatch.layer?.borderWidth = 1
        swatch.layer?.borderColor = NSColor.black.withAlphaComponent(0.12).cgColor
        hexLbl.stringValue = hex.uppercased()
    }
}
