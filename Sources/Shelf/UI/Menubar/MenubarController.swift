import AppKit

final class MenubarController {
    private let repository: ClipboardRepository
    private let preferences = PreferencesStore.shared
    private let pasteService = PasteService()
    private var statusItem: NSStatusItem?

    private let onOpenMain: () -> Void
    private let onOpenSettings: () -> Void

    init(repository: ClipboardRepository,
         onOpenMain: @escaping () -> Void,
         onOpenSettings: @escaping () -> Void) {
        self.repository = repository
        self.onOpenMain = onOpenMain
        self.onOpenSettings = onOpenSettings
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu),
                                               name: ClipboardRepository.didChangeNotification, object: nil)
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Shelf")
            image?.isTemplate = true
            button.image = image
        }
        statusItem = item
        rebuildMenu()
    }

    @objc private func rebuildMenu() {
        guard let statusItem = statusItem else { return }
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Shelf", action: #selector(openMain), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let recents = Array(repository.items.prefix(5))
        if recents.isEmpty {
            let empty = NSMenuItem(title: "No items yet", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let header = NSMenuItem(title: "Recent", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for (idx, item) in recents.enumerated() {
                let title = recentTitle(for: item)
                let menuItem = NSMenuItem(title: title, action: #selector(pasteRecent(_:)), keyEquivalent: "\(idx + 1)")
                menuItem.target = self
                menuItem.representedObject = item.id
                menu.addItem(menuItem)
            }
        }

        menu.addItem(.separator())

        let pauseTitle = preferences.isMonitoringPaused ? "Resume Monitoring" : "Pause Monitoring"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let clearItem = NSMenuItem(title: "Clear History…", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Shelf", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func recentTitle(for item: ClipboardItem) -> String {
        let raw = item.previewText.replacingOccurrences(of: "\n", with: " ")
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 48 ? String(trimmed.prefix(48)) + "…" : trimmed
    }

    @objc private func openMain() { onOpenMain() }
    @objc private func openSettings() { onOpenSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func togglePause() {
        preferences.isMonitoringPaused.toggle()
        rebuildMenu()
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear clipboard history?"
        alert.informativeText = "Pinned items will be kept."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            repository.clearAll(keepPinned: true)
        }
    }

    @objc private func pasteRecent(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let item = repository.items.first(where: { $0.id == id }) else { return }
        pasteService.paste(item)
    }
}
