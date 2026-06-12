import AppKit

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let preferences = PreferencesStore.shared

    func show() {
        if window == nil { buildWindow() }
        guard let window = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func buildWindow() {
        let size = NSSize(width: 520, height: 360)
        let win = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: [.titled, .closable, .fullSizeContentView],
                           backing: .buffered, defer: false)
        win.title = "Shelf Settings"
        win.titlebarAppearsTransparent = true
        win.isReleasedWhenClosed = false
        win.delegate = self

        let content = NSView(frame: .init(origin: .zero, size: size))

        let title = NSTextField(labelWithString: "General")
        title.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(title)

        let hotkeyLabel = NSTextField(labelWithString: "Open shortcut")
        hotkeyLabel.font = Theme.Font.body
        hotkeyLabel.textColor = Theme.Color.secondaryText
        hotkeyLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(hotkeyLabel)

        let hotkeyValue = NSTextField(labelWithString: "⌥V")
        hotkeyValue.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        hotkeyValue.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(hotkeyValue)

        let historyLabel = NSTextField(labelWithString: "History size")
        historyLabel.font = Theme.Font.body
        historyLabel.textColor = Theme.Color.secondaryText
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(historyLabel)

        let historyValue = NSTextField(labelWithString: "\(preferences.maxHistory) items")
        historyValue.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        historyValue.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(historyValue)

        let note = NSTextField(labelWithString: "Customizable shortcut recorder, theme picker and exclude-list are coming soon.")
        note.font = Theme.Font.caption
        note.textColor = Theme.Color.tertiaryText
        note.maximumNumberOfLines = 0
        note.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(note)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 56),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),

            hotkeyLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
            hotkeyLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            hotkeyValue.centerYAnchor.constraint(equalTo: hotkeyLabel.centerYAnchor),
            hotkeyValue.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            historyLabel.topAnchor.constraint(equalTo: hotkeyLabel.bottomAnchor, constant: 16),
            historyLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            historyValue.centerYAnchor.constraint(equalTo: historyLabel.centerYAnchor),
            historyValue.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            note.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            note.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            note.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24)
        ])

        win.contentView = content
        window = win
    }
}
