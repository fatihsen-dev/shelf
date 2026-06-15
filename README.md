<div align="center">
  <img src="assets/logo.png" alt="Shelf" width="160" height="160" />

  <h1>Shelf</h1>

  <p>A native clipboard manager for macOS. Fast, lightweight, and built with pure AppKit.</p>

  <p>
    <a href="https://github.com/fatihsen-dev/shelf/releases"><img src="https://img.shields.io/github/v/release/fatihsen-dev/shelf?style=flat-square" alt="Latest release" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/fatihsen-dev/shelf?style=flat-square" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square" alt="macOS 13+" />
  </p>
</div>

---

## Overview

Shelf keeps a searchable history of everything you copy — text, links, colors, images, and files. It lives in the menu bar, opens with a global hotkey, and pastes back into the frontmost app with a single keystroke.

Built with Swift Package Manager and pure AppKit. No Electron, no SwiftUI runtime, no third-party dependencies.

## Features

- **Universal clipboard history** — text, links, colors, images, and files
- **Global hotkey** — `⌥V` summons the picker at the bottom of the screen
- **Paste-to-frontmost** — selected item is pasted into the active application via `CGEvent`
- **Persistent storage** — history survives restarts (`~/Library/Application Support/Shelf/`)
- **Menu bar access** — quick view of recent items without opening the main window
- **Search** — incremental filtering across the entire history
- **Native performance** — minimal CPU and memory footprint, no background polling overhead

## Installation

### Homebrew (recommended)

```bash
brew tap fatihsen-dev/shelf
brew install --cask shelf
```

### Manual

Download the latest `Shelf-x.y.z.zip` from the [Releases](https://github.com/fatihsen-dev/shelf/releases) page, unzip, and drag `Shelf.app` into `/Applications`.

## Permissions

On first launch, Shelf requests **Accessibility** access. Grant it under:

> System Settings → Privacy & Security → Accessibility

This is required for the global hotkey and the paste-to-frontmost-app feature. Shelf does not transmit clipboard data anywhere — all history stays on your device.

## Usage

| Action | Shortcut |
|--------|----------|
| Open clipboard picker | `⌥V` |
| Paste selected item | `↵` |
| Close picker | `esc` |
| Search | start typing |

The menu bar icon provides quick access to recent items and the settings window.

## Architecture

```
Sources/Shelf/
├── App/             Entry point and AppDelegate
├── Core/
│   ├── Clipboard/   NSPasteboard monitor, item model, types
│   ├── Storage/     JSON-backed persistence and image store
│   ├── Preferences/ UserDefaults wrapper
│   └── Hotkey/      Carbon global hotkey
├── UI/
│   ├── Common/      Theme, blur background, search field
│   ├── Main/        Frameless floating panel
│   ├── Menubar/     NSStatusItem controller
│   └── Settings/    Preferences window
├── Services/        Paste simulation via CGEvent
└── Resources/       Info.plist and entitlements
```

Layered: `UI → Service → Repository → Storage`. Dependencies flow one direction only.

## Building from Source

Requirements:

- macOS 13 (Ventura) or later
- Swift 5.9+ (Xcode 15 or Command Line Tools)

Run locally:

```bash
./scripts/run.sh
```

This builds via SPM, wraps the binary as a `.app` bundle, ad-hoc signs it with the required entitlements, and launches it.

Build a universal release bundle:

```bash
./scripts/build-release.sh
```

Full release pipeline (sign, notarize, staple, package):

```bash
./scripts/release.sh
```

## Privacy

Shelf stores clipboard history exclusively on your local device under `~/Library/Application Support/Shelf/`. Nothing is transmitted to remote servers. There is no analytics, no telemetry, and no account system.

## License

Shelf is released under the [MIT License](LICENSE).
