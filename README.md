# Shelf

A professional macOS clipboard manager. Pure AppKit (no SwiftUI), built with Swift Package Manager.

## Architecture

```
Sources/Shelf/
├── App/                    Entry point + AppDelegate
├── Core/
│   ├── Clipboard/          NSPasteboard monitor, item model, types
│   ├── Storage/            JSON-backed persistence + image store
│   ├── Preferences/        UserDefaults wrapper
│   └── Hotkey/             Carbon global hotkey
├── UI/
│   ├── Common/             Theme, blur background, search field
│   ├── Main/               Frameless floating panel (search + list)
│   ├── Menubar/            NSStatusItem controller
│   └── Settings/           (next iteration)
├── Services/               Paste simulation (CGEvent)
└── Resources/              Info.plist + entitlements
```

Layered: UI → Service → Repository → Storage. No cross-layer shortcuts.

## Build & Run

```bash
./scripts/run.sh
```

Builds via SPM, wraps the binary as a `.app` bundle (with `LSUIElement` for menubar-only), ad-hoc signs with entitlements, and launches.

## Permissions

On first launch, grant **Accessibility** in System Settings → Privacy & Security → Accessibility, so the global hotkey and paste-to-frontmost-app work.

## Default Hotkey

`⌘⇧V` opens the main window at the cursor.

## Status

- ✅ Clipboard monitoring (text, link, color, image, file)
- ✅ Persistent history (`~/Library/Application Support/Shelf/`)
- ✅ Menubar with recent items + actions
- ✅ Frameless main window with search + list
- ✅ Global hotkey
- ✅ Paste-to-frontmost-app via CGEvent
- ⏳ Settings window (next)
- ⏳ Pin/unpin UI, themes, onboarding
