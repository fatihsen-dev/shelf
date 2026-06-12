import AppKit

enum ClipboardType: String, Codable {
    case text
    case link
    case color
    case image
    case file

    var iconName: String {
        switch self {
        case .text:  return "doc.plaintext"
        case .link:  return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        case .file:  return "doc"
        }
    }

    var displayName: String {
        switch self {
        case .text:  return "Text"
        case .link:  return "Link"
        case .color: return "Color"
        case .image: return "Image"
        case .file:  return "File"
        }
    }
}
