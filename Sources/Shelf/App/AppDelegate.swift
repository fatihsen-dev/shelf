import AppKit
import ServiceManagement

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
            if PreferencesStore.shared.playSoundOnCopy {
                NSSound(named: .init("Tink"))?.play()
            }
        }
        monitor.start()
        applyTheme()
        applyLaunchAtLogin(preferences.launchAtLogin)
        hotkey.register(keyCode: preferences.hotkeyKeyCode,
                        modifiers: preferences.hotkeyModifiers) { [weak self] in
            self?.mainController.toggle()
        }
        NotificationCenter.default.addObserver(self,
            selector: #selector(openSettings),
            name: .shelfOpenSettings,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(clearHistory),
            name: .shelfClearHistory,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(applyPauseState),
            name: .shelfSetPaused,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(applyTheme),
            name: .shelfThemeChanged,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleLaunchAtLogin),
            name: .shelfLaunchAtLogin,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleMenuBarIcon),
            name: .shelfMenuBarIconChanged,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(reregisterHotkey),
            name: .shelfHotkeyChanged,
            object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        hotkey.unregister()
        repository.flushPendingWrites()
    }

    @objc private func openSettings() {
        settingsController.show()
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear clipboard history?"
        alert.informativeText = "Pinned items will be kept. This cannot be undone."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        repository.clearAll(keepPinned: true)
    }

    @objc private func applyPauseState() {
        monitor.setPaused(preferences.isMonitoringPaused)
    }

    @objc private func applyTheme() {
        switch preferences.theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }
    }

    @objc private func handleLaunchAtLogin() {
        applyLaunchAtLogin(preferences.launchAtLogin)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail in dev builds without proper bundle config
        }
    }

    @objc private func handleMenuBarIcon() {
        menubar.setVisible(preferences.menuBarIcon)
    }

    @objc private func reregisterHotkey() {
        hotkey.unregister()
        hotkey.register(keyCode: preferences.hotkeyKeyCode,
                        modifiers: preferences.hotkeyModifiers) { [weak self] in
            self?.mainController.toggle()
        }
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
