import AppKit

final class MainWindowController: NSObject {
    private let repository: ClipboardRepository
    private let pasteService = PasteService()

    private var window: MainWindow?
    private let background = BlurredBackgroundView()
    private let searchField = SearchField()
    private let listView = ClipboardListView()

    private var query: String = ""
    private var clickOutsideMonitor: Any?
    private var previousApp: NSRunningApplication?

    init(repository: ClipboardRepository) {
        self.repository = repository
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(repositoryChanged),
                                               name: ClipboardRepository.didChangeNotification,
                                               object: nil)
    }

    func toggle() {
        if let win = window, win.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        if window == nil { buildWindow() }
        guard let window = window else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        positionAtCenter(window: window)
        refreshItems()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        searchField.reset()
        searchField.focus()
        listView.selectFirst()
        startClickOutsideMonitor()
    }

    func close() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        window?.orderOut(nil)
    }

    private func startClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    private func buildWindow() {
        let size = NSSize(width: Theme.Sizes.windowWidth, height: Theme.Sizes.windowHeight)
        let win = MainWindow(contentRect: NSRect(origin: .zero, size: size),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
        win.title = "Shelf"
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.animationBehavior = .none
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.styleMask.insert(.fullSizeContentView)
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true
        win.isMovable = false

        let content = NSView(frame: NSRect(origin: .zero, size: size))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        searchField.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(searchField)

        listView.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(listView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: content.topAnchor),
            searchField.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            searchField.heightAnchor.constraint(equalToConstant: Theme.Sizes.searchHeight),

            listView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: Theme.Spacing.s),
            listView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Theme.Spacing.s),
            listView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Theme.Spacing.s),
            listView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Theme.Spacing.s)
        ])

        win.contentView = content

        searchField.onChange = { [weak self] q in
            self?.query = q
            self?.refreshItems()
            self?.listView.selectFirst()
        }
        searchField.onSubmit = { [weak self] in self?.listView.activateSelection() }
        searchField.onArrowDown = { [weak self] in self?.listView.moveSelection(1) }
        searchField.onArrowUp = { [weak self] in self?.listView.moveSelection(-1) }
        searchField.onEscape = { [weak self] in self?.close() }

        listView.onSelect = { [weak self] item in self?.pasteItem(item) }

        window = win
    }

    private func refreshItems() {
        listView.items = repository.search(query)
    }

    @objc private func repositoryChanged() {
        DispatchQueue.main.async { [weak self] in self?.refreshItems() }
    }

    private func pasteItem(_ item: ClipboardItem) {
        close()
        let target = previousApp
        previousApp = nil
        target?.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.pasteService.paste(item)
        }
    }

    private func positionAtCenter(window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        window.setFrameOrigin(origin)
    }
}
