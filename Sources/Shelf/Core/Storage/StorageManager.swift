import Foundation
import AppKit
import ImageIO
import os

private let log = Logger(subsystem: "app.shelf", category: "storage")

final class StorageManager {
    /// Shared instance — init touches the filesystem (createDirectory), so avoid
    /// spinning up a new one per view/service.
    static let shared = StorageManager()

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
    static let shared = ImageStore()

    private let storage = StorageManager.shared
    private static let thumbnailCache: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 80
        return c
    }()

    private static let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47]

    /// Accepts TIFF or PNG bytes straight off the pasteboard. PNG is written as-is;
    /// anything else is converted once, on the caller's background queue.
    func save(imageData: Data, filename: String) -> Bool {
        let url = storage.imagesURL.appendingPathComponent(filename)
        guard !FileManager.default.fileExists(atPath: url.path) else { return true }
        let png: Data
        if imageData.count > 4, Array(imageData.prefix(4)) == Self.pngMagic {
            png = imageData
        } else {
            guard let rep = NSBitmapImageRep(data: imageData),
                  let converted = rep.representation(using: .png, properties: [:]) else { return false }
            png = converted
        }
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

    /// Downsampled image for card previews. ImageIO decodes straight to the
    /// requested size, so a 6000px screenshot never gets fully decoded.
    func thumbnail(filename: String, maxPixel: Int = 512) -> NSImage? {
        let key = "\(filename)@\(maxPixel)" as NSString
        if let cached = Self.thumbnailCache.object(forKey: key) { return cached }
        let url = storage.imagesURL.appendingPathComponent(filename)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        Self.thumbnailCache.setObject(image, forKey: key)
        return image
    }

    func delete(filename: String) {
        let url = storage.imagesURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        Self.thumbnailCache.removeAllObjects()
    }
}
