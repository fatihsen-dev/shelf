import AppKit
import Carbon.HIToolbox

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
}
