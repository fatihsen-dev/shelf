import AppKit

final class SearchField: NSView, NSTextFieldDelegate {
    var onChange: ((String) -> Void)?
    var onSubmit: (() -> Void)?
    var onArrowDown: (() -> Void)?
    var onArrowUp: (() -> Void)?
    var onEscape: (() -> Void)?

    private let textField = NSTextField()
    private let iconView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        iconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        iconView.symbolConfiguration = .init(pointSize: 18, weight: .medium)
        iconView.contentTintColor = Theme.Color.secondaryText
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = Theme.Font.search
        textField.placeholderAttributedString = NSAttributedString(
            string: "Search clipboard…",
            attributes: [
                .font: Theme.Font.search,
                .foregroundColor: Theme.Color.tertiaryText
            ]
        )
        textField.textColor = Theme.Color.primaryText
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.l),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Theme.Spacing.m),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.l),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0.5))
        path.line(to: NSPoint(x: bounds.width, y: 0.5))
        Theme.Color.separator.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    func focus() {
        window?.makeFirstResponder(textField)
    }

    func reset() {
        textField.stringValue = ""
        onChange?("")
    }

    func controlTextDidChange(_ obj: Notification) {
        onChange?(textField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            onSubmit?(); return true
        case #selector(NSResponder.moveDown(_:)):
            onArrowDown?(); return true
        case #selector(NSResponder.moveUp(_:)):
            onArrowUp?(); return true
        case #selector(NSResponder.cancelOperation(_:)):
            onEscape?(); return true
        default:
            return false
        }
    }
}
