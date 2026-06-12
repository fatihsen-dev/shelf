import AppKit

final class ClipboardListView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var items: [ClipboardItem] = [] { didSet { tableView.reloadData() } }
    var onSelect: ((ClipboardItem) -> Void)?
    var onDelete: ((ClipboardItem) -> Void)?
    var onPin: ((ClipboardItem) -> Void)?

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = Theme.Sizes.cellHeight
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.selectionHighlightStyle = .none
        tableView.gridStyleMask = []
        tableView.dataSource = self
        tableView.delegate = self
        tableView.action = #selector(handleClick)
        tableView.doubleAction = #selector(handleDoubleClick)
        tableView.target = self

        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func selectFirst() {
        guard !items.isEmpty else { return }
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        tableView.scrollRowToVisible(0)
    }

    func moveSelection(_ delta: Int) {
        guard !items.isEmpty else { return }
        let current = tableView.selectedRow
        let next = max(0, min(items.count - 1, current + delta))
        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    func activateSelection() {
        let row = tableView.selectedRow
        guard row >= 0, row < items.count else { return }
        onSelect?(items[row])
    }

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let cell = ClipboardCellView()
        cell.item = items[row]
        return cell
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? { nil }

    @objc private func handleClick() {
        tableView.window?.makeFirstResponder(tableView)
    }

    @objc private func handleDoubleClick() {
        activateSelection()
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76: activateSelection() // return / enter
        default: super.keyDown(with: event)
        }
    }
}
