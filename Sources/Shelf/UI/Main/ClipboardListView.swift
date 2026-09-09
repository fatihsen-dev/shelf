import AppKit

final class CardRailView: NSView {
    var items: [ClipboardItem] = [] { didSet { reload() } }
    var onSelect: ((ClipboardItem) -> Void)?
    var onDelete: ((ClipboardItem) -> Void)?
    var onTogglePin: ((ClipboardItem) -> Void)?

    private let scrollView   = NSScrollView()
    private let contentStack = NSStackView()
    /// Cards currently in the stack, index-aligned with `items[0..<renderedCount]`.
    private var cards: [CardView] = []
    /// Detached cards kept for reuse so a reload doesn't rebuild view trees.
    private var recycled: [CardView] = []
    private var renderedCount = 0
    private var selectedIndex = 0

    /// How many cards get built up front / per scroll batch. Only ~6 fit on screen,
    /// so building all 500 of them on every copy is what froze the app.
    private let pageSize = 12
    private let recyclePoolLimit = 40

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

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(clipBoundsChanged),
            name: NSView.boundsDidChangeNotification, object: scrollView.contentView)

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
        recycled.append(contentsOf: cards.prefix(max(0, recyclePoolLimit - recycled.count)))
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        cards = []
        renderedCount = 0
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

        selectedIndex = min(selectedIndex, items.count - 1)
        render(upTo: max(pageSize, selectedIndex + 1))
        selectCard(at: selectedIndex, scroll: false)
    }

    /// Appends cards until `renderedCount` reaches `target`. Never rebuilds what
    /// is already on screen.
    private func render(upTo target: Int) {
        let end = min(target, items.count)
        guard end > renderedCount else { return }
        for i in renderedCount..<end {
            let item = items[i]
            // divider between pinned and unpinned
            if i > 0, !item.isPinned, items[i - 1].isPinned {
                contentStack.addArrangedSubview(makeDivider())
            }

            let card = dequeueCard()
            card.item = item
            card.isCardSelected = (i == selectedIndex)

            let idx = i
            card.onSelect     = { [weak self] in self?.activateCard(at: idx) }
            card.onDelete     = { [weak self] in self?.onDelete?(item) }
            card.onTogglePin  = { [weak self] in self?.onTogglePin?(item) }

            contentStack.addArrangedSubview(card)
            cards.append(card)
        }
        renderedCount = end
        // Cards must stay index-aligned with items — dividers live in the stack but
        // never in `cards`.
        assert(cards.count == renderedCount, "card/item index alignment broken")
        // Freshly added cards have no frame yet; scrollToCard reads frames.
        contentStack.layoutSubtreeIfNeeded()
    }

    private func dequeueCard() -> CardView {
        if let card = recycled.popLast() { return card }
        let card = CardView()
        card.widthAnchor.constraint(equalToConstant: Theme.Sizes.cardWidth).isActive = true
        card.heightAnchor.constraint(equalToConstant: Theme.Sizes.cardHeight).isActive = true
        return card
    }

    @objc private func clipBoundsChanged() {
        guard renderedCount < items.count else { return }
        let visible = scrollView.documentVisibleRect
        let threshold = contentStack.frame.width - Theme.Sizes.cardWidth * 3
        guard visible.maxX >= threshold else { return }
        render(upTo: renderedCount + pageSize)
    }

    func selectFirst() {
        selectedIndex = 0
        selectCard(at: 0, scroll: true)
    }

    func moveSelection(_ delta: Int) {
        guard !items.isEmpty else { return }
        let next = max(0, min(items.count - 1, selectedIndex + delta))
        render(upTo: next + 1)
        selectCard(at: next, scroll: true)
    }

    func moveSelectionWrapping(_ delta: Int) {
        guard !items.isEmpty else { return }
        let next = (selectedIndex + delta + items.count) % items.count
        render(upTo: next + 1)
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
