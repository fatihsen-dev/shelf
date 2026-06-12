import AppKit

final class ClipboardMonitor {
    var onCapture: ((ClipboardItem) -> Void)?

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private(set) var isPaused = false

    private let pollInterval: TimeInterval = 0.3
    private let imageStore = ImageStore()

    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    func start() {
        lastChangeCount = pasteboard.changeCount
        timer?.invalidate()
        let t = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    private func tick() {
        guard !isPaused else { return }
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current
        capture()
    }

    private func capture() {
        let types = Set(pasteboard.types ?? [])
        guard !types.contains(Self.concealedType), !types.contains(Self.transientType) else { return }

        let source = NSWorkspace.shared.frontmostApplication
        let bundleId = source?.bundleIdentifier
        let appName = source?.localizedName

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], let first = fileURLs.first, first.isFileURL {
            let hash = ClipboardItem.sha256(first.absoluteString)
            let item = ClipboardItem(type: .file, fileURLString: first.absoluteString, hash: hash,
                                     sourceBundleId: bundleId, sourceAppName: appName)
            onCapture?(item)
            return
        }

        if let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage], let img = images.first,
           let tiff = img.tiffRepresentation {
            let hash = ClipboardItem.sha256(tiff)
            let filename = "\(hash).png"
            if imageStore.save(tiff: tiff, filename: filename) {
                let item = ClipboardItem(type: .image, imageFilename: filename, hash: hash,
                                         sourceBundleId: bundleId, sourceAppName: appName)
                onCapture?(item)
            }
            return
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let type: ClipboardType = Self.inferType(trimmed)
            let hash = ClipboardItem.sha256(text)
            let item = ClipboardItem(type: type, textValue: text, hash: hash,
                                     sourceBundleId: bundleId, sourceAppName: appName)
            onCapture?(item)
        }
    }

    private static func inferType(_ text: String) -> ClipboardType {
        if isLikelyURL(text) { return .link }
        if isLikelyColor(text) { return .color }
        return .text
    }

    private static func isLikelyURL(_ text: String) -> Bool {
        guard text.count < 2048, !text.contains(" "), !text.contains("\n") else { return false }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.firstMatch(in: text, options: [], range: range)?.range == range
    }

    private static func isLikelyColor(_ text: String) -> Bool {
        let hex = text.hasPrefix("#") ? String(text.dropFirst()) : text
        guard hex.count == 6 || hex.count == 8 else { return false }
        return hex.allSatisfy { $0.isHexDigit }
    }
}
