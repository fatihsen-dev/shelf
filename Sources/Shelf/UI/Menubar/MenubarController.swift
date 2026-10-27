import AppKit

final class MenubarController {
    private let repository: ClipboardRepository
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
            button.image = menubarImage()
        }
        statusItem = item
        rebuildMenu()
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil { install() }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    @objc private func rebuildMenu() {
        guard let statusItem = statusItem else { return }
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Shelf", action: #selector(openMain), keyEquivalent: "")
        openItem.target = self
        openItem.image = menuItemIcon("tray.fill")
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
                menuItem.image = menuItemIcon(recentIcon(for: item))
                menu.addItem(menuItem)
            }
        }

        menu.addItem(.separator())

        let clearItem = NSMenuItem(title: "Clear History…", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        clearItem.image = menuItemIcon("trash")
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = menuItemIcon("gear")
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Shelf", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = menuItemIcon("power")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// Monochrome template glyph of the app logo (three cards in a drawer), so the
    /// system tints it like every other menu bar icon (light/dark, highlighted).
    private func menubarImage() -> NSImage? {
        let img = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()
            // Cards peeking out of the drawer (middle one taller)
            let cards: [(x: CGFloat, top: CGFloat)] = [(4.0, 3.9), (7.7, 2.2), (11.4, 3.9)]
            for card in cards {
                NSBezierPath(roundedRect: NSRect(x: card.x, y: card.top, width: 2.6, height: 7.6 - card.top),
                             xRadius: 0.8, yRadius: 0.8).fill()
            }
            // Drawer outline
            let drawer = NSBezierPath(roundedRect: NSRect(x: 1.75, y: 8.85, width: 14.5, height: 6.4),
                                      xRadius: 2.5, yRadius: 2.5)
            drawer.lineWidth = 1.5
            drawer.stroke()
            // Handle
            NSBezierPath(roundedRect: NSRect(x: 6.5, y: 11.3, width: 5.0, height: 1.5),
                         xRadius: 0.75, yRadius: 0.75).fill()
            return true
        }
        img.isTemplate = true
        img.accessibilityDescription = "Shelf"
        return img
    }

    private func menuItemIcon(_ symbolName: String) -> NSImage? {
        let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }

    private func recentIcon(for item: ClipboardItem) -> String {
        switch item.type {
        case .text:  return "doc.text"
        case .link:  return "link"
        case .image: return "photo"
        case .color: return "paintpalette"
        case .file:  return "doc"
        }
    }

    private func recentTitle(for item: ClipboardItem) -> String {
        let raw = item.previewText.prefix(200).replacingOccurrences(of: "\n", with: " ")
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 32 ? String(trimmed.prefix(32)) + "…" : trimmed
    }

    @objc private func openMain() { onOpenMain() }
    @objc private func openSettings() { onOpenSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

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
