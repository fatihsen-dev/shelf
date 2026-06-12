import Foundation
import AppKit

final class StorageManager {
    let baseURL: URL
    let databaseURL: URL
    let imagesURL: URL

    init() {
        let fm = FileManager.default
        let appSupport = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        self.baseURL = appSupport.appendingPathComponent("Shelf", isDirectory: true)
        self.databaseURL = baseURL.appendingPathComponent("history.json")
        self.imagesURL = baseURL.appendingPathComponent("Images", isDirectory: true)
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: imagesURL, withIntermediateDirectories: true)
    }

    func loadAll() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: databaseURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipboardItem].self, from: data)) ?? []
    }

    func saveAll(_ items: [ClipboardItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: databaseURL, options: .atomic)
    }
}

final class ImageStore {
    private let storage = StorageManager()

    func save(tiff: Data, filename: String) -> Bool {
        let url = storage.imagesURL.appendingPathComponent(filename)
        guard !FileManager.default.fileExists(atPath: url.path) else { return true }
        guard let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    func loadImage(filename: String) -> NSImage? {
        let url = storage.imagesURL.appendingPathComponent(filename)
        return NSImage(contentsOf: url)
    }

    func delete(filename: String) {
        let url = storage.imagesURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
