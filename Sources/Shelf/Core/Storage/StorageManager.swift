import Foundation
import AppKit
import os

private let log = Logger(subsystem: "app.shelf", category: "storage")

final class StorageManager {
    let baseURL: URL
    let databaseURL: URL
    let imagesURL: URL

    init() {
        let fm = FileManager.default
        let appSupport: URL
        do {
            appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            log.error("Application Support unavailable, falling back to temporary directory: \(error.localizedDescription, privacy: .public)")
            appSupport = fm.temporaryDirectory
        }
        self.baseURL = appSupport.appendingPathComponent("Shelf", isDirectory: true)
        self.databaseURL = baseURL.appendingPathComponent("history.json")
        self.imagesURL = baseURL.appendingPathComponent("Images", isDirectory: true)
        do {
            try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
            try fm.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        } catch {
            log.error("Failed to create storage directories: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadAll() -> [ClipboardItem] {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: databaseURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ClipboardItem].self, from: data)
        } catch {
            log.error("Failed to load history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveAll(_ items: [ClipboardItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(items)
            try data.write(to: databaseURL, options: .atomic)
        } catch {
            log.error("Failed to save history: \(error.localizedDescription, privacy: .public)")
        }
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
            log.error("Failed to write image \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
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
