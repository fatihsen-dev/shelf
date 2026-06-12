import AppKit

final class MainWindow: NSWindow {
    var onKey: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, let onKey, onKey(event) { return }
        super.sendEvent(event)
    }
}
