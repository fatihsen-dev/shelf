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
        guard AXIsProcessTrusted() else {
            NSLog("[Shelf] Paste skipped: accessibility permission not granted")
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        // Suppress local key events during the synthesized paste so a user-held
        // modifier (e.g. ⌘ from the hotkey) doesn't combine with the injected ⌘V.
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        let up   = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
}
