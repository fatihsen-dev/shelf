import AppKit

final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let preferences = PreferencesStore.shared
    private let launchToggle = NSSwitch()
    private var onFinish: (() -> Void)?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        window.delegate = self
        buildContent()
    }

    func present(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        launchToggle.state = .on
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
    }

    private func buildContent() {
        guard let content = window?.contentView else { return }
        content.wantsLayer = true
        content.layer?.backgroundColor = Theme.Color.winBackground.cgColor

        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "Welcome to Shelf")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = NSTextField(wrappingLabelWithString: "A native clipboard manager for macOS. Search, pin, and paste everything you copy.")
        subtitle.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = Theme.Color.winCard.cgColor
        card.layer?.cornerRadius = Theme.Radius.large
        card.layer?.borderWidth = 1
        card.layer?.borderColor = Theme.Color.cardBorder.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let toggleLabel = NSTextField(labelWithString: "Launch at login")
        toggleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        toggleLabel.translatesAutoresizingMaskIntoConstraints = false

        let toggleHint = NSTextField(wrappingLabelWithString: "Shelf opens automatically when you log in to your Mac.")
        toggleHint.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        toggleHint.textColor = .secondaryLabelColor
        toggleHint.translatesAutoresizingMaskIntoConstraints = false

        launchToggle.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(toggleLabel)
        card.addSubview(toggleHint)
        card.addSubview(launchToggle)

        let permissionNote = NSTextField(wrappingLabelWithString: "Next, macOS will ask for Accessibility permission. Shelf needs it for the global hotkey and pasting into other apps.")
        permissionNote.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        permissionNote.textColor = .tertiaryLabelColor
        permissionNote.alignment = .center
        permissionNote.translatesAutoresizingMaskIntoConstraints = false

        let button = NSButton(title: "Get Started", target: self, action: #selector(finish))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(icon)
        content.addSubview(title)
        content.addSubview(subtitle)
        content.addSubview(card)
        content.addSubview(permissionNote)
        content.addSubview(button)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: content.topAnchor, constant: 36),
            icon.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 80),
            icon.heightAnchor.constraint(equalToConstant: 80),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            title.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            subtitle.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 40),
            subtitle.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40),

            card.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            card.heightAnchor.constraint(equalToConstant: 64),

            toggleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            toggleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),

            toggleHint.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            toggleHint.topAnchor.constraint(equalTo: toggleLabel.bottomAnchor, constant: 2),
            toggleHint.trailingAnchor.constraint(equalTo: launchToggle.leadingAnchor, constant: -12),

            launchToggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            launchToggle.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            permissionNote.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 20),
            permissionNote.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 40),
            permissionNote.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40),

            button.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -28),
            button.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 180),
        ])
    }

    @objc private func finish() {
        preferences.launchAtLogin = (launchToggle.state == .on)
        preferences.hasSeenOnboarding = true
        NotificationCenter.default.post(name: .shelfLaunchAtLogin, object: nil)
        window?.close()
        onFinish?()
    }

    func windowWillClose(_ notification: Notification) {
        if !preferences.hasSeenOnboarding {
            preferences.hasSeenOnboarding = true
            onFinish?()
        }
    }
}
