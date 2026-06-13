import AppKit

final class FooterView: NSView {
    private let topBorder = NSView()
    private var kbdViews: [NSView] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        topBorder.wantsLayer = true
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBorder)

        let hints: [(keys: [String], label: String)] = [
            (["⇥", "/", "←", "→"], "Navigate"),
            (["↵"], "Copy & paste"),
            (["⌘", "⌫"], "Delete"),
        ]

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 16
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for hint in hints {
            stack.addArrangedSubview(hintView(keys: hint.keys, label: hint.label))
        }

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(spacer)

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 0.5),

            stack.topAnchor.constraint(equalTo: topBorder.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        updateColors()
    }

    private func hintView(keys: [String], label: String) -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.spacing = 5
        container.alignment = .centerY

        let keyStack = NSStackView()
        keyStack.orientation = .horizontal
        keyStack.spacing = 3

        for key in keys {
            if key == "/" {
                let sep = NSTextField(labelWithString: "/")
                sep.font = Theme.Font.hint
                sep.textColor = Theme.Color.textFaint
                keyStack.addArrangedSubview(sep)
            } else {
                let kbd = FooterKbd(key: key)
                keyStack.addArrangedSubview(kbd)
                kbdViews.append(kbd)
            }
        }

        let lbl = NSTextField(labelWithString: label)
        lbl.font = Theme.Font.hint
        lbl.textColor = Theme.Color.textFaint

        container.addArrangedSubview(keyStack)
        container.addArrangedSubview(lbl)
        return container
    }

    private func updateColors() {
        applyLayerColor(Theme.Color.divider, to: topBorder.layer)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
}

private final class FooterKbd: NSView {
    private let lbl: NSTextField

    init(key: String) {
        lbl = NSTextField(labelWithString: key)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth = 0.5
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 18).isActive = true

        lbl.font = Theme.Font.hint
        lbl.textColor = Theme.Color.textDim
        lbl.alignment = .center
        lbl.drawsBackground = false
        lbl.isBordered = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateColors()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(width: max(18, lbl.intrinsicContentSize.width + 8), height: 18)
    }

    private func updateColors() {
        applyLayerColor(Theme.Color.field, to: layer)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = Theme.Color.cardBorder.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
}
