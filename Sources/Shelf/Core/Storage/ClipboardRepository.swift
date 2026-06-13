import Foundation

final class ClipboardRepository {
    static let didChangeNotification = Notification.Name("ClipboardRepositoryDidChange")

    private let storage: StorageManager
    private let imageStore = ImageStore()
    private(set) var items: [ClipboardItem] = []
    private let queue = DispatchQueue(label: "shelf.repository", qos: .userInitiated)
    private var persistWorkItem: DispatchWorkItem?
    private let persistDebounce: TimeInterval = 0.4

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
            schedulePersist()
            notify()
            return
        }
        items.insert(item, at: 0)
        let dropped = trim()
        cleanupOrphanedImages(in: dropped)
        schedulePersist()
        notify()
    }

    func delete(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let removed = items.remove(at: idx)
        cleanupOrphanedImages(in: [removed])
        schedulePersist()
        notify()
    }

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isPinned.toggle()
        schedulePersist()
        notify()
    }

    func clearAll(keepPinned: Bool = true) {
        let shouldKeep = keepPinned && PreferencesStore.shared.keepPinned
        let removed: [ClipboardItem]
        if shouldKeep {
            removed = items.filter { !$0.isPinned }
            items = items.filter { $0.isPinned }
        } else {
            removed = items
            items = []
        }
        cleanupOrphanedImages(in: removed)
        schedulePersist()
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

    @discardableResult
    private func trim() -> [ClipboardItem] {
        let limit = PreferencesStore.shared.maxHistory
        let kept: [ClipboardItem]
        if PreferencesStore.shared.keepPinned {
            let pinned = items.filter { $0.isPinned }
            let unpinned = items.filter { !$0.isPinned }
            kept = pinned + Array(unpinned.prefix(max(0, limit - pinned.count)))
        } else {
            kept = Array(items.prefix(limit))
        }
        let keptIds = Set(kept.map(\.id))
        let dropped = items.filter { !keptIds.contains($0.id) }
        items = kept
        return dropped
    }

    private func cleanupOrphanedImages(in removed: [ClipboardItem]) {
        let stillReferenced = Set(items.compactMap { $0.imageFilename })
        for item in removed where item.type == .image {
            guard let filename = item.imageFilename,
                  !stillReferenced.contains(filename) else { continue }
            imageStore.delete(filename: filename)
        }
    }

    private func schedulePersist() {
        persistWorkItem?.cancel()
        let snapshot = items
        let work = DispatchWorkItem { [weak self] in
            self?.storage.saveAll(snapshot)
        }
        persistWorkItem = work
        queue.asyncAfter(deadline: .now() + persistDebounce, execute: work)
    }

    func flushPendingWrites() {
        persistWorkItem?.cancel()
        persistWorkItem = nil
        let snapshot = items
        queue.sync { storage.saveAll(snapshot) }
    }

    private func notify() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
