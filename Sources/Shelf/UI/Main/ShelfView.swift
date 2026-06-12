import AppKit

final class ShelfView: NSView {
    var onSelect: ((ClipboardItem) -> Void)?
    var onOpenSettings: (() -> Void)?

    private let repository: ClipboardRepository
    private let container  = NSVisualEffectView()
    private let tintView   = NSView()
    private let searchBar  = SearchBarView()
    private let rail       = CardRailView()
    private let footer     = FooterView()

    private var filter: ClipboardType? = nil
    private var query: String = ""

    init(repository: ClipboardRepository) {
        self.repository = repository
        super.init(frame: .zero)
        setup()
        NotificationCenter.default.addObserver(self,
            selector: #selector(repositoryChanged),
            name: ClipboardRepository.didChangeNotification,
            object: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        container.material = .contentBackground
        container.blendingMode = .behindWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = Theme.Radius.shelf
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 0.5
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        // Color tint overlay — sits inside the blur to match design shelf-bg color
        tintView.wantsLayer = true
        tintView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tintView, positioned: .below, relativeTo: nil)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        rail.translatesAutoresizingMaskIntoConstraints = false
        footer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(searchBar)
        container.addSubview(rail)
        container.addSubview(footer)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: Theme.Sizes.shelfH),

            tintView.topAnchor.constraint(equalTo: container.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            searchBar.topAnchor.constraint(equalTo: container.topAnchor, constant: Theme.Sizes.shelfPadTop),
            searchBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Theme.Sizes.shelfPadH),
            searchBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Theme.Sizes.shelfPadH),
            searchBar.heightAnchor.constraint(equalToConstant: Theme.Sizes.searchH),

            rail.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: Theme.Spacing.s),
            rail.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rail.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rail.heightAnchor.constraint(equalToConstant: Theme.Sizes.cardHeight + Theme.Sizes.railPadV * 2),

            footer.topAnchor.constraint(equalTo: rail.bottomAnchor),
            footer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Theme.Sizes.shelfPadH),
            footer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Theme.Sizes.shelfPadH),
            footer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Theme.Sizes.shelfPadBot),
        ])

        searchBar.onQueryChange = { [weak self] q in self?.query = q; self?.refreshItems() }
        searchBar.onFilterChange = { [weak self] f in self?.filter = f; self?.refreshItems() }
        searchBar.onSettings = { [weak self] in self?.onOpenSettings?() }

        rail.onSelect = { [weak self] item in self?.onSelect?(item) }
        rail.onDelete = { [weak self] item in
            guard let self else { return }
            if item.isPinned {
                let alert = NSAlert()
                alert.messageText = "Delete pinned item?"
                alert.informativeText = "This item is starred. Are you sure you want to delete it?"
                alert.addButton(withTitle: "Delete")
                alert.addButton(withTitle: "Cancel")
                alert.buttons.first?.keyEquivalent = "\r"
                alert.buttons[1].keyEquivalent = "\u{1b}"
                guard alert.runModal() == .alertFirstButtonReturn else { return }
            }
            self.repository.delete(item.id)
        }
        rail.onTogglePin = { [weak self] item in self?.repository.togglePin(item.id) }

        refreshItems()
        updateColors()
    }

    func focusSearch() { searchBar.focus() }
    func resetSearch() { searchBar.reset() }
    func selectFirst()  { rail.selectFirst() }


    func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: rail.moveSelection(-1); return true   // ←
        case 124: rail.moveSelection(1);  return true   // →
        case 48:  rail.moveSelectionWrapping(1); return true  // Tab
        case 36:  rail.activateSelection(); return true // ↵
        case 51 where event.modifierFlags.contains(.command): // ⌘⌫
            rail.deleteSelection(); return true
        case 53:                                        // Esc
            if !query.isEmpty { searchBar.reset(); query = ""; refreshItems() }
            return true
        default:  return false
        }
    }

    @objc private func repositoryChanged() {
        DispatchQueue.main.async { [weak self] in self?.refreshItems() }
    }

    private func refreshItems() {
        var items = repository.search(query)
        if let f = filter { items = items.filter { $0.type == f } }
        let pinned = items.filter(\.isPinned)
        let rest   = items.filter { !$0.isPinned }
        rail.items = pinned + rest
        searchBar.updateCount(visible: items.count, total: repository.items.count)
    }

    private func updateColors() {
        let isDark = effectiveAppearance.name == .darkAqua
        effectiveAppearance.performAsCurrentDrawingAppearance {
            // Shelf-bg tint: light rgba(250,249,251,0.72) / dark rgba(34,30,36,0.66)
            self.tintView.layer?.backgroundColor = isDark
                ? NSColor(red: 0.133, green: 0.118, blue: 0.141, alpha: 0.55).cgColor
                : NSColor(red: 0.980, green: 0.976, blue: 0.984, alpha: 0.52).cgColor

            self.container.layer?.borderColor = isDark
                ? NSColor.white.withAlphaComponent(0.10).cgColor
                : NSColor.white.withAlphaComponent(0.65).cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
}
