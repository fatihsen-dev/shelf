import Foundation

final class ClipboardRepository {
    static let didChangeNotification = Notification.Name("ClipboardRepositoryDidChange")

    private let storage: StorageManager
    private(set) var items: [ClipboardItem] = []
    private let queue = DispatchQueue(label: "shelf.repository", qos: .userInitiated)

    init(storage: StorageManager) {
        self.storage = storage
    }

    func load() {
        items = storage.loadAll()
    }

    func insert(_ item: ClipboardItem) {
        if let existingIndex = items.firstIndex(where: { $0.hash == item.hash }) {
            let existing = items.remove(at: existingIndex)
            items.insert(existing, at: 0)
            persist()
            notify()
            return
        }
        items.insert(item, at: 0)
        trim()
        persist()
        notify()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
        notify()
    }

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isPinned.toggle()
        persist()
        notify()
    }

    func clearAll(keepPinned: Bool = true) {
        let shouldKeep = keepPinned && PreferencesStore.shared.keepPinned
        items = shouldKeep ? items.filter { $0.isPinned } : []
        persist()
        notify()
    }

    func search(_ query: String) -> [ClipboardItem] {
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        let all = pinned + unpinned
        guard !query.isEmpty else { return all }
        let lower = query.lowercased()
        return all.filter { item in
            switch item.type {
            case .text, .link, .color:
                return item.textValue?.lowercased().contains(lower) ?? false
            case .file:
                return item.fileURLString?.lowercased().contains(lower) ?? false
            case .image:
                return "image".contains(lower)
            }
        }
    }

    private func trim() {
        let limit = PreferencesStore.shared.maxHistory
        if PreferencesStore.shared.keepPinned {
            let pinned = items.filter { $0.isPinned }
            let unpinned = items.filter { !$0.isPinned }
            items = pinned + Array(unpinned.prefix(max(0, limit - pinned.count)))
        } else {
            items = Array(items.prefix(limit))
        }
    }

    private func persist() {
        let snapshot = items
        queue.async { [weak self] in
            self?.storage.saveAll(snapshot)
        }
    }

    private func notify() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
