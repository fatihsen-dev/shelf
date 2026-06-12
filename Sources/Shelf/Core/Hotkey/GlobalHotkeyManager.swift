import AppKit
import Carbon.HIToolbox

final class GlobalHotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x53484C46), id: 1) // 'SHLF'

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()
        self.handler = handler

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handler?()
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)

        let regStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if installStatus != noErr || regStatus != noErr {
            NSLog("[Shelf] Hotkey registration failed install=\(installStatus) register=\(regStatus)")
        } else {
            NSLog("[Shelf] Hotkey registered keyCode=\(keyCode) modifiers=\(modifiers)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let h = eventHandler { RemoveEventHandler(h); eventHandler = nil }
        handler = nil
    }

    deinit { unregister() }
}
