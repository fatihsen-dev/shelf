import AppKit
import CryptoKit

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let type: ClipboardType
    let createdAt: Date
    let sourceBundleId: String?
    let sourceAppName: String?
    let hash: String

    let textValue: String?
    let imageFilename: String?
    let fileURLString: String?

    var isPinned: Bool

    init(type: ClipboardType,
         textValue: String? = nil,
         imageFilename: String? = nil,
         fileURLString: String? = nil,
         hash: String,
         sourceBundleId: String? = nil,
         sourceAppName: String? = nil) {
        self.id = UUID()
        self.type = type
        self.createdAt = Date()
        self.textValue = textValue
        self.imageFilename = imageFilename
        self.fileURLString = fileURLString
        self.hash = hash
        self.sourceBundleId = sourceBundleId
        self.sourceAppName = sourceAppName
        self.isPinned = false
    }

    var previewText: String {
        switch type {
        case .text, .link, .color: return textValue ?? ""
        case .image: return "Image"
        case .file:  return (fileURLString.flatMap { URL(string: $0)?.lastPathComponent }) ?? "File"
        }
    }

    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ string: String) -> String {
        sha256(Data(string.utf8))
    }
}
