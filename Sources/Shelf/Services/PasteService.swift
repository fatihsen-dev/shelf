import AppKit
import Carbon.HIToolbox

final class PasteService {
    private let imageStore = ImageStore()
    private let pasteboard = NSPasteboard.general

    func paste(_ item: ClipboardItem) {
        writeToPasteboard(item)
        simulatePasteKeystroke()
    }

    func copyOnly(_ item: ClipboardItem) {
        writeToPasteboard(item)
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        switch item.type {
        case .text, .link, .color:
            if let text = item.textValue { pasteboard.setString(text, forType: .string) }
        case .image:
            if let filename = item.imageFilename, let image = imageStore.loadImage(filename: filename) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let urlString = item.fileURLString, let url = URL(string: urlString) {
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }

    private func simulatePasteKeystroke() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        let loc = CGEventTapLocation.cghidEventTap
        down?.post(tap: loc)
        up?.post(tap: loc)
    }
}
