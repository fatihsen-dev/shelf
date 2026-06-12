import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private let repository: ClipboardRepository
    private let preferences = PreferencesStore.shared
    private lazy var menubar = MenubarController(repository: repository, onOpenMain: { [weak self] in
        self?.mainController.toggle()
    }, onOpenSettings: { [weak self] in
        self?.openSettings()
    })
    private lazy var mainController = MainWindowController(repository: repository)
    private lazy var settingsController = SettingsWindowController()
    private lazy var hotkey = GlobalHotkeyManager()

    override init() {
        let storage = StorageManager()
        self.repository = ClipboardRepository(storage: storage)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        repository.load()
        menubar.install()
        requestAccessibilityIfNeeded()
        monitor.onCapture = { [weak self] item in
            self?.repository.insert(item)
        }
        monitor.start()
        hotkey.register(keyCode: preferences.hotkeyKeyCode,
                        modifiers: preferences.hotkeyModifiers) { [weak self] in
            self?.mainController.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        hotkey.unregister()
    }

    private func openSettings() {
        settingsController.show()
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
