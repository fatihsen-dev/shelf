import AppKit

final class MainWindowController: NSObject {
    private let repository: ClipboardRepository
    private let pasteService = PasteService()

    private var window: MainWindow?
    private var shelfView: ShelfView?
    private var clickOutsideMonitor: Any?
    private var previousApp: NSRunningApplication?

    init(repository: ClipboardRepository) {
        self.repository = repository
        super.init()
    }

    func toggle() {
        if let win = window, win.isVisible { close() } else { show() }
    }

    func show() {
        if window == nil { buildWindow() }
        guard let window = window, let shelf = shelfView else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        positionAtBottom(window: window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        shelf.resetSearch()
        shelf.focusSearch()
        shelf.selectFirst()
        startClickOutsideMonitor()
    }

    func close() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        window?.orderOut(nil)
    }

    private func buildWindow() {
        let w = Theme.Sizes.windowW
        let h = Theme.Sizes.shelfH

        let win = MainWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.animationBehavior = .none
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.styleMask.insert(.fullSizeContentView)
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true
        win.isMovable = false
        win.backgroundColor = .clear
        win.isOpaque = false

        // Use a plain wrapper as contentView — window auto-manages its frame.
        // ShelfView is constrained inside it.
        let wrapper = NSView()
        win.contentView = wrapper

        let shelf = ShelfView(repository: repository)
        shelf.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(shelf)
        NSLayoutConstraint.activate([
            shelf.topAnchor.constraint(equalTo: wrapper.topAnchor),
            shelf.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            shelf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            shelf.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        shelf.onSelect       = { [weak self] item in self?.pasteItem(item) }
        shelf.onOpenSettings = { [weak self] in self?.openSettings() }
        win.onKey            = { [weak self, weak shelf] event in
            if event.keyCode == 53 { self?.close(); return true }
            return shelf?.handleKey(event) ?? false
        }

        window = win
        shelfView = shelf
    }

    private func positionAtBottom(window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let x = visible.midX - size.width / 2
        let y = visible.minY + Theme.Sizes.windowBottomGap
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func startClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in self?.close() }

    }

    private func pasteItem(_ item: ClipboardItem) {
        close()
        let target = previousApp
        previousApp = nil
        target?.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.pasteService.paste(item)
        }
    }

    private func openSettings() {
        close()
        NotificationCenter.default.post(name: .shelfOpenSettings, object: nil)
    }
}

extension Notification.Name {
    static let shelfOpenSettings      = Notification.Name("shelf.openSettings")
    static let shelfClearHistory      = Notification.Name("shelf.clearHistory")
    static let shelfSetPaused         = Notification.Name("shelf.setPaused")
    static let shelfThemeChanged      = Notification.Name("shelf.themeChanged")
    static let shelfLaunchAtLogin     = Notification.Name("shelf.launchAtLogin")
    static let shelfMenuBarIconChanged = Notification.Name("shelf.menuBarIconChanged")
    static let shelfHotkeyChanged      = Notification.Name("shelf.hotkeyChanged")
}
