import AppKit

final class CardRailView: NSView {
    var items: [ClipboardItem] = [] { didSet { reload() } }
    var onSelect: ((ClipboardItem) -> Void)?
    var onDelete: ((ClipboardItem) -> Void)?
    var onTogglePin: ((ClipboardItem) -> Void)?

    private let scrollView   = NSScrollView()
    private let contentStack = NSStackView()
    private var cards: [CardView] = []
    private var selectedIndex = 0

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller   = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers    = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        contentStack.orientation = .horizontal
        contentStack.spacing     = Theme.Sizes.cardGap
        contentStack.alignment   = .centerY
        contentStack.edgeInsets  = NSEdgeInsets(
            top: Theme.Sizes.railPadV, left: Theme.Sizes.shelfPadH,
            bottom: Theme.Sizes.railPadV, right: Theme.Sizes.shelfPadH
        )
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentStack

        // Pin stack to clip view — leave trailing open for horizontal scroll
        let clip = scrollView.contentView
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: clip.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: clip.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private lazy var emptyState: NSView = {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: nil)
        icon.symbolConfiguration = .init(pointSize: 28, weight: .light)
        icon.contentTintColor = Theme.Color.textFaint
        icon.translatesAutoresizingMaskIntoConstraints = false

        let lbl = NSTextField(labelWithString: "Your clipboard is empty")
        lbl.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = Theme.Color.textFaint
        lbl.alignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let sub = NSTextField(labelWithString: "Copy something to get started")
        sub.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        sub.textColor = Theme.Color.textFaint
        sub.alignment = .center
        sub.translatesAutoresizingMaskIntoConstraints = false

        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(icon)
        v.addSubview(lbl)
        v.addSubview(sub)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            icon.topAnchor.constraint(equalTo: v.topAnchor),
            lbl.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 10),
            lbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            sub.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 4),
            sub.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            sub.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        return v
    }()

    private func reload() {
        cards.forEach { $0.removeFromSuperview() }
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        cards = []
        emptyState.removeFromSuperview()

        if items.isEmpty {
            emptyState.translatesAutoresizingMaskIntoConstraints = false
            addSubview(emptyState)
            NSLayoutConstraint.activate([
                emptyState.centerXAnchor.constraint(equalTo: centerXAnchor),
                emptyState.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            return
        }

        var lastPinnedIdx = items.lastIndex(where: { $0.isPinned }) ?? -1
        let _ = lastPinnedIdx  // used below for divider

        for (i, item) in items.enumerated() {
            // divider between pinned and unpinned
            if i > 0, !item.isPinned, items[i - 1].isPinned {
                let divider = makeDivider()
                contentStack.addArrangedSubview(divider)
            }

            let card = CardView()
            card.item = item
            card.widthAnchor.constraint(equalToConstant: Theme.Sizes.cardWidth).isActive = true
            card.heightAnchor.constraint(equalToConstant: Theme.Sizes.cardHeight).isActive = true

            let idx = i
            card.onSelect     = { [weak self] in self?.activateCard(at: idx) }
            card.onDelete     = { [weak self] in self?.onDelete?(item) }
            card.onTogglePin  = { [weak self] in self?.onTogglePin?(item) }

            contentStack.addArrangedSubview(card)
            cards.append(card)
        }

        let target = min(selectedIndex, max(0, cards.count - 1))
        selectCard(at: target, scroll: false)
    }

    func selectFirst() {
        selectedIndex = 0
        selectCard(at: 0, scroll: true)
    }

    func moveSelection(_ delta: Int) {
        guard !cards.isEmpty else { return }
        selectCard(at: max(0, min(cards.count - 1, selectedIndex + delta)), scroll: true)
    }

    func moveSelectionWrapping(_ delta: Int) {
        guard !cards.isEmpty else { return }
        let next = (selectedIndex + delta + cards.count) % cards.count
        selectCard(at: next, scroll: true)
    }

    func activateSelection() {
        guard selectedIndex < items.count else { return }
        onSelect?(items[selectedIndex])
    }

    func deleteSelection() {
        guard selectedIndex < items.count else { return }
        onDelete?(items[selectedIndex])
    }

    private func activateCard(at index: Int) {
        selectCard(at: index, scroll: false)
        guard index < items.count else { return }
        onSelect?(items[index])
    }

    private func selectCard(at index: Int, scroll: Bool) {
        selectedIndex = index
        cards.enumerated().forEach { $1.isCardSelected = ($0 == index) }
        if scroll { scrollToCard(at: index) }
    }

    private func scrollToCard(at index: Int) {
        guard index < cards.count else { return }
        let card = cards[index]
        guard let docView = scrollView.documentView else { return }
        let frameInDoc = card.convert(card.bounds, to: docView)
        let visible = scrollView.documentVisibleRect
        if frameInDoc.minX < visible.minX {
            docView.scroll(NSPoint(x: frameInDoc.minX - Theme.Sizes.shelfPadH, y: 0))
        } else if frameInDoc.maxX > visible.maxX {
            docView.scroll(NSPoint(x: frameInDoc.maxX - scrollView.bounds.width + Theme.Sizes.shelfPadH, y: 0))
        }
    }

    private func makeDivider() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = Theme.Color.divider.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 1).isActive = true
        v.heightAnchor.constraint(equalToConstant: Theme.Sizes.cardHeight - 24).isActive = true
        return v
    }
}
