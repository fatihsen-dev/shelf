import AppKit
import Carbon.HIToolbox

private let kDefaultPasteLatestKeyCode: Int  = kVK_ANSI_C
private let kDefaultPasteLatestMods: Int     = Int(cmdKey | shiftKey)
private let kDefaultPinSelectedKeyCode: Int  = kVK_ANSI_P
private let kDefaultPinSelectedMods: Int     = Int(cmdKey)
private let kDefaultClearShelfKeyCode: Int   = kVK_Delete
private let kDefaultClearShelfMods: Int      = Int(cmdKey | optionKey)

final class PreferencesStore {
    static let shared = PreferencesStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hotkeyKeyCode = "hotkey.keyCode"
        static let hotkeyModifiers = "hotkey.modifiers"
        static let launchAtLogin = "launchAtLogin"
        static let maxHistory = "maxHistory"
        static let theme = "theme" // auto / light / dark
        static let pauseMonitoring = "pauseMonitoring"
    }

    var hotkeyKeyCode: UInt32 {
        get { UInt32(defaults.object(forKey: Keys.hotkeyKeyCode) as? Int ?? kVK_ANSI_V) }
        set { defaults.set(Int(newValue), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 {
        get { UInt32(defaults.object(forKey: Keys.hotkeyModifiers) as? Int ?? Int(optionKey)) }
        set { defaults.set(Int(newValue), forKey: Keys.hotkeyModifiers) }
    }

    var pasteLatestKeyCode: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.pasteLatest.keyCode") as? Int ?? kDefaultPasteLatestKeyCode) }
        set { defaults.set(Int(newValue), forKey: "hotkey.pasteLatest.keyCode") }
    }
    var pasteLatestModifiers: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.pasteLatest.modifiers") as? Int ?? kDefaultPasteLatestMods) }
        set { defaults.set(Int(newValue), forKey: "hotkey.pasteLatest.modifiers") }
    }

    var pinSelectedKeyCode: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.pinSelected.keyCode") as? Int ?? kDefaultPinSelectedKeyCode) }
        set { defaults.set(Int(newValue), forKey: "hotkey.pinSelected.keyCode") }
    }
    var pinSelectedModifiers: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.pinSelected.modifiers") as? Int ?? kDefaultPinSelectedMods) }
        set { defaults.set(Int(newValue), forKey: "hotkey.pinSelected.modifiers") }
    }

    var clearShelfKeyCode: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.clearShelf.keyCode") as? Int ?? kDefaultClearShelfKeyCode) }
        set { defaults.set(Int(newValue), forKey: "hotkey.clearShelf.keyCode") }
    }
    var clearShelfModifiers: UInt32 {
        get { UInt32(defaults.object(forKey: "hotkey.clearShelf.modifiers") as? Int ?? kDefaultClearShelfMods) }
        set { defaults.set(Int(newValue), forKey: "hotkey.clearShelf.modifiers") }
    }

    var maxHistory: Int {
        get { defaults.object(forKey: Keys.maxHistory) as? Int ?? 500 }
        set { defaults.set(newValue, forKey: Keys.maxHistory) }
    }

    var theme: String {
        get { defaults.string(forKey: Keys.theme) ?? "auto" }
        set { defaults.set(newValue, forKey: Keys.theme) }
    }

    var isMonitoringPaused: Bool {
        get { defaults.bool(forKey: Keys.pauseMonitoring) }
        set { defaults.set(newValue, forKey: Keys.pauseMonitoring) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }

    var playSoundOnCopy: Bool {
        get { defaults.bool(forKey: "playSoundOnCopy") }
        set { defaults.set(newValue, forKey: "playSoundOnCopy") }
    }

    var storeImages: Bool {
        get { defaults.object(forKey: "storeImages") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "storeImages") }
    }

    var keepPinned: Bool {
        get { defaults.object(forKey: "keepPinned") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "keepPinned") }
    }

    var ignorePasswords: Bool {
        get { defaults.object(forKey: "ignorePasswords") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "ignorePasswords") }
    }

    var menuBarIcon: Bool {
        get { defaults.object(forKey: "menuBarIcon") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "menuBarIcon") }
    }

    var ignoredBundleIds: [String] {
        get { defaults.array(forKey: "ignoredBundleIds") as? [String] ?? [] }
        set { defaults.set(newValue, forKey: "ignoredBundleIds") }
    }

    func addIgnoredApp(_ bundleId: String) {
        var list = ignoredBundleIds
        guard !list.contains(bundleId) else { return }
        list.append(bundleId)
        ignoredBundleIds = list
    }

    func removeIgnoredApp(_ bundleId: String) {
        ignoredBundleIds = ignoredBundleIds.filter { $0 != bundleId }
    }
}
